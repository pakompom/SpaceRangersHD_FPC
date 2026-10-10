unit Robot;

{$I GameOptions.inc}

interface

uses
  Dynlibs,
  GameWindow,
  Types,
  GR_Sound,
  GR_GraphBuf,
  aGalaxyStruct;

type

  PointerToTRobotTextImage = ^TRobotTextImage;

  PointerToTRobotCallbacks = ^TRobotCallbacks;

  PointerToTRobotDisplaySettingsPrefix = ^TRobotDisplaySettingsPrefix;

  PointerToTRobotInterfacePrefix = ^TRobotInterfacePrefix;

  TRobotTextImage = record
    Buffer: TGraphBufGR;
    Pixels: Pointer;
    Pitch: Integer;
    Width: Integer;
    Height: Integer;
  end;

  PRobotTextImage = PointerToTRobotTextImage;

  TRobotPlaySound = procedure(Name: PWideChar); stdcall;

  TRobotCreateSound =
      function(Name: PWideChar; Group: Integer; Looping: Integer): TSoundBufferControl; stdcall;

  TRobotSoundAction = procedure(Sound: TSoundBufferControl); stdcall;

  TRobotSoundQuery = function(Sound: TSoundBufferControl): Integer; stdcall;

  TRobotSoundSetValue = procedure(Sound: TSoundBufferControl; Value: Single); stdcall;

  TRobotSoundGetValue = function(Sound: TSoundBufferControl): Single; stdcall;

  TRobotRenderText =
      procedure(
          Text: PWideChar;
          FontName: PWideChar;
          Color: Cardinal;
          Width: Integer;
          Height: Integer;
          AlignX: Integer;
          AlignY: Integer;
          Wrap: Integer;
          OffsetX: Integer;
          OffsetY: Integer;
          Clip: PRect;
          Image: PRobotTextImage
      ); stdcall;

  TRobotFreeText = procedure(Image: PRobotTextImage); stdcall;

  TRobotProgress = procedure(Fraction: Single); stdcall;

  TRobotAction = procedure; stdcall;

  TRobotGetVolume = function: Single; stdcall;

  TRobotSetVolume = procedure(Value: Single); stdcall;

  TRobotCallbacks = record
    PlaySound: TRobotPlaySound;
    CreateSound: TRobotCreateSound;
    FreeSound: TRobotSoundAction;
    StartSound: TRobotSoundAction;
    IsSoundPlaying: TRobotSoundQuery;
    SetSoundVolume: TRobotSoundSetValue;
    SetSoundPan: TRobotSoundSetValue;
    GetSoundVolume: TRobotSoundGetValue;
    GetSoundPan: TRobotSoundGetValue;
    RenderText: TRobotRenderText;
    FreeText: TRobotFreeText;
    SetProgress: TRobotProgress;
    PlayMusic: TRobotAction;
    ReleaseTextures: TRobotAction;
    GetMusicVolume: TRobotGetVolume;
    SetMusicVolume: TRobotSetVolume;
  end;

  PRobotCallbacks = PointerToTRobotCallbacks;

  TRobotDisplaySettingsPrefix = record
    Direct3D: Pointer;
    Device: Pointer;
    ShowStencilShadows: Boolean;
    ShowProjShadows: Boolean;
    SelectEx: Boolean;
    LandTexturesGloss: Boolean;
    ObjTexturesGloss: Boolean;
    SoftwareCursor: Boolean;
    Sky: Byte;
    RobotShadow: Byte;
    ColorDepth: Integer;
    ScreenWidth: Integer;
    ScreenHeight: Integer;
    RefreshRate: Integer;
    Brightness: Single;
    Contrast: Single;
    FSAASamples: Integer;
    Anisotropy: Integer;
    MaxDistance: Single;
    VSync: Boolean;
  end;

  PRobotDisplaySettings = PointerToTRobotDisplaySettingsPrefix;

  TRobotInitialize = procedure(Callbacks: PRobotCallbacks); stdcall;

  TRobotSupportQuery = function: Integer; stdcall;

  TRobotRun =
      function(
          Instance: Cardinal;
          Window: Cardinal;
          MapName: PWideChar;
          Settings: PRobotDisplaySettings;
          Language: PWideChar;
          StartText: PWideChar;
          WinText: PWideChar;
          LossText: PWideChar;
          TerronName: PWideChar;
          Statistics: PPlanetBattleStatistics
      ): Integer; stdcall;

  TRobotInterfacePrefix = record
    Initialize: TRobotInitialize;
    Finalize: TRobotAction;
    Support: TRobotSupportQuery;
    Run: TRobotRun;
  end;

  PRobotInterfacePrefix = PointerToTRobotInterfacePrefix;

  TGetRobotInterface = function: PRobotInterfacePrefix; stdcall;

