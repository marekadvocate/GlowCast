/* read-only USB descriptor dumper for HyperX QuadCast 2 S (03f0:02b5 / 03f0:0d84) */
#include <stdio.h>
#include <libusb-1.0/libusb.h>

static void dump(libusb_device *dev)
{
    struct libusb_device_descriptor d;
    struct libusb_config_descriptor *cfg;
    int i, a, e;
    libusb_get_device_descriptor(dev, &d);
    if (d.idVendor != 0x03f0) return;
    if (d.idProduct != 0x02b5 && d.idProduct != 0x0d84) return;
    printf("\n=== %04x:%04x  numConfigs=%d ===\n", d.idVendor, d.idProduct,
           d.bNumConfigurations);
    if (libusb_get_active_config_descriptor(dev, &cfg) != 0) {
        printf("  (no active config)\n");
        return;
    }
    printf("  config: numInterfaces=%d\n", cfg->bNumInterfaces);
    for (i = 0; i < cfg->bNumInterfaces; i++) {
        const struct libusb_interface *itf = &cfg->interface[i];
        for (a = 0; a < itf->num_altsetting; a++) {
            const struct libusb_interface_descriptor *id = &itf->altsetting[a];
            printf("  Iface %d alt %d: class=0x%02x sub=0x%02x proto=0x%02x EPs=%d\n",
                   id->bInterfaceNumber, id->bAlternateSetting,
                   id->bInterfaceClass, id->bInterfaceSubClass,
                   id->bInterfaceProtocol, id->bNumEndpoints);
            for (e = 0; e < id->bNumEndpoints; e++) {
                const struct libusb_endpoint_descriptor *ep = &id->endpoint[e];
                const char *dir = (ep->bEndpointAddress & 0x80) ? "IN " : "OUT";
                int type = ep->bmAttributes & 0x03;
                const char *ts = type == 0 ? "CONTROL" : type == 1 ? "ISO" :
                                 type == 2 ? "BULK" : "INTERRUPT";
                printf("      EP 0x%02x %s %-9s maxpkt=%d\n",
                       ep->bEndpointAddress, dir, ts, ep->wMaxPacketSize);
            }
        }
    }
    libusb_free_config_descriptor(cfg);
}

int main(void)
{
    libusb_device **devs;
    ssize_t n, i;
    if (libusb_init(NULL)) { fprintf(stderr, "libusb_init failed\n"); return 1; }
    n = libusb_get_device_list(NULL, &devs);
    if (n < 0) { fprintf(stderr, "get_device_list failed\n"); return 1; }
    for (i = 0; i < n; i++) dump(devs[i]);
    libusb_free_device_list(devs, 1);
    libusb_exit(NULL);
    return 0;
}
