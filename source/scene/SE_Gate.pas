{$EXCESSPRECISION OFF}
unit SE_Gate;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  SE_Space,
  Types,
  Classes,
  EC_BlockPar,
  GI_MessageLoop,
  GI_RotateImageGAI,
  GI_Label;
type
  TGateEffectSE = class;
  TGateSE = class;
  TGateSE = class(TObjectSE)
    Angle: Byte;
    Gap4D: array[0..2] of Byte;
    State: Integer;
    StateStep: Integer;
    LabelText: WideString;
    Image: TRotateImageGaiGI;
    TextLabel: TLabelGI;
    TextRed: Single;
    TextGreen: Single;
    TextBlue: Single;
    TickCount: Integer;
    procedure AttachToSpace(ASpace: TSpaceSE); override;
    procedure DetachFromSpace; override;
    function GetAngle: Byte; override;
    procedure SetAngle(Value: Byte); override;
    function GetText: WideString; override;
    procedure SetText(const Value: WideString); override;
    procedure Advance; override;
    procedure SetSize(Value: TPoint); override;
    procedure LoadTemplate(Block: TBlockParEC); override;
    procedure ApplyConfig(Block: TBlockParEC); override;
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override;
    constructor Create(GraphKey: WideString; UnusedPosition: TPoint);
    destructor Destroy; override;
    procedure Open;
    procedure Close;
    procedure SetState(Value: Integer);
    procedure RebuildStateGraphics;
    procedure AdvanceAnimation(UnusedTimer: Pointer; UnusedData: Integer);
  end;
  TGateEffectSE = class(TObjectSE)
    Angle: Byte;
    Gap4D: array[0..2] of Byte;
    StateStep: Integer;
    Image: TRotateImageGaiGI;
    TickCount: Integer;
    procedure AttachToSpace(ASpace: TSpaceSE); override;
    procedure DetachFromSpace; override;
    function GetAngle: Byte; override;
    procedure SetAngle(Value: Byte); override;
    procedure Advance; override;
    procedure SetSize(Value: TPoint); override;
    procedure LoadTemplate(Block: TBlockParEC); override;
    procedure ApplyConfig(Block: TBlockParEC); override;
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override;
    constructor Create(GraphKey: WideString; UnusedPosition: TPoint);
    destructor Destroy; override;
    procedure RebuildStateGraphics;
    procedure AdvanceAnimation(UnusedTimer: Pointer; UnusedData: Integer);
  end;
implementation
uses
  GI_Main,
  Math,
  GR_Main,
  GR_GraphBuf,
  GlobalsV;

constructor TGateSE.Create(GraphKey: WideString; UnusedPosition: TPoint);
begin
  inherited Create(GraphKey, UnusedPosition);
  State := 0;
  TextRed := 1;
  TextGreen := 1;
  TextBlue := 1;
end;

destructor TGateSE.Destroy;
begin
  inherited Destroy;
end;

procedure TGateSE.AttachToSpace(ASpace: TSpaceSE);
var
  ImageSize: Integer;
begin
  if IsAttachedToSpace then
    Exit;
  ConfigureLoopSound('Gate');
  ConfigureRandomSound('Gate');
  inherited AttachToSpace(ASpace);
  TickCount := 0;
  Image := TRotateImageGaiGI.Create(Space.MapPanel);
  Image.SetPositionModeW(True);
  Image.SetDepthByName(DepthExpression);
  Image.SetPosition(Classes.Point(Round(Position.X), Round(Position.Y)));
  Image.SetAngle(Angle + 128);
  Image.SetAlpha(255);
  ImageSize := GiScalePixels(Min(200, Size.X));
  Image.SetImage(
      'Bm.Gate2.00?NoConvertPF',
      Classes.Point(ImageSize, ImageSize),
      Classes.Point(ImageSize div 2, ImageSize div 2)
  );
  TextLabel := TLabelGI.Create(Space.MapPanel);
  TextLabel.SetActive(False);
  TextLabel.SetFontName(NormalFontName);
  TextLabel.SetPositionModeW(True);
  TextLabel.SetDepthByName(DepthExpression);
  TextLabel.SetSize(Classes.Point(150, 20));
  TextLabel.SetPosition(
      Classes.Point(
          Round(Position.X - TextLabel.ClientSize.X / 2),
          Round(Position.Y + 50 + ImageSize div 2 - 40)
      )
  );
  TextLabel.SetText(LabelText);
  TextLabel.SetWordWrapEnabled(False);
  TextLabel.SetTextAlignX(taxCenter);
  TextLabel.SetTextAlignY(tayAuto);
  RebuildStateGraphics;
