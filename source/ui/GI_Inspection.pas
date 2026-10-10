unit GI_Inspection;

{$I GameOptions.inc}

interface

uses
  Types,
  GI_MessageLoop,
  GI_Window,
  GI_PanelScrollBar;

// Preserve the original tooltip, scrolling a plain description body when needed.
// Bounds and Anchor use game-screen coordinates, including for nested controls.
procedure FitMobileTooltip(
    Control: TObjectGI;
    const Bounds: TRect;
    const Anchor: TPoint;
    TargetBounds: PRect = nil
);

// Unwrap before the ordinary tooltip builder runs. This restores reparented
// controls and shifted decorations, not text wrapping or the window's size;
// the builder must recalculate that geometry before FitMobileTooltip runs again.
procedure RestoreMobileTooltipBody(Window: TWindowGI);

// A scrolling gesture remains owned by its inspector after leaving its bounds.
function InspectionOwnsTouch(Window: TObjectGI): Boolean;

// Hover polling and an already queued hide timer must not replace a readable
// inspector while its pointer or scrolling gesture is inside it.
function KeepMobileTooltipVisible(Window: TWindowGI; var HideTimer: PCallbackTimerGI): Boolean;

// Icon-leave tooltips have no hover polling of their own. The wrapped body
// owns this deferred dismissal; OnLeave(nil) is called after interaction ends.
function DeferMobileTooltipLeave(Window: TWindowGI; OnLeave: TObjectNotifyEventGI): Boolean;
procedure CancelMobileTooltipLeave(Window: TWindowGI);

// The window owns Scroll and Body. Callers retain only borrowed references;
// loading a new control tree invalidates them. Creation/reparenting happens once.
procedure PrepareInspectionBody(Window: TWindowGI; Body: TObjectGI; var Scroll: TPanelScrollBarGI);

// Keep the original frame and fixed header/footer; only its body can scroll.
procedure FitInspectionWindow(
    Window: TWindowGI;
    Body: TObjectGI;
    var Scroll: TPanelScrollBarGI;
    const Bounds, Target: TRect;
    WrapText: Boolean
);

implementation

uses
  Classes,
  Math,
  GameWindow,
  GI_Label,
  GI_Main,
  GI_Panel,
  GlobalsV;

type
  TTooltipChildGeometry = record
    Control: TObjectGI;
    Position, Size: TPoint;
  end;

  TTooltipBodyScrollGI = class(TPanelScrollBarGI)
    // Body and ChangedChildren belong to the same window tree. Unwrap the body
    // before rebuilding that tree; these are borrowed references, not copies.
    Body: TLabelGI;
    SourcePosition: TPoint;
    SourcePositionModeW, SourceMouseBlocking: Boolean;
    ChangedChildren: array of TTooltipChildGeometry;
    LeaveTimer: PCallbackTimerGI;
    LeaveCallback: TObjectNotifyEventGI;
    procedure RememberGeometry(Control: TObjectGI);
    procedure StopLeaveTimer;
    procedure CheckPointerLeave(Timer: PCallbackTimerGI; UserData: PtrInt);
    procedure OnDeactivate; override;
    destructor Destroy; override;
  end;

function FindTooltipScroll(Window: TWindowGI): TTooltipBodyScrollGI;
begin
  Result := nil;
  if Window <> nil then
    Result := Window.FindByNameRecursive('MobileTooltipBody') as TTooltipBodyScrollGI;
end;

function MobileTooltipInUse(Window: TWindowGI): Boolean;
begin
  // Only wrapped mobile descriptions opt into this lifetime. Keep short,
  // structured and desktop hover tips on their original dismissal paths.
  Result :=
      GameMobileUiEnabled
          and (Window <> nil)
          and Window.Active
          and (Window.MessageLoop <> nil)
          and (FindTooltipScroll(Window) <> nil)
          and (Window.ContainsPoint(Window.MessageLoop.GetCursorPoint)
              or InspectionOwnsTouch(Window));
