{$EXCESSPRECISION OFF}
unit fSelectFace;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  GI_MessageLoop,
  Types;
type
  TfSelectFace = class;
  TfSelectFace = class(TMessageLoopGI)
    PlayerRace: Byte;
    GapD1: array[0..2] of Byte;
    CaptainPortraitIndex: Integer;
    LastPortraitByRace: array[0..4] of Integer;
    PlayerName: WideString;
    PlayerNameEdited: Boolean;
    GapF1: array[0..2] of Byte;
    NationalityCosts: array[0..4] of Integer;
    AvailableMoney: Integer;
    AcceptedCost: Integer;
    procedure OnOpen; override;
    procedure OnClose; override;
    procedure ProcessCallbackTimers; override;
    procedure SelectMusic; override;
    procedure InitializeLayout; override;
    procedure PlayerNameMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
    procedure RefreshPortrait;
    procedure PreviousPortraitClicked(Sender: TObjectGI);
    procedure NextPortraitClicked(Sender: TObjectGI);
    procedure SelectRace(Sender: TObjectGI);
    procedure RaceClicked(Sender: TObjectGI);
    procedure ApplyClicked(Sender: TObjectGI);
    procedure CancelClicked(Sender: TObjectGI);
    procedure RefreshPact;
    procedure PlayerNameChanged(Sender: TObjectGI);
    function ValidatePlayerName(Name: WideString): Boolean;
    procedure MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
  end;
function RunSelectFaceDialog(Parent: TMessageLoopGI): Boolean;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  GI_MessageBox,
  Classes,
  Windows,
  GR_Main,
  GR_Music,
  Globals,
  GlobalsV,
  EC_Str,
  SysUtils,
  aConst,
  aMyFunction,
  GI_Main,
  GI_Edit,
  GI_GraphButton,
  GI_GraphBuf,
  GI_Image,
  GI_Label,
  GI_GAI;

procedure TfSelectFace.InitializeLayout;
var
  I: Integer;
  Face: WideString;
  Race: Byte;
  Control: TObjectGI;
begin
  inherited;
  for Race := 0 to 4 do
  begin
    I := -1;
    repeat
      Inc(I);
      Face := IntToStr(I);
      if I < 10 then
        Face := '0' + Face;
    until GameDataConfig
            .GetBlockByPath(
                'StyleFace' + OwnerInfo[Integer(RaceToOwner(Race)) and $7F].InternalName)
            .CountParams(Face)
        <= 0;
    LastPortraitByRace[Race] := I - 1;
  end;
  AppendLogTextThreadSafe('fSelectFace... ');
  ViewportRect := Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight);
  with GetByName('MainPanel') do
  begin
    SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
    FindByNameRecursive('BGBuf').SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
    with FindByNameRecursive('PlayerName').Parent do
      SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
  end;
  AppendLogLineThreadSafe('ok');
  Control := FindControlByPath('SubPanel');
  if (Control <> nil) and (ExtraScreenHeight < 0) then
  begin
    Control.SetPosition(Classes.Point(0, ExtraScreenHeight));
    Control.SetSize(Classes.Point(GameScreenWidth, GameScreenHeight - ExtraScreenHeight));
  end;
  GetByName('MainPanel').KeyDownCallback := MainPanelKeyDown;
  GetByName('MainPanel').LeftButtonDownCallback := PlayerNameMouseDown;
  (GetByName('FaceLeft') as TGraphButtonGI).DownCallback := PreviousPortraitClicked;
  (GetByName('FaceRight') as TGraphButtonGI).DownCallback := NextPortraitClicked;
  for I := 0 to 4 do
  begin
    Face := OwnerToSys(RaceToOwner(NumberToRace(I)));
    with GetByName('Race' + Face) as TGraphButtonGI do
    begin
      DownCallback := RaceClicked;
      UpCallback := RaceClicked;
      UserValue := I;
    end;
  end;
  (GetByName('Ok') as TGraphButtonGI).UpCallback := ApplyClicked;
  (GetByName('Cancel') as TGraphButtonGI).UpCallback := CancelClicked;
  with GetByName('PlayerName') as TEditGI do
  begin
    ChangedCallback := PlayerNameChanged;
    MaxLength := 13;
  end;
