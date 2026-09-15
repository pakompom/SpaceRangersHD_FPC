{$EXCESSPRECISION OFF}
unit GI_MessageLoop;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  RTLFileSystem,
  GR_Rect,
  Classes,
  EC_BlockPar,
  EC_Str,
  EC_Struct,
  Types;
type
  TFormSoundGroup = class;
  TMessageLoopGI = class;
  TObjectGI = class;
  PointerToTCallbackTimerGI = ^TCallbackTimerGI;
  PointerToTCursorStateGI = ^TCursorStateGI;
  TDialogChoiceEventGI = procedure(Value: PtrInt) of object;
  TObjectNotifyEventGI = procedure(Sender: TObjectGI) of object;
  TObjectMouseEventGI = procedure(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint) of object;
  TObjectHelpEventGI = procedure(Sender: TObjectGI; Visible: Boolean) of object;
  TObjectKeyEventGI = procedure(Sender: TObjectGI; Key: Cardinal) of object;
  TCursorStateGI = packed record
    ImagePath: WideString;
    Active: Boolean;
    HotSpot: TPoint;
    Position: TPoint;
    Gap15: array[0..2] of Byte;
  end;
  TObjectGI = class(TObjectEx)
    FirstChild: TObjectGI;
    LastChild: TObjectGI;
    PrevSibling: TObjectGI;
    NextSibling: TObjectGI;
    Parent: TObjectGI;
    MessageLoop: TMessageLoopGI;
    SourceBlock: TBlockParEC;
    LocalPosition: TPoint;
    ClientSize: TPoint;
    OriginPoint: TPoint;
    Depth: Double;
    PositionModeW: Boolean;
    Active: Boolean;
    HitTestDisabled: Boolean;
    Gap43: array[0..0] of Byte;
    ConfigPath: WideString;
    AutoOffsetEnabled: Boolean;
    Gap49: array[0..2] of Byte;
    AutoOffsetScale: TPointF;
    ScrollOffset: TPoint;
    SkipOwnQueuedDraw: Integer;
    HitTestBounds: TRect;
    AbsolutePosition: TPoint;
    ControlName: WideString;
    HelpText: WideString;
    HelpCallback: TObjectHelpEventGI;
    MouseInside: Boolean;
    MouseBlocking: Boolean;
    MouseBlockingTest: Boolean;
    ScrollUpdate: Boolean;
    UserValue: PtrInt;
    UserIndex: PtrInt;
    UserData: PtrInt;
    UserState: PtrInt;
    Gap9C: array[0..3] of Byte;
    MouseMoveCallback: TObjectMouseEventGI;
    LeftButtonDownCallback: TObjectMouseEventGI;
    LeftButtonUpCallback: TObjectMouseEventGI;
    RightButtonDownCallback: TObjectMouseEventGI;
    RightButtonUpCallback: TObjectMouseEventGI;
    LeftButtonDoubleClickCallback: TObjectMouseEventGI;
    RightButtonDoubleClickCallback: TObjectMouseEventGI;
    MouseEnterCallback: TObjectNotifyEventGI;
    MouseLeaveCallback: TObjectNotifyEventGI;
    ActivateCallback: TObjectNotifyEventGI;
    DeactivateCallback: TObjectNotifyEventGI;
    DestroyNotify: TObjectNotifyEventGI;
    KeyDownCallback: TObjectKeyEventGI;
    KeyUpCallback: TObjectKeyEventGI;
    OnKeyDownCode: TBlockParEC;
    OnMouseEnterCode: TBlockParEC;
    OnMouseLeaveCode: TBlockParEC;
    OnRightButtonDownCode: TBlockParEC;
    procedure Clear; virtual;
    function GetChildAbsolutePosition(LocalPosition: TPoint; ModeW: Boolean): TPoint; virtual;
    procedure UpdateHitTestBounds; virtual;
    procedure SetPosition(Position: TPoint); virtual;
    procedure SetDepth(NewDepth: Double); virtual;
    procedure SetDepthByName(const Name: WideString); virtual;
    procedure SetSize(Size: TPoint); virtual;
    procedure SetOrigin(Origin: TPoint); virtual;
    procedure SetConfigPath(const Path: WideString); virtual;
    function GetLocalBounds: TRect; virtual;
    procedure SetActive(Enabled: Boolean); virtual;
    procedure SetHitTestDisabled(Disabled: Boolean); virtual;
    procedure QueueImageLoad(PendingLoads: TList); virtual;
    procedure LoadFromConfigPath(const Path: WideString); virtual;
    procedure ProcessMouseMove(KeyState: Cardinal; Point: TPoint); virtual;
    procedure OnMouseEnter; virtual;
    procedure OnMouseLeave; virtual;
    procedure OnActivate; virtual;
    procedure NativeHook48; virtual;
    procedure OnDeactivate; virtual;
    procedure NativeHook50; virtual;
    procedure ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint); virtual;
    procedure ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint); virtual;
    procedure ProcessRightButtonDown(KeyState: Cardinal; Point: TPoint); virtual;
    procedure ProcessRightButtonUp(KeyState: Cardinal; Point: TPoint); virtual;
    procedure ProcessLeftButtonDoubleClick(KeyState: Cardinal; Point: TPoint); virtual;
    procedure ProcessRightButtonDoubleClick(KeyState: Cardinal; Point: TPoint); virtual;
    procedure BroadcastKeyDown(Key: Cardinal); virtual;
    procedure BroadcastKeyUp(Key: Cardinal); virtual;
    procedure OnHoverGained; virtual;
    procedure OnHoverLost; virtual;
    procedure OnFocusGained; virtual;
    procedure OnFocusLost; virtual;
    procedure ProcessKeyDown(Key: Integer); virtual;
    procedure ProcessCharacter(Character: WideChar); virtual;
    procedure OnCaretBlink; virtual;
    function ToLocalPoint(Point: TPoint): TPoint; virtual;
    function ToAbsolutePoint(Point: TPoint): TPoint; virtual;
    procedure InvalidateRect(Rect: TRect); virtual;
    procedure Invalidate; virtual;
    procedure Draw(ClipRect: TRect); virtual;
    procedure DrawUpdateRects(ClipRect: TRect); virtual;
    procedure CommitFrameDraw; virtual;
    procedure ErasePreviousFrame; virtual;
    procedure NativeHookB0; virtual;
    procedure PrepareFrameDraw; virtual;
    procedure PrepareRegionDraw(ClipRect: TRect); virtual;
    procedure NativeHookBC(Rect: TRect); virtual;
    procedure LoadFromBlock(Block: TBlockParEC); virtual;
    procedure UpdateAutoGeometry; virtual;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure FreeOwnedChildren;
    procedure AttachOwnedChild(Child: TObjectGI);
    procedure InsertOwnedChildBefore(BeforeChild: TObjectGI; Child: TObjectGI);
    procedure InsertOwnedChildByDepth(Child: TObjectGI; NewDepth: Double);
    procedure FreeOwnedChild(Child: TObjectGI);
    procedure UnlinkOwnedChild(Child: TObjectGI);
    procedure Reparent(NewParent: TObjectGI);
    procedure SetMouseViewUpdates(Enabled: Boolean);
    procedure UpdateAbsolutePosition;
    procedure UpdateSubtreeHitBounds;
    procedure SetHelpCallbackRecursive(Callback: TObjectHelpEventGI);
    function OffsetChildRect(Rect: TRect; ModeW: Boolean): TRect;
    procedure SetPositionModeW(Enabled: Boolean);
    procedure SetName(const Name: WideString);
    function FindDeepestChildAtPoint(Point: TPoint): TObjectGI;
    function IsOccludedAtPoint(Point: TPoint): Boolean;
    function ContainsPoint(Point: TPoint): Boolean;
    function HitTestCursor: Boolean;
    function FindByNameRecursive(const Name: WideString): TObjectGI;
    procedure DispatchNamedEvent(EventKind: Integer; Param1: Integer; Param2: Integer);
    procedure InvalidateChildren(IncludePanels: Boolean);
    function InvalidateScrollOverlap(
        Rect: TRect;
        Delta: TPoint;
        StartControl: TObjectGI
    ): TObjectGI;
    procedure ReloadFromBlock;
  end;
  PCursorStateGI = PointerToTCursorStateGI;
  TFormSoundGroup = class(TObjectEx)
    Section: Integer;
    MinDelayMs: Integer;
    MaxDelayMs: Integer;
    NextPlayTick: Cardinal;
    TotalWeight: Integer;
    Sounds: TStringsEC;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure LoadFromBlock(Block: TBlockParEC);
    procedure ScheduleNextPlayback;
    procedure PlayIfDue;
  end;
  PCallbackTimerGI = PointerToTCallbackTimerGI;
  // Timer payloads and control UserValue slots can carry live object pointers.
  TCallbackTimerEventGI = procedure(Timer: PCallbackTimerGI; UserData: PtrInt) of object;
  TCallbackTimerGI = packed record
    Callback: TCallbackTimerEventGI;
    UserData: PtrInt;
    RepeatMs: Integer;
    DueTick: Cardinal;
    Prev: PCallbackTimerGI;
    Next: PCallbackTimerGI;
    // CHANGE: PERFORMANCE - Remember the deadline used by the lookup cache.
    CachedDueTick: Cardinal;
  end;
  TSavedLineGI = record
    First: TPoint;
    Last: TPoint;
    Pixels: Pointer;
    Heap: Cardinal;
  end;
  TMessageLoopGI = class(TObjectEx)
    RegisteredLoopName: WideString;
    ParentLoop: TMessageLoopGI;
    ChildLoop: TMessageLoopGI;
    DebugControl: TObjectGI;
    StatusLabel: TObjectGI;
    RootUiObject: TObjectGI;
    ContentPanel: TObjectGI;
    BackgroundPanel: TObjectGI;
    OverlayPanel: TObjectGI;
    CursorControl: TObjectGI;
    FocusedControl: TObjectGI;
    HoveredControl: TObjectGI;
    HelpLabel: TObjectGI;
    RegionDrawControl: TObjectGI;
    MouseViewUpdateControls: TList;
    RegionDrawPending: Boolean;
    Gap41: array[0..2] of Byte;
    CursorImagePath: WideString;
    ViewportRect: TRect;
    UpdateRectsEnabled: Boolean;
    Gap59: array[0..2] of Byte;
    UpdateRects: TArrayRectGR;
    ExitCode: Integer;
    CaretBlinkOn: Boolean;
    Gap65: array[0..2] of Byte;
    TimerTick: Cardinal;
    FirstTimer: PCallbackTimerGI;
    LastTimer: PCallbackTimerGI;
    // CHANGE: PERFORMANCE - First timer at each cached deadline; collisions fall back to the list.
    TimerDeadlineHeads: array[0..255] of PCallbackTimerGI;
    TimerDeadlineCacheDisabled: Boolean;
    NextTimerToProcess: PCallbackTimerGI;
    LastObservedTimerTick: Cardinal;
    SavedPixels16: Pointer;
    SavedPixelCount16: Integer;
    SavedPixelCapacity16: Integer;
    SecondaryPixelBuffer: Pointer;
    SecondaryPixelCount: Integer;
    SecondaryPixelCapacity: Integer;
    SavedLines: array of TSavedLineGI;
    SavedLineCount: Integer;
    PendingRedraw: Boolean;
    ContinuousLoop: Boolean;
    Gap9E: array[0..1] of Byte;
    FramesPerSecond: Integer;
    PlayTransitionSounds: Boolean;
    GapA5: array[0..2] of Byte;
    OpenSoundName: WideString;
    CloseSoundName: WideString;
    SoundSection: Integer;
    SoundGroupList: TList;
    TransientControl: TObjectGI;
    TransientData: TObject;
    IsOpen: Boolean;
    GapC1: array[0..2] of Byte;
    SavedBackgroundControl: TObjectGI;
    DeferredCodeBlocks: TList;
    RefreshMouseAfterCode: Boolean;
    GapCD: array[0..2] of Byte;
    // Host travel loops retain the previous frame while servicing events.
    DeferScreenPresentation: Boolean;

    function Run: Integer; virtual;
    procedure ProcessWindowMessage(Message: Cardinal; WParam: Cardinal; LParam: Integer); virtual;
    function RunContinuous: Integer; virtual;
    procedure AdvanceTimerTick; virtual;
    procedure DrawFrame; virtual;
    procedure Present; virtual;
    procedure ProcessNamedControlEvent(
        ControlName: WideString;
        EventKind: Integer;
        Param1: Integer;
        Param2: Integer
    ); virtual;
    procedure OnOpen; virtual;
    procedure OnClose; virtual;
    procedure ProcessCallbackTimers; virtual;
    procedure SelectMusic; virtual;
    procedure ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer); virtual;

    procedure InitializeLayout; virtual;
    procedure UpdateActionCursor(CanTake: Boolean); virtual;
    function GetActionParentLoop: TMessageLoopGI; virtual;
    procedure ExecuteUiCode(Block: TBlockParEC; Key: Cardinal); virtual;
    constructor Create;
    destructor Destroy; override;
    procedure ResetRuntime;
    procedure QueueUpdateRect(Rect: TRect);
    procedure InvalidateViewport;
    function FindMouseViewUpdateControl(Control: TObjectGI): Integer;
    procedure AddMouseViewUpdateControl(Control: TObjectGI);
    procedure RemoveMouseViewUpdateControl(Control: TObjectGI);
    procedure InvalidateMouseViewControls;
    procedure DrawQueuedUpdateRects;
    procedure DrawQueuedControlRects;
    procedure FinishQueuedDraw;
    procedure CommitFrameDraw;
    procedure ErasePreviousFrame;
    procedure PrepareFrameDraw;
    procedure CaptureScreenshot;
    procedure RequestClose(ResultCode: Integer);
    procedure SetHelpCallback(Callback: TObjectHelpEventGI);
    function GetByName(const Name: WideString): TObjectGI;
    function FindControlByPath(const Path: WideString): TObjectGI;
    procedure SetFocusedControl(Control: TObjectGI);
    procedure SetHoveredControl(Control: TObjectGI);
    function ScheduleCallbackTimer(
        DelayMs: Integer;
        RepeatMs: Integer;
        Callback: TCallbackTimerEventGI;
        UserData: PtrInt = 0
    ): PCallbackTimerGI;
    procedure CancelCallbackTimer(Timer: PCallbackTimerGI);
    procedure UpdateCallbackTimer(Timer: PCallbackTimerGI; DelayMs: Integer; RepeatMs: Integer);
    procedure ReinsertCallbackTimer(Timer: PCallbackTimerGI);
    procedure UncacheCallbackTimer(Timer: PCallbackTimerGI);
    procedure RefreshTimerTick;
    procedure SetCursorImage(const ImagePath: WideString; HotSpot: TPoint);
    procedure SetCursorByName(const Name: WideString);
    function IsCursorImageSelected(const RegisteredName: WideString): Boolean;
    function IsCursorActive: Boolean;
    procedure SetCursorActive(Enabled: Boolean);
    procedure CaptureCursorState(State: PCursorStateGI);
    procedure RestoreCursorState(State: PCursorStateGI);
    procedure UpdateCursorPosition;
    function GetCursorPoint: TPoint;
    procedure SetSystemCursorPosition(Point: TPoint);
    function ConsumeTimerTickChange: Boolean;
    function QueryPointOcclusionState(
        Point: TPoint;
        IgnoreControl: TObjectGI;
        StartControl: TObjectGI
    ): Integer;
    procedure FreeSavedPixels16;
    procedure RestoreSavedPixels16;
    procedure FreeSecondaryPixelBuffer;
    procedure ResetSecondaryPixelCount;
    procedure FreeSavedLines;
    procedure AddSavedLine(First: TPoint; Last: TPoint; Pixels: Pointer);
    procedure RestoreSavedLines;
    procedure ResetSavedLineCount;
    procedure ClearTransientControl;
    procedure InvalidateTransientControl;
    procedure InitializeDefaults;
    procedure InitializeFromConfig(
        ConfigRoot: TBlockParEC;
        const ScreenName: WideString;
        UnusedFlag: Boolean
    );
    procedure QueueUiCode(Block: TBlockParEC; RefreshMouse: Boolean);
    procedure RefreshMouseDispatch;
  end;
