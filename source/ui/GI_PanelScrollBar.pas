{$EXCESSPRECISION OFF}
unit GI_PanelScrollBar;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_BlockPar,
  GI_MessageLoop,
  GI_Panel,
  GI_ScrollBar,
  Types;
type
  TPanelScrollBarGI = class;
  TPanelScrollBarGI = class(TPanelGI)
    HorizontalScrollBar: TScrollBarGI;
    VerticalScrollBar: TScrollBarGI;
    AutoHorizontalPlacement: Boolean;
    AutoVerticalPlacement: Boolean;
    HorizontalScrollBarRect: TRect;
    VerticalScrollBarRect: TRect;
    ScrollbarsOutside: Boolean;
    UnlimitedWorld: Boolean;
    procedure Clear; override;
    procedure SetDepth(NewDepth: Double); override;
    procedure SetSize(Size: TPoint); override;
    procedure SetOrigin(Origin: TPoint); override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    procedure SetScrollOffset(Offset: TPoint); override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure SetVerticalScrollBarConfigPath(Path: WideString);
    procedure SetHorizontalScrollbarEnabled(Value: Boolean);
    function IsVerticalScrollbarEnabled: Boolean;
    procedure SetVerticalScrollbarEnabled(Value: Boolean);
    procedure SetScrollbarsOutside(Value: Boolean);
    procedure SetUnlimitedWorldEnabled(Value: Boolean);
    procedure UpdateScrollbarPlacement;
    procedure UpdateScrollRanges;
    procedure ScrollbarPositionChanged(Sender: TObjectGI);
    procedure PanelScrollChanged(Sender: TObjectGI);
    procedure ScrollbarDestroyed(Sender: TObjectGI);
    procedure LoadScrollbarPanelProperties(Block: TBlockParEC);
  end;
implementation
uses
  Math,
  Classes,
  EC_Str,
  EC_Struct,
  GI_Main,
  GR_Main;

constructor TPanelScrollBarGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  HorizontalScrollBar := TScrollBarGI.Create(Self);
  HorizontalScrollBar.UserValue := -1;
  VerticalScrollBar := TScrollBarGI.Create(Self);
  VerticalScrollBar.UserValue := -1;
  HorizontalScrollBar.DestroyNotify := ScrollbarDestroyed;
  VerticalScrollBar.DestroyNotify := ScrollbarDestroyed;
  HorizontalScrollBar.SetActive(False);
  HorizontalScrollBar.SetOrientation(1);
  HorizontalScrollBar.SetKindCalcMode(1);
  VerticalScrollBar.SetActive(False);
  VerticalScrollBar.SetOrientation(2);
  VerticalScrollBar.SetKindCalcMode(1);
  HorizontalScrollBar.SetDepth(-1E30);
  VerticalScrollBar.SetDepth(-1E30);
  HorizontalScrollBar.PositionChangedCallback := ScrollbarPositionChanged;
  VerticalScrollBar.PositionChangedCallback := ScrollbarPositionChanged;
  AutoHorizontalPlacement := True;
  AutoVerticalPlacement := True;
  ScrollbarsOutside := False;
  UnlimitedWorld := True;
  ScrollChangedCallback := PanelScrollChanged;
end;

destructor TPanelScrollBarGI.Destroy;
begin
  if HorizontalScrollBar <> nil then
  begin
    HorizontalScrollBar.Free;
    HorizontalScrollBar := nil;
  end;
  if VerticalScrollBar <> nil then
  begin
    VerticalScrollBar.Free;
    VerticalScrollBar := nil;
  end;
  inherited Destroy;
end;

procedure TPanelScrollBarGI.Clear;
begin
  inherited Clear;
  if (HorizontalScrollBar <> nil) and (VerticalScrollBar <> nil) then
    SetScrollbarsOutside(False);
  UnlimitedWorld := True;
end;

procedure TPanelScrollBarGI.SetVerticalScrollBarConfigPath(Path: WideString);
begin
  VerticalScrollBar.SetConfigPath(Path);
end;

procedure TPanelScrollBarGI.SetHorizontalScrollbarEnabled(Value: Boolean);
begin
  HorizontalScrollBar.SetActive(Value);
  if Value = True then
    HorizontalScrollBar.UpdateSizeForOrientation;
end;

function TPanelScrollBarGI.IsVerticalScrollbarEnabled: Boolean;
begin
  Result := VerticalScrollBar.Active;
end;

procedure TPanelScrollBarGI.SetVerticalScrollbarEnabled(Value: Boolean);
begin
  VerticalScrollBar.SetActive(Value);
  if Value = True then
    VerticalScrollBar.UpdateSizeForOrientation;
end;

