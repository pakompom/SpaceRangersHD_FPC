{$EXCESSPRECISION OFF}
unit TextQuestInterface;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Struct;
type
  TTextQuestInterface = class;
  {$Z4}
  TQuestOutcome = (qoNone = 0, qoFailure = 1, qoSuccess = 2, qoDeath = 3);
  TTextQuestInterface = class(TObjectEx)
    procedure ShowText(Text: WideString); virtual;
    procedure ShowPicture(Name: WideString); virtual;
    procedure PlayMusic(Name: WideString); virtual;
    procedure PlaySound(Name: WideString); virtual;
    procedure ShowParameters(Text: WideString); virtual;
    procedure AddContinueAction; virtual;
    procedure AddSuccessAction; virtual;
    procedure AddDeathAction; virtual;
    procedure AddFailureAction; virtual;
    procedure AddPathAction(Text: WideString; PathId: Integer); virtual;
    procedure AddDisabledPath(Text: WideString); virtual;
    procedure AddPathContinueAction(PathId: Integer); virtual;
    procedure AddLocationContinueAction(LocationId: Integer); virtual;
    procedure AdvanceDays(Days: Integer); virtual;
    constructor Create;
    destructor Destroy; override;
  end;
implementation
uses
  Math;

constructor TTextQuestInterface.Create;
begin
end;

destructor TTextQuestInterface.Destroy;
begin
end;

procedure TTextQuestInterface.ShowText(Text: WideString);
begin
end;

procedure TTextQuestInterface.ShowPicture(Name: WideString);
begin
end;

procedure TTextQuestInterface.PlayMusic(Name: WideString);
begin
end;

procedure TTextQuestInterface.PlaySound(Name: WideString);
begin
end;

procedure TTextQuestInterface.ShowParameters(Text: WideString);
begin
end;

procedure TTextQuestInterface.AddContinueAction;
begin
end;

procedure TTextQuestInterface.AddSuccessAction;
begin
end;

procedure TTextQuestInterface.AddDeathAction;
begin
end;

procedure TTextQuestInterface.AddFailureAction;
begin
end;

procedure TTextQuestInterface.AddPathAction(Text: WideString; PathId: Integer);
begin
end;

procedure TTextQuestInterface.AddDisabledPath(Text: WideString);
begin
end;

procedure TTextQuestInterface.AddPathContinueAction(PathId: Integer);
begin
end;

procedure TTextQuestInterface.AddLocationContinueAction(LocationId: Integer);
begin
end;

procedure TTextQuestInterface.AdvanceDays(Days: Integer);
begin
end;

end.