end;

procedure TTooltipBodyScrollGI.StopLeaveTimer;
begin
  if LeaveTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(LeaveTimer);
    LeaveTimer := nil;
  end;
end;

procedure TTooltipBodyScrollGI.CheckPointerLeave(Timer: PCallbackTimerGI; UserData: PtrInt);
var
  Callback: TObjectNotifyEventGI;
begin
  if MobileTooltipInUse(Parent as TWindowGI) then
    Exit;
  Callback := LeaveCallback;
  StopLeaveTimer;
  // The original screen owns hiding and associated selection bookkeeping.
  // It may destroy or rebuild this body, so do not access it afterward.
  Callback(nil);
end;

procedure TTooltipBodyScrollGI.OnDeactivate;
begin
  StopLeaveTimer;
  inherited;
end;

destructor TTooltipBodyScrollGI.Destroy;
begin
  StopLeaveTimer;
  inherited;
end;

procedure TTooltipBodyScrollGI.RememberGeometry(Control: TObjectGI);
var
  Index: Integer;
begin
  Index := Length(ChangedChildren);
  SetLength(ChangedChildren, Index + 1);
  ChangedChildren[Index].Control := Control;
  ChangedChildren[Index].Position := Control.LocalPosition;
  ChangedChildren[Index].Size := Control.ClientSize;
end;

function InspectionOwnsTouch(Window: TObjectGI): Boolean;
var
  Control: TObjectGI;
begin
  Result := False;
  if (Window = nil)
      or not Window.Active
      or (Window.MessageLoop = nil)
      or (Window.MessageLoop.TouchDragKind <> tdScroll) then
    Exit;
  Control := Window.MessageLoop.TouchScrollControl;
  while Control <> nil do
  begin
    if Control = Window then
      Exit(True);
    Control := Control.Parent;
  end;
end;

function KeepMobileTooltipVisible(Window: TWindowGI; var HideTimer: PCallbackTimerGI): Boolean;
begin
  Result := MobileTooltipInUse(Window);
  if Result and (HideTimer <> nil) then
  begin
    Window.MessageLoop.CancelCallbackTimer(HideTimer);
    HideTimer := nil;
  end;
end;

function DeferMobileTooltipLeave(Window: TWindowGI; OnLeave: TObjectNotifyEventGI): Boolean;
var
  Scroll: TTooltipBodyScrollGI;
begin
  Result := False;
  if not GameMobileUiEnabled or (Window = nil) or not Window.Active then
    Exit;
  Scroll := FindTooltipScroll(Window);
  if Scroll = nil then
    Exit;
  Scroll.StopLeaveTimer;
  Scroll.LeaveCallback := OnLeave;
  Scroll.LeaveTimer := Window.MessageLoop.ScheduleCallbackTimer(100, 100, Scroll.CheckPointerLeave);
  Result := True;
end;

procedure CancelMobileTooltipLeave(Window: TWindowGI);
var
  Scroll: TTooltipBodyScrollGI;
begin
  Scroll := FindTooltipScroll(Window);
  if Scroll <> nil then
    Scroll.StopLeaveTimer;
end;

procedure RestoreMobileTooltipBody(Window: TWindowGI);
var
  Scroll: TTooltipBodyScrollGI;
  Geometry: TTooltipChildGeometry;
begin
  Scroll := FindTooltipScroll(Window);
  if Scroll = nil then
    Exit;
  for Geometry in Scroll.ChangedChildren do
  begin
    Geometry.Control.SetPosition(Geometry.Position);
    Geometry.Control.SetSize(Geometry.Size);
  end;
  Window.MouseBlocking := Scroll.SourceMouseBlocking;
  Scroll.Body.Reparent(Window);
  Scroll.Body.SetPosition(Scroll.SourcePosition);
  Scroll.Body.SetPositionModeW(Scroll.SourcePositionModeW);
  Scroll.Free;
