{$EXCESSPRECISION OFF}
unit fCustom;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  GI_MessageLoop,
  EC_BlockPar;
type
  TfCustomLoop = class;
  TfCustomLoop = class(TMessageLoopGI)
    ReservedBeforeText: WideString;
    ReservedAfterText: WideString;
    procedure ProcessCallbackTimers; override;
    procedure InitializeLayout; override;
    procedure ExecuteUiCode(Block: TBlockParEC; Key: Cardinal); override;
  end;
var
  CurrentCustomDialog: TMessageLoopGI = nil;
function ShowCustomDialog(Parent: TMessageLoopGI; const ScreenName: WideString): Integer;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  ThreadCalc,
  aCalc,
  GR_Main,
  Globals,
  GlobalsV,
  GI_GraphBuf,
  aGalaxy,
  aGalaxyStruct,
  aScript;

procedure TfCustomLoop.InitializeLayout;
begin
  inherited;
end;

procedure TfCustomLoop.ProcessCallbackTimers;
begin
  inherited;
  if ParentLoop.ExitCode <> 0 then
    if ExitCode = 0 then
      RequestClose(255);
end;

procedure TfCustomLoop.ExecuteUiCode(Block: TBlockParEC; Key: Cardinal);
begin
  if not ExitScreenLoop
      and (TurnCalculationPhase
          in [tcpIdle, tcpGalaxyFinished, tcpPlayerStarFinished, tcpPlayerStarPrepared]) then
  begin
    if Galaxy <> nil then
      aCalc.WaitForTurnCalculationUI;
    ExecuteGameplayUiCode(Block, Key);
    if Galaxy <> nil then
      aCalc.WaitForTurnCalculationUI;
  end;
end;

function ShowCustomDialog(Parent: TMessageLoopGI; const ScreenName: WideString): Integer;
var
  Dialog: TfCustomLoop;
  Previous: TMessageLoopGI;
  Block: TBlockParEC;
  Background: TObjectGI;
  BeforeCode, AfterCode: WideString;
  State: TCursorStateGI;
begin
  Parent.RootUiObject.NativeHook50;
  Parent.CaptureCursorState(@State);
  Parent.SetCursorActive(False);
  Parent.DrawQueuedUpdateRects;
  CaptureScreenBackground(False, 0);
  Dialog := TfCustomLoop.Create;
  Dialog.ParentLoop := Parent;
  Parent.ChildLoop := Dialog;
  Dialog.InitializeFromConfig(UiStyleConfig, ScreenName, True);
  Block := UiStyleConfig.GetBlock(ScreenName).FindBlock('CodeBeforeRun');
  if Block <> nil then
    BeforeCode := Block.ConcatenateValues
  else
    BeforeCode := '';
  Block := UiStyleConfig.GetBlock(ScreenName).FindBlock('CodeAfterRun');
  if Block <> nil then
    AfterCode := Block.ConcatenateValues
  else
    AfterCode := '';
  Dialog.InitializeLayout;
  Previous := CurrentCustomDialog;
  try
    CurrentCustomDialog := Dialog;
    ExecuteScriptText(BeforeCode, nil);
    Background := Dialog.FindControlByPath('BGBuf');
    if Background <> nil then
    begin
      CaptureScreenBackground(True, 0);
      (Background as TGraphBufGI).BindExternalGraphBuf(AuxRenderBuffer);
    end;
    Result := Dialog.Run;
    ExecuteScriptText(AfterCode, nil);
    Parent.InvalidateViewport;
  finally
    Parent.ChildLoop := nil;
    CurrentCustomDialog := Previous;
    Dialog.Free;
  end;
  Parent.RestoreCursorState(@State);
  Parent.UpdateCursorPosition;
  Parent.RootUiObject.NativeHook48;
end;

procedure LinkRecoveredTypes;
begin
  TGraphBufGI.ClassName;
end;
end.
