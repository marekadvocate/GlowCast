# Contributing to GlowCast

Thanks for your interest in contributing!

## How to Build

```bash
# Run all unit tests
swift test

# Build the executable
swift build

# Bundle and ad-hoc sign the macOS app
bash Scripts/make_app.sh

# Regenerate the app icon (requires macOS with AppKit)
swift Scripts/make_icon.swift
```

## Project Layout

| Path | Purpose |
|---|---|
| `Sources/GlowCastCore/` | Tested business logic: `RGBColor`, `PacketBuilder`, `Animator`, `Settings`. No AppKit or IOKit imports — pure Swift, fully unit-tested. |
| `Sources/GlowCast/` | macOS app target: `AppModel`, `StatusBarController`, HID device layer. Depends on `GlowCastCore`. |
| `Scripts/` | Build helpers: `make_app.sh` (bundle + sign), `make_icon.swift` (icon generator), `Info.plist`. |
| `Tests/` | XCTest suites for `GlowCastCore`. |

## Pull Requests

PRs are welcome! Please:

1. Ensure `swift test` passes before opening a PR.
2. Keep `GlowCastCore` free of AppKit / IOKit imports so it stays testable.
3. Add unit tests for new protocol logic in `GlowCastCore`.

## Protocol Research Credit

The HID protocol details for the HyperX QuadCast 2 S were reverse-engineered with
reference to [Ors1mer/QuadcastRGB](https://github.com/Ors1mer/QuadcastRGB) (GPL-2.0).
GlowCast is a clean-room Swift reimplementation and is released under the MIT License.
No GPL code was copied or derived from that project; only the documented protocol
observations (packet structure, report IDs, usage page) were used as a reference.
