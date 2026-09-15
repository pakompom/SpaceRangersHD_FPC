{$EXCESSPRECISION OFF}
unit fSaveManager;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  RTLFileSystem,
  Classes,
  GI_MessageLoop,
  GI_Panel,
  GR_Sound,
  Types,
  Windows;
var
  AutoSaveFileName: WideString = 'AutoSave.sav';
  QuickSaveFileNames: array[1..3] of WideString =
      ('QuickSave.sav', 'QuickSave2.sav', 'QuickSave3.sav');
  TurnSaveFileName: WideString = 'TurnSave.sav';
type
  TfSaveManager = class;
  PointerToTSMSlot = ^TSMSlot;
  PSMSlot = PointerToTSMSlot;
  TSMSlot = packed record
    FileName: WideString;
    DisplayName: WideString;
    Turn: Integer;
    Money: Integer;
    PilotName: WideString;
    RaceName: WideString;
    LocalWriteTime: TFileTime;
  end;
  {$Z1}
  TSaveManagerMode = (smmLoad = 0, smmSave = 1);
  TfSaveManager = class(TMessageLoopGI)
    SelectedSlot: Integer;
    Slots: TList;
    PreviewTimer: PCallbackTimerGI;
    PreviewSound: TSoundBufferControl;
    Closing: Boolean;
    GapE1: array[0..2] of Byte;
    procedure OnOpen; override;
    procedure OnClose; override;
    procedure SelectMusic; override;
    procedure ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer); override;
    procedure InitializeLayout; override;
    constructor Create;
    destructor Destroy; override;
    procedure RebuildSlotControls;
    procedure InitializeSlotPanel(Panel: TPanelGI);
    procedure RefreshSlot(SlotIndex: Integer; UnusedEditingFlag: Boolean);
    procedure CloseClicked(Sender: TObjectGI);
    procedure LoadClicked(Sender: TObjectGI);
    procedure SaveClicked(Sender: TObjectGI);
    procedure DeleteClicked(Sender: TObjectGI);
    procedure SlotMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
    procedure SlotDoubleClick(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
    procedure SlotKeyDown(Sender: TObjectGI; Key: Cardinal);
    function AcceptSaveNameCharacter(Sender: TObjectGI; Character: WideChar): Boolean;
    procedure SelectSlot(SlotIndex: Integer);
    procedure ClearSlotSelection;
    function AutoSaveExists: Boolean;
    function GetAutoSavePath: WideString;
    function FindAutoSaveSlot: Integer;
    function BuildCurrentSaveDescription: WideString;
    function BuildUniqueSavePath(const FileName: WideString; out SuffixIndex: Integer): WideString;
    function GetSaveConfigPath(const FileName: WideString): WideString;
    function QuickSaveExists(SlotIndex: Integer): Boolean;
    function GetQuickSavePath(SlotIndex: Integer): WideString;
    function GetTurnSavePath: WideString;
    procedure SlotMouseEnter(Sender: TObjectGI);
    procedure SlotMouseLeave(Sender: TObjectGI);
    procedure ScanSaveFiles;
    function IsSlotEmpty(SlotIndex: Integer): Boolean;
    function FindNewestSlot: Integer;
    function ReadSaveVersion(FileName: WideString): Integer;
    procedure LoadSavePreviews(FileName: WideString);
    procedure FinishPreviewDelay(Timer: PCallbackTimerGI; UserData: PtrInt);
  end;
procedure LinkRecoveredTypes;
implementation
uses
  GI_MessageBox,
  GR_DX,
  aGalaxyStruct,
  GR_Main,
  SysUtils,
  Math,
  EC_Str,
  EC_File,
  EC_Buf,
  EC_BlockPar,
  GI_Main,
  GI_GAI,
  GI_Image,
  GI_Edit,
  GI_Label,
  GI_GraphBuf,
  GI_PanelScrollBar,
  GI_GraphButton,
  Globals,
  GlobalsV,
  aConst,
  aMyFunction,
  aPlayer,
  aGalaxy,
  aSaveLoad,
  fMainForm,
  fShip2;
// @unit-initialization $8778D8
// @unit-finalization $667F54
var
  NewSaveNormalColor: Cardinal; // @addr $88AA58
  NewSaveSelectedColor: Cardinal; // @addr $88AA5C
  SaveSlotNormalColor: Cardinal; // @addr $88AA60
  SaveSlotSelectedColor: Cardinal; // @addr $88AA64

constructor TfSaveManager.Create;
begin
  inherited;
  Slots := TList.Create;
  SelectedSlot := -1;
  PreviewSound := TSoundBufferControl.Create;
  PreviewSound.Configure('Sound.SaveLoadLoop', 0, True);
end;

destructor TfSaveManager.Destroy;
begin
  Slots.Free;
  PreviewSound.Free;
  inherited;
end;

procedure TfSaveManager.InitializeLayout;
begin
  inherited;
  AppendLogTextThreadSafe('fSaveManager... ');
  ViewportRect := Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight);
  GetByName('').SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
  GetByName('BGBuf').SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
  with GetByName('ButClose').Parent do
    SetPosition(
        Classes.Point(
            LocalPosition.X + ExtraScreenWidth div 2,
            LocalPosition.Y + ExtraScreenHeight div 2
        )
    );
  NewSaveNormalColor := GetStyleColorGI('SaveManager.NewSaveNormal', 0, 41, 65);
  NewSaveSelectedColor := GetStyleColorGI('SaveManager.NewSaveSelected', 87, 149, 175);
  SaveSlotNormalColor := GetStyleColorGI('SaveManager.SlotNormal', 97, 129, 143);
  SaveSlotSelectedColor := GetStyleColorGI('SaveManager.SlotSelected', 65, 121, 145);
  AppendLogLineThreadSafe('ok');
end;

procedure TfSaveManager.OnOpen;
var
  Directory: AnsiString;
