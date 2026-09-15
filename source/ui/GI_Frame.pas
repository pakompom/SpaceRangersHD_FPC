{$EXCESSPRECISION OFF}
unit GI_Frame;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_BlockPar,
  GI_MessageLoop,
  Types;
type
  TFrameGI = class;
  {$Z1}
  TFrameKindGI = (fkHide = 0, fkRect = 1);
  TFrameGI = class(TObjectGI)
    Kind: TFrameKindGI;
    Gap121: array[0..2] of Byte;
    Color: Cardinal;
    FillColor: Cardinal;
    Fill: Boolean;
    FillAlpha: Byte;
    Gap12E: array[0..1] of Byte;
    procedure Clear; override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure Draw(ClipRect: TRect); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure SetKind(Value: TFrameKindGI);
    procedure SetColor(Value: Cardinal);
    procedure SetFillColor(Value: Cardinal);
    procedure SetFill(Value: Boolean);
    procedure LoadFrameProperties(Block: TBlockParEC);
  end;
implementation
uses
  Math,
  GlobalsV,
  Classes,
  EC_Mem,
  GI_Main,
  GR_DX,
  GR_Main;

constructor TFrameGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  Kind := fkHide;
  Fill := False;
  FillAlpha := 255;
end;

destructor TFrameGI.Destroy;
begin
  inherited Destroy;
end;

procedure TFrameGI.Clear;
begin
  Kind := fkHide;
  inherited Clear;
end;

procedure TFrameGI.SetKind(Value: TFrameKindGI);
begin
  if Kind <> Value then
  begin
    Kind := Value;
    Invalidate;
  end;
end;

procedure TFrameGI.SetColor(Value: Cardinal);
begin
  if Color <> Value then
  begin
    Color := Value;
    Invalidate;
  end;
end;

procedure TFrameGI.SetFillColor(Value: Cardinal);
begin
  if FillColor <> Value then
  begin
    FillColor := Value;
    Invalidate;
  end;
end;

procedure TFrameGI.SetFill(Value: Boolean);
begin
  if Fill <> Value then
  begin
    Fill := Value;
    Invalidate;
  end;
end;

procedure TFrameGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadFrameProperties(UiStyleConfig.GetBlockByPath(Path));
end;

procedure TFrameGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadFrameProperties(Block);
end;

procedure TFrameGI.LoadFrameProperties(Block: TBlockParEC);
begin
  if Block.CountParams('Kind') > 0 then
  begin
    if Block.GetParam('Kind') = 'Hide' then
      Kind := fkHide
    else if Block.GetParam('Kind') = 'Rect' then
      Kind := fkRect;
  end;
  if Block.CountParams('Color') > 0 then
    SetColor(GetColorGI(Block.GetParam('Color')));
  if Block.CountParams('ColorFill') > 0 then
    SetFillColor(GetColorGI(Block.GetParam('ColorFill')));
  if Block.CountParams('Fill') > 0 then
    SetFill(ParseEnabledNameGI(Block.GetParam('Fill')));
end;

procedure TFrameGI.Draw(ClipRect: TRect);
begin
  if Fill then
  begin
    if HardwareRenderingEnabled then
    begin
      if FillAlpha = 255 then
        DrawColoredRect(
            ClipRect.Left,
            ClipRect.Top,
            ClipRect.Right - ClipRect.Left,
            ClipRect.Bottom - ClipRect.Top,
            Color565ToArgb(FillColor),
            255,
            True,
            @ClipRect
        )
      else
        DrawColoredRect(
            ClipRect.Left,
            ClipRect.Top,
            ClipRect.Right - ClipRect.Left,
            ClipRect.Bottom - ClipRect.Top,
            Color565ToArgb(FillColor),
            64,
            True,
            @ClipRect
        );
    end
    else
    begin
      if FillAlpha = 255 then
        Ex_OKGR_Fill_WORD(
            AddPointerOffset(
                ScreenRenderBuffer.GetPixels,
                ScreenRenderBuffer.PitchBytes * ClipRect.Top + ClipRect.Left * 2
            ),
            ScreenRenderBuffer.PitchBytes,
            ClipRect.Right - ClipRect.Left,
            ClipRect.Bottom - ClipRect.Top,
            FillColor
        )
      else
        ScreenRenderBuffer.DrawAlphaTrapezium16(
            HitTestBounds.Left,
            HitTestBounds.Right,
            HitTestBounds.Top,
            HitTestBounds.Left,
            HitTestBounds.Right,
            HitTestBounds.Bottom,
            FillColor,
            64,
            ClipRect
        );
    end;
  end;
  if Kind = fkRect then
  begin
    if HardwareRenderingEnabled then
    begin
      DrawAlphaLine(
          HitTestBounds.Left,
          HitTestBounds.Top,
          HitTestBounds.Right - 1,
          HitTestBounds.Top,
          Color,
          255,
          @ClipRect
      );
      DrawAlphaLine(
          HitTestBounds.Left,
          HitTestBounds.Bottom - 1,
          HitTestBounds.Right - 1,
          HitTestBounds.Bottom - 1,
          Color,
          255,
          @ClipRect
      );
      DrawAlphaLine(
          HitTestBounds.Left,
          HitTestBounds.Top,
          HitTestBounds.Left,
          HitTestBounds.Bottom - 1,
          Color,
          255,
          @ClipRect
      );
      DrawAlphaLine(
          HitTestBounds.Right - 1,
          HitTestBounds.Top,
          HitTestBounds.Right - 1,
          HitTestBounds.Bottom - 1,
          Color,
          255,
          @ClipRect
      );
    end
    else
    begin
      ScreenRenderBuffer.DrawLine16Clipped(
          Classes.Point(HitTestBounds.Left, HitTestBounds.Top),
          Classes.Point(HitTestBounds.Right - 1, HitTestBounds.Top),
          Color,
          ClipRect
      );
      ScreenRenderBuffer.DrawLine16Clipped(
          Classes.Point(HitTestBounds.Left, HitTestBounds.Bottom - 1),
          Classes.Point(HitTestBounds.Right - 1, HitTestBounds.Bottom - 1),
          Color,
          ClipRect
      );
      ScreenRenderBuffer.DrawLine16Clipped(
          Classes.Point(HitTestBounds.Left, HitTestBounds.Top),
          Classes.Point(HitTestBounds.Left, HitTestBounds.Bottom - 1),
          Color,
          ClipRect
      );
      ScreenRenderBuffer.DrawLine16Clipped(
          Classes.Point(HitTestBounds.Right - 1, HitTestBounds.Top),
          Classes.Point(HitTestBounds.Right - 1, HitTestBounds.Bottom - 1),
          Color,
          ClipRect
      );
    end;
  end;
end;

end.