var

  RobotInterface: PRobotInterfacePrefix = nil;

  RobotCallbacks: TRobotCallbacks;

  RobotBattleStatistics: TPlanetBattleStatistics;

  SupportedMultiSamples: array of Integer;

  RobotSettings: TRobotDisplaySettingsPrefix = (
      Direct3D: nil;
      Device: nil;
      ShowStencilShadows: True;
      ShowProjShadows: True;
      SelectEx: False;
      LandTexturesGloss: True;
      ObjTexturesGloss: True;
      SoftwareCursor: False;
      Sky: 2;
      RobotShadow: 1;
      ColorDepth: 32;
      ScreenWidth: 1024;
      ScreenHeight: 768;
      RefreshRate: 0;
      Brightness: 0.5;
      Contrast: 0.5;
      FSAASamples: 0;
      Anisotropy: 0;
      MaxDistance: 0;
      VSync: False
  );

  RobotSound: Boolean = True;

  RobotMusic: Boolean = True;

  RobotVSync: Boolean = False;

  RobotFSAASamples: Integer = 0;

  RobotAnisotropy: Integer = 0;

  RobotMaxDistance: Integer = 0;

  SupportedMultiSampleCount: Integer = 0;

  MaximumAnisotropy: Cardinal = 0;

  RobotModule: TLibHandle = 0;

function GetRobotMultiSampleIndex: Integer;

procedure InitializeRobotRuntime;

procedure FinalizeRobotRuntime;

procedure RobotPlaySound(Name: PWideChar); stdcall;

function RobotCreateSound(
    Name: PWideChar;
    Group: Integer;
    Looping: Integer
): TSoundBufferControl; stdcall;

procedure RobotFreeSound(Sound: TSoundBufferControl); stdcall;

procedure RobotStartSound(Sound: TSoundBufferControl); stdcall;

function RobotIsSoundPlaying(Sound: TSoundBufferControl): Integer; stdcall;

procedure RobotSetSoundVolume(Sound: TSoundBufferControl; Value: Single); stdcall;

procedure RobotSetSoundPan(Sound: TSoundBufferControl; Value: Single); stdcall;

function RobotGetSoundVolume(Sound: TSoundBufferControl): Single; stdcall;

function RobotGetSoundPan(Sound: TSoundBufferControl): Single; stdcall;

procedure RobotRenderText(
    Text: PWideChar;
    FontName: PWideChar;
    Color: Cardinal;
    Width: Integer;
    Height: Integer;
    AlignX: Integer;
    AlignY: Integer;
    Wrap: Integer;
    OffsetX: Integer;
    OffsetY: Integer;
    Clip: PRect;
    Image: PRobotTextImage
); stdcall;

procedure RobotFreeText(Image: PRobotTextImage); stdcall;

procedure RobotSetProgress(Fraction: Single); stdcall;

function RobotGetMusicVolume: Single; stdcall;

procedure RobotSetMusicVolume(Value: Single); stdcall;

procedure RobotPlayMusic; stdcall;

procedure RobotReleaseTextures; stdcall;

function FRun(
    const MapName: WideString;
    const StartText: WideString;
    const WinText: WideString;
    const LossText: WideString;
    const TerronName: WideString
): Integer;

implementation

uses
  GameSystem,
  GR_Main,
  GlobalsV,
  EC_Mem,
  EC_Str,
  GR_Music,
  GR_DX,
  fPanelLoad,
  SysUtils,
  Classes,
  EC_Cache,
  EC_CacheFont,
  GI_MessageLoop,
  EC_HsFile,
{$IFDEF UNIX}
  BaseUnix,
  GameInput,
{$ENDIF}
  aGalaxy;

{$IFDEF UNIX}
// Native planetary battles: the MatrixGame engine runs as a separate process
// (matrixgame-rs). The interface below mirrors the four MatrixGame.dll entry
// points; Run passes its arguments through MG_* environment variables and
// reads the exit state and player statistics back from a result file.

var
  NativeRobotInterface: TRobotInterfacePrefix;
  NativeRobotEngine: AnsiString;
  NativeRobotGameRoot: AnsiString;

function FindNativeRobotEngine: AnsiString;
begin
  Result := GetEnvironmentVariable('SR_MATRIXGAME');
  if Result = '' then
    Result := ExtractFilePath(ParamStr(0)) + 'matrixgame-rs';
  if not FileExists(Result) then
    Result := '';
end;

procedure NativeRobotInitialize(Callbacks: PRobotCallbacks); stdcall;
begin
end;

procedure NativeRobotFinalize; stdcall;
begin
end;

function NativeRobotSupport: Integer; stdcall;
begin
  Result := 0;
end;

procedure WriteNativeRobotText(const FileName: AnsiString; Text: PWideChar);
var
  Stream: TFileStream;
  Data: UTF8String;
begin
  Data := UTF8Encode(WideString(Text));
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    if Data <> '' then
      Stream.WriteBuffer(Data[1], Length(Data));
  finally
    Stream.Free;
  end;
end;