procedure TPanelScrollBarGI.SetScrollbarsOutside(Value: Boolean);
begin
  if Value <> ScrollbarsOutside then
  begin
    ScrollbarsOutside := Value;
    if not ScrollbarsOutside then
    begin
      HorizontalScrollBar.Reparent(Self);
      VerticalScrollBar.Reparent(Self);
      HorizontalScrollBar.SetDepth(-1E30);
      VerticalScrollBar.SetDepth(-1E30);
    end
    else
    begin
      HorizontalScrollBar.Reparent(Parent);
      VerticalScrollBar.Reparent(Parent);
      HorizontalScrollBar.SetDepth(Depth);
      VerticalScrollBar.SetDepth(Depth);
    end;
    UpdateScrollbarPlacement;
    Invalidate;
  end;
end;

procedure TPanelScrollBarGI.SetUnlimitedWorldEnabled(Value: Boolean);
begin
  if Value <> UnlimitedWorld then
  begin
    UnlimitedWorld := Value;
    Invalidate;
  end;
end;

procedure TPanelScrollBarGI.SetSize(Size: TPoint);
begin
  inherited SetSize(Size);
  UpdateScrollbarPlacement;
end;

procedure TPanelScrollBarGI.SetOrigin(Origin: TPoint);
begin
  inherited SetOrigin(Origin);
  UpdateScrollbarPlacement;
end;

procedure TPanelScrollBarGI.SetScrollOffset(Offset: TPoint);
begin
  inherited SetScrollOffset(Offset);
  if HorizontalScrollBar <> nil then
    HorizontalScrollBar.SetPositionInternal(ScrollOffset.X);
  if VerticalScrollBar <> nil then
    VerticalScrollBar.SetPositionInternal(ScrollOffset.Y);
end;

procedure TPanelScrollBarGI.SetDepth(NewDepth: Double);
begin
  inherited SetDepth(NewDepth);
  if ScrollbarsOutside then
  begin
    HorizontalScrollBar.SetDepth(NewDepth);
    VerticalScrollBar.SetDepth(NewDepth);
  end;
end;

procedure TPanelScrollBarGI.UpdateScrollbarPlacement;
begin
  if not ScrollbarsOutside then
  begin
    if AutoHorizontalPlacement then
    begin
      TObjectGI(HorizontalScrollBar)
          .SetPosition(Classes.Point(0, ClientSize.Y - HorizontalScrollBar.ClientSize.Y));
      HorizontalScrollBar.SetSize(
          Classes.Point(
              ClientSize.X - VerticalScrollBar.ClientSize.X,
              HorizontalScrollBar.ClientSize.Y
          )
      );
    end
    else
    begin
      TObjectGI(HorizontalScrollBar).SetPosition(HorizontalScrollBarRect.TopLeft);
      HorizontalScrollBar.SetSize(
          SubtractPoints(HorizontalScrollBarRect.BottomRight, HorizontalScrollBarRect.TopLeft)
      );
    end;
    if AutoVerticalPlacement then
    begin
      TObjectGI(VerticalScrollBar)
          .SetPosition(Classes.Point(ClientSize.X - VerticalScrollBar.ClientSize.X, 0));
      VerticalScrollBar.SetSize(
          Classes.Point(
              VerticalScrollBar.ClientSize.X,
              ClientSize.Y - HorizontalScrollBar.ClientSize.Y
          )
      );
    end
    else
    begin
      TObjectGI(VerticalScrollBar).SetPosition(VerticalScrollBarRect.TopLeft);
      VerticalScrollBar.SetSize(
          SubtractPoints(VerticalScrollBarRect.BottomRight, VerticalScrollBarRect.TopLeft)
      );
    end;
  end
  else
  begin
    if AutoHorizontalPlacement then
    begin
      TObjectGI(HorizontalScrollBar)
          .SetPosition(Classes.Point(LocalPosition.X, LocalPosition.Y + ClientSize.Y));
      HorizontalScrollBar.SetSize(Classes.Point(ClientSize.X, HorizontalScrollBar.ClientSize.Y));
    end
    else
    begin
      TObjectGI(HorizontalScrollBar).SetPosition(HorizontalScrollBarRect.TopLeft);
      HorizontalScrollBar.SetSize(
          SubtractPoints(HorizontalScrollBarRect.BottomRight, HorizontalScrollBarRect.TopLeft)
      );
    end;
    if AutoVerticalPlacement then
    begin
      TObjectGI(VerticalScrollBar)
          .SetPosition(Classes.Point(LocalPosition.X + ClientSize.X, LocalPosition.Y));
      VerticalScrollBar.SetSize(Classes.Point(VerticalScrollBar.ClientSize.X, ClientSize.Y));
    end
    else
    begin
      TObjectGI(VerticalScrollBar).SetPosition(VerticalScrollBarRect.TopLeft);
      VerticalScrollBar.SetSize(
          SubtractPoints(VerticalScrollBarRect.BottomRight, VerticalScrollBarRect.TopLeft)
      );
    end;
  end;
end;

procedure TPanelScrollBarGI.UpdateScrollRanges;
var
  Child: TObjectGI;
  Bounds, ChildBounds: TRect;