begin
  inherited;
  Directory := GetGameUserDirectory + 'Save';
  if not DirectoryExists(Directory) then
    CreateDir(Directory);
  if AuxRenderBuffer.GetPixels = nil then
    CaptureScreenBackground(True, 0);
  (GetByName('BGBuf') as TGraphBufGI).BindExternalGraphBuf(AuxRenderBuffer);
  with GetByName('Anim') as TgaiGI do
    RestartPlayback;
  SelectedSlot := -1;
  if SaveManagerMode = smmSave then
    SelectedSlot := 0;
  (GetByName('ButClose') as TGraphButtonGI).UpCallback := CloseClicked;
  (GetByName('ButCancel') as TGraphButtonGI).UpCallback := CloseClicked;
  with GetByName('ButLoad') as TGraphButtonGI do
  begin
    SetActive(SaveManagerMode = smmLoad);
    UpCallback := LoadClicked;
  end;
  with GetByName('ButSave') as TGraphButtonGI do
  begin
    SetActive(SaveManagerMode = smmSave);
    UpCallback := SaveClicked;
  end;
  with GetByName('ButDelete') as TGraphButtonGI do
  begin
    UpCallback := DeleteClicked;
    SetDisabled(True);
    SetActive(True);
  end;
  with GetByName('GameImage') as TGraphBufGI do
  begin
    GraphBuf.Clear;
    Invalidate;
  end;
  with GetByName('GameImage2') as TGraphBufGI do
  begin
    GraphBuf.Clear;
    Invalidate;
  end;
  GetByName('CaptionLoad').SetActive(SaveManagerMode = smmLoad);
  GetByName('CaptionSave').SetActive(SaveManagerMode = smmSave);
  if (SaveWriter <> nil) and SaveWriter.IsRunning then
    SaveWriter.WaitForIdle($FFFFFFFF);
  RebuildSlotControls;
  if Slots.Count <= 0 then
    PreviewSound.SetVolume(1);
  Closing := False;
end;

procedure TfSaveManager.OnClose;
var
  I: Integer;
  Slot: PSMSlot;
  ScrollPanel: TPanelScrollBarGI;
begin
  for I := 0 to Slots.Count - 1 do
  begin
    Slot := PSMSlot(Slots[I]);
    Slot.FileName := '';
    Dispose(Slot);
  end;
  Slots.Clear;
  PreviewSound.SetVolume(0);
  if Galaxy <> nil then
    Galaxy.CampaignFlag183 := 0;
  if PreviewTimer <> nil then
  begin
    CancelCallbackTimer(PreviewTimer);
    PreviewTimer := nil;
  end;
  ScrollPanel := GetByName('PanelSlot') as TPanelScrollBarGI;
  ScrollPanel.FreeOwnedChildren;
  with GetByName('GameImage') as TGraphBufGI do
    GraphBuf.Clear;
  with GetByName('GameImage2') as TGraphBufGI do
    GraphBuf.Clear;
  AuxRenderBuffer.Clear;
  inherited;
  Closing := False;
end;

procedure TfSaveManager.RebuildSlotControls;
var
  Panel: TPanelGI;
  ScrollPanel: TPanelScrollBarGI;
  I, Y: Integer;
begin
  ScanSaveFiles;
  if SelectedSlot < 0 then
    SelectedSlot := FindNewestSlot;
  if (FindAutoSaveSlot = SelectedSlot) and (SaveManagerMode <> smmLoad) then
    SelectedSlot := 0;
  if Slots.Count <= SelectedSlot then
    SelectedSlot := Slots.Count - 1;
  ScrollPanel := GetByName('PanelSlot') as TPanelScrollBarGI;
  ScrollPanel.KeyDownCallback := SlotKeyDown;
  ScrollPanel.FreeOwnedChildren;
  GetByName('PanelAutoSave').FreeOwnedChildren;
  Y := 0;
  for I := 0 to Slots.Count - 1 do
  begin
    if FindAutoSaveSlot <> I then
    begin
      Panel := TPanelGI.Create(ScrollPanel);
      Panel.UserValue := I;
      Panel.SetPosition(Classes.Point(0, Y));
      InitializeSlotPanel(Panel);
      Inc(Y, Panel.ClientSize.Y);
      Panel.SetName('Slot' + IntToStr(I));
      Panel.SetPositionModeW(True);
      RefreshSlot(I, False);
      ScrollPanel.VerticalScrollBar.SetSmallChange(Panel.ClientSize.Y);
    end;
  end;
  if FindAutoSaveSlot >= 0 then
  begin
    Panel := TPanelGI.Create(GetByName('PanelAutoSave'));
    Panel.UserValue := FindAutoSaveSlot;
    Panel.SetPosition(Classes.Point(0, 0));
    InitializeSlotPanel(Panel);
    Panel.SetName('Slot' + IntToStr(FindAutoSaveSlot));
    Panel.SetPositionModeW(False);
    RefreshSlot(FindAutoSaveSlot, False);
    GetByName('PanelAutoSave').SetSize(Panel.ClientSize);
    ScrollPanel.VerticalScrollBar.SetSmallChange(Panel.ClientSize.Y);
  end;
  ScrollPanel.UpdateScrollRanges;
  ScrollPanel.VerticalScrollBar.SetActive(ScrollPanel.ClientSize.Y < Y);
  ScrollPanel.VerticalScrollBar.SetLargeChange(ScrollPanel.ClientSize.Y);
  ScrollPanel.VerticalScrollBar.SetPageSize(ScrollPanel.ClientSize.Y);
  I := ScrollPanel.VerticalScrollBar.Position;
  ScrollPanel.VerticalScrollBar.SetPosition(I - 1);
  ScrollPanel.VerticalScrollBar.SetPosition(I);
  if (SelectedSlot < 0) or (Slots.Count <= SelectedSlot) then
    SelectedSlot := -1;
  SelectSlot(SelectedSlot);
  FinishPreviewDelay(nil, 0);
end;

