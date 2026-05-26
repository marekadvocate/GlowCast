/* diagnostic: can libusb claim the HID interfaces of the QuadCast 2 S controller on macOS? */
#include <stdio.h>
#include <libusb-1.0/libusb.h>

int main(void)
{
    int r, i;
    libusb_device_handle *h;
    libusb_init(NULL);
    h = libusb_open_device_with_vid_pid(NULL, 0x03f0, 0x02b5);
    if (!h) {
        printf("open 03f0:02b5 FAILED (maybe needs sudo, or busy)\n");
        libusb_exit(NULL);
        return 1;
    }
    printf("opened 03f0:02b5 OK\n");
    r = libusb_set_auto_detach_kernel_driver(h, 1);
    printf("set_auto_detach_kernel_driver -> %d (%s)\n", r, libusb_strerror(r));
    for (i = 0; i < 3; i++) {
        int act = libusb_kernel_driver_active(h, i);
        int c = libusb_claim_interface(h, i);
        printf("iface %d: kernel_driver_active=%d (%s)  claim=%d (%s)\n",
               i, act, (act < 0 ? libusb_strerror(act) : "ok-or-0"),
               c, libusb_strerror(c));
        if (c == 0) libusb_release_interface(h, i);
    }
    libusb_close(h);
    libusb_exit(NULL);
    return 0;
}
