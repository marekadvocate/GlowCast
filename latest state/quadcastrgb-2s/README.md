# quadcastrgb-2s — research artifacts

These are the five small C programs written during the reverse-engineering session that produced **GlowCast**. They are the evidence trail of "why does this approach work and why doesn't the obvious one." Kept here as a historical archive of the protocol/HID dig.

> They were built against a local clone of [Ors1mer/QuadcastRGB](https://github.com/Ors1mer/QuadcastRGB) (GPL-2.0). `quadcast_hid.c` includes upstream headers (`modules/argparser.h`, `modules/rgbmodes.h`), so to recompile that one you need to drop these files into a checkout of that repo. The other four are standalone.

## The story in five files

### 1. `enum_usb.c` — what does the device actually expose?
Walks IOKit USB descriptors and prints every interface + endpoint of the QuadCast 2 S controller (`03f0:02b5`) and mic (`03f0:0d84`). Result: the controller has three HID-class interfaces; interface 1 is the one with interrupt EP `0x06 OUT` / `0x85 IN` (the RGB channel).

### 2. `claimtest.c` — can libusb even open this on macOS?
Tries `libusb_claim_interface` on all three interfaces of the controller. Result on macOS:

```
iface 0: kernel_driver_active=1   claim=-3 (Access denied)
iface 1: kernel_driver_active=1   claim=-3 (Access denied)
iface 2: kernel_driver_active=1   claim=-3 (Access denied)
```

The conclusive proof that the existing `quadcastrgb` tool can never work on macOS as written — `IOHIDFamily` owns the HID interfaces and libusb's `auto_detach_kernel_driver` is a no-op for HID on macOS. **Forced the pivot to HIDAPI / IOHIDManager.**

### 3. `hid_probe.c` — does HIDAPI/IOHIDManager work?
Opens interface 1 via `hid_open_path`, sends the QS2S header packet (`0x44 0x01 0x06`) and reads the response. Result:

```
OPEN OK (this is what libusb could NOT do)
hid_write header -> 65 bytes OK
hid_read -> 64
response: ff 01 00 ... 44 01
  rsp[0]=0xff  rsp[14]=0x44      ✓ matches the QS2S response protocol
```

This was the moment we knew the project was viable on macOS.

### 4. `dump_packets.c` — show me the exact bytes the device wants
Runs the upstream `parse_arg` + `parse_colorscheme` for `solid 06b6d4` and dumps the 6×64 byte buffer the driver would send. Output proved the QS2S packet structure:

- Header: `44 02 <idx> 00` + 60 bytes of RGB triples
- Packets 0–4: full (20 triples = 60 bytes each = 100 LEDs)
- Packet 5: 8 cyan triples (bytes 4..27) then zeros (108 LEDs total)
- Color byte order: **R, G, B**

These exact bytes became the **golden-test fixtures** in `Tests/GlowCastCoreTests/PacketBuilderTests.swift` — the Swift `PacketBuilder` is verified bit-for-bit against the real device's expectation.

### 5. `quadcast_hid.c` — the working C proof-of-concept
The first program that **actually lit the mic cyan on macOS**. Reuses the upstream packet generator (`argparser.c` + `rgbmodes.c`) and only replaces the transport with HIDAPI. The "Color sent" daemon that confirmed the entire pipeline before the Swift port.

This established four facts that all carried into GlowCast:
- HIDAPI's write-only `SetReport` is enough — input reports never need draining.
- The mic is live-driven (no firmware persistence), so the daemon must keep running.
- Per-LED 30 Hz refresh holds the color smoothly (no flicker).
- Unplug → daemon exits → launchd-style supervisor (or in-process IOHIDManager callbacks) reconnects.

## Why these aren't in the main `Sources/` tree

GlowCast's Swift code is a **clean-room reimplementation** of the protocol (MIT) and never `#include`s any GPL source. These C files were the scaffolding — they referenced upstream headers and are GPL-2.0-by-inheritance for `quadcast_hid.c`. They live here as a separate historical/reference subfolder.

## Upstream

- Protocol research: https://github.com/Ors1mer/QuadcastRGB (GPL-2.0)
- The 2 S support issue these files were filed against: https://github.com/Ors1mer/QuadcastRGB/issues/18
