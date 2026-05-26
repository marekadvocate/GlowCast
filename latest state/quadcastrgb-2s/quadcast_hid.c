/* quadcast_hid - set HyperX QuadCast 2 S RGB on macOS via HIDAPI.
 *
 * Why this exists: the QuadCast 2 S drives RGB over a HID-class interface.
 * On macOS the kernel (IOHIDFamily) owns HID interfaces, so libusb-based
 * quadcastrgb gets "Access denied" claiming them. HIDAPI / IOHIDManager can
 * talk to HID without claiming the interface, so it works where libusb can't.
 *
 * Packet generation is reused verbatim from the upstream Ors1mer/QuadcastRGB
 * code (argparser.c + rgbmodes.c). Only the transport (libusb -> HIDAPI) is new.
 */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <signal.h>
#include <time.h>
#include <wchar.h>
#include <hidapi/hidapi.h>

#include "modules/argparser.h"
#include "modules/rgbmodes.h"

#define VID 0x03f0
#define PID 0x02b5
#define QS2S_DISPLAY_CODE     0x44
#define QS2S_PACKET_CNT_CODE  0x01
#define QUADCAST_2S_PID       0x02b5

static volatile sig_atomic_t running = 1;
static void on_signal(int s) { (void)s; running = 0; }

/* Open HID interface 1 of the QuadCast 2 S controller (the RGB control iface,
 * endpoints 0x06 OUT / 0x85 IN). */
static hid_device *open_iface1(void)
{
    struct hid_device_info *devs, *cur;
    char path[1024] = {0};
    hid_device *dev;

    devs = hid_enumerate(VID, PID);
    for (cur = devs; cur; cur = cur->next) {
        if (cur->interface_number == 1 && !path[0])
            strncpy(path, cur->path, sizeof(path) - 1);
    }
    hid_free_enumeration(devs);

    if (!path[0]) {
        fprintf(stderr, "QuadCast 2 S controller (03f0:02b5, iface 1) not found. "
                        "Is the mic connected?\n");
        return NULL;
    }
    dev = hid_open_path(path);
    if (!dev)
        fprintf(stderr, "Couldn't open the controller HID interface: %ls\n",
                hid_error(NULL));
    return dev;
}

/* Send one 64-byte QS2S packet and read its response (mirrors the upstream
 * interrupt-OUT 0x06 / interrupt-IN 0x85 handshake). */
static int qs2s_xfer(hid_device *dev, const unsigned char *pkt)
{
    unsigned char buf[1 + DATA_PACKET_SIZE]; /* [report id 0][64 data] */
    unsigned char rsp[DATA_PACKET_SIZE];
    int w, r;

    buf[0] = 0x00;
    memcpy(buf + 1, pkt, DATA_PACKET_SIZE);

    w = hid_write(dev, buf, sizeof(buf));
    if (w < 0) {
        fprintf(stderr, "hid_write failed: %ls\n", hid_error(dev));
        return -1;
    }
    r = hid_read_timeout(dev, rsp, sizeof(rsp), 1000);
    if (r < 0) {
        fprintf(stderr, "hid_read failed: %ls\n", hid_error(dev));
        return -1;
    }
    if (r > 0 && rsp[0] != 0xff)
        fprintf(stderr, "warn: unexpected response code 0x%02x (expected 0xff)\n",
                rsp[0]);
    return 0;
}

/* Send the full solid-color sequence: header + all data packets. */
static int send_sequence(hid_device *dev, datpack *data_arr, int pck_cnt)
{
    unsigned char header[DATA_PACKET_SIZE];
    struct timespec gap = {0, 1000000}; /* 1 ms between packets */
    int i;

    memset(header, 0, sizeof(header));
    header[0] = QS2S_DISPLAY_CODE;
    header[1] = QS2S_PACKET_CNT_CODE;
    header[2] = (unsigned char)pck_cnt;

    if (qs2s_xfer(dev, header) < 0) return -1;
    nanosleep(&gap, NULL);
    for (i = 0; i < pck_cnt; i++) {
        if (qs2s_xfer(dev, data_arr[i]) < 0) return -1;
        nanosleep(&gap, NULL);
    }
    return 0;
}

int main(int argc, const char **argv)
{
    struct colschemes cs;
    datpack *data_arr;
    const char *fargv[64];
    int fargc = 0, i, pck_cnt, verbose = 0, daemon_mode = 0;
    hid_device *dev;

    /* Strip our own --daemon/-d flag; forward the rest to the upstream parser
     * verbatim (so the CLI matches quadcastrgb: e.g. "solid 06b6d4 -b 40"). */
    fargv[fargc++] = argv[0];
    for (i = 1; i < argc && fargc < 63; i++) {
        if (!strcmp(argv[i], "--daemon") || !strcmp(argv[i], "-d"))
            daemon_mode = 1;
        else
            fargv[fargc++] = argv[i];
    }

    parse_arg(&cs, fargc, fargv, &verbose);
    cs.pid = QUADCAST_2S_PID;                 /* force the QS2S packet path */
    data_arr = parse_colorscheme(&cs, &pck_cnt);

    if (hid_init()) { fprintf(stderr, "hid_init failed\n"); free(data_arr); return 1; }
    dev = open_iface1();
    if (!dev) { hid_exit(); free(data_arr); return 2; }

    signal(SIGINT, on_signal);
    signal(SIGTERM, on_signal);

    if (send_sequence(dev, data_arr, pck_cnt) < 0) {
        fprintf(stderr, "Failed to send color.\n");
        hid_close(dev); hid_exit(); free(data_arr); return 3;
    }
    printf("Color sent (%d packets).\n", pck_cnt);

    if (daemon_mode) {
        struct timespec loop = {0, 40000000}; /* re-apply every 40 ms (~25 Hz) */
        printf("Daemon mode: holding color (kill / Ctrl-C to stop).\n");
        while (running) {
            nanosleep(&loop, NULL);
            if (!running) break;
            if (send_sequence(dev, data_arr, pck_cnt) < 0) {
                /* mic unplugged / went away: exit so launchd KeepAlive
                 * restarts us and we re-open the device on reconnect */
                fprintf(stderr, "Device lost; exiting for relaunch.\n");
                hid_close(dev); hid_exit(); free(data_arr);
                return 4;
            }
        }
    }

    hid_close(dev);
    hid_exit();
    free(data_arr);
    return 0;
}
