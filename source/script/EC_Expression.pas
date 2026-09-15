{$EXCESSPRECISION OFF}
unit EC_Expression;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  Classes,
  EC_Buf,
  SysUtils,
  Windows;
type
  PointerToInteger = ^Integer;
type
  ExceptionExpressionEC = class;
  TCodeAnalyzerEC = class;
  TCodeAnalyzerUnitEC = class;
  TCodeEC = class;
  TCodeProcessEC = class;
  TCodeUnitEC = class;
  TCompilerEC = class;
  TCompilerUnitEC = class;
  TExpressionEC = class;
  TExpressionInstrEC = class;
  TExpressionVarEC = class;
  TScriptDebugState = class;
  TVarArrayEC = class;
  TVarEC = class;
  PointerToTCodeAnalyzerUnitEC = ^TCodeAnalyzerUnitEC;
  PointerToTVarEC = ^TVarEC;
  PointerToTExpressionVarEC = ^TExpressionVarEC;
  PointerToTExpressionInstrEC = ^TExpressionInstrEC;
  PointerToTCodeExceptionHandler = ^TCodeExceptionHandler;
  ExceptionExpressionEC = class(Exception)
  end;
  TScriptStepCallback = procedure(StatementCount: Integer);
  {$Z1}
  TVarKind = (
      vkEmpty = 0,
      vkInt = 1,
      vkDword = 2,
      vkFloat = 3,
      vkString = 4,
      vkExternFun = 5,
      vkLibraryFun = 6,
      vkFunction = 7,
      vkClass = 8,
      vkArray = 9,
      vkRef = 10
  );
  {$Z4}
  TLibraryValueKind =
      (lvVoid = 0, lvInt = 1, lvDword = 2, lvFloat = 3, lvString = 4, lvRef = 5, lvCode = 6);
  {$Z1}
  TCodeTokenKind = (
      ctNewline = 0,
      ctOpenParen = 1,
      ctCloseParen = 2,
      ctOpenBrace = 3,
      ctCloseBrace = 4,
      ctOpenBracket = 5,
      ctCloseBracket = 6,
      ctBlockCommentStart = 7,
      ctBlockCommentEnd = 8,
      ctLineComment = 9,
      ctDot = 10,
      ctArrow = 11,
      ctAdd = 12,
      ctSubtract = 13,
      ctMultiply = 14,
      ctDivide = 15,
      ctModulo = 16,
      ctBitAnd = 17,
      ctBitOr = 18,
      ctBitXor = 19,
      ctBitNot = 20,
      ctAnd = 21,
      ctOr = 22,
      ctNot = 23,
      ctShiftLeft = 24,
      ctShiftRight = 25,
      ctAssign = 26,
      ctEqual = 27,
      ctNotEqual = 28,
      ctLess = 29,
      ctGreater = 30,
      ctLessEqual = 31,
      ctGreaterEqual = 32,
      ctSemicolon = 33,
      ctColon = 34,
      ctComma = 35,
      ctWhitespace = 36,
      ctStringLiteral = 37,
      ctText = 38
  );
  {$Z1}
  TCompilerUnitKind = (
      cuIntLiteral = 0,
      cuDwordLiteral = 1,
      cuFloatLiteral = 2,
      cuStringLiteral = 3,
      cuBinaryOperator = 4,
      cuUnaryOperator = 5,
      cuOpenParen = 6,
      cuCloseParen = 7,
      cuOpenBracket = 8,
      cuCloseBracket = 9,
      cuName = 10,
      cuCall = 11,
      cuIndex = 12,
      cuVariable = 13,
      cuComma = 14,
      cuAssignment = 15
  );
  {$Z1}
  TExpressionOpcode = (
      eoNegate = 0,
      eoAdd = 1,
      eoSubtract = 2,
      eoMultiply = 3,
      eoDivide = 4,
      eoModulo = 5,
      eoBitAnd = 6,
      eoBitOr = 7,
      eoBitXor = 8,
      eoBitNot = 9,
      eoAnd = 10,
      eoOr = 11,
      eoNot = 12,
      eoShiftLeft = 13,
      eoShiftRight = 14,
      eoLess = 15,
      eoGreater = 16,
      eoEqual = 17,
      eoNotEqual = 18,
      eoLessEqual = 19,
      eoGreaterEqual = 20,
      eoAssign = 21,
      eoCall = 22,
      eoIndex = 23
  );
  {$Z1}
  TExpressionVarKind = (evNamed = 0, evOwned = 1, evIndexed = 2);
  {$Z1}
  TCodeOpcode = (
      coLabel = 0,
      coExpression = 1,
      coBranchFalse = 2,
      coJump = 3,
      coExit = 4,
      coPushHandler = 5,
      coPopHandler = 6,
      coThrow = 7
  );
  PCodeAnalyzerUnitEC = PointerToTCodeAnalyzerUnitEC;
  TVarEC = class(TObject)
    Name: WideString;
    Kind: TVarKind;
    Gap9: array[0..2] of Byte;
    // Win32 mods also use int variables to transport object addresses (e.g.
    // ShuMercs' art_num = CreateArt(...)). GetInt still provides 32-bit numeric
    // semantics; GetDword must recover the entire address on wider targets.
    IntValue: PtrInt;
    DwordValue: PtrUInt;
    StringValue: WideString;
    FloatValue: Double;
    ExternFunValue: Pointer;
    LibraryFunData: array of Dword;
    FunctionValue: TCodeEC;
    ClassValue: TCodeEC;
    ArrayValue: TVarArrayEC;
    RefValue: TVarEC;
    constructor Create(InitialKind: TVarKind);
    destructor Destroy; override;
    procedure ConvertToKind(NewKind: TVarKind);
    procedure ResetKind(NewKind: TVarKind);
    function RealVType: TVarKind;
    procedure AssignFrom(Source: TVarEC; CopyArrays: Boolean);
    function IsEmpty: Boolean;
    function GetInt: Integer;
    function GetDword: PtrUInt;
    function GetFloat: Double;
    function GetString: WideString;
    function GetExternFun: Pointer;
    function GetFunction: TCodeEC;
    function GetClass: TCodeEC;
    function GetArray: TVarArrayEC;
    procedure SetInt(Value: Integer);
    procedure SetDword(Value: PtrUInt);
    procedure SetFloat(Value: Double);
    procedure SetString(const Value: WideString);
    procedure SetExternFun(Value: Pointer);
    procedure SetFunction(Value: TCodeEC);
    procedure SetClass(Value: TCodeEC);
    procedure SetArray(Value: TVarArrayEC);
    procedure SetRef(Value: TVarEC);
    function Resolve: TVarEC;
    procedure PackAnsiString;
    procedure UnpackAnsiString;
    procedure CreateArray(Dimensions: array of Integer);
    procedure ResizeArray(Count: Integer; Dimension: Integer);
    procedure FreeArray;
    procedure OAdd(Left: TVarEC; Right: TVarEC);
    procedure OSub(Left: TVarEC; Right: TVarEC);
    procedure OMul(Left: TVarEC; Right: TVarEC);
    procedure ODiv(Left: TVarEC; Right: TVarEC);
    procedure OMod(Left: TVarEC; Right: TVarEC);
    procedure OBitAnd(Left: TVarEC; Right: TVarEC);
    procedure OBitOr(Left: TVarEC; Right: TVarEC);
    procedure OBitXor(Left: TVarEC; Right: TVarEC);
    procedure OAnd(Left: TVarEC; Right: TVarEC);
    procedure OOr(Left: TVarEC; Right: TVarEC);
    procedure OShl(Left: TVarEC; Right: TVarEC);
    procedure OShr(Left: TVarEC; Right: TVarEC);
    procedure OEqual(Left: TVarEC; Right: TVarEC);
    procedure ONotEqual(Left: TVarEC; Right: TVarEC);
    procedure OLess(Left: TVarEC; Right: TVarEC);
    procedure OMore(Left: TVarEC; Right: TVarEC);
    procedure OLessEqual(Left: TVarEC; Right: TVarEC);
    procedure OMoreEqual(Left: TVarEC; Right: TVarEC);
    procedure OMinus(Value: TVarEC);
    procedure OBitNot(Value: TVarEC);
    procedure ONot(Value: TVarEC);
    procedure Assume(Source: TVarEC; CopyArrays: Boolean);
    function EqualsValue(Other: TVarEC): Boolean;
    function LessThan(Other: TVarEC): Boolean;
    function GreaterThan(Other: TVarEC): Boolean;
    function IsTrue: Boolean;
    procedure SaveToBuffer(Buffer: TBufEC);
    procedure LoadFromBuffer(Buffer: TBufEC);
    procedure SetLibrarySignature(Signature: array of Dword);
  end;
  PVarEC = PointerToTVarEC;
  TVarArrayEC = class(TObject)
    Count: Integer;
    Data: PVarEC;
    NameOrder: PointerToInteger;
    constructor Create;
    destructor Destroy; override;
    procedure ClearStorage;
    procedure Clear;
    procedure CopyFrom(Source: TVarArrayEC; CopyArrays: Boolean);
    function FindNameOrderIndex(const Name: WideString): Integer;
    function FindNameInsertionIndex(const Name: WideString): Integer;
    procedure SetNameOrderIndex(Index: Integer; DataIndex: Integer);
    function GetNameOrderIndex(Index: Integer): Integer;
    function GetItemByNameOrder(Index: Integer): TVarEC;
    function FindNameOrderForDataIndex(DataIndex: Integer): Integer;
    function GetItem(Index: Integer): TVarEC;
    procedure SetItem(Index: Integer; Value: TVarEC);
    function GetItemNE(Index: Integer): TVarEC;
    function IndexOf(Value: TVarEC): Integer;
    function GetVar(const Name: WideString): TVarEC;
    function GetVarNE(const Name: WideString): TVarEC;
    procedure Delete(Index: Integer);
    procedure Remove(Value: TVarEC);
    procedure DeleteByName(const Name: WideString);
    procedure AddItem(Value: TVarEC);
    function Add(const Name: WideString; Kind: TVarKind): TVarEC;
    procedure SaveToBuffer(Buffer: TBufEC);
    procedure LoadFromBuffer(Buffer: TBufEC);
    procedure AppendFromBuffer(Buffer: TBufEC);
  end;
  TCodeAnalyzerUnitEC = class(TObject)
    Prev: TCodeAnalyzerUnitEC;
    Next: TCodeAnalyzerUnitEC;
    TokenKind: TCodeTokenKind;
    GapD: array[0..2] of Byte;
    SourceStart: Integer;
    SourceLength: Integer;
    Text: WideString;
  end;
  TCodeAnalyzerEC = class(TObject)
    FirstFree: TCodeAnalyzerUnitEC;
    LastFree: TCodeAnalyzerUnitEC;
    First: TCodeAnalyzerUnitEC;
    Last: TCodeAnalyzerUnitEC;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure ReserveTokens(Count: Integer);
    function AcquireToken: TCodeAnalyzerUnitEC;
    procedure RecycleToken(Token: TCodeAnalyzerUnitEC);
    procedure ClearTokens;
    function AddToken: TCodeAnalyzerUnitEC;
    procedure DeleteToken(Token: TCodeAnalyzerUnitEC);
    procedure AppendText(Text: WideString; SourceOffset: Integer; NewlineOffset: Integer);
    procedure Tokenize(Text: WideString; NewlineOffset: Integer = 0);
    function ValidateDelimiters: WideString;
    procedure RemoveWhitespace;
    procedure RemoveNewlines;
    procedure RemoveComments;
  end;
  TScriptIncludeResolver =
      function(
          SourceContext: Pointer;
          const Name: WideString;
          InsertSource: Boolean;
          var IncludedContext: Pointer;
          Analyzer: TCodeAnalyzerEC
      ): Integer;
  TExpressionCallback = procedure(av: array of TVarEC; Code: TCodeEC);
  TExpressionInstrEC = class(TObject)
    Opcode: TExpressionOpcode;
    Gap5: array[0..2] of Byte;
    OperandCount: Integer;
    Operands: array of Integer;
    destructor Destroy; override;
    procedure CopyFrom(Source: TExpressionInstrEC);
  end;
  TExpressionVarEC = class(TObject)
    Kind: TExpressionVarKind;
    Gap5: array[0..2] of Byte;
    Name: WideString;
    MemberPath: array of WideString;
    Value: TVarEC;
    destructor Destroy; override;
    procedure CopyFrom(Source: TExpressionVarEC);
    function SplitMemberPath: Boolean;
    function GetFullName: WideString;
    function Resolve(InitialKind: TVarKind): TVarEC;
  end;
  TExpressionEC = class(TObject)
    VariableCount: Integer;
    Variables: PointerToTExpressionVarEC;
    InstructionCount: Integer;
    Instructions: PointerToTExpressionInstrEC;
    SharedInstructions: Boolean;
    Gap15: array[0..2] of Byte;
    ResultIndex: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure CopyFrom(Source: TExpressionEC);
    procedure CopyFromFast(Source: TExpressionEC);
    function AddVariable: Integer;
    procedure DeleteVariable(Index: Integer);
    function GetVariable(Index: Integer): TExpressionVarEC; cdecl;
    procedure SetVariable(Index: Integer; Value: TExpressionVarEC); cdecl;
    function AddInstruction: Integer;
    procedure DeleteInstruction(Index: Integer);
    function GetInstruction(Index: Integer): TExpressionInstrEC; cdecl;
    procedure SetInstruction(Index: Integer; Value: TExpressionInstrEC); cdecl;
    procedure Compile(
        Analyzer: TCodeAnalyzerEC;
        FirstToken: TCodeAnalyzerUnitEC;
        EndToken: TCodeAnalyzerUnitEC;
        NextToken: PCodeAnalyzerUnitEC;
        var ErrorText: WideString
    );
    procedure Link(Scope: TVarArrayEC; OnlyUnlinked: Boolean);
    procedure Evaluate(Process: TCodeProcessEC; Code: TCodeEC; DebugContext: TScriptDebugState);
    function GetResult: TVarEC;
  end;
  TCodeUnitEC = class(TObject)
    Prev: TCodeUnitEC;
    Next: TCodeUnitEC;
    Opcode: TCodeOpcode;
    GapD: array[0..2] of Byte;
    Expression: TExpressionEC;
    Target: TCodeUnitEC;
    ExceptionVar: TVarEC;
    SourceStart: Integer;
    SourceLength: Integer;
    SourceContext: Pointer;
    Breakpoint: Boolean;
    Gap29: array[0..2] of Byte;
    destructor Destroy; override;
  end;
  PCodeExceptionHandler = PointerToTCodeExceptionHandler;
  TCodeProcessEC = class(TObject)
    Handlers: TList;
    Exceptions: TList;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure PushHandler(Code: TCodeEC; Handler: TCodeUnitEC);
    procedure PopHandler;
    function GetHandler: PCodeExceptionHandler;
    procedure PushException(Value: TVarEC);
    procedure PopException;
    function GetException: PVarEC;
    procedure RaiseUnhandledExceptions;
  end;
  TCodeEC = class(TObject)
    Parent: TCodeEC;
    IsClassDefinition: Boolean;
    Gap9: array[0..2] of Byte;
    Name: WideString;
    First: TCodeUnitEC;
    Last: TCodeUnitEC;
    LocalVar: TVarArrayEC;
    Process: TCodeProcessEC;
    DebugContext: TScriptDebugState;
    ScriptFunLinked: Boolean;
    Gap25: array[0..2] of Byte;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure CopyFrom(Source: TCodeEC);
    procedure CopyFromFast(Source: TCodeEC);
    function FindVar(Name: WideString): TVarEC;
    procedure DeleteCodeUnit(CodeUnit: TCodeUnitEC);
    function AddCodeUnit: TCodeUnitEC;
    function InsertCodeUnitBefore(BeforeUnit: TCodeUnitEC): TCodeUnitEC;
    procedure Compile(
        Analyzer: TCodeAnalyzerEC;
        SourceContext: Pointer;
        IncludeResolver: TScriptIncludeResolver;
        FirstToken: TCodeAnalyzerUnitEC;
        NextToken: PCodeAnalyzerUnitEC;
        var ErrorText: WideString
    );
    procedure CompileBlock(
        Analyzer: TCodeAnalyzerEC;
        SourceContext: Pointer;
        IncludeResolver: TScriptIncludeResolver;
        Token: TCodeAnalyzerUnitEC;
        BeforeUnit: TCodeUnitEC;
        NextToken: PCodeAnalyzerUnitEC;
        StatementEnd: PCodeAnalyzerUnitEC;
        BreakTarget: TCodeUnitEC;
        ContinueTarget: TCodeUnitEC;
        var ErrorText: WideString
    );
    procedure LinkAll(Scope: TVarArrayEC; OnlyUnlinked: Boolean);
    procedure LinkLocalScopes;
    procedure Run(Process: TCodeProcessEC);
    procedure RunDebug(Process: TCodeProcessEC; DebugContext: TScriptDebugState);
  end;
  TCodeExceptionHandler = packed record
    Code: TCodeEC;
    Handler: TCodeUnitEC;
  end;
  TCompilerUnitEC = class(TObject)
    Prev: TCompilerUnitEC;
    Next: TCompilerUnitEC;
    Kind: TCompilerUnitKind;
    OperatorToken: TCodeTokenKind;
    GapE: array[0..1] of Byte;
    Text: WideString;
    VariableIndex: Integer;
    IntValue: Integer;
    DwordValue: PtrUInt;
    FloatValue: Double;
    SourceStart: Integer;
    SourceLength: Integer;
  end;
  TCompilerEC = class(TObject)
    First: TCompilerUnitEC;
    Last: TCompilerUnitEC;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function AddUnit: TCompilerUnitEC;
    procedure DeleteUnit(UnitNode: TCompilerUnitEC);
    function FindReducibleOperator: TCompilerUnitEC;
    function FindReducibleIndex: TCompilerUnitEC;
    function FindReducibleCall: TCompilerUnitEC;
  end;
  TScriptDebugState = class(TObject)
    Paused: Boolean;
    Gap5: array[0..2] of Byte;
    StopEvent: Dword;
    ResumeEvent: Dword;
    StepMode: Byte;
    Gap11: array[0..2] of Byte;
    CurrentUnit: TCodeUnitEC;
    CurrentCode: TCodeEC;
  end;
var
  ScriptCallTrace: array[0..19] of TVarEC;
  ScriptCallTracePosition: Integer = 0;
  ScriptCallTraceCount: Integer = 0;
const
  ScriptHexDigits: array[0..15] of WideChar =
      ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f');
var
  ScriptStepInterval: Integer = 0;
  ScriptStepCallback: TScriptStepCallback = nil;
function CompareScriptNames(Left: PWideChar; Right: PWideChar): Integer; cdecl;
function TrimScriptString(Text: WideString): WideString;
function ScriptStringToInt(Text: WideString): Integer;
function ScriptFloatToString(Value: Double): WideString;
function ScriptDwordToHex(Value: Dword): WideString;
function ScriptStringToFloat(Text: WideString): Double;
function IsScriptIntegerText(Text: WideString): Boolean;
function IsNonIntegerScriptText(Text: WideString): Boolean;
procedure FormatScriptError(Code: Integer; Position: Integer; var Text: WideString);
function TryReadFloatLiteral(var Token: TCodeAnalyzerUnitEC; out Value: Double): Boolean;
function TryReadIntegerLiteral(var Token: TCodeAnalyzerUnitEC; out Value: Integer): Boolean;
function TryReadStringLiteral(var Token: TCodeAnalyzerUnitEC; var Value: WideString): Boolean;
function TryReadDwordLiteral(var Token: TCodeAnalyzerUnitEC; out Value: Dword): Boolean;
function TryReadMemberName(var Token: TCodeAnalyzerUnitEC; var Name: WideString): Boolean;
procedure FreeScriptArrayTree(Values: TVarArrayEC);
procedure GrowScriptArray(
    Values: TVarArrayEC;
    Dimensions: array of Integer;
    DimensionIndex: Integer
);
procedure ResizeScriptArray(Values: TVarArrayEC; Count: Integer);
procedure InitInstr(Instruction: TExpressionInstrEC; Token: TCodeTokenKind);
procedure SetScriptStepCallback(Callback: TScriptStepCallback; Interval: Integer);
procedure EF_Min(av: array of TVarEC; code: TCodeEC);
procedure EF_Max(av: array of TVarEC; code: TCodeEC);
procedure EF_NewArray(av: array of TVarEC; code: TCodeEC);
procedure EF_ArrayChange(av: array of TVarEC; code: TCodeEC);
procedure EF_Free(av: array of TVarEC; code: TCodeEC);
procedure EF_Count(av: array of TVarEC; code: TCodeEC);
procedure EF_Copy(av: array of TVarEC; code: TCodeEC);
procedure EF_Abs(av: array of TVarEC; code: TCodeEC);
procedure EF_ArcTan(av: array of TVarEC; code: TCodeEC);
procedure EF_Exp(av: array of TVarEC; code: TCodeEC);
procedure EF_Ln(av: array of TVarEC; code: TCodeEC);
procedure EF_Round(av: array of TVarEC; code: TCodeEC);
procedure EF_Sin(av: array of TVarEC; code: TCodeEC);
procedure EF_Cos(av: array of TVarEC; code: TCodeEC);
procedure EF_Sqr(av: array of TVarEC; code: TCodeEC);
procedure EF_Sqrt(av: array of TVarEC; code: TCodeEC);
procedure EF_Frac(av: array of TVarEC; code: TCodeEC);
procedure EF_Int(av: array of TVarEC; code: TCodeEC);
procedure EF_Ord(av: array of TVarEC; code: TCodeEC);
procedure EF_Rnd(av: array of TVarEC; code: TCodeEC);
procedure EF_Randomize(av: array of TVarEC; code: TCodeEC);
procedure EF_RandSeed(av: array of TVarEC; code: TCodeEC);
procedure EF_SubStr(av: array of TVarEC; code: TCodeEC);
procedure EF_FindSubStr(av: array of TVarEC; code: TCodeEC);
procedure EF_Trim(av: array of TVarEC; code: TCodeEC);
procedure EF_ToAnsi(av: array of TVarEC; code: TCodeEC);
procedure EF_ToUnicode(av: array of TVarEC; code: TCodeEC);
procedure EF_LowerCase(av: array of TVarEC; code: TCodeEC);
procedure EF_UpperCase(av: array of TVarEC; code: TCodeEC);
procedure EF_LoadLibrary(av: array of TVarEC; code: TCodeEC);
procedure EF_FreeLibrary(av: array of TVarEC; code: TCodeEC);
procedure EF_LibraryFunction(av: array of TVarEC; code: TCodeEC);
procedure EF_New(av: array of TVarEC; code: TCodeEC);
procedure EF_Delete(av: array of TVarEC; code: TCodeEC);
procedure RegisterExpressionBuiltins(Scope: TVarArrayEC);
// Optional host snapshot encoding; nil preserves the ordinary save format.
var
  SnapshotObjectIdentity: function(Value: PtrUInt): WideString;
implementation
uses
  EC_Str,
  Math;
// Reference parameters avoid copies of Self and RunStart in composed inline calls.
procedure FlushTokenRun(
    var Analyzer: TCodeAnalyzerEC;
    const Text: WideString;
    var RunStart: Integer;
    RunLength: Integer
); inline;
begin
  if (RunStart >= 0) and (RunLength > 0) then
  begin
    Analyzer.Last.Text := Analyzer.Last.Text + Copy(Text, RunStart + 1, RunLength);
    Inc(Analyzer.Last.SourceLength, RunLength);
  end;
end;
procedure FlushQuotedRun(
    var Analyzer: TCodeAnalyzerEC;
    const Text: WideString;
    RunStart, RunLength: Integer
); inline;
begin
  if (RunStart >= 0) and (RunLength > 0) then
  begin
    Analyzer.Last.Text := Analyzer.Last.Text + Copy(Text, RunStart + 1, RunLength - 1);
    Inc(Analyzer.Last.SourceLength, RunLength - 1);
  end;
end;
// Reference parameters preserve caller storage when DCC32 expands these helpers.
procedure EmitSourceToken(
    var Analyzer: TCodeAnalyzerEC;
    var Token: TCodeAnalyzerUnitEC;
    Kind: TCodeTokenKind;
    var Index, SourceOffset: Integer;
    SourceLength: Integer
); inline;
begin
  Token := Analyzer.AddToken;
  Token.TokenKind := Kind;
  Token.SourceStart := Index + SourceOffset;
  Token.SourceLength := SourceLength;
end;
// Finish the pending text before beginning a punctuation or newline token.
procedure EmitToken(
    var Analyzer: TCodeAnalyzerEC;
    const Text: WideString;
    var RunStart: Integer;
    RunLength: Integer;
    var Token: TCodeAnalyzerUnitEC;
    Kind: TCodeTokenKind;
    var Index, SourceOffset: Integer;
    SourceLength: Integer
); inline;
begin
  FlushTokenRun(Analyzer, Text, RunStart, RunLength);
  RunStart := -1;
  EmitSourceToken(Analyzer, Token, Kind, Index, SourceOffset, SourceLength);
end;

function CompareScriptNames(Left, Right: PWideChar): Integer; cdecl;
begin
  Result := CompareWideChars(Left, Right)
end;

function TrimScriptString(Text: WideString): WideString;
var
  C, Count, First, Last: Integer;
begin
  Count := Length(Text);
  First := 0;
  while First < Count do
  begin
    C := Ord(Text[First + 1]);
    if (C = Ord(' ')) or (C = 9) or (C = 13) or (C = 10) or (C = 0) then
      Inc(First)
    else
      Break;
  end;
  if First >= Count then
  begin
    Result := '';
    Exit;
  end;
  Last := Count - 1;
  while Last >= 0 do
  begin
    C := Ord(Text[Last + 1]);
    if (C = Ord(' ')) or (C = 9) or (C = 13) or (C = 10) or (C = 0) then
      Dec(Last)
    else
      Break;
  end;
  if Last < First then
  begin
    Result := '';
    Exit;
  end;
  SetLength(Result, Last - First + 1);
  Result := Copy(Text, First + 1, Last - First + 1);
end;

function ScriptStringToInt(Text: WideString): Integer;
var
  Count, i, Sign: Integer;
begin
  Result := 0;
  Count := Length(Text);
  Sign := 1;
  for i := 1 to Count do
    if (Integer(Text[i]) >= Ord('0')) and (Integer(Text[i]) <= Ord('9')) then
      Result := StrToInt(Text[i]) + Result * 10
    else if (Text[i] = '-') and (i = 1) then
      Sign := Sign * -1;
  Result := Sign * Result;
end;

function ScriptStringToDword(const Text: WideString): PtrUInt;
var
  I: Integer;
begin
  // Like native $45FE4C, collect all decimal digits, ignore other characters,
  // and recognize a minus only at the start. Use the target's pointer width:
  // EvoTranc stores a weapon address in TextData1 between combat phases.
  Result := 0;
  for I := 1 to Length(Text) do
    if (Text[I] >= '0') and (Text[I] <= '9') then
      Result := Result * 10 + PtrUInt(Ord(Text[I]) - Ord('0'));
  if (Length(Text) > 0) and (Text[1] = '-') then
  begin
    // Keep Win32 negative sentinel strings (notably '-1') as 32-bit bit patterns.
    if Result <= High(Cardinal) then
      Result := Dword(0 - Result)
    else
      Result := 0 - Result;
  end;
end;

function ScriptFloatToString(Value: Double): WideString;
var
  SavedSeparator: AnsiChar;
begin
  SavedSeparator := DecimalSeparator;
  DecimalSeparator := '.';
  Result := FloatToStr(Value);
  DecimalSeparator := SavedSeparator;
end;

function ScriptDwordToHex(Value: Dword): WideString;
begin
  Result := '';
  while Value <> 0 do
  begin
    Result := ScriptHexDigits[Value - (Value shr 4) shl 4] + Result;
    Value := Value div 16;
  end;
  if Result = '' then
    Result := '0';
end;

function ScriptStringToFloat(Text: WideString): Double;
var
  i, Count: Integer;
  Value, Divisor: Double;
  C: Integer;
