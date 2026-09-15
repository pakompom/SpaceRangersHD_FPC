{$EXCESSPRECISION OFF}
unit fPanelLoad;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Struct,
  GI_GAI,
  GI_Image,
  GI_Label,
  GI_MessageLoop,
  GI_Panel;
type
  TfPanelLoad = class;
  TfPanelLoad = class(TObjectEx)
    Screen: TMessageLoopGI;
    ProgressSegments: array[0..16] of TImageGI;
    LayoutAdjusted: Boolean;
    Gap4D: array[0..2] of Byte;
    BackgroundImage: TObjectGI;
    ShipPanelImage: TObjectGI;
    LoadAnimation: TObjectGI;
    AnimationText: TObjectGI;
    ProgressLabel: TLabelGI;
    ProgressBar: TObjectGI;
    BackgroundRestTop: Integer;
    ShipPanelRestTop: Integer;
    AnimationRestTop: Integer;
    AnimationTextRestTop: Integer;
    ProgressLabelRestTop: Integer;
    ProgressBarRestTop: Integer;
    ShutterTimer: PCallbackTimerGI;
    ShutterOpenFraction: Single;
    RightShutter: TPanelGI;
    LeftShutter: TPanelGI;
    TopShutter: TPanelGI;
    BottomShutter: TPanelGI;
    HasShutters: Boolean;
    Gap99: array[0..2] of Byte;
    ShutterDirection: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure InitializeLayout(Screen: TMessageLoopGI);
    procedure OnOpen;
    procedure OnClose;
    function GetProgressSegmentCount: Integer;
    procedure Show;
    procedure Hide;
    procedure SelectBackgroundStyle(StyleGroup: Integer);
    procedure RefreshBackgroundImages;
    procedure SetProgress(Fraction: Single);
    procedure SetShutterOpenFraction(Fraction: Single);
    procedure StartOpeningShutters;
    procedure StartClosingShutters;
    procedure UpdateOpeningShutters(Timer: PCallbackTimerGI; UserData: PtrInt);
    procedure UpdateClosingShutters(Timer: PCallbackTimerGI; UserData: PtrInt);
    function IsAnimatingShutters: Boolean;
    function GetShutterDirection: Integer;
  end;
var
  ActiveLoadPanel: TfPanelLoad;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  Classes,
  GR_Main,
  Globals,
  GlobalsV,
  SysUtils,
  aMyFunction,
  aPlayer;

constructor TfPanelLoad.Create;
begin
  inherited Create;
  LayoutAdjusted := False;
end;

destructor TfPanelLoad.Destroy;
begin
  inherited Destroy;
end;

procedure TfPanelLoad.InitializeLayout(Screen: TMessageLoopGI);
var
  I: Integer;
  Panel: TObjectGI;
