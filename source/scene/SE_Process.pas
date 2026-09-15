{$EXCESSPRECISION OFF}
unit SE_Process;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_BlockPar,
  EC_Struct,
  GI_MessageLoop,
  GI_Panel,
  SE_Space,
  Types;
type
  TProcessSE = class;
  TProcessSE = class(TObject)
    Space: TSpaceSE;
    FirstObject: TObjectSE;
    LastObject: TObjectSE;
    RetainedObjects: TList;
    BackgroundTimer: PSpaceTimerSE;
    PreviousViewRect: TRect;
    ViewRect: TRect;
    RadarCenter: TPointF;
    RadarRange: Integer;
    ActionRange: Integer;
    ActionColor: Cardinal;
    SystemRadius: Integer;
    procedure OpenSpace(MapPanel: TPanelGI; Screen: TMessageLoopGI); virtual;
    procedure BindMinimap(Control: TObjectGI); virtual;
    procedure CloseSpace; virtual;
    procedure LoadFromBlock(Block: TBlockParEC); virtual;
    constructor Create(const ConfigName: WideString);
    destructor Destroy; override;
    procedure AddObject(Obj: TObjectSE);
    procedure RemoveObject(Obj: TObjectSE);
    function IsSpaceOpen: Boolean;
    procedure PopulateAmbientObjects(Radius: Integer; BackgroundImage: Integer; Seed: Cardinal);
    procedure StartBackgroundEffects;
    procedure StopBackgroundEffects;
    procedure AdvanceBackgroundEffects(Timer: PSpaceTimerSE; UserData: Integer);
    procedure UpdateViewRect;
    function SelectBackgroundAnimation: WideString;
  end;
function CreateSpaceObjectByName(
    const ClassName: WideString;
    const GraphKey: WideString;
    UnusedPosition: TPoint
): TObjectSE;
function ClassSEtoName(Obj: TObjectSE): WideString;
procedure LinkRecoveredTypes;
implementation
uses
  Windows,
  SysUtils,
  Math,
  GR_Main,
  GlobalsV,
  Globals,
  aGalaxy,
  aMyFunction,
  EC_Str,
  GI_Main,
  SE_Comet,
  SE_Angel,
  SE_Meteorite,
  SE_Star,
  SE_StarsField,
  SE_Planet,
  SE_Sputnik,
  SE_Asteroid,
  SE_Hole,
  SE_Ruins,
  SE_Ship2,
  SE_Container,
  SE_Laser,
  SE_Anim,
  SE_BGObj,
  SE_Weapon,
  SE_GAIEffect,
  SE_Gate,
  SE_Missile;

constructor TProcessSE.Create(const ConfigName: WideString);
begin
  inherited Create;
  LoadFromBlock(GameDataConfig.GetBlockByPath('SE.' + ConfigName));
  RetainedObjects := TList.Create;
end;

destructor TProcessSE.Destroy;
var
  Obj: TObjectSE;
  Index: Integer;
begin
  CloseSpace;
  while FirstObject <> nil do
  begin
    Obj := LastObject;
    RemoveObject(Obj);
  end;
  if RetainedObjects <> nil then
  begin
    for Index := 0 to RetainedObjects.Count - 1 do
    begin
      Obj := RetainedObjects[Index];
      ReleaseSpaceObject(Obj);
    end;
    RetainedObjects.Free;
    RetainedObjects := nil;
  end;
  inherited Destroy;
end;

procedure TProcessSE.AddObject(Obj: TObjectSE);
begin
  if LastObject <> nil then
    LastObject.ProcessNext := Obj;
  Obj.ProcessPrev := LastObject;
  Obj.ProcessNext := nil;
  RetainSpaceObject(LastObject, Obj);
  if FirstObject = nil then
    FirstObject := Obj;
end;

procedure TProcessSE.RemoveObject(Obj: TObjectSE);
begin
  if Obj.ProcessPrev <> nil then
    Obj.ProcessPrev.ProcessNext := Obj.ProcessNext;
  if Obj.ProcessNext <> nil then
    Obj.ProcessNext.ProcessPrev := Obj.ProcessPrev;
  if LastObject = Obj then
    LastObject := Obj.ProcessPrev;
  if FirstObject = Obj then
    FirstObject := Obj.ProcessNext;
  ReleaseSpaceObject(Obj);
end;

procedure TProcessSE.OpenSpace(MapPanel: TPanelGI; Screen: TMessageLoopGI);
var
  Obj: TObjectSE;
