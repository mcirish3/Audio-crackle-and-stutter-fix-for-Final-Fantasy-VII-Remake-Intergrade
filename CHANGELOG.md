# Changelog

## 1.1.0 - 2026-11-12

- **Starts from Steam's Play button.** The installer adds the launcher to the game's Steam launch options (Steam is closed for a moment while that's saved; your own options are kept). No separate "Play" batch file, extra window or admin prompt.
- The launcher runs hidden and logs to `%LOCALAPPDATA%\SmoothMidgar\launcher.log`.
- Windows audio engine priority is raised only when Steam runs as admin; everything else works without admin.
- If a previous session ended without restoring (crash, power cut), the next launch restores the right power plan instead of keeping the tuning plan.
- Uninstaller no longer needs admin, and also removes the Steam launch option.
- Epic Games Store: new `Epic Games - Play FF7R.bat`.
- `3 - Uninstall.bat` is now `2 - Uninstall.bat`.

## 1.0.0 - 2026-11-07

First public release.

- Hardware-detecting installer: writes `Engine.ini` tuned to CPU threads, GPU memory and system RAM, and backs up any existing config.
- Audio: larger mixer buffers and a full voice budget instead of muting channels.
- Streaming: texture and level loading spread across frames; pool sized to VRAM.
- Launcher: temporary performance power plan, `-USEALLAVAILABLECORES`, raised game and audio-engine priority, all reverted on exit.
- Uninstaller: restores the original `Engine.ini` and removes the power plan.
- Tested on AMD FX-8350 + Radeon RX 6600 + 32 GB DDR3 at max settings.