begin
  Count := Length(Text);
  if Count < 1 then
  begin
    Result := 0;
    Exit;
  end;
  Value := 0;
  for i := 0 to Count - 1 do
  begin
    C := Ord(Text[i + 1]);
    if (C >= Ord('0')) and (C <= Ord('9')) then
      Value := Value * 10 + (C - Ord('0'))
    else if C = Ord('.') then
      Break;
  end;
  Inc(i);
  Divisor := 10;
  while i < Count do
  begin
    C := Ord(Text[i + 1]);
    if (C >= Ord('0')) and (C <= Ord('9')) then
    begin
      Value := (C - Ord('0')) / Divisor + Value;
      Divisor := Divisor * 10;
    end;
    Inc(i);
  end;
  for i := 0 to Count - 1 do
    if Integer(Text[i + 1]) = Ord('-') then
    begin
      Value := -Value;
      Break;
    end;
  Result := Value;
end;

function IsScriptIntegerText(Text: WideString): Boolean;
var
  i, Count: Integer;
begin
  Count := Length(Text);
  for i := 0 to Count - 1 do
    if ((Text[i + 1] < '0') or (Text[i + 1] > '9')) and ((Text[i + 1] <> '-') or (i > 0)) then
    begin
      Result := False;
      Exit;
    end;
  Result := True;
end;

function IsNonIntegerScriptText(Text: WideString): Boolean;
begin
  Result := not IsScriptIntegerText(Text);
end;

procedure FormatScriptError(Code, Position: Integer; var Text: WideString);
begin
  Text := IntToStr(Code) + ',' + IntToStr(Position);
end;

function TryReadFloatLiteral(var Token: TCodeAnalyzerUnitEC; out Value: Double): Boolean;
var
  Sign, Fraction, Exponent: Double;
  Current: TCodeAnalyzerUnitEC;
  C: WideChar;
  i, Count: Integer;
  ExponentText: WideString;
begin
  Current := Token;
  Result := False;
  Sign := 1;
  if Current = nil then
    Exit;
  if Current.TokenKind = ctSubtract then
  begin
    Sign := -1;
    Current := Current.Next;
    if Current = nil then
      Exit;
  end;
  if Current.TokenKind <> ctText then
    Exit;
  if not IsScriptIntegerText(Current.Text) then
    Exit;
  Value := ScriptStringToInt(Current.Text);
  Current := Current.Next;
  if Current = nil then
    Exit;
  if Current.TokenKind <> ctDot then
    Exit;
  Current := Current.Next;
  if Current = nil then
    Exit;
  if Current.TokenKind <> ctText then
    Exit;
  Count := Length(Current.Text);
  Fraction := 0;
  i := 0;
  while i < Count do
  begin
    C := Current.Text[i + 1];
    if (C >= '0') and (C <= '9') then
      Fraction := Fraction * 10 + (Ord(C) - Ord('0'))
    else if (C = 'e') or (C = 'E') then
      Break
    else
      Exit;
    Inc(i);
  end;
  if i < 1 then
    Exit;
  Value := Fraction / Power(10, i) + Value;
  Exponent := 0;
  if Count - 1 > i then
  begin
    ExponentText := Copy(Current.Text, i + 2, Count - i - 1);
    if not IsScriptIntegerText(ExponentText) then
      Exit;
    Exponent := ScriptStringToInt(ExponentText);
    Current := Current.Next;
  end
  else if Count - 1 = i then
  begin
    Current := Current.Next;
    if Current = nil then
      Exit;
    if Current.Next = nil then
      Exit;
    if Current.Next.TokenKind <> ctText then
      Exit;
    if not IsScriptIntegerText(Current.Next.Text) then
      Exit;
    if Current.TokenKind = ctSubtract then
      Exponent := -ScriptStringToInt(Current.Next.Text)
    else if Current.TokenKind = ctAdd then
      Exponent := ScriptStringToInt(Current.Next.Text)
    else
      Exit;
    Current := Current.Next.Next;
  end
  else
    Current := Current.Next;
  if Exponent > 0 then
    Value := Power(10, Exponent) * Value
  else if Exponent < 0 then
    Value := Value / Power(10, -Exponent);
  Value := Value * Sign;
  Token := Current;
  Result := True;
end;

function TryReadIntegerLiteral(var Token: TCodeAnalyzerUnitEC; out Value: Integer): Boolean;
var
  Sign: Integer;
  Current: TCodeAnalyzerUnitEC;
begin
  Current := Token;
  Result := False;
  Sign := 1;
  if Current = nil then
    Exit;
  if Current.TokenKind = ctSubtract then
  begin
    Sign := -1;
    Current := Current.Next;
    if Current = nil then
      Exit;
  end;
  if Current.TokenKind <> ctText then
    Exit;
  if not IsScriptIntegerText(Current.Text) then
    Exit;
  Value := ScriptStringToInt(Current.Text);
  Current := Current.Next;
  Value := Sign * Value;
  Token := Current;
  Result := True;
end;

function TryReadStringLiteral(var Token: TCodeAnalyzerUnitEC; var Value: WideString): Boolean;
var
  Current: TCodeAnalyzerUnitEC;
begin
  Current := Token;
  Result := False;
  if Current = nil then
    Exit;
  if Current.TokenKind <> ctStringLiteral then
    Exit;
  Value := Current.Text;
  Current := Current.Next;
  Token := Current;
  Result := True;
end;

function TryReadDwordLiteral(var Token: TCodeAnalyzerUnitEC; out Value: Dword): Boolean;
var
  Current: TCodeAnalyzerUnitEC;
  C: WideChar;
  Count, i: Integer;
begin
  Value := 0;
  Current := Token;
  Result := False;
  if Current = nil then
    Exit;
  if Current.TokenKind <> ctText then
    Exit;
  Count := Length(Current.Text);
  if Count < 2 then
    Exit;
  C := Current.Text[Count];
  if (C = 'h') or (C = 'H') then
    for i := 0 to Count - 2 do
    begin
      C := Current.Text[i + 1];
      if (C >= '0') and (C <= '9') then
        Value := Value * 16 + Dword(Ord(C) - Ord('0'))
      else if (C >= 'a') and (C <= 'f') then
        Value := Value * 16 + Dword(Ord(C) + 10 - Ord('a'))
      else if (C >= 'A') and (C <= 'F') then
        Value := Value * 16 + Dword(Ord(C) + 10 - Ord('A'))
      else
        Exit;
    end
  else if (C = 'b') or (C = 'B') then
    for i := 0 to Count - 2 do
    begin
      C := Current.Text[i + 1];
      if (C >= '0') and (C <= '1') then
        Value := Value * 2 + Dword(Ord(C) - Ord('0'))
      else
        Exit;
    end
  else
    Exit;
  Current := Current.Next;
  Token := Current;
  Result := True;
end;

function TryReadMemberName(var Token: TCodeAnalyzerUnitEC; var Name: WideString): Boolean;
begin
  Name := '';
  while (Token.TokenKind = ctText) and IsNonIntegerScriptText(Token.Text) do
  begin
    Name := Name + Token.Text;
    Token := Token.Next;
    if (Token = nil) or (Token.TokenKind <> ctDot) then
      Break;
    Name := Name + '.';
    Token := Token.Next;
    if (Token = nil) or (Token.TokenKind <> ctText) or not IsNonIntegerScriptText(Token.Text) then
    begin
      Name := '';
      Break;
    end;
  end;
  Result := Name <> '';
end;

constructor TVarEC.Create(InitialKind: TVarKind);
begin
  inherited Create;
  Kind := InitialKind;
  if InitialKind = vkFunction then
    FunctionValue := TCodeEC.Create;
end;

destructor TVarEC.Destroy;
begin
  if FunctionValue <> nil then
  begin
    FunctionValue.Free;
    FunctionValue := nil;
  end;
  LibraryFunData := nil;
  inherited Destroy;
end;

function ScriptDwordToIntStorage(Value: PtrUInt): PtrInt;
begin
  // Preserve signed Win32 values such as $FFFFFFFF = -1, while allowing an
  // object address above the Win32 range to survive an int assignment.
  if Value <= High(Cardinal) then
    Result := Integer(Value)
  else
    Result := PtrInt(Value);
end;

procedure TVarEC.ConvertToKind(NewKind: TVarKind);
begin
  if FunctionValue <> nil then
  begin
    FunctionValue.Free;
    FunctionValue := nil;
  end;
  if NewKind = vkInt then
  begin
    if Kind <> vkInt then
    begin
      if Kind = vkDword then
        IntValue := ScriptDwordToIntStorage(DwordValue)
      else if Kind = vkFloat then
        IntValue := Integer(Trunc(FloatValue))
      else if Kind = vkString then
        IntValue := ScriptDwordToIntStorage(ScriptStringToDword(StringValue))
      else
        IntValue := 0;
    end;
    DwordValue := 0;
    FloatValue := 0;
    StringValue := '';
    ExternFunValue := nil;
    LibraryFunData := nil;
    FunctionValue := nil;
    ClassValue := nil;
    ArrayValue := nil;
    RefValue := nil;
  end
  else if NewKind = vkDword then
  begin
    if Kind = vkInt then
      DwordValue := GetDword
    else if Kind <> vkDword then
    begin
      if Kind = vkFloat then
        DwordValue := Dword(Trunc(FloatValue))
      else if Kind = vkString then
        DwordValue := ScriptStringToDword(StringValue)
      else
        DwordValue := 0;
    end;
    IntValue := 0;
    FloatValue := 0;
    StringValue := '';
    ExternFunValue := nil;
    LibraryFunData := nil;
    FunctionValue := nil;
    ClassValue := nil;
    ArrayValue := nil;
    RefValue := nil;
  end
  else if NewKind = vkFloat then
  begin
    if Kind = vkInt then
      FloatValue := GetInt
    else if Kind = vkDword then
      FloatValue := DwordValue
    else if Kind <> vkFloat then
    begin
      if Kind = vkString then
        FloatValue := ScriptStringToFloat(StringValue)
      else
        FloatValue := 0;
    end;
    IntValue := 0;
    DwordValue := 0;
    StringValue := '';
    ExternFunValue := nil;
    LibraryFunData := nil;
    FunctionValue := nil;
    ClassValue := nil;
    ArrayValue := nil;
    RefValue := nil;
  end
  else if NewKind = vkString then
  begin
    if Kind = vkInt then
      StringValue := IntToStr(IntValue)
    else if Kind = vkDword then
      StringValue := IntToStr(Int64(DwordValue))
    else if Kind = vkFloat then
    begin
      try
        StringValue := ScriptFloatToString(FloatValue);
      except
        StringValue := '';
      end;
    end
    else if Kind <> vkString then
      StringValue := '';
    IntValue := 0;
    DwordValue := 0;
    FloatValue := 0;
    ExternFunValue := nil;
    LibraryFunData := nil;
    FunctionValue := nil;
    ClassValue := nil;
    ArrayValue := nil;
    RefValue := nil;
  end
  else if NewKind = vkExternFun then
  begin
    if Kind <> vkExternFun then
      ExternFunValue := nil;
    IntValue := 0;
    DwordValue := 0;
    FloatValue := 0;
    StringValue := '';
    LibraryFunData := nil;
    FunctionValue := nil;
    ClassValue := nil;
    ArrayValue := nil;
    RefValue := nil;
  end
  else if NewKind = vkLibraryFun then
  begin
    if Kind <> vkLibraryFun then
      LibraryFunData := nil;
    IntValue := 0;
    DwordValue := 0;
    FloatValue := 0;
    StringValue := '';
    ExternFunValue := nil;
    FunctionValue := nil;
    ClassValue := nil;
    ArrayValue := nil;
    RefValue := nil;
  end
  else if NewKind = vkFunction then
  begin
    IntValue := 0;
    DwordValue := 0;
    FloatValue := 0;
    StringValue := '';
    ExternFunValue := nil;
    LibraryFunData := nil;
    if FunctionValue <> nil then
      FunctionValue.Free;
    FunctionValue := TCodeEC.Create;
    ClassValue := nil;
    ArrayValue := nil;
    RefValue := nil;
  end
  else if NewKind = vkClass then
  begin
    if Kind <> vkClass then
    begin
      if ClassValue <> nil then
      begin
        ClassValue.Free;
        ClassValue := nil;
      end;
    end;
    IntValue := 0;
    DwordValue := 0;
    FloatValue := 0;
    StringValue := '';
    ExternFunValue := nil;
    LibraryFunData := nil;
    FunctionValue := nil;
    ArrayValue := nil;
    RefValue := nil;
  end
  else if NewKind = vkArray then
  begin
    if Kind <> vkArray then
      ArrayValue := nil;
    IntValue := 0;
    DwordValue := 0;
    FloatValue := 0;
    StringValue := '';
    ExternFunValue := nil;
    LibraryFunData := nil;
    FunctionValue := nil;
    ClassValue := nil;
    RefValue := nil;
  end
  else if NewKind = vkRef then
  begin
    if Kind <> vkRef then
      RefValue := nil;
    IntValue := 0;
    DwordValue := 0;
    FloatValue := 0;
    StringValue := '';
    ExternFunValue := nil;
    LibraryFunData := nil;
    FunctionValue := nil;
    ClassValue := nil;
    ArrayValue := nil;
  end;
  Kind := NewKind;
end;

procedure TVarEC.ResetKind(NewKind: TVarKind);
begin
  if FunctionValue <> nil then
  begin
    FunctionValue.Free;
    FunctionValue := nil;
  end;
  if Kind = vkRef then
  begin
    if RefValue <> nil then
      RefValue.ResetKind(NewKind);
  end
  else
  begin
    Kind := NewKind;
    IntValue := 0;
    DwordValue := 0;
    FloatValue := 0;
    StringValue := '';
    ExternFunValue := nil;
    LibraryFunData := nil;
    FunctionValue := nil;
    ClassValue := nil;
    ArrayValue := nil;
    RefValue := nil;
    if NewKind = vkFunction then
      FunctionValue := TCodeEC.Create;
  end;
end;

function TVarEC.RealVType: TVarKind;
var
  Value: TVarEC;
begin
  Value := Resolve;
  if Value = nil then
    Result := vkRef
  else
    Result := Value.Kind;
end;

procedure TVarEC.AssignFrom(Source: TVarEC; CopyArrays: Boolean);
var
  i: Integer;
begin
  if FunctionValue <> nil then
  begin
    FunctionValue.Free;
    FunctionValue := nil;
  end;
  Name := Source.Name;
  Kind := Source.Kind;
  IntValue := Source.IntValue;
  DwordValue := Source.DwordValue;
  FloatValue := Source.FloatValue;
  StringValue := Source.StringValue;
  ExternFunValue := Source.ExternFunValue;
  ClassValue := Source.ClassValue;
  RefValue := Source.RefValue;
  if (Source.ArrayValue <> nil) and CopyArrays then
  begin
    if GetArray = nil then
      SetArray(TVarArrayEC.Create);
    if GetArray.Count > 0 then
      GetArray.Clear;
    GetArray.CopyFrom(Source.GetArray, True);
  end
  else
    ArrayValue := Source.ArrayValue;
  LibraryFunData := nil;
  if Source.LibraryFunData <> nil then
  begin
    SetLength(LibraryFunData, High(Source.LibraryFunData) + 1);
    for i := 0 to High(LibraryFunData) do
      LibraryFunData[i] := Source.LibraryFunData[i];
  end;
  FunctionValue := nil;
  if Source.FunctionValue <> nil then
  begin
    FunctionValue := TCodeEC.Create;
    FunctionValue.CopyFrom(Source.FunctionValue);
  end;
end;

function TVarEC.IsEmpty: Boolean;
begin
  Result := Kind = vkEmpty;
end;

function TVarEC.GetInt: Integer;
begin
  if Kind = vkEmpty then
    Result := 0
  else if Kind = vkInt then
    Result := Integer(IntValue)
  else if Kind = vkDword then
    Result := Integer(DwordValue)
  else if Kind = vkFloat then
    Result := Trunc(FloatValue)
  else if Kind = vkString then
    Result := ScriptStringToInt(StringValue)
  else if Kind = vkExternFun then
    Result := 0
  else if Kind = vkLibraryFun then
    Result := 0
  else if Kind = vkFunction then
    Result := 0
  else if Kind = vkClass then
    Result := 0
  else if Kind = vkArray then
    Result := 0
  else if Kind = vkRef then
  begin
    if RefValue = nil then
      Result := 0
    else
      Result := RefValue.GetInt;
  end
  else
    raise ExceptionExpressionEC.Create('Type error');
end;

function TVarEC.GetDword: PtrUInt;
begin
  if Kind = vkEmpty then
    Result := 0
  else if Kind = vkInt then
  begin
    // Undo sign extension for ordinary signed 32-bit values, but do not
    // truncate a native address stored in an int cell.
    if (IntValue >= Low(Integer)) and (IntValue <= High(Integer)) then
      Result := Dword(IntValue)
    else
      Result := PtrUInt(IntValue);
  end
  else if Kind = vkDword then
    Result := DwordValue
  else if Kind = vkFloat then
    Result := Dword(Trunc(FloatValue))
  else if Kind = vkString then
    Result := ScriptStringToDword(StringValue)
  else if Kind = vkExternFun then
    Result := 0
  else if Kind = vkLibraryFun then
    Result := 0
  else if Kind = vkFunction then
    Result := 0
  else if Kind = vkClass then
    Result := 0
  else if Kind = vkArray then
    Result := 0
  else if Kind = vkRef then
  begin
    // Native $4615BC delegates to GetInt. That preserves all DWORD bits on
    // Win32, but truncates object addresses in pointer-width script DWORDs.
    if RefValue = nil then
      Result := 0
    else if RefValue.RealVType in [vkInt, vkDword, vkString] then
      Result := RefValue.GetDword
    else
      Result := Dword(RefValue.GetInt);
  end
  else
    raise ExceptionExpressionEC.Create('Type error');
end;

function TVarEC.GetFloat: Double;
begin
  if Kind = vkEmpty then
    Result := 0
  else if Kind = vkInt then
    Result := GetInt
  else if Kind = vkDword then
    Result := DwordValue
  else if Kind = vkFloat then
    Result := FloatValue
  else if Kind = vkString then
    Result := ScriptStringToFloat(StringValue)
  else if Kind = vkExternFun then
    Result := 0
  else if Kind = vkLibraryFun then
    Result := 0
  else if Kind = vkFunction then
    Result := 0
  else if Kind = vkClass then
    Result := 0
  else if Kind = vkArray then
    Result := 0
  else if Kind = vkRef then
  begin
    if RefValue = nil then
      Result := 0
    else
      Result := RefValue.GetFloat;
  end
  else
    raise ExceptionExpressionEC.Create('Type error');
end;

function TVarEC.GetString: WideString;
begin
  if Kind = vkEmpty then
    Result := ''
  else if Kind = vkInt then
    Result := IntToStr(IntValue)
  else if Kind = vkDword then
    Result := IntToStr(Int64(DwordValue))
  else if Kind = vkFloat then
    Result := ScriptFloatToString(FloatValue)
  else if Kind = vkString then
    Result := StringValue
  else if Kind = vkExternFun then
    Result := ''
  else if Kind = vkLibraryFun then
    Result := StringValue
  else if Kind = vkFunction then
    Result := ''
  else if Kind = vkClass then
    Result := ''
  else if Kind = vkArray then
    Result := ''
  else if Kind = vkRef then
  begin
    if RefValue = nil then
      Result := ''
    else
      Result := RefValue.GetString;
  end
  else
    raise ExceptionExpressionEC.Create('Type error');
end;

function TVarEC.GetExternFun: Pointer;
begin
  if Kind = vkEmpty then
    Result := nil
  else if Kind = vkInt then
    Result := nil
  else if Kind = vkDword then
    Result := nil
  else if Kind = vkFloat then
    Result := nil
  else if Kind = vkString then
    Result := nil
  else if Kind = vkExternFun then
    Result := ExternFunValue
  else if Kind = vkLibraryFun then
    Result := nil
  else if Kind = vkFunction then
    Result := nil
  else if Kind = vkClass then
    Result := nil
  else if Kind = vkArray then
    Result := nil
  else if Kind = vkRef then
  begin
    if RefValue = nil then
      Result := nil
    else
      Result := RefValue.GetExternFun;
  end
  else
    raise ExceptionExpressionEC.Create('Type error');
end;

function TVarEC.GetFunction: TCodeEC;
begin
  if Kind = vkEmpty then
    Result := nil
  else if Kind = vkInt then
    Result := nil
  else if Kind = vkDword then
    Result := nil
  else if Kind = vkFloat then
    Result := nil
  else if Kind = vkString then
    Result := nil
  else if Kind = vkExternFun then
    Result := nil
  else if Kind = vkLibraryFun then
    Result := nil
  else if Kind = vkFunction then
    Result := FunctionValue
  else if Kind = vkClass then
    Result := nil
  else if Kind = vkArray then
    Result := nil
  else if Kind = vkRef then
  begin
    if RefValue = nil then
      Result := nil
    else
      Result := RefValue.GetFunction;
  end
  else
    raise ExceptionExpressionEC.Create('Type error');
end;

function TVarEC.GetClass: TCodeEC;
begin
  if Kind = vkEmpty then
    Result := nil
  else if Kind = vkInt then
    Result := nil
  else if Kind = vkDword then
    Result := nil
  else if Kind = vkFloat then
    Result := nil
  else if Kind = vkString then
    Result := nil
  else if Kind = vkExternFun then
    Result := nil
  else if Kind = vkLibraryFun then
    Result := nil
  else if Kind = vkFunction then
    Result := nil
  else if Kind = vkClass then
    Result := ClassValue
  else if Kind = vkArray then
    Result := nil
  else if Kind = vkRef then
  begin
    if RefValue = nil then
      Result := nil
    else
      Result := RefValue.GetFunction;
  end
  else
    raise ExceptionExpressionEC.Create('Type error');
end;

function TVarEC.GetArray: TVarArrayEC;
begin
  if Kind = vkEmpty then
    Result := nil
  else if Kind = vkInt then
    Result := nil
  else if Kind = vkDword then
    Result := nil
  else if Kind = vkFloat then
    Result := nil
  else if Kind = vkString then
    Result := nil
  else if Kind = vkExternFun then
    Result := nil
  else if Kind = vkLibraryFun then
    Result := nil
  else if Kind = vkFunction then
    Result := nil
  else if Kind = vkClass then
    Result := nil
  else if Kind = vkArray then
    Result := ArrayValue
  else if Kind = vkRef then
  begin
    if RefValue = nil then
      Result := nil
    else
      Result := RefValue.GetArray;
  end
  else
    raise ExceptionExpressionEC.Create('Type error');
end;

procedure TVarEC.SetInt(Value: Integer);
begin
  if Kind = vkEmpty then
  begin
    ResetKind(vkInt);
    IntValue := Value;
  end
  else if Kind = vkInt then
    IntValue := Value
  else if Kind = vkDword then
    DwordValue := Dword(Value)
  else if Kind = vkFloat then
    FloatValue := Value
  else if Kind = vkString then
    StringValue := IntToStr(Value)
  else if Kind = vkExternFun then
    ExternFunValue := nil
  else if Kind = vkLibraryFun then
    LibraryFunData := nil
  else if Kind = vkFunction then
  begin
  end
  else if Kind = vkClass then
    ClassValue := nil
  else if Kind = vkArray then
    ArrayValue := nil
  else if Kind = vkRef then
  begin
    if RefValue <> nil then
      RefValue.SetInt(Value)
    else
      raise ExceptionExpressionEC.Create('Type error');
  end;
end;

procedure TVarEC.SetDword(Value: PtrUInt);
begin
  if Kind = vkEmpty then
  begin
    ResetKind(vkDword);
    DwordValue := Value;
  end
  else if Kind = vkInt then
    IntValue := ScriptDwordToIntStorage(Value)
  else if Kind = vkDword then
    DwordValue := Value
  else if Kind = vkFloat then
    FloatValue := Value
  else if Kind = vkString then
    StringValue := IntToStr(Int64(Value))
  else if Kind = vkExternFun then
    ExternFunValue := nil
  else if Kind = vkLibraryFun then
    LibraryFunData := nil
  else if Kind = vkFunction then
  begin
  end
  else if Kind = vkClass then
    ClassValue := nil
  else if Kind = vkArray then
    ArrayValue := nil
  else if Kind = vkRef then
  begin
    if RefValue <> nil then
    begin
      // Native $461FD0 delegates to SetInt. Preserve that signed conversion
      // for other scalar types, but retain full object addresses in integer cells.
      // Empty/string references must also retain addresses outside Win32.
      if (RefValue.RealVType in [vkInt, vkDword])
          or ((RefValue.RealVType in [vkEmpty, vkString]) and (Value > High(Cardinal))) then
        RefValue.SetDword(Value)
      else
        RefValue.SetInt(Integer(Value));
    end
    else
      raise ExceptionExpressionEC.Create('Type error');
  end;
end;

procedure TVarEC.SetFloat(Value: Double);
begin
  if Kind = vkEmpty then
  begin
    ResetKind(vkFloat);
    FloatValue := Value;
  end
  else if Kind = vkInt then
    IntValue := Integer(Trunc(Value))
  else if Kind = vkDword then
    DwordValue := Dword(Trunc(Value))
  else if Kind = vkFloat then
    FloatValue := Value
  else if Kind = vkString then
    StringValue := ScriptFloatToString(Value)
  else if Kind = vkExternFun then
    ExternFunValue := nil
  else if Kind = vkLibraryFun then
    LibraryFunData := nil
  else if Kind = vkFunction then
  begin
  end
  else if Kind = vkClass then
    ClassValue := nil
  else if Kind = vkArray then
    ArrayValue := nil
  else if Kind = vkRef then
  begin
    if RefValue <> nil then
      RefValue.SetFloat(Value)
    else
      raise ExceptionExpressionEC.Create('Type error');
  end;
end;

procedure TVarEC.SetString(const Value: WideString);
begin
  if Kind = vkEmpty then
  begin
    ResetKind(vkString);
    StringValue := Value;
  end
  else if Kind = vkInt then
    IntValue := ScriptDwordToIntStorage(ScriptStringToDword(Value))
  else if Kind = vkDword then
    DwordValue := ScriptStringToDword(Value)
  else if Kind = vkFloat then
    FloatValue := ScriptStringToFloat(Value)
  else if Kind = vkString then
    StringValue := Value
  else if Kind = vkExternFun then
    ExternFunValue := nil
  else if Kind = vkLibraryFun then
    StringValue := Value
  else if Kind = vkFunction then
  begin
  end
  else if Kind = vkClass then
    ClassValue := nil
  else if Kind = vkArray then
    ArrayValue := nil
  else if Kind = vkRef then
  begin
    if RefValue <> nil then
      RefValue.SetString(Value)
    else
      raise ExceptionExpressionEC.Create('Type error');
  end;
end;

procedure TVarEC.SetExternFun(Value: Pointer);
begin
  if Kind = vkEmpty then
  begin
    ResetKind(vkExternFun);
    ExternFunValue := Value;
  end
  else if Kind = vkInt then
    IntValue := 0
  else if Kind = vkDword then
    DwordValue := 0
  else if Kind = vkFloat then
    FloatValue := 0
  else if Kind = vkString then
    StringValue := ''
  else if Kind = vkExternFun then
    ExternFunValue := Value
  else if Kind = vkLibraryFun then
    LibraryFunData := nil
  else if Kind = vkFunction then
  begin
  end
  else if Kind = vkClass then
    ClassValue := nil
  else if Kind = vkArray then
    ArrayValue := nil
  else if Kind = vkRef then
  begin
    if RefValue <> nil then
      RefValue.SetExternFun(Value)
    else
      raise ExceptionExpressionEC.Create('Type error');
  end;
end;

procedure TVarEC.SetFunction(Value: TCodeEC);
begin
  if Kind = vkEmpty then
  begin
  end
  else if Kind = vkInt then
    IntValue := 0
  else if Kind = vkDword then
    DwordValue := 0
  else if Kind = vkFloat then
    FloatValue := 0
  else if Kind = vkString then
    StringValue := ''
  else if Kind = vkExternFun then
    ExternFunValue := nil
  else if Kind = vkLibraryFun then
    LibraryFunData := nil
  else if Kind = vkFunction then
  begin
  end
  else if Kind = vkClass then
    ClassValue := nil
  else if Kind = vkArray then
    ArrayValue := nil
  else if Kind = vkRef then
  begin
    if RefValue <> nil then
      RefValue.SetFunction(Value)
    else
      raise ExceptionExpressionEC.Create('Type error');
  end;