begin
  Self.Screen := Screen;
  AppendLogTextThreadSafe('fPanelLoad... ');
  if not LayoutAdjusted then
  begin
    Panel := Self.Screen.GetByName('PanelLoad');
    Panel.SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
    with Panel.FindByNameRecursive('BGImage') do
    begin
      SetPosition(Classes.Point(LocalPosition.X, LocalPosition.Y + ExtraScreenHeight div 2));
      SetSize(Classes.Point(GameScreenWidth, ClientSize.Y));
    end;
    with Panel.FindByNameRecursive('ShipPanelImage') do
      SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
    with Panel.FindByNameRecursive('LoadAnim') as TgaiGI do
    begin
      SetPosition(
          Classes.Point(
              LocalPosition.X + ExtraScreenWidth div 2,
              LocalPosition.Y + ExtraScreenHeight div 2
          )
      );
      StopAutoPlayback;
    end;
    with Panel.FindByNameRecursive('LoadAnimText') do
      SetPosition(
          Classes.Point(
              LocalPosition.X + ExtraScreenWidth div 2,
              LocalPosition.Y + ExtraScreenHeight div 2
          )
      );
    with Panel.FindByNameRecursive('PLProgress') do
      SetPosition(
          Classes.Point(
              LocalPosition.X + ExtraScreenWidth div 2,
              LocalPosition.Y + ExtraScreenHeight div 2
          )
      );
    with Panel.FindByNameRecursive('PLBar') do
      SetActive(False);
    LayoutAdjusted := True;
  end;
  AppendLogLineThreadSafe('ok');
  for I := 0 to GetProgressSegmentCount - 1 do
  begin
    ProgressSegments[I] := Self.Screen.GetByName('PLB' + IntToStr(I + 1)) as TImageGI;
    ProgressSegments[I].SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
  end;
  BackgroundImage := Self.Screen.GetByName('BGImage');
  ShipPanelImage := Self.Screen.GetByName('ShipPanelImage');
  LoadAnimation := Self.Screen.GetByName('LoadAnim');
  AnimationText := Self.Screen.GetByName('LoadAnimText');
  ProgressLabel := Self.Screen.GetByName('PLProgress') as TLabelGI;
  ProgressBar := Self.Screen.GetByName('PLBar');
  BackgroundRestTop := BackgroundImage.LocalPosition.Y;
  ShipPanelRestTop := ShipPanelImage.LocalPosition.Y;
  AnimationRestTop := LoadAnimation.LocalPosition.Y;
  AnimationTextRestTop := AnimationText.LocalPosition.Y;
  ProgressLabelRestTop := ProgressLabel.LocalPosition.Y;
  ProgressBarRestTop := ProgressBar.LocalPosition.Y;
  RightShutter := Self.Screen.FindControlByPath('PLRight') as TPanelGI;
  LeftShutter := Self.Screen.FindControlByPath('PLLeft') as TPanelGI;
  TopShutter := Self.Screen.FindControlByPath('PLTop') as TPanelGI;
  BottomShutter := Self.Screen.FindControlByPath('PLBottom') as TPanelGI;
  HasShutters :=
      (RightShutter <> nil)
          and (LeftShutter <> nil)
          and (TopShutter <> nil)
          and (BottomShutter <> nil);
  if HasShutters then
  begin
    RightShutter.SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
    LeftShutter.SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
    TopShutter.SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
    BottomShutter.SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
    Self.Screen.GetByName('PLRightImage').SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
    Self.Screen.GetByName('PLLeftImage').SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
    Self.Screen.GetByName('PLTopImage').SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
    Self
        .Screen
        .GetByName('PLBottomImage')
        .SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
  end;
end;

procedure TfPanelLoad.OnOpen;
begin
  Hide;
  if Screen.DeferScreenPresentation then
  begin
    ActiveLoadPanel := Self;
    Exit;
  end;
  if LoadScreen.BackgroundStyle <= 0 then
    SelectBackgroundStyle(0);
  if FastTravelTransitions
      and (CurrentScreenId = screenStarMap)
      and ((PreviousScreenId = screenJump)
          or ((PreviousScreenId = screenLoad) and (ScreenLoadMode = 2))) then
  begin
    ShutterOpenFraction := 1;
    SetShutterOpenFraction(1);
    PreviousScreenId := screenNone;
    ActiveLoadPanel := Self;
    Exit;
  end;
  RefreshBackgroundImages;
  SetProgress(1);
  ShutterOpenFraction := 0;
  SetShutterOpenFraction(ShutterOpenFraction);
  if ((PreviousScreenId = screenLoad)
          and (CurrentScreenId <> screenMainMenu)
          and (CurrentScreenId <> screenGameLoad)
          and (CurrentScreenId <> screenLoadQuest))
      or ((PreviousScreenId = screenLoad) and (CurrentScreenId = screenMainMenu) and SkipVideo)
      or ((PreviousScreenId = screenGameLoad) and (CurrentScreenId <> screenLoad))
      or ((CurrentScreenId
              in [
                  screenHangar,
                  screenPlanet,
                  screenPlanetNO,
                  screenEquipmentShop,
                  screenGovernment,
                  screenRuinsTalk,
                  screenInfo])
          and (PreviousScreenId = screenStarMap)
          and (GetPlayer.RuinsMode = 0))
      or ((CurrentScreenId in [screenStarMap, screenRuinsTalk])
          and (PreviousScreenId in [screenJump, screenArcadeBattle]))
      or ((CurrentScreenId = screenArcadeBattle) and (PreviousScreenId = screenStarMap)) then
  begin
    PreviousScreenId := screenNone;
    StartOpeningShutters;
  end;
  ActiveLoadPanel := Self;