end;

procedure TGateSE.DetachFromSpace;
begin
  if IsAttachedToSpace then
  begin
    Image.SetActive(False);
    Image.Free;
    Image := nil;
    if TextLabel <> nil then
    begin
      TextLabel.SetActive(False);
      TextLabel.Free;
      TextLabel := nil;
    end;
    inherited DetachFromSpace;
  end;
end;

procedure TGateSE.SetSize(Value: TPoint);
begin
  if (Size.X <> Value.X) or (Size.Y <> Value.Y) then
    inherited SetSize(Value);
end;

function TGateSE.GetAngle: Byte;
begin
  Result := Angle;
end;

procedure TGateSE.SetAngle(Value: Byte);
begin
  Angle := Value;
  if IsAttachedToSpace then
    Image.SetAngle(Angle + 128);
end;

function TGateSE.GetText: WideString;
begin
  Result := LabelText;
end;

procedure TGateSE.SetText(const Value: WideString);
begin
  LabelText := Value;
  if IsAttachedToSpace then
    if TextLabel <> nil then
      TextLabel.SetText(LabelText);
end;

procedure TGateSE.Open;
begin
  if State = 0 then
  begin
    State := 1;
    StateStep := 0;
    if IsAttachedToSpace then
      RebuildStateGraphics;
  end;
end;

procedure TGateSE.Close;
begin
  if State = 2 then
  begin
    State := 3;
    StateStep := 0;
    if IsAttachedToSpace then
      RebuildStateGraphics;
  end;
end;

procedure TGateSE.SetState(Value: Integer);
begin
  State := Value;
  StateStep := 0;
  if IsAttachedToSpace then
    RebuildStateGraphics;
end;

procedure TGateSE.RebuildStateGraphics;
begin
  if State = 0 then
  begin
    Image.SetActive(False);
    if TextLabel <> nil then
      TextLabel.SetActive(False);
  end
  else if State = 1 then
  begin
    Image.AnimationIndex := 0;
    Image.UpdateAutoGeometry;
    if (StateStep >= 0) and (Image.FrameCount > StateStep) then
    begin
      Image.SetActive(True);
      Image.SetFrame(StateStep);
      if TextLabel <> nil then
        TextLabel.SetActive(False);
    end
    else
    begin
      Image.SetActive(False);
      if TextLabel <> nil then
        TextLabel.SetActive(False);
    end;
  end
  else if State = 2 then
  begin
    Image.AnimationIndex := 1;
    Image.UpdateAutoGeometry;
    if (StateStep >= 0) and (Image.FrameCount > StateStep) then
    begin
      Image.SetActive(True);
      Image.SetFrame(StateStep);
      if TextLabel <> nil then
      begin
        TextLabel.SetTextColor(CurrentPixelFormat.PackNormalizedRgb(TextRed, TextGreen, TextBlue));
        TextLabel.SetActive(True);
      end;
    end
    else
    begin
      Image.SetActive(False);
      if TextLabel <> nil then
        TextLabel.SetActive(False);
    end;
  end
  else if State = 3 then
  begin
    Image.AnimationIndex := 2;
    Image.UpdateAutoGeometry;
    if (StateStep >= 0) and (Image.FrameCount > StateStep) then
    begin
      Image.SetActive(True);
      Image.SetFrame(StateStep);
      if TextLabel <> nil then
        TextLabel.SetActive(False);
    end
    else
    begin
      Image.SetActive(False);
      if TextLabel <> nil then
        TextLabel.SetActive(False);
    end;
  end;
end;