var
  MessageLoopStack: TList = nil;
  IgnoreWarpMouseMove: Boolean = False;
  LastMousePosition: TPoint;
procedure PushMessageLoop(Loop: TMessageLoopGI);
procedure PopMessageLoop(Loop: TMessageLoopGI);
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  GameNative,
  PopUp,
  BreakMessageGIException,
  EC_Mem,
  MMSystem,
  Windows,
  Messages,
  GI_Cursor,
  GI_Label,
  GI_Main,
  GI_Panel,
  GI_GraphBuf,
  GlobalsV,
  Globals,
  GR_Main,
  GR_GraphBuf,
  SysUtils,
  aMyFunction,
  GR_Sound,
  GR_Music;

procedure PushMessageLoop(Loop: TMessageLoopGI);
begin
  if MessageLoopStack = nil then
    MessageLoopStack := TList.Create;
  MessageLoopStack.Add(Loop);
end;
procedure PopMessageLoop(Loop: TMessageLoopGI);
begin
  if (MessageLoopStack = nil) or (MessageLoopStack.Count < 1) then
    RaiseWideMessage('ML 1');
  if MessageLoopStack[MessageLoopStack.Count - 1] <> Loop then
    RaiseWideMessage('ML 2');
  MessageLoopStack.Delete(MessageLoopStack.Count - 1);

end;
constructor TObjectGI.Create(Owner: TObjectGI);
begin
  inherited Create;
  Active := True;
  HitTestDisabled := False;
  MouseBlocking := False;
  MouseBlockingTest := True;
  ScrollUpdate := False;
  AutoOffsetEnabled := False;
  AutoOffsetScale.X := 0;
  AutoOffsetScale.Y := 0;
  if Owner <> nil then
    Owner.AttachOwnedChild(Self);
  OnKeyDownCode := nil;
  OnMouseEnterCode := nil;
  OnMouseLeaveCode := nil;
  OnRightButtonDownCode := nil;
end;
destructor TObjectGI.Destroy;
begin
  if MessageLoop <> nil then
  begin
    MessageLoop.RemoveMouseViewUpdateControl(Self);
    if MessageLoop.FocusedControl = Self then
      MessageLoop.SetFocusedControl(nil);
    if MessageLoop.HoveredControl = Self then
      MessageLoop.HoveredControl := nil;
  end;
  Clear;
  FreeOwnedChildren;
  if Parent <> nil then
    Parent.UnlinkOwnedChild(Self);
  if Assigned(DestroyNotify) then
    DestroyNotify(Self);
  inherited Destroy;
end;
procedure TObjectGI.FreeOwnedChildren;
begin
  while LastChild <> nil do
    FreeOwnedChild(FirstChild);
end;
procedure TObjectGI.Clear;
begin
  LocalPosition.X := 0;
  LocalPosition.Y := 0;
  ClientSize.X := 0;
  ClientSize.Y := 0;
  OriginPoint.X := 0;
  OriginPoint.Y := 0;
  Depth := 0;
  PositionModeW := False;
  Active := True;
  HitTestDisabled := False;
  ConfigPath := '';
  MouseBlocking := False;
  MouseBlockingTest := True;
  ScrollUpdate := False;
end;
procedure TObjectGI.AttachOwnedChild(Child: TObjectGI);
begin
  if LastChild <> nil then
    LastChild.NextSibling := Child;
  Child.PrevSibling := LastChild;
  Child.NextSibling := nil;
  LastChild := Child;
  if FirstChild = nil then
    FirstChild := Child;
  Child.Parent := Self;
  Child.MessageLoop := MessageLoop;
end;
procedure TObjectGI.InsertOwnedChildBefore(BeforeChild, Child: TObjectGI);
begin
  if BeforeChild <> nil then
  begin
    Child.PrevSibling := BeforeChild.PrevSibling;
    Child.NextSibling := BeforeChild;
    if BeforeChild.PrevSibling <> nil then
      BeforeChild.PrevSibling.NextSibling := Child;
    BeforeChild.PrevSibling := Child;
    if FirstChild = BeforeChild then
      FirstChild := Child;
    Child.Parent := Self;
    Child.MessageLoop := MessageLoop;
  end
  else
    AttachOwnedChild(Child);
end;
procedure TObjectGI.InsertOwnedChildByDepth(Child: TObjectGI; NewDepth: Double);
var
  BeforeChild: TObjectGI;
begin
  Child.Depth := NewDepth;
  BeforeChild := FirstChild;
  while BeforeChild <> nil do
  begin
    if BeforeChild.Depth <= NewDepth then
    begin
      InsertOwnedChildBefore(BeforeChild, Child);
      Break;
    end;
    BeforeChild := BeforeChild.NextSibling;
  end;
  if BeforeChild = nil then
    AttachOwnedChild(Child);
end;
procedure TObjectGI.FreeOwnedChild(Child: TObjectGI);
begin
  UnlinkOwnedChild(Child);
  Child.Free;
end;
procedure TObjectGI.UnlinkOwnedChild(Child: TObjectGI);
begin
  if Child.PrevSibling <> nil then
    Child.PrevSibling.NextSibling := Child.NextSibling;
  if Child.NextSibling <> nil then
    Child.NextSibling.PrevSibling := Child.PrevSibling;
  if LastChild = Child then
    LastChild := Child.PrevSibling;
  if FirstChild = Child then
    FirstChild := Child.NextSibling;
  Child.Parent := nil;
end;
procedure TObjectGI.Reparent(NewParent: TObjectGI);
begin
  Parent.UnlinkOwnedChild(Self);
  NewParent.InsertOwnedChildByDepth(Self, Depth);
end;
procedure TObjectGI.SetMouseViewUpdates(Enabled: Boolean);
begin
  if Enabled = True then
    MessageLoop.AddMouseViewUpdateControl(Self)
  else
    MessageLoop.RemoveMouseViewUpdateControl(Self);
end;
procedure TObjectGI.UpdateAbsolutePosition;
var
  Child: TObjectGI;
begin
  if Parent <> nil then
    AbsolutePosition := Parent.GetChildAbsolutePosition(LocalPosition, PositionModeW)
  else
  begin
    AbsolutePosition.X := LocalPosition.X;
    AbsolutePosition.Y := LocalPosition.Y;
  end;
  Child := FirstChild;
  while Child <> nil do
  begin
    if Child.Active = True then
      Child.UpdateAbsolutePosition;
    Child := Child.NextSibling;
  end;
end;
function TObjectGI.GetChildAbsolutePosition(LocalPosition: TPoint; ModeW: Boolean): TPoint;
begin
  Result.X := AbsolutePosition.X + LocalPosition.X;
  Result.Y := AbsolutePosition.Y + LocalPosition.Y;
end;
procedure TObjectGI.UpdateHitTestBounds;
begin
  HitTestBounds :=
      Classes.Rect(
          AbsolutePosition.X - OriginPoint.X,
          AbsolutePosition.Y - OriginPoint.Y,
          AbsolutePosition.X - OriginPoint.X + ClientSize.X,
          AbsolutePosition.Y - OriginPoint.Y + ClientSize.Y
      );
end;
procedure TObjectGI.UpdateSubtreeHitBounds;
var
  Child: TObjectGI;
begin
  UpdateHitTestBounds;
  Child := FirstChild;
  while Child <> nil do
  begin
    if Child.Active = True then
      Child.UpdateSubtreeHitBounds;
    Child := Child.NextSibling;
  end;
end;
procedure TObjectGI.SetHelpCallbackRecursive(Callback: TObjectHelpEventGI);
var
  Child: TObjectGI;
begin
  if (HelpText <> '') or Assigned(HelpCallback) then
    HelpCallback := Callback;
  Child := FirstChild;
  while Child <> nil do
  begin
    Child.SetHelpCallbackRecursive(Callback);
    Child := Child.NextSibling;
  end;
end;
function TObjectGI.OffsetChildRect(Rect: TRect; ModeW: Boolean): TRect;
begin
  if not ModeW then
  begin
    Result.Left := LocalPosition.X + Rect.Left;
    Result.Top := LocalPosition.Y + Rect.Top;
    Result.Right := LocalPosition.X + Rect.Right;
    Result.Bottom := LocalPosition.Y + Rect.Bottom;
  end
  else
  begin
    Result.Left := LocalPosition.X + Rect.Left - ScrollOffset.X;
    Result.Top := LocalPosition.Y + Rect.Top - ScrollOffset.Y;
    Result.Right := LocalPosition.X + Rect.Right - ScrollOffset.X;
    Result.Bottom := LocalPosition.Y + Rect.Bottom - ScrollOffset.Y;
  end;
end;
procedure TObjectGI.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X = Position.X) and (LocalPosition.Y = Position.Y) then
    Exit;
  if not Active then
    LocalPosition := Position
  else
  begin
    Invalidate;
    LocalPosition := Position;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Invalidate;
  end;
end;
procedure TObjectGI.SetDepth(NewDepth: Double);
begin
  if Depth = NewDepth then
    Exit;
  if Parent = nil then
    Exit;
  if PrevSibling <> nil then
    PrevSibling.NextSibling := NextSibling;
  if NextSibling <> nil then
    NextSibling.PrevSibling := PrevSibling;
  if Parent.LastChild = Self then
    Parent.LastChild := PrevSibling;
  if Parent.FirstChild = Self then
    Parent.FirstChild := NextSibling;
  Parent.InsertOwnedChildByDepth(Self, NewDepth);
  Invalidate;
end;
procedure TObjectGI.SetDepthByName(const Name: WideString);
var
  Value: WideString;
begin
  Value := UiDepthConfig.GetParamOrMarker(Name);
  if Value <> '' then
    SetDepth(ExtractDecimalToSingleW(Value))
  else
    SetDepth(ExtractDecimalToSingleW(Name));
end;
procedure TObjectGI.SetSize(Size: TPoint);
begin
  if (ClientSize.X = Size.X) and (ClientSize.Y = Size.Y) then
    Exit;
  if not Active then
    ClientSize := Size
  else
  begin
    Invalidate;
    ClientSize := Size;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Invalidate;
  end;
end;
procedure TObjectGI.SetOrigin(Origin: TPoint);
begin
  if (OriginPoint.X = Origin.X) and (OriginPoint.Y = Origin.Y) then
    Exit;
  if not Active then
    OriginPoint := Origin
  else
  begin
    Invalidate;
    OriginPoint := Origin;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Invalidate;
  end;
