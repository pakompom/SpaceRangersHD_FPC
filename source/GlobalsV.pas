{$EXCESSPRECISION OFF}
unit GlobalsV;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes;
type
  TSpaceImageTemplate = record
    Kind: Integer;
    Weight: Integer;
    CacheControl: TObject;
    CachedData: TObject;
  end;
  TStarFieldImageTemplate = record
    Reserved: Integer;
    Weight: Integer;
    CacheControl: TObject;
    CachedData: TObject;
  end;
  {$Z1}
  TGameScreenId = (
      screenNone = 0,
      screenMainMenu = 1,
      screenIntroduction = 3,
      screenHangar = 4,
      screenPlanet = 5,
      screenPlanetNO = 6,
      screenPlanetQuest = 7,
      screenEquipmentShop = 8,
      screenShip = 10,
      screenTalk = 11,
      screenScanner = 12,
      screenGovernment = 15,
      screenStarMap = 16,
      screenFilm = 17,
      screenGalaxy = 18,
      screenJump = 19,
      screenRuinsTalk = 20,
      screenArcadeBattle = 21,
      screenLoad = 22,
      screenSaveManager = 23,
      screenGameLoad = 24,
      screenGameMenu = 25,
      screenSettings = 26,
      screenGameEnd = 27,
      screenInfo = 28,
      screenRewards = 30,
      screenAbout = 31,
      screenScores = 32,
      screenNewGame = 33,
      screenGoodsShop = 34,
      screenRating = 35,
      screenSelectFace = 36,
      screenJournal = 37,
      screenLoadRobot = 38,
      screenLoadQuest = 39,
      screenLoadArcade = 40,
      screenAchievements = 41
  );
  {$Z4}
  TGalaxyMapFontChoice = (
      gmfRanger = 1,
      gmfMini = 2,
      gmfSmall = 3,
      gmfSmallBold = 4,
      gmfNormal = 5,
      gmfNormalBold = 6
  );
  TGameScreenTable = array[0..41] of TObject;