procedure TfSaveManager.InitializeSlotPanel(Panel: TPanelGI);
begin
  Panel.SetName('Slot' + IntToStr(Cardinal(Panel.UserValue)));
  Panel.MouseEnterCallback := SlotMouseEnter;
  Panel.MouseLeaveCallback := SlotMouseLeave;
  Panel.LeftButtonDownCallback := SlotMouseDown;
  if (SaveManagerMode = smmLoad) or (FindAutoSaveSlot <> Panel.UserValue) then
    Panel.LeftButtonDoubleClickCallback := SlotDoubleClick;
  with TImageGI.Create(Panel) do
  begin
    SetPosition(Classes.Point(0, 0));
    SetDepth(10);
    SetImagePath('GI,Bm.FormSave2.' + GiResourceSuffix + 'Glow');
    SetSize(GetContentSize);
    Panel.SetSize(ClientSize);
    SetActive(False);
    SetName('Slot' + IntToStr(Cardinal(Panel.UserValue)) + 'onmouse');
  end;
  with TImageGI.Create(Panel) do
  begin
    if GiResourceVariant = 1 then
      SetPosition(Classes.Point(51, 2))
    else
      SetPosition(Classes.Point(64, 3));
    SetDepth(9);
    SetImagePath('GI,Bm.FormSave2.' + GiResourceSuffix + 'SlotN');
    SetSize(GetContentSize);
    SetName('Slot' + IntToStr(Cardinal(Panel.UserValue)) + 'BG');
  end;
  with TImageGI.Create(Panel) do
  begin
    if GiResourceVariant = 1 then
    begin
      SetPosition(Classes.Point(2, 2));
      SetSize(Classes.Point(49, 49));
    end
    else
    begin
      SetPosition(Classes.Point(3, 3));
      SetSize(Classes.Point(61, 61));
    end;
    SetDepth(9);
    SetName('Slot' + IntToStr(Cardinal(Panel.UserValue)) + 'Emblem');
  end;
  if (SaveManagerMode = smmLoad) or (FindAutoSaveSlot = Panel.UserValue) then
  begin
    with TLabelGI.Create(Panel) do
    begin
      SetPosition(Classes.Point(81, 14));
      SetSize(Classes.Point(409, 20));
      SetDepth(7);
      if FontDialog = 0 then
        SetFontName(NormalFontName)
      else if FontDialog = 1 then
        SetFontName(SmoothBigFontName)
      else if FontDialog = 2 then
        SetFontName(SmoothHugeFontName)
      else if FontDialog >= 3 then
        SetFontName(SmoothIntroFontName);
      SetTextAlignX(taxLeft);
      SetTextAlignY(tayCenterEx);
      SetName('Slot' + IntToStr(Cardinal(Panel.UserValue)) + 'Edit');
      if Self.IsSlotEmpty(Panel.UserValue) then
        SetText('')
      else
        SetText(PSMSlot(Self.Slots[Panel.UserValue]).DisplayName);
      SetTextColor(CurrentPixelFormat.PackRgbBytes(0, 0, 0));
    end;
  end
  else
  begin
    with TEditGI.Create(Panel) do
    begin
      SetPosition(Classes.Point(81, 14));
      SetSize(Classes.Point(409, 20));
      SetDepth(7);
      if FontDialog = 0 then
        SetFontName(NormalFontName)
      else if FontDialog = 1 then
        SetFontName(SmoothBigFontName)
      else if FontDialog = 2 then
        SetFontName(SmoothHugeFontName)
      else if FontDialog >= 3 then
        SetFontName(SmoothIntroFontName);
      SetName('Slot' + IntToStr(Cardinal(Panel.UserValue)) + 'Edit');
      MaxLength := 55;
      if Self.IsSlotEmpty(Panel.UserValue) then
        SetText('')
      else
        SetText(PSMSlot(Self.Slots[Panel.UserValue]).DisplayName);
      SetTextColor(CurrentPixelFormat.PackRgbBytes(0, 0, 0));
      AcceptCharCallback := AcceptSaveNameCharacter;
    end;
  end;
  with TLabelGI.Create(Panel) do
  begin
    SetPosition(Classes.Point(72, 37));
    SetSize(Classes.Point(130, 17));
    SetDepth(8);
    SetFontName(RangerFontName);
    SetTextAlignX(taxCenter);
    SetTextAlignY(tayCenterEx);
    SetName('Slot' + IntToStr(Cardinal(Panel.UserValue)) + 'Captain');
  end;
  with TLabelGI.Create(Panel) do
  begin
    SetPosition(Classes.Point(207, 37));
    SetSize(Classes.Point(165, 17));
    SetDepth(8);
    SetFontName(RangerFontName);
    SetTextColor(CurrentPixelFormat.PackRgbBytes(227, 227, 227));
    SetTextAlignX(taxCenter);
    SetTextAlignY(tayCenterEx);
    SetName('Slot' + IntToStr(Cardinal(Panel.UserValue)) + 'Turn');
  end;
  with TLabelGI.Create(Panel) do
  begin
    SetPosition(Classes.Point(387, 37));
    SetSize(Classes.Point(108, 17));
    SetDepth(8);
    SetFontName(RangerFontName);
    SetTextColor(CurrentPixelFormat.PackRgbBytes(227, 227, 227));
    SetTextAlignX(taxCenter);
    SetTextAlignY(tayCenterEx);
    SetName('Slot' + IntToStr(Cardinal(Panel.UserValue)) + 'Money');
  end;
  with TLabelGI.Create(Panel) do
  begin
    SetPosition(Classes.Point(297, 7));
    SetSize(Classes.Point(200, 15));
    SetDepth(8);
    SetFontName(MiniFontName);
    SetTextColor(CurrentPixelFormat.PackRgbBytes(227, 227, 227));
    SetTextAlignX(taxRight);
    SetTextAlignY(tayCenterEx);
    SetName('Slot' + IntToStr(Cardinal(Panel.UserValue)) + 'Date');
  end;
end;

procedure TfSaveManager.RefreshSlot(SlotIndex: Integer; UnusedEditingFlag: Boolean);
var
  State: WideString;
  Color: Cardinal;
  Time: Windows.TSystemTime;
