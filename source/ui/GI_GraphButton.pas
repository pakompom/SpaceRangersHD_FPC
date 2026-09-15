{$EXCESSPRECISION OFF}
unit GI_GraphButton;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_BlockPar,
  GI_Image,
  GI_Label,
  GI_Main,
  GI_MessageLoop,
  Types;
type
  TGraphButtonGI = class;
  {$Z1}
  TGraphButtonKindGI = (gbkNormal = 0, gbkFix = 1, gbkDisable = 2, gbkFixDisable = 3);
  {$Z1}
  TGraphButtonHitKindGI = (gbhRect = 0, gbhGraph = 1, gbhImageHit = 2);
  TGraphButtonGI = class(TObjectGI)
    Kind: TGraphButtonKindGI;
    HitKind: TGraphButtonHitKindGI;
    Down: Boolean;
    Disabled: Boolean;
    Gap124: array[0..3] of Byte;
    DownCallback: TObjectNotifyEventGI;
    UpCallback: TObjectNotifyEventGI;
    StateChangedCallback: TObjectNotifyEventGI;
    ImageNormal: TImageGI;
    ImageNormalActive: TImageGI;
    ImageDown: TImageGI;
    ImageDownActive: TImageGI;
    ImageDisabled: TImageGI;
    ImageDisabledActive: TImageGI;
    ImageHit: TImageGI;
    CaptionLabel: TLabelGI;
    NormalOffset: TPoint;
    NormalActiveOffset: TPoint;
    DownOffset: TPoint;
    DownActiveOffset: TPoint;
    DisabledOffset: TPoint;
    DisabledActiveOffset: TPoint;
    HitOffset: TPoint;
    EnterSound: WideString;
    LeaveSound: WideString;
    ClickSound: WideString;
    CaptionOffsets: TRect;
    CaptionColors: array[0..5] of Cardinal;
    CaptionShadowColors: array[0..5] of Cardinal;
    CaptionAlignX: TTextAlignXGI;
    CaptionAlignY: TTextAlignYGI;
    Gap1E6: array[0..1] of Byte;
    ImageAutoUpdateFlags: Cardinal;
    UpOnlyDown: Boolean;
    Gap1ED: array[0..2] of Byte;
    OnPressCode: TBlockParEC;
    procedure Clear; override;
    procedure SetSize(Size: TPoint); override;
    procedure SetOrigin(Origin: TPoint); override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure ProcessMouseMove(KeyState: Cardinal; Point: TPoint); override;
    procedure OnMouseEnter; override;
    procedure OnMouseLeave; override;
    procedure OnActivate; override;
    procedure OnDeactivate; override;
    procedure ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint); override;
    procedure ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint); override;
    procedure ProcessLeftButtonDoubleClick(KeyState: Cardinal; Point: TPoint); override;
    procedure OnHoverGained; override;
    procedure OnHoverLost; override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    procedure UpdateAutoGeometry; override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure SetCaptionFontName(const FontName: WideString);
    procedure SetCaption(const Text: WideString);
    procedure SetCaptionColor(Value: Cardinal);
    procedure SetCaptionShadowOffset(Value: Integer);
    procedure SetImageNormalPath(const Path: WideString);
    procedure SetImageNormalActivePath(const Path: WideString);
    procedure SetImageDownPath(const Path: WideString);
    procedure SetImageDownActivePath(const Path: WideString);
    procedure SetImageDisabledPath(const Path: WideString);
    procedure SetImageDisabledActivePath(const Path: WideString);
    procedure SetImageHitPath(const Path: WideString);
    procedure SetKind(Value: TGraphButtonKindGI);
    function HitTest(Point: TPoint): Boolean;
    procedure SetDown(Value: Boolean);
    procedure SetDisabled(Value: Boolean);
    function IsHovered: Boolean;
    procedure SetHovered(Value: Boolean);
    function GetMaxStateImageSize: TPoint;
    procedure UpdateStateVisuals;
    procedure UpdateStateImagePlacement;
    procedure ExecuteOnPressCode;
    procedure LoadButtonProperties(Block: TBlockParEC);
  end;
implementation
uses
  Classes,
  EC_Str,
  EC_Struct,
  GR_Main,
  GR_Sound,
  Math,
  Windows;

constructor TGraphButtonGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  Kind := gbkNormal;
  HitKind := gbhRect;
  UpOnlyDown := False;
  CaptionColors[0] := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  CaptionColors[1] := CaptionColors[0];
  CaptionColors[2] := CaptionColors[0];
  CaptionColors[3] := CaptionColors[0];
  CaptionColors[4] := CaptionColors[0];
  CaptionColors[5] := CaptionColors[0];
  CaptionAlignX := taxCenter;
  CaptionAlignY := tayCenterEx;
  OnPressCode := nil;