begin
  if not Active then
    Exit;
  Bounds.Left := $7FFFFFF0;
  Bounds.Top := $7FFFFFF0;
  Bounds.Right := -$7FFFFFF0;
  Bounds.Bottom := -$7FFFFFF0;
  Child := FirstChild;
  while Child <> nil do
  begin
    if (Child <> HorizontalScrollBar)
        and (Child <> VerticalScrollBar)
        and (Child.PositionModeW = True)
        and (Child.Active = True) then
    begin
      ChildBounds := Child.GetLocalBounds;
      if ChildBounds.Left < Bounds.Left then
        Bounds.Left := ChildBounds.Left;
      if ChildBounds.Top < Bounds.Top then
        Bounds.Top := ChildBounds.Top;
      if ChildBounds.Right > Bounds.Right then
        Bounds.Right := ChildBounds.Right;
      if ChildBounds.Bottom > Bounds.Bottom then
        Bounds.Bottom := ChildBounds.Bottom;
    end;
    Child := Child.NextSibling;
  end;
  if HorizontalScrollBar <> nil then
  begin
    HorizontalScrollBar.SetRange(Bounds.Left, Bounds.Right - 1);
    HorizontalScrollBar.SetPageSize(ClientSize.X);
    HorizontalScrollBar.SetPositionInternal(ScrollOffset.X);
  end;
  if VerticalScrollBar <> nil then
  begin
    VerticalScrollBar.SetRange(Bounds.Top, Bounds.Bottom - 1);
    VerticalScrollBar.SetPageSize(ClientSize.Y);
    VerticalScrollBar.SetPositionInternal(ScrollOffset.Y);
  end;
end;

procedure TPanelScrollBarGI.ScrollbarPositionChanged(Sender: TObjectGI);
begin
  SetScrollOffset(Classes.Point(HorizontalScrollBar.Position, VerticalScrollBar.Position));
end;

procedure TPanelScrollBarGI.PanelScrollChanged(Sender: TObjectGI);
begin
  HorizontalScrollBar.SetPositionInternal(ScrollOffset.X);
  VerticalScrollBar.SetPositionInternal(ScrollOffset.Y);
  if not UnlimitedWorld then
    SetScrollOffset(Classes.Point(HorizontalScrollBar.Position, VerticalScrollBar.Position));
end;

procedure TPanelScrollBarGI.ScrollbarDestroyed(Sender: TObjectGI);
begin
  if HorizontalScrollBar = Sender then
    HorizontalScrollBar := nil;
  if VerticalScrollBar = Sender then
    VerticalScrollBar := nil;
end;

procedure TPanelScrollBarGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadScrollbarPanelProperties(UiStyleConfig.GetBlockByPath(Path));
end;

procedure TPanelScrollBarGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadScrollbarPanelProperties(Block);
end;

procedure TPanelScrollBarGI.LoadScrollbarPanelProperties(Block: TBlockParEC);
begin
  if Block.CountParams('StyleBarX') > 0 then
    HorizontalScrollBar.SetConfigPath(Block.GetParam('StyleBarX'));
  if Block.CountParams('StyleBarY') > 0 then
    VerticalScrollBar.SetConfigPath(Block.GetParam('StyleBarY'));
  if Block.CountParams('ActiveBarX') > 0 then
  begin
    if Block.GetParam('ActiveBarX') = 'True' then
      SetHorizontalScrollbarEnabled(True)
    else
      SetHorizontalScrollbarEnabled(False);
  end;
  if Block.CountParams('ActiveBarY') > 0 then
  begin
    if Block.GetParam('ActiveBarY') = 'True' then
      SetVerticalScrollbarEnabled(True)
    else
      SetVerticalScrollbarEnabled(False);
  end;
  if Block.CountParams('ExternalSB') > 0 then
  begin
    if TrimWideString(Block.GetParam('ExternalSB')) = 'True' then
      SetScrollbarsOutside(True)
    else
      SetScrollbarsOutside(False);
  end;
  if Block.CountParams('UnlimitedWorld') > 0 then
  begin
    if TrimWideString(Block.GetParam('UnlimitedWorld')) = 'True' then
      SetUnlimitedWorldEnabled(True)
    else
      SetUnlimitedWorldEnabled(False);
  end;
  if Block.CountParams('PosAutoBarX') > 0 then
    AutoHorizontalPlacement := ParseEnabledNameGI(Block.GetParam('PosAutoBarX'));
  if Block.CountParams('PosAutoBarY') > 0 then
    AutoVerticalPlacement := ParseEnabledNameGI(Block.GetParam('PosAutoBarY'));
  if Block.CountParams('RectBarX') > 0 then
    HorizontalScrollBarRect := GetRectGI(Block.GetParam('RectBarX'));
  if Block.CountParams('RectBarY') > 0 then
    VerticalScrollBarRect := GetRectGI(Block.GetParam('RectBarY'));
  UpdateScrollbarPlacement;
  UpdateScrollRanges;
end;

end.