end;

procedure TfSelectFace.OnOpen;
begin
  CaptureScreenBackground(True, 0);
  (GetByName('BGBuf') as TGraphBufGI).BindExternalGraphBuf(AuxRenderBuffer);
  SelectRace(GetByName('Race' + OwnerToSys(RaceToOwner(PlayerRace))));
  (GetByName('PlayerName') as TEditGI).SetText(PlayerName);
  RefreshPact;
  PlayerNameEdited := False;
  RefreshPortrait;
end;

procedure TfSelectFace.OnClose;
begin
end;

procedure TfSelectFace.PlayerNameMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  SetFocusedControl(GetByName('PlayerName'));
end;

procedure TfSelectFace.RefreshPortrait;
begin
  if CaptainPortraitIndex < 0 then
    CaptainPortraitIndex := LastPortraitByRace[PlayerRace]
  else if CaptainPortraitIndex > LastPortraitByRace[PlayerRace] then
    CaptainPortraitIndex := 0;
  with GetByName('CaptainI') as TImageGI do
    if LastPortraitByRace[PlayerRace] >= 0 then
    begin
      SetImagePath(
          'GI,Bm.Captain.'
              + GiResourceSuffix
              + OwnerInfo[Integer(RaceToOwner(PlayerRace)) and $7F].InternalName
              + IntToStr(CaptainPortraitIndex)
              + 'i'
      );
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
      SetActive(True);
    end
    else
      SetActive(False);
  with GetByName('CaptainA') as TgaiGI do
  begin
    FirstFrameOnly := not AnimCaptain;
    if LastPortraitByRace[PlayerRace] >= 0 then
    begin
      SetImagePath(
          'Bm.Captain.'
              + GiResourceSuffix
              + OwnerInfo[Integer(RaceToOwner(PlayerRace)) and $7F].InternalName
              + IntToStr(CaptainPortraitIndex)
              + 'a'
      );
      SequenceIndex := 0;
      UpdateAutoGeometry;
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
      SetActive(True);
      RestartPlayback;
    end
    else
      SetActive(False);
  end;
end;

procedure TfSelectFace.PreviousPortraitClicked(Sender: TObjectGI);
begin
  Dec(CaptainPortraitIndex);
  RefreshPortrait;
end;

procedure TfSelectFace.NextPortraitClicked(Sender: TObjectGI);
begin
  Inc(CaptainPortraitIndex);
  RefreshPortrait;
end;

procedure TfSelectFace.SelectRace(Sender: TObjectGI);
begin
  PlayerRace := Sender.UserValue;
  (GetByName('RaceMaloc') as TGraphButtonGI).SetDown(PlayerRace = 0);
  (GetByName('RacePeleng') as TGraphButtonGI).SetDown(PlayerRace = 1);
  (GetByName('RacePeople') as TGraphButtonGI).SetDown(PlayerRace = 2);
  (GetByName('RaceFei') as TGraphButtonGI).SetDown(PlayerRace = 3);
  (GetByName('RaceGaal') as TGraphButtonGI).SetDown(PlayerRace = 4);
end;

procedure TfSelectFace.RaceClicked(Sender: TObjectGI);
begin
  SelectRace(Sender);
  CaptainPortraitIndex := 0;
  RefreshPortrait;
  SetFocusedControl(GetByName('PlayerName'));
  with GetByName('PlayerName') as TEditGI do
    SetCaretPosition(Length(Text));
  PlayerNameChanged(nil);
end;

procedure TfSelectFace.ApplyClicked(Sender: TObjectGI);
var
  Cost: Integer;
  Text: WideString;
begin
  Cost := 0;
  case PlayerRace of
    0: Cost := NationalityCosts[0];
    1: Cost := NationalityCosts[1];
    2: Cost := NationalityCosts[2];
    3: Cost := NationalityCosts[3];
    4: Cost := NationalityCosts[4];
  end;
  if Cost <= AvailableMoney then
  begin
    AcceptedCost := Cost;
    Text :=
        FormatText1(
            LanguageDataConfig.GetParamByPathOrMarker('FormRuins.PB.ChangeNationality.Confirm'),
            '<color=255,240,100>',
            '<Money>',
            IntToStr(Cost)
        );
    if ShowMessageBoxGI(Self, Text, mbgOK or mbgCancel or mbgQuestion) = mbgResultOK then
      RequestClose(1);
  end
  else
  begin
    AcceptedCost := 0;
    Text :=
        FormatText1(
            LanguageDataConfig.GetParamByPathOrMarker('FormRuins.PB.ChangeNationality.NoMoney'),
            '<color=255,240,100>',
            '<Money>',
            IntToStr(Cost)
        );
    ShowMessageBoxGI(Self, Text, mbgOK or mbgWarning);
  end;
