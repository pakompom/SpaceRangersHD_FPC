{$EXCESSPRECISION OFF}
unit GI_CheckBox;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_BlockPar,
  GI_MessageLoop,
  GI_TransImage,
  Types;
type
  TCheckBoxGI = class;
  TCheckBoxGI = class(TObjectGI)
    CheckedImage: TTransImageGI;
    UncheckedImage: TTransImageGI;
    Checked: Boolean;
    Gap129: array[0..6] of Byte;
    ChangedCallback: TObjectNotifyEventGI;
    procedure Clear; override;
    procedure SetSize(Size: TPoint); override;
    procedure SetConfigPath(const Path: WideString); override;
    procedure LoadFromConfigPath(const Path: WideString); override;
    procedure ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint); override;
    procedure LoadFromBlock(Block: TBlockParEC); override;
    constructor Create(Owner: TObjectGI);
    destructor Destroy; override;
    procedure RefreshStateImages;
  end;
implementation
uses
  Math,
  GR_Main,
  Classes,
  EC_Str,
  GI_Main;

constructor TCheckBoxGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  CheckedImage := TTransImageGI.Create(Self);
  CheckedImage.SetImageKindX(ikxCenter);
  CheckedImage.SetImageKindY(ikyCenter);
  CheckedImage.SetActive(False);
  UncheckedImage := TTransImageGI.Create(Self);
  UncheckedImage.SetImageKindX(ikxCenter);
  UncheckedImage.SetImageKindY(ikyCenter);
  UncheckedImage.SetActive(True);
  Checked := False;
end;

destructor TCheckBoxGI.Destroy;
begin
  CheckedImage.Free;
  UncheckedImage.Free;
  inherited Destroy;
end;

procedure TCheckBoxGI.Clear;
begin
  Checked := False;
end;

procedure TCheckBoxGI.SetConfigPath(const Path: WideString);
begin
  inherited SetConfigPath(Path);
  RefreshStateImages;
  Invalidate;
end;

procedure TCheckBoxGI.SetSize(Size: TPoint);
begin
  inherited SetSize(Size);
  CheckedImage.SetPosition(
      Classes.Point(
          Size.X div 2 - CheckedImage.ClientSize.X div 2,
          Size.Y div 2 - CheckedImage.ClientSize.Y div 2
      )
  );
  UncheckedImage.SetPosition(
      Classes.Point(
          Size.X div 2 - UncheckedImage.ClientSize.X div 2,
          Size.Y div 2 - UncheckedImage.ClientSize.Y div 2
      )
  );
end;

procedure TCheckBoxGI.RefreshStateImages;
begin
  CheckedImage.SetImagePath(ConfigPath + '.IChecked');
  CheckedImage.SetSize(CheckedImage.GetContentSize);
  UncheckedImage.SetImagePath(ConfigPath + '.IUnchecked');
  UncheckedImage.SetSize(UncheckedImage.GetContentSize);
  CheckedImage.SetPosition(
      Classes.Point(
          ClientSize.X div 2 - CheckedImage.ClientSize.X div 2,
          ClientSize.Y div 2 - CheckedImage.ClientSize.Y div 2
      )
  );
  UncheckedImage.SetPosition(
      Classes.Point(
          ClientSize.X div 2 - UncheckedImage.ClientSize.X div 2,
          ClientSize.Y div 2 - UncheckedImage.ClientSize.Y div 2
      )
  );
end;

procedure TCheckBoxGI.ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonDown(KeyState, Point);
  if Checked = True then
  begin
    Checked := False;
    CheckedImage.SetActive(False);
    UncheckedImage.SetActive(True);
  end
  else
  begin
    Checked := True;
    CheckedImage.SetActive(True);
    UncheckedImage.SetActive(False);
  end;
  if Assigned(ChangedCallback) then
    ChangedCallback(Self);
end;

procedure TCheckBoxGI.LoadFromConfigPath(const Path: WideString);
var
  Block: TBlockParEC;
begin
  inherited LoadFromConfigPath(Path);
  Block := UiStyleConfig.GetBlockByPath(Path);
  if Block.CountParams('Checked') > 0 then
    if TrimWideString(Block.GetParam('Checked')) = 'True' then
      Checked := True
    else
      Checked := False;
end;

procedure TCheckBoxGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  if Block.CountParams('Checked') > 0 then
    if TrimWideString(Block.GetParam('Checked')) = 'True' then
      Checked := True
    else
      Checked := False;
  RefreshStateImages;
end;

end.
