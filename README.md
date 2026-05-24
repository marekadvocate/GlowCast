# GlowCast

A native macOS **menu-bar app** to control **HyperX QuadCast 2 S** RGB lighting on macOS:
solid color, brightness, software animations (breathing, cycle, rainbow, strobe, pulse, wave,
fire, police, party), and **microphone-reactive** modes that pulse with your voice / the music.

The QuadCast 2 S has no macOS software and does **not** store color in firmware, so GlowCast
drives it continuously via IOHIDManager and runs at login. Unplug/replug auto-recovers.

## Install

```bash
bash Scripts/make_app.sh
open build/GlowCast.app          # or: cp -R build/GlowCast.app /Applications/ && open /Applications/GlowCast.app
```

A `mic.fill` icon appears in the menu bar. Click it to pick color, mode, brightness, save
presets, and toggle **Launch at login**.

## How it works

- Device `03f0:02b5` (QuadCast 2 S controller). RGB is a HID **vendor collection**
  (usage page `0xff13`, usage `0xff00`) on interface 1 — matched by VID+PID then filtered
  by that usage pair (it is a *non-primary* usage, so primary-usage matching misses it).
- Each ~30 Hz frame sends a header packet `[0x44, 0x01, 6]` plus 6 data packets
  `[0x44, 0x02, idx, … 108 RGB triples]` via `IOHIDDeviceSetReport` (report id 0, 64 bytes).
- Verified on hardware: **write-only works** (no response reads needed) and **no Input
  Monitoring permission** was required for the signed `.app` opening the vendor collection.
- Animations are produced in software (the device exposes only solid mode).

## Develop

```bash
swift test     # 30 unit tests: RGBColor, PacketBuilder (golden device bytes), Animator, Settings
swift build    # build the executable
bash Scripts/make_app.sh   # bundle + ad-hoc sign GlowCast.app
```

## Screenshots

_(add a screenshot of the menu-bar popover here)_

## Notes

- macOS 13+. **Not** available on the Mac App Store (the sandbox forbids this HID access) —
  distribute as a signed/notarized direct download instead.
- Protocol reverse-engineered with help from
  [Ors1mer/QuadcastRGB](https://github.com/Ors1mer/QuadcastRGB) (GPL-2.0). Credit to Ors1mer.
- Future (v2): spatial "wave" effects across individual LEDs (needs physical LED-order mapping);
  independent upper/lower zones.

## License

MIT — see [LICENSE](LICENSE). Protocol research credit: Ors1mer/QuadcastRGB.
