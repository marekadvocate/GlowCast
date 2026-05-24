# GlowCast — Design Spec

**Date:** 2026-05-24
**Status:** Approved (brainstorming) → planning
**Author:** Marek + Claude

## Problem

The **HyperX QuadCast 2 S** microphone (USB `03f0:02b5` controller / `03f0:0d84` mic) has RGB lighting that can only be configured via **NGENUITY on Windows**. There is no macOS software, no Mac App Store option, and the color is **not** stored in onboard memory — it reverts to default when not actively driven by software. Existing CLI tools (`Ors1mer/QuadcastRGB`) use **libusb**, which on macOS cannot claim the device's HID interface (`Access denied`, kernel owns HID).

We proved during research that:
- The device's RGB control is a **HID interface** (interface 1, vendor usage page `0xff13`).
- **HIDAPI / IOHIDManager works** where libusb fails (opened iface 1, wrote a header, got a correct `0xff` protocol response).
- The device is **live-driven**: it must be sent the color sequence continuously (~25–30 Hz). It does not persist color. The upstream tool is a continuous daemon for the same reason.
- A continuous HIDAPI daemon **successfully lights the mic cyan** (verified).
- A bare CLI binary under `launchd` is blocked by **Input Monitoring (TCC)**; a proper signed `.app` gets the correct TCC prompt and is the right vehicle.

## Goal

A native macOS **menu-bar app, "GlowCast"**, that controls the QuadCast 2 S RGB: pick any solid color, brightness, and software-driven animations (breathing, color cycle/rainbow, strobe, pulse). It runs at login, drives the mic continuously, and auto-recovers on unplug/replug.

## Non-Goals (v1)

- Mac App Store distribution (impossible: sandbox forbids this HID access).
- Device-native effect modes (the QS2S protocol exposes only solid; animations are produced by us driving frames).
- Spatial / per-LED "wave" effects (deferred to v2 — requires mapping the physical LED order).
- Support for other microphones (QuadCast S, Duocast, etc.) — only the 2 S for now.
- Multi-zone (upper/lower) independent colors (v2).

## Reverse-Engineered Protocol (the key asset)

- **Device:** VendorID `0x03f0`, ProductID `0x02b5` (the "Controller"). RGB lives on its **HID interface 1**, vendor collection **usage page `0xff13`, usage `0xff00`**.
- **Transport:** IOHIDManager. Output via `IOHIDDeviceSetReport(kIOHIDReportTypeOutput, reportID: 0, 64 bytes)`. Optional response via input report (64 bytes).
- **Refresh sequence** (sent every frame, ~30 Hz):
  1. **Header packet** (64 bytes): `0x44, 0x01, <packetCount=6>, 0x00, …zeros`.
  2. **6 data packets** (64 bytes each): `0x44, 0x02, <index 0..5>, 0x00`, then RGB triples.
- **LED layout:** 108 LEDs. Each data packet holds 20 RGB triples in bytes 4..63 (60 bytes). Packets 0–4 are full (100 LEDs); packet 5 holds 8 triples (bytes 4..27), the rest zero. For a **solid** color, all 108 triples are the same `R,G,B`.
- **Color byte order:** `R, G, B`. Cyan `#06b6d4` = `06 b6 d4`.
- **Device response:** an input report beginning `0xff` with `rsp[14]` echoing the command's first byte (`0x44`). Used for flow control; treated as best-effort.
- **Golden reference:** the exact 6×64 byte output for `solid #06b6d4` is captured (see `PacketBuilderTests`). It is the ground truth for the packet builder.

## Architecture

Pure Swift. Two SPM targets:

- **`GlowCastCore`** (library, fully unit-tested): pure logic with no hardware/UI dependencies.
  - `RGBColor` — color value, hex parse, brightness scaling.
  - `QS2SProtocol` — constants (IDs, codes, sizes).
  - `PacketBuilder` — builds the 7-packet sequence from a 108-color buffer (or a single solid color).
  - `LightingMode` + `Animator` — given mode/params and a frame clock, produces the per-frame color buffer (solid/breathing/cycle/rainbow/strobe/pulse).
  - `AppSettings` — Codable settings + UserDefaults persistence.
- **`GlowCast`** (executable → wrapped into `.app`): hardware + UI.
  - `HIDDevice` — IOHIDManager wrapper: match/open the vendor collection, send reports, connect/disconnect callbacks, surfaces `notPermitted`.
  - `DriverEngine` — 30 Hz render loop tying `Animator` → `PacketBuilder` → `HIDDevice`; idles when no device; resumes on reconnect.
  - `PermissionManager` — detects `notPermitted`, opens the Input Monitoring settings pane.
  - `LoginItemManager` — `SMAppService` register/unregister/status.
  - `GlowCastApp` (`MenuBarExtra`) + `ContentView` — the popover UI.

### Data flow

UI mutates `AppSettings` (observable) → `DriverEngine` reads settings each frame → `Animator` computes colors → `PacketBuilder` → `HIDDevice` → mic. Device connect/disconnect → `HIDDevice` state → UI status. Open failure `notPermitted` → `PermissionManager` → UI permission prompt.

## UI (menu-bar popover)

- Color picker (any color)
- Brightness slider (0–100%)
- Mode picker: Solid / Breathing / Cycle / Rainbow / Strobe / Pulse
- Speed slider (animations)
- Preset swatches (e.g., Cyan, Deep Indigo, Warm White) + "save current as preset"
- On/Off toggle (off = send black / stop driving)
- "Launch at login" toggle
- Device status ("QuadCast 2 S connected" / "not connected")
- Permission banner + "Open Input Monitoring settings" button when needed

## Permission strategy

Opening **only the vendor collection** (`0xff13/0xff00`) may avoid Input Monitoring entirely (we are not opening the pointer/keyboard collections). This is the first thing to verify. If TCC is still required, the `.app` triggers a proper prompt; `PermissionManager` provides a one-click path to the settings pane. As a signed `.app` launched in the user session (and via `SMAppService` at login), the grant attaches to the bundle and persists — unlike the bare CLI binary under `launchd`.

## Persistence reality

The mic stores nothing, so GlowCast must run to maintain color. "Launch at login" + the always-on render loop = de-facto persistence. On unplug, the IOHIDManager removal callback fires; on replug, the matching callback re-opens and driving resumes — no process restart needed (unlike the interim CLI supervisor).

## Distribution

- **Now (just me):** SPM build + `Scripts/make_app.sh` assembles `GlowCast.app` with `Info.plist` (`LSUIElement = true`) and **ad-hoc** code signing. Runs locally.
- **Later (open source):** publish to GitHub. Credit `Ors1mer/QuadcastRGB` for the protocol. License TBD at publish time (GPL-2.0 is safe given protocol knowledge derived from their GPL code; a clean-room Swift reimplementation gives more freedom — decide before publishing).

## Testing strategy

- **TDD core:** `RGBColor`, `PacketBuilder` (golden bytes), `Animator` (deterministic frame outputs), `AppSettings` (round-trip) — `swift test`.
- **Hardware boundary:** `HIDDevice` / `DriverEngine` verified manually against the real mic, with explicit checkpoints (does opening the vendor collection need Input Monitoring? does SetReport without reading responses still light it?).

## Risks / open questions (resolved during implementation)

1. **Input Monitoring needed?** Verify by opening only the vendor collection. Fallback: TCC prompt via the `.app`.
2. **Reads required?** Try write-only `SetReport`; if the device stalls/ignores, add input-report draining.
3. **LED order for v2 spatial effects** — unmapped; out of scope for v1.