end;

destructor TGraphButtonGI.Destroy;
begin
  inherited Destroy;
end;

procedure TGraphButtonGI.Clear;
begin
  Kind := gbkNormal;
  if ImageNormal <> nil then
  begin
    ImageNormal.Free;
    ImageNormal := nil;
  end;
  if ImageNormalActive <> nil then
  begin
    ImageNormalActive.Free;
    ImageNormalActive := nil;
  end;
  if ImageDown <> nil then
  begin
    ImageDown.Free;
    ImageDown := nil;
  end;
  if ImageDownActive <> nil then
  begin
    ImageDownActive.Free;
    ImageDownActive := nil;
  end;
  if ImageDisabled <> nil then
  begin
    ImageDisabled.Free;
    ImageDisabled := nil;
  end;
  if ImageDisabledActive <> nil then
  begin
    ImageDisabledActive.Free;
    ImageDisabledActive := nil;
  end;
  if ImageHit <> nil then
  begin
    ImageHit.Free;
    ImageHit := nil;
  end;
  if CaptionLabel <> nil then
  begin
    CaptionLabel.Free;
    CaptionLabel := nil;
  end;
  inherited Clear;
end;

procedure TGraphButtonGI.SetCaptionFontName(const FontName: WideString);
begin
  if CaptionLabel = nil then
  begin
    CaptionLabel := TLabelGI.Create(Self);
    CaptionLabel.SetPosition(Classes.Point(0, 0));
    CaptionLabel.SetSize(ClientSize);
    CaptionLabel.SetDepth(-9999);
    CaptionLabel.SetTextAlignX(CaptionAlignX);
    CaptionLabel.SetTextAlignY(CaptionAlignY);
  end;
  CaptionLabel.SetFontName(FontName);
end;

procedure TGraphButtonGI.SetCaption(const Text: WideString);
begin
  if CaptionLabel = nil then
  begin
    CaptionLabel := TLabelGI.Create(Self);
    CaptionLabel.SetPosition(Classes.Point(0, 0));
    CaptionLabel.SetSize(ClientSize);
    CaptionLabel.SetDepth(-9999);
    CaptionLabel.SetTextAlignX(CaptionAlignX);
    CaptionLabel.SetTextAlignY(CaptionAlignY);
  end;
  CaptionLabel.SetText(Text);
end;

procedure TGraphButtonGI.SetCaptionColor(Value: Cardinal);
begin
  CaptionColors[0] := Value;
  CaptionColors[1] := Value;
  CaptionColors[2] := Value;
  CaptionColors[3] := Value;
  CaptionColors[4] := Value;
  CaptionColors[5] := Value;
  if CaptionLabel = nil then
  begin
    CaptionLabel := TLabelGI.Create(Self);
    CaptionLabel.SetPosition(Classes.Point(0, 0));
    CaptionLabel.SetSize(ClientSize);
    CaptionLabel.SetDepth(-9999);
    CaptionLabel.SetTextAlignX(CaptionAlignX);
    CaptionLabel.SetTextAlignY(CaptionAlignY);
  end;
  CaptionLabel.SetTextColor(Value);
end;

procedure TGraphButtonGI.SetCaptionShadowOffset(Value: Integer);
begin
  if CaptionLabel = nil then
  begin
    CaptionLabel := TLabelGI.Create(Self);
    CaptionLabel.SetPosition(Classes.Point(0, 0));
    CaptionLabel.SetSize(ClientSize);
    CaptionLabel.SetDepth(-9999);
    CaptionLabel.SetTextAlignX(CaptionAlignX);
    CaptionLabel.SetTextAlignY(CaptionAlignY);
  end;
  CaptionLabel.SetShadowOffset(Value);
end;

procedure TGraphButtonGI.SetImageNormalPath(const Path: WideString);
begin
  if ImageNormal = nil then
    ImageNormal := TImageGI.Create(Self);
  ImageNormal.SetDepth(1);
  ImageNormal.AutoUpdateFlags := ImageAutoUpdateFlags;
  ImageNormal.SetImagePath(Path);
  ImageNormal.SetSize(ImageNormal.GetContentSize);
  ImageNormal.SetPosition(NormalOffset);
end;

procedure TGraphButtonGI.SetImageNormalActivePath(const Path: WideString);
begin
  if ImageNormalActive = nil then
    ImageNormalActive := TImageGI.Create(Self);
  ImageNormalActive.SetDepth(1);
  ImageNormalActive.AutoUpdateFlags := ImageAutoUpdateFlags;
  ImageNormalActive.SetImagePath(Path);
  ImageNormalActive.SetSize(ImageNormalActive.GetContentSize);
  ImageNormalActive.SetPosition(NormalActiveOffset);
end;