begin
  if not IsSpaceOpen then
  begin
    Space := TSpaceSE.Create(MapPanel, Screen);
    Space.Process := Self;
    Obj := FirstObject;
    while Obj <> nil do
    begin
      Obj.AttachToSpace(Space);
      Obj := Obj.ProcessNext;
    end;
    StartBackgroundEffects;
  end;
end;

procedure TProcessSE.BindMinimap(Control: TObjectGI);
begin
  if IsSpaceOpen then
  begin
    Space.MinimapControl := Control;
    Space.MinimapControl.LeftButtonDownCallback := Space.MinimapMouseDown;
    Space.MinimapControl.RightButtonDownCallback := Space.MinimapMouseDown;
    Space.MinimapControl.MouseEnterCallback := Space.MinimapMouseEnter;
    Space.MinimapControl.MouseMoveCallback := Space.MinimapMouseMove;
    Space.CreateMinimapViewport;
  end;
end;

procedure TProcessSE.CloseSpace;
begin
  if IsSpaceOpen then
  begin
    StopBackgroundEffects;
    Space.FreeMinimapViewport;
    Space.Free;
    Space := nil;
  end;
end;

function TProcessSE.IsSpaceOpen: Boolean;
begin
  if Space = nil then
    Result := False
  else
    Result := True;
end;

procedure TProcessSE.PopulateAmbientObjects(Radius, BackgroundImage: Integer; Seed: Cardinal);
var
  Block: TBlockParEC;
  CometObj: TCometSE;
  AngelObj: TAngelSE;
  MeteoriteObj: TMeteoriteSE;
  Count, Index, BlockCount, BlockIndex, VariantCount, VariantIndex: Integer;
  MinRadius, MaxRadius, Diameter: Integer;
  CountRange: TPoint;
  NextObj, Obj: TObjectSE;
  Text: WideString;
begin
  Count := 0;
  NextObj := FirstObject;
  while NextObj <> nil do
  begin
    Obj := NextObj;
    NextObj := NextObj.ProcessNext;
    if (Obj is TCometSE) or (Obj is TAngelSE) or (Obj is TMeteoriteSE) then
    begin
      Obj.DetachFromSpace;
      RemoveObject(Obj);
    end;
  end;
  MinRadius := TStar(Galaxy.Stars[0]).MapDiameter;
  MaxRadius := MinRadius;
  for Index := 1 to Galaxy.Stars.Count - 1 do
  begin
    Diameter := TStar(Galaxy.Stars[Index]).MapDiameter;
    MinRadius := Min(MinRadius, Diameter);
    MaxRadius := Max(MaxRadius, Diameter);
  end;
  MinRadius := MinRadius div 2;
  MaxRadius := MaxRadius div 2;
  Block := GameDataConfig.GetBlockByPath('SE.Anim.BGO_HS.Objects');
  if Comet > 0 then
  begin
    if BackgroundImage < 10 then
      Text :=
          GameDataConfig
              .GetBlockByPath('StyleComet')
              .GetParam(WideString('0' + IntToStr(BackgroundImage)))
    else
      Text :=
          GameDataConfig
              .GetBlockByPath('StyleComet')
              .GetParam(WideString(IntToStr(BackgroundImage)));
    Index := NextRandomIntRange(0, CountDelimitedPartsW(Text, ',') div 2 - 1, Seed) * 2;
    VariantCount := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, Index + 1, ','));
    Text := ExtractDelimitedPartW(Text, Index, ',');
    CountRange.X := 15;
    CountRange.Y := 30;
    if Block.CountParams('CometCount') > 0 then
      CountRange := GetPointGI(Block.GetParam('CometCount'));
    if Comet = 1 then
      Count := CountRange.X
    else
      Count := CountRange.Y;
    Count := Round(RemapClamped(Radius, MinRadius, MaxRadius, 0.5, 2.0) * Count);
    for Index := 1 to Count do
    begin
      CometObj := TCometSE.Create('Anim.BGO_HS.Comet', Classes.Point(0, 0));
      VariantIndex := NextRandomIntRange(0, VariantCount - 1, Seed);
      if VariantIndex < 10 then
        CometObj.ImagePath := 'Bm.Comet.' + Text + '0' + WideString(IntToStr(VariantIndex))
      else
        CometObj.ImagePath := 'Bm.Comet.' + Text + WideString(IntToStr(VariantIndex));
      AddObject(CometObj);
    end;
  end;
  { Native reuses the previous Count when AngelCount is absent. }
  if Block.CountParams('AngelCount') > 0 then
  begin
    CountRange := GetPointGI(Block.GetParam('AngelCount'));
    Count := RandomIntRange(CountRange.X, CountRange.Y);
  end;
  for Index := 1 to Count do
  begin
    AngelObj := TAngelSE.Create('Anim.BGO_HS.Angel', Classes.Point(0, 0));
    AddObject(AngelObj);
  end;
  CountRange :=
      GetPointGI(GameDataConfig.GetParamByPathOrMarker('SE.Anim.BGO_HS.Objects.MeteoriteCount'));
  Count := RandomIntRange(CountRange.X, CountRange.Y);
  Block := GameDataConfig.GetBlockByPath('SE.Meteorite');
  BlockCount := Block.GetBlockCount;
  for Index := 0 to Count - 1 do
  begin
    BlockIndex := RandomIntRange(0, BlockCount - 1);
    MeteoriteObj :=
        TMeteoriteSE
            .Create('Meteorite.' + Block.GetBlockNameByIndex(BlockIndex), Classes.Point(0, 0));
    AddObject(MeteoriteObj);
  end;
