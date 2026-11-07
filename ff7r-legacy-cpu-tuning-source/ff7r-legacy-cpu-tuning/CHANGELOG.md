# Changelog

## 1.0.0 - 2026-11-07

First public release.

- Hardware-detecting installer: writes `Engine.ini` tuned to CPU threads, GPU memory and system RAM, and backs up any existing config.
- Audio: larger mixer buffers and a full voice budget instead of muting channels.
- Streaming: texture and level loading spread across frames; pool sized to VRAM.
- Launcher: temporary performance power plan, `-USEALLAVAILABLECORES`, raised game and audio-engine priority, all reverted on exit.
- Uninstaller: restores the original `Engine.ini` and removes the power plan.
- Tested on AMD FX-8350 + Radeon RX 6600 + 32 GB DDR3 at max settings.