procedure TGraphButtonGI.SetImageDownPath(const Path: WideString);
begin
  if ImageDown = nil then
    ImageDown := TImageGI.Create(Self);
  ImageDown.SetDepth(1);
  ImageDown.AutoUpdateFlags := ImageAutoUpdateFlags;
  ImageDown.SetImagePath(Path);
  ImageDown.SetSize(ImageDown.GetContentSize);
  ImageDown.SetPosition(DownOffset);
end;

procedure TGraphButtonGI.SetImageDownActivePath(const Path: WideString);
begin
  if ImageDownActive = nil then
    ImageDownActive := TImageGI.Create(Self);
  ImageDownActive.SetDepth(1);
  ImageDownActive.AutoUpdateFlags := ImageAutoUpdateFlags;
  ImageDownActive.SetImagePath(Path);
  ImageDownActive.SetSize(ImageDownActive.GetContentSize);
  ImageDownActive.SetPosition(DownActiveOffset);
end;

procedure TGraphButtonGI.SetImageDisabledPath(const Path: WideString);
begin
  if ImageDisabled = nil then
    ImageDisabled := TImageGI.Create(Self);
  ImageDisabled.SetDepth(1);
  ImageDisabled.AutoUpdateFlags := ImageAutoUpdateFlags;
  ImageDisabled.SetImagePath(Path);
  ImageDisabled.SetSize(ImageDisabled.GetContentSize);
  ImageDisabled.SetPosition(DisabledOffset);
end;

procedure TGraphButtonGI.SetImageDisabledActivePath(const Path: WideString);
begin
  if ImageDisabledActive = nil then
    ImageDisabledActive := TImageGI.Create(Self);
  ImageDisabledActive.SetDepth(1);
  ImageDisabledActive.AutoUpdateFlags := ImageAutoUpdateFlags;
  ImageDisabledActive.SetImagePath(Path);
  ImageDisabledActive.SetSize(ImageDisabledActive.GetContentSize);
  ImageDisabledActive.SetPosition(DisabledActiveOffset);
end;

procedure TGraphButtonGI.SetImageHitPath(const Path: WideString);
begin
  if ImageHit = nil then
    ImageHit := TImageGI.Create(Self);
  ImageHit.SetImagePath(Path);
  ImageHit.SetSize(ImageHit.GetContentSize);
  ImageHit.SetPosition(HitOffset);
end;

procedure TGraphButtonGI.SetKind(Value: TGraphButtonKindGI);
begin
  if Kind <> Value then
  begin
    Kind := Value;
    UpdateStateVisuals;
  end;
end;

function TGraphButtonGI.HitTest(Point: TPoint): Boolean;
begin
  Result := False;
  if HitKind = gbhRect then
    Result := ContainsPoint(Point)
  else if HitKind = gbhGraph then
  begin
    if ImageNormal <> nil then
      Result := ImageNormal.HitTestPixel(Point);
    if Result then
      Exit;
    if ImageNormalActive <> nil then
      Result := ImageNormalActive.HitTestPixel(Point);
    if Result then
      Exit;
    if ImageDown <> nil then
      Result := ImageDown.HitTestPixel(Point);
    if Result then
      Exit;
    if ImageDownActive <> nil then
      Result := ImageDownActive.HitTestPixel(Point);
    if Result then
      Exit;
    if ImageDisabled <> nil then
      Result := ImageDisabled.HitTestPixel(Point);
    if Result then
      Exit;
    if ImageDisabledActive <> nil then
      Result := ImageDisabledActive.HitTestPixel(Point);
    if Result then
      Exit;
  end
  else if HitKind = gbhImageHit then
  begin
    if ImageHit <> nil then
      Result := ImageHit.HitTestPixel(Point);
  end;
end;

procedure TGraphButtonGI.SetDown(Value: Boolean);
begin
  if Down <> Value then
  begin
    Down := Value;
    UpdateStateVisuals;
  end;
end;

procedure TGraphButtonGI.SetDisabled(Value: Boolean);
begin
  if Disabled <> Value then
  begin
    Disabled := Value;
    UpdateStateVisuals;
  end;
end;

function TGraphButtonGI.IsHovered: Boolean;
begin
  Result := MessageLoop.HoveredControl = Self;
end;

procedure TGraphButtonGI.SetHovered(Value: Boolean);
begin
  if Value then
    MessageLoop.SetHoveredControl(Self)
  else if MessageLoop.HoveredControl = Self then
    MessageLoop.SetHoveredControl(nil);
end;

function TGraphButtonGI.GetMaxStateImageSize: TPoint;
var
  Size: TPoint;