end;
procedure TObjectGI.SetPositionModeW(Enabled: Boolean);
begin
  if PositionModeW = Enabled then
    Exit;
  if not Active then
    PositionModeW := Enabled
  else
  begin
    Invalidate;
    PositionModeW := Enabled;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Invalidate;
  end;
end;
procedure TObjectGI.SetConfigPath(const Path: WideString);
begin
  LoadFromConfigPath(Path);
  ConfigPath := Path;
end;
function TObjectGI.GetLocalBounds: TRect;
begin
  Result.Left := LocalPosition.X - OriginPoint.X;
  Result.Top := LocalPosition.Y - OriginPoint.Y;
  Result.Right := LocalPosition.X - OriginPoint.X + ClientSize.X;
  Result.Bottom := LocalPosition.Y - OriginPoint.Y + ClientSize.Y;
end;
procedure TObjectGI.SetName(const Name: WideString);
begin
  ControlName := Name;
end;
procedure TObjectGI.SetActive(Enabled: Boolean);
begin
  if Active = Enabled then
    Exit;
  if Enabled = True then
  begin
    Active := Enabled;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Invalidate;
    OnActivate;
  end
  else
  begin
    Invalidate;
    Active := Enabled;
    OnDeactivate;
  end;
end;
procedure TObjectGI.SetHitTestDisabled(Disabled: Boolean);
begin
  if HitTestDisabled = Disabled then
    Exit;
  if Disabled = True then
  begin
    HitTestDisabled := Disabled;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Invalidate;
    OnActivate;
  end
  else
  begin
    Invalidate;
    HitTestDisabled := Disabled;
    OnDeactivate;
  end;
end;
function TObjectGI.FindDeepestChildAtPoint(Point: TPoint): TObjectGI;
var
  Child: TObjectGI;
begin
  Child := LastChild;
  while Child <> nil do
  begin
    if Child.ContainsPoint(Point) then
    begin
      Result := Child.FindDeepestChildAtPoint(Point);
      Exit;
    end;
    Child := Child.PrevSibling;
  end;
  Result := Self;
end;
function TObjectGI.IsOccludedAtPoint(Point: TPoint): Boolean;
begin
  if MessageLoop.QueryPointOcclusionState(Point, Self, nil) = 1 then
    Result := True
  else
    Result := False;
end;
procedure TObjectGI.QueueImageLoad(PendingLoads: TList);
begin
end;
procedure TObjectGI.ProcessMouseMove(KeyState: Cardinal; Point: TPoint);
var
  Child: TObjectGI;
begin
  if Assigned(MouseMoveCallback) then
    MouseMoveCallback(Self, KeyState, Point);
  Child := FirstChild;
  while Child <> nil do
  begin
    if (Child.Active = True) and not Child.ContainsPoint(Point) and (Child.MouseInside = True) then
      Child.OnMouseLeave;
    Child := Child.NextSibling;
  end;
  Child := FirstChild;
  while Child <> nil do
  begin
    if (Child.Active = True) and Child.ContainsPoint(Point) then
    begin
      if Child.MouseInside = False then
        Child.OnMouseEnter;
      Child.ProcessMouseMove(KeyState, Point);
      DispatchNamedEvent(3, Point.X, Point.Y);
    end;
    Child := Child.NextSibling;
  end;
end;
procedure TObjectGI.OnMouseEnter;
begin
  if Assigned(MouseEnterCallback) then
    MouseEnterCallback(Self);
  if OnMouseEnterCode <> nil then
    MessageLoop.QueueUiCode(OnMouseEnterCode, False);
  MouseInside := True;
  if HelpText <> '' then
    if MessageLoop.HelpLabel <> nil then
      (MessageLoop.HelpLabel as TLabelGI).SetText(HelpText);
end;
procedure TObjectGI.OnMouseLeave;
var
  Child: TObjectGI;
begin
  if Assigned(MouseLeaveCallback) then
    MouseLeaveCallback(Self);
  if OnMouseLeaveCode <> nil then
    MessageLoop.QueueUiCode(OnMouseLeaveCode, False);
  MouseInside := False;
  Child := FirstChild;
  while Child <> nil do
  begin
    if (Child.Active = True) and (Child.MouseInside = True) then
      Child.OnMouseLeave;
    Child := Child.NextSibling;
  end;
  if HelpText <> '' then
    if MessageLoop.HelpLabel <> nil then
      (MessageLoop.HelpLabel as TLabelGI).SetText('');
end;
procedure TObjectGI.OnActivate;
var
  Child: TObjectGI;
begin
  if Assigned(ActivateCallback) then
    ActivateCallback(Self);
  Child := FirstChild;
  while Child <> nil do
  begin
    if Child.Active = True then
      Child.OnActivate;
    Child := Child.NextSibling;
  end;
end;
procedure TObjectGI.NativeHook48;
var
  Child: TObjectGI;
begin
  Child := FirstChild;
  while Child <> nil do
  begin
    if Child.Active = True then
      Child.NativeHook48;
    Child := Child.NextSibling;
  end;
end;
procedure TObjectGI.OnDeactivate;
var
  Child: TObjectGI;
begin
  if Assigned(DeactivateCallback) then
    DeactivateCallback(Self);
  Child := FirstChild;
  while Child <> nil do
  begin
    Child.OnDeactivate;
    Child := Child.NextSibling;
  end;
end;
procedure TObjectGI.NativeHook50;
var
  Child: TObjectGI;
begin
  Child := FirstChild;
  while Child <> nil do
  begin
    if Child.Active = True then
      Child.NativeHook50;
    Child := Child.NextSibling;
  end;
end;
procedure TObjectGI.ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint);
var
  Child: TObjectGI;
begin
  if Assigned(LeftButtonDownCallback) then
    LeftButtonDownCallback(Self, KeyState, Point);
  Child := FirstChild;
  while Child <> nil do
  begin
    if (Child.Active = True) and Child.ContainsPoint(Point) then
      Child.ProcessLeftButtonDown(KeyState, Point);
    Child := Child.NextSibling;
  end;
end;
procedure TObjectGI.ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint);
var
  Child: TObjectGI;
begin
  if Assigned(LeftButtonUpCallback) then
    LeftButtonUpCallback(Self, KeyState, Point);
  Child := FirstChild;
  while Child <> nil do
  begin
    if (Child.Active = True) and Child.ContainsPoint(Point) then
      Child.ProcessLeftButtonUp(KeyState, Point);
    Child := Child.NextSibling;
  end;
end;
procedure TObjectGI.ProcessRightButtonDown(KeyState: Cardinal; Point: TPoint);
var
  Child: TObjectGI;
begin
  if Assigned(RightButtonDownCallback) then
    RightButtonDownCallback(Self, KeyState, Point);
  Child := FirstChild;
  while Child <> nil do
  begin
    if (Child.Active = True) and Child.ContainsPoint(Point) then
      Child.ProcessRightButtonDown(KeyState, Point);
    Child := Child.NextSibling;
  end;
  if OnRightButtonDownCode <> nil then
    MessageLoop.QueueUiCode(OnRightButtonDownCode, False);
end;
procedure TObjectGI.ProcessRightButtonUp(KeyState: Cardinal; Point: TPoint);
var
  Child: TObjectGI;
begin
  if Assigned(RightButtonUpCallback) then
    RightButtonUpCallback(Self, KeyState, Point);
  Child := FirstChild;
  while Child <> nil do
  begin
    if (Child.Active = True) and Child.ContainsPoint(Point) then
      Child.ProcessRightButtonUp(KeyState, Point);
    Child := Child.NextSibling;
  end;
end;
procedure TObjectGI.ProcessLeftButtonDoubleClick(KeyState: Cardinal; Point: TPoint);
var
  Child: TObjectGI;
begin
  if Assigned(LeftButtonDoubleClickCallback) then
    LeftButtonDoubleClickCallback(Self, KeyState, Point);
  Child := FirstChild;
  while Child <> nil do
  begin
    if (Child.Active = True) and Child.ContainsPoint(Point) then
      Child.ProcessLeftButtonDoubleClick(KeyState, Point);
    Child := Child.NextSibling;
  end;
end;
procedure TObjectGI.ProcessRightButtonDoubleClick(KeyState: Cardinal; Point: TPoint);
var
  Child: TObjectGI;
begin
  if Assigned(RightButtonDoubleClickCallback) then
    RightButtonDoubleClickCallback(Self, KeyState, Point);
  Child := FirstChild;
  while Child <> nil do
  begin
    if (Child.Active = True) and Child.ContainsPoint(Point) then
      Child.ProcessRightButtonDoubleClick(KeyState, Point);
    Child := Child.NextSibling;
  end;
end;
procedure TObjectGI.BroadcastKeyDown(Key: Cardinal);
var
  Child: TObjectGI;
begin
  if OnKeyDownCode <> nil then
    MessageLoop.ExecuteUiCode(OnKeyDownCode, Key);
  if Assigned(KeyDownCallback) then
    KeyDownCallback(Self, Key);
  Child := FirstChild;
  while Child <> nil do
  begin
    Child.BroadcastKeyDown(Key);
    Child := Child.NextSibling;
  end;
end;
procedure TObjectGI.BroadcastKeyUp(Key: Cardinal);
var
  Child: TObjectGI;
begin
  if Assigned(KeyUpCallback) then
    KeyUpCallback(Self, Key);
  Child := FirstChild;
  while Child <> nil do
  begin
    Child.BroadcastKeyUp(Key);
    Child := Child.NextSibling;
  end;
end;
procedure TObjectGI.OnHoverGained;
begin
end;
procedure TObjectGI.OnHoverLost;
begin
end;
procedure TObjectGI.OnFocusGained;
begin
end;
procedure TObjectGI.OnFocusLost;
begin
end;
procedure TObjectGI.ProcessKeyDown(Key: Integer);
begin
end;
procedure TObjectGI.ProcessCharacter(Character: WideChar);
begin
end;
procedure TObjectGI.OnCaretBlink;
begin
end;
function TObjectGI.ContainsPoint(Point: TPoint): Boolean;
begin
  if (Active = False) or (HitTestDisabled = True) then
  begin
    Result := False;
    Exit;
  end;
  if (Point.X >= HitTestBounds.Left)
      and (Point.Y >= HitTestBounds.Top)
      and (Point.X < HitTestBounds.Right)
      and (Point.Y < HitTestBounds.Bottom) then
    Result := True
  else
    Result := False;
end;
function TObjectGI.HitTestCursor: Boolean;
begin
  Result := ContainsPoint(MessageLoop.GetCursorPoint);
end;
function TObjectGI.FindByNameRecursive(const Name: WideString): TObjectGI;
var
  Child, Found: TObjectGI;
begin
  if ControlName = Name then
  begin
    Result := Self;
    Exit;
  end;
  Child := FirstChild;
  while Child <> nil do
  begin
    Found := Child.FindByNameRecursive(Name);
    if Found <> nil then
    begin
      Result := Found;
      Exit;
    end;
    Child := Child.NextSibling;
  end;
  Result := nil;
end;
function TObjectGI.ToLocalPoint(Point: TPoint): TPoint;
begin
  Result.X := Point.X - AbsolutePosition.X;
  Result.Y := Point.Y - AbsolutePosition.Y;
end;
function TObjectGI.ToAbsolutePoint(Point: TPoint): TPoint;
begin
  Result.X := Point.X + AbsolutePosition.X;
  Result.Y := Point.Y + AbsolutePosition.Y;
end;
procedure TObjectGI.DispatchNamedEvent(EventKind, Param1, Param2: Integer);
begin
  if Length(ControlName) > 0 then
    MessageLoop.ProcessNamedControlEvent(ControlName, EventKind, Param1, Param2);
end;
procedure TObjectGI.InvalidateRect(Rect: TRect);
var
  Intersection, First, Second: TRect;
begin
  if Active <> True then
    Exit;
  if Parent = nil then
    MessageLoop.QueueUpdateRect(Rect)
  else
  begin
    First := Parent.OffsetChildRect(Rect, PositionModeW);
    Second := Parent.OffsetChildRect(GetLocalBounds, PositionModeW);
    if IntersectRects(Intersection, First, Second) then
      Parent.InvalidateRect(Intersection);
  end;
end;
procedure TObjectGI.Invalidate;
begin
  if MessageLoop.UpdateRectsEnabled and (Parent <> nil) and (Active = True) then
    InvalidateRect(GetLocalBounds);
end;
procedure TObjectGI.InvalidateChildren(IncludePanels: Boolean);
var
  Child: TObjectGI;
begin
  Child := FirstChild;
  while Child <> nil do
  begin
    if Child.Active then
    begin
      if not IncludePanels and (Child is TPanelGI) then
        Child.InvalidateChildren(IncludePanels)
      else
        Child.Invalidate;
    end;
    Child := Child.NextSibling;
  end;
end;
function TObjectGI.InvalidateScrollOverlap(
    Rect: TRect;
    Delta: TPoint;
    StartControl: TObjectGI
): TObjectGI;
var
  Child: TObjectGI;
begin
  if Self = StartControl then
    StartControl := nil;
  if (Self is TPanelGI) and not ScrollUpdate then
  begin
    Child := FirstChild;
    while Child <> nil do
    begin
      if Child.Active then
        StartControl := Child.InvalidateScrollOverlap(Rect, Delta, StartControl);
      Child := Child.NextSibling;
    end;
  end
  else if (StartControl = nil) and (not PositionModeW or ScrollUpdate) then
  begin
    SetPosition(Classes.Point(LocalPosition.X + Delta.X, LocalPosition.Y + Delta.Y));
    SetPosition(Classes.Point(LocalPosition.X - Delta.X, LocalPosition.Y - Delta.Y));
  end;
  Result := StartControl;
