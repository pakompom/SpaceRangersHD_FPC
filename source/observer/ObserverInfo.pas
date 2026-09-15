{$EXCESSPRECISION OFF}
unit ObserverInfo;

// The original StarMap controls and layout routines, populated from recordings.
// Never call ShowObjectInfo on a live ship: it executes script inspection hooks.
interface
uses
  Classes,
  Types,
  ObserverCapture,
  fStarMap,
  GI_Window,
  GI_Label,
  SE_Space;
type
  TObserverInspector = class
    Screen: TfStarMap;
    LastTrack: TObserverTrack;
    LastKey: AnsiString;
    Main: TWindowGI;
    ExtraLines: TStringList;
    Page: Integer;
    MainBounds, ExtraBounds: TRect;
    ItemCentre, ItemSizeOffset, ItemCostOffset: TPoint;
    ItemEmblemOffset, ShipEmblemOffset, PlanetEmblemOffset: TPoint;
    constructor Create(AScreen: TfStarMap);
    destructor Destroy; override;
    procedure Hide;
    function Contains(Point: TPoint): Boolean;
    procedure Scroll(Delta: Integer);
    procedure Show(
        Track: TObserverTrack;
        SystemData: TObserverSystem;
        const Pose: TObserverPose;
        Graphic: TObjectSE;
        Mouse: TPoint;
        Pinned: Boolean;
        Canvas: TRect
    );
  end;
implementation
uses
  Math,
  SysUtils,
  EC_Struct,
  EC_Str,
  GI_GI,
  GI_MessageLoop,
  GI_GraphBuf,
  GI_Image,
  GI_Main,
  Globals,
  GlobalsV,
  GR_Main,
  GR_GraphBuf,
  aConst,
  aGalaxyStruct,
  fShip2,
  SE_Planet,
  SE_Process;
constructor TObserverInspector.Create(AScreen: TfStarMap);
begin
  inherited Create;
  Screen := AScreen;
  ExtraLines := TStringList.Create;
  // Read offsets from this screen's own native layout. The equipment screen
  // may not have been opened, so its lazily initialized offsets can be zero.
  with Screen.GetByName('InfoItemImage') do
    ItemCentre := AddPoints(LocalPosition, HalfPoint(ClientSize));
  with Screen.GetByName('InfoItemSize') do
    ItemSizeOffset := Classes.Point(LocalPosition.X, LocalPosition.Y - Parent.ClientSize.Y);
  with Screen.GetByName('InfoItemPrice') do
    ItemCostOffset := Classes.Point(LocalPosition.X, LocalPosition.Y - Parent.ClientSize.Y);
  with Screen.GetByName('InfoItemEmRace') do
    ItemEmblemOffset := SubtractPoints(LocalPosition, Parent.ClientSize);
  with Screen.GetByName('InfoShipEmRace') do
    ShipEmblemOffset := SubtractPoints(LocalPosition, Parent.ClientSize);
  with Screen.GetByName('InfoPlanetEmRace') do
    PlanetEmblemOffset := SubtractPoints(LocalPosition, Parent.ClientSize);
end;
destructor TObserverInspector.Destroy;
begin
  ExtraLines.Free;
  inherited Destroy
end;
procedure TObserverInspector.Hide;
begin
  Screen.InfoWindow.SetActive(False);
  Screen.ItemInfoWindow.SetActive(False);
  Screen.ShipInfoPanel.SetActive(False);
  Screen.PlanetInfoPanel.SetActive(False);
  Screen.StarInfoWindow.SetActive(False);
  Screen.StandardInfoPanel.SetActive(False);
  Main := nil;
end;
function TObserverInspector.Contains(Point: TPoint): Boolean;
begin
  Result :=
      (Main <> nil)
          and (PtInRect(MainBounds, Point)
              or (Screen.InfoWindow.Active and PtInRect(ExtraBounds, Point)))
end;
procedure TObserverInspector.Scroll(Delta: Integer);
begin
  Page := EnsureRange(Page - Delta, 0, Max(0, (ExtraLines.Count - 1) div 16))
end;
procedure TObserverInspector.Show(
    Track: TObserverTrack;
    SystemData: TObserverSystem;
    const Pose: TObserverPose;
    Graphic: TObjectSE;
    Mouse: TPoint;
    Pinned: Boolean;
    Canvas: TRect
);
const
  Orders: array[0..7] of WideString = (
      'Idle',
      'Flying',
      'Landing',
      'Hyperspace departure',
      'Black hole',
      'Taking off',
      'Following',
      'Teleporting'
  );
