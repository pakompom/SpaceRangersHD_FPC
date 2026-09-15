{$EXCESSPRECISION OFF}
unit GI_Panel;
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
  TPanelGI = class;
  {$Z1}
  TPanelScrollTypeGI = (pstSimple = 0, pstAll = 1, pstObj = 2, pstView = 3);
  {$Z1}
  TPanelScrollAxisGI = (psaHorizontal = 0, psaVertical = 1, psaBoth = 2);
  TPanelGI = class(TObjectGI)
    DragScrollingEnabled: Boolean;
    ScrollType: TPanelScrollTypeGI;
    Dragging: Boolean;
    LastDragPoint: TPoint;
    Gap12B: array[0..4] of Byte;
    ScrollChangedCallback: TObjectNotifyEventGI;
    ScrollAxis: TPanelScrollAxisGI;
    Gap139: array[0..2] of Byte;
    procedure Clear; override;
    function GetChildAbsolutePosition(LocalPosition: TPoint; ModeW: Boolean): TPoint; override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure ProcessMouseMove(KeyState: Cardinal; Point: TPoint); override;
    procedure OnMouseEnter; override;
    procedure OnMouseLeave; override;
    procedure OnActivate; override;
    procedure ProcessRightButtonDown(KeyState: Cardinal; Point: TPoint); override;
    procedure ProcessRightButtonUp(KeyState: Cardinal; Point: TPoint); override;
    function ToLocalPoint(Point: TPoint): TPoint; override;
    function ToAbsolutePoint(Point: TPoint): TPoint; override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    procedure SetScrollOffset(Offset: TPoint); virtual;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure SetDragScrollingEnabled(Value: Boolean);
    function GetVisibleContentRect: TRect;
    procedure ScrollRectIntoView(Rect: TRect);
  end;
implementation
uses
  Math,
  Classes,
  EC_Str,
  GI_Main,
  GR_Main,
  SysUtils;

constructor TPanelGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  SkipOwnQueuedDraw := 1;
  DragScrollingEnabled := False;
  ScrollType := pstAll;
end;

destructor TPanelGI.Destroy;
begin
  inherited Destroy;
end;

procedure TPanelGI.Clear;
begin
  inherited Clear;
  ScrollOffset.X := 0;
  ScrollOffset.Y := 0;
  Dragging := False;
  DragScrollingEnabled := False;
  ScrollType := pstAll;
  ScrollAxis := psaBoth;
end;

function TPanelGI.GetChildAbsolutePosition(LocalPosition: TPoint; ModeW: Boolean): TPoint;
begin
  if not ModeW then
  begin
    Result.X := AbsolutePosition.X + LocalPosition.X;
    Result.Y := AbsolutePosition.Y + LocalPosition.Y;
  end
  else
  begin
    Result.X := AbsolutePosition.X + LocalPosition.X - ScrollOffset.X;
    Result.Y := AbsolutePosition.Y + LocalPosition.Y - ScrollOffset.Y;
  end;
end;

function TPanelGI.ToLocalPoint(Point: TPoint): TPoint;
begin
  Result.X := Point.X - AbsolutePosition.X + ScrollOffset.X;
  Result.Y := Point.Y - AbsolutePosition.Y + ScrollOffset.Y;
end;

function TPanelGI.ToAbsolutePoint(Point: TPoint): TPoint;
begin
  Result.X := Point.X + AbsolutePosition.X - ScrollOffset.X;
  Result.Y := Point.Y + AbsolutePosition.Y - ScrollOffset.Y;
end;

procedure TPanelGI.SetDragScrollingEnabled(Value: Boolean);
begin
  if Value <> DragScrollingEnabled then
  begin
    DragScrollingEnabled := Value;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Invalidate;
  end;
end;

procedure TPanelGI.SetScrollOffset(Offset: TPoint);
var
  Child: TObjectGI;
  Delta: TPoint;
  DestRect, SourceRect: TRect;
