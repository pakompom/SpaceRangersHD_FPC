{$EXCESSPRECISION OFF}
unit EventClass;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Struct,
  TextFieldClass;
type
  TEvent = class;
  TEvent = class(TObjectEx)
    Text: TTextField;
    Picture: TTextField;
    Music: TTextField;
    Sound: TTextField;
    constructor Create;
    destructor Destroy; override;
    procedure ClearTextFields;
    procedure Assign(Source: TEvent);
  end;
implementation
uses
  Math,
  EC_Str;

constructor TEvent.Create;
begin
  inherited Create;
  Text := TTextField.Create;
  Text.ClearText;
  Picture := TTextField.Create;
  Picture.ClearText;
  Music := TTextField.Create;
  Music.ClearText;
  Sound := TTextField.Create;
  Sound.ClearText;
end;

destructor TEvent.Destroy;
begin
  Text.Free;
  Text := nil;
  Picture.Free;
  Picture := nil;
  Music.Free;
  Music := nil;
  Sound.Free;
  Sound := nil;
  inherited Destroy;
end;

procedure TEvent.ClearTextFields;
begin
  Text.Text := '';
  Picture.Text := '';
  Music.Text := '';
  Sound.Text := '';
end;

procedure TEvent.Assign(Source: TEvent);
begin
  Text.Text := TrimWideString(Source.Text.Text);
  Picture.Text := TrimWideString(Source.Picture.Text);
  Music.Text := TrimWideString(Source.Music.Text);
  Sound.Text := TrimWideString(Source.Sound.Text);
end;

end.