end;

procedure ConfigureInspectionBody(Scroll: TPanelScrollBarGI; Body: TObjectGI);
begin
  Scroll.SetDepth(Body.Depth);
  Scroll.SetDragScrollingEnabled(True);
  Scroll.ScrollAxis := psaBoth;
  Scroll.VerticalScrollBar.SetIndicatorThickness(2);
  Scroll.HorizontalScrollBar.SetIndicatorThickness(2);
  Body.Reparent(Scroll);
  Body.SetPositionModeW(True);
end;

procedure PrepareInspectionBody(Window: TWindowGI; Body: TObjectGI; var Scroll: TPanelScrollBarGI);
begin
  if Scroll <> nil then
    Exit;
  Scroll := TPanelScrollBarGI.Create(Window);
  ConfigureInspectionBody(Scroll, Body);
end;

function FindTooltipBody(Window: TWindowGI): TLabelGI;
var
  Child: TObjectGI;
begin
  Result := nil;
  Child := Window.FirstChild;
  while Child <> nil do
  begin
    // LayoutItemInfo places its description at the work rectangle. Other
    // tooltip families contain tables and diagrams: do not flatten those.
    if (Child is TLabelGI)
        and Child.Active
        and TLabelGI(Child).WordWrapEnabled
        and (Child.LocalPosition.X = Window.WorkSubRect.Left)
        and (Child.LocalPosition.Y = Window.WorkSubRect.Top) then
      Exit(TLabelGI(Child));
    Child := Child.NextSibling;
  end;
end;

procedure FitMobileTooltip(
    Control: TObjectGI;
    const Bounds: TRect;
    const Anchor: TPoint;
    TargetBounds: PRect
);
var
  Area, Target, ControlBounds: TRect;
  Scale: Single;
  Width, Height, X, Y, Gap, SideWidth: Integer;
  Position: TPoint;
  Window: TWindowGI;
  Body: TLabelGI;
  Scroll: TPanelScrollBarGI;
  TooltipScroll: TTooltipBodyScrollGI;
  Child: TObjectGI;
  OriginalSize: TPoint;