end;
procedure TObjectGI.Draw(ClipRect: TRect);
var
  Child: TObjectGI;
  Intersection: TRect;
begin
  if MessageLoop.PendingRedraw then
    Exit;
  Child := FirstChild;
  while Child <> nil do
  begin
    if Child.Active and IntersectRects(Intersection, ClipRect, Child.HitTestBounds) then
      Child.Draw(Intersection);
    Child := Child.NextSibling;
  end;
end;
procedure TObjectGI.DrawUpdateRects(ClipRect: TRect);
var
  RectNode: TRectGR;
  Child: TObjectGI;
  Stage: Integer;
  DrawRect, Intersection: TRect;
begin
  Stage := 0;
  Child := nil;
  try
    if IntersectRects(Intersection, ClipRect, HitTestBounds) then
    begin
      Stage := 1;
      Child := FirstChild;
      while Child <> nil do
      begin
        Stage := 2;
        if Child.Active then
          Child.DrawUpdateRects(Intersection);
        Child := Child.NextSibling;
      end;
      Stage := 3;
      if SkipOwnQueuedDraw = 0 then
      begin
        Stage := 4;
        RectNode := MessageLoop.UpdateRects.FirstRect;
        while RectNode <> nil do
        begin
          Stage := 5;
          if IntersectRects(DrawRect, RectNode.Bounds, Intersection) then
            Draw(DrawRect);
          RectNode := RectNode.Next;
        end;
      end;
    end;
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
      LogExceptionBackTrace;
      if Child <> nil then
      begin
        AppendLogLineThreadSafe('Error in TObjectGI.DrawEx, label = ' + IntToStr(Stage));
        AppendLogLineThreadSafe('obj - ' + Child.ControlName + ' ' + Child.ClassName);
      end
      else
        AppendLogLineThreadSafe('TObjectGI.DrawEx, label = ' + IntToStr(Stage));
      raise;
    end;
  end;
end;
procedure TObjectGI.CommitFrameDraw;
var
  Child: TObjectGI;
begin
  Child := FirstChild;
  while Child <> nil do
  begin
    if Child.Active then
      Child.CommitFrameDraw;
    Child := Child.NextSibling;
  end;
end;
procedure TObjectGI.ErasePreviousFrame;
var
  Child: TObjectGI;
begin
  Child := FirstChild;
  while Child <> nil do
  begin
    if Child.Active then
      Child.ErasePreviousFrame;
    Child := Child.NextSibling;
  end;
end;
procedure TObjectGI.NativeHookB0;
var
  Child: TObjectGI;
begin
  Child := FirstChild;
  while Child <> nil do
  begin
    if Child.Active then
      Child.NativeHookB0;
    Child := Child.NextSibling;
  end;
end;
procedure TObjectGI.PrepareFrameDraw;
var
  Child: TObjectGI;
begin
  Child := FirstChild;
  while Child <> nil do
  begin
    if Child.Active then
      Child.PrepareFrameDraw;
    Child := Child.NextSibling;
  end;
end;
procedure TObjectGI.PrepareRegionDraw(ClipRect: TRect);
begin
end;
procedure TObjectGI.NativeHookBC(Rect: TRect);
begin
end;
procedure TObjectGI.LoadFromConfigPath(const Path: WideString);
var
  Block: TBlockParEC;
  Text: WideString;
  Count: Integer;
begin
  Block := UiStyleConfig.GetBlockByPath(Path);
  if Block.CountParams('Pos') > 0 then
  begin
    Text := Block.GetParam('Pos');
    Count := CountDelimitedPartsW(Text, ',');
    if Count >= 2 then
    begin
      LocalPosition.X := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
      LocalPosition.Y := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
    end;
    if Count >= 3 then
      SetDepthByName(ExtractDelimitedPartW(Text, 2, ','));
    if Count >= 4 then
      if TrimWideString(ExtractDelimitedPartW(Text, 3, ',')) = 'w' then
        PositionModeW := True;
  end;
  if Block.CountParams('PosZ') > 0 then
    SetDepthByName(Block.GetParam('PosZ'));
  if Block.CountParams('Size') > 0 then
  begin
    Text := Block.GetParam('Size');
    ClientSize.X := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
    ClientSize.Y := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
  end;
  if Block.CountParams('Sme') > 0 then
  begin
    Text := Block.GetParam('Sme');
    OriginPoint.X := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
    OriginPoint.Y := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
  end;
  if Block.CountParams('Name') > 0 then
    ControlName := TrimWideString(Block.GetParam('Name'));
  if Block.CountParams('Help') > 0 then
    HelpText := LookupLocalizedTextByKey(TrimWideString(Block.GetParam('Help')));
  if Block.CountParams('Active') > 0 then
    if TrimWideString(Block.GetParam('Active')) = 'False' then
      Active := False;
  if Block.CountParams('MouseBlocking') > 0 then
    MouseBlocking := ParseEnabledNameGI(TrimWideString(Block.GetParam('MouseBlocking')));
  if Block.CountParams('MouseBlockingTest') > 0 then
    MouseBlockingTest := ParseEnabledNameGI(TrimWideString(Block.GetParam('MouseBlockingTest')));
  if Block.CountParams('MVUpdate') > 0 then
    SetMouseViewUpdates(ParseEnabledNameGI(TrimWideString(Block.GetParam('MVUpdate'))));
end;
procedure TObjectGI.LoadFromBlock(Block: TBlockParEC);
var
  Count: Integer;
  Text: WideString;
  procedure LoadConfiguredChildren(
      Block: TBlockParEC
  ); // @addr $4BD50C @ida "void __usercall $name(TBlockParEC *Block@<eax>, void *ParentFrame@<^0>);" @stackpop 0 @calls "0x4BD6CA 0x4BD5F8" @note "Nested helper of TObjectGI.LoadFromBlock; creates recognized controls and descends through other blocks."
  var
    Index, Count: Integer;
    Child: TObjectGI;
  begin
    Count := Block.GetBlockCount;
    for Index := 0 to Count - 1 do
    begin
      Child := CreateControlByName(Block.GetBlockNameByIndex(Index), Self);
      if Child <> nil then
        Child.LoadFromBlock(Block.GetBlockByIndex(Index))
      else if (Block.GetBlockNameByIndex(Index) <> 'OnPressCode')
          and (Block.GetBlockNameByIndex(Index) <> 'OnMouseEnterCode')
          and (Block.GetBlockNameByIndex(Index) <> 'OnMouseLeaveCode') then
        LoadConfiguredChildren(Block.GetBlockByIndex(Index));
    end;
  end;
begin
  Clear;
  LoadConfiguredChildren(Block);
  SourceBlock := Block;
  Depth := -1;
  SetDepth(0);
  if Block.CountParams('Style') > 0 then
    SetConfigPath(Block.GetParam('Style'));
  if Block.CountParams('Pos') > 0 then
  begin
    Text := Block.GetParam('Pos');
    Count := CountDelimitedPartsW(Text, ',');
    if Count >= 2 then
    begin
      LocalPosition.X := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
      LocalPosition.Y := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
    end;
    if Count >= 3 then
      SetDepthByName(ExtractDelimitedPartW(Text, 2, ','));
    if Count >= 4 then
      if TrimWideString(ExtractDelimitedPartW(Text, 3, ',')) = 'w' then
        PositionModeW := True;
  end;
  if Block.CountParams('PosZ') > 0 then
    SetDepthByName(Block.GetParam('PosZ'));
  if Block.CountParams('Size') > 0 then
    SetSize(GetPointGI(Block.GetParam('Size')));
  if Block.CountParams('Sme') > 0 then
    SetOrigin(GetPointGI(Block.GetParam('Sme')));
  ControlName := '';
  if Block.CountParams('Name') > 0 then
    ControlName := TrimWideString(Block.GetParam('Name'));
  if Block.CountParams('Help') > 0 then
    HelpText := LookupLocalizedTextByKey(TrimWideString(Block.GetParam('Help')));
  Active := True;
  if Block.CountParams('Active') > 0 then
    if TrimWideString(Block.GetParam('Active')) = 'False' then
      Active := False;
  if Block.CountParams('MouseBlocking') > 0 then
    MouseBlocking := ParseEnabledNameGI(TrimWideString(Block.GetParam('MouseBlocking')));
  if Block.CountParams('MouseBlockingTest') > 0 then
    MouseBlockingTest := ParseEnabledNameGI(TrimWideString(Block.GetParam('MouseBlockingTest')));
  if Block.CountParams('ScrollUpdate') > 0 then
    ScrollUpdate := ParseEnabledNameGI(TrimWideString(Block.GetParam('ScrollUpdate')));
  if Block.CountParams('MVUpdate') > 0 then
    SetMouseViewUpdates(ParseEnabledNameGI(TrimWideString(Block.GetParam('MVUpdate'))));
  if Block.CountParams('PosAutoCorrection') > 0 then
    AutoOffsetEnabled := ParseEnabledNameGI(TrimWideString(Block.GetParam('PosAutoCorrection')));
  if Block.CountParams('PosAutoCorrectionXCoef') > 0 then
    AutoOffsetScale.X :=
        ExtractDecimalToSingleW(TrimWideString(Block.GetParam('PosAutoCorrectionXCoef')));
  if Block.CountParams('PosAutoCorrectionYCoef') > 0 then
    AutoOffsetScale.Y :=
        ExtractDecimalToSingleW(TrimWideString(Block.GetParam('PosAutoCorrectionYCoef')));
  if Block.CountBlocks('OnKey') > 0 then
    OnKeyDownCode := Block.GetBlock('OnKey');
  if Block.CountBlocks('OnMouseEnterCode') > 0 then
    OnMouseEnterCode := Block.GetBlock('OnMouseEnterCode');
  if Block.CountBlocks('OnMouseLeaveCode') > 0 then
    OnMouseLeaveCode := Block.GetBlock('OnMouseLeaveCode');
  if Block.CountBlocks('OnMouseRightClick') > 0 then
    OnRightButtonDownCode := Block.GetBlock('OnMouseRightClick');
end;
procedure TObjectGI.ReloadFromBlock;
begin
  FreeOwnedChildren;
  LoadFromBlock(SourceBlock);
end;
procedure TObjectGI.UpdateAutoGeometry;
var
  Child: TObjectGI;
begin
  if AutoOffsetEnabled then
  begin
    LocalPosition.X := Round(ExtraScreenWidth * AutoOffsetScale.X + LocalPosition.X);
    LocalPosition.Y := Round(ExtraScreenHeight * AutoOffsetScale.Y + LocalPosition.Y);
  end;
  Child := FirstChild;
  while Child <> nil do
  begin
    Child.UpdateAutoGeometry;
    Child := Child.NextSibling;
  end;
end;
constructor TFormSoundGroup.Create;
begin
  inherited Create;
  Sounds := TStringsEC.Create;
end;
destructor TFormSoundGroup.Destroy;
begin
  Clear;
  Sounds.Free;
  Sounds := nil;
  inherited Destroy;
end;
procedure TFormSoundGroup.Clear;
begin
  Sounds.Clear;
  Section := 0;
end;
procedure TFormSoundGroup.LoadFromBlock(Block: TBlockParEC);
var
  Text: WideString;
  Index, Count: Integer;
begin
  Clear;
  TotalWeight := 0;
  Text := Block.GetParam('NextTime');
  MinDelayMs := StrToInt(ExtractDelimitedPartW(Text, 0, ',-'));
  MaxDelayMs := StrToInt(ExtractDelimitedPartW(Text, 1, ',-'));
  if Block.CountParams('Section') > 0 then
    Section := StrToInt(Block.GetParam('Section'));
  Count := Block.GetParamCount;
  for Index := 0 to Count - 1 do
  begin
    Text := Block.GetParamName(Index);
    if IsIntegerTextW(Text) then
    begin
      Sounds.Add(Block.GetParamValue(Index));
      Sounds.SetDataAt(Sounds.GetCount - 1, Pointer(ExtractDigitsToIntW(Text)));
      TotalWeight := TotalWeight + ExtractDigitsToIntW(Text);
    end;
  end;
end;
procedure TFormSoundGroup.ScheduleNextPlayback;
begin
  NextPlayTick := Cardinal(RandomIntRange(MinDelayMs, MaxDelayMs)) + timeGetTime;
end;
procedure TFormSoundGroup.PlayIfDue;
var
  Weight: Integer;
begin
  if timeGetTime > NextPlayTick then
  begin
    ScheduleNextPlayback;
    Weight := RandomIntRange(0, TotalWeight - 1);
    Sounds.First;
    while not Sounds.IsAtEnd do
    begin
      Weight := Weight - Integer(Sounds.GetCurrentData);
      if Weight < 0 then
        Break;
      Sounds.Next;
    end;
    SoundManager.PlaySound(Sounds.GetCurrentText);
  end;
end;
constructor TMessageLoopGI.Create;
begin
  inherited Create;
  UpdateRects := TArrayRectGR.Create;
  MouseViewUpdateControls := TList.Create;
  UpdateRectsEnabled := True;
  SoundGroupList := TList.Create;
  PlayTransitionSounds := True;
  SavedBackgroundControl := nil;
  IsOpen := False;
  DeferredCodeBlocks := TList.Create;
  RefreshMouseAfterCode := False;