end;

procedure TfPanelLoad.OnClose;
begin
  if ActiveLoadPanel = Self then
    ActiveLoadPanel := nil;
  if ShutterTimer <> nil then
  begin
    Screen.CancelCallbackTimer(ShutterTimer);
    ShutterTimer := nil;
  end;
end;

function TfPanelLoad.GetProgressSegmentCount: Integer;
begin
  Result := 17;
end;

procedure TfPanelLoad.Show;
begin
  Screen.GetByName('PanelLoad').SetActive(True);
end;

procedure TfPanelLoad.Hide;
begin
  Screen.GetByName('PanelLoad').SetActive(False);
end;

procedure TfPanelLoad.SelectBackgroundStyle(StyleGroup: Integer);
begin
  if not HasShutters then
  begin
    if StyleGroup = 0 then
      LoadScreen.BackgroundStyle := RandomIntRange(1, 2)
    else if StyleGroup = 1 then
      LoadScreen.BackgroundStyle := RandomIntRange(3, 6)
    else if StyleGroup = 2 then
      LoadScreen.BackgroundStyle := 7
    else if StyleGroup = 3 then
      LoadScreen.BackgroundStyle := 8;
  end
  else
  begin
    if StyleGroup = 0 then
      LoadScreen.BackgroundStyle := RandomIntRange(1, 7)
    else if StyleGroup = 1 then
      LoadScreen.BackgroundStyle := RandomIntRange(8, 13)
    else if StyleGroup = 2 then
      LoadScreen.BackgroundStyle := 14
    else if StyleGroup = 3 then
      LoadScreen.BackgroundStyle := 15;
  end;
end;

procedure TfPanelLoad.RefreshBackgroundImages;
var
  Style: WideString;
begin
  if Screen.DeferScreenPresentation
      or (FastTravelTransitions
          and (((RequestedScreenId = screenLoad) and (ScreenLoadMode = 2))
              or ((RequestedScreenId = screenJump)
                  and (GetPlayer <> nil)
                  and not GetPlayer.IsDockedToShip))) then
    Exit;
  if not HasShutters then
    (BackgroundImage as TImageGI)
        .SetImagePath('GI,Bm.FormLoad2.Style' + IntToStr(LoadScreen.BackgroundStyle))
  else
  begin
    if LoadScreen.BackgroundStyle < 10 then
      Style := '0' + IntToStr(LoadScreen.BackgroundStyle)
    else
      Style := IntToStr(LoadScreen.BackgroundStyle);
    (Screen.GetByName('PLRightImage') as TImageGI)
        .SetImagePath('GI,Bm.FormLoad2.ShutterRight' + Style);
    (Screen.GetByName('PLLeftImage') as TImageGI)
        .SetImagePath('GI,Bm.FormLoad2.ShutterLeft' + Style);
    (Screen.GetByName('PLTopImage') as TImageGI).SetImagePath('GI,Bm.FormLoad2.ShutterTop' + Style);
    (Screen.GetByName('PLBottomImage') as TImageGI)
        .SetImagePath('GI,Bm.FormLoad2.ShutterBottom' + Style);
  end;
end;

procedure TfPanelLoad.SetProgress(Fraction: Single);
var
  I, LastActive: Integer;
begin
  if Screen.DeferScreenPresentation then
    Exit;
  LastActive := Round(GetProgressSegmentCount * Fraction) - 1;
  for I := 0 to LastActive do
    ProgressSegments[I].SetActive(True);
  for I := LastActive + 1 to GetProgressSegmentCount - 1 do
    ProgressSegments[I].SetActive(False);
  ProgressLabel.SetText(IntToStr(Round(Fraction * 100 + 0.5)) + '%');
  with Screen.GetByName('LoadAnim') as TgaiGI do
    SetSequenceFrame(
        Round((SequenceFrameCount - 1) * Fraction * 2 + 3) mod (SequenceFrameCount - 1)
    );
end;