function NativeRobotRun(
    Instance: Cardinal;
    Window: Cardinal;
    MapName: PWideChar;
    Settings: PRobotDisplaySettings;
    Language: PWideChar;
    StartText: PWideChar;
    WinText: PWideChar;
    LossText: PWideChar;
    TerronName: PWideChar;
    Statistics: PPlanetBattleStatistics
): Integer; stdcall;
var
  Root, Prefix, ResultFile, EngineLog: AnsiString;
  Environment, Lines: TStringList;
  Arguments, EnvironmentBlock: array of PAnsiChar;
  MapArgument: AnsiString;
  VolumeText: AnsiString;
  Index, Status: Integer;
  LogHandle: cint;
  Child, Waited: TPid;
  Message: TGameMessage;
begin
  // 1 = back to the game without a win, as when the battle is cancelled.
  Result := 1;
  Root := IncludeTrailingPathDelimiter(NativeRobotGameRoot);
  Prefix := IncludeTrailingPathDelimiter(GetTempDir(False)) + 'srhd-battle-' + IntToStr(FpGetPid);
  ResultFile := Prefix + '-result.txt';
  EngineLog := Prefix + '-engine.log';
  DeleteFile(ResultFile);
  WriteNativeRobotText(Prefix + '-begin.txt', StartText);
  WriteNativeRobotText(Prefix + '-win.txt', WinText);
  WriteNativeRobotText(Prefix + '-loss.txt', LossText);
  MapArgument := UTF8Encode(WideString(MapName));

  Environment := TStringList.Create;
  Lines := TStringList.Create;
  try
    for Index := 1 to GetEnvironmentVariableCount do
      Environment.Add(GetEnvironmentString(Index));
    Environment.Add('MG_PKG=' + AnsiString(NativeGamePath(Root + 'DATA\robots.pkg')));
    Environment.Add(
        'MG_DAT='
            + AnsiString(
                NativeGamePath(Root + 'CFG\' + UTF8Encode(WideString(Language)) + '\robots.dat')
            )
    );
    Environment.Add(
        'MG_SOUND_PKGS='
            + AnsiString(NativeGamePath(Root + 'DATA\Sound.pkg'))
            + ':'
            + AnsiString(
                NativeGamePath(Root + 'DATA\voices' + UTF8Encode(WideString(Language)) + '.pkg')
            )
    );
    if RobotSound then
      Str(SoundVolume:0:3, VolumeText)
    else
      VolumeText := '0';
    Environment.Add('MG_SOUND_VOL=' + VolumeText);
    Environment.Add('MG_TXT_BEGIN=' + Prefix + '-begin.txt');
    Environment.Add('MG_TXT_WIN=' + Prefix + '-win.txt');
    Environment.Add('MG_TXT_LOSS=' + Prefix + '-loss.txt');
    Environment.Add('MG_RESULT=' + ResultFile);
    Environment.Add('MG_WIDTH=' + IntToStr(Settings.ScreenWidth));
    Environment.Add('MG_HEIGHT=' + IntToStr(Settings.ScreenHeight));
    if not Direct3DPresentParameters.Windowed then
      Environment.Add('MG_FULLSCREEN=1');
    if Environment.IndexOfName('RUST_LOG') < 0 then
      Environment.Add('RUST_LOG=info');

    SetLength(EnvironmentBlock, Environment.Count + 1);
    for Index := 0 to Environment.Count - 1 do
      EnvironmentBlock[Index] := PAnsiChar(Environment.Strings[Index]);
    EnvironmentBlock[Environment.Count] := nil;
    SetLength(Arguments, 3);
    Arguments[0] := PAnsiChar(NativeRobotEngine);
    Arguments[1] := PAnsiChar(MapArgument);
    Arguments[2] := nil;

    AppendLogLineThreadSafe('Starting native MatrixGame: ' + NativeRobotEngine + ' ' + MapArgument);
    Child := FpFork;
    if Child = 0 then
    begin
      LogHandle := FpOpen(PAnsiChar(EngineLog), O_WRONLY or O_CREAT or O_TRUNC, &644);
      if LogHandle >= 0 then
        FpDup2(LogHandle, 2);
      FpExecve(PAnsiChar(NativeRobotEngine), @Arguments[0], @EnvironmentBlock[0]);
      FpExit(127);
    end;
    if Child < 0 then
      raise Exception.Create('Cannot start native MatrixGame');

    // The soundtrack stays with the game: the engine process only plays effects.
    RobotPlayMusic;
    // Keep the game window responsive while the battle owns the screen.
    repeat
      Waited := FpWaitPid(Child, Status, WNOHANG);
      if Waited = 0 then
      begin
        while PollGameMessage(Message) do
          ;
        Sleep(30);
      end;
    until (Waited = Child) or ((Waited < 0) and (fpgeterrno <> ESysEINTR));

    if FileExists(ResultFile) then
    begin
      Lines.LoadFromFile(ResultFile);
      Result := StrToIntDef(Lines.Values['exit'], 1);
      Statistics.SignedTimeMs := StrToIntDef(Lines.Values['time'], 0);
      Statistics.RobotsBuilt := StrToIntDef(Lines.Values['robot_build'], 0);
      Statistics.RobotsDestroyed := StrToIntDef(Lines.Values['robot_kill'], 0);
      Statistics.TurretsBuilt := StrToIntDef(Lines.Values['turret_build'], 0);
      Statistics.TurretsDestroyed := StrToIntDef(Lines.Values['turret_kill'], 0);
      Statistics.BuildingsDestroyed := StrToIntDef(Lines.Values['building_kill'], 0);
      // The engine reports surrender as 4; the game only knows loss.
      if Result = 4 then
        Result := 2;
      // 0 would terminate the whole game; a closed battle returns to it.
      if Result = 0 then
        Result := 1;
    end
    else
      AppendLogLineThreadSafe(
          'Native MatrixGame left no result, wait status=' + IntToStr(Status)
      );
    AppendLogLineThreadSafe('Native MatrixGame finished, result=' + IntToStr(Result));
  finally
    Environment.Free;
    Lines.Free;
    DeleteFile(Prefix + '-begin.txt');
    DeleteFile(Prefix + '-win.txt');
    DeleteFile(Prefix + '-loss.txt');
    DeleteFile(ResultFile);
  end;
end;
{$ENDIF}

function GetRobotMultiSampleIndex: Integer;
var
  I: Integer;
begin
  for I := 0 to SupportedMultiSampleCount - 1 do
    if SupportedMultiSamples[I] = RobotFSAASamples then
    begin
      Result := I;
      Exit;
    end;
  Result := 0;
end;

procedure InitializeRobotRuntime;
var
  GetInterface: TGetRobotInterface;
  OverrideName: WideString;
  Callbacks: PRobotCallbacks;
begin
  FinalizeRobotRuntime;
  if IsInstallFeatureEnabled('Robot') then
  begin
    Callbacks := @RobotCallbacks;
    FillChar(Callbacks^, SizeOf(TRobotCallbacks), 0);
    RobotCallbacks.PlaySound := RobotPlaySound;
    RobotCallbacks.CreateSound := RobotCreateSound;
    RobotCallbacks.FreeSound := RobotFreeSound;
    RobotCallbacks.StartSound := RobotStartSound;
    RobotCallbacks.IsSoundPlaying := RobotIsSoundPlaying;
    RobotCallbacks.SetSoundVolume := RobotSetSoundVolume;
    RobotCallbacks.SetSoundPan := RobotSetSoundPan;
    RobotCallbacks.GetSoundVolume := RobotGetSoundVolume;
    RobotCallbacks.GetSoundPan := RobotGetSoundPan;
    RobotCallbacks.RenderText := RobotRenderText;
    RobotCallbacks.FreeText := RobotFreeText;
    RobotCallbacks.SetProgress := RobotSetProgress;
    RobotCallbacks.PlayMusic := RobotPlayMusic;
    RobotCallbacks.ReleaseTextures := RobotReleaseTextures;
    RobotCallbacks.GetMusicVolume := RobotGetMusicVolume;
    RobotCallbacks.SetMusicVolume := RobotSetMusicVolume;
{$IF Defined(MSWINDOWS) and Defined(CPU386)}
    if DirectXVersion >= $90000 then
    begin
      if LanguageDataConfig.GetBlock('RobotsMap').CountParams('MatrixOverride') > 0 then
      begin
        OverrideName := LanguageDataConfig.GetBlock('RobotsMap').GetParam('MatrixOverride');
        RobotModule := LoadLibrary(UTF8Encode(OverrideName));
      end
      else
        RobotModule := LoadLibrary('MatrixGame.dll');
      if RobotModule <> 0 then
      begin
        GetInterface := GetProcAddress(RobotModule, 'GetRobotInterface');
        if GetInterface() = nil then
        begin
          FreeLibrary(RobotModule);
          RobotModule := 0;
        end
        else
        begin
          RobotInterface := GetInterface();
          RobotInterface.Initialize(@RobotCallbacks);
          AppendLogLineThreadSafe('Load MatrixGame.dll .... ok');
          AppendLogLineThreadSafe(
              AnsiString('Robot.Support()=' + IntToWideString(RobotInterface.Support()))
          );
        end;
      end;
    end;
{$ELSEIF Defined(UNIX)}
    NativeRobotEngine := FindNativeRobotEngine;
    if NativeRobotEngine <> '' then
    begin
      NativeRobotInterface.Initialize := NativeRobotInitialize;
      NativeRobotInterface.Finalize := NativeRobotFinalize;
      NativeRobotInterface.Support := NativeRobotSupport;
      NativeRobotInterface.Run := NativeRobotRun;
      RobotInterface := @NativeRobotInterface;
      RobotInterface.Initialize(@RobotCallbacks);
      AppendLogLineThreadSafe('Load native MatrixGame .... ok: ' + NativeRobotEngine);
    end
    else
      AppendLogLineThreadSafe('Native MatrixGame not found; planetary battles are disabled');
{$ENDIF}
  end;
end;

procedure FinalizeRobotRuntime;
begin
  if RobotInterface <> nil then
  begin
    RobotInterface.Finalize;
    RobotInterface := nil;
    if RobotModule <> 0 then
    begin
      FreeLibrary(RobotModule);
      RobotModule := 0;
    end;
  end;
end;

procedure RobotPlaySound(Name: PWideChar); stdcall;
begin
  SoundManager.PlaySound(WideString(Name));
end;

function RobotCreateSound(Name: PWideChar; Group, Looping: Integer): TSoundBufferControl; stdcall;
var
  Sound: TSoundBufferControl;
begin
  Sound := TSoundBufferControl.Create;
  if RobotSound then
    Sound.Configure(WideString(Name), Group, Looping <> 0);
  Result := Sound;
end;

procedure RobotFreeSound(Sound: TSoundBufferControl); stdcall;
begin
  if Sound <> nil then
    Sound.Free;
end;

procedure RobotStartSound(Sound: TSoundBufferControl); stdcall;
begin
  if Sound <> nil then
    if RobotSound then
      Sound.Play;
end;

function RobotIsSoundPlaying(Sound: TSoundBufferControl): Integer; stdcall;
begin
  Result := 0;
  if Sound <> nil then
    Result := Integer(Sound.IsPlaying);
end;

procedure RobotSetSoundVolume(Sound: TSoundBufferControl; Value: Single); stdcall;
begin
  if Sound <> nil then
    Sound.SetVolume(Value);
end;

procedure RobotSetSoundPan(Sound: TSoundBufferControl; Value: Single); stdcall;
begin
  if Sound <> nil then
    Sound.SetPan(Value);
end;

function RobotGetSoundVolume(Sound: TSoundBufferControl): Single; stdcall;
begin
  if Sound = nil then
    Result := 0
  else
    Result := Sound.Volume;
end;

function RobotGetSoundPan(Sound: TSoundBufferControl): Single; stdcall;
begin
  if Sound = nil then
    Result := 0
  else
    Result := Sound.Pan;
end;

function CenterSpan(SpanStart, SpanEnd, ContentStart, ContentEnd: Integer): Integer; inline;
begin
  Result := SpanStart + (SpanEnd - SpanStart) div 2 - (ContentEnd - ContentStart) div 2;
end;

procedure RobotRenderText(
    Text, FontName: PWideChar;
    Color: Cardinal;
    Width, Height, AlignX, AlignY, Wrap, OffsetX, OffsetY: Integer;
    Clip: PRect;
    Image: PRobotTextImage
); stdcall;
var
  TopAdjustment: Integer;
  Lines: TStringsEC;
  Font: TCFontEC;
  WrappedLines: TStringsEC;
  Buffer: TGraphBufGR;
  Control: TCFontControlEC;
  DrawX, DrawY, CurrentY: Integer;
  ImageSize: TPoint;
  DrawClip, Bounds, SourceClip: TRect;

  function MeasureRobotTextSize: TPoint;
  var
    Y: Integer;
    First: Boolean;
    MergedBounds, LineBounds: TRect;
  begin
    MergedBounds.Left := 0;
    MergedBounds.Right := 0;
    MergedBounds.Top := 0;
    MergedBounds.Bottom := 0;
    Y := 0;
    Lines.First;
    if Wrap = 0 then
    begin
      if not Lines.IsAtEnd then
      begin
        MergedBounds := Font.MeasureTaggedTextBounds(Lines.GetCurrentText, 0, Y, @TopAdjustment);
        Inc(Y, Font.GetLineHeight);
        Lines.Next;
      end;
      while not Lines.IsAtEnd do
      begin
        LineBounds := Font.MeasureTaggedTextBounds(Lines.GetCurrentText, 0, Y, nil);
        Types.UnionRect(MergedBounds, MergedBounds, LineBounds);
        Inc(Y, Font.GetLineHeight);
        Lines.Next;
      end;
    end
    else
    begin
      First := True;
      while not Lines.IsAtEnd do
      begin
        Font.WrapTaggedTextIntoLines(WrappedLines, Lines.GetCurrentText, Width - 4);
        if not WrappedLines.IsEmpty then
        begin
          WrappedLines.First;
          if First then
          begin
            MergedBounds :=
                Font.MeasureTaggedTextBounds(WrappedLines.GetCurrentText, 0, Y, @TopAdjustment);
            First := False;
            Inc(Y, Font.GetLineHeight);
            WrappedLines.Next;
          end;
          while not WrappedLines.IsAtEnd do
          begin
            LineBounds := Font.MeasureTaggedTextBounds(WrappedLines.GetCurrentText, 0, Y, nil);
            Types.UnionRect(MergedBounds, MergedBounds, LineBounds);
            Inc(Y, Font.GetLineHeight);
            WrappedLines.Next;
          end;
        end;
        Lines.Next;
      end;
    end;
    Result :=
        Classes
            .Point(MergedBounds.Right - MergedBounds.Left, MergedBounds.Bottom - MergedBounds.Top);
  end;

begin
  Control := nil;
  Font := nil;
  Lines := nil;
  WrappedLines := nil;
  try
    Lines := TStringsEC.Create;
    Lines.SetText(WideString(Text));
    Control := TCFontControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(WideString(FontName));
    Font := AcquireCachedFont(Control);
    Font.ResetTextMeasureState;
    Font.UseARGBColors := True;
    Font.ColorTagsEnabled := False;
    if Wrap <> 0 then
      WrappedLines := TStringsEC.Create;
    if (Width = 0) and (Wrap <> 0) then
      RaiseWideMessage('robot text');
    ImageSize := MeasureRobotTextSize;
    SourceClip := Clip^;
    if Width = 0 then
    begin
      Width := ImageSize.X + 4;
      SourceClip.Right := Width;
    end;
    if Height = 0 then
    begin
      Height := ImageSize.Y + 4;
      SourceClip.Bottom := Height;
    end;
    Buffer := TGraphBufGR.Create(False);
    Buffer.AllocateRgbaTight(Width, Height);
    Buffer.ClearPixels;
    Image.Buffer := Buffer;
    Image.Pixels := Buffer.GetPixels;
    Image.Pitch := Buffer.PitchBytes;
    Image.Width := Buffer.Width;
    Image.Height := Buffer.Height;
    DrawClip := Classes.Rect(0, 0, Width, Height);
    if not Types.IntersectRect(DrawClip, DrawClip, SourceClip) then
      Exit;
    DrawX := 0;
    DrawY := 0;
    if (AlignX = 0) or (Wrap <> 0) then
      DrawX := 2
    else if AlignX = 2 then
      DrawX := Width - ImageSize.X - 2
    else if AlignX = 1 then
      DrawX := Width div 2 - ImageSize.X div 2
    else if AlignX = 3 then
      DrawX := 2;
    if AlignY = 0 then
      DrawY := TopAdjustment + 2
    else if AlignY = 2 then
      DrawY := Height - ImageSize.Y - 2 + TopAdjustment
    else if AlignY = 1 then
      DrawY := Height div 2 - ImageSize.Y div 2 + TopAdjustment
    else if AlignY = 3 then
      DrawY := TopAdjustment + 2;
    Font.ColorTagsEnabled := True;
    Font.DefaultColor := Color;
    if Wrap = 0 then
    begin
      if AlignY = 1 then
        CurrentY :=
            Height div 2
                - (Font.GetLineHeight * (Lines.GetCount - 1) + Font.GetCenteringHeight) div 2
                + Font.GetCenteringHeight
      else
        CurrentY := Font.AboveBaseline + DrawY - 2;
      Lines.First;
      while not Lines.IsAtEnd do
      begin
        Font.DrawTaggedText32(
            Buffer.GetPixels,
            Buffer.PitchBytes,
            DrawX + OffsetX,
            CurrentY + OffsetY,
            Lines.GetCurrentText,
            DrawClip
        );
        Inc(CurrentY, Font.GetLineHeight);
        Lines.Next;
      end;
    end
    else
    begin
      CurrentY := Font.AboveBaseline + DrawY - 2;
      Lines.First;
      while not Lines.IsAtEnd do
      begin
        Font.WrapTaggedTextIntoLines(WrappedLines, Lines.GetCurrentText, Width - 4);
        WrappedLines.First;
        while not WrappedLines.IsAtEnd do
        begin
          if AlignX = 0 then
            Font.DrawTaggedText32(
                Buffer.GetPixels,
                Buffer.PitchBytes,
                DrawX + OffsetX,
                CurrentY + OffsetY,
                WrappedLines.GetCurrentText,
                DrawClip
            )
          else if AlignX = 2 then
          begin
            Bounds := Font.MeasureTaggedTextBounds(WrappedLines.GetCurrentText, 0, 0, nil);
            Font.DrawTaggedText32(
                Buffer.GetPixels,
                Buffer.PitchBytes,
                Width - (Bounds.Right - Bounds.Left) - 2 + OffsetX,
                CurrentY + OffsetY,
                WrappedLines.GetCurrentText,
                DrawClip
            );
          end
          else if AlignX = 1 then
          begin
            Bounds := Font.MeasureTaggedTextBounds(WrappedLines.GetCurrentText, 0, 0, nil);
            Font.DrawTaggedText32(
                Buffer.GetPixels,
                Buffer.PitchBytes,
                CenterSpan(0, Width, Bounds.Left, Bounds.Right) + OffsetX,
                CurrentY + OffsetY,
                WrappedLines.GetCurrentText,
                DrawClip
            );
          end
          else if (AlignX = 3) and not WrappedLines.IsAtLast then
            Font.DrawJustifiedTaggedText32(
                Buffer.GetPixels,
                Buffer.PitchBytes,
                DrawX + OffsetX,
                CurrentY + OffsetY,
                WrappedLines.GetCurrentText,
                Width - 4,
                DrawClip
            )
          else
            Font.DrawTaggedText32(
                Buffer.GetPixels,
                Buffer.PitchBytes,
                DrawX + OffsetX,
                CurrentY + OffsetY,
                WrappedLines.GetCurrentText,
                DrawClip
            );
          Inc(CurrentY, Font.GetLineHeight);
          WrappedLines.Next;
        end;
        Lines.Next;
      end;
    end;
  finally
    if Font <> nil then
      Control.Release;
    if Control <> nil then
      Control.Free;
    if Lines <> nil then
      Lines.Free;
    if WrappedLines <> nil then
      WrappedLines.Free;
  end;
end;

procedure RobotFreeText(Image: PRobotTextImage); stdcall;
begin
  if Image.Buffer <> nil then
    Image.Buffer.Free;
  FillChar(Image^, SizeOf(TRobotTextImage), 0);
end;

procedure RobotSetProgress(Fraction: Single); stdcall;
var
  Panel: TfPanelLoad;
begin
  if Direct3DDevice <> nil then
    if ActiveLoadPanel <> nil then
    begin
      Panel := ActiveLoadPanel;
      Panel.SelectBackgroundStyle(3);
      Panel.RefreshBackgroundImages;
      Panel.SetShutterOpenFraction(0);
      Panel.SetProgress(Fraction);
      Panel.Show;
      TMessageLoopGI(RegisteredScreens[CurrentScreenId]).SetCursorActive(False);
      TMessageLoopGI(RegisteredScreens[CurrentScreenId]).InvalidateViewport;
      TMessageLoopGI(RegisteredScreens[CurrentScreenId]).Present;
      Panel.Hide;
    end;
end;

function RobotGetMusicVolume: Single; stdcall;
begin
  Result := MusicVolumeScale;
end;

procedure RobotSetMusicVolume(Value: Single); stdcall;
var
  Buffer: TSoundBuffer;
begin
  MusicVolumeScale := Value;
  if SoundManager <> nil then
  begin
    Buffer := SoundManager.FirstBuffer;
    while Buffer <> nil do
    begin
      if Buffer.Streaming then
        Buffer.SetVolume(MusicVolume * MusicVolumeScale);
      Buffer := Buffer.Next;
    end;
  end;
end;

procedure RobotPlayMusic; stdcall;
begin
  if MusicEnabled and RobotMusic and not MusicManager.HasSelectedMusic then
  begin
    MusicManager.HasSelectedMusic;
    MusicManager.PlayCategory('Robot');
  end;
end;

procedure RobotReleaseTextures; stdcall;
begin
  ReleaseAllTextureSurfaces;
end;

function FRun(const MapName, StartText, WinText, LossText, TerronName: WideString): Integer;
var
  SavedDirectory, RobotDirectory: AnsiString;
  SavedSoundVolume, SavedMusicVolume: Single;
  Failed: Boolean;
  CursorState: TCursorStateGI;
  Memory: TMemoryStatusEx;
begin
  if MusicEnabled and MusicManager.HasSelectedMusic then
    MusicManager.RequestFadeOut;
  AppendLogLineThreadSafe('Preparing to start planetary battle');
  SavedDirectory := GetCurrentDir;
{$IFDEF UNIX}
  NativeRobotGameRoot := SavedDirectory;
{$ENDIF}
  LooseFileRoot := SavedDirectory + '\';
  try
    TMessageLoopGI(RegisteredScreens[CurrentScreenId]).CaptureCursorState(@CursorState);
    if InstallConfig.CountParams('RobotPath') > 0 then
    begin
      SetCurrentDir(NativeGamePath(AnsiString(InstallConfig.GetParam('RobotPath'))));
      RobotDirectory := GetCurrentDir;
    end;
    RobotSetProgress(0);
    Memory.Length := SizeOf(Memory);
    QueryGameMemory(Memory);
    if MemorySnapshotActive or (Galaxy <> nil) or ((Int64(Memory.AvailPhys) shr 30) <= 0) then
      GlobalCache.TrimToBudget(0);
    Result := 1;
    SavedSoundVolume := SoundVolume;
    SavedMusicVolume := MusicVolume;
    SoundVolume := RobotSoundVolume;
    MusicVolume := RobotMusicVolume;
    RobotSettings.Brightness := RobotBrightness / 2 + 0.5;
    RobotSettings.Contrast := RobotContrast / 2 + 0.5;
    RobotSettings.ColorDepth := 32;
    if Direct3DPresentParameters.Windowed then
    begin
      if AlternateViewportEnabled then
      begin
        RobotSettings.ScreenWidth := PresentationWidth;
        RobotSettings.ScreenHeight := PresentationHeight;
      end
      else
      begin
        RobotSettings.ScreenWidth := GameScreenWidth;
        RobotSettings.ScreenHeight := GameScreenHeight;
      end;
      RobotSettings.RefreshRate := 0;
    end
    else
    begin
      if RobotDisplayModes[SelectedRobotDisplayMode].Width = 0 then
      begin
        if AlternateViewportEnabled then
        begin
          RobotSettings.ScreenWidth := PresentationWidth;
          RobotSettings.ScreenHeight := PresentationHeight;
        end
        else
        begin
          RobotSettings.ScreenWidth := GameScreenWidth;
          RobotSettings.ScreenHeight := GameScreenHeight;
        end;
        RobotSettings.RefreshRate := GameDisplayModes[SelectedGameDisplayMode].RefreshRate;
      end
      else
      begin
        RobotSettings.ScreenWidth := RobotDisplayModes[SelectedRobotDisplayMode].Width;
        RobotSettings.ScreenHeight := RobotDisplayModes[SelectedRobotDisplayMode].Height;
        RobotSettings.RefreshRate := RobotDisplayModes[SelectedRobotDisplayMode].RefreshRate;
      end;
    end;
    RobotSettings.VSync := RobotVSync;
    RobotSettings.FSAASamples := RobotFSAASamples;
    RobotSettings.Anisotropy := RobotAnisotropy;
    RobotSettings.MaxDistance := RobotMaxDistance / 100;
    RobotBattleStatistics.SignedTimeMs := 0;
    RobotBattleStatistics.RobotsBuilt := 0;
    RobotBattleStatistics.RobotsDestroyed := 0;
    RobotBattleStatistics.TurretsBuilt := 0;
    RobotBattleStatistics.TurretsDestroyed := 0;
    RobotBattleStatistics.BuildingsDestroyed := 0;
    RobotSettings.Direct3D := Pointer(Direct3D);
    RobotSettings.Device := Pointer(Direct3DDevice);
    AppendLogLineThreadSafe('Starting planetary battle');
    RobotBattleActive := True;
    Failed := False;
    try
      if RobotInterface <> nil then
      begin
        if LanguageDataConfig.GetBlock('RobotsMap').CountParams('CfgOverride') > 0 then
          Result :=
              RobotInterface.Run(
                  HInstance,
                  MainWindowHandle,
                  PWideChar(MapName),
                  @RobotSettings,
                  PWideChar(LanguageDataConfig.GetBlock('RobotsMap').GetParam('CfgOverride')),
                  PWideChar(StartText),
                  PWideChar(WinText),
                  PWideChar(LossText),
                  PWideChar(TerronName),
                  @RobotBattleStatistics
              )
        else
          Result :=
              RobotInterface.Run(
                  HInstance,
                  MainWindowHandle,
                  PWideChar(MapName),
                  @RobotSettings,
                  PWideChar(LanguageInstallConfig.GetParam('Lang')),
                  PWideChar(StartText),
                  PWideChar(WinText),
                  PWideChar(LossText),
                  PWideChar(TerronName),
                  @RobotBattleStatistics
              );
      end;
    except
      on E: Exception do
      begin
        AppendLogLineThreadSafe(E.ClassName + ' ' + E.Message);
        Failed := True;
      end;
    end;
    if Result >= 100 then
    begin
      Dec(Result, 100);
      if Result >= 1 then
        AppendLogLineThreadSafe('Warning! There was an error on exit from planetary battle!');
      if Result = 0 then
        Failed := True;
    end;
    RobotBattleActive := False;
    AppendLogLineThreadSafe('Planetary battle finished');
    GR_DXReset;
    SetGameWindowTitle('Rangers');
    ApplyGammaRamp(DisplayBrightness, DisplayContrast);
    SoundVolume := SavedSoundVolume;
    MusicVolume := SavedMusicVolume;
    MusicVolumeScale := 1;
    if (Result = 0) and not Failed then
    begin
      ExitScreenLoop := True;
      RequestedScreenId := screenNone;
      TMessageLoopGI(RegisteredScreens[CurrentScreenId]).RequestClose(1);
      Result := 0;
      Exit;
    end;
    TMessageLoopGI(RegisteredScreens[CurrentScreenId]).RestoreCursorState(@CursorState);
    if ShowSystemMouse then
      while ShowGameCursor(True) < 0 do
    else
      while ShowGameCursor(False) >= 0 do
        ;
    TMessageLoopGI(RegisteredScreens[CurrentScreenId]).InvalidateViewport;
  finally
    SetCurrentDir(NativeGamePath(SavedDirectory));
    LooseFileRoot := '';
  end;
  AppendLogLineThreadSafe('Cleanup after planetary battle finished');
  if MusicEnabled and MusicManager.HasSelectedMusic then
    MusicManager.RequestFadeOut;
  if Failed then
    raise Exception.Create('Error in GIRobot.FRun');
end;

end.