begin
  Result.X := 0;
  Result.Y := 0;
  // Native comparisons are unconditional, including before Size is initialized.
  if ImageNormal <> nil then
    Size := ImageNormal.GetContentSize;
  Result.X := Max(Result.X, Size.X);
  Result.Y := Max(Result.Y, Size.Y);
  if ImageNormalActive <> nil then
    Size := ImageNormalActive.GetContentSize;
  Result.X := Max(Result.X, Size.X);
  Result.Y := Max(Result.Y, Size.Y);
  if ImageDown <> nil then
    Size := ImageDown.GetContentSize;
  Result.X := Max(Result.X, Size.X);
  Result.Y := Max(Result.Y, Size.Y);
  if ImageDownActive <> nil then
    Size := ImageDownActive.GetContentSize;
  Result.X := Max(Result.X, Size.X);
  Result.Y := Max(Result.Y, Size.Y);
  if ImageDisabled <> nil then
    Size := ImageDisabled.GetContentSize;
  Result.X := Max(Result.X, Size.X);
  Result.Y := Max(Result.Y, Size.Y);
  if ImageDisabledActive <> nil then
    Size := ImageDisabledActive.GetContentSize;
  Result.X := Max(Result.X, Size.X);
  Result.Y := Max(Result.Y, Size.Y);
  if ImageHit <> nil then
    Size := ImageHit.GetContentSize;
  Result.X := Max(Result.X, Size.X);
  Result.Y := Max(Result.Y, Size.Y);
end;

procedure TGraphButtonGI.UpdateStateVisuals;
begin
  if ImageNormal <> nil then
    ImageNormal.SetActive(False);
  if ImageNormalActive <> nil then
    ImageNormalActive.SetActive(False);
  if ImageDown <> nil then
    ImageDown.SetActive(False);
  if ImageDownActive <> nil then
    ImageDownActive.SetActive(False);
  if ImageDisabled <> nil then
    ImageDisabled.SetActive(False);
  if ImageDisabledActive <> nil then
    ImageDisabledActive.SetActive(False);
  if ImageHit <> nil then
    ImageHit.SetActive(False);
  if Disabled and ((Kind = gbkDisable) or (Kind = gbkFixDisable)) then
  begin
    if MessageLoop.HoveredControl = Self then
    begin
      if ImageDisabledActive <> nil then
        ImageDisabledActive.SetActive(True)
      else if ImageDisabled <> nil then
        ImageDisabled.SetActive(True);
    end
    else if ImageDisabled <> nil then
      ImageDisabled.SetActive(True);
  end
  else
  begin
    if Down then
    begin
      if MessageLoop.HoveredControl = Self then
      begin
        if ImageDownActive <> nil then
          ImageDownActive.SetActive(True)
        else if ImageDown <> nil then
          ImageDown.SetActive(True);
      end
      else if ImageDown <> nil then
        ImageDown.SetActive(True);
    end
    else
    begin
      if MessageLoop.HoveredControl = Self then
      begin
        if ImageNormalActive <> nil then
          ImageNormalActive.SetActive(True)
        else if ImageNormal <> nil then
          ImageNormal.SetActive(True);
      end
      else if ImageNormal <> nil then
        ImageNormal.SetActive(True);
    end;
  end;
  if CaptionLabel <> nil then
  begin
    if not Down then
      CaptionLabel.SetPosition(CaptionOffsets.TopLeft)
    else
      CaptionLabel.SetPosition(CaptionOffsets.BottomRight);
    if Disabled and ((Kind = gbkDisable) or (Kind = gbkFixDisable)) then
    begin
      if MessageLoop.HoveredControl = Self then
      begin
        CaptionLabel.SetTextColor(CaptionColors[5]);
        CaptionLabel.SetShadowColor(CaptionShadowColors[5]);
      end
      else
      begin
        CaptionLabel.SetTextColor(CaptionColors[4]);
        CaptionLabel.SetShadowColor(CaptionShadowColors[4]);
      end;
    end
    else
    begin
      if Down then
      begin
        if MessageLoop.HoveredControl = Self then
        begin
          CaptionLabel.SetTextColor(CaptionColors[3]);
          CaptionLabel.SetShadowColor(CaptionShadowColors[3]);
        end
        else
        begin
          CaptionLabel.SetTextColor(CaptionColors[2]);
          CaptionLabel.SetShadowColor(CaptionShadowColors[2]);
        end;
      end
      else
      begin
        if MessageLoop.HoveredControl = Self then
        begin
          CaptionLabel.SetTextColor(CaptionColors[1]);
          CaptionLabel.SetShadowColor(CaptionShadowColors[1]);
        end
        else
        begin
          CaptionLabel.SetTextColor(CaptionColors[0]);
          CaptionLabel.SetShadowColor(CaptionShadowColors[0]);
        end;
      end;
    end;
  end;
  if ImageNormal <> nil then
    if ImageNormal.Active then
      ImageNormal.RestartPlayback;
  if ImageNormalActive <> nil then
    if ImageNormalActive.Active then
      ImageNormalActive.RestartPlayback;
  if ImageDown <> nil then
    if ImageDown.Active then
      ImageDown.RestartPlayback;
  if ImageDownActive <> nil then
    if ImageDownActive.Active then
      ImageDownActive.RestartPlayback;
  if ImageDisabled <> nil then
    if ImageDisabled.Active then
      ImageDisabled.RestartPlayback;
  if ImageDisabledActive <> nil then
    if ImageDisabledActive.Active then
      ImageDisabledActive.RestartPlayback;
  Invalidate;
  if Assigned(StateChangedCallback) then
    StateChangedCallback(Self);