var
  Changed: Boolean;
  L, T, I, W, H: Integer;
  Text: WideString;
  P: TPoint;
  B: TGraphBufGI;
  Factor: Double;
  Planet: TPlanetSE;
  OwnPlanet: Boolean;
  StarText: TLabelGI;
  Borders: TRect;
  function LabelOf(const Name: WideString): TLabelGI;
  begin
    Result := Screen.GetByName(Name) as TLabelGI
  end;
  procedure Put(const Name, Text: WideString);
  begin
    LabelOf(Name).SetText(Text);
    LabelOf(Name).SetActive(True)
  end;
  procedure Emblem(const Name, Path: WideString);
  var
    Image: TImageGI;
  begin
    Image := Screen.GetByName(Name) as TImageGI;
    Image.SetActive((Path <> '') and (Path <> 'None'));
    if Image.Active and Changed then
    begin
      Image.SetImagePath(GetFactionEmblemPath(Path));
      Image.SetImageKindX(ikxCenter);
      Image.SetImageKindY(ikyCenter)
    end;
  end;
  procedure FitThumbnail(Control: TGraphBufGI; const Path: WideString);
  var
    Width, Height: Integer;
  begin
    if not Changed then
      Exit;
    Control.SetActive(Path <> '');
    if Path = '' then
      Exit;
    Control.SourceHasPerPixelAlpha := True;
    LoadGiByPathIntoGraphBuf(ExtractDelimitedPartW(Path, 1, ','), Control.GraphBuf);
    Width := Control.GraphBuf.Width;
    Height := Control.GraphBuf.Height;
    if (Width > Control.ClientSize.X) or (Height > Control.ClientSize.Y) then
      if Width >= Height then
        Control.GraphBuf.RescaleRgba(
            Control.ClientSize.X,
            Max(1, Round(Control.ClientSize.X / Width * Height)),
            5
        )
      else
        Control.GraphBuf.RescaleRgba(
            Max(1, Round(Control.ClientSize.Y / Height * Width)),
            Control.ClientSize.Y,
            5
        );
    Control.SetImageKindX(ikxCenter);
    Control.SetImageKindY(ikyCenter);
    Control.Invalidate;
  end;
  procedure Place(Window: TWindowGI; X, Y: Integer);
  begin
    Window.SetPosition(
        Classes.Point(
            X - Window.Parent.AbsolutePosition.X + Window.OriginPoint.X,
            Y - Window.Parent.AbsolutePosition.Y + Window.OriginPoint.Y
        )
    );
  end;
  procedure Durability(const Prefix: WideString; Fraction: Double; Fragility, Mass: Double);
  var
    Width, Cap: Integer;
    Image: TImageGI;
  begin
    Width := EnsureRange(Round(64 * Sqrt(Max(1, Mass) / 100) / Max(0.25, Fragility)), 32, 160);
    Cap := (Screen.GetByName(Prefix + 'Left') as TImageGI).GetContentSize.X;
    Image := Screen.GetByName(Prefix) as TImageGI;
    Image.Parent.Parent.SetActive(True);
    Image.Parent.Parent.SetSize(Classes.Point(Width + Cap * 2, Image.Parent.Parent.ClientSize.Y));
    Image.Parent.SetSize(Classes.Point(Width + 2, Image.Parent.ClientSize.Y));
    Image.SetPosition(
        Classes.Point(
            Round(EnsureRange(Fraction, 0.0, 1.0) * Width) - (Image.GetContentSize.X - 5),
            Image.LocalPosition.Y
        )
    );
    Image := Screen.GetByName(Prefix + 'Right') as TImageGI;
    Image.SetPosition(Classes.Point(Width + Cap - Image.GetContentSize.X, Image.LocalPosition.Y));
    Image.Parent.SetPosition(Classes.Point(Cap, Image.Parent.LocalPosition.Y));
    Image.Parent.SetSize(Classes.Point(Width + Cap, Image.Parent.ClientSize.Y));
    Image := Screen.GetByName(Prefix + 'Back') as TImageGI;
    Image.SetPosition(Classes.Point(Width + 1 - Image.GetContentSize.X, Image.LocalPosition.Y));
    Image.Parent.SetSize(Classes.Point(Width + Cap, Image.Parent.ClientSize.Y));
  end;