begin
  if (ScrollOffset.X = Offset.X) and (ScrollOffset.Y = Offset.Y) then
    Exit;
  if ScrollType = pstSimple then
  begin
    ScrollOffset := Offset;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
  end
  else if ScrollType = pstAll then
  begin
    ScrollOffset := Offset;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Invalidate;
  end
  else if ScrollType = pstObj then
  begin
    MessageLoop.RegionDrawPending := True;
    MessageLoop.InvalidateMouseViewControls;
    Child := FirstChild;
    while Child <> nil do
    begin
      if Child.PositionModeW then
        Child.Invalidate;
      Child := Child.NextSibling;
    end;
    ScrollOffset := Offset;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Child := FirstChild;
    while Child <> nil do
    begin
      if Child.PositionModeW then
        Child.Invalidate;
      Child := Child.NextSibling;
    end;
  end
  else if ScrollType = pstView then
  begin
    Delta.X := ScrollOffset.X - Offset.X;
    Delta.Y := ScrollOffset.Y - Offset.Y;
    if (Abs(Delta.X) > ClientSize.X div 2) or (Abs(Delta.Y) > ClientSize.Y div 2) then
    begin
      ScrollOffset := Offset;
      UpdateAbsolutePosition;
      UpdateSubtreeHitBounds;
      Invalidate;
      Exit;
    end;
    MessageLoop.DrawQueuedUpdateRects;
    ScrollOffset := Offset;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    MessageLoop.RootUiObject.InvalidateScrollOverlap(HitTestBounds, Delta, Self);
    DestRect := GetLocalBounds;
    SourceRect := DestRect;
    if Delta.X > 0 then
    begin
      InvalidateRect(
          Classes.Rect(DestRect.Left, DestRect.Top, DestRect.Left + Delta.X, DestRect.Bottom)
      );
      Inc(DestRect.Left, Delta.X);
      Dec(SourceRect.Right, Delta.X);
    end
    else if Delta.X < 0 then
    begin
      InvalidateRect(
          Classes.Rect(DestRect.Right + Delta.X, DestRect.Top, DestRect.Right, DestRect.Bottom)
      );
      Inc(DestRect.Right, Delta.X);
      Dec(SourceRect.Left, Delta.X);
    end;
    if Delta.Y > 0 then
    begin
      InvalidateRect(
          Classes.Rect(DestRect.Left, DestRect.Top, DestRect.Right, DestRect.Top + Delta.Y)
      );
      Inc(DestRect.Top, Delta.Y);
      Dec(SourceRect.Bottom, Delta.Y);
    end
    else if Delta.Y < 0 then
    begin
      InvalidateRect(
          Classes.Rect(DestRect.Left, DestRect.Bottom + Delta.Y, DestRect.Right, DestRect.Bottom)
      );
      Inc(DestRect.Bottom, Delta.Y);
      Dec(SourceRect.Top, Delta.Y);
    end;
    Ex_OKGR_CopySingleBuf_XY_XY_WORD(
        ScreenRenderBuffer.GetPixels,
        ScreenRenderBuffer.PitchBytes,
        DestRect.Left,
        DestRect.Top,
        SourceRect.Left,
        SourceRect.Top,
        SourceRect.Right - SourceRect.Left,
        SourceRect.Bottom - SourceRect.Top
    );
  end;
end;

function TPanelGI.GetVisibleContentRect: TRect;
begin
  Result.Left := ScrollOffset.X - OriginPoint.X;
  Result.Top := ScrollOffset.Y - OriginPoint.Y;
  Result.Right := Result.Left + ClientSize.X;
  Result.Bottom := Result.Top + ClientSize.Y;
end;

procedure TPanelGI.ScrollRectIntoView(Rect: TRect);
var
  Offset: TPoint;
  Visible: TRect;
begin
  Offset := ScrollOffset;
  Visible := GetVisibleContentRect;
  if Rect.Bottom > Visible.Bottom then
  begin
    Offset.Y := Rect.Bottom - (Visible.Bottom - Visible.Top);
    SetScrollOffset(Offset);
  end;
  Offset := ScrollOffset;
  Visible := GetVisibleContentRect;
  if Rect.Top < Visible.Top then
  begin
    Offset.Y := Rect.Top;
    SetScrollOffset(Offset);
  end;
  Offset := ScrollOffset;
  Visible := GetVisibleContentRect;
  if Rect.Right > Visible.Right then
  begin
    Offset.X := Rect.Right - (Visible.Right - Visible.Left);
    SetScrollOffset(Offset);
  end;
  Offset := ScrollOffset;
  Visible := GetVisibleContentRect;
  if Rect.Left < Visible.Left then
  begin
    Offset.X := Rect.Left;
    SetScrollOffset(Offset);
  end;