end;

procedure TGraphButtonGI.UpdateStateImagePlacement;
begin
  if ImageNormal <> nil then
    ImageNormal.SetPosition(NormalOffset);
  if ImageNormalActive <> nil then
    ImageNormalActive.SetPosition(NormalActiveOffset);
  if ImageDown <> nil then
    ImageDown.SetPosition(DownOffset);
  if ImageDownActive <> nil then
    ImageDownActive.SetPosition(DownActiveOffset);
  if ImageDisabled <> nil then
    ImageDisabled.SetPosition(DisabledOffset);
  if ImageDisabledActive <> nil then
    ImageDisabledActive.SetPosition(DisabledActiveOffset);
  if ImageHit <> nil then
    ImageHit.SetPosition(HitOffset);
  if CaptionLabel <> nil then
  begin
    CaptionLabel.SetPosition(Classes.Point(0, 0));
    CaptionLabel.SetSize(ClientSize);
  end;
end;

procedure TGraphButtonGI.SetSize(Size: TPoint);
begin
  inherited SetSize(Size);
  UpdateStateImagePlacement;
end;

procedure TGraphButtonGI.SetOrigin(Origin: TPoint);
begin
  inherited SetOrigin(Origin);
  UpdateStateImagePlacement;
end;

procedure TGraphButtonGI.OnActivate;
begin
  inherited OnActivate;
  if HitTestCursor then
    MessageLoop.HoveredControl := Self;
  if (Kind = gbkNormal) or (Kind = gbkDisable) then
    Down := False;
  UpdateStateVisuals;
end;

procedure TGraphButtonGI.OnDeactivate;
begin
  inherited OnDeactivate;
  if MessageLoop.HoveredControl = Self then
    MessageLoop.HoveredControl := nil;
  if (Kind = gbkNormal) or (Kind = gbkDisable) then
    Down := False;
  UpdateStateVisuals;
end;

procedure TGraphButtonGI.OnMouseEnter;
begin
  inherited OnMouseEnter;
end;

procedure TGraphButtonGI.OnMouseLeave;
begin
  inherited OnMouseLeave;
  if MessageLoop.HoveredControl = Self then
    MessageLoop.SetHoveredControl(nil);
end;

procedure TGraphButtonGI.ProcessMouseMove(KeyState: Cardinal; Point: TPoint);
begin
  if MouseBlockingTest and IsOccludedAtPoint(AbsolutePosition) then
    Exit;
  if HitTest(Point) then
  begin
    if not Disabled then
      MessageLoop.SetHoveredControl(Self);
  end
  else if MessageLoop.HoveredControl = Self then
    MessageLoop.SetHoveredControl(nil);
end;

procedure TGraphButtonGI.OnHoverGained;
begin
  if (EnterSound <> '') and not Disabled then
    SoundManager.PlaySound(EnterSound);
  if Assigned(HelpCallback) then
    HelpCallback(Self, True);
  UpdateStateVisuals;
end;

procedure TGraphButtonGI.OnHoverLost;
begin
  if (Kind = gbkNormal) or (Kind = gbkDisable) then
  begin
    if Down then
    begin
      Down := False;
      if Assigned(UpCallback) then
        UpCallback(Self);
    end;
  end;
  if (LeaveSound <> '') and not Disabled then
    SoundManager.PlaySound(LeaveSound);
  if Assigned(HelpCallback) then
    HelpCallback(Self, False);
  UpdateStateVisuals;
end;

procedure TGraphButtonGI.ExecuteOnPressCode;
begin
  if OnPressCode <> nil then
  begin
    MessageLoop.QueueUiCode(OnPressCode, True);
    if Assigned(HelpCallback) then
      HelpCallback(Self, False);
  end
  else
    MessageLoop.RefreshMouseDispatch;
end;