end;
destructor TMessageLoopGI.Destroy;
begin
  ResetRuntime;
  UpdateRects.Free;
  MouseViewUpdateControls.Free;
  SoundGroupList.Free;
  SoundGroupList := nil;
  DeferredCodeBlocks.Free;
  DeferredCodeBlocks := nil;
  inherited Destroy;
end;
procedure TMessageLoopGI.ResetRuntime;
var
  Index: Integer;
  Item: TObject;
begin
  FreeSecondaryPixelBuffer;
  FreeSavedLines;
  if SoundGroupList <> nil then
  begin
    for Index := 0 to SoundGroupList.Count - 1 do
    begin
      Item := SoundGroupList[Index];
      Item.Free;
    end;
    SoundGroupList.Clear;
  end;
  if RootUiObject <> nil then
  begin
    RootUiObject.Free;
    RootUiObject := nil;
  end;
  CursorControl := nil;
  FocusedControl := nil;
  HoveredControl := nil;
  while FirstTimer <> nil do
    CancelCallbackTimer(LastTimer);
end;
procedure TMessageLoopGI.QueueUpdateRect(Rect: TRect);
var
  Intersection: TRect;
begin
  if UpdateRectsEnabled then
    if IntersectRects(Intersection, Rect, GameScreenRect) then
      UpdateRects.AddRect(Intersection);
end;
procedure TMessageLoopGI.InvalidateViewport;
begin
  QueueUpdateRect(Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight));
end;
function TMessageLoopGI.FindMouseViewUpdateControl(Control: TObjectGI): Integer;
var
  Index, Count: Integer;
begin
  Count := MouseViewUpdateControls.Count;
  for Index := 0 to Count - 1 do
    if MouseViewUpdateControls[Index] = Control then
    begin
      Result := Index;
      Exit;
    end;
  Result := -1;
end;
procedure TMessageLoopGI.AddMouseViewUpdateControl(Control: TObjectGI);
begin
  if FindMouseViewUpdateControl(Control) < 0 then
    MouseViewUpdateControls.Add(Control);
end;
procedure TMessageLoopGI.RemoveMouseViewUpdateControl(Control: TObjectGI);
var
  Index: Integer;
begin
  Index := FindMouseViewUpdateControl(Control);
  if Index >= 0 then
    MouseViewUpdateControls.Delete(Index);
end;
procedure TMessageLoopGI.InvalidateMouseViewControls;
var
  Count, Index: Integer;
  Control: TObjectGI;
begin
  Count := MouseViewUpdateControls.Count;
  for Index := 0 to Count - 1 do
  begin
    Control := MouseViewUpdateControls[Index];
    Control.Invalidate;
  end;
end;
procedure TMessageLoopGI.DrawQueuedUpdateRects;
var
  RectNode: TRectGR;
begin
  if RegionDrawPending and (RegionDrawControl <> nil) then
    RegionDrawControl.PrepareRegionDraw(RegionDrawControl.HitTestBounds);
  PendingRedraw := False;
  RectNode := UpdateRects.FirstRect;
  while RectNode <> nil do
  begin
    RootUiObject.Draw(RectNode.Bounds);
    RectNode := RectNode.Next;
  end;
end;
procedure TMessageLoopGI.DrawQueuedControlRects;
begin
  if UpdateRects.FirstRect <> nil then
  begin
    PendingRedraw := True;
    RootUiObject.DrawUpdateRects(Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight));
  end;
end;
procedure TMessageLoopGI.FinishQueuedDraw;
begin
  RegionDrawPending := False;
end;
procedure TMessageLoopGI.CommitFrameDraw;
begin
  RootUiObject.CommitFrameDraw;
end;
procedure TMessageLoopGI.ErasePreviousFrame;
begin
  RootUiObject.ErasePreviousFrame;
end;
procedure TMessageLoopGI.PrepareFrameDraw;
begin
  RootUiObject.PrepareFrameDraw;
end;
function TMessageLoopGI.Run: Integer;
var
  LastCaretTick, Tick: Cardinal;
  Point: TPoint;
  Index: Integer;
  RecordingTime: Cardinal;
  Stage: Integer;
  Background: TGraphBufGI;

begin
  Stage := 0;
  try

    PushMessageLoop(Self);
    ExitCode := 0;
    ContinuousLoop := False;
    DeferScreenPresentation := False;
    Stage := 1;
    FreeSecondaryPixelBuffer;
    FreeSavedLines;
    FreeSavedPixels16;
    Stage := 2;
    SetCursorByName('Main');
    Stage := 3;
    GetCursorPos(Point);
    if Direct3DPresentParameters.Windowed then
      ScreenToClient(MainWindowHandle, Point);
    CursorControl.SetPosition(Point);
    if CustomCursorEnabled then
      SetCursorActive(True);
    TimerTick := timeGetTime;
    Stage := 4;

    OnOpen;

    Stage := 5;
    RootUiObject.UpdateAbsolutePosition;
    RootUiObject.UpdateSubtreeHitBounds;
    QueueUpdateRect(ViewportRect);
    LastCaretTick := 0;
    CaretBlinkOn := False;
    Stage := 6;
    RootUiObject.OnActivate;
    if (ViewportRect.Right - ViewportRect.Left < GameScreenWidth)
        or (ViewportRect.Bottom - ViewportRect.Top < GameScreenHeight) then
    begin
      Stage := 7;
      if SavedBackgroundControl = nil then
        SavedBackgroundControl := TGraphBufGI.Create(BackgroundPanel, HardwareRenderingEnabled);
      Stage := 8;
      Background := SavedBackgroundControl as TGraphBufGI;
      Background.SetDepth(1E30);
      Background.SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
      Background.AllocateBuffer(GameScreenWidth, GameScreenHeight, False);
      Background.CopyScreenRectToBuffer(
          Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight),
          Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight)
      );
    end;
    Stage := 9;
    for Index := 0 to SoundGroupList.Count - 1 do
      TFormSoundGroup(SoundGroupList[Index]).ScheduleNextPlayback;
    if PlayTransitionSounds and (OpenSoundName <> '') then
      SoundManager.PlaySound(OpenSoundName);
    Stage := 10;
    while (GR_WinMessage(ProcessWindowMessage) <> 0) and (ExitCode = 0) do
    begin
      Stage := 11;
      Tick := timeGetTime;
      if Tick - LastCaretTick > 200 then
      begin
        Stage := 12;
        LastCaretTick := Tick;
        if CaretBlinkOn = True then
          CaretBlinkOn := False
        else
          CaretBlinkOn := True;
        if FocusedControl <> nil then
          FocusedControl.OnCaretBlink;
      end;
      if not MemorySnapshotActive then
      begin
        if not DeferScreenPresentation then
        begin
          Stage := 13;
          if OffscreenTexture <> nil then
          begin
            Stage := 14;
            DrawOffscreenTexture;
          end
          else
          begin
            Stage := 15;
            if PopupController = nil then
              DrawQueuedUpdateRects
            else
            begin
              RootUiObject.AttachOwnedChild(PopupController);
              DrawQueuedUpdateRects;
              RootUiObject.UnlinkOwnedChild(PopupController);
            end;
          end;
          if not BeginFramePresentation then
          begin
            RequestedScreenId := screenNone;
            PostLoadScreenId := FormToId(Self);
            Break;
          end;
          Stage := 16;
          FinishQueuedDraw;
          Stage := 17;
          EndFramePresentation;

          if RecordingFrames then
          begin
            Stage := 18;
            RecordingTime := timeGetTime;
            CaptureRecordingFrame;
            RecordingTime := timeGetTime - RecordingTime;
            Inc(TimerTick, RecordingTime);
            // CHANGE: PERFORMANCE - Recording shifts all deadlines without reordering.
            FillChar(TimerDeadlineHeads, SizeOf(TimerDeadlineHeads), 0);
            NextTimerToProcess := FirstTimer;
            while NextTimerToProcess <> nil do
            begin
              // A bulk shift can wrap the queue out of numeric order. Retain
              // the original list search until the queue becomes empty again.
              if Cardinal(NextTimerToProcess.DueTick + RecordingTime)
                  < NextTimerToProcess.DueTick then
                TimerDeadlineCacheDisabled := True;
              Inc(NextTimerToProcess.DueTick, RecordingTime);
              NextTimerToProcess.CachedDueTick := NextTimerToProcess.DueTick;
              NextTimerToProcess := NextTimerToProcess.Next;
            end;
          end;
        end;
        Stage := 19;
        if MusicEnabled and not MusicManager.HasSelectedMusic then
        begin
          Stage := 20;
          MusicManager.HasSelectedMusic;
          SelectMusic;
        end;
        Stage := 21;
        ProcessCallbackTimers;
        if PopupController <> nil then
          PopupController.AdvancePopups(TimerTick);
        Stage := 22;
        for Index := 0 to SoundGroupList.Count - 1 do
          if (TFormSoundGroup(SoundGroupList[Index]).Section = 0)
              or (TFormSoundGroup(SoundGroupList[Index]).Section = SoundSection) then
            TFormSoundGroup(SoundGroupList[Index]).PlayIfDue;
      end;
    end;
    Stage := 23;
    try
      RootUiObject.OnMouseLeave;
      RefreshMouseAfterCode := False;
      for Index := 0 to DeferredCodeBlocks.Count - 1 do
        ExecuteUiCode(TBlockParEC(DeferredCodeBlocks[Index]), 0);
      DeferredCodeBlocks.Clear;
    except
      on E: EBreakMessageGI do
        ;
    end;
    RootUiObject.OnDeactivate;
    if CustomCursorEnabled then
      SetCursorActive(False);
    Stage := 24;
    if PlayTransitionSounds and (CloseSoundName <> '') then
      SoundManager.PlaySound(CloseSoundName);
    Stage := 25;
    ClearTransientControl;
    Stage := 26;

    OnClose;

    DeferScreenPresentation := False;
    Stage := 27;
    FreeSavedPixels16;
    FreeSecondaryPixelBuffer;
    FreeSavedLines;
    Result := ExitCode;
    Stage := 28;
    PopMessageLoop(Self);
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
      LogExceptionBackTrace;
      raise Exception.Create(
          'Error in procedure TMessageLoopGI.Run, '
              + RegisteredLoopName
              + ', label = '
              + IntToStr(Stage));
    end;
  end;
end;
function TMessageLoopGI.RunContinuous: Integer;
var
  Point: TPoint;

  NowTick, LastUpdateTick, ElapsedTicks, LastFpsTick: Cardinal;
  LastPresentCount, BeforeDrawCount, PresentCount: QWord;

  RecordingTime: Cardinal;
  Index, Stage: Integer;
