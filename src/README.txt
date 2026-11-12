SMOOTH MIDGAR (FF7R Legacy CPU Tuning)  v1.1.0
Audio crackle and stutter fix for Final Fantasy VII Remake Intergrade
on older CPUs (AMD FX, Phenom II, early Intel quad-cores).
No visual settings are lowered.

------------------------------------------------------------------
REQUIREMENT
------------------------------------------------------------------
FFVIIHook by emoose (Nexus Mods, FF7 Remake mod 74).
Put xinput1_3.dll next to ff7remake_.exe in:
  ...\FINAL FANTASY VII REMAKE\End\Binaries\Win64
Without it the game ignores Engine.ini.

------------------------------------------------------------------
INSTALL
------------------------------------------------------------------
1. Extract this folder anywhere (your desktop is fine).
2. Double-click  "1 - Install (run once).bat"
   It detects your CPU, graphics memory and RAM, backs up any existing
   Engine.ini, and writes a tuned one. Then it closes Steam for a moment,
   adds the launcher to the game's Steam launch options (your own options
   are kept) and restarts Steam.
3. Press Play in Steam as usual. The tuning starts and stops with the
   game. No extra window, no admin prompt.
   Log of what it did: %LOCALAPPDATA%\SmoothMidgar\launcher.log

Updating from 1.0.0: run the new installer, then delete the old folder.

Epic Games Store: double-click  "Epic Games - Play FF7R.bat",
approve the admin prompt, then start the game from Epic and keep that
window open while you play.

------------------------------------------------------------------
UNINSTALL
------------------------------------------------------------------
Double-click  "2 - Uninstall.bat"
Restores your original Engine.ini, removes the power plan, and takes
the launcher out of the game's Steam launch options.

------------------------------------------------------------------
FINE-TUNING
------------------------------------------------------------------
File: Documents\My Games\FINAL FANTASY VII REMAKE\Saved\Config\
      WindowsNoEditor\Engine.ini

  Sounds missing        raise AudioMaxChannels by 4 (max 48)
  Crackle remains       AudioCallbackBufferFrameSize=3072,
                        or lower AudioMaxChannels by 4
  Textures load late    lower r.Streaming.PoolSize by 500

Test audio live in the ~ console:  au.SetAudioChannelCount 28

------------------------------------------------------------------
WHAT THE LAUNCHER CHANGES (only while the game runs)
------------------------------------------------------------------
- Temporary power plan: CPU at full clock, no core parking,
  PCIe and USB power saving off
- Game started with -USEALLAVAILABLECORES
- Game priority Above Normal
- Windows audio engine priority High, only if Steam runs as admin
  (otherwise skipped; the Engine.ini audio fixes still apply)

------------------------------------------------------------------
CREDITS
------------------------------------------------------------------
emoose          FFVIIHook
ComplexRobot    Streaming stutter fix (basis of the streaming values)
Steam community The audio channel-count workaround

Source: https://github.com/mcirish3/Audio-crackle-and-stutter-fix-for-Final-Fantasy-VII-Remake-Intergrade
License: MIT