end;

procedure TVarEC.SetClass(Value: TCodeEC);
begin
  if Kind = vkEmpty then
  begin
    ResetKind(vkClass);
    ClassValue := Value;
  end
  else if Kind = vkInt then
    IntValue := 0
  else if Kind = vkDword then
    DwordValue := 0
  else if Kind = vkFloat then
    FloatValue := 0
  else if Kind = vkString then
    StringValue := ''
  else if Kind = vkExternFun then
    ExternFunValue := nil
  else if Kind = vkLibraryFun then
    LibraryFunData := nil
  else if Kind = vkFunction then
  begin
  end
  else if Kind = vkClass then
    ClassValue := Value
  else if Kind = vkArray then
    ArrayValue := nil
  else if Kind = vkRef then
  begin
    if RefValue <> nil then
      RefValue.SetFunction(Value)
    else
      raise ExceptionExpressionEC.Create('Type error');
  end;
end;

procedure TVarEC.SetArray(Value: TVarArrayEC);
begin
  if Kind = vkEmpty then
  begin
    ResetKind(vkArray);
    ArrayValue := Value;
  end
  else if Kind = vkInt then
    IntValue := 0
  else if Kind = vkDword then
    DwordValue := 0
  else if Kind = vkFloat then
    FloatValue := 0
  else if Kind = vkString then
    StringValue := ''
  else if Kind = vkExternFun then
    ExternFunValue := nil
  else if Kind = vkLibraryFun then
    LibraryFunData := nil
  else if Kind = vkFunction then
  begin
  end
  else if Kind = vkClass then
    ClassValue := nil
  else if Kind = vkArray then
    ArrayValue := Value
  else if Kind = vkRef then
  begin
    if RefValue <> nil then
      RefValue.SetArray(Value)
    else
      raise ExceptionExpressionEC.Create('Type error');
  end;
end;

procedure TVarEC.SetRef(Value: TVarEC);
begin
  if Kind = vkEmpty then
  begin
    ResetKind(vkRef);
    RefValue := Value;
  end
  else if Kind = vkInt then
    IntValue := 0
  else if Kind = vkDword then
    DwordValue := 0
  else if Kind = vkFloat then
    FloatValue := 0
  else if Kind = vkString then
    StringValue := ''
  else if Kind = vkExternFun then
    ExternFunValue := nil
  else if Kind = vkLibraryFun then
    LibraryFunData := nil
  else if Kind = vkFunction then
  begin
  end
  else if Kind = vkClass then
    ClassValue := nil
  else if Kind = vkArray then
    ArrayValue := nil
  else if Kind = vkRef then
    RefValue := Value
  else
    raise ExceptionExpressionEC.Create('Type error');
end;

function TVarEC.Resolve: TVarEC;
begin
  Result := Self;
  while (Result <> nil) and (Result.Kind = vkRef) do
    Result := Result.RefValue;
end;

procedure TVarEC.PackAnsiString;
var
  Text: AnsiString;
  i, Count: Integer;
  Dest: PAnsiChar;
begin
  ConvertToKind(vkString);
  Count := Length(StringValue);
  if Count > 0 then
  begin
    Text := StringValue;
    Dest := PAnsiChar(PWideChar(StringValue));
    for i := 0 to Count - 1 + 1 do
    begin
      Dest^ := Text[i + 1];
      Inc(Dest);
    end;
    if Odd(Count) then
      SetLength(StringValue, (Count shr 1) + 1)
    else
      SetLength(StringValue, Count shr 1);
  end;
end;

procedure TVarEC.UnpackAnsiString;
var
  Text: AnsiString;
  Count: Integer;
begin
  if Kind <> vkString then
    ConvertToKind(vkString)
  else
  begin
    Count := Length(StringValue);
    if Count > 0 then
    begin
      Text := PAnsiChar(PWideChar(StringValue));
      StringValue := Text;
    end;
  end;
end;

procedure FreeScriptArrayTree(Values: TVarArrayEC);
var
  i, Count: Integer;
  Item: TVarEC;
begin
  Count := Values.Count;
  for i := 0 to Count - 1 do
  begin
    Item := Values.GetItem(i);
    if (Item.Kind = vkArray) and (Item.GetArray <> nil) then
    begin
      FreeScriptArrayTree(Item.GetArray);
      Item.SetArray(nil);
    end;
  end;
  Values.Free;
end;

procedure GrowScriptArray(
    Values: TVarArrayEC;
    Dimensions: array of Integer;
    DimensionIndex: Integer
);
var
  i, Count: Integer;
  Item: TVarEC;
begin
  Count := Dimensions[DimensionIndex];
  if High(Dimensions) = DimensionIndex then
  begin
    for i := Values.Count to Count - 1 do
      Values.Add('', vkEmpty);
  end
  else
  begin
    for i := Values.Count to Count - 1 do
    begin
      Item := Values.Add('', vkArray);
      Item.SetArray(TVarArrayEC.Create);
      GrowScriptArray(Item.GetArray, Dimensions, DimensionIndex + 1);
    end;
  end;
end;

procedure ResizeScriptArray(Values: TVarArrayEC; Count: Integer);
var
  i, OldCount: Integer;
  Item: TVarEC;
  Dimensions: array of Integer;
  procedure CollectScriptArrayDimensions(
      Values: TVarArrayEC
  ); // @addr $462D4C @ida "void __usercall $name(TVarArrayEC *Values@<eax>, void *ParentFrame@<^0>);" @note "Nested in ResizeScriptArray; collects dimensions by following each first child."
  begin
    SetLength(Dimensions, High(Dimensions) + 1 + 1);
    Dimensions[High(Dimensions)] := Values.Count;
    if (Values.Count > 0) and (Values.GetItem(0).RealVType = vkArray) then
      CollectScriptArrayDimensions(Values.GetItem(0).GetArray);
  end;
begin
  OldCount := Values.Count;
  if Count = OldCount then
    Exit;
  if Count < OldCount then
  begin
    for i := Count to OldCount - 1 do
    begin
      Item := Values.GetItem(i);
      if (Item.Kind = vkArray) and (Item.GetArray <> nil) then
        FreeScriptArrayTree(Item.GetArray);
    end;
    for i := OldCount - 1 downto Count do
      Values.Delete(i);
  end
  else
  begin
    Dimensions := nil;
    CollectScriptArrayDimensions(Values);
    Dimensions[0] := Count;
    GrowScriptArray(Values, Dimensions, 0);
  end;
end;

procedure TVarEC.CreateArray(Dimensions: array of Integer);
begin
  ResetKind(vkArray);
  ArrayValue := TVarArrayEC.Create;
  GrowScriptArray(ArrayValue, Dimensions, 0);
end;

procedure TVarEC.ResizeArray(Count, Dimension: Integer);
begin
  if RealVType = vkArray then
  begin
    if Count <= 0 then
      FreeArray
    else if Dimension <= 0 then
    begin
      if GetArray = nil then
        CreateArray([Count])
      else
        ResizeScriptArray(GetArray, Count);
    end;
  end;
end;

procedure TVarEC.FreeArray;
begin
  if (RealVType = vkArray) and (GetArray <> nil) then
  begin
    FreeScriptArrayTree(GetArray);
    SetArray(nil);
  end;
end;

procedure TVarEC.OAdd(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then
    ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Left.GetInt + Right.GetInt);
      vkDword: SetDword(Left.GetDword + Right.GetDword);
      vkFloat: SetFloat(Left.GetFloat + Right.GetFloat);
      vkString: SetString(Left.GetString + Right.GetString);
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else
      raise ExceptionExpressionEC.Create('OAdd');
    end;
  end;
end;

procedure TVarEC.OSub(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then
    ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Left.GetInt - Right.GetInt);
      vkDword: SetDword(Left.GetDword - Right.GetDword);
      vkFloat: SetFloat(Left.GetFloat - Right.GetFloat);
      vkString: SetString(Left.GetString + Right.GetString);
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else
      raise ExceptionExpressionEC.Create('OSub');
    end;
  end;
end;

procedure TVarEC.OMul(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then
    ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Left.GetInt * Right.GetInt);
      vkDword: SetDword(Left.GetDword * Right.GetDword);
      vkFloat: SetFloat(Left.GetFloat * Right.GetFloat);
      vkString: SetString(Left.GetString + Right.GetString);
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else
      raise ExceptionExpressionEC.Create('OMul');
    end;
  end;
end;

procedure TVarEC.ODiv(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then
    ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Left.GetInt div Right.GetInt);
      vkDword: SetDword(Left.GetDword div Right.GetDword);
      vkFloat: SetFloat(Left.GetFloat / Right.GetFloat);
      vkString: SetString(Left.GetString + Right.GetString);
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else
      raise ExceptionExpressionEC.Create('ODiv');
    end;
  end;
end;

procedure TVarEC.OMod(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then
    ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Left.GetInt mod Right.GetInt);
      vkDword: SetDword(Left.GetDword mod Right.GetDword);
      vkFloat: SetFloat(Trunc(Left.GetFloat) mod Trunc(Right.GetFloat));
      vkString: SetString('');
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else
      raise ExceptionExpressionEC.Create('OMod');
    end;
  end;
end;

procedure TVarEC.OBitAnd(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then
    ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Left.GetInt and Right.GetInt);
      vkDword: SetDword(Left.GetDword and Right.GetDword);
      vkFloat: SetFloat(Trunc(Left.GetFloat) and Trunc(Right.GetFloat));
      vkString: SetString('');
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else
      raise ExceptionExpressionEC.Create('OBitAnd');
    end;
  end;
end;

procedure TVarEC.OBitOr(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then
    ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Left.GetInt or Right.GetInt);
      vkDword: SetDword(Left.GetDword or Right.GetDword);
      vkFloat: SetFloat(Trunc(Left.GetFloat) or Trunc(Right.GetFloat));
      vkString: SetString('');
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else
      raise ExceptionExpressionEC.Create('OBitOr');
    end;
  end;
end;

procedure TVarEC.OBitXor(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then
    ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Left.GetInt xor Right.GetInt);
      vkDword: SetDword(Left.GetDword xor Right.GetDword);
      vkFloat: SetFloat(Trunc(Left.GetFloat) xor Trunc(Right.GetFloat));
      vkString: SetString('');
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else
      raise ExceptionExpressionEC.Create('OBitXor');
    end;
  end;
end;

procedure TVarEC.OAnd(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then
    ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Ord((Left.GetDword <> 0) and (Right.GetDword <> 0)));
      vkDword: SetDword(Ord((Left.GetDword <> 0) and (Right.GetDword <> 0)));
      vkFloat: SetFloat(Integer((Left.GetFloat <> 0) and (Right.GetFloat <> 0)));
      vkString: SetString('');
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else
      raise ExceptionExpressionEC.Create('OAnd');
    end;
  end;
end;

procedure TVarEC.OOr(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then
    ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Ord((Left.GetDword <> 0) or (Right.GetDword <> 0)));
      vkDword: SetDword(Ord((Left.GetDword <> 0) or (Right.GetDword <> 0)));
      vkFloat: SetFloat(Integer((Left.GetFloat <> 0) or (Right.GetFloat <> 0)));
      vkString: SetString('');
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else
      raise ExceptionExpressionEC.Create('OOr');
    end;
  end;
end;

procedure TVarEC.OShl(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then
    ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Left.GetInt shl Right.GetInt);
      vkDword: SetDword(Left.GetDword shl Right.GetDword);
      vkFloat: SetFloat(Trunc(Left.GetFloat) shl Trunc(Right.GetFloat));
      vkString: SetString('');
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else
      raise ExceptionExpressionEC.Create('OShl');
    end;
  end;
end;

procedure TVarEC.OShr(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then
    ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Left.GetInt shr Right.GetInt);
      vkDword: SetDword(Left.GetDword shr Right.GetDword);
      vkFloat: SetFloat(Trunc(Left.GetFloat) shr Trunc(Right.GetFloat));
      vkString: SetString('');
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else
      raise ExceptionExpressionEC.Create('OShr');
    end;
  end;
end;