begin
  Stage := 0;
  try

    PushMessageLoop(Self);
    ExitCode := 0;
    ContinuousLoop := True;
    Stage := 1;
    FreeSecondaryPixelBuffer;
    Stage := 2;
    FreeSavedPixels16;
    Stage := 3;
    FreeSavedLines;
    Stage := 4;
    SetCursorByName('Main');
    GetCursorPos(Point);
    if Direct3DPresentParameters.Windowed then
      ScreenToClient(MainWindowHandle, Point);
    Stage := 5;
    CursorControl.SetPosition(Point);
    if CustomCursorEnabled then
      SetCursorActive(True);
    TimerTick := timeGetTime;
    Stage := 6;

    OnOpen;

    Stage := 7;
    RootUiObject.UpdateAbsolutePosition;
    Stage := 8;
    RootUiObject.UpdateSubtreeHitBounds;
    Stage := 9;
    QueueUpdateRect(ViewportRect);
    Stage := 10;
    CaretBlinkOn := False;
    RootUiObject.OnActivate;
    Stage := 11;
    LastUpdateTick := timeGetTime;
    if ExitCode = 0 then
    begin
      DrawFrame;

    end;
    LastFpsTick := timeGetTime;

    LastPresentCount := sr_present_count;
    FramesPerSecond := 0;

    Stage := 12;
    for Index := 0 to SoundGroupList.Count - 1 do
      TFormSoundGroup(SoundGroupList[Index]).ScheduleNextPlayback;
    if PlayTransitionSounds and (OpenSoundName <> '') then
      SoundManager.PlaySound(OpenSoundName);
    while (GR_WinMessage(ProcessWindowMessage) <> 0) and (ExitCode = 0) do
    begin
      Stage := 13;
      if not MemorySnapshotActive then
      begin
        Stage := 14;

        // Include event processing and presentation waits in elapsed time.
        // Keep native one-millisecond simulation ticks, applying them before
        // rendering so the submitted image contains the latest film state.
        NowTick := timeGetTime;
        ElapsedTicks := NowTick - LastUpdateTick;
        LastUpdateTick := NowTick;
        if ElapsedTicks > 200 then
          ElapsedTicks := 200;
        for Index := 1 to ElapsedTicks do
        begin
          Stage := 23;
          AdvanceTimerTick;
          if PopupController <> nil then
            PopupController.AdvancePopups(TimerTick);
          if (ExitCode <> 0) or ExitScreenLoop or MemorySnapshotActive then
            Break;
        end;
        if (ExitCode <> 0) or ExitScreenLoop or MemorySnapshotActive then
          Continue;
        BeforeDrawCount := sr_present_count;

        if PopupController = nil then
        begin
          Stage := 15;
          DrawFrame;
        end
        else
        begin
          Stage := 16;
          RootUiObject.AttachOwnedChild(PopupController);
          Stage := 17;
          DrawFrame;
          Stage := 18;
          RootUiObject.UnlinkOwnedChild(PopupController);
        end;
        Stage := 19;

        // A submitted frame is paced by SDL. Yield only when nothing was
        // submitted (including headless checks), not after each refresh.
        if sr_present_count = BeforeDrawCount then
          Sleep(1);

        Stage := 20;
        if RecordingFrames then
        begin
          Stage := 21;
          RecordingTime := timeGetTime;
          CaptureRecordingFrame;
          RecordingTime := timeGetTime - RecordingTime;

          Inc(LastUpdateTick, RecordingTime);

        end;

        NowTick := timeGetTime;
        if NowTick - LastFpsTick >= 500 then

        begin
          Stage := 22;

          PresentCount := sr_present_count;
          FramesPerSecond :=
              Round((PresentCount - LastPresentCount) * 1000.0 / (NowTick - LastFpsTick));
          LastFpsTick := NowTick;
          LastPresentCount := PresentCount;

          if ShowFrameRate then
            (GetByName('FPS') as TLabelGI).SetText('FPS: ' + IntToStr(FramesPerSecond));

        end;
        Stage := 24;
        for Index := 0 to SoundGroupList.Count - 1 do
          if (TFormSoundGroup(SoundGroupList[Index]).Section = 0)
              or (TFormSoundGroup(SoundGroupList[Index]).Section = SoundSection) then
            TFormSoundGroup(SoundGroupList[Index]).PlayIfDue;
        if MusicEnabled and not MusicManager.HasSelectedMusic then
        begin
          Stage := 25;
          MusicManager.HasSelectedMusic;
          SelectMusic;
        end;
        Stage := 26;
      end
      else
      begin
        LastUpdateTick := timeGetTime;
        Sleep(1);
      end;

    end;
    Stage := 27;
    try
      RootUiObject.OnMouseLeave;
      RefreshMouseAfterCode := False;
      for Index := 0 to DeferredCodeBlocks.Count - 1 do
        ExecuteUiCode(TBlockParEC(DeferredCodeBlocks[Index]), 0);
      DeferredCodeBlocks.Clear;
    except
      on E: EBreakMessageGI do
        ;
    end;
    RootUiObject.OnDeactivate;
    if CustomCursorEnabled then
      SetCursorActive(False);
    Stage := 28;
    if PlayTransitionSounds and (CloseSoundName <> '') then
      SoundManager.PlaySound(CloseSoundName);
    Stage := 29;
    ClearTransientControl;
    Stage := 30;

    OnClose;

    Stage := 31;
    FreeSavedPixels16;
    Stage := 32;
    FreeSecondaryPixelBuffer;
    Stage := 33;
    FreeSavedLines;
    Result := ExitCode;
    Stage := 34;
    PopMessageLoop(Self);
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
      LogExceptionBackTrace;
      AppendLogLineThreadSafe(
          'Error in procedure TMessageLoopGI.Run2, '
              + RegisteredLoopName
              + ', label = '
              + IntToStr(Stage)
      );
      // Keep the failing instruction and stack for the host's exception log.
      raise;
    end;
  end;
end;
procedure TMessageLoopGI.AdvanceTimerTick;
var
  Timer: PCallbackTimerGI;
  Stage: Integer;
  CallbackMethod: TMethod;
begin
  Stage := 0;
  CallbackMethod.Code := nil;
  CallbackMethod.Data := nil;
  try
    Inc(TimerTick);
    Stage := 1;
    NextTimerToProcess := FirstTimer;
    while NextTimerToProcess <> nil do
    begin
      Stage := 2;
      if NextTimerToProcess.DueTick > TimerTick then
        Break;
      Stage := 3;
      Timer := NextTimerToProcess;
      NextTimerToProcess := NextTimerToProcess.Next;
      Timer.DueTick := TimerTick + Cardinal(Timer.RepeatMs);
      Stage := 4;
      ReinsertCallbackTimer(Timer);
      Stage := 5;
      // A callback may cancel its own timer; retain diagnostic data separately.
      CallbackMethod := TMethod(Timer.Callback);
      Timer.Callback(Timer, Timer.UserData);
      Stage := 6;
    end;
    NextTimerToProcess := nil;
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
      LogExceptionBackTrace;
      AppendLogLineThreadSafe(
          'Error in procedure TMessageLoopGI.Takt2, '
              + RegisteredLoopName
              + ', label = '
              + IntToStr(Stage)
      );
      if Stage = 5 then
        AppendLogLineThreadSafe(
            'Timer callback: '
                + BackTraceStrFunc(CallbackMethod.Code)
                + ', owner=$'
                + IntToHex(PtrUInt(CallbackMethod.Data), SizeOf(Pointer) * 2)
        );
      raise;
    end;
  end;
end;
procedure TMessageLoopGI.DrawFrame;
begin
  if UpdateRects.FirstRect <> nil then
  begin
    DrawQueuedUpdateRects;
    FinishQueuedDraw;
  end;
end;
procedure TMessageLoopGI.Present;
begin
  if DeferScreenPresentation then
    Exit;
  UnknownPresentState := 0;
  if ContinuousLoop then
  begin
    FullFrameRedrawRequested := True;
    DrawFrame;
  end
  else
  begin
    DrawQueuedUpdateRects;
    if not BeginFramePresentation then
    begin
      RequestedScreenId := screenNone;
      PostLoadScreenId := FormToId(Self);
      Exit;
    end;
    FinishQueuedDraw;
    EndFramePresentation;
  end;
end;
procedure TMessageLoopGI.ProcessWindowMessage(Message, WParam: Cardinal; LParam: Integer);
var
  Point: TPoint;
  MoveStep: Integer;
  BreakAfterDoubleClick: Boolean;
  Stage, Index: Integer;
  NewOffset: TPoint;
  // Native reserves twelve unreferenced bytes at EBP-$4C..EBP-$41.
  // DCC32 O- allocates unused locals after live ones; original types are unknown.
  UnusedLocals: array[0..11] of Byte;
  procedure ConvertMousePointToViewport; // @addr $4BFB04 @ida "void __usercall $name(void *ParentFrame@<^0>);" @stackpop 0 @calls "0x4BFD6E 0x4BFED2 0x4BFF1C 0x4BFF7B 0x4BFFFF 0x4C0183 0x4C01E6 0x4C02A9" @note "Nested ProcessWindowMessage helper; scales or offsets its captured mouse point."
  begin
    if AlternateViewportEnabled then
      if ScaleViewportToWindow then
      begin
        Point.X := Point.X * GameScreenWidth div PresentationWidth;
        Point.Y := Point.Y * GameScreenHeight div PresentationHeight;
      end
      else
      begin
        Dec(Point.X, ViewportOffset.X);
        Dec(Point.Y, ViewportOffset.Y);
      end;
  end;
begin
  if MemorySnapshotActive then
    Exit;
  if ExitCode <> 0 then
    Exit;
  Stage := 0;
  try
    if Message = WM_MOUSEMOVE then
    begin
      Point.X := SmallInt(LParam);
      Point.Y := SmallInt(LParam shr 16);
      LastMousePosition.X := Point.X;
      LastMousePosition.Y := Point.Y;
      if IgnoreWarpMouseMove then
      begin
        IgnoreWarpMouseMove := False;
        Exit;
      end;
      if not ScaleViewportToWindow then
      begin
        Stage := 1;
        NewOffset.X := ViewportOffset.X + ((PresentationWidth shr 1) - Point.X);
        NewOffset.Y := ViewportOffset.Y + ((PresentationHeight shr 1) - Point.Y);
        if NewOffset.X > 0 then
          NewOffset.X := 0;
        if NewOffset.Y > 0 then
          NewOffset.Y := 0;
        if GameScreenWidth + NewOffset.X < PresentationWidth then
          NewOffset.X := -(GameScreenWidth - PresentationWidth);
        if GameScreenHeight + NewOffset.Y < PresentationHeight then
          NewOffset.Y := -(GameScreenHeight - PresentationHeight);
        if ViewportOffset.X <> NewOffset.X then
          Point.X := PresentationWidth shr 1;
        if ViewportOffset.Y <> NewOffset.Y then
          Point.Y := PresentationHeight shr 1;
        Stage := 2;
        if (ViewportOffset.X <> NewOffset.X) or (ViewportOffset.Y <> NewOffset.Y) then
        begin
          IgnoreWarpMouseMove := True;
          ClientToScreen(MainWindowHandle, Point);
          SetCursorPos(Point.X, Point.Y);
          ScreenToClient(MainWindowHandle, Point);
        end;
        ViewportOffset := NewOffset;
      end;
      Stage := 3;
      ConvertMousePointToViewport;
      if CursorControl.Active = True then
        (CursorControl as TCursorGI).SetPosition(Point);
      Stage := 4;
      if FocusedControl <> nil then
        FocusedControl.ProcessMouseMove(WParam, Point);
      Stage := 5;
      if RootUiObject.ContainsPoint(Point) then
      begin
        if not RootUiObject.MouseInside then
        begin
          Stage := 6;
          RootUiObject.OnMouseEnter;
        end;
        RootUiObject.ProcessMouseMove(WParam, Point);
      end
      else if RootUiObject.MouseInside = True then
      begin
        Stage := 7;
        RootUiObject.OnMouseLeave;
      end;
    end
    else if Message = WM_MOUSELEAVE then
    begin
      Stage := 8;
      GetCursorPos(Point);
      ScreenToClient(MainWindowHandle, Point);
      Stage := 9;
      ProcessWindowMessage(WM_MOUSEMOVE, 0, Word(Point.X) or (Word(Point.Y) shl 16));
      Stage := 10;
      LastMouseMessageTick := timeGetTime;
    end
    else if Message = WM_MOUSEWHEEL then
    begin
      Stage := 11;
      Point := Classes.Point(SmallInt(LParam), SmallInt(LParam shr 16));
      ScreenToClient(MainWindowHandle, Point);
      ConvertMousePointToViewport;
      ProcessMouseWheel(Word(WParam), Point, SmallInt(WParam shr 16));
    end
    else if Message = WM_LBUTTONDOWN then
    begin
      Stage := 12;
      Point := Classes.Point(Word(LParam), Word(LParam shr 16));
      ConvertMousePointToViewport;
      if RootUiObject.ContainsPoint(Point) then
      begin
        Stage := 13;
        RootUiObject.ProcessLeftButtonDown(WParam, Point);
      end;
    end
    else if Message = WM_LBUTTONUP then
    begin
      Stage := 14;
      Point := Classes.Point(Word(LParam), Word(LParam shr 16));
      ConvertMousePointToViewport;
      if FocusedControl <> nil then
      begin
        Stage := 15;
        FocusedControl.ProcessLeftButtonUp(WParam, Point);
      end;
      if RootUiObject.ContainsPoint(Point) then
      begin
        Stage := 16;
        RootUiObject.ProcessLeftButtonUp(WParam, Point);
      end;
    end
    else if Message = WM_RBUTTONDOWN then
    begin
      Stage := 17;
      Point := Classes.Point(Word(LParam), Word(LParam shr 16));
      ConvertMousePointToViewport;
      if RootUiObject.ContainsPoint(Point) then
      begin
        Stage := 18;
        RootUiObject.ProcessRightButtonDown(WParam, Point);
      end;
      if StatusLabel.Active then
      begin
        Stage := 19;
        if (DebugControl = nil)
            or (DebugControl.Parent = ContentPanel)
            or not DebugControl.ContainsPoint(Point) then
          DebugControl := ContentPanel.FindDeepestChildAtPoint(Point)
        else
          DebugControl := DebugControl.Parent;
        Stage := 20;
        (StatusLabel as TLabelGI)
            .SetText(
                DebugControl.ControlName
                    + ' ('
                    + DebugControl.ClassName
                    + ') Pos='
                    + IntToStr(DebugControl.LocalPosition.X)
                    + ','
                    + IntToStr(DebugControl.LocalPosition.Y));
      end;
    end
    else if Message = WM_RBUTTONUP then
    begin
      Stage := 21;
      Point := Classes.Point(Word(LParam), Word(LParam shr 16));
      ConvertMousePointToViewport;
      if RootUiObject.ContainsPoint(Point) then
      begin
        Stage := 22;
        RootUiObject.ProcessRightButtonUp(WParam, Point);
      end;
    end
    else if Message = WM_LBUTTONDBLCLK then
    begin
      Stage := 23;
      Point := Classes.Point(Word(LParam), Word(LParam shr 16));
      ConvertMousePointToViewport;
      if RootUiObject.ContainsPoint(Point) then
      begin
        Stage := 24;
        BreakAfterDoubleClick := True;
        try
          RootUiObject.ProcessLeftButtonDown(WParam, Point);
        except
          on E: EBreakMessageGI do
            BreakAfterDoubleClick := True;
        end;
        Stage := 25;
        RootUiObject.ProcessLeftButtonDoubleClick(WParam, Point);
        if BreakAfterDoubleClick then
          BreakUiMessage;
      end;
    end
    else if Message = WM_RBUTTONDBLCLK then
    begin
      Stage := 26;
      Point := Classes.Point(Word(LParam), Word(LParam shr 16));
      ConvertMousePointToViewport;
      if RootUiObject.ContainsPoint(Point) then
      begin
        Stage := 27;
        BreakAfterDoubleClick := True;
        try
          RootUiObject.ProcessRightButtonDown(WParam, Point);
        except
          on E: EBreakMessageGI do
            BreakAfterDoubleClick := True;
        end;
        Stage := 28;
        RootUiObject.ProcessRightButtonDoubleClick(WParam, Point);
        if BreakAfterDoubleClick then
          BreakUiMessage;
      end;
    end
    else if Message = WM_CHAR then
    begin
      Stage := 29;
      if (WParam >= Ord(' ')) and (FocusedControl <> nil) then
      begin
        Stage := 30;
        FocusedControl.ProcessCharacter(WideChar(WParam));
      end;
    end
    else if (Message = WM_KEYDOWN)
        or ((Message = WM_SYSKEYDOWN) and (WParam in [VK_MENU, VK_LEFT..VK_DOWN, VK_F5])) then
    begin
      Stage := 31;
      RootUiObject.BroadcastKeyDown(WParam);
      if FocusedControl <> nil then
      begin
        Stage := 32;
        FocusedControl.ProcessKeyDown(WParam);
      end;
      Stage := 33;
      if IsVirtualKeyDown(VK_CONTROL)
          and IsVirtualKeyDown(VK_SHIFT)
          and not IsVirtualKeyDown(VK_MENU)
          and Assigned(DebugKeyCallback) then
        DebugKeyCallback(Word(WParam));
      Stage := 34;
      if WParam = VK_F9 then
        CaptureScreenshot;
      Stage := 35;
      if (WParam = Ord('M'))
          and IsVirtualKeyDown(VK_CONTROL)
          and IsVirtualKeyDown(VK_SHIFT)
          and IsVirtualKeyDown(VK_MENU) then
        StatusLabel.SetActive(not StatusLabel.Active);
      Stage := 36;
      if StatusLabel.Active and (DebugControl <> nil) then
      begin
        Stage := 37;
        if GetAsyncKeyState(VK_CONTROL) and $8000 = $8000 then
          MoveStep := 10
        else
          MoveStep := 1;
        Stage := 38;
        if WParam = VK_UP then
          DebugControl.SetPosition(
              Classes.Point(DebugControl.LocalPosition.X, DebugControl.LocalPosition.Y - MoveStep)
          )
        else if WParam = VK_DOWN then
          DebugControl.SetPosition(
              Classes.Point(DebugControl.LocalPosition.X, DebugControl.LocalPosition.Y + MoveStep)
          )
        else if WParam = VK_LEFT then
          DebugControl.SetPosition(
              Classes.Point(DebugControl.LocalPosition.X - MoveStep, DebugControl.LocalPosition.Y)
          )
        else if WParam = VK_RIGHT then
          DebugControl.SetPosition(
              Classes.Point(DebugControl.LocalPosition.X + MoveStep, DebugControl.LocalPosition.Y)
          );
        Stage := 39;
        (StatusLabel as TLabelGI)
            .SetText(
                DebugControl.ControlName
                    + ' ('
                    + DebugControl.ClassName
                    + ') Pos='
                    + IntToStr(DebugControl.LocalPosition.X)
                    + ','
                    + IntToStr(DebugControl.LocalPosition.Y));
      end
      else if StatusLabel.Active and (DebugControl = nil) then
      begin
        Stage := 40;
        (StatusLabel as TLabelGI).SetText('Not object');
      end;
    end
    else if (Message = WM_KEYUP)
        or ((Message = WM_SYSKEYUP) and (WParam in [VK_MENU, VK_LEFT..VK_DOWN])) then
    begin
      Stage := 41;
      RootUiObject.BroadcastKeyUp(WParam);
    end
    else if Message = WM_PAINT then
    begin
      Stage := 42;
      InvalidateViewport;
    end;
    Stage := 43;
    for Index := 0 to DeferredCodeBlocks.Count - 1 do
      ExecuteUiCode(TBlockParEC(DeferredCodeBlocks[Index]), 0);
    if RefreshMouseAfterCode then
    begin
      Point.X := LastMousePosition.X;
      Point.Y := LastMousePosition.Y;
      RootUiObject.ProcessMouseMove(0, Point);
    end;
    RefreshMouseAfterCode := False;
    DeferredCodeBlocks.Clear;
  except
    on E: EBreakMessageGI do
      ;
    on E: Exception do
    begin
      AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
      LogExceptionBackTrace;
      if Stage in [31, 32] then
        AppendLogLineThreadSafe('key=' + IntToWideString(WParam));
      raise Exception.Create(
          'Error in procedure TMessageLoopGI.SysMessage, label = ' + IntToStr(Stage));
    end;
  end;
