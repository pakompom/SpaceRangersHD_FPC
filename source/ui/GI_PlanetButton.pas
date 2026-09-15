{$EXCESSPRECISION OFF}
unit GI_PlanetButton;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_BlockPar,
  GI_Label,
  GI_MessageLoop,
  GI_Panel,
  GI_Planet,
  Types;
type
  TPlanetButtonGI = class;
  TPlanetButtonGI = class(TPanelGI)
    NormalPlanet: TPlanetGI;
    HoverPlanet: TPlanetGI;
    TextLabel: TLabelGI;
    procedure Clear; override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure OnMouseEnter; override;
    procedure OnMouseLeave; override;
    procedure ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
  end;
implementation
uses
  Math;

constructor TPlanetButtonGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  NormalPlanet := TPlanetGI.Create(Self);
  NormalPlanet.SetDepth(2);
  HoverPlanet := TPlanetGI.Create(Self);
  HoverPlanet.SetDepth(2);
  HoverPlanet.SetActive(False);
  TextLabel := TLabelGI.Create(Self);
  TextLabel.SetDepth(1);
end;

destructor TPlanetButtonGI.Destroy;
begin
  NormalPlanet.Free;
  HoverPlanet.Free;
  TextLabel.Free;
  inherited Destroy;
end;

procedure TPlanetButtonGI.Clear;
begin
end;

procedure TPlanetButtonGI.OnMouseEnter;
begin
  inherited OnMouseEnter;
  NormalPlanet.SetActive(False);
  HoverPlanet.SetActive(True);
end;

procedure TPlanetButtonGI.OnMouseLeave;
begin
  inherited OnMouseLeave;
  NormalPlanet.SetActive(True);
  HoverPlanet.SetActive(False);
end;

procedure TPlanetButtonGI.ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonDown(KeyState, Point);
  DispatchNamedEvent(1, Point.X, Point.Y);
end;

procedure TPlanetButtonGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
end;

procedure TPlanetButtonGI.LoadFromBlock(Block: TBlockParEC);
begin
  TextLabel.SetActive(False);
  inherited LoadFromBlock(Block);
  NormalPlanet.SetImage(
      Block.GetParam('PN_Mask'),
      Block.GetParam('PN_Image'),
      Block.GetParam('PN_ImageLight')
  );
  SetSize(NormalPlanet.ClientSize);
  HoverPlanet.SetImage(
      Block.GetParam('PN_Mask'),
      Block.GetParam('PA_Image'),
      Block.GetParam('PA_ImageLight')
  );
  if Block.CountParams('Font') > 0 then
    TextLabel.SetFontName(Block.GetParam('Font'));
  if Block.CountParams('Text') > 0 then
  begin
    TextLabel.SetText(Block.GetParam('Text'));
    TextLabel.SetActive(True);
    TextLabel.SetSize(ClientSize);
  end;
end;

end.
