# Additions

## Enhancements

- Saved search results retain their destination; clicking centers and pings it.
  [ResolveSearchBookmarkTarget](source/ui/SearchBookmarks.pas#L27), [TfPanelMain.MessageClicked](source/screens/fPanelMain.pas#L1334).
- Z/X also fire arcade weapons. [TfAB.BattleKeyDown](source/arcade/ab_MainForm.pas#L847).
- SDL provides native rendering, input, and audio; `--renderer=sdl` enables GPU
  rendering. [sr_window_open](platform/game_native.c#L107), [sr_renderer_select](platform/game_gpu.inc.c#L16).

## Bug fixes

- Prevent ship flicker near path endpoints on ARM64. [TSPath.ResampleBezierRange](source/core/aPath.pas#L431).
- Use bilinear background resizing to avoid brightness grids. [TGraphBufGR.RescaleBilinearRgba](source/graphics/GR_GraphBuf.pas#L1466).
- Close a complete temporary save before replacing its destination. [TSaver.Execute](source/game/aSaveLoad.pas#L103).
- Clamp invalid arcade portal counts. [TfAB.ABSpaceBuild](source/arcade/ab_MainForm.pas#L2077).

## Performance

- Inline RTL list operations in normal builds, with `noreturn` on the list error
  routine. Offer macOS LTO separately through `--lto`, using isolated build and
  runtime caches. [Build options](BUILDING.md).
- Reuse equipment queries during read-only calculations. [BeginStatQueryScope](source/game/aShip.pas#L914).
- Cache sequential compressed-package reads. [TPackFileEC.ReadEntrySlot](source/resources/EC_HsFile.pas#L540).
- Cache star-hover thumbnails within a turn. [TfStarMap.LoadStarThumbnail](source/screens/fStarMap.pas#L385).
- Reduce travel loading-screen waits. [TfLoad.OnOpen](source/screens/fLoad.pas#L289), [TfJump.OnOpen](source/screens/fJump.pas#L97).
- Use faster autosave compression, producing somewhat larger files. [TSaver.Execute](source/game/aSaveLoad.pas#L103).
- Use OKGF's native math on non-x86 targets and exact x87 math on x86.
  [OKGF backend selection](native/CMakeLists.txt#L8).

## Legacy cleanup

- Remove in-memory anti-tamper checks, money mirrors, module/resource fingerprints,
  and decoy state. Money and campaign metadata use ordinary fields.
  [TShip.SetMoney](source/game/aShip.pas#L2291), [TGalaxy.GetCheatPoints](source/game/aGalaxy.pas#L3988),
  [TGalaxy.CanRecordAchievements](source/game/aGalaxy.pas#L17061).
- Use readable source literals for commands and editable-state keys.
  [TGalaxy.SaveEditableState](source/game/aGalaxy.pas#L2443), [TShip.LoadFromBlock](source/game/aShip.pas#L1960).
- Keep suspension snapshots in plain memory.
  [SaveGameToMemorySnapshot](source/game/aSaveLoad.pas#L549).
- Remove unreachable scan/RSA paths, ineffective checks, and empty callbacks.
  [HandleApplicationDeactivated](source/GameApplication.pas#L86), [TPolyLineGI.PrepareFrameDraw](source/graphics/GI_PolyLine.pas#L418).

The original save layout and file codecs are retained. Legacy protection slots
remain in saves; money's encoded mirror is generated during writing.
[TGalaxy.SaveToBuffer](source/game/aGalaxy.pas#L1136), [TGalaxy.LoadFromBuffer](source/game/aGalaxy.pas#L1520),
[TShip.SaveToBuffer](source/game/aShip.pas#L1199).
DAT payload checksums still detect corrupted content, and achievement-file encoding
is unchanged. [TBlockParEC.LoadFromEncryptedDatFile](source/resources/EC_BlockPar.pas#L1498),
[LoadLocalAchievements](source/NoSteamAchievemens.pas#L51).

Saved per-object random states and algorithms are retained. The original shared
RNG also depends on runtime seeding and call order across gameplay and visuals.
Removing protection draws changes that shared sequence, including chaotic-random mode.
[RandomIntRange](source/core/aMyFunction.pas#L193), [NextRandomIntRange](source/core/aMyFunction.pas#L252).
Save-label padding is deterministic.
[EncodeLegacySaveLabel](source/core/EC_Str.pas#L1158).

## Observer

The galaxy observer adds inspection, transit trails, and playback controls.
It parks the player while advancing the simulation. [RunObserver](source/observer/ObserverHost.pas#L1508), [ParkObserverPlayer](source/observer/ObserverSimulation.pas#L32).

Wheel zooms, drag pans, click inspects, F follows, O toggles orbits, G opens the
galaxy view, Space pauses, N advances one turn, and +/- changes playback speed.
[TObserverScreen.KeyDown](source/observer/ObserverHost.pas#L1324).

## Runtime notes

- Android imports the original game directory from a ZIP. [LauncherActivity.importResources](platform/android/java/org/spacerangershd/android/LauncherActivity.java#L117).
- Mods use the original manager and resource overrides.
  [ShowModsManager](source/screens/fMods.pas#L1702), [LoadSelectedModInstallBlocks](source/GR_Main.pas#L2496).
- Achievements use local storage. [LoadLocalAchievements](source/NoSteamAchievemens.pas#L51).
- Robot battles resolve as automatic victories.
  [AutoWinRobotBattle](source/game/Robot.pas#L659).
- Intro movies and recording are disabled.
  [PrepareUserSettings](source/GameBootstrap.pas#L195), [FlushRecordingFrames](source/GR_Main.pas#L3733).