procedure TGateSE.AdvanceAnimation(UnusedTimer: Pointer; UnusedData: Integer);
begin
  Inc(StateStep);
  if State = 0 then
    Exit
  else if State = 1 then
  begin
    if Image.FrameCount <= StateStep then
    begin
      State := 2;
      StateStep := 0;
      RebuildStateGraphics;
    end
    else
      Image.SetFrame(StateStep);
  end
  else if State = 2 then
  begin
    if Image.FrameCount <= StateStep then
    begin
      StateStep := 0;
      RebuildStateGraphics;
    end
    else
      Image.SetFrame(StateStep);
  end
  else if State = 3 then
  begin
    if Image.FrameCount <= StateStep then
    begin
      State := 0;
      StateStep := 0;
      RebuildStateGraphics;
    end
    else
      Image.SetFrame(StateStep);
  end;
end;

procedure TGateSE.Advance;
begin
  inherited Advance;
  Inc(TickCount);
  if TickCount mod 5 = 0 then
    AdvanceAnimation(nil, 0);
end;

procedure TGateSE.LoadTemplate(Block: TBlockParEC);
begin
  inherited LoadTemplate(Block);
end;

procedure TGateSE.ApplyConfig(Block: TBlockParEC);
begin
  inherited ApplyConfig(Block);
end;

procedure TGateSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
begin
end;

constructor TGateEffectSE.Create(GraphKey: WideString; UnusedPosition: TPoint);
begin
  inherited Create(GraphKey, UnusedPosition);
end;

destructor TGateEffectSE.Destroy;
begin
  inherited Destroy;
end;

procedure TGateEffectSE.AttachToSpace(ASpace: TSpaceSE);
var
  ImageSize: Integer;
begin
  if IsAttachedToSpace then
    Exit;
  inherited AttachToSpace(ASpace);
  TickCount := 0;
  Image := TRotateImageGaiGI.Create(Space.MapPanel);
  Image.SetPositionModeW(True);
  Image.SetDepthByName(DepthExpression);
  Image.SetPosition(Classes.Point(Round(Position.X), Round(Position.Y)));
  Image.SetAngle(Angle + 128);
  Image.SetAlpha(255);
  Image.SetActive(True);
  ImageSize := GiScalePixels(Min(200, Size.X));
  Image.SetImage(
      'Bm.Gate2.GateEffect?NoConvertPF',
      Classes.Point(ImageSize, ImageSize),
      Classes.Point(ImageSize div 2, ImageSize div 2)
  );
  RebuildStateGraphics;
end;

procedure TGateEffectSE.DetachFromSpace;
begin
  if IsAttachedToSpace then
  begin
    Image.SetActive(False);
    Image.Free;
    Image := nil;
    StateStep := 0;
    inherited DetachFromSpace;
  end;
end;

procedure TGateEffectSE.SetSize(Value: TPoint);
begin
  if (Size.X <> Value.X) or (Size.Y <> Value.Y) then
    inherited SetSize(Value);
end;

function TGateEffectSE.GetAngle: Byte;
begin
  Result := Angle;
end;

procedure TGateEffectSE.SetAngle(Value: Byte);
begin
  Angle := Value;
  if IsAttachedToSpace then
    Image.SetAngle(Angle + 128);
end;

procedure TGateEffectSE.RebuildStateGraphics;
begin
  Image.AnimationIndex := 0;
  Image.UpdateAutoGeometry;
  Image.SetActive(True);
  Image.SetFrame(StateStep);
end;

procedure TGateEffectSE.AdvanceAnimation(UnusedTimer: Pointer; UnusedData: Integer);
begin
  if IsAttachedToSpace then
  begin
    Inc(StateStep);
    if Image.FrameCount <= StateStep then
    begin
      StateStep := 0;
      DetachFromSpace;
    end
    else
      RebuildStateGraphics;
  end;
end;

procedure TGateEffectSE.Advance;
begin
  inherited Advance;
  Inc(TickCount);
  if TickCount mod 5 = 0 then
    AdvanceAnimation(nil, 0);
end;

procedure TGateEffectSE.LoadTemplate(Block: TBlockParEC);
begin
  inherited LoadTemplate(Block);
end;

procedure TGateEffectSE.ApplyConfig(Block: TBlockParEC);
begin
  inherited ApplyConfig(Block);
end;

procedure TGateEffectSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
begin
end;

end.