end;

procedure TfSelectFace.CancelClicked(Sender: TObjectGI);
begin
  RequestClose(2);
end;

procedure TfSelectFace.RefreshPact;
var
  Text: WideString;
begin
  Text := LocalizedColorText('FormRuins.PB.ChangeNationality.PactText');
  ReplaceTextToken(Text, '<CurName>', PlayerName, '<color=247,148,29>');
  (GetByName('Pact') as TLabelGI).SetText(Text);
end;

procedure TfSelectFace.PlayerNameChanged(Sender: TObjectGI);
begin
  if Sender <> nil then
    PlayerNameEdited := True;
  (GetByName('Ok') as TGraphButtonGI)
      .SetDisabled(not ValidatePlayerName((GetByName('PlayerName') as TEditGI).Text));
  PlayerName := (GetByName('PlayerName') as TEditGI).Text;
  RefreshPact;
end;

function TfSelectFace.ValidatePlayerName(Name: WideString): Boolean;
var
  I: Integer;
begin
  Result := False;
  Name := RemoveWideStringChars(Name, '<>{}');
  with GetByName('PlayerName') as TEditGI do
    if Text <> Name then
    begin
      I := CaretPosition;
      SetText(Name);
      if I > 0 then
        SetCaretPosition(I - 1)
      else
        SetCaretPosition(0);
    end;
  Name := TrimWideString(Name);
  if Length(Name) < 1 then
    Exit;
  with GetByName('PlayerName') as TEditGI do
    for I := 0 to Length(Name) - 1 do
      if not HasGlyph(Name[I + 1]) then
        Exit;
  Result := True;
end;

procedure TfSelectFace.MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if not IsVirtualKeyDown(VK_CONTROL)
      and not IsVirtualKeyDown(VK_SHIFT)
      and not IsVirtualKeyDown(VK_MENU) then
    if Key = VK_RETURN then
    begin
      if not (GetByName('Ok') as TGraphButtonGI).Disabled then
        ApplyClicked(nil);
    end
    else if Key = VK_ESCAPE then
      CancelClicked(nil);
end;

procedure TfSelectFace.SelectMusic;
begin
  MusicManager.PlayCategory('Base');
end;

procedure TfSelectFace.ProcessCallbackTimers;
begin
  inherited;
  if (ParentLoop <> nil) and (ParentLoop.ExitCode <> 0) and (ExitCode = 0) then
    RequestClose(2);
end;

function RunSelectFaceDialog(Parent: TMessageLoopGI): Boolean;
var
  CursorAlignment:
      array[0..2] of
          Byte; // Native gap between the Boolean result and packed cursor record at EBP-$20.
  State: TCursorStateGI;
begin
  Result := False;
  Parent.RootUiObject.NativeHook50;
  Parent.CaptureCursorState(@State);
  Parent.SetCursorActive(False);
  Parent.DrawQueuedUpdateRects;
  SelectFaceScreen.ParentLoop := Parent;
  Parent.ChildLoop := SelectFaceScreen;
  if SelectFaceScreen.Run = 1 then
    Result := True;
  SelectFaceScreen.ParentLoop := nil;
  Parent.ChildLoop := nil;
  Parent.InvalidateViewport;
  Parent.RestoreCursorState(@State);
  Parent.UpdateCursorPosition;
  Parent.RootUiObject.NativeHook48;
  Parent.Present;
  PostMouseMoveMessage;
end;

procedure LinkRecoveredTypes;
begin
  TEditGI.ClassName;
  TGraphBufGI.ClassName;
  TGraphButtonGI.ClassName;
  TImageGI.ClassName;
  TLabelGI.ClassName;
  TgaiGI.ClassName;
end;
end.