end;
procedure TMessageLoopGI.CaptureScreenshot;
var

  Digits: AnsiString;

  DigitCount: Integer;
  Extension, BaseName, FileName: AnsiString;
  Buffer: TGraphBufGR;
  function FindFreeScreenshotName: Boolean; // @addr $4C0A14 @ida "bool __usercall $name@<al>(void *ParentFrame@<^0>);" @stackpop 0 @calls "0x4C0C40" @note "Nested CaptureScreenshot helper; updates the captured filename strings."
  var
    Index: Integer;
  begin
    Result := False;
    Index := 0;
    while Index < 1000 do
    begin

      Digits := IntToStr(Index);
      while Length(Digits) < DigitCount do
        Digits := '0' + Digits;
      BaseName := 'Shot' + Digits + Extension;

      FileName := GetGameUserDirectory + 'Screenshots' + '\' + BaseName;
      if not RTLFileSystem.FileExists(FileName) then
        Break;
      Inc(Index);
    end;
    if Index < 1000 then
      Result := True;
  end;
begin
  CreateDir(GetGameUserDirectory + 'Screenshots');
  DigitCount := Length(IntToStr(999));
  case ScreenshotFormat of
    0: Extension := '.bmp';
    1: Extension := '.png';
    2: Extension := '.jpg';
  end;
  if FindFreeScreenshotName then
  begin
    DrawQueuedUpdateRects;
    Buffer := TGraphBufGR.Create(False);
    try
      if HardwareRenderingEnabled then
        Buffer.LoadFromScreen(0)
      else
      begin
        Buffer.AllocateRgbaTight(GameScreenWidth, GameScreenHeight);
        Ex_OKGF_Convert565toBGRA(
            ScreenRenderBuffer.GetPixels,
            ScreenRenderBuffer.PitchBytes,
            Buffer.GetPixels,
            Buffer.PitchBytes,
            Buffer.Width,
            Buffer.Height
        );
      end;
      case ScreenshotFormat of
        0: Buffer.SaveBmp(FileName);
        1: Buffer.SavePng(FileName);
        2: Buffer.SaveJpeg(FileName, ScreenshotJpegQuality);
      end;
    finally
      Buffer.Free;
    end;
  end;
end;
procedure TMessageLoopGI.RequestClose(ResultCode: Integer);
begin
  ExitCode := ResultCode;
end;
procedure TMessageLoopGI.SetHelpCallback(Callback: TObjectHelpEventGI);
begin
  ContentPanel.SetHelpCallbackRecursive(Callback);
end;
function TMessageLoopGI.GetByName(const Name: WideString): TObjectGI;
begin

  Result := ContentPanel.FindByNameRecursive(Name);
  if Result = nil then
    raise Exception.Create('TMessageLoopGI.GetByName. Name=' + Name);
end;
function TMessageLoopGI.FindControlByPath(const Path: WideString): TObjectGI;
var
  Index, Count: Integer;
begin
  Count := CountDelimitedPartsW(Path, ':');
  if Count <= 1 then
    Result := ContentPanel.FindByNameRecursive(Path)
  else
  begin
    Result := ContentPanel;
    for Index := 0 to Count - 1 do
    begin
      Result := Result.FindByNameRecursive(ExtractDelimitedPartW(Path, Index, ':'));
      if Result = nil then
        Break;
    end;
  end;
end;
procedure TMessageLoopGI.SetFocusedControl(Control: TObjectGI);
begin
  if FocusedControl = Control then
    Exit;
  if FocusedControl <> nil then
    FocusedControl.OnFocusLost;
  FocusedControl := Control;
  if FocusedControl <> nil then
    FocusedControl.OnFocusGained;
end;
procedure TMessageLoopGI.SetHoveredControl(Control: TObjectGI);
var
  Previous: TObjectGI;
begin
  if HoveredControl = Control then
    Exit;
  if HoveredControl <> nil then
  begin
    Previous := HoveredControl;
    HoveredControl := nil;
    Previous.OnHoverLost;
  end;
  HoveredControl := Control;
  if HoveredControl <> nil then
    HoveredControl.OnHoverGained;
end;
procedure TMessageLoopGI.ProcessNamedControlEvent(
    ControlName: WideString;
    EventKind, Param1, Param2: Integer
);
begin
end;
procedure TMessageLoopGI.OnOpen;
begin
  IsOpen := True;
end;
procedure TMessageLoopGI.OnClose;
begin
  IsOpen := False;
end;
procedure TMessageLoopGI.ProcessCallbackTimers;
var
  NowTick: Cardinal;
  Timer: PCallbackTimerGI;

  WaitMs: PtrInt;
  Handle: Windows.THandle;

begin

  NowTick := timeGetTime;

  if FirstTimer <> nil then
  begin
    WaitMs := Integer(FirstTimer.DueTick - NowTick);
    if WaitMs > 0 then
    begin
      Handle := 0;
      MsgWaitForMultipleObjects(0, Handle, False, WaitMs, $1FF);
      NowTick := timeGetTime;
    end;
  end;

  NextTimerToProcess := FirstTimer;
  while NextTimerToProcess <> nil do
  begin
    if NextTimerToProcess.DueTick > NowTick then
      Break;
    Timer := NextTimerToProcess;
    NextTimerToProcess := NextTimerToProcess.Next;
    Timer.DueTick := NowTick + Cardinal(Timer.RepeatMs);
    ReinsertCallbackTimer(Timer);
    Timer.Callback(Timer, Timer.UserData);
  end;
  NextTimerToProcess := nil;
  TimerTick := NowTick;
end;
procedure TMessageLoopGI.SelectMusic;
begin
end;
function TMessageLoopGI.ScheduleCallbackTimer(
    DelayMs, RepeatMs: Integer;
    Callback: TCallbackTimerEventGI;
    UserData: PtrInt
): PCallbackTimerGI;
var
  Timer: PCallbackTimerGI;
begin
  Timer := AllocEC(SizeOf(TCallbackTimerGI));
  if LastTimer <> nil then
    LastTimer.Next := Timer;
  Timer.Prev := LastTimer;
  Timer.Next := nil;
  LastTimer := Timer;
  if FirstTimer = nil then
    FirstTimer := Timer;
  Timer.DueTick := TimerTick + Cardinal(DelayMs);
  Timer.CachedDueTick := Timer.DueTick;
  Timer.RepeatMs := RepeatMs;
  Timer.UserData := UserData;
  Timer.Callback := Callback;
  ReinsertCallbackTimer(Timer);
  Result := Timer;
end;
procedure TMessageLoopGI.CancelCallbackTimer(Timer: PCallbackTimerGI);
var
  Current: PCallbackTimerGI;
begin
  Current := Timer;
  UncacheCallbackTimer(Current);
  if NextTimerToProcess = Current then
    NextTimerToProcess := NextTimerToProcess.Next;
  if Current.Prev <> nil then
    Current.Prev.Next := Current.Next;
  if Current.Next <> nil then
    Current.Next.Prev := Current.Prev;
  if LastTimer = Current then
    LastTimer := Current.Prev;
  if FirstTimer = Current then
    FirstTimer := Current.Next;
  FreeEC(Current);
end;
procedure TMessageLoopGI.UpdateCallbackTimer(Timer: PCallbackTimerGI; DelayMs, RepeatMs: Integer);
var
  Current: PCallbackTimerGI;
begin
  Current := Timer;
  if (TimerTick + Cardinal(DelayMs) = Current.DueTick) and (Current.RepeatMs = RepeatMs) then
    Exit;
  Current.DueTick := TimerTick + Cardinal(DelayMs);
  Current.RepeatMs := RepeatMs;
  ReinsertCallbackTimer(Current);
end;
// CHANGE: PERFORMANCE - Never retain a timer after it moves or is cancelled.
procedure TMessageLoopGI.UncacheCallbackTimer(Timer: PCallbackTimerGI);
var
  Slot: Cardinal;
begin
  Slot := Timer.CachedDueTick and High(TimerDeadlineHeads);
  if TimerDeadlineHeads[Slot] <> Timer then
    Exit;
  if (Timer.Next <> nil) and (Timer.Next.DueTick = Timer.CachedDueTick) then
    TimerDeadlineHeads[Slot] := Timer.Next
  else
    TimerDeadlineHeads[Slot] := nil;
end;
procedure TMessageLoopGI.ReinsertCallbackTimer(Timer: PCallbackTimerGI);
var
  Current, Before, DeadlineHead: PCallbackTimerGI;
  Slot: Cardinal;