procedure TVarEC.OEqual(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then
    ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      // Equality compares all address bits even when a mod used an int cell.
      vkInt: SetInt(Ord(Left.GetDword = Right.GetDword));
      vkDword: SetDword(Ord(Left.GetDword = Right.GetDword));
      vkFloat: SetFloat(Integer(Left.GetFloat = Right.GetFloat));
      vkString: SetString(IntToStr(Ord(Left.GetString = Right.GetString)));
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else
      raise ExceptionExpressionEC.Create('OEqual');
    end;
  end;
end;

procedure TVarEC.ONotEqual(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then
    ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Ord(Left.GetDword <> Right.GetDword));
      vkDword: SetDword(Ord(Left.GetDword <> Right.GetDword));
      vkFloat: SetFloat(Integer(Left.GetFloat <> Right.GetFloat));
      vkString: SetString(IntToStr(Ord(Left.GetString <> Right.GetString)));
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else
      raise ExceptionExpressionEC.Create('ONotEqual');
    end;
  end;
end;

procedure TVarEC.OLess(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then
    ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Ord(Left.GetInt < Right.GetInt));
      vkDword: SetDword(Ord(Left.GetDword < Right.GetDword));
      vkFloat: SetFloat(Integer(Left.GetFloat < Right.GetFloat));
      vkString: SetString(IntToStr(Ord(Left.GetString < Right.GetString)));
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else
      raise ExceptionExpressionEC.Create('OLess');
    end;
  end;
end;

procedure TVarEC.OMore(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then
    ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Ord(Left.GetInt > Right.GetInt));
      vkDword: SetDword(Ord(Left.GetDword > Right.GetDword));
      vkFloat: SetFloat(Integer(Left.GetFloat > Right.GetFloat));
      vkString: SetString(IntToStr(Ord(Left.GetString > Right.GetString)));
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else
      raise ExceptionExpressionEC.Create('OMore');
    end;
  end;
end;

procedure TVarEC.OLessEqual(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then
    ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Ord(Left.GetInt <= Right.GetInt));
      vkDword: SetDword(Ord(Left.GetDword <= Right.GetDword));
      vkFloat: SetFloat(Integer(Left.GetFloat <= Right.GetFloat));
      vkString: SetString(IntToStr(Ord(Left.GetString <= Right.GetString)));
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else
      raise ExceptionExpressionEC.Create('OLessEqual');
    end;
  end;
end;

procedure TVarEC.OMoreEqual(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then
    ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Ord(Left.GetInt >= Right.GetInt));
      vkDword: SetDword(Ord(Left.GetDword >= Right.GetDword));
      vkFloat: SetFloat(Integer(Left.GetFloat >= Right.GetFloat));
      vkString: SetString(IntToStr(Ord(Left.GetString >= Right.GetString)));
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else
      raise ExceptionExpressionEC.Create('OMoreEqual');
    end;
  end;
end;

procedure TVarEC.OMinus(Value: TVarEC);
begin
  if RealVType = vkEmpty then
    ResetKind(Value.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Value.RealVType of
      vkInt: SetInt(-Value.GetInt);
      // Match DWORD addition/subtraction at the target's pointer width.
      vkDword: SetDword(PtrUInt(-Int64(Value.GetDword)));
      vkFloat: SetFloat(-Value.GetFloat);
      vkString: SetString(Value.GetString);
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else
      raise ExceptionExpressionEC.Create('OMinus');
    end;
  end;
end;

procedure TVarEC.OBitNot(Value: TVarEC);
begin
  if RealVType = vkEmpty then
    ResetKind(Value.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Value.RealVType of
      vkInt: SetInt(not Value.GetInt);
      vkDword: SetDword(not Value.GetDword);
      vkFloat: SetFloat(0);
      vkString: SetString('');
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else
      raise ExceptionExpressionEC.Create('OBitNot');
    end;
  end;
end;

procedure TVarEC.ONot(Value: TVarEC);
begin
  if RealVType = vkEmpty then
    ResetKind(Value.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Value.RealVType of
      vkInt: SetInt(Ord(Value.GetDword = 0));
      // A non-nil object can have zero in its low 32 bits.
      vkDword: SetDword(Ord(Value.GetDword = 0));
      vkFloat: SetFloat(Integer(Value.GetFloat = 0));
      vkString: SetString('');
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else
      raise ExceptionExpressionEC.Create('ONot');
    end;
  end;
end;

procedure TVarEC.Assume(Source: TVarEC; CopyArrays: Boolean);
var
  Dest: TVarEC;
  i: Integer;
begin
  Dest := Self;
  if Kind = vkRef then
  begin
    Dest := Resolve;
    if Dest = nil then
      Exit;
  end;
  if (Dest.Kind = vkExternFun) and (Source.Kind <> vkExternFun) then
    raise Exception.Create('Error assigning to function ' + Dest.Name);
  if Dest.Kind = vkEmpty then
    Dest.ResetKind(Source.RealVType);
  if Dest.Kind = vkEmpty then
  begin
  end
  else if Dest.Kind = vkInt then
  begin
    // Native $465300/$46530A copies through 32-bit GetInt/SetInt. On a wider
    // target integer-to-integer assignment must also preserve object addresses.
    // This path is shared by variable assignment and script function arguments.
    if Source.RealVType in [vkInt, vkDword] then
      Dest.SetDword(Source.GetDword)
    else if Source.RealVType = vkString then
      Dest.SetString(Source.GetString)
    else
      Dest.SetInt(Source.GetInt);
  end
  else if Dest.Kind = vkDword then
    Dest.SetDword(Source.GetDword)
  else if Dest.Kind = vkFloat then
    Dest.SetFloat(Source.GetFloat)
  else if Dest.Kind = vkString then
    Dest.SetString(Source.GetString)
  else if Dest.Kind = vkExternFun then
    Dest.SetExternFun(Source.GetExternFun)
  else if Dest.Kind = vkLibraryFun then
  begin
    Dest.LibraryFunData := nil;
    if Source.LibraryFunData <> nil then
    begin
      SetLength(Dest.LibraryFunData, High(Source.LibraryFunData) + 1);
      for i := 0 to High(Dest.LibraryFunData) do
        Dest.LibraryFunData[i] := Source.LibraryFunData[i];
    end;
    Dest.SetString(Source.GetString);
  end
  else if Dest.Kind = vkFunction then
    Dest.SetFunction(Source.GetFunction)
  else if Dest.Kind = vkClass then
    Dest.SetClass(Source.GetClass)
  else if Dest.Kind = vkArray then
  begin
    if not CopyArrays then
      Dest.SetArray(Source.GetArray)
    else
    begin
      if Dest.GetArray = nil then
        Dest.SetArray(TVarArrayEC.Create);
      if Dest.GetArray.Count > 0 then
        Dest.GetArray.Clear;
      Dest.GetArray.CopyFrom(Source.GetArray, True);
    end;
  end
  else
    raise ExceptionExpressionEC.Create('OAssume');
end;

function TVarEC.EqualsValue(Other: TVarEC): Boolean;
begin
  case RealVType of
    vkEmpty: Result := IsEmpty = Other.IsEmpty;
    vkInt: Result := GetDword = Other.GetDword;
    vkDword: Result := GetDword = Other.GetDword;
    vkFloat: Result := GetFloat = Other.GetFloat;
    vkString: Result := GetString = Other.GetString;
    vkExternFun: Result := False;
    vkFunction: Result := False;
    vkClass: Result := GetClass = Other.GetClass;
    vkArray: Result := False;
  else
    raise ExceptionExpressionEC.Create('Equal');
  end;
end;

function TVarEC.LessThan(Other: TVarEC): Boolean;
begin
  case RealVType of
    vkEmpty: Result := IsEmpty < Other.IsEmpty;
    vkInt: Result := GetInt < Other.GetInt;
    vkDword: Result := GetDword < Other.GetDword;
    vkFloat: Result := GetFloat < Other.GetFloat;
    vkString: Result := GetString < Other.GetString;
    vkExternFun: Result := False;
    vkFunction: Result := False;
    vkClass: Result := False;
    vkArray: Result := False;
  else
    raise ExceptionExpressionEC.Create('Less');
  end;
end;

function TVarEC.GreaterThan(Other: TVarEC): Boolean;
begin
  case RealVType of
    vkEmpty: Result := IsEmpty > Other.IsEmpty;
    vkInt: Result := GetInt > Other.GetInt;
    vkDword: Result := GetDword > Other.GetDword;
    vkFloat: Result := GetFloat > Other.GetFloat;
    vkString: Result := GetString > Other.GetString;
    vkExternFun: Result := False;
    vkFunction: Result := False;
    vkClass: Result := False;
    vkArray: Result := False;
  else
    raise ExceptionExpressionEC.Create('More');
  end;
end;

function TVarEC.IsTrue: Boolean;
begin
  case RealVType of
    vkEmpty: Result := False;
    vkInt: Result := GetDword <> 0;
    vkDword: Result := GetDword <> 0;
    vkFloat: Result := GetFloat <> 0;
    vkString: Result := GetString <> '';
    vkExternFun: Result := False;
    vkLibraryFun: Result := Resolve.LibraryFunData <> nil;
    vkFunction: Result := False;
    vkClass: Result := GetClass <> nil;
    vkArray: Result := False;
  else
    raise ExceptionExpressionEC.Create('IsTrue');
  end;
end;

procedure TVarEC.SaveToBuffer(Buffer: TBufEC);
var
  ObjectKey: WideString;
begin
  if (Kind = vkDword) and Assigned(SnapshotObjectIdentity) then
  begin
    ObjectKey := SnapshotObjectIdentity(DwordValue);
    if ObjectKey <> '' then
    begin
      Buffer.AddWideStringZ(Name);
      Buffer.AddByte($FE); // Distinguish object identities from every scalar kind.
      Buffer.AddWideStringZ(ObjectKey);
      Exit;
    end;
  end;
  Buffer.AddWideStringZ(Name);
  Buffer.AddAnsiChar(AnsiChar(Kind));
  if Kind = vkEmpty then
  begin
  end
  else if Kind = vkInt then
  begin
    Buffer.AddIntegerValue(IntValue);
  end
  else if Kind = vkDword then
  begin
    Buffer.AddDWord(DwordValue);
  end
  else if Kind = vkFloat then
  begin
    Buffer.AddDouble(FloatValue);
  end
  else if Kind = vkString then
  begin
    Buffer.AddWideStringZ(StringValue);
  end
  else if Kind = vkExternFun then
  begin
  end
  else if Kind = vkLibraryFun then
  begin
  end
  else if Kind = vkFunction then
  begin
  end
  else if Kind = vkClass then
  begin
  end
  else if Kind = vkArray then
  begin
    ArrayValue.SaveToBuffer(Buffer);
  end
  else if Kind = vkRef then
  begin
  end;
end;

procedure TVarEC.LoadFromBuffer(Buffer: TBufEC);
begin
  Name := Buffer.ReadWideString;
  ResetKind(TVarKind(Buffer.GetByte));
  if Kind = vkEmpty then
  begin
  end
  else if Kind = vkInt then
  begin
    IntValue := Buffer.GetInt32;
  end
  else if Kind = vkDword then
  begin
    DwordValue := Buffer.GetUInt32;
  end
  else if Kind = vkFloat then
  begin
    FloatValue := Buffer.GetDouble;
  end
  else if Kind = vkString then
  begin
    StringValue := Buffer.ReadWideString;
  end
  else if Kind = vkExternFun then
  begin
  end
  else if Kind = vkLibraryFun then
  begin
  end
  else if Kind = vkFunction then
  begin
  end
  else if Kind = vkClass then
  begin
  end
  else if Kind = vkArray then
  begin
    ArrayValue := TVarArrayEC.Create;
    ArrayValue.LoadFromBuffer(Buffer);
  end
  else if Kind = vkRef then
  begin
  end;
end;

constructor TVarArrayEC.Create;
begin
  inherited Create;
end;

destructor TVarArrayEC.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TVarArrayEC.ClearStorage;
begin
  if Data <> nil then
  begin
    HeapFree(GetProcessHeap, 0, Data);
    Data := nil;
  end;
  if NameOrder <> nil then
  begin
    HeapFree(GetProcessHeap, 0, NameOrder);
    NameOrder := nil;
  end;
  Count := 0;
end;

procedure TVarArrayEC.Clear;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
  begin
    if (GetItem(i).Kind = vkArray) and (GetItem(i).GetArray <> nil) then
      GetItem(i).GetArray.Clear;
    GetItem(i).Free;
  end;
  ClearStorage;
end;

procedure TVarArrayEC.CopyFrom(Source: TVarArrayEC; CopyArrays: Boolean);
var
  Item, SourceItem: TVarEC;
  i: Integer;
begin
  Clear;
  Count := Source.Count;
  if Count < 1 then
    Exit;
  Data := HeapAlloc(GetProcessHeap, 0, Count * SizeOf(Pointer));
  NameOrder := HeapAlloc(GetProcessHeap, 0, Count * 4);
  CopyMemory(NameOrder, Source.NameOrder, Count * 4);
  for i := 0 to Count - 1 do
  begin
    SourceItem := Source.GetItem(i);
    Item := TVarEC.Create(vkEmpty);
    SetItem(i, Item);
    Item.Name := SourceItem.Name;
    Item.AssignFrom(SourceItem, CopyArrays);
  end;
end;

function TVarArrayEC.FindNameOrderIndex(const Name: WideString): Integer;
var
  Low, High, Middle, Comparison: Integer;
  Item: TVarEC;
begin
  if Count < 1 then
  begin
    Result := -1;
    Exit;
  end;
  Low := 0;
  High := Count - 1;
  repeat
    Middle := (High - Low) div 2 + Low;
    Item := GetItemByNameOrder(Middle);
    Comparison := CompareScriptNames(PWideChar(Name), PWideChar(Item.Name));
    if Comparison = 0 then
    begin
      Result := Middle;
      Exit;
    end;
    if Comparison < 0 then
      High := Middle - 1
    else
      Low := Middle + 1;
  until High < Low;
  Result := -1;
end;

function TVarArrayEC.FindNameInsertionIndex(const Name: WideString): Integer;
var
  Low, High, Middle, Comparison: Integer;
  Item: TVarEC;
begin
  if Count <= 0 then
  begin
    Result := 0;
    Exit;
  end;
  Low := 0;
  High := Count - 1;
  repeat
    Middle := (High - Low) div 2 + Low;
    Item := GetItemByNameOrder(Middle);
    Comparison := CompareScriptNames(PWideChar(Name), PWideChar(Item.Name));
    if Comparison = 0 then
    begin
      Result := Middle;
      Exit;
    end;
    if Comparison < 0 then
      High := Middle - 1
    else
      Low := Middle + 1;
  until High < Low;
  if Comparison < 0 then
    Result := Middle
  else
    Result := Middle + 1;
end;

procedure TVarArrayEC.SetNameOrderIndex(Index: Integer; DataIndex: Integer);
begin
  PInteger(PByte(NameOrder) + Index * SizeOf(Integer))^ := DataIndex
end;

function TVarArrayEC.GetNameOrderIndex(Index: Integer): Integer;
begin
  Result := PInteger(PByte(NameOrder) + Index * SizeOf(Integer))^
end;

function TVarArrayEC.GetItemByNameOrder(Index: Integer): TVarEC;
begin
  Result := GetItem(GetNameOrderIndex(Index))
end;

function TVarArrayEC.FindNameOrderForDataIndex(DataIndex: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to Count - 1 do
    if GetNameOrderIndex(I) = DataIndex then
    begin
      Result := I;
      Exit
    end
end;

function TVarArrayEC.GetItem(Index: Integer): TVarEC;
begin
  Result := TVarEC(PPointer(PByte(Data) + Index * SizeOf(Pointer))^)
end;

procedure TVarArrayEC.SetItem(Index: Integer; Value: TVarEC);
begin
  PPointer(PByte(Data) + Index * SizeOf(Pointer))^ := Value
end;

function TVarArrayEC.GetItemNE(Index: Integer): TVarEC;
begin
  if (Index < 0) or (Index >= Count) then
    Result := nil
  else
    Result := GetItem(Index);
end;

function TVarArrayEC.IndexOf(Value: TVarEC): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to Count - 1 do
    if GetItem(I) = Value then
    begin
      Result := I;
      Exit
    end
end;

function TVarArrayEC.GetVar(const Name: WideString): TVarEC;
begin
  Result := GetVarNE(Name);
  if Result = nil then
    raise ExceptionExpressionEC.Create('Var not found:' + Name);
end;

function TVarArrayEC.GetVarNE(const Name: WideString): TVarEC;
var
  Low, High, Middle, Comparison: Integer;
  Item: TVarEC;
begin
  if Count < 1 then
  begin
    Result := nil;
    Exit;
  end;
  Low := 0;
  High := Count - 1;
  repeat
    Middle := (High - Low) div 2 + Low;
    Item := GetItemByNameOrder(Middle);
    Comparison := CompareScriptNames(PWideChar(Name), PWideChar(Item.Name));
    if Comparison = 0 then
    begin
      Result := GetItem(GetNameOrderIndex(Middle));
      Exit;
    end;
    if Comparison < 0 then
      High := Middle - 1
    else
      Low := Middle + 1;
  until High < Low;
  Result := nil;
end;

procedure TVarArrayEC.Delete(Index: Integer);
var
  i, NameIndex, DataIndex: Integer;
  Item: TVarEC;
begin
  if Index < 0 then
    Exit;
  if Index >= Count then
    Exit;
  Item := GetItem(Index);
  if Item <> nil then
    Item.Free;
  NameIndex := FindNameOrderForDataIndex(Index);
  for i := NameIndex to Count - 2 do
    SetNameOrderIndex(i, GetNameOrderIndex(i + 1));
  for i := Index to Count - 2 do
    SetItem(i, GetItem(i + 1));
  Dec(Count);
  for i := 0 to Count - 1 do
  begin
    DataIndex := GetNameOrderIndex(i);
    if DataIndex > Index then
      SetNameOrderIndex(i, DataIndex - 1);
  end;
  if Count < 1 then
    Clear;
end;

procedure TVarArrayEC.Remove(Value: TVarEC);
begin
  Delete(IndexOf(Value));
end;

procedure TVarArrayEC.DeleteByName(const Name: WideString);
var
  Index, i, NameIndex, DataIndex: Integer;
  Item: TVarEC;
begin
  NameIndex := FindNameOrderIndex(Name);
  if NameIndex < 0 then
    Exit;
  Index := GetNameOrderIndex(NameIndex);
  Item := GetItem(Index);
  if Item <> nil then
    Item.Free;
  for i := NameIndex to Count - 2 do
    SetNameOrderIndex(i, GetNameOrderIndex(i + 1));
  for i := Index to Count - 2 do
    SetItem(i, GetItem(i + 1));
  Dec(Count);
  for i := 0 to Count - 1 do
  begin
    DataIndex := GetNameOrderIndex(i);
    if DataIndex > Index then
      SetNameOrderIndex(i, DataIndex - 1);
  end;
  if Count < 1 then
    Clear;
end;

procedure TVarArrayEC.AddItem(Value: TVarEC);
var
  i, InsertionIndex: Integer;
begin
  if Data = nil then
    Data := HeapAlloc(GetProcessHeap, 0, (Count + 1) * SizeOf(Pointer))
  else
    Data := HeapReAlloc(GetProcessHeap, 0, Data, (Count + 1) * SizeOf(Pointer));
  SetItem(Count, Value);
  InsertionIndex := FindNameInsertionIndex(Value.Name);
  if InsertionIndex >= Count then
  begin
    Inc(Count);
    if NameOrder = nil then
      NameOrder := HeapAlloc(GetProcessHeap, 0, Count * SizeOf(Integer))
    else
      NameOrder := HeapReAlloc(GetProcessHeap, 0, NameOrder, Count * SizeOf(Integer));
    SetNameOrderIndex(Count - 1, Count - 1);
  end
  else
  begin
    Inc(Count);
    NameOrder := HeapReAlloc(GetProcessHeap, 0, NameOrder, Count * SizeOf(Integer));
    for i := Count - 1 downto InsertionIndex + 1 do
      SetNameOrderIndex(i, GetNameOrderIndex(i - 1));
    SetNameOrderIndex(InsertionIndex, Count - 1);
  end;
end;

function TVarArrayEC.Add(const Name: WideString; Kind: TVarKind): TVarEC;
var
  Item: TVarEC;
begin
  Item := TVarEC.Create(Kind);
  Item.Name := Name;
  try
    AddItem(Item);
  except
    Item.Free;
    raise;
  end;
  Result := Item;
end;

procedure TVarArrayEC.SaveToBuffer(Buffer: TBufEC);
var
  i: Integer;
begin
  Buffer.AddIntegerValue(Count);
  for i := 0 to Count - 1 do
    GetItem(i).SaveToBuffer(Buffer);
end;

procedure TVarArrayEC.LoadFromBuffer(Buffer: TBufEC);
var
  ItemCount, i: Integer;
  Item: TVarEC;
begin
  Clear;
  ItemCount := Buffer.GetInt32;
  for i := 0 to ItemCount - 1 do
  begin
    Item := TVarEC.Create(vkEmpty);
    Item.LoadFromBuffer(Buffer);
    AddItem(Item);
  end;
end;

procedure TVarArrayEC.AppendFromBuffer(Buffer: TBufEC);
var
  ItemCount, i: Integer;
  Item: TVarEC;
begin
  ItemCount := Buffer.GetInt32;
  for i := 0 to ItemCount - 1 do
  begin
    Item := TVarEC.Create(vkEmpty);
    Item.LoadFromBuffer(Buffer);
    AddItem(Item);
  end;
end;

constructor TCodeAnalyzerEC.Create;
begin
  inherited Create;
end;

destructor TCodeAnalyzerEC.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TCodeAnalyzerEC.Clear;
var
  Token, Previous: TCodeAnalyzerUnitEC;
begin
  Token := First;
  while Token <> nil do
  begin
    Previous := Token;
    Token := Token.Next;
    Previous.Free;
  end;
  First := nil;
  Last := nil;
  Token := FirstFree;
  while Token <> nil do
  begin
    Previous := Token;
    Token := Token.Next;
    Previous.Free;
  end;
  FirstFree := nil;
  LastFree := nil;
end;

procedure TCodeAnalyzerEC.ReserveTokens(Count: Integer);
var
  Token: TCodeAnalyzerUnitEC;
  i: Integer;
begin
  for i := 0 to Count - 1 do
  begin
    Token := TCodeAnalyzerUnitEC.Create;
    if LastFree <> nil then
      LastFree.Next := Token;
    Token.Prev := LastFree;
    Token.Next := nil;
    LastFree := Token;
    if FirstFree = nil then
      FirstFree := Token;
  end;
end;

function TCodeAnalyzerEC.AcquireToken: TCodeAnalyzerUnitEC;
var
  Token: TCodeAnalyzerUnitEC;
begin
  if FirstFree = nil then
    ReserveTokens(64);
  Token := LastFree;
  if Token.Prev <> nil then
    Token.Prev.Next := Token.Next;
  if Token.Next <> nil then
    Token.Next.Prev := Token.Prev;
  if LastFree = Token then
    LastFree := Token.Prev;
  if FirstFree = Token then
    FirstFree := Token.Next;
  Result := Token;
end;

procedure TCodeAnalyzerEC.RecycleToken(Token: TCodeAnalyzerUnitEC);
begin
  if LastFree <> nil then
    LastFree.Next := Token;
  Token.Prev := LastFree;
  Token.Next := nil;
  LastFree := Token;
  if FirstFree = nil then
    FirstFree := Token;
end;

procedure TCodeAnalyzerEC.ClearTokens;
begin
  while First <> nil do
    DeleteToken(Last);
end;

function TCodeAnalyzerEC.AddToken: TCodeAnalyzerUnitEC;
var
  Token: TCodeAnalyzerUnitEC;
begin
  Token := AcquireToken;
  if Last <> nil then
    Last.Next := Token;
  Token.Prev := Last;
  Token.Next := nil;
  Last := Token;
  if First = nil then
    First := Token;
  Result := Token;
end;

procedure TCodeAnalyzerEC.DeleteToken(Token: TCodeAnalyzerUnitEC);
begin
  if Token.Prev <> nil then
    Token.Prev.Next := Token.Next;
  if Token.Next <> nil then
    Token.Next.Prev := Token.Prev;
  if Last = Token then
    Last := Token.Prev;
  if First = Token then
    First := Token.Next;
  RecycleToken(Token);
end;

procedure TCodeAnalyzerEC.AppendText(Text: WideString; SourceOffset, NewlineOffset: Integer);
var
  C: WideChar;
  Index: Integer;
  Token: TCodeAnalyzerUnitEC;
  TextLength, QuoteStart, RunStart, RunLength, HexValue, HexDigits: Integer;
begin
  TextLength := Length(Text);
  QuoteStart := -1;
  RunStart := -1;
  RunLength := 0;
  Index := 0;
  while Index < TextLength do
  begin
    C := Text[Index + 1];
    if QuoteStart = -1 then
    begin
      if (C = '(') then
        EmitToken(Self, Text, RunStart, RunLength, Token, ctOpenParen, Index, SourceOffset, 1)
      else if (C = ')') then
        EmitToken(Self, Text, RunStart, RunLength, Token, ctCloseParen, Index, SourceOffset, 1)
      else if (C = '{') then
        EmitToken(Self, Text, RunStart, RunLength, Token, ctOpenBrace, Index, SourceOffset, 1)
      else if (C = '}') then
        EmitToken(Self, Text, RunStart, RunLength, Token, ctCloseBrace, Index, SourceOffset, 1)
      else if (C = '[') then
        EmitToken(Self, Text, RunStart, RunLength, Token, ctOpenBracket, Index, SourceOffset, 1)
      else if (C = ']') then
        EmitToken(Self, Text, RunStart, RunLength, Token, ctCloseBracket, Index, SourceOffset, 1)
      else if (C = '/') and (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '*') then
      begin
        EmitToken(
            Self,
            Text,
            RunStart,
            RunLength,
            Token,
            ctBlockCommentStart,
            Index,
            SourceOffset,
            2
        );
        Inc(Index);
      end
      else if (C = '*') and (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '/') then
      begin
        EmitToken(
            Self,
            Text,
            RunStart,
            RunLength,
            Token,
            ctBlockCommentEnd,
            Index,
            SourceOffset,
            2
        );
        Inc(Index);
      end
      else if (C = '/') and (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '/') then
      begin
        EmitToken(Self, Text, RunStart, RunLength, Token, ctLineComment, Index, SourceOffset, 2);
        Inc(Index);
      end
      else if (C = '.') then
      begin
        // The native tokenizer counts a dot as two source characters.
        EmitToken(Self, Text, RunStart, RunLength, Token, ctDot, Index, SourceOffset, 2);
      end
      else if (C = '-') and (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '>') then
      begin
        EmitToken(Self, Text, RunStart, RunLength, Token, ctArrow, Index, SourceOffset, 2);
        Inc(Index);
      end
      else if (C = '&') and (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '&') then
      begin
        EmitToken(Self, Text, RunStart, RunLength, Token, ctAnd, Index, SourceOffset, 2);
        Inc(Index);
      end
      else if (C = '|') and (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '|') then
      begin
        EmitToken(Self, Text, RunStart, RunLength, Token, ctOr, Index, SourceOffset, 2);
        Inc(Index);
      end
      else if (C = '+') then
        EmitToken(Self, Text, RunStart, RunLength, Token, ctAdd, Index, SourceOffset, 1)
      else if (C = '-') then
        EmitToken(Self, Text, RunStart, RunLength, Token, ctSubtract, Index, SourceOffset, 1)
      else if (C = '*') then
        EmitToken(Self, Text, RunStart, RunLength, Token, ctMultiply, Index, SourceOffset, 1)
      else if (C = '/') then
        EmitToken(Self, Text, RunStart, RunLength, Token, ctDivide, Index, SourceOffset, 1)
      else if (C = '%') then
        EmitToken(Self, Text, RunStart, RunLength, Token, ctModulo, Index, SourceOffset, 1)
      else if (C = '&') then
        EmitToken(Self, Text, RunStart, RunLength, Token, ctBitAnd, Index, SourceOffset, 1)
      else if (C = '|') then
        EmitToken(Self, Text, RunStart, RunLength, Token, ctBitOr, Index, SourceOffset, 1)
      else if (C = '^') then
        EmitToken(Self, Text, RunStart, RunLength, Token, ctBitXor, Index, SourceOffset, 1)
      else if (C = '~') then
        EmitToken(Self, Text, RunStart, RunLength, Token, ctBitNot, Index, SourceOffset, 1)
      else if (C = '!') and (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '=') then
      begin
        EmitToken(Self, Text, RunStart, RunLength, Token, ctNotEqual, Index, SourceOffset, 2);
        Inc(Index);
      end
      else if (C = '!') then
        EmitToken(Self, Text, RunStart, RunLength, Token, ctNot, Index, SourceOffset, 1)
      else if (C = '<') and (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '<') then
      begin
        EmitToken(Self, Text, RunStart, RunLength, Token, ctShiftLeft, Index, SourceOffset, 2);
        Inc(Index);
      end
      else if (C = '>') and (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '>') then
      begin
        EmitToken(Self, Text, RunStart, RunLength, Token, ctShiftRight, Index, SourceOffset, 2);
        Inc(Index);
      end
      else if (C = '=') and (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '=') then
      begin
        EmitToken(Self, Text, RunStart, RunLength, Token, ctEqual, Index, SourceOffset, 2);
        Inc(Index);
      end
      else if (C = '=') then
        EmitToken(Self, Text, RunStart, RunLength, Token, ctAssign, Index, SourceOffset, 1)
      else if (C = '<') and (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '=') then
      begin
        EmitToken(Self, Text, RunStart, RunLength, Token, ctLessEqual, Index, SourceOffset, 2);
        Inc(Index);
      end
      else if (C = '>') and (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '=') then
      begin
        EmitToken(Self, Text, RunStart, RunLength, Token, ctGreaterEqual, Index, SourceOffset, 2);
        Inc(Index);
      end
      else if (C = '<') then
        EmitToken(Self, Text, RunStart, RunLength, Token, ctLess, Index, SourceOffset, 1)
      else if (C = '>') then
        EmitToken(Self, Text, RunStart, RunLength, Token, ctGreater, Index, SourceOffset, 1)
      else if (C = ';') then
        EmitToken(Self, Text, RunStart, RunLength, Token, ctSemicolon, Index, SourceOffset, 1)
      else if (C = ':') then
        EmitToken(Self, Text, RunStart, RunLength, Token, ctColon, Index, SourceOffset, 1)
      else if (C = ',') then
        EmitToken(Self, Text, RunStart, RunLength, Token, ctComma, Index, SourceOffset, 1)
      else if (C = ' ') or (C = #9) then
      begin
        FlushTokenRun(Self, Text, RunStart, RunLength);
        RunStart := -1;
        if (Last = nil) or ((Last <> nil) and (Last.TokenKind <> ctWhitespace)) then
        begin
          EmitSourceToken(Self, Token, ctWhitespace, Index, SourceOffset, 1);
        end
        else
          Inc(Last.SourceLength);
      end
      else if (C = #13) or (C = #10) then
      begin
        EmitToken(Self, Text, RunStart, RunLength, Token, ctNewline, Index, SourceOffset, 1);
        Inc(SourceOffset, NewlineOffset);
        if (Index + 1 < TextLength)
            and ((Text[(Index + 1) + 1] = #13) or (Text[(Index + 1) + 1] = #10)) then
        begin
          Inc(Index);
          Inc(Token.SourceLength);
        end;
      end
      // Either quote closes the native string, regardless of its opener.
      else if (C = '"') or (C = '''') then
      begin
        FlushTokenRun(Self, Text, RunStart, RunLength);
        Token := AddToken;
        Token.TokenKind := ctStringLiteral;
        QuoteStart := Index;
        Last.SourceStart := Index + SourceOffset;
        Last.SourceLength := 2;
        Last.Text := '';
        RunStart := Index + 1;
        RunLength := 0;
      end
      else if C > ' ' then
      begin
        if (Last = nil) or (Last.TokenKind <> ctText) then
        begin
          Token := AddToken;
          Token.TokenKind := ctText;
          Last.SourceStart := Index + SourceOffset;
          Last.SourceLength := 0;
          Last.Text := '';
          RunStart := Index;
          RunLength := 1;
        end
        else
          Inc(RunLength);
      end;
    end
    else if Last.TokenKind = ctStringLiteral then
    begin
      Inc(RunLength);
      if C = '\' then
      begin
        if (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '\') then
        begin
          FlushQuotedRun(Self, Text, RunStart, RunLength);
          Last.Text := Last.Text + C;
          Inc(Last.SourceLength, 2);
          Inc(Index);
          RunStart := Index + 1;
          RunLength := 0;
        end
        else if (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '"') then
        begin
          FlushQuotedRun(Self, Text, RunStart, RunLength);
          Last.Text := Last.Text + '"';
          Inc(Last.SourceLength, 2);
          Inc(Index);
          RunStart := Index + 1;
          RunLength := 0;
        end
        else if (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '''') then
        begin
          FlushQuotedRun(Self, Text, RunStart, RunLength);
          Last.Text := Last.Text + '''';
          Inc(Last.SourceLength, 2);
          Inc(Index);
          RunStart := Index + 1;
          RunLength := 0;
        end
        else if (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = 'n') then
        begin
          FlushQuotedRun(Self, Text, RunStart, RunLength);
          Last.Text := Last.Text + #13#10;
          Inc(Last.SourceLength, 2);
          Inc(Index);
          RunStart := Index + 1;
          RunLength := 0;
        end
        else if (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = 'x') then
        begin
          FlushQuotedRun(Self, Text, RunStart, RunLength);
          Inc(Last.SourceLength, 2);
          Inc(Index, 2);
          HexValue := 0;
          HexDigits := 0;
          while (Index < TextLength) and (HexDigits < 4) do
          begin
            C := Text[Index + 1];
            if (C >= '0') and (C <= '9') then
              HexValue := HexValue * 16 + Ord(C) - Ord('0')
            else if (C >= 'a') and (C <= 'f') then
              HexValue := HexValue * 16 + Ord(C) - Ord('a') + 10
            else if (C >= 'A') and (C <= 'F') then
              HexValue := HexValue * 16 + Ord(C) - Ord('A') + 10
            else
              Break;
            Inc(HexDigits);
            Inc(Last.SourceLength);
            Inc(Index);
          end;
          Last.Text := Last.Text + WideChar(HexValue);
          Dec(Index);
          RunStart := Index + 1;
          RunLength := 0;
        end;
      end
      // Either quote closes the native string, regardless of its opener.
      else if (C = '"') or (C = '''') then
      begin
        FlushQuotedRun(Self, Text, RunStart, RunLength);
        RunStart := -1;
        QuoteStart := -1;
      end;
    end;
    Inc(Index);
  end;
  if (RunStart >= 0) and (RunLength > 0) then
  begin
    Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
  end;
end;

procedure TCodeAnalyzerEC.Tokenize(Text: WideString; NewlineOffset: Integer);
begin
  ClearTokens;
  AppendText(Text, 0, NewlineOffset);
end;

function TCodeAnalyzerEC.ValidateDelimiters: WideString;
var
  Depth, OpenCount, CloseCount: Integer;
  Token: TCodeAnalyzerUnitEC;
  Stack: array of Byte;
begin
  Result := '';
  OpenCount := 0;
  CloseCount := 0;
  Token := First;
  while Token <> nil do
  begin
    if (Token.TokenKind = ctOpenParen)
        or (Token.TokenKind = ctOpenBrace)
        or (Token.TokenKind = ctOpenBracket)
        or (Token.TokenKind = ctBlockCommentStart) then
      Inc(OpenCount);
    if (Token.TokenKind = ctCloseParen)
        or (Token.TokenKind = ctCloseBrace)
        or (Token.TokenKind = ctCloseBracket)
        or (Token.TokenKind = ctBlockCommentEnd) then
      Inc(CloseCount);
    Token := Token.Next;
  end;
  if OpenCount <> CloseCount then
  begin
    FormatScriptError(0, Last.SourceStart + Last.SourceLength, Result);
    Exit;
  end;
  if OpenCount < 1 then
    Exit;
  SetLength(Stack, OpenCount);
  try
    Depth := 0;
    Token := First;
    while Token <> nil do
    begin
      if Token.TokenKind = ctOpenParen then
      begin
        Stack[Depth] := 1;
        Inc(Depth);
      end
      else if Token.TokenKind = ctOpenBrace then
      begin
        Stack[Depth] := 2;
        Inc(Depth);
      end
      else if Token.TokenKind = ctOpenBracket then
      begin
        Stack[Depth] := 3;
        Inc(Depth);
      end
      else if Token.TokenKind = ctBlockCommentStart then
      begin
        Stack[Depth] := 4;
        Inc(Depth);
      end
      else if Token.TokenKind = ctCloseParen then
      begin
        // Native checks total openings here, not the current stack depth.
        if (OpenCount < 1) or (Stack[Depth - 1] <> 1) then
        begin
          FormatScriptError(0, Token.SourceStart, Result);
          Stack := nil;
          Exit;
        end;
        Dec(Depth);
      end
      else if Token.TokenKind = ctCloseBrace then
      begin
        if (OpenCount < 1) or (Stack[Depth - 1] <> 2) then
        begin
          FormatScriptError(0, Token.SourceStart, Result);
          Stack := nil;
          Exit;
        end;
        Dec(Depth);
      end
      else if Token.TokenKind = ctCloseBracket then
      begin
        if (OpenCount < 1) or (Stack[Depth - 1] <> 3) then
        begin
          FormatScriptError(0, Token.SourceStart, Result);
          Stack := nil;
          Exit;
        end;
        Dec(Depth);
      end
      else if Token.TokenKind = ctBlockCommentEnd then
      begin
        if (OpenCount < 1) or (Stack[Depth - 1] <> 4) then
        begin
          FormatScriptError(0, Token.SourceStart, Result);
          Stack := nil;
          Exit;
        end;
        Dec(Depth);
      end;
      Token := Token.Next;
    end;
    if Depth > 0 then
    begin
      FormatScriptError(0, Last.SourceStart + Last.SourceLength, Result);
      Stack := nil;
      Exit;
    end;
  except
    Stack := nil;
    raise;
  end;
  Stack := nil;
end;

procedure TCodeAnalyzerEC.RemoveWhitespace;
var
  Token, Previous: TCodeAnalyzerUnitEC;
begin
  Token := First;
  while Token <> nil do
  begin
    Previous := Token;
    Token := Token.Next;
    if Previous.TokenKind = ctWhitespace then
      DeleteToken(Previous);
  end;
end;

procedure TCodeAnalyzerEC.RemoveNewlines;
var
  Token, Previous: TCodeAnalyzerUnitEC;
begin
  Token := First;
  while Token <> nil do
  begin
    Previous := Token;
    Token := Token.Next;
    if Previous.TokenKind = ctNewline then
      DeleteToken(Previous);
  end;
end;

procedure TCodeAnalyzerEC.RemoveComments;
var
  Token, Previous: TCodeAnalyzerUnitEC;
  LineComment: Boolean;
  CommentDepth: Integer;
begin
  LineComment := False;
  CommentDepth := 0;
  Token := First;
  while Token <> nil do
  begin
    Previous := Token;
    Token := Token.Next;
    if not LineComment and (CommentDepth = 0) then
    begin
      if Previous.TokenKind = ctBlockCommentStart then
      begin
        CommentDepth := 1;
        DeleteToken(Previous);
      end
      else if Previous.TokenKind = ctLineComment then
      begin
        LineComment := True;
        DeleteToken(Previous);
      end;
    end
    else
    begin
      if (CommentDepth <> 0) and (Previous.TokenKind = ctBlockCommentStart) then
        Inc(CommentDepth)
      else if LineComment and (Previous.TokenKind = ctNewline) then
        LineComment := False
      else if (CommentDepth <> 0) and (Previous.TokenKind = ctBlockCommentEnd) then
        Dec(CommentDepth);
      DeleteToken(Previous);
    end;
  end;
end;

destructor TExpressionInstrEC.Destroy;
begin
  Operands := nil;
  inherited Destroy;
end;

procedure InitInstr(Instruction: TExpressionInstrEC; Token: TCodeTokenKind);
begin
  if Token = ctAdd then
    Instruction.Opcode := eoAdd
  else if Token = ctSubtract then
    Instruction.Opcode := eoSubtract
  else if Token = ctMultiply then
    Instruction.Opcode := eoMultiply
  else if Token = ctDivide then
    Instruction.Opcode := eoDivide
  else if Token = ctModulo then
    Instruction.Opcode := eoModulo
  else if Token = ctBitAnd then
    Instruction.Opcode := eoBitAnd
  else if Token = ctBitOr then
    Instruction.Opcode := eoBitOr
  else if Token = ctBitXor then
    Instruction.Opcode := eoBitXor
  else if Token = ctBitNot then
    Instruction.Opcode := eoBitNot
  else if Token = ctAnd then
    Instruction.Opcode := eoAnd
  else if Token = ctOr then
    Instruction.Opcode := eoOr
  else if Token = ctNot then
    Instruction.Opcode := eoNot
  else if Token = ctShiftLeft then
    Instruction.Opcode := eoShiftLeft
  else if Token = ctShiftRight then
    Instruction.Opcode := eoShiftRight
  else if Token = ctEqual then
    Instruction.Opcode := eoEqual
  else if Token = ctNotEqual then
    Instruction.Opcode := eoNotEqual
  else if Token = ctLess then
    Instruction.Opcode := eoLess
  else if Token = ctGreater then
    Instruction.Opcode := eoGreater
  else if Token = ctLessEqual then
    Instruction.Opcode := eoLessEqual
  else if Token = ctGreaterEqual then
    Instruction.Opcode := eoGreaterEqual
  else
    raise ExceptionExpressionEC.Create('InitInstr');
end;

procedure TExpressionInstrEC.CopyFrom(Source: TExpressionInstrEC);
var
  i: Integer;
begin
  Opcode := Source.Opcode;
  OperandCount := Source.OperandCount;
  Operands := nil;
  if Source.Operands <> nil then
  begin
    SetLength(Operands, OperandCount);
    for i := 0 to OperandCount - 1 do
      Operands[i] := Source.Operands[i];
  end;
end;

destructor TExpressionVarEC.Destroy;
begin
  if Kind = evOwned then
    Value.Free;
  Value := nil;
  MemberPath := nil;
  inherited Destroy;
end;

procedure TExpressionVarEC.CopyFrom(Source: TExpressionVarEC);
var
  i, Count: Integer;
begin
  Name := Source.Name;
  Kind := Source.Kind;
  Value := nil;
  if Kind = evNamed then
    Value := Source.Value
  else if Kind = evOwned then
  begin
    if Source.Value <> nil then
    begin
      Value := TVarEC.Create(vkEmpty);
      Value.AssignFrom(Source.Value, False);
    end;
  end;
  if Source.MemberPath <> nil then
  begin
    Count := High(Source.MemberPath) + 1;
    SetLength(MemberPath, Count);
    for i := 0 to Count - 1 do
      MemberPath[i] := Source.MemberPath[i];
  end;
end;

function TExpressionVarEC.SplitMemberPath: Boolean;
var
  Start, Stop, Count, i, Parts: Integer;
  Text: WideString;
begin
  Result := True;
  Text := Name;
  Count := Length(Text);
  Start := 0;
  Stop := Start;
  while Stop < Count do
  begin
    if Text[Stop + 1] = '.' then
      Break;
    Inc(Stop);
  end;
  if Stop >= Count then
    Exit;
  Name := Copy(Text, Start + 1, Stop - Start);
  Parts := 1;
  for i := Stop + 1 to Count - 1 do
    if Text[i + 1] = '.' then
      Inc(Parts);
  SetLength(MemberPath, Parts);
  i := 0;
  while Stop + 1 < Count do
  begin
    Start := Stop + 1;
    Stop := Start;
    while Stop < Count do
    begin
      if Text[Stop + 1] = '.' then
        Break;
      Inc(Stop);
    end;
    MemberPath[i] := Copy(Text, Start + 1, Stop - Start);
    Inc(i);
  end;
  Result := True;
end;

function TExpressionVarEC.GetFullName: WideString;
var
  i: Integer;
begin
  Result := Name;
  if MemberPath <> nil then
    for i := 0 to High(MemberPath) do
      Result := Result + '.' + MemberPath[i];
end;

function TExpressionVarEC.Resolve(InitialKind: TVarKind): TVarEC;
var
  i: Integer;
begin
  if Value <> nil then
  begin
    if MemberPath = nil then
      Result := Value
    else
    begin
      Result := Value;
      i := 0;
      while i <= High(MemberPath) do
      begin
        if Result.RealVType = vkClass then
          Result := Result.GetClass.FindVar(MemberPath[i])
        else if Result.RealVType = vkFunction then
          Result := Result.GetFunction.FindVar(MemberPath[i])
        else
          raise ExceptionExpressionEC.Create('Not link var :' + GetFullName);
        if Result = nil then
          raise ExceptionExpressionEC.Create('Not link var :' + GetFullName);
        Inc(i);
      end;
    end;
  end
  else
  begin
    if Kind = evOwned then
      Value := TVarEC.Create(InitialKind)
    else
      raise ExceptionExpressionEC.Create('Not link var :' + GetFullName);
    Result := Value;
  end;
end;

constructor TExpressionEC.Create;
begin
  inherited Create;
end;

destructor TExpressionEC.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TExpressionEC.Clear;
begin
  while VariableCount > 0 do
    DeleteVariable(VariableCount - 1);
  if not SharedInstructions then
    while InstructionCount > 0 do
      DeleteInstruction(InstructionCount - 1);
  ResultIndex := -1;
  SharedInstructions := False;
end;

procedure TExpressionEC.CopyFrom(Source: TExpressionEC);
var
  i: Integer;
begin
  Clear;
  for i := 0 to Source.VariableCount - 1 do
    GetVariable(AddVariable).CopyFrom(Source.GetVariable(i));
  for i := 0 to Source.InstructionCount - 1 do
    GetInstruction(AddInstruction).CopyFrom(Source.GetInstruction(i));
  ResultIndex := Source.ResultIndex;
end;

procedure TExpressionEC.CopyFromFast(Source: TExpressionEC);
var
  i: Integer;
begin
  Clear;
  for i := 0 to Source.VariableCount - 1 do
    GetVariable(AddVariable).CopyFrom(Source.GetVariable(i));
  InstructionCount := Source.InstructionCount;
  Instructions := Source.Instructions;
  SharedInstructions := True;
  ResultIndex := Source.ResultIndex;
end;

function TExpressionEC.AddVariable: Integer;
begin
  Inc(VariableCount);
  if Variables = nil then
    Variables := HeapAlloc(GetProcessHeap, 0, VariableCount * SizeOf(Pointer))
  else
    Variables := HeapReAlloc(GetProcessHeap, 0, Variables, VariableCount * SizeOf(Pointer));
  SetVariable(VariableCount - 1, TExpressionVarEC.Create);
  Result := VariableCount - 1;
end;

procedure TExpressionEC.DeleteVariable(Index: Integer);
var
  i: Integer;
begin
  if (Index < 0) or (Index >= VariableCount) then
    Exit;
  GetVariable(Index).Free;
  for i := Index to VariableCount - 2 do
    SetVariable(i, GetVariable(i + 1));
  Dec(VariableCount);
  if VariableCount <= 0 then
  begin
    HeapFree(GetProcessHeap, 0, Variables);
    Variables := nil;
  end;
end;

function TExpressionEC.GetVariable(Index: Integer): TExpressionVarEC; cdecl;
begin
  Result := TExpressionVarEC(PPointer(PByte(Variables) + Index * SizeOf(Pointer))^)
end;

procedure TExpressionEC.SetVariable(Index: Integer; Value: TExpressionVarEC); cdecl;
begin
  PPointer(PByte(Variables) + Index * SizeOf(Pointer))^ := Value
end;

function TExpressionEC.AddInstruction: Integer;
begin
  Inc(InstructionCount);
  if Instructions = nil then
    Instructions := HeapAlloc(GetProcessHeap, 0, InstructionCount * SizeOf(Pointer))
  else
    Instructions :=
        HeapReAlloc(GetProcessHeap, 0, Instructions, InstructionCount * SizeOf(Pointer));
  SetInstruction(InstructionCount - 1, TExpressionInstrEC.Create);
  Result := InstructionCount - 1;
end;

procedure TExpressionEC.DeleteInstruction(Index: Integer);
var
  i: Integer;
begin
  if (Index < 0) or (Index >= InstructionCount) then
    Exit;
  GetInstruction(Index).Free;
  for i := Index to InstructionCount - 2 do
    SetInstruction(i, GetInstruction(i + 1));
  Dec(InstructionCount);
  if InstructionCount <= 0 then
  begin
    HeapFree(GetProcessHeap, 0, Instructions);
    Instructions := nil;
  end;
end;

function TExpressionEC.GetInstruction(Index: Integer): TExpressionInstrEC; cdecl;
begin
  Result := TExpressionInstrEC(PPointer(PByte(Instructions) + Index * SizeOf(Pointer))^)
end;

procedure TExpressionEC.SetInstruction(Index: Integer; Value: TExpressionInstrEC); cdecl;
begin
  PPointer(PByte(Instructions) + Index * SizeOf(Pointer))^ := Value
end;

// Extract whole conditions: a helper inside an and/or chain adds DCC32 temporaries.
function IsBinaryToken(const Token: TCodeAnalyzerUnitEC): Boolean; inline;
begin
  // The native test includes ctSubtract twice.
  Result :=
      (Token.TokenKind = ctAdd)
          or (Token.TokenKind = ctSubtract)
          or (Token.TokenKind = ctMultiply)
          or (Token.TokenKind = ctDivide)
          or (Token.TokenKind = ctModulo)
          or (Token.TokenKind = ctSubtract)
          or (Token.TokenKind = ctBitAnd)
          or (Token.TokenKind = ctBitOr)
          or (Token.TokenKind = ctBitXor)
          or (Token.TokenKind = ctAnd)
          or (Token.TokenKind = ctOr)
          or (Token.TokenKind = ctShiftLeft)
          or (Token.TokenKind = ctShiftRight)
          or (Token.TokenKind = ctEqual)
          or (Token.TokenKind = ctNotEqual)
          or (Token.TokenKind = ctLess)
          or (Token.TokenKind = ctGreater)
          or (Token.TokenKind = ctLessEqual)
          or (Token.TokenKind = ctGreaterEqual);
end;
function IsUnaryMinusPosition(const Item: TCompilerUnitEC): Boolean; inline;
begin
  Result :=
      (Item.Prev = nil)
          or ((Item.Prev.Kind <> cuIntLiteral)
              and (Item.Prev.Kind <> cuDwordLiteral)
              and (Item.Prev.Kind <> cuFloatLiteral)
              and (Item.Prev.Kind <> cuCloseParen)
              and (Item.Prev.Kind <> cuCloseBracket)
              and (Item.Prev.Kind <> cuName));
end;
function InvalidBinaryOperands(const Item: TCompilerUnitEC): Boolean; inline;
begin
  Result :=
      (Item.Prev = nil)
          or (Item.Next = nil)
          or not ((Item.Prev.Kind = cuName)
              or (Item.Prev.Kind = cuIntLiteral)
              or (Item.Prev.Kind = cuDwordLiteral)
              or (Item.Prev.Kind = cuFloatLiteral)
              or (Item.Prev.Kind = cuStringLiteral)
              or (Item.Prev.Kind = cuCloseParen)
              or (Item.Prev.Kind = cuCloseBracket))
          or not ((Item.Next.Kind = cuName)
              or (Item.Next.Kind = cuIntLiteral)
              or (Item.Next.Kind = cuDwordLiteral)
              or (Item.Next.Kind = cuFloatLiteral)
              or (Item.Next.Kind = cuStringLiteral)
              or (Item.Next.Kind = cuOpenParen)
              or (Item.Next.Kind = cuCall)
              or (Item.Next.Kind = cuIndex)
              or (Item.Next.Kind = cuUnaryOperator));
end;
function InvalidAssignmentOperands(const Item: TCompilerUnitEC): Boolean; inline;
begin
  Result :=
      (Item.Prev = nil)
          or (Item.Next = nil)
          or not ((Item.Prev.Kind = cuName) or (Item.Prev.Kind = cuCloseBracket))
          or not ((Item.Next.Kind = cuName)
              or (Item.Next.Kind = cuIntLiteral)
              or (Item.Next.Kind = cuDwordLiteral)
              or (Item.Next.Kind = cuFloatLiteral)
              or (Item.Next.Kind = cuStringLiteral)
              or (Item.Next.Kind = cuOpenParen)
              or (Item.Next.Kind = cuCall)
              or (Item.Next.Kind = cuIndex)
              or (Item.Next.Kind = cuUnaryOperator));
end;
function InvalidUnaryOperand(const Item: TCompilerUnitEC): Boolean; inline;
begin
  Result :=
      (Item.Kind = cuUnaryOperator)
          and ((Item.Next = nil)
              or not ((Item.Next.Kind = cuName)
                  or (Item.Next.Kind = cuIntLiteral)
                  or (Item.Next.Kind = cuDwordLiteral)
                  or (Item.Next.Kind = cuFloatLiteral)
                  or (Item.Next.Kind = cuStringLiteral)
                  or (Item.Next.Kind = cuOpenParen)
                  or (Item.Next.Kind = cuCall)
                  or (Item.Next.Kind = cuIndex)
                  or (Item.Next.Kind = cuUnaryOperator)));
end;
// Callers exit immediately after this; Compiler has been freed.
procedure RejectExpression(
    var Compiler: TCompilerEC;
    SourceStart: Integer;
    var ErrorText: WideString
); inline;
begin
  FormatScriptError(0, SourceStart, ErrorText);
  Compiler.Free;
end;
procedure TExpressionEC.Compile(
    Analyzer: TCodeAnalyzerEC;
    FirstToken, EndToken: TCodeAnalyzerUnitEC;
    NextToken: PCodeAnalyzerUnitEC;
    var ErrorText: WideString
);
var
  Token, Next: TCodeAnalyzerUnitEC;
  Compiler: TCompilerEC;
  Item, Reduced, Closing: TCompilerUnitEC;
  ResultSlot, Depth, ArgumentCount, OperandIndex: Integer;
  Slot: TExpressionVarEC;
  Instruction: TExpressionInstrEC;
  IntValue: Integer;
  DwordValue: Dword;
  FloatValue: Double;
  Text: WideString;
begin
  Clear;
  ErrorText := '';
  if FirstToken = nil then
    FirstToken := Analyzer.First;
  if FirstToken = nil then
  begin
    FormatScriptError(0, 0, ErrorText);
    Exit;
  end;
  Compiler := TCompilerEC.Create;
  Depth := 0;
  Token := FirstToken;
  while Token <> EndToken do
  begin
    if (Token.TokenKind <> ctBlockCommentStart) and (Token.TokenKind <> ctLineComment) then
    begin
      if Token.TokenKind = ctStringLiteral then
      begin
        Item := Compiler.AddUnit;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := Token.SourceLength;
        Item.Kind := cuStringLiteral;
        Item.Text := Token.Text;
      end
      else if Token.TokenKind = ctComma then
      begin
        if Depth <= 0 then
          Break;
        Item := Compiler.AddUnit;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := Token.SourceLength;
        Item.Kind := cuComma;
      end
      else if Token.TokenKind = ctAssign then
      begin
        Item := Compiler.AddUnit;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := Token.SourceLength;
        Item.Kind := cuAssignment;
      end
      else if Token.TokenKind = ctOpenParen then
      begin
        Item := Compiler.AddUnit;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := Token.SourceLength;
        Item.Kind := cuOpenParen;
        Inc(Depth);
      end
      else if Token.TokenKind = ctCloseParen then
      begin
        Dec(Depth);
        if Depth < 0 then
          Break;
        Item := Compiler.AddUnit;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := Token.SourceLength;
        Item.Kind := cuCloseParen;
      end
      else if Token.TokenKind = ctOpenBracket then
      begin
        Item := Compiler.AddUnit;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := Token.SourceLength;
        Item.Kind := cuOpenBracket;
        Inc(Depth);
      end
      else if Token.TokenKind = ctCloseBracket then
      begin
        Dec(Depth);
        if Depth < 0 then
          Break;
        Item := Compiler.AddUnit;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := Token.SourceLength;
        Item.Kind := cuCloseBracket;
      end
      else if Token.TokenKind = ctAssign then
      begin
        Item := Compiler.AddUnit;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := Token.SourceLength;
        Item.Kind := cuAssignment;
      end
      else if (Token.TokenKind = ctBitNot) or (Token.TokenKind = ctNot) then
      begin
        Item := Compiler.AddUnit;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := Token.SourceLength;
        Item.Kind := cuUnaryOperator;
        Item.OperatorToken := Token.TokenKind;
      end
      else if IsBinaryToken(Token) then
      begin
        Item := Compiler.AddUnit;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := Token.SourceLength;
        Item.Kind := cuBinaryOperator;
        Item.OperatorToken := Token.TokenKind;
      end
      else if Token.TokenKind = ctText then
      begin
        Next := Token;
        if TryReadFloatLiteral(Next, FloatValue) then
        begin
          Item := Compiler.AddUnit;
          Item.SourceStart := Token.SourceStart;
          if Next = nil then
            Item.SourceLength :=
                Analyzer.Last.SourceStart + Analyzer.Last.SourceLength - Token.SourceStart
          else
            Item.SourceLength := Next.Prev.SourceStart + Next.Prev.SourceLength - Token.SourceStart;
          Item.Kind := cuFloatLiteral;
          Item.FloatValue := FloatValue;
          Token := Next;
          Continue;
        end
        else if TryReadDwordLiteral(Next, DwordValue) then
        begin
          Item := Compiler.AddUnit;
          Item.SourceStart := Token.SourceStart;
          if Next = nil then
            Item.SourceLength :=
                Analyzer.Last.SourceStart + Analyzer.Last.SourceLength - Token.SourceStart
          else
            Item.SourceLength := Next.Prev.SourceStart + Next.Prev.SourceLength - Token.SourceStart;
          Item.Kind := cuDwordLiteral;
          Item.DwordValue := DwordValue;
          Token := Next;
          Continue;
        end
        else if TryReadIntegerLiteral(Next, IntValue) then
        begin
          Item := Compiler.AddUnit;
          Item.SourceStart := Token.SourceStart;
          if Next = nil then
            Item.SourceLength :=
                Analyzer.Last.SourceStart + Analyzer.Last.SourceLength - Token.SourceStart
          else
            Item.SourceLength := Next.Prev.SourceStart + Next.Prev.SourceLength - Token.SourceStart;
          Item.Kind := cuIntLiteral;
          Item.IntValue := IntValue;
          Token := Next;
          Continue;
        end
        else if TryReadStringLiteral(Next, Text) then
        begin
          Item := Compiler.AddUnit;
          Item.SourceStart := Token.SourceStart;
          if Next = nil then
            Item.SourceLength :=
                Analyzer.Last.SourceStart + Analyzer.Last.SourceLength - Token.SourceStart
          else
            Item.SourceLength := Next.Prev.SourceStart + Next.Prev.SourceLength - Token.SourceStart;
          Item.Kind := cuStringLiteral;
          Item.Text := Text;
          Token := Next;
          Continue;
        end
        else if TryReadMemberName(Next, Text) then
        begin
          Item := Compiler.AddUnit;
          Item.SourceStart := Token.SourceStart;
          if Next = nil then
            Item.SourceLength :=
                Analyzer.Last.SourceStart + Analyzer.Last.SourceLength - Token.SourceStart
          else
            Item.SourceLength := Next.Prev.SourceStart + Next.Prev.SourceLength - Token.SourceStart;
          Item.Kind := cuName;
          Item.Text := Text;
          Token := Next;
          Continue;
        end
        else
        begin
          RejectExpression(Compiler, Token.SourceStart, ErrorText);
          Exit;
        end;
      end
      else
      begin
        if Token.TokenKind = ctSemicolon then
          Break;
        if (Token.TokenKind <> ctNewline) and (Token.TokenKind <> ctWhitespace) then
        begin
          RejectExpression(Compiler, Token.SourceStart, ErrorText);
          Exit;
        end;
      end;
    end;
    Token := Token.Next;
  end;
  if NextToken <> nil then
    NextToken^ := Token;
  Depth := 0;
  Item := Compiler.First;
  while Item <> nil do
  begin
    if (Item.Kind = cuOpenParen) and (Item.Prev <> nil) and (Item.Prev.Kind = cuName) then
    begin
      Item.Kind := cuCall;
      Item.Text := Item.Prev.Text;
      Compiler.DeleteUnit(Item.Prev);
      Inc(Depth);
    end
    else if Item.Kind = cuOpenBracket then
    begin
      if (Item.Prev <> nil) and (Item.Prev.Kind = cuName) then
      begin
        Item.Kind := cuIndex;
        Item.Text := Item.Prev.Text;
        Compiler.DeleteUnit(Item.Prev);
        Inc(Depth);
      end
      else
      begin
        RejectExpression(Compiler, Item.SourceStart, ErrorText);
        Exit;
      end;
    end
    else if Item.Kind = cuOpenParen then
      Inc(Depth)
    else if Item.Kind = cuCloseParen then
      Dec(Depth)
    else if Item.Kind = cuCloseBracket then
      Dec(Depth);
    Item := Item.Next;
  end;
  if Depth <> 0 then
  begin
    if Token = nil then
      Token := Analyzer.Last;
    RejectExpression(Compiler, Token.SourceStart + Token.SourceLength, ErrorText);
    Exit;
  end;
  Item := Compiler.First;
  while Item <> nil do
  begin
    if (Item.Kind = cuBinaryOperator)
        and (Item.OperatorToken = ctSubtract)
        and (Item.Next <> nil)
        and ((Item.Next.Kind = cuIntLiteral) or (Item.Next.Kind = cuFloatLiteral)) then
    begin
      if IsUnaryMinusPosition(Item) then
      begin
        Item := Item.Next;
        Compiler.DeleteUnit(Item.Prev);
        Item.IntValue := -Item.IntValue;
        Item.FloatValue := -Item.FloatValue;
      end;
    end
    else if (Item.Kind = cuBinaryOperator)
        and (Item.OperatorToken = ctSubtract)
        and (Item.Next <> nil)
        and ((Item.Next.Kind = cuIntLiteral)
            or (Item.Next.Kind = cuDwordLiteral)
            or (Item.Next.Kind = cuFloatLiteral)
            or (Item.Next.Kind = cuOpenParen)
            or (Item.Next.Kind = cuCall)
            or (Item.Next.Kind = cuIndex)
            or (Item.Next.Kind = cuName)) then
    begin
      if IsUnaryMinusPosition(Item) then
        Item.Kind := cuUnaryOperator;
    end;
    Item := Item.Next;
  end;
  Item := Compiler.First;
  while Item <> nil do
  begin
    if Item.Kind = cuBinaryOperator then
    begin
      if InvalidBinaryOperands(Item) then
      begin
        RejectExpression(Compiler, Item.SourceStart, ErrorText);
        Exit;
      end;
    end
    else if Item.Kind = cuAssignment then
    begin
      if InvalidAssignmentOperands(Item) then
      begin
        RejectExpression(Compiler, Item.SourceStart, ErrorText);
        Exit;
      end;
    end
    else if InvalidUnaryOperand(Item) then
    begin
      RejectExpression(Compiler, Item.SourceStart, ErrorText);
      Exit;
    end;
    Item := Item.Next;
  end;
  Item := Compiler.First;
  while Item <> nil do
  begin
    if Item.Kind = cuIntLiteral then
    begin
      Item.Kind := cuVariable;
      Item.VariableIndex := AddVariable;
      Slot := GetVariable(Item.VariableIndex);
      Slot.Kind := evOwned;
      Slot.Value := TVarEC.Create(vkInt);
      Slot.Value.SetInt(Item.IntValue);
    end
    else if Item.Kind = cuDwordLiteral then
    begin
      Item.Kind := cuVariable;
      Item.VariableIndex := AddVariable;
      Slot := GetVariable(Item.VariableIndex);
      Slot.Kind := evOwned;
      Slot.Value := TVarEC.Create(vkDword);
      Slot.Value.SetDword(Item.DwordValue);
    end
    else if Item.Kind = cuFloatLiteral then
    begin
      Item.Kind := cuVariable;
      Item.VariableIndex := AddVariable;
      Slot := GetVariable(Item.VariableIndex);
      Slot.Kind := evOwned;
      Slot.Value := TVarEC.Create(vkFloat);
      Slot.Value.SetFloat(Item.FloatValue);
    end
    else if Item.Kind = cuStringLiteral then
    begin
      Item.Kind := cuVariable;
      Item.VariableIndex := AddVariable;
      Slot := GetVariable(Item.VariableIndex);
      Slot.Kind := evOwned;
      Slot.Value := TVarEC.Create(vkString);
      Slot.Value.SetString(Item.Text);
    end
    else if Item.Kind = cuName then
    begin
      Item.Kind := cuVariable;
      Item.VariableIndex := AddVariable;
      Slot := GetVariable(Item.VariableIndex);
      Slot.Kind := evNamed;
      Slot.Name := Item.Text;
      if not Slot.SplitMemberPath then
      begin
        RejectExpression(Compiler, Item.SourceStart, ErrorText);
        Exit;
      end;
    end
    else if Item.Kind = cuCall then
    begin
      Item.VariableIndex := AddVariable;
      Slot := GetVariable(Item.VariableIndex);
      Slot.Kind := evNamed;
      Slot.Name := Item.Text;
      if not Slot.SplitMemberPath then
      begin
        RejectExpression(Compiler, Item.SourceStart, ErrorText);
        Exit;
      end;
    end
    else if Item.Kind = cuIndex then
    begin
      Item.VariableIndex := AddVariable;
      Slot := GetVariable(Item.VariableIndex);
      Slot.Kind := evNamed;
      Slot.Name := Item.Text;
      if not Slot.SplitMemberPath then
      begin
        RejectExpression(Compiler, Item.SourceStart, ErrorText);
        Exit;
      end;
    end;
    Item := Item.Next;
  end;
  if Compiler.First = nil then
  begin
    RejectExpression(Compiler, 0, ErrorText);
    Exit;
  end;
  while Compiler.First.Next <> nil do
  begin
    Item := Compiler.FindReducibleIndex;
    if Item = nil then
      Item := Compiler.FindReducibleCall;
    if Item = nil then
      Item := Compiler.FindReducibleOperator;
    if Item = nil then
    begin
      Clear;
      if Compiler.First = nil then
        ErrorText := 'Unknown error'
      else
        FormatScriptError(0, Compiler.First.SourceStart, ErrorText);
      Compiler.Free;
      Exit;
    end;
    if (Item.Kind = cuCall) or (Item.Kind = cuIndex) then
    begin
      ArgumentCount := 0;
      Closing := Item.Next;
      while Closing <> nil do
      begin
        if Closing.Kind = cuVariable then
          Inc(ArgumentCount)
        else if (Closing.Kind = cuCloseParen) or (Closing.Kind = cuCloseBracket) then
          Break;
        Closing := Closing.Next;
      end;
      if (Item.Kind = cuIndex) and (ArgumentCount < 1) then
      begin
        Clear;
        RejectExpression(Compiler, Item.SourceStart, ErrorText);
        Exit;
      end;
      ResultSlot := AddVariable;
      if Item.Kind = cuCall then
        GetVariable(ResultSlot).Kind := evOwned
      else
        GetVariable(ResultSlot).Kind := evIndexed;
      Instruction := GetInstruction(AddInstruction);
      if Item.Kind = cuCall then
        Instruction.Opcode := eoCall
      else
        Instruction.Opcode := eoIndex;
      Instruction.OperandCount := ArgumentCount + 2;
      SetLength(Instruction.Operands, ArgumentCount + 2);
      Instruction.Operands[0] := ResultSlot;
      Instruction.Operands[1] := Item.VariableIndex;
      OperandIndex := 2;
      Reduced := Item.Next;
      while Reduced <> nil do
      begin
        if Reduced.Kind = cuVariable then
        begin
          Instruction.Operands[OperandIndex] := Reduced.VariableIndex;
          Inc(OperandIndex);
        end
        else if (Reduced.Kind = cuCloseParen) or (Reduced.Kind = cuCloseBracket) then
          Break;
        Reduced := Reduced.Next;
      end;
      Item.Kind := cuVariable;
      Item.Text := '';
      Item.VariableIndex := ResultSlot;
      Reduced := Item;
      while Closing <> Reduced do
      begin
        Item := Closing;
        Closing := Closing.Prev;
        Compiler.DeleteUnit(Item);
      end;
    end
    else if Item.Kind = cuUnaryOperator then
    begin
      ResultSlot := AddVariable;
      GetVariable(ResultSlot).Kind := evOwned;
      Instruction := GetInstruction(AddInstruction);
      if Item.OperatorToken = ctSubtract then
        Instruction.Opcode := eoNegate
      else
        InitInstr(Instruction, Item.OperatorToken);
      Instruction.OperandCount := 2;
      SetLength(Instruction.Operands, 2);
      Instruction.Operands[0] := ResultSlot;
      Instruction.Operands[1] := Item.Next.VariableIndex;
      Item.Next.VariableIndex := ResultSlot;
      Reduced := Item.Next;
      Compiler.DeleteUnit(Item);
    end
    else if Item.Kind = cuAssignment then
    begin
      Instruction := GetInstruction(AddInstruction);
      Instruction.Opcode := eoAssign;
      Instruction.OperandCount := 2;
      SetLength(Instruction.Operands, 2);
      Instruction.Operands[0] := Item.Prev.VariableIndex;
      Instruction.Operands[1] := Item.Next.VariableIndex;
      Reduced := Item.Prev;
      Compiler.DeleteUnit(Item.Next);
      Compiler.DeleteUnit(Item);
    end
    else
    begin
      ResultSlot := AddVariable;
      GetVariable(ResultSlot).Kind := evOwned;
      Instruction := GetInstruction(AddInstruction);
      InitInstr(Instruction, Item.OperatorToken);
      Instruction.OperandCount := 3;
      SetLength(Instruction.Operands, 3);
      Instruction.Operands[0] := ResultSlot;
      Instruction.Operands[1] := Item.Prev.VariableIndex;
      Instruction.Operands[2] := Item.Next.VariableIndex;
      Item.Prev.VariableIndex := ResultSlot;
      Reduced := Item.Prev;
      Compiler.DeleteUnit(Item.Next);
      Compiler.DeleteUnit(Item);
    end;
    while (Reduced <> nil)
        and (Reduced.Prev <> nil)
        and (Reduced.Prev.Kind = cuOpenParen)
        and (Reduced.Next <> nil)
        and (Reduced.Next.Kind = cuCloseParen) do
    begin
      Compiler.DeleteUnit(Reduced.Prev);
      Compiler.DeleteUnit(Reduced.Next);
    end;
  end;
  ResultIndex := Compiler.First.VariableIndex;
  Compiler.Free;
end;

procedure TExpressionEC.Link(Scope: TVarArrayEC; OnlyUnlinked: Boolean);
var
  i: Integer;
  Slot: TExpressionVarEC;
  Found: TVarEC;
begin
  for i := 0 to VariableCount - 1 do
  begin
    Slot := GetVariable(i);
    if (not OnlyUnlinked) or (Slot.Value = nil) then
    begin
      if Slot.Kind = evNamed then
      begin
        Found := Scope.GetVarNE(Slot.Name);
        if Found <> nil then
          Slot.Value := Found;
      end;
    end;
  end;
end;

procedure TExpressionEC.Evaluate(
    Process: TCodeProcessEC;
    Code: TCodeEC;
    DebugContext: TScriptDebugState
);
var
  LibraryWord: Dword;
  i, j: Integer;
  Instruction: TExpressionInstrEC;
  Dest, Left, Right: TExpressionVarEC;
  Arguments: array of TVarEC;
  Value, IndexValue, Callee, Argument: TVarEC;
  Invocation: TCodeEC;
  ResultKind: TVarKind;
  SingleValue: Single;
begin
  i := 0;
  while i < VariableCount do
  begin
    Dest := GetVariable(i);
    if Dest.Kind = evIndexed then
      Dest.Value := nil;
    Inc(i);
  end;
  i := 0;
  while i < InstructionCount do
  begin
    Instruction := GetInstruction(i);
    if (Instruction.Opcode = eoNegate)
        or (Instruction.Opcode = eoBitNot)
        or (Instruction.Opcode = eoNot) then
    begin
      Dest := GetVariable(Instruction.Operands[0]);
      Left := GetVariable(Instruction.Operands[1]);
      case Instruction.Opcode of
        eoNegate: Dest.Resolve(Left.Value.RealVType).OMinus(Left.Resolve(vkEmpty));
        eoBitNot: Dest.Resolve(Left.Value.RealVType).OBitNot(Left.Resolve(vkEmpty));
        eoNot: Dest.Resolve(Left.Value.RealVType).ONot(Left.Resolve(vkEmpty));
      end;
    end
    else if (Instruction.Opcode <> eoCall)
        and (Instruction.Opcode <> eoAssign)
        and (Instruction.Opcode <> eoIndex) then
    begin
      Dest := GetVariable(Instruction.Operands[0]);
      Left := GetVariable(Instruction.Operands[1]);
      Right := GetVariable(Instruction.Operands[2]);
      ResultKind := vkEmpty;
      if (Dest.Value = nil) and (Dest.Kind = evOwned) then
      begin
        if (Instruction.Opcode = eoAdd)
            or (Instruction.Opcode = eoSubtract)
            or (Instruction.Opcode = eoMultiply)
            or (Instruction.Opcode = eoDivide) then
          ResultKind := Left.Resolve(vkEmpty).RealVType
        else
          ResultKind := vkInt;
      end;
      case Instruction.Opcode of
        eoAdd: Dest.Resolve(ResultKind).OAdd(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoSubtract: Dest.Resolve(ResultKind).OSub(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoMultiply: Dest.Resolve(ResultKind).OMul(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoDivide: Dest.Resolve(ResultKind).ODiv(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoModulo: Dest.Resolve(ResultKind).OMod(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoBitAnd: Dest.Resolve(ResultKind).OBitAnd(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoBitOr: Dest.Resolve(ResultKind).OBitOr(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoBitXor: Dest.Resolve(ResultKind).OBitXor(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoAnd: Dest.Resolve(ResultKind).OAnd(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoOr: Dest.Resolve(ResultKind).OOr(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoShiftLeft: Dest.Resolve(ResultKind).OShl(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoShiftRight: Dest.Resolve(ResultKind).OShr(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoEqual: Dest.Resolve(ResultKind).OEqual(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoNotEqual:
          Dest.Resolve(ResultKind).ONotEqual(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoLess: Dest.Resolve(ResultKind).OLess(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoGreater: Dest.Resolve(ResultKind).OMore(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoLessEqual:
          Dest.Resolve(ResultKind).OLessEqual(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoGreaterEqual:
          Dest.Resolve(ResultKind).OMoreEqual(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
      end;
    end
    else if Instruction.Opcode = eoAssign then
    begin
      Dest := GetVariable(Instruction.Operands[0]);
      Left := GetVariable(Instruction.Operands[1]);
      Dest.Resolve(vkEmpty).Assume(Left.Resolve(vkEmpty), False);
    end
    else if Instruction.Opcode = eoIndex then
    begin
      Dest := GetVariable(Instruction.Operands[0]);
      Left := GetVariable(Instruction.Operands[1]);
      Value := Left.Resolve(vkEmpty);
      if Value.RealVType <> vkArray then
        raise ExceptionExpressionEC.Create('Not array:' + Left.Name);
      for j := 2 to Instruction.OperandCount - 1 do
      begin
        Right := GetVariable(Instruction.Operands[j]);
        IndexValue := Right.Resolve(vkEmpty);
        if IndexValue.RealVType = vkString then
        begin
          Value := Value.GetArray.GetVarNE(IndexValue.GetString);
          if Value = nil then
            raise ExceptionExpressionEC.Create(
                'Error array. name='
                    + Left.Resolve(vkEmpty).Name
                    + ' index='
                    + Right.Value.GetString
                    + ' level='
                    + IntToStr(j - 1));
        end
        else
        begin
          Value := Value.GetArray.GetItemNE(IndexValue.GetInt);
          if Value = nil then
            raise ExceptionExpressionEC.Create(
                'Error array. name='
                    + Left.Resolve(vkEmpty).Name
                    + ' index='
                    + IntToStr(Right.Value.GetInt)
                    + ' level='
                    + IntToStr(j - 1));
        end;
        if (j <> Instruction.OperandCount - 1) and (Value.RealVType <> vkArray) then
          raise ExceptionExpressionEC.Create('Error array:' + Left.Name);
      end;
      Dest.Value := Value;
    end
    else
    begin
      Dest := GetVariable(Instruction.Operands[0]);
      Left := GetVariable(Instruction.Operands[1]);
      Dest.Resolve(vkEmpty);
      Callee := Left.Resolve(vkEmpty);
      if Callee.RealVType = vkLibraryFun then
      begin
        Value := Callee.Resolve;
        if High(Value.LibraryFunData) + 1 - 2 <> Instruction.OperandCount - 2 then
          raise ExceptionExpressionEC.Create('Count variable : ' + Left.Name);
        for j := Instruction.OperandCount - 2 - 1 downto 0 do
        begin
          Argument := GetVariable(Instruction.Operands[j + 2]).Resolve(vkEmpty);
          case TLibraryValueKind(Value.LibraryFunData[2 + j]) of
            lvInt: LibraryWord := Argument.GetInt;
            lvDword: LibraryWord := Argument.GetDword;
            lvFloat:
            begin
              SingleValue := Argument.GetFloat;
              LibraryWord := PDword(@SingleValue)^;
            end;
            lvString:
            begin
              IndexValue := Argument.Resolve;
              if IndexValue.Kind <> vkString then
                raise ExceptionExpressionEC.Create('Variable not string');
              if Length(IndexValue.StringValue) <= 0 then
                LibraryWord := 0
              else
                LibraryWord := Dword(PWideChar(IndexValue.StringValue));
            end;
            lvRef: LibraryWord := Dword(Argument);
            lvCode: LibraryWord := Dword(Code);
          else
            LibraryWord := 0;
          end;
          // The imported function consumes its dynamically constructed argument stack.
          raise ExceptionExpressionEC.Create(
              'Win32 script DLL calls are unavailable in the FPC port');
        end;
        ScriptCallTrace[ScriptCallTracePosition] := Callee;
        ScriptCallTraceCount := Min(20, ScriptCallTraceCount + 1);
        ScriptCallTracePosition := (ScriptCallTracePosition + 1) mod 20;
        LibraryWord := Value.LibraryFunData[1];
        raise ExceptionExpressionEC.Create(
            'Win32 script DLL calls are unavailable in the FPC port');
        if Value.LibraryFunData[0] = 1 then
          Dest.Value.SetInt(LibraryWord)
        else if Value.LibraryFunData[0] = 2 then
          Dest.Value.SetDword(LibraryWord)
        else if Value.LibraryFunData[0] = 3 then
          Dest.Value.SetFloat(PSingle(@LibraryWord)^)
        else if Value.LibraryFunData[0] = 4 then
          Dest.Value.SetString(AnsiString('') + PWideChar(LibraryWord));
      end
      else if Callee.RealVType = vkExternFun then
      begin
        SetLength(Arguments, Instruction.OperandCount - 1);
        Arguments[0] := Dest.Value;
        Dest.Value.ResetKind(vkEmpty);
        for j := 2 to Instruction.OperandCount - 1 do
        begin
          Argument := GetVariable(Instruction.Operands[j]).Resolve(vkEmpty);
          Arguments[j - 1] := Argument;
        end;
        if Code <> nil then
        begin
          Code.Process := Process;
          Code.DebugContext := DebugContext;
        end;
        ScriptCallTrace[ScriptCallTracePosition] := Callee;
        ScriptCallTraceCount := Min(20, ScriptCallTraceCount + 1);
        ScriptCallTracePosition := (ScriptCallTracePosition + 1) mod 20;
        TExpressionCallback(Callee.GetExternFun())(Arguments, Code);
      end
      else if Callee.RealVType = vkFunction then
      begin
        if Callee.GetFunction.LocalVar.GetVar('funBaseVarCount').GetInt
            < Instruction.OperandCount - 2 then
          raise ExceptionExpressionEC.Create('Count var error. fun:' + Left.Name);
        Invocation := TCodeEC.Create;
        Invocation.Parent := Callee.GetFunction;
        Invocation.CopyFromFast(Callee.GetFunction);
        for j := 2 to Instruction.OperandCount - 1 do
        begin
          Argument := GetVariable(Instruction.Operands[j]).Resolve(vkEmpty);
          if Invocation.LocalVar.GetItem(j - 2).Kind = vkRef then
            Invocation.LocalVar.GetItem(j - 2).SetRef(Argument)
          else
            Invocation.LocalVar.GetItem(j - 2).Assume(Argument, False);
        end;
        try
          Invocation.LocalVar.GetVar('result').SetRef(Dest.Value);
          if DebugContext = nil then
            Invocation.Run(Process)
          else
            Invocation.RunDebug(Process, DebugContext);
          ScriptCallTrace[ScriptCallTracePosition] := Callee;
          ScriptCallTraceCount := Min(20, ScriptCallTraceCount + 1);
          ScriptCallTracePosition := (ScriptCallTracePosition + 1) mod 20;
        except
          on E: Exception do
          begin
            Invocation.Free;
            if E.ClassName = 'EBreakMessageGI' then
              raise;
            ScriptCallTrace[ScriptCallTracePosition] := Callee;
            ScriptCallTraceCount := Min(20, ScriptCallTraceCount + 1);
            ScriptCallTracePosition := (ScriptCallTracePosition + 1) mod 20;
            raise ExceptionExpressionEC.Create(
                'Error in function ' + Callee.Name + ' (' + E.ClassName + ' ' + E.Message + ')');
          end;
        end;
        Invocation.Free;
      end
      else
        raise ExceptionExpressionEC.Create('Not fun:' + Left.Name);
    end;
    Inc(i);
  end;
end;

function TExpressionEC.GetResult: TVarEC;
begin
  if (ResultIndex < 0) or (GetVariable(ResultIndex).Value = nil) then
    raise ExceptionExpressionEC.Create('Not link var return');
  Result := GetVariable(ResultIndex).Value;
end;

constructor TCompilerEC.Create;
begin
  inherited Create;
end;

destructor TCompilerEC.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TCompilerEC.Clear;
begin
  while First <> nil do
    DeleteUnit(Last);
end;

function TCompilerEC.AddUnit: TCompilerUnitEC;
var
  Item: TCompilerUnitEC;
begin
  Item := TCompilerUnitEC.Create;
  if Last <> nil then
    Last.Next := Item;
  Item.Prev := Last;
  Item.Next := nil;
  Last := Item;
  if First = nil then
    First := Item;
  Result := Item;
end;

procedure TCompilerEC.DeleteUnit(UnitNode: TCompilerUnitEC);
begin
  if UnitNode.Prev <> nil then
    UnitNode.Prev.Next := UnitNode.Next;
  if UnitNode.Next <> nil then
    UnitNode.Next.Prev := UnitNode.Prev;
  if Last = UnitNode then
    Last := UnitNode.Prev;
  if First = UnitNode then
    First := UnitNode.Next;
  UnitNode.Free;
end;

function TCompilerEC.FindReducibleOperator: TCompilerUnitEC;
var
  i: Integer;
  Item, Following: TCompilerUnitEC;
  Candidates: array[0..10] of TCompilerUnitEC;
begin
  for i := 0 to 10 do
    Candidates[i] := nil;
  Item := First;
  while Item <> nil do
  begin
    if Item.Kind = cuUnaryOperator then
    begin
      if (Item.Next <> nil) and (Item.Next.Kind = cuVariable) and (Candidates[0] = nil) then
        Candidates[0] := Item;
    end
    else if Item.Kind = cuBinaryOperator then
    begin
      if (Item.Prev.Kind = cuVariable) and (Item.Next.Kind = cuVariable) then
      begin
        Following := Item.Next.Next;
        while Following <> nil do
        begin
          if (Following.Kind = cuOpenParen)
              or (Following.Kind = cuOpenBracket)
              or (Following.Kind = cuCall)
              or (Following.Kind = cuCloseParen)
              or (Following.Kind = cuCloseBracket) then
            Break;
          Following := Following.Next;
        end;
        if (Following = nil)
            or ((Following.Kind <> cuOpenParen)
                and (Following.Kind <> cuOpenBracket)
                and (Following.Kind <> cuCall)) then
        begin
          if (Item.OperatorToken = ctMultiply)
              or (Item.OperatorToken = ctDivide)
              or (Item.OperatorToken = ctModulo) then
          begin
            if Candidates[1] = nil then
              Candidates[1] := Item;
          end
          else if (Item.OperatorToken = ctAdd) or (Item.OperatorToken = ctSubtract) then
          begin
            if Candidates[2] = nil then
              Candidates[2] := Item;
          end
          else if (Item.OperatorToken = ctShiftLeft) or (Item.OperatorToken = ctShiftRight) then
          begin
            if Candidates[3] = nil then
              Candidates[3] := Item;
          end
          else if (Item.OperatorToken = ctEqual)
              or (Item.OperatorToken = ctNotEqual)
              or (Item.OperatorToken = ctLess)
              or (Item.OperatorToken = ctGreater)
              or (Item.OperatorToken = ctLessEqual)
              or (Item.OperatorToken = ctGreaterEqual) then
          begin
            if Candidates[4] = nil then
              Candidates[4] := Item;
          end
          else if Item.OperatorToken = ctBitAnd then
          begin
            if Candidates[5] = nil then
              Candidates[5] := Item;
          end
          else if Item.OperatorToken = ctBitXor then
          begin
            if Candidates[6] = nil then
              Candidates[6] := Item;
          end
          else if Item.OperatorToken = ctBitOr then
          begin
            if Candidates[7] = nil then
              Candidates[7] := Item;
          end
          else if Item.OperatorToken = ctAnd then
          begin
            if Candidates[8] = nil then
              Candidates[8] := Item;
          end
          else if Item.OperatorToken = ctOr then
          begin
            if Candidates[9] = nil then
              Candidates[9] := Item;
          end;
        end;
      end;
    end
    else if Item.Kind = cuAssignment then
    begin
      if (Item.Prev.Kind = cuVariable)
          and (Item.Next.Kind = cuVariable)
          and (Candidates[10] = nil) then
        Candidates[10] := Item;
    end;
    Item := Item.Next;
  end;
  for i := 0 to 10 do
    if Candidates[i] <> nil then
    begin
      Result := Candidates[i];
      Exit;
    end;
  Result := nil;
end;

function TCompilerEC.FindReducibleIndex: TCompilerUnitEC;
var
  Item, Following: TCompilerUnitEC;
begin
  Item := First;
  while Item <> nil do
  begin
    if Item.Kind = cuIndex then
    begin
      Following := Item.Next;
      while Following <> nil do
      begin
        if Following.Kind = cuCloseBracket then
        begin
          Result := Item;
          Exit;
        end;
        if (Following.Kind <> cuComma) and (Following.Kind <> cuVariable) then
          Break;
        Following := Following.Next;
      end;
    end;
    Item := Item.Next;
  end;
  Result := nil;
end;

function TCompilerEC.FindReducibleCall: TCompilerUnitEC;
var
  Item, Following: TCompilerUnitEC;
begin
  Item := First;
  while Item <> nil do
  begin
    if Item.Kind = cuCall then
    begin
      Following := Item.Next;
      while Following <> nil do
      begin
        if Following.Kind = cuCloseParen then
        begin
          Result := Item;
          Exit;
        end;
        if (Following.Kind <> cuComma) and (Following.Kind <> cuVariable) then
          Break;
        Following := Following.Next;
      end;
    end;
    Item := Item.Next;
  end;
  Result := nil;
end;

destructor TCodeUnitEC.Destroy;
begin
  if Expression <> nil then
  begin
    Expression.Free;
    Expression := nil;
  end;
  inherited Destroy;
end;

constructor TCodeProcessEC.Create;
begin
  inherited Create;
  Handlers := TList.Create;
  Exceptions := TList.Create;
end;

destructor TCodeProcessEC.Destroy;
begin
  Clear;
  Handlers.Free;
  Handlers := nil;
  Exceptions.Free;
  Exceptions := nil;
  inherited Destroy;
end;

procedure TCodeProcessEC.Clear;
var
  Handler: PCodeExceptionHandler;
  Value: PVarEC;
  i: Integer;
begin
  for i := 0 to Handlers.Count - 1 do
  begin
    Handler := Handlers[i];
    HeapFree(GetProcessHeap, 0, Handler);
  end;
  Handlers.Clear;
  for i := 0 to Exceptions.Count - 1 do
  begin
    Value := Exceptions[i];
    if Value^ <> nil then
    begin
      Value^.Free;
      Value^ := nil;
    end;
    HeapFree(GetProcessHeap, 0, Value);
  end;
  Exceptions.Clear;
end;

procedure TCodeProcessEC.PushHandler(Code: TCodeEC; Handler: TCodeUnitEC);
var
  Entry: PCodeExceptionHandler;
begin
  Entry := HeapAlloc(GetProcessHeap, 0, SizeOf(TCodeExceptionHandler));
  Entry.Code := Code;
  Entry.Handler := Handler;
  Handlers.Add(Entry);
end;

procedure TCodeProcessEC.PopHandler;
var
  Entry: PCodeExceptionHandler;
  Count: Integer;
begin
  Count := Handlers.Count;
  if Count < 1 then
    Exit;
  Entry := Handlers[Count - 1];
  HeapFree(GetProcessHeap, 0, Entry);
  Handlers.Delete(Count - 1);
end;

function TCodeProcessEC.GetHandler: PCodeExceptionHandler;
var
  Count: Integer;
begin
  Count := Handlers.Count;
  if Count < 1 then
    Result := nil
  else
    Result := Handlers[Count - 1];
end;

procedure TCodeProcessEC.PushException(Value: TVarEC);
var
  Entry: PVarEC;
begin
  Entry := HeapAlloc(GetProcessHeap, 0, SizeOf(TVarEC));
  Entry^ := TVarEC.Create(Value.RealVType);
  Entry^.Assume(Value, False);
  Exceptions.Add(Entry);
end;

procedure TCodeProcessEC.PopException;
var
  Entry: PVarEC;
  Count: Integer;
begin
  Count := Exceptions.Count;
  if Count < 1 then
    Exit;
  Entry := Exceptions[Count - 1];
  HeapFree(GetProcessHeap, 0, Entry);
  Exceptions.Delete(Count - 1);
end;

function TCodeProcessEC.GetException: PVarEC;
var
  Count: Integer;
begin
  Count := Exceptions.Count;
  if Count < 1 then
    Result := nil
  else
    Result := Exceptions[Count - 1];
end;

procedure TCodeProcessEC.RaiseUnhandledExceptions;
var
  Entry: PVarEC;
  Text: WideString;
  i: Integer;
begin
  Text := '';
  for i := 0 to Exceptions.Count - 1 do
  begin
    Entry := Exceptions[i];
    if i > 0 then
      Text := Text + #13#10;
    Text := Text + 'Exception: ' + Entry^.GetString;
  end;
  if Text <> '' then
    raise ExceptionExpressionEC.Create(Text);
end;

constructor TCodeEC.Create;
begin
  inherited Create;
  LocalVar := TVarArrayEC.Create;
  ScriptFunLinked := False;
end;

destructor TCodeEC.Destroy;
begin
  Clear;
  LocalVar.Free;
  inherited Destroy;
end;

procedure TCodeEC.Clear;
begin
  while First <> nil do
    DeleteCodeUnit(Last);
  LocalVar.Clear;
  ScriptFunLinked := False;
end;

procedure TCodeEC.CopyFrom(Source: TCodeEC);
var
  Dest, Src, DestTarget, SrcTarget: TCodeUnitEC;
begin
  Clear;
  IsClassDefinition := Source.IsClassDefinition;
  Name := Source.Name;
  Parent := Source.Parent;
  Src := Source.First;
  while Src <> nil do
  begin
    Dest := AddCodeUnit;
    Dest.Opcode := Src.Opcode;
    Dest.SourceStart := Src.SourceStart;
    Dest.SourceLength := Src.SourceLength;
    Dest.SourceContext := Src.SourceContext;
    Dest.Target := Src.Target;
    Dest.Breakpoint := Src.Breakpoint;
    Dest.Expression := nil;
    if Src.Expression <> nil then
    begin
      Dest.Expression := TExpressionEC.Create;
      Dest.Expression.CopyFrom(Src.Expression);
    end;
    Src := Src.Next;
  end;
  Src := Source.First;
  Dest := First;
  while Src <> nil do
  begin
    if Src.Target <> nil then
    begin
      SrcTarget := Source.First;
      DestTarget := First;
      while SrcTarget <> nil do
      begin
        if Src.Target = SrcTarget then
          Dest.Target := DestTarget;
        SrcTarget := SrcTarget.Next;
        DestTarget := DestTarget.Next;
      end;
    end;
    Src := Src.Next;
    Dest := Dest.Next;
  end;
  LocalVar.CopyFrom(Source.LocalVar, False);
  ScriptFunLinked := Source.ScriptFunLinked;
end;

procedure TCodeEC.CopyFromFast(Source: TCodeEC);
var
  Dest, Src, DestTarget, SrcTarget: TCodeUnitEC;
begin
  Clear;
  Src := Source.First;
  while Src <> nil do
  begin
    Dest := AddCodeUnit;
    Dest.Opcode := Src.Opcode;
    Dest.SourceStart := Src.SourceStart;
    Dest.SourceLength := Src.SourceLength;
    Dest.SourceContext := Src.SourceContext;
    Dest.Target := Src.Target;
    Dest.Breakpoint := Src.Breakpoint;
    Dest.Expression := nil;
    if Src.Expression <> nil then
    begin
      Dest.Expression := TExpressionEC.Create;
      Dest.Expression.CopyFromFast(Src.Expression);
    end;
    Src := Src.Next;
  end;
  Src := Source.First;
  Dest := First;
  while Src <> nil do
  begin
    if Src.Target <> nil then
    begin
      SrcTarget := Source.First;
      DestTarget := First;
      while SrcTarget <> nil do
      begin
        if Src.Target = SrcTarget then
          Dest.Target := DestTarget;
        SrcTarget := SrcTarget.Next;
        DestTarget := DestTarget.Next;
      end;
    end;
    Src := Src.Next;
    Dest := Dest.Next;
  end;
  LocalVar.CopyFrom(Source.LocalVar, False);
  Src := Source.First;
  Dest := First;
  while Src <> nil do
  begin
    if Src.ExceptionVar <> nil then
      Dest.ExceptionVar := LocalVar.GetVarNE(Src.ExceptionVar.Name);
    Src := Src.Next;
    Dest := Dest.Next;
  end;
  ScriptFunLinked := Source.ScriptFunLinked;
end;

function TCodeEC.FindVar(Name: WideString): TVarEC;
var
  Item: TVarEC;
  i: Integer;
begin
  Result := LocalVar.GetVarNE(Name);
  if Result <> nil then
    Exit;
  for i := 0 to LocalVar.Count - 1 do
  begin
    Item := LocalVar.GetItem(i);
    if (Item.Kind = vkFunction) and Item.FunctionValue.IsClassDefinition then
    begin
      Result := Item.FunctionValue.FindVar(Name);
      if Result <> nil then
        Exit;
    end;
  end;
end;

procedure TCodeEC.DeleteCodeUnit(CodeUnit: TCodeUnitEC);
begin
  if CodeUnit.Prev <> nil then
    CodeUnit.Prev.Next := CodeUnit.Next;
  if CodeUnit.Next <> nil then
    CodeUnit.Next.Prev := CodeUnit.Prev;
  if Last = CodeUnit then
    Last := CodeUnit.Prev;
  if First = CodeUnit then
    First := CodeUnit.Next;
  CodeUnit.Free;
end;

function TCodeEC.AddCodeUnit: TCodeUnitEC;
var
  Item: TCodeUnitEC;
begin
  Item := TCodeUnitEC.Create;
  if Last <> nil then
    Last.Next := Item;
  Item.Prev := Last;
  Item.Next := nil;
  Last := Item;
  if First = nil then
    First := Item;
  Result := Item;
end;

function TCodeEC.InsertCodeUnitBefore(BeforeUnit: TCodeUnitEC): TCodeUnitEC;
var
  Item: TCodeUnitEC;
begin
  if BeforeUnit = nil then
  begin
    Result := AddCodeUnit;
    Exit;
  end;
  Item := TCodeUnitEC.Create;
  Item.Prev := BeforeUnit.Prev;
  Item.Next := BeforeUnit;
  if BeforeUnit.Prev <> nil then
    BeforeUnit.Prev.Next := Item;
  BeforeUnit.Prev := Item;
  if First = BeforeUnit then
    First := Item;
  Result := Item;
end;

procedure TCodeEC.Compile(
    Analyzer: TCodeAnalyzerEC;
    SourceContext: Pointer;
    IncludeResolver: TScriptIncludeResolver;
    FirstToken: TCodeAnalyzerUnitEC;
    NextToken: PCodeAnalyzerUnitEC;
    var ErrorText: WideString
);
begin
  ErrorText := '';
  if FirstToken = nil then
    FirstToken := Analyzer.First;
  CompileBlock(
      Analyzer,
      SourceContext,
      IncludeResolver,
      FirstToken,
      nil,
      NextToken,
      nil,
      nil,
      nil,
      ErrorText
  );
end;

procedure TCodeEC.CompileBlock(
    Analyzer: TCodeAnalyzerEC;
    SourceContext: Pointer;
    IncludeResolver: TScriptIncludeResolver;
    Token: TCodeAnalyzerUnitEC;
    BeforeUnit: TCodeUnitEC;
    NextToken, StatementEnd: PCodeAnalyzerUnitEC;
    BreakTarget, ContinueTarget: TCodeUnitEC;
    var ErrorText: WideString
);
var
  Included: TCodeAnalyzerEC;
  IncludedContext: Pointer;
  Next: TCodeAnalyzerUnitEC;
  Keyword: WideString;
  Item, LoopStart, StepStart, EndLabel, Branch: TCodeUnitEC;
  Depth: Integer;
  Value, BaseValue: TVarEC;
  Definition: TCodeEC;
  ParameterCount: Integer;
  FloatValue: Double;
  DwordValue: Dword;
  IntValue: Integer;
  Text: WideString;
  InsertSource: Boolean;
  procedure AddScriptLocal(
      TypeName,
      Name: WideString
  ); // @addr $46D2E8 @ida "void __usercall $name(unsigned __int16 *TypeName@<eax>, unsigned __int16 *Name@<edx>, void *ParentFrame@<^0>);"
  begin
    if TypeName = 'unknown' then
      LocalVar.Add(Name, vkEmpty)
    else if TypeName = 'int' then
      LocalVar.Add(Name, vkInt)
    else if TypeName = 'dword' then
      LocalVar.Add(Name, vkDword)
    else if TypeName = 'float' then
      LocalVar.Add(Name, vkFloat)
    else if TypeName = 'str' then
      LocalVar.Add(Name, vkString)
    else if TypeName = 'ref' then
      LocalVar.Add(Name, vkRef)
    else if TypeName = 'array' then
      LocalVar.Add(Name, vkArray);
  end;
  function IsScriptLocalDeclaration(
      Token: TCodeAnalyzerUnitEC
  ): Boolean; // @addr $46D4A4 @ida "bool __usercall $name@<al>(TCodeAnalyzerUnitEC *Token@<eax>, void *ParentFrame@<^0>);"
  begin
    Result :=
        (Token <> nil)
            and (Token.Next <> nil)
            and (Token.Next.TokenKind = ctText)
            and (Token.TokenKind = ctText)
            and ((Token.Text = 'unknown')
                or (Token.Text = 'int')
                or (Token.Text = 'dword')
                or (Token.Text = 'float')
                or (Token.Text = 'str')
                or (Token.Text = 'ref')
                or (Token.Text = 'array'))
            and IsNonIntegerScriptText(Token.Next.Text);
  end;
  function CompileScriptLocals(
      var Token: TCodeAnalyzerUnitEC
  ): WideString; // @addr $46D5EC @ida "void __usercall $name(TCodeAnalyzerUnitEC **Token@<eax>, unsigned __int16 **Result@<edx>, void *ParentFrame@<^0>);"
  var
    Item: TCodeUnitEC;
    Next: TCodeAnalyzerUnitEC;
    TypeName: WideString;
  begin
    Result := '';
    TypeName := Token.Text;
    Token := Token.Next;
    while (Token.TokenKind = ctText) and IsNonIntegerScriptText(Token.Text) do
    begin
      if LocalVar.GetVarNE(Token.Text) <> nil then
      begin
        FormatScriptError(0, Token.SourceStart, Result);
        Exit;
      end;
      AddScriptLocal(TypeName, Token.Text);
      if Token.Next = nil then
      begin
        FormatScriptError(0, Token.SourceStart + Token.SourceLength, Result);
        Exit;
      end;
      Token := Token.Next;
      if Token.TokenKind = ctComma then
      begin
        Token := Token.Next;
        Continue;
      end;
      if Token.TokenKind = ctAssign then
      begin
        Item := InsertCodeUnitBefore(BeforeUnit);
        Item.Opcode := coExpression;
        Item.Expression := TExpressionEC.Create;
        Item.SourceStart := Token.Prev.SourceStart;
        Item.SourceLength := 0;
        Item.SourceContext := SourceContext;
        Item.Expression.Compile(Analyzer, Token.Prev, nil, @Next, Result);
        if Result <> '' then
          Exit;
        Item.SourceLength := Next.Prev.SourceStart + Next.Prev.SourceLength - Item.SourceStart;
        Token := Next;
        if Token.TokenKind = ctComma then
          Token := Token.Next;
      end;
    end;
  end;
begin
  ErrorText := '';
  Depth := 0;
  while Token <> nil do
  begin
    if Token.TokenKind = ctText then
    begin
      Keyword := LowerCase(AnsiString(Token.Text));
      if IsScriptLocalDeclaration(Token) then
      begin
        ErrorText := CompileScriptLocals(Token);
        if ErrorText <> '' then
          Exit;
        if Token.TokenKind <> ctSemicolon then
        begin
          FormatScriptError(0, Token.SourceStart, ErrorText);
          Exit;
        end;
        Token := Token.Next;
        if (StatementEnd <> nil) and (Depth = 0) then
        begin
          StatementEnd^ := Token;
          Exit;
        end;
        Continue;
      end
      else if Keyword = 'if' then
      begin
        EndLabel := InsertCodeUnitBefore(BeforeUnit);
        EndLabel.Opcode := coLabel;
        EndLabel.SourceStart := 0;
        EndLabel.SourceLength := 0;
        EndLabel.SourceContext := SourceContext;
        while True do
        begin
          if Token.Next = nil then
          begin
            FormatScriptError(0, Token.SourceStart, ErrorText);
            Exit;
          end;
          if (Token.Next.TokenKind <> ctOpenParen) or (Token.Next.Next = nil) then
          begin
            FormatScriptError(0, Token.Next.SourceStart, ErrorText);
            Exit;
          end;
          Item := InsertCodeUnitBefore(EndLabel);
          Item.Opcode := coBranchFalse;
          Item.SourceStart := Token.SourceStart;
          Item.SourceLength := 0;
          Item.SourceContext := SourceContext;
          Item.Target := EndLabel;
          Item.Expression := TExpressionEC.Create;
          Item.Expression.Compile(Analyzer, Token.Next.Next, nil, @Next, ErrorText);
          if ErrorText <> '' then
            Exit;
          if Next = nil then
          begin
            FormatScriptError(0, Token.SourceStart, ErrorText);
            Exit;
          end;
          if Next.TokenKind <> ctCloseParen then
          begin
            FormatScriptError(0, Next.SourceStart, ErrorText);
            Exit;
          end;
          Token := Next.Next;
          Item.SourceLength := Next.SourceStart - Item.SourceStart + Next.SourceLength;
          Branch := Item;
          if Token = nil then
            raise ExceptionExpressionEC.Create('Compiler error, code ends abruptly');
          Item := InsertCodeUnitBefore(EndLabel);
          Item.Opcode := coJump;
          Item.SourceStart := Token.SourceStart;
          Item.SourceLength := 0;
          Item.SourceContext := SourceContext;
          Item.Target := EndLabel;
          LoopStart := Item;
          if Token.TokenKind = ctSemicolon then
            Token := Token.Next
          else
          begin
            CompileBlock(
                Analyzer,
                SourceContext,
                IncludeResolver,
                Token,
                LoopStart,
                NextToken,
                @Token,
                BreakTarget,
                ContinueTarget,
                ErrorText
            );
            if ErrorText <> '' then
              Exit;
          end;
          if Token = nil then
            Exit;
          if Token.TokenKind <> ctText then
            Break;
          Keyword := LowerCase(AnsiString(Token.Text));
          if Keyword <> 'else' then
            Break;
          Item := InsertCodeUnitBefore(EndLabel);
          Item.Opcode := coLabel;
          Item.SourceStart := 0;
          Item.SourceLength := 0;
          Item.SourceContext := SourceContext;
          Branch.Target := Item;
          if (Token.Next <> nil)
              and (Token.Next.TokenKind = ctText)
              and (LowerCase(AnsiString(Token.Next.Text)) = 'if') then
          begin
            Token := Token.Next;
            Continue;
          end;
          if Token.Next = nil then
          begin
            FormatScriptError(0, Token.SourceStart, ErrorText);
            Exit;
          end;
          if Token.Next.TokenKind = ctSemicolon then
            Continue;
          CompileBlock(
              Analyzer,
              SourceContext,
              IncludeResolver,
              Token.Next,
              EndLabel,
              NextToken,
              @Token,
              BreakTarget,
              ContinueTarget,
              ErrorText
          );
          if ErrorText <> '' then
            Exit;
          if (StatementEnd <> nil) and (Depth = 0) then
          begin
            StatementEnd^ := Token;
            Exit;
          end;
          Break;
        end;
        Continue;
      end
      else if Keyword = 'while' then
      begin
        EndLabel := InsertCodeUnitBefore(BeforeUnit);
        EndLabel.Opcode := coLabel;
        EndLabel.SourceStart := 0;
        EndLabel.SourceLength := 0;
        EndLabel.SourceContext := SourceContext;
        if Token.Next = nil then
        begin
          FormatScriptError(0, Token.SourceStart, ErrorText);
          Exit;
        end;
        if (Token.Next.TokenKind <> ctOpenParen) or (Token.Next.Next = nil) then
        begin
          FormatScriptError(0, Token.Next.SourceStart, ErrorText);
          Exit;
        end;
        Item := InsertCodeUnitBefore(EndLabel);
        Item.Opcode := coBranchFalse;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := 0;
        Item.SourceContext := SourceContext;
        Item.Target := EndLabel;
        Item.Expression := TExpressionEC.Create;
        Item.Expression.Compile(Analyzer, Token.Next.Next, nil, @Next, ErrorText);
        if ErrorText <> '' then
          Exit;
        if Next = nil then
        begin
          FormatScriptError(0, Token.SourceStart, ErrorText);
          Exit;
        end;
        if Next.TokenKind <> ctCloseParen then
        begin
          FormatScriptError(0, Next.SourceStart, ErrorText);
          Exit;
        end;
        Token := Next.Next;
        Item.SourceLength := Next.SourceStart - Item.SourceStart + Next.SourceLength;
        LoopStart := Item;
        Item := InsertCodeUnitBefore(EndLabel);
        Item.Opcode := coJump;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := 0;
        Item.SourceContext := SourceContext;
        Item.Target := LoopStart;
        if Token.TokenKind = ctSemicolon then
          Token := Token.Next
        else
        begin
          CompileBlock(
              Analyzer,
              SourceContext,
              IncludeResolver,
              Token,
              Item,
              NextToken,
              @Token,
              EndLabel,
              LoopStart,
              ErrorText
          );
          if ErrorText <> '' then
            Exit;
        end;
        if (StatementEnd <> nil) and (Depth = 0) then
        begin
          StatementEnd^ := Token;
          Exit;
        end;
        Continue;
      end
      else if Keyword = 'for' then
      begin
        if Token.Next = nil then
        begin
          FormatScriptError(0, Token.SourceStart, ErrorText);
          Exit;
        end;
        if Token.Next.TokenKind <> ctOpenParen then
        begin
          FormatScriptError(0, Token.Next.SourceStart, ErrorText);
          Exit;
        end;
        if Token.Next.Next = nil then
        begin
          FormatScriptError(0, Token.Next.SourceStart + Token.Next.SourceLength, ErrorText);
          Exit;
        end;
        Token := Token.Next.Next;
        if Token.TokenKind <> ctSemicolon then
        begin
          if IsScriptLocalDeclaration(Token) then
          begin
            ErrorText := CompileScriptLocals(Token);
            if ErrorText <> '' then
              Exit;
          end
          else
          begin
            while True do
            begin
              Item := InsertCodeUnitBefore(BeforeUnit);
              Item.Opcode := coExpression;
              Item.SourceStart := Token.SourceStart;
              Item.SourceLength := 0;
              Item.SourceContext := SourceContext;
              Item.Expression := TExpressionEC.Create;
              Item.Expression.Compile(Analyzer, Token, nil, @Next, ErrorText);
              if ErrorText <> '' then
                Exit;
              if Next = nil then
              begin
                FormatScriptError(0, Token.SourceStart, ErrorText);
                Exit;
              end;
              Item.SourceLength := Next.SourceStart - Item.SourceStart + Next.SourceLength;
              if Next.TokenKind = ctSemicolon then
              begin
                Token := Next;
                Break;
              end
              else if Next.TokenKind = ctComma then
                Token := Next.Next
              else
              begin
                FormatScriptError(0, Next.SourceStart, ErrorText);
                Exit;
              end;
            end;
          end;
        end;
        if Token.TokenKind <> ctSemicolon then
        begin
          FormatScriptError(0, Token.SourceStart, ErrorText);
          Exit;
        end;
        if Token.Next = nil then
        begin
          FormatScriptError(0, Token.SourceStart + Token.SourceLength, ErrorText);
          Exit;
        end;
        Token := Token.Next;
        EndLabel := InsertCodeUnitBefore(BeforeUnit);
        EndLabel.Opcode := coLabel;
        EndLabel.SourceStart := 0;
        EndLabel.SourceLength := 0;
        EndLabel.SourceContext := SourceContext;
        if Token.TokenKind = ctSemicolon then
        begin
          Item := InsertCodeUnitBefore(EndLabel);
          Item.Opcode := coLabel;
          Item.SourceStart := Token.SourceStart;
          Item.SourceLength := 0;
          Item.SourceContext := SourceContext;
          Token := Token.Next;
        end
        else
        begin
          Item := InsertCodeUnitBefore(EndLabel);
          Item.Opcode := coBranchFalse;
          Item.SourceStart := Token.SourceStart;
          Item.SourceLength := 0;
          Item.SourceContext := SourceContext;
          Item.Target := EndLabel;
          Item.Expression := TExpressionEC.Create;
          Item.Expression.Compile(Analyzer, Token, nil, @Next, ErrorText);
          if ErrorText <> '' then
            Exit;
          if Next = nil then
          begin
            FormatScriptError(0, Token.SourceStart, ErrorText);
            Exit;
          end;
          if Next.TokenKind <> ctSemicolon then
          begin
            FormatScriptError(0, Next.SourceStart, ErrorText);
            Exit;
          end;
          if Next.Next = nil then
          begin
            FormatScriptError(0, Next.SourceStart + Next.SourceLength, ErrorText);
            Exit;
          end;
          Token := Next.Next;
          Item.SourceLength := Next.Prev.SourceStart - Item.SourceStart + Next.Prev.SourceLength;
        end;
        LoopStart := Item;
        Item := InsertCodeUnitBefore(LoopStart);
        Item.Opcode := coJump;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := 0;
        Item.SourceContext := SourceContext;
        Item.Target := LoopStart;
        StepStart := nil;
        if Token.TokenKind = ctCloseParen then
        begin
          Item := InsertCodeUnitBefore(LoopStart);
          Item.Opcode := coLabel;
          Item.SourceStart := Token.SourceStart;
          Item.SourceLength := 0;
          Item.SourceContext := SourceContext;
          StepStart := Item;
          Token := Token.Next;
        end
        else
        begin
          while True do
          begin
            Item := InsertCodeUnitBefore(LoopStart);
            Item.Opcode := coExpression;
            Item.SourceStart := Token.SourceStart;
            Item.SourceLength := 0;
            Item.SourceContext := SourceContext;
            Item.Expression := TExpressionEC.Create;
            Item.Expression.Compile(Analyzer, Token, nil, @Next, ErrorText);
            if ErrorText <> '' then
              Exit;
            if Next = nil then
            begin
              FormatScriptError(0, Token.SourceStart, ErrorText);
              Exit;
            end;
            Item.SourceLength := Next.Prev.SourceStart - Item.SourceStart + Next.Prev.SourceLength;
            if StepStart = nil then
              StepStart := Item;
            if Next.TokenKind = ctCloseParen then
            begin
              Token := Next.Next;
              Break;
            end
            else if Next.TokenKind = ctComma then
              Token := Next.Next
            else
            begin
              FormatScriptError(0, Next.SourceStart, ErrorText);
              Exit;
            end;
          end;
        end;
        Item := InsertCodeUnitBefore(EndLabel);
        Item.Opcode := coJump;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := 0;
        Item.SourceContext := SourceContext;
        Item.Target := StepStart;
        if Token.TokenKind = ctSemicolon then
          Token := Token.Next
        else
        begin
          CompileBlock(
              Analyzer,
              SourceContext,
              IncludeResolver,
              Token,
              Item,
              NextToken,
              @Token,
              EndLabel,
              StepStart,
              ErrorText
          );
          if ErrorText <> '' then
            Exit;
        end;
        if (StatementEnd <> nil) and (Depth = 0) then
        begin
          StatementEnd^ := Token;
          Exit;
        end;
        Continue;
      end
      else if Keyword = 'break' then
      begin
        if (BreakTarget = nil) or (Token.Next = nil) then
        begin
          FormatScriptError(0, Token.SourceStart, ErrorText);
          Exit;
        end;
        if Token.Next.TokenKind <> ctSemicolon then
        begin
          FormatScriptError(0, Token.Next.SourceStart, ErrorText);
          Exit;
        end;
        Item := InsertCodeUnitBefore(BeforeUnit);
        Item.Opcode := coJump;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := Token.Next.SourceStart - Token.SourceStart + Token.Next.SourceLength;
        Item.SourceContext := SourceContext;
        Item.Target := BreakTarget;
        Token := Token.Next.Next;
        if (StatementEnd <> nil) and (Depth = 0) then
        begin
          StatementEnd^ := Token;
          Exit;
        end;
        Continue;
      end
      else if Keyword = 'continue' then
      begin
        if (ContinueTarget = nil) or (Token.Next = nil) then
        begin
          FormatScriptError(0, Token.SourceStart, ErrorText);
          Exit;
        end;
        if Token.Next.TokenKind <> ctSemicolon then
        begin
          FormatScriptError(0, Token.Next.SourceStart, ErrorText);
          Exit;
        end;
        Item := InsertCodeUnitBefore(BeforeUnit);
        Item.Opcode := coJump;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := Token.Next.SourceStart - Token.SourceStart + Token.Next.SourceLength;
        Item.SourceContext := SourceContext;
        Item.Target := ContinueTarget;
        Token := Token.Next.Next;
        if (StatementEnd <> nil) and (Depth = 0) then
        begin
          StatementEnd^ := Token;
          Exit;
        end;
        Continue;
      end
      else if Keyword = 'exit' then
      begin
        if Token.Next = nil then
        begin
          FormatScriptError(0, Token.SourceStart + Token.SourceLength, ErrorText);
          Exit;
        end;
        if Token.Next.TokenKind <> ctSemicolon then
        begin
          FormatScriptError(0, Token.Next.SourceStart, ErrorText);
          Exit;
        end;
        Item := InsertCodeUnitBefore(BeforeUnit);
        Item.Opcode := coExit;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := Token.Next.SourceStart - Token.SourceStart + Token.Next.SourceLength;
        Item.SourceContext := SourceContext;
        Token := Token.Next.Next;
        if (StatementEnd <> nil) and (Depth = 0) then
        begin
          StatementEnd^ := Token;
          Exit;
        end;
        Continue;
      end
      else if (Keyword = '#include') or (Keyword = '#insert') then
      begin
        if Token.Next = nil then
        begin
          FormatScriptError(0, Token.SourceStart + Token.SourceLength, ErrorText);
          Exit;
        end;
        if Token.Next.TokenKind <> ctStringLiteral then
        begin
          FormatScriptError(0, Token.Next.SourceStart, ErrorText);
          Exit;
        end;
        if not Assigned(IncludeResolver) then
        begin
          FormatScriptError(0, Token.SourceStart, ErrorText);
          Exit;
        end;
        InsertSource := Keyword = '#insert';
        Included := TCodeAnalyzerEC.Create;
        IntValue :=
            IncludeResolver(
                SourceContext,
                Token.Next.Text,
                InsertSource,
                IncludedContext,
                Included
            );
        if (IntValue = 2) or (IntValue = 3) then
        begin
          Included.Free;
          FormatScriptError(0, Token.Next.SourceStart, ErrorText);
          Exit;
        end;
        if IntValue = 0 then
        begin
          Text := Included.ValidateDelimiters;
          if Text <> '' then
          begin
            Included.Free;
            FormatScriptError(0, Token.Next.SourceStart, ErrorText);
            Exit;
          end;
          CompileBlock(
              Included,
              IncludedContext,
              IncludeResolver,
              Included.First,
              BeforeUnit,
              nil,
              nil,
              nil,
              nil,
              ErrorText
          );
          if ErrorText <> '' then
          begin
            Included.Free;
            Exit;
          end;
        end;
        Included.Free;
        Token := Token.Next.Next;
        Continue;
      end
      else if Keyword = 'function' then
      begin
        if Token.Next = nil then
        begin
          FormatScriptError(0, Token.SourceStart + Token.SourceLength, ErrorText);
          Exit;
        end;
        if (Token.Next.TokenKind <> ctText)
            or not IsNonIntegerScriptText(Token.Next.Text)
            or (Token.Next.Next = nil) then
        begin
          FormatScriptError(0, Token.Next.SourceStart, ErrorText);
          Exit;
        end;
        if (Token.Next.Next.TokenKind <> ctOpenParen) or (Token.Next.Next.Next = nil) then
        begin
          FormatScriptError(0, Token.Next.Next.SourceStart, ErrorText);
          Exit;
        end;
        Value := LocalVar.Add(Token.Next.Text, vkFunction);
        Definition := Value.GetFunction;
        Definition.Parent := Self;
        Next := Token.Next.Next.Next;
        while (Next <> nil) and (Next.TokenKind = ctText) and IsNonIntegerScriptText(Next.Text) do
        begin
          Keyword := LowerCase(AnsiString(Next.Text));
          if (Keyword = 'unknown')
              or (Keyword = 'int')
              or (Keyword = 'dword')
              or (Keyword = 'float')
              or (Keyword = 'str')
              or (Keyword = 'ref')
              or (Keyword = 'array') then
            Next := Next.Next
          else
            Keyword := 'unknown';
          if (Next = nil)
              or (Next.TokenKind <> ctText)
              or not IsNonIntegerScriptText(Next.Text) then
            Break;
          Value := nil;
          if Keyword = 'unknown' then
            Value := Definition.LocalVar.Add(Next.Text, vkEmpty)
          else if Keyword = 'int' then
            Value := Definition.LocalVar.Add(Next.Text, vkInt)
          else if Keyword = 'dword' then
            Value := Definition.LocalVar.Add(Next.Text, vkDword)
          else if Keyword = 'float' then
            Value := Definition.LocalVar.Add(Next.Text, vkFloat)
          else if Keyword = 'str' then
            Value := Definition.LocalVar.Add(Next.Text, vkString)
          else if Keyword = 'ref' then
            Value := Definition.LocalVar.Add(Next.Text, vkRef)
          else if Keyword = 'array' then
            Value := Definition.LocalVar.Add(Next.Text, vkArray);
          Next := Next.Next;
          if Next = nil then
          begin
            FormatScriptError(0, Analyzer.Last.SourceStart + Analyzer.Last.SourceLength, ErrorText);
            Exit;
          end;
          if (Keyword <> 'ref') and (Next.TokenKind = ctAssign) then
          begin
            if Next.Next = nil then
            begin
              FormatScriptError(
                  0,
                  Analyzer.Last.SourceStart + Analyzer.Last.SourceLength,
                  ErrorText
              );
              Exit;
            end;
            Next := Next.Next;
            if TryReadFloatLiteral(Next, FloatValue) then
              Value.SetFloat(FloatValue)
            else if TryReadDwordLiteral(Next, DwordValue) then
              Value.SetDword(DwordValue)
            else if TryReadIntegerLiteral(Next, IntValue) then
              Value.SetInt(IntValue)
            else if TryReadStringLiteral(Next, Text) then
              Value.SetString(Text)
            else
            begin
              FormatScriptError(0, Next.SourceStart, ErrorText);
              Exit;
            end;
          end;
          if (Next = nil) or (Next.TokenKind <> ctComma) then
            Break;
          Next := Next.Next;
        end;
        if (Next = nil) or (Next.TokenKind <> ctCloseParen) then
        begin
          FormatScriptError(0, Token.Next.Next.Next.SourceStart, ErrorText);
          Exit;
        end;
        Token := Next.Next;
        if Token = nil then
        begin
          FormatScriptError(0, Next.SourceStart, ErrorText);
          Exit;
        end;
        if (Token.TokenKind <> ctOpenBrace) or (Token.Next = nil) then
        begin
          FormatScriptError(0, Token.SourceStart, ErrorText);
          Exit;
        end;
        ParameterCount := Definition.LocalVar.Count;
        Definition.LocalVar.Add('funBaseVarCount', vkInt).SetInt(ParameterCount);
        Definition.LocalVar.Add('result', vkRef);
        Next := nil;
        Definition.Compile(Analyzer, SourceContext, IncludeResolver, Token.Next, @Next, ErrorText);
        if ErrorText <> '' then
          Exit;
        if Next = nil then
        begin
          FormatScriptError(0, Analyzer.Last.SourceStart + Analyzer.Last.SourceLength, ErrorText);
          Exit;
        end;
        if Next.TokenKind <> ctCloseBrace then
        begin
          FormatScriptError(0, Next.SourceStart, ErrorText);
          Exit;
        end;
        Token := Next.Next;
        Continue;
      end
      else if Keyword = 'class' then
      begin
        if Token.Next = nil then
        begin
          FormatScriptError(0, Token.SourceStart + Token.SourceLength, ErrorText);
          Exit;
        end;
        if (Token.Next.TokenKind <> ctText) or not IsNonIntegerScriptText(Token.Next.Text) then
        begin
          FormatScriptError(0, Token.Next.SourceStart, ErrorText);
          Exit;
        end;
        if Token.Next.Next = nil then
        begin
          FormatScriptError(0, Token.Next.SourceStart + Token.Next.SourceLength, ErrorText);
          Exit;
        end;
        Value := LocalVar.Add(Token.Next.Text, vkFunction);
        Definition := Value.GetFunction;
        Definition.Parent := Self;
        Definition.IsClassDefinition := True;
        Definition.Name := Token.Next.Text;
        Token := Token.Next.Next;
        if Token.TokenKind = ctColon then
        begin
          Token := Token.Next;
          while True do
          begin
            if Token.TokenKind <> ctText then
              Break;
            BaseValue := LocalVar.GetVarNE(Token.Text);
            if (BaseValue = nil) or (BaseValue.RealVType <> vkFunction) then
            begin
              FormatScriptError(0, Token.SourceStart, ErrorText);
              Exit;
            end;
            Definition
                .LocalVar
                .Add(Token.Text, vkFunction)
                .GetFunction
                .CopyFrom(BaseValue.GetFunction);
            Token := Token.Next;
            if Token.TokenKind <> ctComma then
              Break;
            Token := Token.Next;
          end;
        end;
        if Token.TokenKind <> ctOpenBrace then
        begin
          FormatScriptError(0, Token.SourceStart, ErrorText);
          Exit;
        end;
        Next := nil;
        Definition.Compile(Analyzer, SourceContext, IncludeResolver, Token.Next, @Next, ErrorText);
        if ErrorText <> '' then
          Exit;
        if Next = nil then
        begin
          FormatScriptError(0, Analyzer.Last.SourceStart + Analyzer.Last.SourceLength, ErrorText);
          Exit;
        end;
        if Next.TokenKind <> ctCloseBrace then
        begin
          FormatScriptError(0, Next.SourceStart, ErrorText);
          Exit;
        end;
        Token := Next.Next;
        Continue;
      end
      else if Keyword = 'try' then
      begin
        if Token.Next = nil then
        begin
          FormatScriptError(0, Token.SourceStart + Token.SourceLength, ErrorText);
          Exit;
        end;
        if Token.Next.TokenKind <> ctOpenBrace then
        begin
          FormatScriptError(0, Token.Next.SourceStart, ErrorText);
          Exit;
        end;
        LoopStart := InsertCodeUnitBefore(BeforeUnit);
        LoopStart.Opcode := coPushHandler;
        LoopStart.SourceStart := Token.SourceStart;
        LoopStart.SourceLength := 0;
        LoopStart.SourceContext := SourceContext;
        CompileBlock(
            Analyzer,
            SourceContext,
            IncludeResolver,
            Token.Next,
            BeforeUnit,
            NextToken,
            @Token,
            nil,
            nil,
            ErrorText
        );
        if ErrorText <> '' then
          Exit;
        Item := InsertCodeUnitBefore(BeforeUnit);
        Item.Opcode := coPopHandler;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := 0;
        Item.SourceContext := SourceContext;
        if Token = nil then
        begin
          FormatScriptError(0, Token.SourceStart + Token.SourceLength, ErrorText);
          Exit;
        end;
        if Token.TokenKind <> ctText then
        begin
          FormatScriptError(1001, Token.SourceStart, ErrorText);
          Exit;
        end;
        if (Token.Text <> 'catch') and (Token.Text <> 'finally') then
        begin
          FormatScriptError(1001, Token.SourceStart, ErrorText);
          Exit;
        end;
        if Token.Next = nil then
        begin
          FormatScriptError(1001, Token.SourceStart + Token.SourceLength, ErrorText);
          Exit;
        end;
        if Token.Text = 'catch' then
          IntValue := 0
        else
          IntValue := 1;
        Token := Token.Next;
        Value := nil;
        if Token.TokenKind = ctOpenParen then
        begin
          if Token.Next = nil then
          begin
            FormatScriptError(1001, Token.SourceStart + Token.SourceLength, ErrorText);
            Exit;
          end;
          Token := Token.Next;
          if Token.TokenKind <> ctText then
          begin
            FormatScriptError(1001, Token.SourceStart, ErrorText);
            Exit;
          end;
          Value := LocalVar.Add(Token.Text, vkEmpty);
          if Token.Next = nil then
          begin
            FormatScriptError(1001, Token.SourceStart + Token.SourceLength, ErrorText);
            Exit;
          end;
          Token := Token.Next;
          if Token.TokenKind <> ctCloseParen then
          begin
            FormatScriptError(1001, Token.SourceStart, ErrorText);
            Exit;
          end;
          if Token.Next = nil then
          begin
            FormatScriptError(1001, Token.SourceStart + Token.SourceLength, ErrorText);
            Exit;
          end;
          Token := Token.Next;
        end;
        if Token.TokenKind <> ctOpenBrace then
        begin
          FormatScriptError(1001, Token.SourceStart, ErrorText);
          Exit;
        end;
        EndLabel := InsertCodeUnitBefore(BeforeUnit);
        EndLabel.Opcode := coLabel;
        EndLabel.SourceStart := 0;
        EndLabel.SourceLength := 0;
        EndLabel.SourceContext := SourceContext;
        if IntValue = 0 then
        begin
          Item := InsertCodeUnitBefore(EndLabel);
          Item.Opcode := coJump;
          Item.SourceStart := Token.SourceStart;
          Item.SourceLength := 0;
          Item.SourceContext := SourceContext;
          Item.Target := EndLabel;
        end;
        Item := InsertCodeUnitBefore(EndLabel);
        Item.Opcode := coLabel;
        Item.SourceStart := 0;
        Item.SourceLength := 0;
        Item.SourceContext := SourceContext;
        LoopStart.Target := Item;
        Item.ExceptionVar := Value;
        Item := EndLabel;
        if IntValue = 1 then
        begin
          Item := InsertCodeUnitBefore(Item);
          Item.Opcode := coThrow;
          Item.SourceStart := Token.SourceStart;
          Item.SourceLength := 0;
          Item.SourceContext := SourceContext;
        end;
        CompileBlock(
            Analyzer,
            SourceContext,
            IncludeResolver,
            Token,
            Item,
            NextToken,
            @Token,
            nil,
            nil,
            ErrorText
        );
        if ErrorText <> '' then
          Exit;
        if (StatementEnd <> nil) and (Depth = 0) then
        begin
          StatementEnd^ := Token;
          Exit;
        end;
        Continue;
      end
      else if Keyword = 'throw' then
      begin
        if Token.Next = nil then
        begin
          FormatScriptError(0, Token.SourceStart + Token.SourceLength, ErrorText);
          Exit;
        end;
        if Token.Next.TokenKind = ctSemicolon then
        begin
          Item := InsertCodeUnitBefore(BeforeUnit);
          Item.Opcode := coThrow;
          Item.SourceStart := Token.SourceStart;
          Item.SourceLength := Token.Next.SourceStart - Token.SourceStart + Token.Next.SourceLength;
          Item.SourceContext := SourceContext;
          Token := Token.Next.Next;
        end
        else
        begin
          Item := InsertCodeUnitBefore(BeforeUnit);
          Item.Opcode := coThrow;
          Item.SourceStart := Token.SourceStart;
          Item.SourceLength := Token.Next.SourceStart - Token.SourceStart + Token.Next.SourceLength;
          Item.SourceContext := SourceContext;
          Item.Expression := TExpressionEC.Create;
          Item.Expression.Compile(Analyzer, Token.Next, nil, @Next, ErrorText);
          if ErrorText <> '' then
            Exit;
          if Next = nil then
          begin
            FormatScriptError(0, Token.SourceStart, ErrorText);
            Exit;
          end;
          if Next.TokenKind <> ctSemicolon then
          begin
            FormatScriptError(0, Next.SourceStart, ErrorText);
            Exit;
          end;
          Token := Next.Next;
          Item.SourceLength := Next.SourceStart - Item.SourceStart + Next.SourceLength;
        end;
        if (StatementEnd <> nil) and (Depth = 0) then
        begin
          StatementEnd^ := Token;
          Exit;
        end;
        Continue;
      end
      else
      begin
        Item := InsertCodeUnitBefore(BeforeUnit);
        Item.Opcode := coExpression;
        Item.Expression := TExpressionEC.Create;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := 0;
        Item.SourceContext := SourceContext;
        Item.Expression.Compile(Analyzer, Token, nil, @Next, ErrorText);
        if ErrorText <> '' then
          Exit;
        if Next = nil then
        begin
          FormatScriptError(0, Analyzer.Last.SourceStart + Analyzer.Last.SourceLength, ErrorText);
          Exit;
        end;
        if Next.TokenKind <> ctSemicolon then
        begin
          FormatScriptError(0, Next.SourceStart, ErrorText);
          Exit;
        end;
        Item.SourceLength := Next.SourceStart + Next.SourceLength - Item.SourceStart;
        if (StatementEnd <> nil) and (Depth = 0) then
        begin
          StatementEnd^ := Next.Next;
          Exit;
        end;
        Token := Next.Next;
        Continue;
      end;
    end
    else if Token.TokenKind = ctOpenBrace then
      Inc(Depth)
    else if Token.TokenKind = ctCloseBrace then
    begin
      Dec(Depth);
      if (StatementEnd <> nil) and (Depth = 0) then
      begin
        StatementEnd^ := Token.Next;
        Exit;
      end;
      if Depth = -1 then
      begin
        if NextToken <> nil then
          NextToken^ := Token;
        Exit;
      end;
    end
    else
    begin
      FormatScriptError(0, Token.SourceStart, ErrorText);
      Exit;
    end;
    if Token = nil then
      Exit;
    Token := Token.Next;
  end;
end;

procedure TCodeEC.LinkAll(Scope: TVarArrayEC; OnlyUnlinked: Boolean);
var
  Item: TCodeUnitEC;
  i: Integer;
begin
  Item := First;
  while Item <> nil do
  begin
    if Item.Expression <> nil then
      Item.Expression.Link(Scope, OnlyUnlinked);
    Item := Item.Next;
  end;
  for i := 0 to LocalVar.Count - 1 do
  begin
    with LocalVar.GetItem(i) do
    begin
      if (Kind = vkFunction) and (GetFunction <> nil) then
        GetFunction.LinkAll(Scope, OnlyUnlinked)
      else if Kind = vkClass then
      begin
        if GetClass <> nil then
          GetClass.LinkAll(Scope, OnlyUnlinked);
      end;
    end;
  end;
end;

procedure TCodeEC.LinkLocalScopes;
var
  i: Integer;
begin
  for i := 0 to LocalVar.Count - 1 do
  begin
    with LocalVar.GetItem(i) do
    begin
      if Kind = vkFunction then
      begin
        if FunctionValue <> nil then
        begin
          if FunctionValue.IsClassDefinition then
            FunctionValue.LinkLocalScopes;
        end;
      end;
    end;
  end;
  LinkAll(LocalVar, False);
end;

procedure SetScriptStepCallback(Callback: TScriptStepCallback; Interval: Integer);
begin
  ScriptStepCallback := Callback;
  ScriptStepInterval := Interval;
end;

procedure TCodeEC.Run(Process: TCodeProcessEC);
var
  Item: TCodeUnitEC;
  Handler: PCodeExceptionHandler;
  Pending: PVarEC;
  Caught: TVarEC;
  Steps, TotalSteps: Integer;
begin
  ScriptCallTracePosition := 0;
  ScriptCallTraceCount := 0;
  LinkAll(LocalVar, False);
  Caught := nil;
  Item := First;
  Steps := 0;
  TotalSteps := 0;
  while Item <> nil do
  begin
    Inc(Steps);
    if (Steps > ScriptStepInterval) and (ScriptStepInterval > 0) then
    begin
      Inc(TotalSteps, ScriptStepInterval);
      Dec(Steps, ScriptStepInterval);
      if Assigned(ScriptStepCallback) then
        ScriptStepCallback(TotalSteps);
    end;
    if Item.Opcode = coExpression then
    begin
      try
        Item.Expression.Evaluate(Process, Self, nil);
      except
        raise;
      end;
    end
    else if Item.Opcode = coJump then
    begin
      Item := Item.Target;
      Continue;
    end
    else if Item.Opcode = coBranchFalse then
    begin
      try
        Item.Expression.Evaluate(Process, Self, nil);
      except
        raise;
      end;
      if not Item.Expression.GetResult.IsTrue then
      begin
        Item := Item.Target;
        Continue;
      end;
    end
    else if Item.Opcode = coExit then
    begin
      while True do
      begin
        Handler := Process.GetHandler;
        if (Handler = nil) or (Handler.Code <> Self) then
          Break;
        Process.PopHandler;
      end;
      Break;
    end
    else if Item.Opcode = coPushHandler then
      Process.PushHandler(Self, Item.Target)
    else if Item.Opcode = coPopHandler then
      Process.PopHandler
    else if Item.Opcode = coThrow then
    begin
      if Item.Expression <> nil then
      begin
        Item.Expression.Evaluate(Process, Self, nil);
        Process.PushException(Item.Expression.GetResult);
      end
      else if Caught <> nil then
      begin
        Process.PushException(Caught);
        Caught := nil;
      end;
    end;
    Pending := Process.GetException;
    if Pending <> nil then
    begin
      Handler := Process.GetHandler;
      if Handler <> nil then
      begin
        if Handler.Code <> Self then
          Break;
        Item := Handler.Handler;
        Caught := Pending^;
        Pending^ := nil;
        if Item.ExceptionVar <> nil then
          Item.ExceptionVar.Assume(Caught, False);
        Process.PopHandler;
        Process.PopException;
        Continue;
      end
      else
        Process.RaiseUnhandledExceptions;
    end;
    Item := Item.Next;
  end;
  if Caught <> nil then
    Caught.Free;
  ScriptCallTracePosition := 0;
  ScriptCallTraceCount := 0;
end;

procedure TCodeEC.RunDebug(Process: TCodeProcessEC; DebugContext: TScriptDebugState);
var
  Item: TCodeUnitEC;
  Events: array[0..1] of Dword;
  WaitResult: Dword;
  Handler: PCodeExceptionHandler;
  Pending: PVarEC;
  Caught: TVarEC;
begin
  ScriptCallTracePosition := 0;
  ScriptCallTraceCount := 0;
  LinkAll(LocalVar, False);
  Caught := nil;
  Events[0] := DebugContext.StopEvent;
  Events[1] := DebugContext.ResumeEvent;
  Item := First;
  while Item <> nil do
  begin
    WaitResult := WaitForSingleObject(DebugContext.StopEvent, 0);
    if (WaitResult = WAIT_FAILED)
        or (WaitResult = WAIT_OBJECT_0)
        or (WaitResult = WAIT_ABANDONED_0) then
      Break;
    if (DebugContext.Paused and (Item.SourceLength > 0)) or Item.Breakpoint then
    begin
      DebugContext.CurrentUnit := Item;
      ResetEvent(DebugContext.ResumeEvent);
      WaitResult := WaitForMultipleObjects(Length(Events), @Events, False, INFINITE);
      if (WaitResult = WAIT_FAILED)
          or (WaitResult = WAIT_OBJECT_0)
          or ((WaitResult >= WAIT_ABANDONED_0)
              and (WaitResult < WAIT_ABANDONED_0 + Length(Events))) then
        Break;
      DebugContext.CurrentCode := Self;
      if DebugContext.StepMode = 1 then
        DebugContext.Paused := True;
    end;
    if Item.Opcode = coExpression then
    begin
      try
        Item.Expression.Evaluate(Process, Self, DebugContext);
      except
        raise;
      end;
    end
    else if Item.Opcode = coJump then
    begin
      Item := Item.Target;
      Continue;
    end
    else if Item.Opcode = coBranchFalse then
    begin
      try
        Item.Expression.Evaluate(Process, Self, DebugContext);
      except
        raise;
      end;
      if not Item.Expression.GetResult.IsTrue then
      begin
        Item := Item.Target;
        Continue;
      end;
    end
    else if Item.Opcode = coExit then
    begin
      while True do
      begin
        Handler := Process.GetHandler;
        if (Handler = nil) or (Handler.Code <> Self) then
          Break;
        Process.PopHandler;
      end;
      Break;
    end
    else if Item.Opcode = coPushHandler then
      Process.PushHandler(Self, Item.Target)
    else if Item.Opcode = coPopHandler then
      Process.PopHandler
    else if Item.Opcode = coThrow then
    begin
      if Item.Expression <> nil then
      begin
        Item.Expression.Evaluate(Process, Self, nil);
        Process.PushException(Item.Expression.GetResult);
      end
      else if Caught <> nil then
      begin
        Process.PushException(Caught);
        Caught := nil;
      end;
    end;
    Pending := Process.GetException;
    if Pending <> nil then
    begin
      Handler := Process.GetHandler;
      if Handler <> nil then
      begin
        if Handler.Code <> Self then
          Break;
        Item := Handler.Handler;
        Caught := Pending^;
        Pending^ := nil;
        if Item.ExceptionVar <> nil then
          Item.ExceptionVar.Assume(Caught, False);
        Process.PopHandler;
        Process.PopException;
        Continue;
      end
      else
        Break;
    end;
    if (DebugContext.StepMode = 2) and (DebugContext.CurrentCode = Self) then
      DebugContext.Paused := True;
    Item := Item.Next;
  end;
  if ((DebugContext.StepMode = 2) or (DebugContext.StepMode = 3))
      and (DebugContext.CurrentCode = Self) then
    DebugContext.Paused := True;
  if Caught <> nil then
    Caught.Free;
  ScriptCallTracePosition := 0;
  ScriptCallTraceCount := 0;
end;

procedure EF_Min(av: array of TVarEC; code: TCodeEC);
var
  i, Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then
    Exit;
  av[0].Assume(av[1], False);
  for i := 2 to Count - 1 do
  begin
    if (av[0].RealVType = vkString) and (av[i].RealVType in [vkInt, vkDword, vkFloat]) then
      av[0].ConvertToKind(av[i].RealVType)
    else if av[i].RealVType = vkFloat then
    begin
      if av[0].RealVType in [vkInt, vkDword] then
        av[0].ConvertToKind(av[i].RealVType);
    end;
    if av[0].GreaterThan(av[i]) then
      av[0].Assume(av[i], False);
  end;
end;

procedure EF_Max(av: array of TVarEC; code: TCodeEC);
var
  i, Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then
    Exit;
  av[0].Assume(av[1], False);
  for i := 2 to Count - 1 do
  begin
    if (av[0].RealVType = vkString) and (av[i].RealVType in [vkInt, vkDword, vkFloat]) then
      av[0].ConvertToKind(av[i].RealVType)
    else if av[i].RealVType = vkFloat then
    begin
      if av[0].RealVType in [vkInt, vkDword] then
        av[0].ConvertToKind(av[i].RealVType);
    end;
    if av[0].LessThan(av[i]) then
      av[0].Assume(av[i], False);
  end;
end;

procedure EF_NewArray(av: array of TVarEC; code: TCodeEC);
var
  i, Count: Integer;
  Dimensions: array of Integer;
begin
  Count := High(av) + 1;
  av[0].ResetKind(vkArray);
  if Count < 2 then
    Exit;
  Dec(Count);
  SetLength(Dimensions, Count);
  for i := 0 to Count - 1 do
  begin
    if (av[i + 1].RealVType <> vkInt) or (av[i + 1].GetInt < 1) then
    begin
      Dimensions := nil;
      Exit;
    end;
    Dimensions[i] := av[i + 1].GetInt;
  end;
  av[0].CreateArray(Dimensions);
  Dimensions := nil;
end;

procedure EF_ArrayChange(av: array of TVarEC; code: TCodeEC);
var
  Dimension: Integer;
begin
  if High(av) < 2 then
    Exit;
  Dimension := 0;
  if High(av) >= 3 then
    Dimension := av[3].GetInt;
  av[1].ResizeArray(av[2].GetInt, Dimension);
end;

procedure EF_Free(av: array of TVarEC; code: TCodeEC);
var
  Count, i: Integer;
begin
  Count := High(av) + 1 - 1;
  if Count < 1 then
    Exit;
  av[0].Assume(av[1], False);
  for i := 0 to Count - 1 do
    av[i + 1].FreeArray;
end;

procedure EF_Count(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1 - 1;
  if Count < 1 then
    Exit;
  if av[1].RealVType = vkArray then
    av[0].SetInt(av[1].GetArray.Count);
  if av[1].RealVType = vkString then
    av[0].SetInt(Length(av[1].GetString));
end;

procedure EF_Copy(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1 - 1;
  if Count < 2 then
    Exit;
  av[1].ResetKind(av[2].RealVType);
  av[1].Assume(av[2], True);
end;

procedure EF_Abs(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then
    Exit;
  if av[1].RealVType = vkInt then
    av[0].SetInt(Abs(av[1].GetInt))
  else
    av[0].SetFloat(Abs(av[1].GetFloat));
end;

procedure EF_ArcTan(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then
    Exit;
  av[0].SetFloat(ArcTan(av[1].GetFloat));
end;

procedure EF_Exp(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then
    Exit;
  av[0].SetFloat(Exp(av[1].GetFloat));
end;

procedure EF_Ln(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then
    Exit;
  av[0].SetFloat(Ln(av[1].GetFloat));
end;

procedure EF_Round(av: array of TVarEC; code: TCodeEC);
var
  Count, Step: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then
    Exit;
  if Count >= 3 then
    Step := av[2].GetInt
  else
    Step := 1;
  if av[1].RealVType = vkFloat then
    av[0].SetInt(Integer(Round(av[1].GetFloat / Step)) * Step)
  else
    av[0].SetInt(Integer(Round(av[1].GetInt / Step)) * Step);
end;

procedure EF_Sin(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then
    Exit;
  av[0].SetFloat(Sin(av[1].GetFloat));
end;

procedure EF_Cos(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then
    Exit;
  av[0].SetFloat(Cos(av[1].GetFloat));
end;

procedure EF_Sqr(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then
    Exit;
  if av[1].RealVType = vkInt then
    av[0].SetInt(av[1].GetInt * av[1].GetInt)
  else
    av[0].SetFloat(Sqr(av[1].GetFloat));
end;

procedure EF_Sqrt(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then
    Exit;
  av[0].SetFloat(Sqrt(av[1].GetFloat));
end;

procedure EF_Frac(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then
    Exit;
  av[0].SetFloat(Frac(av[1].GetFloat));
end;

procedure EF_Int(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then
    Exit;
  av[0].SetInt(Trunc(av[1].GetFloat));
end;

procedure EF_Ord(av: array of TVarEC; code: TCodeEC);
var
  Text: WideString;
begin
  if High(av) < 1 then
    Exit;
  Text := av[1].GetString;
  if Length(Text) > 0 then
    av[0].SetInt(Ord(Text[1]));
end;

procedure EF_Rnd(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then
    Exit;
  av[0].SetInt(Random(av[1].GetInt));
end;

procedure EF_Randomize(av: array of TVarEC; code: TCodeEC);
begin
  Randomize;
end;

procedure EF_RandSeed(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 1 then
    Exit;
  av[0].SetInt(RandSeed);
  if Count >= 2 then
    RandSeed := av[1].GetInt;
end;

procedure EF_SubStr(av: array of TVarEC; code: TCodeEC);
var
  Count, Start, Size, TextLength: Integer;
begin
  Count := High(av) + 1;
  if Count < 3 then
    Exit;
  TextLength := Length(av[1].GetString);
  Start := av[2].GetInt;
  if Count >= 4 then
    Size := av[3].GetInt
  else
    Size := 1999999999;
  if (Start < 0) or (Start >= TextLength) then
  begin
    av[0].SetString('');
    Exit;
  end;
  if Start + Size > TextLength then
    Size := TextLength - Start;
  av[0].SetString(Copy(av[1].GetString, Start + 1, Size));
end;

procedure EF_FindSubStr(av: array of TVarEC; code: TCodeEC);
var
  Start, TextLength, SearchLength: Integer;
  Text, Search: WideString;
begin
  if High(av) < 2 then
    Exit;
  Text := av[1].GetString;
  Search := av[2].GetString;
  Start := 0;
  if High(av) >= 3 then
    Start := av[3].GetInt;
  TextLength := Length(Text);
  SearchLength := Length(Search);
  if TextLength - Start < SearchLength then
  begin
    av[0].SetInt(-1);
    Exit;
  end;
  if (TextLength < 1) and (SearchLength < 1) then
  begin
    av[0].SetInt(-1);
    Exit;
  end;
  while Start <= TextLength - SearchLength do
  begin
    if CompareMem(
        Pointer(PtrUInt(PWideChar(Text)) + Start * SizeOf(WideChar)),
        PWideChar(Search),
        SearchLength * 2) then
    begin
      av[0].SetInt(Start);
      Exit;
    end;
    Inc(Start);
  end;
  av[0].SetInt(-1);
end;

procedure EF_Trim(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then
    Exit;
  av[0].SetString(TrimScriptString(av[1].GetString));
end;

procedure EF_ToAnsi(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then
    Exit;
  av[0].SetString(av[1].GetString);
  av[0].PackAnsiString;
end;

procedure EF_ToUnicode(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then
    Exit;
  av[0].SetString(av[1].GetString);
  av[0].UnpackAnsiString;
end;

procedure EF_LowerCase(av: array of TVarEC; code: TCodeEC);
var
  Text: WideString;
  AnsiText: AnsiString;
  Start, Count: Integer;
begin
  if High(av) < 1 then
    Exit;
  Text := av[1].GetString;
  Start := 0;
  if High(av) >= 2 then
    Start := av[2].GetInt;
  if High(av) >= 3 then
    Count := av[3].GetInt
  else
    Count := Length(Text) - Start;
  if (Start < 0) or (Start + Count > Length(Text)) or (Count < 1) then
  begin
    av[0].SetString(Text);
    Exit;
  end;
  if GetVersion < $80000000 then
  begin
    CharLowerBuffW(PWideChar(Text) + Start, Count);
    av[0].SetString(Text);
  end
  else
  begin
    AnsiText := Text;
    CharLowerBuffA(PAnsiChar(AnsiText) + Start, Count);
    av[0].SetString(AnsiText);
  end;
end;

procedure EF_UpperCase(av: array of TVarEC; code: TCodeEC);
var
  Text: WideString;
  AnsiText: AnsiString;
  Start, Count: Integer;
begin
  if High(av) < 1 then
    Exit;
  Text := av[1].GetString;
  Start := 0;
  if High(av) >= 2 then
    Start := av[2].GetInt;
  if High(av) >= 3 then
    Count := av[3].GetInt
  else
    Count := Length(Text) - Start;
  if (Start < 0) or (Start + Count > Length(Text)) or (Count < 1) then
  begin
    av[0].SetString(Text);
    Exit;
  end;
  if GetVersion < $80000000 then
  begin
    CharUpperBuffW(PWideChar(Text) + Start, Count);
    av[0].SetString(Text);
  end
  else
  begin
    AnsiText := Text;
    // Native ANSI fallback lowercases even for UpperCase.
    CharLowerBuffA(PAnsiChar(AnsiText) + Start, Count);
    av[0].SetString(AnsiText);
  end;
end;

procedure EF_LoadLibrary(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 1 then
    Exit;
  av[0].SetDword(LoadLibraryW(PWideChar(av[1].GetString)));
end;

procedure EF_FreeLibrary(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 1 then
    Exit;
  av[0].SetInt(Integer(FreeLibrary(av[1].GetDword)));
end;

procedure TVarEC.SetLibrarySignature(Signature: array of Dword);
var
  i, Last: Integer;
begin
  Last := High(Signature);
  SetLength(LibraryFunData, Last + 1);
  for i := 0 to Last do
    LibraryFunData[i] := Signature[i];
end;

procedure EF_LibraryFunction(av: array of TVarEC; code: TCodeEC);
var
  i: Integer;
  Proc: Pointer;
  KindName: WideString;
begin
  if High(av) < 3 then
    Exit;
  Proc := GetProcAddress(av[1].GetDword, PAnsiChar(AnsiString(av[3].GetString)));
  if Proc = nil then
  begin
    av[0].SetInt(0);
    Exit;
  end;
  av[0].ConvertToKind(vkLibraryFun);
  SetLength(av[0].LibraryFunData, 2 + High(av) - 3);
  if av[2].GetString = 'int' then
    av[0].LibraryFunData[0] := 1
  else if av[2].GetString = 'dword' then
    av[0].LibraryFunData[0] := 2
  else if av[2].GetString = 'float' then
    av[0].LibraryFunData[0] := 3
  else if av[2].GetString = 'str' then
    av[0].LibraryFunData[0] := 4
  else
    av[0].LibraryFunData[0] := 0;
  av[0].LibraryFunData[1] := Dword(Proc);
  for i := 0 to High(av) - 3 - 1 do
  begin
    KindName := av[4 + i].GetString;
    if KindName = 'int' then
      av[0].LibraryFunData[2 + i] := 1
    else if KindName = 'dword' then
      av[0].LibraryFunData[2 + i] := 2
    else if KindName = 'float' then
      av[0].LibraryFunData[2 + i] := 3
    else if KindName = 'str' then
      av[0].LibraryFunData[2 + i] := 4
    else if KindName = 'ref' then
      av[0].LibraryFunData[2 + i] := 5
    else if KindName = 'code' then
      av[0].LibraryFunData[2 + i] := 6
    else
      raise ExceptionExpressionEC.Create('LibraryFunction. Unknown type');
  end;
end;

procedure EF_New(av: array of TVarEC; code: TCodeEC);
var
  Found: TVarEC;
  Definition, Instance: TCodeEC;
begin
  if High(av) <> 1 then
    Exit;
  if code = nil then
    Exit;
  while (code <> nil) and (code.Parent <> nil) do
    code := code.Parent;
  Found := code.LocalVar.GetVar(av[1].GetString);
  if Found.RealVType = vkFunction then
  begin
    Definition := Found.GetFunction;
    if Definition.IsClassDefinition then
    begin
      Instance := TCodeEC.Create;
      Instance.CopyFromFast(Definition);
      Instance.LinkLocalScopes;
      av[0].SetClass(Instance);
    end;
  end;
end;

procedure EF_Delete(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 1 then
    Exit;
  if av[1].RealVType = vkClass then
  begin
    av[1].GetClass.Free;
    av[1].ResetKind(vkEmpty);
  end;
end;

procedure RegisterExpressionBuiltins(Scope: TVarArrayEC);
begin
  Scope.Add('pi', vkFloat).SetFloat(Pi);
  Scope.Add('min', vkExternFun).SetExternFun(@EF_Min);
  Scope.Add('max', vkExternFun).SetExternFun(@EF_Max);
  Scope.Add('newarray', vkExternFun).SetExternFun(@EF_NewArray);
  Scope.Add('arraychange', vkExternFun).SetExternFun(@EF_ArrayChange);
  Scope.Add('free', vkExternFun).SetExternFun(@EF_Free);
  Scope.Add('count', vkExternFun).SetExternFun(@EF_Count);
  Scope.Add('copy', vkExternFun).SetExternFun(@EF_Copy);
  Scope.Add('abs', vkExternFun).SetExternFun(@EF_Abs);
  Scope.Add('arctan', vkExternFun).SetExternFun(@EF_ArcTan);
  Scope.Add('exp', vkExternFun).SetExternFun(@EF_Exp);
  Scope.Add('ln', vkExternFun).SetExternFun(@EF_Ln);
  Scope.Add('round', vkExternFun).SetExternFun(@EF_Round);
  Scope.Add('sin', vkExternFun).SetExternFun(@EF_Sin);
  Scope.Add('cos', vkExternFun).SetExternFun(@EF_Cos);
  Scope.Add('sqr', vkExternFun).SetExternFun(@EF_Sqr);
  Scope.Add('sqrt', vkExternFun).SetExternFun(@EF_Sqrt);
  Scope.Add('frac', vkExternFun).SetExternFun(@EF_Frac);
  Scope.Add('int', vkExternFun).SetExternFun(@EF_Int);
  Scope.Add('ord', vkExternFun).SetExternFun(@EF_Ord);
  Scope.Add('rnd', vkExternFun).SetExternFun(@EF_Rnd);
  Scope.Add('randomize', vkExternFun).SetExternFun(@EF_Randomize);
  Scope.Add('randseed', vkExternFun).SetExternFun(@EF_RandSeed);
  Scope.Add('substr', vkExternFun).SetExternFun(@EF_SubStr);
  Scope.Add('findsubstr', vkExternFun).SetExternFun(@EF_FindSubStr);
  Scope.Add('trim', vkExternFun).SetExternFun(@EF_Trim);
  Scope.Add('toansi', vkExternFun).SetExternFun(@EF_ToAnsi);
  Scope.Add('tounicode', vkExternFun).SetExternFun(@EF_ToUnicode);
  Scope.Add('lowercase', vkExternFun).SetExternFun(@EF_LowerCase);
  Scope.Add('uppercase', vkExternFun).SetExternFun(@EF_UpperCase);
  Scope.Add('loadlibrary', vkExternFun).SetExternFun(@EF_LoadLibrary);
  Scope.Add('freelibrary', vkExternFun).SetExternFun(@EF_FreeLibrary);
  Scope.Add('libraryfunction', vkExternFun).SetExternFun(@EF_LibraryFunction);
  Scope.Add('new', vkExternFun).SetExternFun(@EF_New);
  Scope.Add('delete', vkExternFun).SetExternFun(@EF_Delete);
end;

end.