begin
  if not GameMobileUiEnabled or not HardwareRenderingEnabled or (Control = nil) then
    Exit;
  Area := Bounds;
  InflateRect(Area, -12, -12);
  Target := Rect(Anchor.X, Anchor.Y, Anchor.X, Anchor.Y);
  if TargetBounds <> nil then
    Target := TargetBounds^;
  Control.UpdateAbsolutePosition;
  Control.UpdateSubtreeHitBounds;
  ControlBounds := Control.HitTestBounds;
  Width := ControlBounds.Right - ControlBounds.Left;
  Height := ControlBounds.Bottom - ControlBounds.Top;
  if (Width <= 0) or (Height <= 0) or (Area.Right <= Area.Left) or (Area.Bottom <= Area.Top) then
    Exit;
  Gap := Max(12, Round(6 * GetGameMobileUiScale));
  SideWidth := Max(Target.Left - Area.Left - Gap, Area.Right - Target.Right - Gap);
  if SideWidth <= 0 then
    SideWidth := Area.Right - Area.Left;
  if Control is TWindowGI then
  begin
    Window := TWindowGI(Control);
    TooltipScroll := FindTooltipScroll(Window);
    if TooltipScroll <> nil then
    begin
      // Repositioning an existing tip must not reset the reader's scroll.
      Scale := Window.GetDisplayScale;
      Width := Ceil(Window.ClientSize.X * Scale);
      Height := Ceil(Window.ClientSize.Y * Scale);
    end
    else
    begin
      Body := FindTooltipBody(Window);
      if (Body <> nil)
          and ((Height * GetGameMobileUiScale > (Area.Bottom - Area.Top) * 0.8)
              or (Width * GetGameMobileUiScale
                  > Min(SideWidth, (Area.Right - Area.Left) * 0.6))) then
      begin
        OriginalSize := Window.ClientSize;
        TooltipScroll := TTooltipBodyScrollGI.Create(Window);
        TooltipScroll.SetName('MobileTooltipBody');
        TooltipScroll.Body := Body;
        TooltipScroll.SourcePosition := Body.LocalPosition;
        TooltipScroll.SourcePositionModeW := Body.PositionModeW;
        TooltipScroll.SourceMouseBlocking := Window.MouseBlocking;
        ConfigureInspectionBody(TooltipScroll, Body);
        Scroll := TooltipScroll;
        FitInspectionWindow(Window, Body, Scroll, Bounds, Target, True);
        Child := Window.FirstChild;
        while Child <> nil do
        begin
          if (Child <> TooltipScroll)
              and (Child <> Window.LeftImage)
              and (Child <> Window.RightImage)
              and (Child <> Window.TopImage)
              and (Child <> Window.BottomImage)
              and (Child <> Window.TopLeftImage)
              and (Child <> Window.TopRightImage)
              and (Child <> Window.BottomLeftImage)
              and (Child <> Window.BottomRightImage)
              and (Child <> Window.TextureImage) then
          begin
            Position := Child.LocalPosition;
            if Position.Y >= OriginalSize.Y - Window.WorkSubRect.Bottom then
            begin
              TooltipScroll.RememberGeometry(Child);
              Inc(Position.Y, Window.ClientSize.Y - OriginalSize.Y);
              if Position.X > OriginalSize.X div 2 then
                Inc(Position.X, Window.ClientSize.X - OriginalSize.X);
              Child.SetPosition(Position);
            end
            else if (Child is TLabelGI)
                and (Position.Y < Window.WorkSubRect.Top)
                and (Position.X + Child.ClientSize.X
                    > Window.ClientSize.X - Window.WorkSubRect.Right) then
            begin
              TooltipScroll.RememberGeometry(Child);
              Child.SetSize(
                  Classes.Point(
                      Max(1, Window.ClientSize.X - Window.WorkSubRect.Right - Position.X),
                      Child.ClientSize.Y
                  )
              );
            end;
          end;
          Child := Child.NextSibling;
        end;
        Window.UpdateAbsolutePosition;
        Window.UpdateSubtreeHitBounds;
        Exit;
      end;
    end;
  end
  else
    TooltipScroll := nil;
  // Short and structured tips retain the complete original composition.
  if TooltipScroll = nil then
    Scale :=
        Min(
            GetGameMobileUiScale,
            Min(
                Min(SideWidth, (Area.Right - Area.Left) * 0.6) / Width,
                (Area.Bottom - Area.Top) * 0.8 / Height
            )
        );
  if TooltipScroll = nil then
  begin
    Width := Ceil(Width * Scale);
    Height := Ceil(Height * Scale);
  end;
  if Target.Left - Area.Left < Area.Right - Target.Right then
    X := Target.Right + Gap
  else
    X := Target.Left - Width - Gap;
  Y := Target.Top - Height - Gap;
  if Y < Area.Top then
    Y := Target.Bottom + Gap;
  X := EnsureRange(X, Area.Left, Area.Right - Width);
  Y := EnsureRange(Y, Area.Top, Area.Bottom - Height);
  PlaceControlAtScreen(
      Control,
      Classes.Point(
          X + Round(Control.OriginPoint.X * Scale),
          Y + Round(Control.OriginPoint.Y * Scale)
      ),
      Scale
  );
end;