procedure TGraphButtonGI.ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonDown(KeyState, Point);
  if IsOccludedAtPoint(Point) then
    Exit;
  if not HitTest(Point) then
    Exit;
  if MessageLoop.HoveredControl <> Self then
    Exit;
  if ((Kind = gbkDisable) or (Kind = gbkFixDisable)) and (Disabled = True) then
    Exit;
  if (Kind = gbkNormal) or (Kind = gbkDisable) then
  begin
    Down := True;
    if ClickSound <> '' then
      SoundManager.PlaySound(ClickSound);
    if Assigned(DownCallback) then
    begin
      DownCallback(Self);
      ExecuteOnPressCode;
    end;
  end
  else
  begin
    if Down then
    begin
      Down := False;
      if Assigned(UpCallback) then
      begin
        UpCallback(Self);
        ExecuteOnPressCode;
      end
      else if not Assigned(DownCallback) then
        ExecuteOnPressCode;
    end
    else
    begin
      Down := True;
      if ClickSound <> '' then
        SoundManager.PlaySound(ClickSound);
      if Assigned(DownCallback) then
      begin
        DownCallback(Self);
        ExecuteOnPressCode;
      end
      else if not Assigned(UpCallback) then
        ExecuteOnPressCode;
    end;
  end;
  UpdateStateVisuals;
end;

procedure TGraphButtonGI.ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint);
var
  WasDown: Boolean;
begin
  inherited ProcessLeftButtonUp(KeyState, Point);
  if IsOccludedAtPoint(Point) then
    Exit;
  if not HitTest(Point) then
    Exit;
  if MessageLoop.HoveredControl <> Self then
    Exit;
  if ((Kind = gbkDisable) or (Kind = gbkFixDisable)) and (Disabled = True) then
    Exit;
  if (Kind = gbkNormal) or (Kind = gbkDisable) then
  begin
    WasDown := Down;
    Down := False;
    if Assigned(UpCallback) and MessageLoop.ConsumeTimerTickChange then
    begin
      if (UpOnlyDown = False) or (WasDown <> False) then
        UpCallback(Self);
      ExecuteOnPressCode;
    end;
    if not Assigned(UpCallback) and not Assigned(DownCallback) then
      ExecuteOnPressCode;
    UpdateStateVisuals;
  end;
end;

