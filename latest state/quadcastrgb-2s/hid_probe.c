/* HIDAPI probe: can we open interface 1 of the QuadCast 2 S controller (03f0:02b5)
 * on macOS and do a write + read, where libusb got Access denied? */
#include <stdio.h>
#include <string.h>
#include <wchar.h>
#include <hidapi/hidapi.h>

#define VID 0x03f0
#define PID 0x02b5
#define RPT 64

int main(void)
{
    struct hid_device_info *devs, *cur;
    char target_path[1024] = {0};
    hid_device *dev;
    unsigned char buf[1 + RPT];
    unsigned char rsp[RPT];
    int w, r, i;

    if (hid_init()) { printf("hid_init failed\n"); return 1; }

    devs = hid_enumerate(VID, PID);
    printf("=== HID interfaces for %04x:%04x ===\n", VID, PID);
    for (cur = devs; cur; cur = cur->next) {
        printf("  iface=%d  usage_page=0x%04hx  usage=0x%04hx\n    path=%s\n",
               cur->interface_number, cur->usage_page, cur->usage, cur->path);
        if (cur->interface_number == 1 && !target_path[0])
            strncpy(target_path, cur->path, sizeof(target_path) - 1);
    }
    hid_free_enumeration(devs);

    if (!target_path[0]) {
        printf("\n!! interface 1 not found by interface_number; cannot continue\n");
        hid_exit();
        return 2;
    }

    printf("\nopening interface 1...\n");
    dev = hid_open_path(target_path);
    if (!dev) {
        printf("!! hid_open_path FAILED: %ls\n", hid_error(NULL));
        hid_exit();
        return 3;
    }
    printf("OPEN OK (this is what libusb could NOT do)\n");

    /* QS2S header packet: [0x44][0x01][pck_cnt=6] then zeros */
    memset(buf, 0, sizeof(buf));
    buf[0] = 0x00;  /* report id (0 = none) */
    buf[1] = 0x44;  /* QS2S_DISPLAY_CODE */
    buf[2] = 0x01;  /* QS2S_PACKET_CNT_CODE */
    buf[3] = 0x06;  /* pck_cnt */
    w = hid_write(dev, buf, sizeof(buf));
    if (w < 0)
        printf("hid_write header -> %d  ERROR: %ls\n", w, hid_error(dev));
    else
        printf("hid_write header -> %d bytes OK\n", w);

    memset(rsp, 0, sizeof(rsp));
    r = hid_read_timeout(dev, rsp, sizeof(rsp), 1000);
    printf("hid_read_timeout -> %d\n", r);
    if (r > 0) {
        printf("  response: ");
        for (i = 0; i < r && i < 16; i++) printf("%02x ", rsp[i]);
        printf("\n  rsp[0]=0x%02x (QS2S expects 0xff), rsp[14]=0x%02x (expects 0x44)\n",
               rsp[0], rsp[14]);
    } else if (r == 0) {
        printf("  (no response within timeout)\n");
    } else {
        printf("  read error: %ls\n", hid_error(dev));
    }

    hid_close(dev);
    hid_exit();
    return 0;
}
