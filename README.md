# FF7R Legacy CPU Tuning

**Audio crackle and stutter fix for *Final Fantasy VII Remake Intergrade* on older CPUs, with no visual downgrade.**

Built for PCs at or near the game's minimum CPU spec, especially the AMD FX family (FX-4300, FX-6300, FX-8320/8350, FX-9590), and also Phenom II and early Intel quad-cores, often paired with a newer graphics card. On these machines the game runs at high settings but suffers two problems:

- **Crackling, static or popping audio.** The common fix (`au.SetAudioChannelCount 0`) silences it by muting footsteps, fire, crowds and ambience.
- **Hitches and stutter** in busy areas such as the Sector 7 slums and Wall Market.

Both come from the CPU, not the graphics card. When an older CPU is maxed out, the game's audio mixer misses its deadlines (crackle), and asset loading arrives in bursts (hitches). This mod fixes the scheduling instead of lowering what the game draws.

## What it does

**Engine config** (`Engine.ini`, generated for your hardware):
- Larger, deeper audio mixer buffers and a full voice budget, so nothing is muted.
- Audio decode workers matched to your CPU thread count.
- Texture and level streaming spread across frames (based on ComplexRobot's stutter fix), with the pool sized to your VRAM and the I/O cache sized to your RAM.
- Dynamic resolution off, because on a CPU-limited PC it blurs the image without saving the frame.

**Launcher** (applied only while the game runs, reverted on exit):
- A temporary power plan that keeps the CPU at full clock with all cores awake, and turns off PCIe and USB power saving.
- Starts the game with `-USEALLAVAILABLECORES`.
- Game priority set to Above Normal, and Windows' audio engine (`audiodg.exe`) set to High.

## Requirements

- *Final Fantasy VII Remake Intergrade* on PC (Steam; Epic works with `-NoLaunch`)
- [FFVIIHook](https://www.nexusmods.com/finalfantasy7remake/mods/74) by emoose. Without it the game ignores `Engine.ini`.
- Windows 10 or 11

## Install

1. Install FFVIIHook: put `xinput1_3.dll` next to `ff7remake_.exe` in `End\Binaries\Win64`.
2. Download the zip from [Releases](../../releases) or [Nexus Mods](https://www.nexusmods.com/finalfantasy7remake/mods/2275) and extract it anywhere, for example your desktop.
3. Run **`1 - Install (run once).bat`**. It detects your hardware, backs up any existing `Engine.ini` and writes the tuned one.
4. From now on, start the game with **`2 - Play FF7R.bat`** and approve the admin prompt. Keep its window open while you play.

**Epic Games Store:** run `2 - Play FF7R.bat -NoLaunch` from a command prompt, then start the game from Epic.

**Uninstall:** run **`3 - Uninstall.bat`**. It restores your original `Engine.ini` and removes the power plan.

## Tuning

Open `Documents\My Games\FINAL FANTASY VII REMAKE\Saved\Config\WindowsNoEditor\Engine.ini`.

| Problem | Change |
|---|---|
| Sounds missing | Raise `AudioMaxChannels` by 4 (max 48) |
| Crackle remains | Set `AudioCallbackBufferFrameSize=3072`, or lower `AudioMaxChannels` by 4 |
| Late-loading textures | Lower `r.Streaming.PoolSize` by 500 |

Test audio live in the `~` console with `au.SetAudioChannelCount <n>`.

Installer overrides: `"1 - Install (run once).bat" -VramGB 8 -Threads 8`

## How values are chosen

| Detected | Value |
|---|---|
| 4 threads or fewer | 28 channels, 3072-frame buffer, 2 workers |
| 5-6 threads | 30 channels, 2048-frame buffer, 3 workers |
| 7+ threads | 32 channels, 2048-frame buffer, 4 workers |
| VRAM 4 / 6 / 8 / 10-11 / 12+ GB | Pool 1000 / 1800 / 2850 / 4500 / 5700 MB |
| RAM 16 GB+ | I/O cache 512 MB (otherwise 256) |

## Repository layout

```
src/scripts/     Installer, launcher, uninstaller, Engine.ini template
src/launchers/   The three .bat files users double-click
src/README.txt   Readme shipped inside the download
nexus/           Nexus Mods listing text (BBCode) and listing details
build.sh         Builds the release zip into dist/
```

Build locally: `./build.sh` produces `dist/FF7R-Legacy-CPU-Tuning-v<version>.zip`.

Publish a release: bump `VERSION` (and the matching version in `Install-FF7RTuning.ps1` and `src/README.txt`), add a `CHANGELOG.md` section, then run **Actions → release → Run workflow**. It builds the zip and publishes the GitHub release.

## Credits

- **emoose**: [FFVIIHook](https://www.nexusmods.com/finalfantasy7remake/mods/74), which makes `Engine.ini` work at all.
- **ComplexRobot**: [streaming stutter fix](https://www.nexusmods.com/finalfantasy7remake/mods/139), the basis of the streaming values.
- Steam community members who identified the audio channel-count workaround.

## License

MIT. See [LICENSE](LICENSE).
