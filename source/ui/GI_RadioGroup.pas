{$EXCESSPRECISION OFF}
unit GI_RadioGroup;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_BlockPar,
  GI_MessageLoop,
  Types;
type
  TRadioGroupGI = class;
  TRadioGroupGI = class(TObjectGI)
    SelectionChangedCallback: TObjectNotifyEventGI;
    procedure Clear; override;
    procedure SetSize(Size: TPoint); override;
    procedure SetConfigPath(const Path: WideString); override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure AddItem(Name: WideString; Position: TPoint);
    procedure RefreshItemImages;
    procedure ClearSelection;
    procedure SelectItem(Name: WideString);
    procedure ItemClick(Sender: TObjectGI; MouseState: Cardinal; Point: TPoint);
  end;
procedure LinkRecoveredTypes;
implementation
uses
  Math,
  Classes,
  SysUtils,
  EC_Str,
  GI_TransImage;

constructor TRadioGroupGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
end;

destructor TRadioGroupGI.Destroy;
begin
  inherited Destroy;
end;

procedure TRadioGroupGI.Clear;
begin
end;

procedure TRadioGroupGI.SetConfigPath(const Path: WideString);
begin
  inherited SetConfigPath(Path);
  RefreshItemImages;
  Invalidate;
end;

procedure TRadioGroupGI.SetSize(Size: TPoint);
begin
  inherited SetSize(Size);
end;

procedure TRadioGroupGI.AddItem(Name: WideString; Position: TPoint);
var
  Image: TTransImageGI;
begin
  Image := TTransImageGI.Create(Self);
  Image.SetPosition(Position);
  Image.SetName(Name);
  Image.UserValue := 0;
  Image.SetActive(True);
  Image.LeftButtonDownCallback := ItemClick;
  Image := TTransImageGI.Create(Self);
  Image.SetPosition(Position);
  Image.SetName(Name);
  Image.UserValue := 1;
  Image.SetActive(False);
  Image.LeftButtonDownCallback := ItemClick;
  RefreshItemImages;
end;

procedure TRadioGroupGI.RefreshItemImages;
var
  Item: TObjectGI;
begin
  Item := FirstChild;
  while Item <> nil do
  begin
    if Item.UserValue = 0 then
      (Item as TTransImageGI).SetImagePath(ConfigPath + '.IUnchecked')
    else
      (Item as TTransImageGI).SetImagePath(ConfigPath + '.IChecked');
    Item := Item.NextSibling;
  end;
end;

procedure TRadioGroupGI.ClearSelection;
var
  Item: TObjectGI;
begin
  Item := FirstChild;
  while Item <> nil do
  begin
    if Item.UserValue = 0 then
      Item.SetActive(True)
    else
      Item.SetActive(False);
    Item := Item.NextSibling;
  end;
end;

procedure TRadioGroupGI.SelectItem(Name: WideString);
var
  Item: TObjectGI;
begin
  ClearSelection;
  Item := FirstChild;
  while Item <> nil do
  begin
    if Item.ControlName = Name then
    begin
      if Item.UserValue = 0 then
        Item.SetActive(False)
      else
        Item.SetActive(True);
    end
    else
    begin
      if Item.UserValue = 0 then
        Item.SetActive(True)
      else
        Item.SetActive(False);
    end;
    Item := Item.NextSibling;
  end;
end;

procedure TRadioGroupGI.ItemClick(Sender: TObjectGI; MouseState: Cardinal; Point: TPoint);
begin
  SelectItem(Sender.ControlName);
  if Assigned(SelectionChangedCallback) then
    SelectionChangedCallback(Self);
end;

procedure TRadioGroupGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
end;

procedure TRadioGroupGI.LoadFromBlock(Block: TBlockParEC);
var
  Items: TBlockParEC;
  Index, Count: Integer;
  Text: WideString;
begin
  inherited LoadFromBlock(Block);
  if Block.CountBlocks('RadioButton') > 0 then
  begin
    Items := Block.GetBlock('RadioButton');
    Count := Items.GetParamCount;
    for Index := 0 to Count - 1 do
    begin
      Text := Items.GetParamValue(Index);
      AddItem(
          Items.GetParamName(Index),
          Classes.Point(
              StrToInt(AnsiString(ExtractDelimitedPartW(Text, 0, ','))),
              StrToInt(AnsiString(ExtractDelimitedPartW(Text, 1, ',')))
          )
      );
    end;
  end;
  if Block.CountParams('Checked') > 0 then
    SelectItem(TrimWideString(Block.GetParam('Checked')));
end;

procedure LinkRecoveredTypes;
begin
  TTransImageGI.ClassName;
end;
end.