procedure TfPanelLoad.SetShutterOpenFraction(Fraction: Single);
begin
  if not HasShutters then
    Exit;
  LeftShutter.SetPosition(
      Classes
          .Point(-Round(Cardinal(GameScreenWidth) * Fraction * 0.34), LeftShutter.LocalPosition.Y)
  );
  RightShutter.SetPosition(
      Classes
          .Point(Round(Cardinal(GameScreenWidth) * Fraction * 0.34), RightShutter.LocalPosition.Y)
  );
  TopShutter.SetPosition(
      Classes
          .Point(TopShutter.LocalPosition.X, -Round(Cardinal(GameScreenHeight) * Fraction * 0.61))
  );
  BottomShutter.SetPosition(
      Classes
          .Point(BottomShutter.LocalPosition.X, Round(Cardinal(GameScreenHeight) * Fraction * 0.39))
  );
end;

procedure TfPanelLoad.StartOpeningShutters;
begin
  if AnimChangeForm and HasShutters then
  begin

    Show;
    if ShutterTimer <> nil then
    begin
      Screen.CancelCallbackTimer(ShutterTimer);
      ShutterTimer := nil;
    end;
    ShutterTimer := Screen.ScheduleCallbackTimer(17, 17, UpdateOpeningShutters);
    ShutterDirection := 1;
    Exit;
  end;
  Hide;
end;

procedure TfPanelLoad.StartClosingShutters;
begin
  if FastTravelTransitions
      and (((RequestedScreenId = screenLoad) and (ScreenLoadMode = 2))
          or ((RequestedScreenId = screenJump)
              and (GetPlayer <> nil)
              and not GetPlayer.IsDockedToShip)) then
  begin
    Screen.RequestClose(1);
    Exit;
  end;
  if AnimChangeForm and HasShutters then
  begin

    Show;
    SetProgress(0);
    ShutterOpenFraction := 1;
    SetShutterOpenFraction(ShutterOpenFraction);
    if ShutterTimer <> nil then
    begin
      Screen.CancelCallbackTimer(ShutterTimer);
      ShutterTimer := nil;
    end;
    ShutterTimer := Screen.ScheduleCallbackTimer(17, 17, UpdateClosingShutters);
    ShutterDirection := -1;
    Exit;
  end;
  Screen.RequestClose(1);
end;

procedure TfPanelLoad.UpdateOpeningShutters(Timer: PCallbackTimerGI; UserData: PtrInt);
begin
  ShutterOpenFraction := 0.03 + ShutterOpenFraction;
  if ShutterOpenFraction >= 1 then
  begin
    ShutterOpenFraction := 1;
    if ShutterTimer <> nil then
    begin
      Screen.CancelCallbackTimer(ShutterTimer);
      ShutterTimer := nil;
    end;

    Hide;
    SetShutterOpenFraction(ShutterOpenFraction);
    Screen.Present;
  end
  else
    SetShutterOpenFraction(ShutterOpenFraction);
end;

procedure TfPanelLoad.UpdateClosingShutters(Timer: PCallbackTimerGI; UserData: PtrInt);
begin
  ShutterOpenFraction := ShutterOpenFraction - 0.03;
  if ShutterOpenFraction <= -0.025 then
  begin
    ShutterOpenFraction := 0;
    if ShutterTimer <> nil then
    begin
      Screen.CancelCallbackTimer(ShutterTimer);
      ShutterTimer := nil;
    end;
    SetShutterOpenFraction(ShutterOpenFraction);
    Screen.Present;

    Screen.RequestClose(1);
  end
  else if ShutterOpenFraction <= 0 then
    SetShutterOpenFraction(0)
  else
    SetShutterOpenFraction(ShutterOpenFraction);
end;

function TfPanelLoad.IsAnimatingShutters: Boolean;
begin
  Result := ShutterTimer <> nil;
end;

function TfPanelLoad.GetShutterDirection: Integer;
begin
  if ShutterTimer = nil then
    Result := 0
  else
    Result := ShutterDirection;
end;

procedure LinkRecoveredTypes;
begin
  TImageGI.ClassName;
  TLabelGI.ClassName;
  TPanelGI.ClassName;
  TgaiGI.ClassName;
end;
end.