begin
  try
    if SelectedSlot = SlotIndex then
      State := 'D'
    else
      State := 'N';
    with GetByName('Slot' + IntToStr(SlotIndex) + 'BG') as TImageGI do
      SetImagePath('GI,Bm.FormSave2.2Slot' + State);
    with GetByName('Slot' + IntToStr(SlotIndex) + 'Emblem') as TImageGI do
    begin
      SetImagePath('GI,Bm.FormSave2.2' + PSMSlot(Slots[SlotIndex]).RaceName + State);
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
      SetActive(True);
    end;
    with GetByName('Slot' + IntToStr(SlotIndex) + 'Date') as TLabelGI do
    begin
      if IsSlotEmpty(SlotIndex) then
        SetText(LocalizedText('FormSaveManager.New'))
      else
      begin
        FileTimeToSystemTime(PSMSlot(Slots[SlotIndex]).LocalWriteTime, Time);
        SetText(
            FormatDateTime(
                AnsiString(LocalizedText('FormSaveManager.DateFormatStr')),
                SystemTimeToDateTime(Time)
            )
        );
      end;
      if (SaveManagerMode = smmSave) and (SlotIndex = 0) then
      begin
        if SelectedSlot = SlotIndex then
          SetTextColor(NewSaveSelectedColor)
        else
          SetTextColor(NewSaveNormalColor);
      end
      else
      begin
        if SelectedSlot = SlotIndex then
          SetTextColor(SaveSlotSelectedColor)
        else
          SetTextColor(SaveSlotNormalColor);
      end;
    end;
    if SelectedSlot = SlotIndex then
      Color := CurrentPixelFormat.PackRgbBytes(255, 255, 255)
    else
      Color := CurrentPixelFormat.PackRgbBytes(0, 0, 0);
    if GetByName('Slot' + IntToStr(SlotIndex) + 'Edit') is TEditGI then
    begin
      with GetByName('Slot' + IntToStr(SlotIndex) + 'Edit') as TEditGI do
      begin
        SetText(PSMSlot(Slots[SlotIndex]).DisplayName);
        SetTextColor(Color);
      end;
    end
    else
    begin
      with GetByName('Slot' + IntToStr(SlotIndex) + 'Edit') as TLabelGI do
      begin
        SetText(PSMSlot(Slots[SlotIndex]).DisplayName);
        SetTextColor(Color);
      end;
    end;
    if IsSlotEmpty(SlotIndex) then
    begin
      if SelectedSlot = SlotIndex then
      begin
        (GetByName('Slot' + IntToStr(SlotIndex) + 'Captain') as TLabelGI).SetText(GetPlayer.Name);
        (GetByName('Slot' + IntToStr(SlotIndex) + 'Turn') as TLabelGI)
            .SetText(FormatGameTurnDate(Galaxy.CurrentTurn));
        (GetByName('Slot' + IntToStr(SlotIndex) + 'Money') as TLabelGI)
            .SetText(IntToStr(GetPlayer.Money));
      end
      else
      begin
        (GetByName('Slot' + IntToStr(SlotIndex) + 'Captain') as TLabelGI).SetText('');
        (GetByName('Slot' + IntToStr(SlotIndex) + 'Turn') as TLabelGI).SetText('');
        (GetByName('Slot' + IntToStr(SlotIndex) + 'Money') as TLabelGI).SetText('');
      end;
    end
    else
    begin
      (GetByName('Slot' + IntToStr(SlotIndex) + 'Captain') as TLabelGI)
          .SetText(PSMSlot(Slots[SlotIndex]).PilotName);
      (GetByName('Slot' + IntToStr(SlotIndex) + 'Turn') as TLabelGI)
          .SetText(FormatGameTurnDate(PSMSlot(Slots[SlotIndex]).Turn));
      (GetByName('Slot' + IntToStr(SlotIndex) + 'Money') as TLabelGI)
          .SetText(IntToStr(PSMSlot(Slots[SlotIndex]).Money));
    end;
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
      AppendLogLineThreadSafe(
          AnsiString(
              WideString('Error when loading info from save file ')
                  + PSMSlot(Slots[SlotIndex]).FileName
          )
      );
    end;
  end;
end;

procedure TfSaveManager.CloseClicked(Sender: TObjectGI);
begin
  RequestedScreenId := SaveManagerReturnScreenId;
  Closing := True;
  RequestClose(1);
end;

procedure TfSaveManager.LoadClicked(Sender: TObjectGI);
begin
  ReleaseAllTextureSurfaces;
  MainMenuScreen.LoadPanel.SelectBackgroundStyle(0);
  if SelectedSlot >= 0 then
  begin
    if not IsSlotEmpty(SelectedSlot)
        and (ReadSaveVersion(PSMSlot(Slots[SelectedSlot]).FileName)
            < MinimumLoadableSaveVersion) then
      ShowMessageBoxGI(
          TMessageLoopGI(GetRegisteredScreenLoop(CurrentScreenId)),
          LanguageDataConfig.GetParamByPathOrMarker('FormSaveManager.LoadError'),
          mbgCancel or mbgError
      )
    else if not IsSlotEmpty(SelectedSlot) then
    begin
      PendingLoadFileName := PSMSlot(Slots[SelectedSlot]).FileName;
      EditableSaveFileName := GetSaveConfigPath(PendingLoadFileName);
      if RTLFileSystem.FileExists(EditableSaveFileName) then
        if ShowMessageBoxGI(
                Self,
                LocalizedColorText('FormSaveManager.LoadDumpConfirm'),
                mbgOK or mbgCancel or mbgQuestion)
            = mbgResultOK then
        begin
          EditableSaveBlock.Clear;
          EditableSaveBlock
              .LoadFromTextFileWithEncodingProbe(PWideChar(EditableSaveFileName), True);
          ApplyEditableSaveOnLoad := True;
        end;
      ShipScreen.SelectedHoldKind := phkEmpty;
      ShipScreen.SelectedHoldItem := nil;
      RequestedScreenId := screenGameLoad;
      RequestClose(1);
    end;
  end;
end;

procedure TfSaveManager.SaveClicked(Sender: TObjectGI);
var
  Saved: Boolean;
  FileName, Description, ExistingFile: WideString;
  SuffixIndex: Integer;