procedure FitInspectionWindow(
    Window: TWindowGI;
    Body: TObjectGI;
    var Scroll: TPanelScrollBarGI;
    const Bounds, Target: TRect;
    WrapText: Boolean
);
var
  Area, Available, Borders: TRect;
  Scale, MinimumScale: Single;
  Width, Height, BodyWidth, BodyHeight, MaximumWidth, MaximumHeight: Integer;
  VerticalScroll, HorizontalScroll: Boolean;

  procedure MeasureBody(AvailableWidth: Integer);
  begin
    if WrapText and (Body is TLabelGI) then
      with TLabelGI(Body) do
      begin
        SetWordWrapEnabled(True);
        SetTextAlignY(tayAuto);
        SetSize(Classes.Point(Max(1, AvailableWidth), 1));
      end;
    BodyHeight := Body.ClientSize.Y;
    Height :=
        Min(Max(Window.MinimumSize.Y, BodyHeight + Borders.Top + Borders.Bottom), MaximumHeight);
  end;
begin
  Area := Bounds;
  InflateRect(Area, -12, -12);
  if (Area.Right <= Area.Left) or (Area.Bottom <= Area.Top) then
    Exit;
  Available := Area;
  Borders := Window.WorkSubRect;
  Scale := 1;
  if HardwareRenderingEnabled then
    Scale := GetGameMobileUiScale;
  MinimumScale := Scale * 0.8;
  // Reserve the selected object while a usable inspector fits beside it.
  // Otherwise use the available panel area instead of shrinking all its text
  // to fit a narrow gap. The body can scroll; Back dismisses the inspection.
  if Target.Left - Area.Left > Area.Right - Target.Right then
    Area.Right := Target.Left - 12
  else
    Area.Left := Target.Right + 12;
  if Area.Right - Area.Left < Max(Window.MinimumSize.X, 240) * MinimumScale then
    Area := Available;
  Scale := Min(Scale, (Area.Right - Area.Left) / Max(1, Window.MinimumSize.X));
  Scale :=
      Min(
          Scale,
          (Area.Bottom - Area.Top) / Max(Window.MinimumSize.Y, Borders.Top + Borders.Bottom + 48)
      );
  if Scale <= 0 then
    Exit;
  MaximumWidth := Floor((Area.Right - Area.Left) / Scale);
  MaximumHeight := Floor((Area.Bottom - Area.Top) / Scale);
  Width := Min(Max(Window.MinimumSize.X, Window.ClientSize.X), MaximumWidth);
  BodyWidth := Max(1, Width - Borders.Left - Borders.Right);
  MeasureBody(BodyWidth);
  VerticalScroll := BodyHeight > Height - Borders.Top - Borders.Bottom;
  if VerticalScroll then
  begin
    // Add an indicator gutter only for actual overflow. Taking it out of an
    // already fitting table used to create six pixels of needless sideways scroll.
    Width := Min(MaximumWidth, Width + 6);
    BodyWidth := Max(1, Width - Borders.Left - Borders.Right);
    MeasureBody(BodyWidth - 6);
  end;
  HorizontalScroll := Body.ClientSize.X > BodyWidth;

  // Original hover tips allow click-through. A pinned, scrollable inspector
  // must not send taps to other items or stars underneath it.
  Window.MouseBlocking := True;
  Window.SetSize(Classes.Point(Width, Height));
  // Exact bounds matter here: tile alignment may otherwise grow past Area.
  Window.UpdateBorderLayout;
  PrepareInspectionBody(Window, Body, Scroll);
  Scroll.SetPosition(Borders.TopLeft);
  Scroll.SetSize(Classes.Point(BodyWidth, Max(1, Height - Borders.Top - Borders.Bottom)));
  Scroll.SetScrollOffset(Classes.Point(0, 0));
  Body.SetPosition(Classes.Point(0, 0));
  Scroll.UpdateScrollRanges;
  Scroll.SetVerticalScrollbarEnabled(VerticalScroll);
  Scroll.SetHorizontalScrollbarEnabled(HorizontalScroll);
  PlaceControlAtScreen(
      Window,
      Classes.Point(
          Round((Area.Left + Area.Right - Width * Scale) / 2),
          Round((Area.Top + Area.Bottom - Height * Scale) / 2)
      ),
      Scale
  );
  Window.MessageLoop.InvalidateViewport;
end;

end.