begin
  Current := Timer;
  UncacheCallbackTimer(Current);
  Slot := Current.DueTick and High(TimerDeadlineHeads);
  DeadlineHead := TimerDeadlineHeads[Slot];
  Current.CachedDueTick := Current.DueTick;
  // Insertion is always before equal deadlines, retaining the original tie order.
  if not TimerDeadlineCacheDisabled then
    TimerDeadlineHeads[Slot] := Current;
  if Current.Prev <> nil then
    Current.Prev.Next := Current.Next;
  if Current.Next <> nil then
    Current.Next.Prev := Current.Prev;
  if LastTimer = Current then
    LastTimer := Current.Prev;
  if FirstTimer = Current then
    FirstTimer := Current.Next;
  if FirstTimer = nil then
  begin
    TimerDeadlineCacheDisabled := False;
    TimerDeadlineHeads[Slot] := Current;
    FirstTimer := Current;
    LastTimer := Current;
    Current.Prev := nil;
    Current.Next := nil;
    Exit;
  end;
  // CHANGE: PERFORMANCE - Animation timers commonly share a deadline. Avoid
  // walking thousands of later timers to find the same insertion point again.
  if (DeadlineHead <> nil) and (DeadlineHead.DueTick = Current.DueTick) then
  begin
    Current.Prev := DeadlineHead.Prev;
    Current.Next := DeadlineHead;
    if DeadlineHead.Prev <> nil then
      DeadlineHead.Prev.Next := Current
    else
      FirstTimer := Current;
    DeadlineHead.Prev := Current;
    Exit;
  end;
  if LastTimer.DueTick < Current.DueTick then
  begin
    LastTimer.Next := Current;
    Current.Prev := LastTimer;
    Current.Next := nil;
    LastTimer := Current;
    Exit;
  end;
  if FirstTimer.DueTick >= Current.DueTick then
  begin
    Current.Prev := nil;
    Current.Next := FirstTimer;
    FirstTimer.Prev := Current;
    FirstTimer := Current;
    Exit;
  end;
  begin
    Before := LastTimer.Prev;
    while Current.DueTick <= Before.DueTick do
      Before := Before.Prev;
    Current.Prev := Before;
    Current.Next := Before.Next;
    Before.Next.Prev := Current;
    Before.Next := Current;
  end;
end;
procedure TMessageLoopGI.RefreshTimerTick;
begin
  TimerTick := timeGetTime;
end;
procedure TMessageLoopGI.SetCursorImage(const ImagePath: WideString; HotSpot: TPoint);
begin
  if CustomCursorEnabled then
  begin
    (CursorControl as TCursorGI).SetImagePath(ImagePath);
    CursorControl.SetOrigin(HotSpot);
    CursorImagePath := ImagePath;
  end;
end;
procedure TMessageLoopGI.SetCursorByName(const Name: WideString);
var
  Cursor: TCursorUnit;
begin
  if CustomCursorEnabled then
  begin
    Cursor := FindCursorByName(Name);
    SetCursorImage(Cursor.ImagePath, Cursor.HotSpot);
  end;
end;
function TMessageLoopGI.IsCursorImageSelected(const RegisteredName: WideString): Boolean;
var
  Cursor: TCursorUnit;
begin
  Cursor := FindCursorByName(RegisteredName);
  Result := Cursor.ImagePath = CursorImagePath;
end;
function TMessageLoopGI.IsCursorActive: Boolean;
begin
  Result := CursorControl.Active;
end;
procedure TMessageLoopGI.SetCursorActive(Enabled: Boolean);
begin
  if CursorControl.Active <> Enabled then
    CursorControl.SetActive(Enabled);
end;
procedure TMessageLoopGI.CaptureCursorState(State: PCursorStateGI);
begin
  State^.ImagePath := CursorImagePath;
  State^.Active := IsCursorActive;
  State^.HotSpot := CursorControl.OriginPoint;
  State^.Position := CursorControl.LocalPosition;
end;
procedure TMessageLoopGI.RestoreCursorState(State: PCursorStateGI);
begin
  if CustomCursorEnabled then
  begin
    SetCursorImage(State^.ImagePath, State^.HotSpot);
    SetCursorActive(State^.Active);
    CursorControl.SetPosition(State^.Position);
  end;
end;
procedure TMessageLoopGI.UpdateCursorPosition;
var
  Point: TPoint;
begin
  GetCursorPos(Point);
  if Direct3DPresentParameters.Windowed then
    ScreenToClient(MainWindowHandle, Point);
  CursorControl.SetPosition(Point);
end;
function TMessageLoopGI.GetCursorPoint: TPoint;
begin
  Result := CursorControl.LocalPosition;
end;
procedure TMessageLoopGI.SetSystemCursorPosition(Point: TPoint);
begin
  SetCursorPos(Point.X, Point.Y);
end;
function TMessageLoopGI.ConsumeTimerTickChange: Boolean;
begin
  if LastObservedTimerTick = TimerTick then
  begin
    Result := False;
    Exit;
  end;
  LastObservedTimerTick := TimerTick;
  Result := True;
end;
function TMessageLoopGI.QueryPointOcclusionState(
    Point: TPoint;
    IgnoreControl, StartControl: TObjectGI
): Integer;
var
  Child: TObjectGI;
begin
  if StartControl = nil then
    StartControl := RootUiObject;
  if ((StartControl.Parent <> nil) and StartControl.ContainsPoint(Point))
      or (StartControl.Parent = nil) then
  begin
    Child := StartControl.LastChild;
    while Child <> nil do
    begin
      Result := QueryPointOcclusionState(Point, IgnoreControl, Child);
      if Result <> 0 then
        Exit;
      Child := Child.PrevSibling;
    end;
    if StartControl.MouseBlocking and (StartControl <> IgnoreControl) then
    begin
      Result := 1;
      Exit;
    end;
  end;
  if StartControl = IgnoreControl then
    Result := -1
  else
    Result := 0;
end;
procedure TMessageLoopGI.FreeSavedPixels16;
begin
  if SavedPixels16 <> nil then
  begin
    FreeEC(SavedPixels16);
    SavedPixels16 := nil;
  end;
  SavedPixelCount16 := 0;
  SavedPixelCapacity16 := 0;
end;
procedure TMessageLoopGI.RestoreSavedPixels16;
var
  I: Integer;
  P, Pixels: PByte;
begin
  if HardwareRenderingEnabled or (SavedPixelCount16 = 0) then
  begin
    SavedPixelCount16 := 0;
    Exit
  end;
  Pixels := ScreenRenderBuffer.GetPixels;
  P := SavedPixels16;
  for I := 0 to SavedPixelCount16 - 1 do
  begin
    PWord(Pixels + PInteger(P)^)^ := PWord(P + 4)^;
    Inc(P, 8)
  end;
  SavedPixelCount16 := 0
end;
procedure TMessageLoopGI.FreeSecondaryPixelBuffer;
begin
  if SecondaryPixelBuffer <> nil then
  begin
    FreeEC(SecondaryPixelBuffer);
    SecondaryPixelBuffer := nil;
  end;
  SecondaryPixelCount := 0;
  SecondaryPixelCapacity := 0;
end;
procedure TMessageLoopGI.ResetSecondaryPixelCount;
begin
  if SecondaryPixelCount < 1 then
    Exit;
  SecondaryPixelCount := 0;
end;
procedure TMessageLoopGI.FreeSavedLines;
var
  Index: Integer;
begin
  for Index := 0 to High(SavedLines) do
    FreeFromHeapEC(SavedLines[Index].Heap, SavedLines[Index].Pixels);
  SavedLines := nil;
  SavedLineCount := 0;
end;
procedure TMessageLoopGI.AddSavedLine(First, Last: TPoint; Pixels: Pointer);
begin
  if High(SavedLines) + 1 = SavedLineCount then
    SetLength(SavedLines, SavedLineCount + 100);
  SavedLines[SavedLineCount].First := First;
  SavedLines[SavedLineCount].Last := Last;
  SavedLines[SavedLineCount].Pixels := Pixels;
  SavedLines[SavedLineCount].Heap := GetProcessHeap;
  Inc(SavedLineCount);
end;
procedure TMessageLoopGI.RestoreSavedLines;
var
  Index: Integer;
begin
  if not SkipSavedPixelRestore then
    for Index := 0 to SavedLineCount - 1 do
      Ex_OKGR_Line_CopyFromBuf_WORD(
          SavedLines[Index].Pixels,
          ScreenRenderBuffer.GetPixels,
          ScreenRenderBuffer.PitchBytes,
          SavedLines[Index].First.X,
          SavedLines[Index].First.Y,
          SavedLines[Index].Last.X,
          SavedLines[Index].Last.Y
      );
end;
procedure TMessageLoopGI.ResetSavedLineCount;
begin
  SavedLineCount := 0;
end;
procedure TMessageLoopGI.ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer);
begin
end;
procedure TMessageLoopGI.ClearTransientControl;
begin
  InvalidateTransientControl;
  if TransientData <> nil then
  begin
    TransientData.Free;
    TransientData := nil;
  end;
  if TransientControl <> nil then
  begin
    TransientControl.SetActive(False);
    TransientControl.Free;
    TransientControl := nil;
  end;
end;
procedure TMessageLoopGI.InvalidateTransientControl;
var
  WasEnabled: Boolean;
begin
  if TransientControl <> nil then
  begin
    WasEnabled := UpdateRectsEnabled;
    UpdateRectsEnabled := True;
    TransientControl.Invalidate;
    UpdateRectsEnabled := WasEnabled;
  end;
end;
procedure TMessageLoopGI.InitializeDefaults;
var
  LabelControl: TLabelGI;
begin
  RootUiObject := CreateControlByName('Panel', nil);
  RootUiObject.MessageLoop := Self;
  RootUiObject.SetPosition(Classes.Point(0, 0));
  RootUiObject.SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
  BackgroundPanel := CreateControlByName('Panel', RootUiObject);
  BackgroundPanel.SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
  BackgroundPanel.SetDepth(1);
  ContentPanel := CreateControlByName('Panel', RootUiObject);
  ContentPanel.SetDepth(0);
  OverlayPanel := CreateControlByName('Panel', RootUiObject);
  OverlayPanel.SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
  OverlayPanel.SetDepth(-1);
  StatusLabel := TLabelGI.Create(OverlayPanel);
  LabelControl := StatusLabel as TLabelGI;
  LabelControl.SetActive(False);
  LabelControl.SetFontName(NormalFontName);
  LabelControl.SetDepth(-1E29);
  LabelControl.SetPosition(Classes.Point(5, 5));
  LabelControl.SetSize(Classes.Point(400, 20));
  LabelControl.SetTextAlignX(taxLeft);
  LabelControl.SetTextAlignY(tayCenterEx);
  CursorControl := TCursorGI.Create(OverlayPanel);
  CursorControl.SetDepth(-1E30);
end;
procedure TMessageLoopGI.InitializeFromConfig(
    ConfigRoot: TBlockParEC;
    const ScreenName: WideString;
    UnusedFlag: Boolean
);
var
  ScreenBlock, SoundBlock: TBlockParEC;
  Text: WideString;
  Index, Count: Integer;
  Group: TFormSoundGroup;
begin
  ResetRuntime;
  InitializeDefaults;
  ScreenBlock := ConfigRoot.GetBlockByPath(ScreenName);
  RegisteredLoopName := ScreenName;
  Text := ScreenBlock.GetParam('Border');
  ViewportRect.Left := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
  ViewportRect.Top := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
  ViewportRect.Right := StrToInt(ExtractDelimitedPartW(Text, 2, ','));
  ViewportRect.Bottom := StrToInt(ExtractDelimitedPartW(Text, 3, ','));
  if ScreenBlock.CountBlocks('Sound') > 0 then
  begin
    SoundBlock := ScreenBlock.GetBlock('Sound');
    if SoundBlock.CountParams('Open') > 0 then
      OpenSoundName := SoundBlock.GetParam('Open');
    if SoundBlock.CountParams('Close') > 0 then
      CloseSoundName := SoundBlock.GetParam('Close');
    Count := SoundBlock.GetBlockCount;
    for Index := 0 to Count - 1 do
    begin
      Group := TFormSoundGroup.Create;
      SoundGroupList.Add(Group);
      Group.LoadFromBlock(SoundBlock.GetBlockByIndex(Index));
    end;
  end;

  ContentPanel.LoadFromBlock(ScreenBlock.GetBlockByPath('Panel'));
  RootUiObject.UpdateAbsolutePosition;
  RootUiObject.UpdateSubtreeHitBounds;
  QueueUpdateRect(ViewportRect);

end;
procedure TMessageLoopGI.InitializeLayout;
begin
  RootUiObject.UpdateAutoGeometry;
end;
procedure TMessageLoopGI.UpdateActionCursor(CanTake: Boolean);
begin
end;
function TMessageLoopGI.GetActionParentLoop: TMessageLoopGI;
begin
  Result := nil;
end;
procedure TMessageLoopGI.QueueUiCode(Block: TBlockParEC; RefreshMouse: Boolean);
begin
  DeferredCodeBlocks.Add(Block);
  if RefreshMouse then
    RefreshMouseAfterCode := True;
end;
procedure TMessageLoopGI.RefreshMouseDispatch;
var
  Point: TPoint;
begin
  Point.X := LastMousePosition.X;
  Point.Y := LastMousePosition.Y;
  RootUiObject.ProcessMouseMove(0, Point);
end;
procedure TMessageLoopGI.ExecuteUiCode(Block: TBlockParEC; Key: Cardinal);
begin
end;
procedure LinkRecoveredTypes;
begin
  TCursorGI.ClassName;
  TGraphBufGI.ClassName;
  TLabelGI.ClassName;
  TPanelGI.ClassName;
end;
end.