begin
  if SelectedSlot >= 0 then
  begin
    ExistingFile := '';
    if not IsSlotEmpty(SelectedSlot) then
      ExistingFile := PSMSlot(Slots[SelectedSlot]).FileName;
    FileName :=
        TrimWideString((GetByName('Slot' + IntToStr(SelectedSlot) + 'Edit') as TEditGI).Text);
    if FileName = '' then
      SetFocusedControl(GetByName('Slot' + IntToStr(SelectedSlot) + 'Edit'))
    else
    begin
      Description := FileName;
      FileName := RemoveWideStringChars(FileName, '<>"/\:');
      if RunningUnderWine
          or ((UserSettingsConfig.CountParams('TransliterateSaveNames') > 0)
              and ParseEnabledNameGI(
                  TrimWideString(
                      UserSettingsConfig.GetParamByPathOrMarker('TransliterateSaveNames')
                  ))) then
        FileName := TransliterateCyrillicToLatin(FileName);
      SuffixIndex := 0;
      if ExistingFile <> '' then
        FileName := ExistingFile
      else
        FileName :=
            BuildUniqueSavePath(GetGameUserDirectory + 'Save\' + FileName + '.sav', SuffixIndex);
      if SuffixIndex > 0 then
        Description := Description + ' (' + IntToStr(SuffixIndex) + ')';
      Saved := SaveGameToFile(FileName, Description);
      if not Saved then
        ShowMessageBoxGI(
            Self,
            LanguageDataConfig.GetParamByPathOrMarker('FormSaveManager.SaveError')
                + #13#10
                + LastSaveLoadError,
            mbgOK or mbgError
        )
      else
        CloseClicked(Sender);
    end;
  end;
end;

procedure TfSaveManager.DeleteClicked(Sender: TObjectGI);
var
  WasAutoSave: Boolean;
begin
  if (SelectedSlot >= 0) and not IsSlotEmpty(SelectedSlot) then
    if ShowMessageBoxGI(
            Self,
            LanguageDataConfig.GetParamByPathOrMarker('FormSaveManager.QueryDelete'),
            mbgOK or mbgCancel or mbgQuestion)
        = mbgResultOK then
    begin
      if (FindAutoSaveSlot = SelectedSlot) and (SaveManagerMode = smmLoad) then
        WasAutoSave := True
      else
        WasAutoSave := False;
      SysUtils.DeleteFile(NativePath(UTF8Encode(PSMSlot(Slots[SelectedSlot]).FileName)));
      if RTLFileSystem.FileExists(GetSaveConfigPath(PSMSlot(Slots[SelectedSlot]).FileName)) then
        SysUtils.DeleteFile(
            NativePath(UTF8Encode(GetSaveConfigPath(PSMSlot(Slots[SelectedSlot]).FileName)))
        );
      if WasAutoSave then
        SelectedSlot := 0;
      RebuildSlotControls;
    end;
end;

procedure TfSaveManager.SlotMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  if not Closing and ((SaveManagerMode = smmLoad) or (FindAutoSaveSlot <> Sender.UserValue)) then
  begin
    SoundManager.PlaySound('Sound.ButtonClick');
    SelectSlot(Sender.UserValue);
  end;
end;

procedure TfSaveManager.SlotDoubleClick(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  if SaveManagerMode = smmSave then
    SaveClicked(Sender)
  else
    LoadClicked(Sender);
end;

procedure TfSaveManager.SlotKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if Key = VK_DOWN then
  begin
    if SelectedSlot < 0 then
      SelectSlot(0)
    else if ((SaveManagerMode = smmLoad) or (FindAutoSaveSlot < 0))
        and (Slots.Count - 1 <= SelectedSlot) then
      SelectSlot(0)
    else if (SaveManagerMode <> smmLoad)
        and (FindAutoSaveSlot >= 0)
        and (Slots.Count - 2 <= SelectedSlot) then
      SelectSlot(0)
    else
      SelectSlot(SelectedSlot + 1);
  end
  else if Key = VK_UP then
  begin
    if SelectedSlot < 0 then
      SelectSlot(Slots.Count - 1)
    else if SelectedSlot = 0 then
    begin
      if (SaveManagerMode = smmLoad) or (FindAutoSaveSlot < 0) then
      begin
        if Slots.Count - 1 <> SelectedSlot then
          SelectSlot(Slots.Count - 1);
      end
      else if Slots.Count - 2 <> SelectedSlot then
        SelectSlot(Slots.Count - 2);
    end
    else
      SelectSlot(SelectedSlot - 1);
  end
  else if Key = VK_PRIOR then
  begin
    if SelectedSlot <> 0 then
      SelectSlot(0);
  end
  else if Key = VK_NEXT then
  begin
    if (SaveManagerMode = smmLoad) or (FindAutoSaveSlot < 0) then
    begin
      if Slots.Count - 1 <> SelectedSlot then
        SelectSlot(Slots.Count - 1);
    end
    else if Slots.Count - 2 <> SelectedSlot then
      SelectSlot(Slots.Count - 2);
  end
  else if Key = VK_DELETE then
    DeleteClicked(nil)
  else if Key = VK_ESCAPE then
    CloseClicked(Sender)
  else if Key = VK_RETURN then
  begin
    if SaveManagerMode = smmSave then
      SaveClicked(Sender)
    else
      LoadClicked(Sender);
  end;
end;

procedure TfSaveManager.ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer);
begin
  if Delta = WHEEL_DELTA then
    SlotKeyDown(nil, VK_UP)
  else if Delta = -WHEEL_DELTA then
    SlotKeyDown(nil, VK_DOWN);
end;

function TfSaveManager.AcceptSaveNameCharacter(Sender: TObjectGI; Character: WideChar): Boolean;
begin
  Result :=
      (Character <> '\')
          and (Character <> '/')
          and (Character <> ':')
          and (Character <> '*')
          and (Character <> '?')
          and (Character <> '"')
          and (Character <> '<')
          and (Character <> '>')
          and (Character <> '|');
end;

procedure TfSaveManager.SelectSlot(SlotIndex: Integer);
var
  ScrollPanel: TPanelScrollBarGI;
begin
  ClearSlotSelection;
  SelectedSlot := SlotIndex;
  if Slots.Count <= SelectedSlot then
    SelectedSlot := -1;
  (GetByName('ButDelete') as TGraphButtonGI).SetDisabled(IsSlotEmpty(SlotIndex));
  (GetByName('ButLoad') as TGraphButtonGI).SetDisabled(IsSlotEmpty(SlotIndex));
  (GetByName('ButSave') as TGraphButtonGI)
      .SetDisabled((SlotIndex < 0) or (Slots.Count <= SlotIndex));
  if (SelectedSlot >= 0) and (Slots.Count > SelectedSlot) then
  begin
    ScrollPanel := GetByName('PanelSlot') as TPanelScrollBarGI;
    if FindAutoSaveSlot <> SlotIndex then
      with GetByName('Slot' + IntToStr(SlotIndex)) as TPanelGI do
        ScrollPanel.ScrollRectIntoView(GetLocalBounds);
    RefreshSlot(SlotIndex, SaveManagerMode = smmSave);
    if GetByName('Slot' + IntToStr(SlotIndex) + 'Edit') is TEditGI then
    begin
      if IsSlotEmpty(SlotIndex) then
        with GetByName('Slot' + IntToStr(SlotIndex) + 'Edit') as TEditGI do
          SetText(BuildCurrentSaveDescription);
      SetFocusedControl(GetByName('Slot' + IntToStr(SlotIndex) + 'Edit'));
    end;
    if not IsSlotEmpty(SlotIndex) then
    begin
      if PreviewTimer <> nil then
      begin
        CancelCallbackTimer(PreviewTimer);
        PreviewTimer := nil;
      end;
      LoadSavePreviews(PSMSlot(Slots[SlotIndex]).FileName);
    end
    else if (SelectedSlot = 0) and (SaveManagerMode = smmSave) then
    begin
      with GetByName('GameImage') as TGraphBufGI do
      begin
        GraphBuf.Clear;
        GraphBuf.AllocateRgb(
            SavePreviewGraph.Width,
            SavePreviewGraph.Height,
            SavePreviewGraph.PitchBytes
        );
        Windows.CopyMemory(
            GraphBuf.GetPixels,
            SavePreviewGraph.GetPixels,
            GraphBuf.Height * GraphBuf.PitchBytes
        );
        GraphBuf.RescaleRgb(ClientSize.X, ClientSize.Y);
        GraphBuf.ConvertRgbTo565;
        Invalidate;
        SetActive(False);
      end;
      with GetByName('GameImage2') as TGraphBufGI do
      begin
        GraphBuf.Clear;
        GraphBuf.AllocateRgb(
            SecondarySavePreviewGraph.Width,
            SecondarySavePreviewGraph.Height,
            SecondarySavePreviewGraph.PitchBytes
        );
        Windows.CopyMemory(
            GraphBuf.GetPixels,
            SecondarySavePreviewGraph.GetPixels,
            GraphBuf.Height * GraphBuf.PitchBytes
        );
        GraphBuf.RescaleRgb(ClientSize.X, ClientSize.Y);
        GraphBuf.ConvertRgbTo565;
        Invalidate;
        SetActive(False);
      end;
      if PreviewTimer <> nil then
      begin
        CancelCallbackTimer(PreviewTimer);
        PreviewTimer := nil;
      end;
      PreviewTimer := ScheduleCallbackTimer(250, 250, FinishPreviewDelay);
      PreviewSound.SetVolume(1);
    end
    else
    begin
      with GetByName('GameImage') as TGraphBufGI do
      begin
        GraphBuf.Clear;
        Invalidate;
        SetActive(False);
      end;
      with GetByName('GameImage2') as TGraphBufGI do
      begin
        GraphBuf.Clear;
        Invalidate;
        SetActive(False);
      end;
    end;
    PostMouseMoveMessage;
  end;
end;

procedure TfSaveManager.ClearSlotSelection;
var
  PreviousSlot: Integer;
begin
  if PreviewTimer <> nil then
  begin
    CancelCallbackTimer(PreviewTimer);
    PreviewTimer := nil;
  end;
  GetByName('GameImage').SetActive(False);
  GetByName('GameImage2').SetActive(False);
  PreviousSlot := SelectedSlot;
  SelectedSlot := -1;
  if PreviousSlot >= 0 then
  begin
    if GetByName('Slot' + IntToStr(PreviousSlot) + 'Edit') is TEditGI then
      SetFocusedControl(nil);
    RefreshSlot(PreviousSlot, False);
  end;
end;

function TfSaveManager.AutoSaveExists: Boolean;
begin
  Result := RTLFileSystem.FileExists(GetAutoSavePath);
end;

function TfSaveManager.GetAutoSavePath: WideString;
begin
  Result := GetGameUserDirectory + 'Save\' + AutoSaveFileName;
end;

function TfSaveManager.FindAutoSaveSlot: Integer;
begin
  Result := -1;
  if Slots.Count > 0 then
    if PSMSlot(Slots[Slots.Count - 1]).FileName = GetAutoSavePath then
      Result := Slots.Count - 1;
end;

function TfSaveManager.BuildCurrentSaveDescription: WideString;
begin
  if GetPlayer.RuinsMode = 0 then
  begin
    if GetPlayer.CurrentPlanet <> nil then
    begin
      if GetPlayer.CurrentPlanet.IsMainPiratePlanet then
      begin
        Result := LocalizedText('FormSaveManager.SaveInShip');
        Result := ReplaceAllWideString(Result, '<ShipName>', GetPlayer.CurrentPlanet.Name);
      end
      else
      begin
        Result := LocalizedText('FormSaveManager.SaveInPlanet');
        Result := ReplaceAllWideString(Result, '<Planet>', GetPlayer.CurrentPlanet.Name);
      end;
    end
    else if GetPlayer.DockedTo <> nil then
    begin
      Result := LocalizedText('FormSaveManager.SaveInShip');
      Result := ReplaceAllWideString(Result, '<ShipName>', GetPlayer.DockedTo.GetFullName(' '));
    end
    else
      Result := LocalizedText('FormSaveManager.SaveInSpace');
  end
  else
  begin
    if GetPlayer.RuinsSavedPlanet <> nil then
    begin
      if GetPlayer.RuinsSavedPlanet.IsMainPiratePlanet then
      begin
        Result := LocalizedText('FormSaveManager.SaveInShip');
        Result := ReplaceAllWideString(Result, '<ShipName>', GetPlayer.RuinsSavedPlanet.Name);
      end
      else
      begin
        Result := LocalizedText('FormSaveManager.SaveInPlanet');
        Result := ReplaceAllWideString(Result, '<Planet>', GetPlayer.RuinsSavedPlanet.Name);
      end;
    end
    else if GetPlayer.RuinsSavedDockedTo <> nil then
    begin
      Result := LocalizedText('FormSaveManager.SaveInShip');
      Result :=
          ReplaceAllWideString(Result, '<ShipName>', GetPlayer.RuinsSavedDockedTo.GetFullName(' '));
    end
    else
      Result := LocalizedText('FormSaveManager.SaveInSpace');
  end;
  Result := ReplaceAllWideString(Result, '<Star>', GetPlayer.CurrentStar.Name);
  Result :=
      ReplaceAllWideString(Result, '<Constellation>', GetPlayer.CurrentStar.Constellation.GetName);
  Result := ReplaceAllWideString(Result, '<Player>', GetPlayer.Name);
end;

function TfSaveManager.BuildUniqueSavePath(
    const FileName: WideString;
    out SuffixIndex: Integer
): WideString;
var
  I, ExistingSuffix, Parts: Integer;
  Directory, BaseName, Extension, ExistingName, Suffix: WideString;
begin
  Directory := TrimWideString(ExtractFileDirW(FileName));
  if Directory = '' then
    Directory := GetGameUserDirectory + 'Save';
  BaseName := TrimWideString(ExtractFileNameNoExtW(FileName));
  Extension := TrimWideString(ExtractFileExtNoDotW(FileName));
  if Extension = '' then
    Extension := 'sav';
  Parts := CountDelimitedPartsW(BaseName, '()');
  if Parts >= 3 then
  begin
    Suffix := ExtractDelimitedPartW(BaseName, Parts - 2, '()');
    if IsIntegerTextW(Suffix) then
      BaseName := TrimWideString(ExtractDelimitedRangeW(BaseName, 0, Parts - 3, '()'));
  end;
  SuffixIndex := 0;
  I := 0;
  while I < Slots.Count do
  begin
    ExistingName :=
        TrimWideString(LowerCaseWideString(ExtractFileNameNoExtW(PSMSlot(Slots[I]).FileName)));
    Parts := CountDelimitedPartsW(ExistingName, '()');
    ExistingSuffix := 0;
    if Parts >= 3 then
    begin
      Suffix := ExtractDelimitedPartW(ExistingName, Parts - 2, '()');
      if IsIntegerTextW(Suffix) then
      begin
        ExistingName := TrimWideString(ExtractDelimitedRangeW(ExistingName, 0, Parts - 3, '()'));
        ExistingSuffix := ExtractDigitsToIntW(Suffix);
      end;
    end;
    if ExistingName = LowerCaseWideString(BaseName) then
      SuffixIndex := Max(SuffixIndex, ExistingSuffix + 1);
    Inc(I);
  end;
  if SuffixIndex = 0 then
    Result := Directory + '\' + BaseName + '.' + Extension
  else
  begin
    Parts := CountDelimitedPartsW(BaseName, '()');
    if Parts >= 3 then
    begin
      Suffix := ExtractDelimitedPartW(BaseName, Parts - 2, '()');
      if IsIntegerTextW(Suffix) then
        Result :=
            Directory
                + '\'
                + ExtractDelimitedRangeW(BaseName, 0, Parts - 3, '()')
                + ' ('
                + IntToStr(SuffixIndex)
                + ').'
                + Extension
      else
        Result := Directory + '\' + BaseName + ' (' + IntToStr(SuffixIndex) + ').' + Extension;
    end
    else
      Result := Directory + '\' + BaseName + ' (' + IntToStr(SuffixIndex) + ').' + Extension;
  end;
end;

function TfSaveManager.GetSaveConfigPath(const FileName: WideString): WideString;
var
  Directory, BaseName, Extension: WideString;
begin
  Directory := TrimWideString(ExtractFileDirW(FileName));
  BaseName := TrimWideString(ExtractFileNameNoExtW(FileName));
  Extension := 'txt';
  Result := Directory + '\' + BaseName + '.' + Extension;
end;

function TfSaveManager.QuickSaveExists(SlotIndex: Integer): Boolean;
begin
  Result := RTLFileSystem.FileExists(GetQuickSavePath(SlotIndex));
end;

function TfSaveManager.GetQuickSavePath(SlotIndex: Integer): WideString;
begin
  Result := GetGameUserDirectory + 'Save\' + QuickSaveFileNames[SlotIndex];
end;

function TfSaveManager.GetTurnSavePath: WideString;
begin
  Result := GetGameUserDirectory + 'Save\' + TurnSaveFileName;
end;

procedure TfSaveManager.SlotMouseEnter(Sender: TObjectGI);
begin
  GetByName('Slot' + IntToStr(Cardinal(Sender.UserValue)) + 'onmouse')
      .SetActive((FindAutoSaveSlot <> Sender.UserValue) or (SaveManagerMode <> smmSave));
  SoundManager.PlaySound('Sound.ButtonEnter');
end;

procedure TfSaveManager.SlotMouseLeave(Sender: TObjectGI);
begin
  GetByName('Slot' + IntToStr(Cardinal(Sender.UserValue)) + 'onmouse').SetActive(False);
  SoundManager.PlaySound('Sound.ButtonLeave');
end;

procedure TfSaveManager.ScanSaveFiles;
var
  Slot: PSMSlot;
  PreviousDirectory: AnsiString;
  Search: Windows.THandle;
  I: Integer;
  AutoSlot, NewSlot: PSMSlot;
  FileObject: TFileEC;
  AutoPath: WideString;
  FindData: TWin32FindData;
  procedure InsertScannedSaveSlotByTime; // @addr 0x667220 @ida "void __usercall $name(void *ParentFrame@<^0>);" @stackpop 0 @calls "0x66783A" @note "Nested helper of TfSaveManager.ScanSaveFiles; requires its parent stack frame."
  var
    Low, High, Middle, Comparison: Integer;
    OtherSlot: PSMSlot;
    Time: TFileTime;
  begin
    if Slots.Count < 1 then
    begin
      Slots.Add(Slot);
      Exit;
    end;
    Time := Slot.LocalWriteTime;
    Low := 0;
    OtherSlot := PSMSlot(Slots[0]);
    Comparison := CompareFileTime(OtherSlot.LocalWriteTime, Time);
    if Comparison <= 0 then
    begin
      Slots.Insert(0, Slot);
      Exit;
    end;
    High := Slots.Count - 1;
    OtherSlot := PSMSlot(Slots[High]);
    Comparison := CompareFileTime(OtherSlot.LocalWriteTime, Time);
    if Comparison >= 0 then
    begin
      Slots.Add(Slot);
      Exit;
    end;
    while True do
    begin
      if High - Low < 2 then
      begin
        Slots.Insert(High, Slot);
        Exit;
      end;
      Middle := (Low + High) div 2;
      OtherSlot := PSMSlot(Slots[Middle]);
      Comparison := CompareFileTime(OtherSlot.LocalWriteTime, Time);
      if Comparison = 0 then
      begin
        Slots.Insert(Middle, Slot);
        Exit;
      end
      else if Comparison < 0 then
        High := Middle
      else
        Low := Middle;
    end;
  end;
begin
  FileObject := TFileEC.Create;
  AutoPath := GetAutoSavePath;
  PreviousDirectory := GetCurrentDir;
  SetCurrentDir(GetGameUserDirectory + 'Save');
  AutoSlot := nil;
  NewSlot := nil;
  for I := 0 to Slots.Count - 1 do
  begin
    Slot := PSMSlot(Slots[I]);
    Slot.FileName := '';
    Dispose(Slot);
  end;
  Slots.Clear;
  if SaveManagerMode = smmSave then
  begin
    New(NewSlot);
    if GetPlayer.OwnerId = Byte(oiPirate) then
      NewSlot.RaceName :=
          OwnerInfo[Ord(oiPirate)].InternalName
              + OwnerInfo[Integer(RaceToOwner(GetPlayer.PilotRace)) and $7F].InternalName
    else
      NewSlot.RaceName := OwnerInfo[GetPlayer.OwnerId].InternalName;
  end;
  try
    FindData.dwFileAttributes := FILE_ATTRIBUTE_NORMAL;
    Search := Windows.FindFirstFile('*.sav', FindData);
    if Search <> INVALID_HANDLE_VALUE then
    begin
      repeat
        if (FindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) = 0 then
        begin
          New(Slot);
          Slot.FileName :=
              GetGameUserDirectory + 'Save\' + TrimWideString(WideString(FindData.cFileName));
          if LowerCaseWideString(Slot.FileName) = LowerCaseWideString(GetAutoSavePath) then
            Slot.FileName := AutoPath;
          Slot.DisplayName := ExtractFileNameNoExtW(Slot.FileName);
          FileTimeToLocalFileTime(FindData.ftLastWriteTime, Slot.LocalWriteTime);
          try
            FileObject.SetFileName(Slot.FileName);
            if not FileObject.TryAcquireReadHandle(True) then
            begin
              SuppressExceptionLogCopy := True;
              raise EAbort.Create('Err');
            end;
            if FileObject.ReadWideString <> 'RSG' then
            begin
              SuppressExceptionLogCopy := True;
              raise EAbort.Create('Err');
            end;
            I := ExtractDigitsToIntW(FileObject.ReadWideString);
            if (I < 13) or (I > CurrentSaveVersion) then
            begin
              SuppressExceptionLogCopy := True;
              raise EAbort.Create('Err');
            end;
            if (Slot.FileName = AutoPath) or RunningUnderWine then
              Slot.DisplayName := FileObject.ReadWideString
            else
              FileObject.ReadWideString;
            Slot.Turn := ExtractDigitsToIntW(FileObject.ReadWideString);
            Slot.Money := ExtractDigitsToIntW(FileObject.ReadWideString);
            Slot.PilotName := FileObject.ReadWideString;
            Slot.RaceName := FileObject.ReadWideString;
            if FileObject.ReadWideString <> 'EZ' then
            begin
              SuppressExceptionLogCopy := True;
              raise EAbort.Create('Err');
            end;
            FileObject.ReleaseHandle;
            if Slot.FileName = AutoPath then
              AutoSlot := Slot
            else
              InsertScannedSaveSlotByTime;
          except
            Dispose(Slot);
          end;
        end;
      until not Boolean(Windows.FindNextFile(Search, FindData));
      Windows.FindClose(Search);
    end;
  finally
    FileObject.Free;
    SetCurrentDir(PreviousDirectory);
  end;
  if NewSlot <> nil then
    Slots.Insert(0, NewSlot);
  if AutoSlot <> nil then
    Slots.Add(AutoSlot);
end;

function TfSaveManager.IsSlotEmpty(SlotIndex: Integer): Boolean;
begin
  if (SlotIndex < 0) or (Slots.Count <= SlotIndex) then
    Result := True
  else
    Result := PSMSlot(Slots[SlotIndex]).FileName = '';
end;

function TfSaveManager.FindNewestSlot: Integer;
var
  I: Integer;
  Latest: TFileTime;
begin
  Result := -1;
  Latest.dwLowDateTime := 0;
  Latest.dwHighDateTime := 0;
  for I := 0 to Slots.Count - 1 do
    if CompareFileTime(PSMSlot(Slots[I]).LocalWriteTime, Latest) > 0 then
    begin
      Latest := PSMSlot(Slots[I]).LocalWriteTime;
      Result := I;
    end;
end;

function TfSaveManager.ReadSaveVersion(FileName: WideString): Integer;
var
  FileObject: TFileEC;
begin
  FileObject := TFileEC.Create;
  FileObject.SetFileName(FileName);
  FileObject.AcquireReadHandle(False);
  FileObject.TryAcquireReadHandle(False);
  FileObject.ReadWideString;
  Result := ExtractDigitsToIntW(FileObject.ReadWideString);
  FileObject.ReleaseHandle;
  FileObject.Free;
end;

procedure TfSaveManager.LoadSavePreviews(FileName: WideString);
var
  FileObject: TFileEC;
  ByteCount: Integer;
  Buffer: TBufEC;
  FirstImage, SecondImage: TGraphBufGI;
begin
  FirstImage := GetByName('GameImage') as TGraphBufGI;
  FirstImage.SetActive(False);
  FirstImage.GraphBuf.Clear;
  FirstImage.Invalidate;
  SecondImage := GetByName('GameImage2') as TGraphBufGI;
  SecondImage.SetActive(False);
  SecondImage.GraphBuf.Clear;
  SecondImage.Invalidate;
  FileObject := TFileEC.Create;
  Buffer := TBufEC.Create;
  try
    FileObject.SetFileName(FileName);
    FileObject.AcquireReadHandle(False);
    FileObject.ReadWideString;
    FileObject.ReadWideString;
    FileObject.ReadWideString;
    FileObject.ReadWideString;
    FileObject.ReadWideString;
    FileObject.ReadWideString;
    FileObject.ReadWideString;
    FileObject.ReadWideString;
    FileObject.ReadBuffer(@ByteCount, 4);
    if ByteCount > 0 then
    begin
      Buffer.SetSize(ByteCount);
      FileObject.ReadBuffer(Buffer.Data, ByteCount);
    end;
    if ByteCount > 0 then
    begin
      FirstImage.GraphBuf.LoadFromBuffer(Buffer);
      FirstImage.GraphBuf.RescaleRgb(FirstImage.ClientSize.X, FirstImage.ClientSize.Y);
      FirstImage.GraphBuf.ConvertRgbTo565;
    end;
    FileObject.ReadBuffer(@ByteCount, 4);
    if ByteCount > 0 then
    begin
      Buffer.SetSize(ByteCount);
      FileObject.ReadBuffer(Buffer.Data, ByteCount);
    end;
    if ByteCount > 0 then
    begin
      Buffer.SetPosition(0);
      SecondImage.GraphBuf.LoadFromBuffer(Buffer);
      // Native deliberately uses the first control's dimensions for both previews.
      SecondImage.GraphBuf.RescaleRgb(FirstImage.ClientSize.X, FirstImage.ClientSize.Y);
      SecondImage.GraphBuf.ConvertRgbTo565;
    end;
    FileObject.ReleaseHandle;
  except
    FirstImage.GraphBuf.Clear;
    SecondImage.GraphBuf.Clear;
  end;
  FileObject.Free;
  Buffer.Free;
  if PreviewTimer <> nil then
  begin
    CancelCallbackTimer(PreviewTimer);
    PreviewTimer := nil;
  end;
  PreviewTimer := ScheduleCallbackTimer(250, 250, FinishPreviewDelay);
  PreviewSound.SetVolume(1);
end;

procedure TfSaveManager.FinishPreviewDelay(Timer: PCallbackTimerGI; UserData: PtrInt);
begin
  PreviewSound.SetVolume(0);
  if PreviewTimer <> nil then
  begin
    CancelCallbackTimer(PreviewTimer);
    PreviewTimer := nil;
  end;
  if not IsSlotEmpty(SelectedSlot) or ((SelectedSlot = 0) and (SaveManagerMode = smmSave)) then
  begin
    GetByName('GameImage').SetActive(True);
    GetByName('GameImage2').SetActive(True);
  end
  else
  begin
    GetByName('GameImage').SetActive(False);
    GetByName('GameImage2').SetActive(False);
  end;
end;

procedure TfSaveManager.SelectMusic;
begin
end;

procedure LinkRecoveredTypes;
begin
  TEditGI.ClassName;
  TGraphBufGI.ClassName;
  TGraphButtonGI.ClassName;
  TImageGI.ClassName;
  TLabelGI.ClassName;
  TPanelGI.ClassName;
  TPanelScrollBarGI.ClassName;
  TgaiGI.ClassName;
end;
end.
