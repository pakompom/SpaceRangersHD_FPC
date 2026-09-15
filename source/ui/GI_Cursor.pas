{$EXCESSPRECISION OFF}
unit GI_Cursor;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  GI_Image,
  GI_MessageLoop,
  GR_GraphBuf,
  Types;
type
  TCursorGI = class;
  TCursorGI = class(TObjectGI)
    ImageControl: TImageGI;
    ImagePath: WideString;
    CursorHandles: array of Cardinal;
    FrameIndices: array of Integer;
    FrameDelays: array of Integer;
    FrameIndex: Integer;
    AnimationTimer: PCallbackTimerGI;
    procedure Clear; override;
    procedure SetOrigin(Origin: TPoint); override;
    procedure SetActive(Enabled: Boolean); override;
    procedure Draw(ClipRect: TRect); override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure SetImagePath(const Path: WideString);
    procedure RebuildSystemCursor;
    function CreateCursorBitmap(Buffer: TGraphBufGR): Cardinal;
    procedure AdvanceAnimation(Timer: PCallbackTimerGI; UserData: PtrInt);
  end;
implementation
uses
  Math,
  Classes,
  EC_Cache,
  EC_CacheGAI,
  EC_CacheGI,
  EC_Str,
  GR_Main,
  SysUtils,
  Windows;

constructor TCursorGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  ImageControl := TImageGI.Create(Self);
  Active := False;
end;

destructor TCursorGI.Destroy;
var
  Index: Integer;
begin
  if AnimationTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(AnimationTimer);
    AnimationTimer := nil;
  end;
  for Index := 0 to High(CursorHandles) do
    if CursorHandles[Index] <> 0 then
    begin
      CursorHandles[Index] := 0;
    end;
  ImagePath := '';
  CursorHandles := nil;
  FrameIndices := nil;
  FrameDelays := nil;
  inherited Destroy;
end;

procedure TCursorGI.Clear;
var
  Index: Integer;
begin
  if AnimationTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(AnimationTimer);
    AnimationTimer := nil;
  end;
  for Index := 0 to High(CursorHandles) do
    if CursorHandles[Index] <> 0 then
    begin
      CursorHandles[Index] := 0;
    end;
  ImagePath := '';
  CursorHandles := nil;
  FrameIndices := nil;
  FrameDelays := nil;
  ImageControl.Clear;
end;

procedure TCursorGI.SetImagePath(const Path: WideString);
begin
  Clear;
  ImagePath := Path;
  ImageControl.SetImagePath(Path);
  SetSize(ImageControl.GetContentSize);
  ImageControl.SetSize(ClientSize);
  ImageControl.RestartPlayback
end;

procedure TCursorGI.SetActive(Enabled: Boolean);
begin
  Invalidate;
  inherited SetActive(Enabled);
  ImageControl.SetActive(Enabled);
  ImageControl.RestartPlayback
end;

procedure TCursorGI.SetOrigin(Origin: TPoint);
begin
  inherited SetOrigin(Origin);
  ImageControl.SetPosition(Classes.Point(-Origin.X, -Origin.Y));
  if ShowSystemMouse then
    RebuildSystemCursor;
end;

procedure TCursorGI.Draw(ClipRect: TRect);
begin
  inherited Draw(ClipRect);
end;

procedure TCursorGI.RebuildSystemCursor;
begin
  ImageControl.SetImagePath(ImagePath);
  SetSize(ImageControl.GetContentSize);
  ImageControl.SetSize(ClientSize)
end;

function TCursorGI.CreateCursorBitmap(Buffer: TGraphBufGR): Cardinal;
begin
  raise Exception.Create('System cursor bitmaps are not used by the native software cursor')
end;

procedure TCursorGI.AdvanceAnimation(Timer: PCallbackTimerGI; UserData: PtrInt);
begin
  Inc(FrameIndex);
  if High(FrameIndices) < FrameIndex then
    FrameIndex := 0;
  if AnimationTimer <> nil then
  begin
    MessageLoop.CancelCallbackTimer(AnimationTimer);
    AnimationTimer := nil;
  end;
  AnimationTimer :=
      MessageLoop.ScheduleCallbackTimer(
          FrameDelays[FrameIndex],
          FrameDelays[FrameIndex],
          AdvanceAnimation
      );
end;

end.
