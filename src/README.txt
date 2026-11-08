FF7R LEGACY CPU TUNING  v1.0.0
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
   Engine.ini, and writes a tuned one.
3. From now on, start the game with  "2 - Play FF7R.bat"
   Approve the admin prompt and leave its window open while you play.
   It reverts everything automatically when the game closes.

Epic Games Store: open a command prompt in this folder and run
   "2 - Play FF7R.bat" -NoLaunch
then start the game from Epic.

------------------------------------------------------------------
UNINSTALL
------------------------------------------------------------------
Double-click  "3 - Uninstall.bat"
Restores your original Engine.ini and removes the power plan.

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
- Game priority Above Normal, Windows audio engine priority High

------------------------------------------------------------------
CREDITS
------------------------------------------------------------------
emoose          FFVIIHook
ComplexRobot    Streaming stutter fix (basis of the streaming values)
Steam community The audio channel-count workaround

Source: https://github.com/mcirish3/ff7r-legacy-cpu-tuning
License: MIT