end;

procedure TPanelGI.OnActivate;
begin
  inherited OnActivate;
  Dragging := False;
end;

procedure TPanelGI.ProcessMouseMove(KeyState: Cardinal; Point: TPoint);
var
  X, Y: Integer;
begin
  inherited ProcessMouseMove(KeyState, Point);
  if Dragging = True then
    if (Point.X <> LastDragPoint.X) or (Point.Y <> LastDragPoint.Y) then
    begin
      if MessageLoop.IsCursorImageSelected('Main') then
        MessageLoop.SetCursorByName('Scroll');
      if (ScrollAxis = psaHorizontal) or (ScrollAxis = psaBoth) then
        X := ScrollOffset.X + LastDragPoint.X - Point.X
      else
        X := ScrollOffset.X;
      if (ScrollAxis = psaVertical) or (ScrollAxis = psaBoth) then
        Y := ScrollOffset.Y + LastDragPoint.Y - Point.Y
      else
        Y := ScrollOffset.Y;
      SetScrollOffset(Classes.Point(X, Y));
      LastDragPoint := Point;
      if Assigned(ScrollChangedCallback) then
        ScrollChangedCallback(Self);
    end;
end;

procedure TPanelGI.OnMouseEnter;
begin
  inherited OnMouseEnter;
  Dragging := False;
end;

procedure TPanelGI.OnMouseLeave;
begin
  inherited OnMouseLeave;
  Dragging := False;
  if MessageLoop.IsCursorImageSelected('Scroll') then
    MessageLoop.SetCursorByName('Main');
end;

procedure TPanelGI.ProcessRightButtonDown(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessRightButtonDown(KeyState, Point);
  if not IsOccludedAtPoint(Point) and (DragScrollingEnabled = True) then
  begin
    Dragging := True;
    LastDragPoint := Point;
    if MessageLoop.IsCursorImageSelected('Main') then
      MessageLoop.SetCursorByName('Scroll');
  end;
end;

procedure TPanelGI.ProcessRightButtonUp(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessRightButtonUp(KeyState, Point);
  Dragging := False;
  if MessageLoop.IsCursorImageSelected('Scroll') then
    MessageLoop.SetCursorByName('Main');
end;

procedure TPanelGI.LoadFromConfigPath(const Path: WideString);
var
  Block: TBlockParEC;
  Text: WideString;
begin
  inherited LoadFromConfigPath(Path);
  Block := UiStyleConfig.GetBlockByPath(Path);
  if Block.CountParams('CenterWorld') > 0 then
  begin
    Text := Block.GetParam('CenterWorld');
    ScrollOffset.X := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
    ScrollOffset.Y := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
  end;
  if Block.CountParams('MoveWorld') > 0 then
    DragScrollingEnabled := ParseEnabledNameGI(Block.GetParam('MoveWorld'));
end;

procedure TPanelGI.LoadFromBlock(Block: TBlockParEC);
var
  Text: WideString;
begin
  inherited LoadFromBlock(Block);
  if Block.CountParams('CenterWorld') > 0 then
  begin
    Text := Block.GetParam('CenterWorld');
    ScrollOffset.X := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
    ScrollOffset.Y := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
  end;
  if Block.CountParams('MoveWorld') > 0 then
    if TrimWideString(Block.GetParam('MoveWorld')) = 'True' then
      DragScrollingEnabled := True;
  if Block.CountParams('TypeScroll') > 0 then
  begin
    Text := Block.GetParam('TypeScroll');
    if Text = 'Simple' then
      ScrollType := pstSimple
    else if Text = 'All' then
      ScrollType := pstAll
    else if Text = 'Obj' then
      ScrollType := pstObj
    else if Text = 'View' then
      ScrollType := pstView;
  end;
end;

end.