begin
  Changed := Track <> LastTrack;
  Hide;
  if Track = nil then
    Exit;
  if Changed then
  begin
    LastTrack := Track;
    if LastKey <> Track.Key then
      Page := 0;
    LastKey := Track.Key;
    ExtraLines.Text := UTF8Encode(Track.Equipment);
    Page := Min(Page, Max(0, (ExtraLines.Count - 1) div 16))
  end;
  case Track.Kind of
    2:
    begin
      Main := Screen.ShipInfoPanel as TWindowGI;
      Put('InfoShipName', Track.ShipInfo.FullName);
      Put('InfoShipType', Track.Category);
      Put('InfoShipSpeed', IntToStr(Pose.Speed));
      Put('InfoShipSize', IntToStr(Pose.Hull) + '/' + IntToStr(Pose.HullMax));
      Put('InfoShipDef', Track.ShipInfo.DefenseText);
      Put('InfoShipDamage', Track.ShipInfo.DamageText);
      Put('InfoShipRel', RelationInfo[Ord(Track.ShipInfo.Relation)].DisplayName);
      Put('ISWin', 'Order:');
      Put('InfoShipWin', Orders[EnsureRange(Pose.Order, 0, 7)]);
      Screen.GetByName('ISType').SetActive(True);
      Screen.GetByName('ISDamage').SetActive(True);
      Put('InfoShipEffects', Track.ShipInfo.CombatStatusText);
      Screen.GetByName('ISEffects').SetActive(Track.ShipInfo.CombatStatusCount > 0);
      Screen.GetByName('InfoShipEffects').SetActive(Track.ShipInfo.CombatStatusCount > 0);
      if Track.ShipInfo.CombatStatusCount > 0 then
        LabelOf('InfoShipEffects')
            .SetSize(
                Classes.Point(
                    180,
                    Track.ShipInfo.CombatStatusCount * LabelOf('InfoShipEffects').GetLineHeight + 2
                ));
      Emblem('InfoShipEmRace', Track.ShipInfo.Faction);
      FitThumbnail(Screen.GetByName('InfoShipImage2') as TGraphBufGI, Track.Portrait);
      Durability(
          'InfoShipDurable',
          Pose.Hull / Max(1, Pose.HullMax),
          Track.ShipInfo.HullFragility,
          Pose.HullMax
      );
      ShipScreen.LayoutObjectInfo(
          Main,
          LabelOf('InfoShipName'),
          LabelOf('ISType'),
          LabelOf('InfoShipType'),
          LabelOf('ISSpeed'),
          LabelOf('InfoShipSpeed'),
          LabelOf('ISSize'),
          LabelOf('InfoShipSize'),
          LabelOf('ISDef'),
          LabelOf('InfoShipDef'),
          LabelOf('ISDamage'),
          LabelOf('InfoShipDamage'),
          LabelOf('ISRel'),
          LabelOf('InfoShipRel'),
          LabelOf('ISWin'),
          LabelOf('InfoShipWin'),
          LabelOf('ISEffects'),
          LabelOf('InfoShipEffects'),
          Screen.GetByName('InfoShipEmRace'),
          True,
          290
      );
      Screen.GetByName('InfoShipEmRace').SetPosition(AddPoints(Main.ClientSize, ShipEmblemOffset));
    end;
    1:
    begin
      Main := Screen.PlanetInfoPanel as TWindowGI;
      Put('InfoPlanetName', Track.Name);
      Put(
          'InfoPlanetOwner',
          OwnerInfo[Integer(RaceToOwner(Track.PlanetInfo.RaceId)) and $7F].DisplayName
      );
      Put('InfoPlanetPop', IntToStr(Round(Track.PlanetInfo.Population / 1000)));
      Put('InfoPlanetEco', PlanetEconomyInfo[Ord(Track.PlanetInfo.Economy)].DisplayName);
      Put('InfoPlanetGov', PlanetGovernmentMarket[Ord(Track.PlanetInfo.Government)].DisplayName);
      Put('InfoPlanetRel', RelationInfo[Ord(Track.PlanetInfo.Relation)].DisplayName);
      Emblem('InfoPlanetEmRace', Track.PlanetInfo.Faction);
      if Changed then
      begin
        OwnPlanet := not (Graphic is TPlanetSE);
        if OwnPlanet then
          Planet :=
              CreateSpaceObjectByName(Track.SceneClass, Track.GraphKey, Classes.Point(0, 0))
                  as TPlanetSE
        else
          Planet := TPlanetSE(Graphic);
        try
          if OwnPlanet then
          begin
            Planet.Radius := Track.Radius;
            Planet.SurfaceMapStep := Track.SurfaceStep;
            Planet.SurfaceMapOffset := Track.SurfaceOffset;
            Planet.RingKind := Track.RingKind
          end;
          B := Screen.GetByName('InfoPlanetImage') as TGraphBufGI;
          B.SourceHasPerPixelAlpha := True;
          Planet.RenderToBuffer(Screen, B.GraphBuf, False);
          Factor :=
              Min(
                  B.ClientSize.X / Max(1, B.GraphBuf.Width),
                  B.ClientSize.Y / Max(1, B.GraphBuf.Height)
              );
          if Factor < 1 then
            B.GraphBuf.RescaleRgba(
                Max(1, Round(B.GraphBuf.Width * Factor)),
                Max(1, Round(B.GraphBuf.Height * Factor)),
                5
            );
          B.SetImageKindX(ikxCenter);
          B.SetImageKindY(ikyCenter);
          B.Invalidate;
        finally
          if OwnPlanet then
            Planet.Free
        end;
      end;
      ShipScreen.LayoutObjectInfo(
          Main,
          LabelOf('InfoPlanetName'),
          LabelOf('IPOwner'),
          LabelOf('InfoPlanetOwner'),
          LabelOf('IPPop'),
          LabelOf('InfoPlanetPop'),
          LabelOf('IPEco'),
          LabelOf('InfoPlanetEco'),
          LabelOf('IPGov'),
          LabelOf('InfoPlanetGov'),
          LabelOf('IPRel'),
          LabelOf('InfoPlanetRel'),
          nil,
          nil,
          nil,
          nil,
          nil,
          nil,
          Screen.GetByName('InfoPlanetEmRace'),
          True,
          290
      );
      Screen
          .GetByName('InfoPlanetEmRace')
          .SetPosition(AddPoints(Main.ClientSize, PlanetEmblemOffset));
    end;
    5:
    begin
      Main := Screen.ItemInfoWindow;
      Put('InfoItemName', Track.Name);
      Put('InfoItemText', Track.Info);
      LabelOf('InfoItemSize').SetTextAlignX(taxAuto);
      LabelOf('InfoItemPrice').SetTextAlignX(taxAuto);
      Put('InfoItemSize', IntToStr(Track.ItemInfo.Weight));
      Put('InfoItemPrice', IntToStr(Track.ItemInfo.Cost));
      if Changed then
        with Screen.GetByName('InfoItemImage') as TImageGI do
        begin
          SetImagePath(Track.Portrait);
          SetImageKindX(ikxCenter);
          SetImageKindY(ikyCenter);
          SetPosition(SubtractPoints(ItemCentre, GetVisualCenter))
        end;
      Emblem('InfoItemEmRace', Track.ItemInfo.Faction);
      (Screen.GetByName('InfoDurable') as TImageGI)
          .Parent
          .Parent
          .SetActive(Track.ItemInfo.ConditionPercent < 100);
      if Track.ItemInfo.ConditionPercent < 100 then
        Durability(
            'InfoDurable',
            Track.ItemInfo.ConditionPercent / 100,
            Track.ItemInfo.Fragility,
            100
        );
      ShipScreen
          .LayoutItemInfo(Main, LabelOf('InfoItemName'), LabelOf('InfoItemText'), True, True, 290);
      Screen
          .GetByName('InfoItemSize')
          .SetPosition(Classes.Point(ItemSizeOffset.X, Main.ClientSize.Y + ItemSizeOffset.Y));
      Screen
          .GetByName('InfoItemPrice')
          .SetPosition(Classes.Point(ItemCostOffset.X, Main.ClientSize.Y + ItemCostOffset.Y));
      Screen
          .GetByName('InfoItemEmRace')
          .SetPosition(
              Classes.Point(
                  Main.ClientSize.X + ItemEmblemOffset.X,
                  Main.ClientSize.Y + ItemEmblemOffset.Y
              ));
    end;
    0:
    begin
      Main := Screen.StarInfoWindow;
      Put('InfoStarName', Track.Name);
      FitThumbnail(Screen.GetByName('InfoStarImage') as TGraphBufGI, Track.Portrait);
      if Changed then
      begin
        Screen.GetByName('InfoStarPanel').FreeOwnedChildren;
        StarText := TLabelGI.Create(Screen.GetByName('InfoStarPanel'));
        StarText.SetFontName(NormalFontName);
        StarText.SetTextColor($FFFFFF);
        StarText.SetTextAlignY(tayAuto);
        StarText.SetWordWrapEnabled(True);
        StarText.SetSize(Classes.Point(290, 1));
        Text := IntToStr(SystemData.Ships) + ' ships' + #13#10;
        for I := 0 to SystemData.Tracks.Count - 1 do
          if TObserverTrack(SystemData.Tracks[I]).Kind = 1 then
            Text := Text + #13#10 + TObserverTrack(SystemData.Tracks[I]).Name;
        StarText.SetText(Text);
        Screen.GetByName('InfoStarPanel').SetPosition(Main.WorkSubRect.TopLeft);
        Screen.GetByName('InfoStarPanel').SetSize(StarText.ClientSize);
        Main.SetSize(
            Classes.Point(
                290 + Main.WorkSubRect.Left + Main.WorkSubRect.Right,
                StarText.ClientSize.Y + Main.WorkSubRect.Top + Main.WorkSubRect.Bottom
            )
        );
        Main.UpdateAutoGeometry;
      end;
    end;
  else
    Main := Screen.StandardInfoPanel as TWindowGI;
    Put('InfoStdName', Track.Name);
    Put('InfoStdText', Track.Info);
    Screen.GetByName('InfoStdImage').SetActive(False);
    Screen.GetByName('InfoStdGB').SetActive(False);
    ShipScreen
        .LayoutItemInfo(Main, LabelOf('InfoStdName'), LabelOf('InfoStdText'), True, True, 260);
  end;
  Main.SetActive(True);
  Main.SetDepth(-150);
  W := Main.ClientSize.X;
  H := Main.ClientSize.Y;
  if Pinned then
  begin
    L := 12;
    T := Canvas.Bottom - H - 12
  end
  else
  begin
    L := Mouse.X + 18;
    T := Mouse.Y + 18
  end;
  L := EnsureRange(L, 8, Max(8, Canvas.Right - W - 8));
  T := EnsureRange(T, 8, Max(8, Canvas.Bottom - H - 8));
  if (L + W > Canvas.Right - 212) and (T < 235) then
    L := Max(8, Canvas.Right - 220 - W);
  Place(Main, L, T);
  MainBounds := Classes.Rect(L, T, L + W, T + H);
  if ExtraLines.Count > 0 then
  begin
    Text := '';
    for I := Page * 16 to Min(ExtraLines.Count - 1, Page * 16 + 15) do
      Text := Text + UTF8Decode(ExtraLines[I]) + #13#10;
    if ExtraLines.Count > 16 then
      Text :=
          Text
              + '<color=160,190,210>'
              + IntToStr(Page + 1)
              + '/'
              + IntToStr((ExtraLines.Count + 15) div 16)
              + '  ·  scroll</color>';
    with Screen.InfoTextLabel do
    begin
      SetWordWrapEnabled(True);
      SetTextAlignX(taxLeft);
      SetTextAlignY(tayAuto);
      SetSize(Classes.Point(330, 1));
      SetText(Text)
    end;
    Borders := Screen.InfoWindow.WorkSubRect;
    P := Screen.InfoTextLabel.ClientSize;
    Screen.InfoWindow.SetSize(
        Classes.Point(P.X + Borders.Left + Borders.Right, P.Y + Borders.Top + Borders.Bottom)
    );
    Screen.InfoWindow.UpdateAutoGeometry;
    Screen.InfoTextLabel.SetPosition(Borders.TopLeft);
    Screen.InfoWindow.SetActive(True);
    Screen.InfoWindow.SetDepth(-150);
    L := MainBounds.Right + 6;
    T := MainBounds.Top;
    if L + Screen.InfoWindow.ClientSize.X > Canvas.Right - 8 then
      L := Max(8, MainBounds.Left - Screen.InfoWindow.ClientSize.X - 6);
    T := Min(T, Canvas.Bottom - Screen.InfoWindow.ClientSize.Y - 12);
    Place(Screen.InfoWindow, L, T);
    ExtraBounds :=
        Classes.Rect(L, T, L + Screen.InfoWindow.ClientSize.X, T + Screen.InfoWindow.ClientSize.Y);
  end;
end;
end.