end;

procedure TProcessSE.StartBackgroundEffects;
begin
  StopBackgroundEffects;
  if IsSpaceOpen then
  begin
    ViewRect := Classes.Rect(-100001, -100001, -100000, -100000);
    UpdateViewRect;
    BackgroundTimer := Space.CreateTimer(BGOTime, BGOTime, AdvanceBackgroundEffects, 0);
  end;
end;

procedure TProcessSE.StopBackgroundEffects;
var
  Obj: TObjectSE;
  Index: Integer;
begin
  if IsSpaceOpen then
  begin
    for Index := 0 to RetainedObjects.Count - 1 do
    begin
      Obj := RetainedObjects[Index];
      ReleaseSpaceObject(Obj);
    end;
    RetainedObjects.Clear;
    if BackgroundTimer <> nil then
    begin
      Space.DeleteTimer(BackgroundTimer);
      BackgroundTimer := nil;
    end;
  end;
end;

procedure TProcessSE.AdvanceBackgroundEffects(Timer: PSpaceTimerSE; UserData: Integer);
var
  Index: Integer;
  Obj: TObjectSE;
  Position: TPointF;
begin
  Index := 0;
  while Index < RetainedObjects.Count do
  begin
    Obj := RetainedObjects[Index];
    if not Obj.IsAttachedToSpace then
    begin
      RetainedObjects.Delete(Index);
      ReleaseSpaceObject(Obj);
    end
    else
      Inc(Index);
  end;
  if BGOCount > RetainedObjects.Count then
    if RandomIntRange(0, BGOCount - 1) >= RetainedObjects.Count - 1 then
    begin
      RetainSpaceObject(Obj, TAnimSE.Create(SelectBackgroundAnimation, Classes.Point(0, 0)));
      Position.X := RandomIntRange(ViewRect.Left, ViewRect.Right);
      Position.Y := RandomIntRange(ViewRect.Top, ViewRect.Bottom);
      Obj.SetPosition(Position);
      Obj.AttachToSpace(Space);
      RetainedObjects.Add(Obj);
    end;
end;

procedure TProcessSE.UpdateViewRect;
begin
  PreviousViewRect := ViewRect;
  ViewRect := TSpaceSE(Space).MapPanel.GetVisibleContentRect;
end;

function TProcessSE.SelectBackgroundAnimation: WideString;
var
  Block: TBlockParEC;
  Index, Count, Weight: Integer;
begin
  Block := GameDataConfig.GetBlockByPath('SE.BGO');
  Count := Block.GetParamCount;
  Weight := 0;
  for Index := 0 to Count - 1 do
    Inc(Weight, ExtractDigitsToIntW(Block.GetParamName(Index)));
  Weight := RandomIntRange(0, Weight - 1);
  Index := 0;
  Dec(Weight, ExtractDigitsToIntW(Block.GetParamName(Index)));
  while Weight >= 0 do
  begin
    Inc(Index);
    Dec(Weight, ExtractDigitsToIntW(Block.GetParamName(Index)));
  end;
  Result := Block.GetParamValue(Index);
end;

procedure TProcessSE.LoadFromBlock(Block: TBlockParEC);
var
  Obj: TObjectSE;
  Objects: TBlockParEC;
  Count, Index: Integer;
