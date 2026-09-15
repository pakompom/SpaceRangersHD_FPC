{$EXCESSPRECISION OFF}
unit TextFieldClass;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Buf,
  EC_Struct;
type
  TTextField = class;
  TTextField = class(TObjectEx)
    Text: WideString;
    procedure ClearText;
    procedure LoadTextLinesFromReader(Reader: TBufEC);
  end;
implementation
uses
  Math,
  EC_Str;

procedure TTextField.ClearText;
begin
  Text := '';
end;

procedure TTextField.LoadTextLinesFromReader(Reader: TBufEC);
var
  Line: WideString;
  i, j, LineCount, CharCount: Integer;
begin
  ClearText;
  LineCount := Reader.GetInt32;
  for j := 1 to LineCount do
  begin
    CharCount := Reader.GetInt32;
    SetLength(Line, CharCount);
    for i := 1 to CharCount do
      Line[i] := Reader.GetWideChar;
    if Text <> '' then
      Text := Text + #13#10 + TrimWideString(Line)
    else
      Text := TrimWideString(Line);
  end;
  Text := TrimWideString(Text);
end;

end.