procedure TGraphButtonGI.ProcessLeftButtonDoubleClick(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonDoubleClick(KeyState, Point);
end;

procedure TGraphButtonGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadButtonProperties(UiStyleConfig.GetBlockByPath(Path));
end;

procedure TGraphButtonGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadButtonProperties(Block);
end;

procedure TGraphButtonGI.LoadButtonProperties(Block: TBlockParEC);
var
  Text: WideString;
begin
  if Block.CountParams('CaptionAlignY') > 0 then
  begin
    Text := TrimWideString(Block.GetParam('CaptionAlignY'));
    CaptionAlignY := ParseTextAlignYName(Text);
  end;
  if Block.CountParams('CaptionAlignX') > 0 then
  begin
    Text := TrimWideString(Block.GetParam('CaptionAlignX'));
    CaptionAlignX := ParseTextAlignXName(Text);
  end;
  if Block.CountParams('Font') > 0 then
    SetCaptionFontName(Block.GetParam('Font'));
  if Block.CountParams('Caption') > 0 then
  begin
    Text := Block.GetParam('Caption');
    SetCaption(Text);
    if LanguageDataConfig.CountParamsByPath(Text) > 0 then
      SetCaption(LanguageDataConfig.GetParamByPathOrMarker(Text));
  end;
  if Block.CountParams('CaptionColor') > 0 then
    SetCaptionColor(GetColorGI(Block.GetParam('CaptionColor')));
  if Block.CountParams('CaptionShadow') > 0 then
    SetCaptionShadowOffset(ExtractDigitsToIntW(Block.GetParam('CaptionShadow')));
  if Block.CountParams('CaptionColorNormal') > 0 then
    CaptionColors[0] := GetColorGI(Block.GetParam('CaptionColorNormal'));
  if Block.CountParams('CaptionColorNormalA') > 0 then
    CaptionColors[1] := GetColorGI(Block.GetParam('CaptionColorNormalA'));
  if Block.CountParams('CaptionColorDown') > 0 then
    CaptionColors[2] := GetColorGI(Block.GetParam('CaptionColorDown'));
  if Block.CountParams('CaptionColorDownA') > 0 then
    CaptionColors[3] := GetColorGI(Block.GetParam('CaptionColorDownA'));
  if Block.CountParams('CaptionColorDisable') > 0 then
    CaptionColors[4] := GetColorGI(Block.GetParam('CaptionColorDisable'));
  if Block.CountParams('CaptionColorDisableA') > 0 then
    CaptionColors[5] := GetColorGI(Block.GetParam('CaptionColorDisableA'));
  if Block.CountParams('CaptionShadowColorNormal') > 0 then
    CaptionShadowColors[0] := GetColorGI(Block.GetParam('CaptionShadowColorNormal'));
  if Block.CountParams('CaptionShadowColorNormalA') > 0 then
    CaptionShadowColors[1] := GetColorGI(Block.GetParam('CaptionShadowColorNormalA'));
  if Block.CountParams('CaptionShadowColorDown') > 0 then
    CaptionShadowColors[2] := GetColorGI(Block.GetParam('CaptionShadowColorDown'));
  if Block.CountParams('CaptionShadowColorDownA') > 0 then
    CaptionShadowColors[3] := GetColorGI(Block.GetParam('CaptionShadowColorDownA'));
  if Block.CountParams('CaptionShadowColorDisable') > 0 then
    CaptionShadowColors[4] := GetColorGI(Block.GetParam('CaptionShadowColorDisable'));
  if Block.CountParams('CaptionShadowColorDisableA') > 0 then
    CaptionShadowColors[5] := GetColorGI(Block.GetParam('CaptionShadowColorDisableA'));
  if Block.CountParams('Kind') > 0 then
  begin
    Text := Block.GetParam('Kind');
    if Text = 'Normal' then
      SetKind(gbkNormal)
    else if Text = 'Fix' then
      SetKind(gbkFix)
    else if Text = 'Disable' then
      SetKind(gbkDisable)
    else if Text = 'FixDisable' then
      SetKind(gbkFixDisable);
  end;
  if Block.CountParams('Auto') > 0 then
    ImageAutoUpdateFlags := ParseAutoGeometryFlagsGI(Block.GetParam('Auto'));
  if Block.CountParams('KindHit') > 0 then
  begin
    Text := Block.GetParam('KindHit');
    if Text = 'Rect' then
      HitKind := gbhRect
    else if Text = 'Graph' then
      HitKind := gbhGraph
    else if Text = 'ImageHit' then
      HitKind := gbhImageHit;
  end;
  if Block.CountParams('ImageNormal') > 0 then
    SetImageNormalPath(Block.GetParam('ImageNormal'));
  if Block.CountParams('ImageNormalA') > 0 then
    SetImageNormalActivePath(Block.GetParam('ImageNormalA'));
  if Block.CountParams('ImageDown') > 0 then
    SetImageDownPath(Block.GetParam('ImageDown'));
  if Block.CountParams('ImageDownA') > 0 then
    SetImageDownActivePath(Block.GetParam('ImageDownA'));
  if Block.CountParams('ImageDisable') > 0 then
    SetImageDisabledPath(Block.GetParam('ImageDisable'));
  if Block.CountParams('ImageDisableA') > 0 then
    SetImageDisabledActivePath(Block.GetParam('ImageDisableA'));
  if Block.CountParams('ImageHit') > 0 then
    SetImageHitPath(Block.GetParam('ImageHit'));
  if Block.CountParams('ImageNormal_Pos') > 0 then
    NormalOffset := GetPointGI(Block.GetParam('ImageNormal_Pos'))
  else
    NormalOffset := LocalPosition;
  if Block.CountParams('ImageNormalA_Pos') > 0 then
    NormalActiveOffset := GetPointGI(Block.GetParam('ImageNormalA_Pos'))
  else
    NormalActiveOffset := LocalPosition;
  if Block.CountParams('ImageDown_Pos') > 0 then
    DownOffset := GetPointGI(Block.GetParam('ImageDown_Pos'))
  else
    DownOffset := LocalPosition;
  if Block.CountParams('ImageDownA_Pos') > 0 then
    DownActiveOffset := GetPointGI(Block.GetParam('ImageDownA_Pos'))
  else
    DownActiveOffset := LocalPosition;
  if Block.CountParams('ImageDisable_Pos') > 0 then
    DisabledOffset := GetPointGI(Block.GetParam('ImageDisable_Pos'))
  else
    DisabledOffset := LocalPosition;
  if Block.CountParams('ImageDisableA_Pos') > 0 then
    DisabledActiveOffset := GetPointGI(Block.GetParam('ImageDisableA_Pos'))
  else
    DisabledActiveOffset := LocalPosition;
  if Block.CountParams('ImageHit_Pos') > 0 then
    HitOffset := GetPointGI(Block.GetParam('ImageHit_Pos'))
  else
    HitOffset := LocalPosition;
  NormalOffset := SubtractPoints(NormalOffset, LocalPosition);
  NormalActiveOffset := SubtractPoints(NormalActiveOffset, LocalPosition);
  DownOffset := SubtractPoints(DownOffset, LocalPosition);
  DownActiveOffset := SubtractPoints(DownActiveOffset, LocalPosition);
  DisabledOffset := SubtractPoints(DisabledOffset, LocalPosition);
  DisabledActiveOffset := SubtractPoints(DisabledActiveOffset, LocalPosition);
  HitOffset := SubtractPoints(HitOffset, LocalPosition);
  if Block.CountParams('Disable') > 0 then
    SetDisabled(ParseEnabledNameGI(Block.GetParam('Disable')));
  if Block.CountParams('Down') > 0 then
    SetDown(ParseEnabledNameGI(Block.GetParam('Down')));
  if Block.CountParams('UpOnlyDown') > 0 then
    UpOnlyDown := ParseEnabledNameGI(Block.GetParam('UpOnlyDown'));
  if Block.CountParams('SoundEnter') > 0 then
    EnterSound := Block.GetParam('SoundEnter');
  if Block.CountParams('SoundLeave') > 0 then
    LeaveSound := Block.GetParam('SoundLeave');
  if Block.CountParams('SoundClick') > 0 then
    ClickSound := Block.GetParam('SoundClick');
  if Block.CountParams('CaptionSme') > 0 then
    CaptionOffsets := GetRectGI(Block.GetParam('CaptionSme'));
  if Block.CountBlocks('OnPressCode') > 0 then
    OnPressCode := Block.GetBlock('OnPressCode');
  UpdateStateImagePlacement;
end;

procedure TGraphButtonGI.UpdateAutoGeometry;
var
  Bounds, ImageBounds: TRect;
begin
  inherited UpdateAutoGeometry;
  if ImageAutoUpdateFlags <> 0 then
  begin
    Bounds.Left := 0;
    Bounds.Top := 0;
    Bounds.Right := 0;
    Bounds.Bottom := 0;
    if ImageNormal <> nil then
    begin
      ImageBounds.TopLeft := ImageNormal.GetContentOrigin;
      ImageBounds.BottomRight := ImageNormal.GetContentSize;
      ImageBounds.BottomRight := AddPoints(ImageBounds.TopLeft, ImageBounds.BottomRight);
      Bounds := ImageBounds;
    end;
    if ImageNormalActive <> nil then
    begin
      ImageBounds.TopLeft := ImageNormalActive.GetContentOrigin;
      ImageBounds.BottomRight := ImageNormalActive.GetContentSize;
      ImageBounds.BottomRight := AddPoints(ImageBounds.TopLeft, ImageBounds.BottomRight);
      if Bounds.Right - Bounds.Left < 1 then
        Bounds := ImageBounds
      else
        Windows.UnionRect(Bounds, Bounds, ImageBounds);
    end;
    if ImageDown <> nil then
    begin
      ImageBounds.TopLeft := ImageDown.GetContentOrigin;
      ImageBounds.BottomRight := ImageDown.GetContentSize;
      ImageBounds.BottomRight := AddPoints(ImageBounds.TopLeft, ImageBounds.BottomRight);
      if Bounds.Right - Bounds.Left < 1 then
        Bounds := ImageBounds
      else
        Windows.UnionRect(Bounds, Bounds, ImageBounds);
    end;
    if ImageDownActive <> nil then
    begin
      ImageBounds.TopLeft := ImageDownActive.GetContentOrigin;
      ImageBounds.BottomRight := ImageDownActive.GetContentSize;
      ImageBounds.BottomRight := AddPoints(ImageBounds.TopLeft, ImageBounds.BottomRight);
      if Bounds.Right - Bounds.Left < 1 then
        Bounds := ImageBounds
      else
        Windows.UnionRect(Bounds, Bounds, ImageBounds);
    end;
    if ImageDisabled <> nil then
    begin
      ImageBounds.TopLeft := ImageDisabled.GetContentOrigin;
      ImageBounds.BottomRight := ImageDisabled.GetContentSize;
      ImageBounds.BottomRight := AddPoints(ImageBounds.TopLeft, ImageBounds.BottomRight);
      if Bounds.Right - Bounds.Left < 1 then
        Bounds := ImageBounds
      else
        Windows.UnionRect(Bounds, Bounds, ImageBounds);
    end;
    if ImageDisabledActive <> nil then
    begin
      ImageBounds.TopLeft := ImageDisabledActive.GetContentOrigin;
      ImageBounds.BottomRight := ImageDisabledActive.GetContentSize;
      ImageBounds.BottomRight := AddPoints(ImageBounds.TopLeft, ImageBounds.BottomRight);
      if Bounds.Right - Bounds.Left < 1 then
        Bounds := ImageBounds
      else
        Windows.UnionRect(Bounds, Bounds, ImageBounds);
    end;
    if (ImageAutoUpdateFlags and agfPosition) = agfPosition then
      SetPosition(Parent.ToLocalPoint(Bounds.TopLeft));
    if (ImageAutoUpdateFlags and agfSize) = agfSize then
      SetSize(SubtractPoints(Bounds.BottomRight, Bounds.TopLeft));
  end;
  inherited UpdateAutoGeometry;
end;

end.