begin
  Objects := Block.GetBlockByPath('Objects');
  Count := Objects.GetBlockCount;
  for Index := 0 to Count - 1 do
  begin
    Obj :=
        CreateSpaceObjectByName(
            Objects.GetBlockNameByIndex(Index),
            Objects.GetBlockByIndex(Index).GetParam('Type'),
            GetPointGI(Objects.GetBlockByIndex(Index).GetParam('Size'))
        );
    if Obj <> nil then
    begin
      AddObject(Obj);
      Obj.ApplyConfig(Objects.GetBlockByIndex(Index));
    end;
  end;
end;

function CreateSpaceObjectByName(
    const ClassName, GraphKey: WideString;
    UnusedPosition: TPoint
): TObjectSE;
begin
  if ClassName = 'Star' then
    Result := TStarSE.Create(GraphKey, UnusedPosition)
  else if ClassName = 'StarsField' then
    Result := TStarsFieldSE.Create(GraphKey, UnusedPosition)
  else if ClassName = 'Planet' then
    Result := TPlanetSE.CreateFromGraph(GraphKey, UnusedPosition)
  else if ClassName = 'Sputnik' then
    Result := TSputnikSE.Create(GraphKey, UnusedPosition)
  else if ClassName = 'Asteroid' then
    Result := TAsteroidSE.Create(GraphKey, UnusedPosition)
  else if ClassName = 'Hole' then
    Result := THoleSE.Create(GraphKey, UnusedPosition)
  else if ClassName = 'Ruins' then
    Result := TRuinsSE.Create(GraphKey, UnusedPosition)
  else if (ClassName = 'Ship2') or (ClassName = 'Ship') then
    Result := TShip2SE.Create(GraphKey, UnusedPosition)
  else if ClassName = 'Container' then
    Result := TContainerSE.Create(GraphKey, UnusedPosition)
  else if ClassName = 'Laser' then
    Result := TLaserSE.Create(GraphKey, UnusedPosition)
  else if ClassName = 'Anim' then
    Result := TAnimSE.Create(GraphKey, UnusedPosition)
  else if ClassName = 'BGObj' then
    Result := TBGObjSE.Create(GraphKey, UnusedPosition)
  else if ClassName = 'Weapon' then
    Result := TWeaponSE.Create(GraphKey, UnusedPosition, 0, -1)
  else if ClassName = 'Effect' then
    Result := TGAIEffectSE.Create(GraphKey, UnusedPosition)
  else if ClassName = 'Gate' then
    Result := TGateSE.Create(GraphKey, UnusedPosition)
  else if ClassName = 'GateEffect' then
    Result := TGateEffectSE.Create(GraphKey, UnusedPosition)
  else if ClassName = 'Missile' then
    Result := TMissileSE.Create(GraphKey, UnusedPosition)
  else
    Result := nil;
end;

function ClassSEtoName(Obj: TObjectSE): WideString;
begin
  if Obj is TStarSE then
    Result := 'Star'
  else if Obj is TPlanetSE then
    Result := 'Planet'
  else if Obj is TSputnikSE then
    Result := 'Sputnik'
  else if Obj is TAsteroidSE then
    Result := 'Asteroid'
  else if Obj is THoleSE then
    Result := 'Hole'
  else if Obj is TRuinsSE then
    Result := 'Ruins'
  else if Obj is TShip2SE then
    Result := 'Ship2'
  else if Obj is TContainerSE then
    Result := 'Container'
  else if Obj is TLaserSE then
    Result := 'Laser'
  else if Obj is TAnimSE then
    Result := 'Anim'
  else if Obj is TBGObjSE then
    Result := 'BGObj'
  else if Obj is TWeaponSE then
    Result := 'Weapon'
  else if Obj is TGAIEffectSE then
    Result := 'Effect'
  else if Obj is TGateSE then
    Result := 'Gate'
  else if Obj is TGateEffectSE then
    Result := 'GateEffect'
  else if Obj is TMissileSE then
    Result := 'Missile'
  else
    raise Exception.Create('Error in ClassSEtoName');
end;

procedure LinkRecoveredTypes;
begin
  TAngelSE.ClassName;
  TAnimSE.ClassName;
  TAsteroidSE.ClassName;
  TBGObjSE.ClassName;
  TCometSE.ClassName;
  TContainerSE.ClassName;
  TGAIEffectSE.ClassName;
  TGateEffectSE.ClassName;
  TGateSE.ClassName;
  THoleSE.ClassName;
  TLaserSE.ClassName;
  TMeteoriteSE.ClassName;
  TMissileSE.ClassName;
  TPlanetSE.ClassName;
  TRuinsSE.ClassName;
  TShip2SE.ClassName;
  TSputnikSE.ClassName;
  TStarSE.ClassName;
  TWeaponSE.ClassName;
end;
end.
