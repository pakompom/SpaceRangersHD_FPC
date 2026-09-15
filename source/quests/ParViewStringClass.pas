{$EXCESSPRECISION OFF}
unit ParViewStringClass;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Buf,
  EC_Struct,
  TextFieldClass;
type
  TParViewString = class;
  TParViewString = class(TObjectEx)
    MinValue: Integer;
    MaxValue: Integer;
    Text: TTextField;
    constructor Create(Value: WideString);
    destructor Destroy; override;
    procedure LoadFromReader(Reader: TBufEC);
  end;
implementation
uses
  Math;

constructor TParViewString.Create(Value: WideString);
begin
  inherited Create;
  Text := TTextField.Create;
  Text.Text := Value;
end;

destructor TParViewString.Destroy;
begin
  Text.Free;
  Text := nil;
  inherited Destroy;
end;

procedure TParViewString.LoadFromReader(Reader: TBufEC);
begin
  MinValue := Reader.GetInt32;
  MaxValue := Reader.GetInt32;
  Text.LoadTextLinesFromReader(Reader);
end;

end.