var
  DumpLoadedConfig: Boolean = False;
  HalfGovAnim: Boolean = False;
  QuestStyleIndex: Integer = 0;
  QuestPageAnimationEnabled: Boolean = True;
  DefaultOrder: Integer = 0;
  RightClickOnShip: Integer = 0;
  EstOptionEnabled: Boolean = False;
  SendRecordOff: Boolean = False;
  ChangeAutoPilot: Integer = 4;
  DisableAutoPilot: Boolean = False;
  SkipGiper: Boolean = False;
  Wind: Integer = 2;
  PendingQuestName: WideString = 'Prison';
  RegisteredScreens: TGameScreenTable;
  SkipSavedPixelRestore: Boolean;
  HardwareRenderingRequested: Boolean;
  HardwareRenderingEnabled: Boolean;
  RunningUnderWine: Boolean;
  ScaleViewportToWindow: Boolean;
  UseTablesForGov: Boolean;
  RangerFontName: WideString;
  MiniFontName: WideString;
  SmallFontName: WideString;
  SmallBoldFontName: WideString;
  NormalFontName: WideString;
  NormalBoldFontName: WideString;
  BigFontName: WideString;
  HugeFontName: WideString;
  IntroFontName: WideString;
  AuthorsFontName: WideString;
  SmoothSmallFontName: WideString;
  SmoothSmallBoldFontName: WideString;
  SmoothNormalFontName: WideString;
  SmoothNormalBoldFontName: WideString;
  SmoothBigFontName: WideString;
  SmoothHugeFontName: WideString;
  SmoothIntroFontName: WideString;
  PendingLoadFileName: AnsiString;
  LoadedFilmCount: Integer;
  GameEndReason: Integer;
  ShipTail: Integer = 0;
  ThreeDimensionalModeEnabled: Boolean = False;
  AnimCaptain: Boolean = False;
  AnimItem: Boolean = False;
  Comet: Integer = 1;
  BGImage: Boolean = False;
  AnimShipFull: Boolean = False;
  AnimCity: Boolean = False;
  AnimMenuShip: Boolean = True;
  AnimGov: Integer = 2;
  AnimStar: Boolean = True;
  AnimHangar: Boolean = True;
  CircleAction: Boolean = True;
  StaticBackground: Boolean = True;
  ScrollTime: Integer = 20;
  ScrollStep: Integer = 5;
  ScrollSense: Integer = 1;
  FilmSpeed: Integer = 1;
  BGOCount: Integer = 50;
  BGOTime: Integer = 300;
  SpaceImage: Integer = 0;
  SoundEnabled: Boolean = False;
  SoundInSpaceEnabled: Boolean = False;
  SoundVolume: Single = 1.0;
  RobotSoundVolume: Single = 1.0;
  MusicEnabled: Boolean = False;
  MusicInSpaceEnabled: Boolean = False;
  MusicInHyperEnabled: Boolean = True;
  MusicInPlanetEnabled: Boolean = True;
  MusicVolume: Single = 0.75;
  MusicVolumeScale: Single = 1.0;
  RobotMusicVolume: Single = 0.75;
  MaxFilmStepSkip: Integer = 3;
  FilmHistoryLimit: Integer = 1;
  BeginCalcNextTurn: Single = 1.0;
  DoNotChangeMusicInBattle: Boolean = False;
  ViewFollowShip: Boolean = True;
  ActionDoubleClick: Boolean = True;
  GalaxyMapFontChoice: TGalaxyMapFontChoice = gmfNormalBold;
  FontQuest: Integer = 0;
  FontDialog: Integer = 0;
  FontSmoothingEnabled: Boolean = False;
  ScreenshotFormat: Integer = 1;
  ScreenshotJpegQuality: Integer = 85;
  DynamicTipsPos: Boolean = True;
  ViewPathLength: Boolean = False;
  AfterburnerStopCondition: Integer = 35;
  TurnSaveStep: Integer = 0;
  QuickSaveExtraSlots: Integer = 0;
  MaxPlayerNews: Integer = 30;
  MaxSearchResult: Integer = 100;
  ClickAutoCloseForm: Boolean = True;
  UiRuntimeFlag: Boolean = False;
  MultiThreadEnabled: Boolean = False;
  ShowWineWarning: Boolean = False;
  XonarSoundDevice: Boolean = False;
  ShowXonarWarning: Boolean = False;
  PlanetDepth: Single = 0;
  ShipPathDepth: Single = 15.0;
  ShipPathEndDepth: Single = 14.0;
  UnitPathDepth: Single = 13.0;
  UnitPathEndDepth: Single = 12.0;
  ActionButtonDepth: Single = 9.0;
  GalaxyStarDepth: Single = 20.0;
  GalaxyStarNameDepth: Single = 19.0;
  GalaxyWarDepth: Single = 18.0;
  ConstellationLineDepth: Single = 21.0;
  ConstellationColorDepth: Single = 22.0;
  MemorySnapshotActive: Boolean = False;
  PreviousScreenId: TGameScreenId = screenNone;
  CurrentScreenId: TGameScreenId = screenNone;
  RequestedScreenId: TGameScreenId = screenNone;
  PostLoadScreenId: TGameScreenId = screenNone;
  ShipReturnScreenId: TGameScreenId = screenNone;
  TalkReturnScreenId: TGameScreenId = screenNone;
  ScannerReturnScreenId: TGameScreenId = screenNone;
  QuestReturnScreenId: TGameScreenId = screenNone;
  Screen13ReturnScreenId: TGameScreenId = screenNone;
  GalaxyReturnScreenId: TGameScreenId = screenNone;
  SaveManagerReturnScreenId: TGameScreenId = screenNone;
  GameMenuReturnScreenId: TGameScreenId = screenNone;
  SettingsReturnScreenId: TGameScreenId = screenNone;
  AchievementsReturnScreenId: TGameScreenId = screenNone;
  LoadedSaveVersion: Integer = 0;
  LoadingFilmCount: Integer = -1;
  BackgroundShade: Boolean = False;
  BackgroundBlur: Boolean = False;
  BackgroundGrayscale: Boolean = False;
  PlanetClouds: Boolean = True;
  PlanetAtm: Boolean = True;
  AnimChangeForm: Boolean = True;
  AnimMainFon: Boolean = True;
  SputnikShow: Boolean = True;
  SatelliteLightMapPath: WideString = 'Bm.Planet.S.Light094';
  SatelliteTemplateParameter1: Integer = 128;
  SatelliteTemplateParameter2: Integer = 60;
  MinimumSatelliteTemplateRadius: Integer = 10;
  GeneratedSatelliteBaseRadius: Integer = 13;
  MaximumSatelliteTemplateRadius: Integer = 60;
  SatelliteRenderTemplates: TList = nil;
  SpaceImageTemplates: array of TSpaceImageTemplate = nil;
  StarFieldImageTemplates: array of TStarFieldImageTemplate = nil;
  ForcedPlanetQuestId: Integer = -1;
function FormToId(Screen: TObject): TGameScreenId;
function GetRegisteredScreenLoop(ScreenId: TGameScreenId): TObject;
function IsSpaceBackdropScreen(ScreenId: TGameScreenId): Boolean;
function ScreenUsesCompositeLoadAssets(ScreenId: TGameScreenId): Boolean;
implementation
uses
  Math,
  SysUtils;
// @unit-initialization $87671C
// @unit-finalization $45EA2C

function FormToId(Screen: TObject): TGameScreenId;
var
  Id: TGameScreenId;
begin
  Id := screenNone;
  repeat
    if RegisteredScreens[Ord(Id)] = Screen then
    begin
      Result := Id;
      Exit;
    end;
    Inc(Id);
  until Id = TGameScreenId(42);
  raise Exception.Create('FormToId');
end;

function GetRegisteredScreenLoop(ScreenId: TGameScreenId): TObject;
begin
  Result := RegisteredScreens[Ord(ScreenId)];
end;

function IsSpaceBackdropScreen(ScreenId: TGameScreenId): Boolean;
begin
  Result :=
      (ScreenId = screenStarMap)
          or (ScreenId = screenGalaxy)
          or (ScreenId = screenFilm)
          or (ScreenId = screenTalk);
end;

function ScreenUsesCompositeLoadAssets(ScreenId: TGameScreenId): Boolean;
begin
  Result := False;
  if IsSpaceBackdropScreen(ScreenId) then
  begin
    Result := True;
    Exit;
  end;
  if (ScreenId = screenLoad) and IsSpaceBackdropScreen(PostLoadScreenId) then
  begin
    Result := True;
    Exit;
  end;
  if (ScreenId = screenShip) and IsSpaceBackdropScreen(ShipReturnScreenId) then
  begin
    Result := True;
    Exit;
  end;
  if (ScreenId = screenScanner) and IsSpaceBackdropScreen(ScannerReturnScreenId) then
  begin
    Result := True;
    Exit;
  end;
  if (ScreenId = TGameScreenId(13)) and IsSpaceBackdropScreen(Screen13ReturnScreenId) then
  begin
    Result := True;
    Exit;
  end;
  if (ScreenId = screenSaveManager) and IsSpaceBackdropScreen(SaveManagerReturnScreenId) then
  begin
    Result := True;
    Exit;
  end;
  if (ScreenId = screenGameMenu) and IsSpaceBackdropScreen(GameMenuReturnScreenId) then
  begin
    Result := True;
    Exit;
  end;
  if (ScreenId = screenSettings) and IsSpaceBackdropScreen(SettingsReturnScreenId) then
  begin
    Result := True;
    Exit;
  end;
  if (ScreenId = screenSettings)
      and (SettingsReturnScreenId = screenGameMenu)
      and IsSpaceBackdropScreen(GameMenuReturnScreenId) then
    Result := True;
end;

end.
