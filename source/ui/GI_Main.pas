{$EXCESSPRECISION OFF}
unit GI_Main;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  GI_MessageLoop,
  SysUtils,
  Types,
  EC_Struct;
const
  agfPosition = $01;
  agfSize = $02;
type
  {$Z1}
  TImageKindXGI = (
      ikxLeftFill = 0,
      ikxCenterFill = 1,
      ikxRightFill = 2,
      ikxLeft = 3,
      ikxCenter = 4,
      ikxRight = 5
  );
  {$Z1}
  TImageKindYGI = (
      ikyTopFill = 0,
      ikyCenterFill = 1,
      ikyBottomFill = 2,
      ikyTop = 3,
      ikyCenter = 4,
      ikyBottom = 5
  );
  {$Z1}
  TTextAlignXGI = (taxLeft = 0, taxCenter = 1, taxRight = 2, taxAuto = 3);
  {$Z1}
  TTextAlignYGI = (tayTop = 0, tayCenter = 1, tayCenterEx = 2, tayBottom = 3, tayAuto = 4);
function CreateControlByName(Name: WideString; Owner: TObjectGI): TObjectGI;
function ParseImageKindXName(Name: WideString): TImageKindXGI;
function ParseImageKindYName(Name: WideString): TImageKindYGI;
function ParseTextAlignXName(Name: WideString): TTextAlignXGI;
function ParseTextAlignYName(Name: WideString): TTextAlignYGI;
function ParseEnabledNameGI(Name: WideString): Boolean;
function GetColorGI(ColorText: WideString): Cardinal;
function GetPointGI(PointText: WideString): TPoint;
function GetFloatPointGI(PointText: WideString): TPointF;
function GetRectGI(RectText: WideString): TRect;
function ParseAutoGeometryFlagsGI(Values: WideString): Integer;
procedure BreakUiMessage;
implementation
uses
  Math,
  BreakMessageGIException,
  GR_GraphBuf,
  GI_XviD,
  GI_PolyLine,
  GI_SpaceImg,
  GI_SpaceCircle,
  GI_StarFieldImg,
  EC_CachePalBitmap,
  EC_CacheRotateBuf,
  EC_CachePlanetTempl,
  EC_CacheLightPal,
  EC_CacheTBitmap,
  EC_CacheBitmap,
  GI_StarFieldM,
  GI_StarField,
  GI_GraphBuf,
  GI_ShrLight,
  GI_Frame,
  GI_Circle,
  GI_Line,
  GI_Grid,
  GI_RadioGroup,
  GI_CheckBox,
  GI_Planet,
  GI_PlanetButton,
  GI_StatusBar,
  GI_CountBar,
  GI_ScrollBar,
  GI_Edit,
  GI_Label,
  GI_Zone,
  GI_GraphButton,
  GI_TextButton,
  GI_SimpleButton,
  GI_Door,
  GI_MultiImage,
  GI_GAIFile,
  GI_GAI,
  GI_GI,
  GI_AImage,
  GI_InfiniteImage,
  GI_Image,
  GI_RotateImageGAI,
  GI_RotateImage5,
  GI_RotateImage2,
  GI_RotateImage,
  GI_SBPath,
  GI_AlphaImage,
  GI_TransImage,
  GI_SimpleImage,
  GI_Window,
  GI_PanelScrollBar,
  GI_Panel,
  GR_Main,
  EC_Str,
  Classes;

function CreateControlByName(Name: WideString; Owner: TObjectGI): TObjectGI;
begin
  if Name = 'Panel' then
    Result := TPanelGI.Create(Owner)
  else if Name = 'PanelScrollBar' then
    Result := TPanelScrollBarGI.Create(Owner)
  else if Name = 'Window' then
    Result := TWindowGI.Create(Owner)
  else if Name = 'SimpleImage' then
    Result := TSimpleImageGI.Create(Owner)
  else if Name = 'TransImage' then
    Result := TTransImageGI.Create(Owner)
  else if Name = 'AlphaImage' then
    Result := TAlphaImageGI.Create(Owner)
  else if Name = 'RotateImage' then
    Result := TRotateImageGI.Create(Owner)
  else if Name = 'RotateImage2' then
    Result := TRotateImage2GI.Create(Owner)
  else if Name = 'RotateImage5' then
    Result := TRotateImage5GI.Create(Owner)
  else if Name = 'RotateImageGAI' then
    Result := TRotateImageGaiGI.Create(Owner)
  else if Name = 'Image' then
    Result := TImageGI.Create(Owner)
  else if Name = 'InfiniteImage' then
    Result := TInfiniteImageGI.Create(Owner)
  else if Name = 'AImage' then
    Result := TAImageGI.Create(Owner)
  else if Name = 'GI' then
    Result := TgiGI.Create(Owner)
  else if Name = 'GAI' then
    Result := TgaiGI.Create(Owner)
  else if Name = 'GAIFile' then
    Result := TGAIFileGI.Create(Owner)
  else if Name = 'MultiImage' then
    Result := TMultiImageGI.Create(Owner)
  else if Name = 'Door' then
    Result := TDoorGI.Create(Owner)
  else if Name = 'SimpleButton' then
    Result := TSimpleButtonGI.Create(Owner)
  else if Name = 'TextButton' then
    Result := TTextButtonGI.Create(Owner)
  else if Name = 'GraphButton' then
    Result := TGraphButtonGI.Create(Owner)
  else if Name = 'Zone' then
    Result := TZoneGI.Create(Owner)
  else if Name = 'Label' then
    Result := TLabelGI.Create(Owner)
  else if Name = 'Edit' then
    Result := TEditGI.Create(Owner)
  else if Name = 'ScrollBar' then
    Result := TScrollBarGI.Create(Owner)
  else if Name = 'CountBar' then
    Result := TCountBarGI.Create(Owner)
  else if Name = 'SBPath' then
    Result := TSBPathGI.Create(Owner)
  else if Name = 'StatusBar' then
    Result := TStatusBarGI.Create(Owner)
  else if Name = 'Planet' then
    Result := TPlanetGI.Create(Owner)
  else if Name = 'PlanetButton' then
    Result := TPlanetButtonGI.Create(Owner)
  else if Name = 'CheckBox' then
    Result := TCheckBoxGI.Create(Owner)
  else if Name = 'RadioGroup' then
    Result := TRadioGroupGI.Create(Owner)
  else if Name = 'Grid' then
    Result := TGridGI.Create(Owner)
  else if Name = 'Line' then
    Result := TLineGI.Create(Owner)
  else if Name = 'Circle' then
    Result := TCircleGI.Create(Owner)
  else if Name = 'Frame' then
    Result := TFrameGI.Create(Owner)
  else if Name = 'ShrLight' then
    Result := TShrLightGI.Create(Owner)
  else if Name = 'GraphBuf' then
    Result := TGraphBufGI.Create(Owner, False)
  else if Name = 'StarField' then
    Result := TStarFieldGI.Create(Owner)
  else if Name = 'StarFieldM' then
    Result := TStarFieldMGI.Create(Owner)
  else if Name = 'StarFieldImg' then
    Result := TStarFieldImgGI.Create(Owner)
  else if Name = 'SpaceCircle' then
    Result := TSpaceCircleGI.Create(Owner)
  else if Name = 'SpaceImg' then
    Result := TSpaceImgGI.Create(Owner)
  else if Name = 'PolyLine' then
    Result := TPolyLineGI.Create(Owner)
  else if Name = 'XviD' then
    Result := TxvidGI.Create(Owner)
  else
    Result := nil;
end;

function ParseImageKindXName(Name: WideString): TImageKindXGI;
begin
  if Name = 'LeftFill' then
    Result := ikxLeftFill
  else if Name = 'CenterFill' then
    Result := ikxCenterFill
  else if Name = 'RightFill' then
    Result := ikxRightFill
  else if Name = 'Left' then
    Result := ikxLeft
  else if Name = 'Center' then
    Result := ikxCenter
  else if Name = 'Right' then
    Result := ikxRight
  else
    raise Exception.Create('GetITDXbyNameGI. name=' + Name);
end;

function ParseImageKindYName(Name: WideString): TImageKindYGI;
begin
  if Name = 'TopFill' then
    Result := ikyTopFill
  else if Name = 'CenterFill' then
    Result := ikyCenterFill
  else if Name = 'BottomFill' then
    Result := ikyBottomFill
  else if Name = 'Top' then
    Result := ikyTop
  else if Name = 'Center' then
    Result := ikyCenter
  else if Name = 'Bottom' then
    Result := ikyBottom
  else
    raise Exception.Create('GetITDYbyNameGI. name=' + Name);
end;

function ParseTextAlignXName(Name: WideString): TTextAlignXGI;
begin
  if Name = 'Left' then
    Result := taxLeft
  else if Name = 'Center' then
    Result := taxCenter
  else if Name = 'Right' then
    Result := taxRight
  else if Name = 'Auto' then
    Result := taxAuto
  else
    raise Exception.Create('GetTTAXbyNameGI. name=' + Name);
end;

function ParseTextAlignYName(Name: WideString): TTextAlignYGI;
begin
  if Name = 'Top' then
    Result := tayTop
  else if Name = 'Center' then
    Result := tayCenter
  else if Name = 'CenterEx' then
    Result := tayCenterEx
  else if Name = 'Bottom' then
    Result := tayBottom
  else if Name = 'Auto' then
    Result := tayAuto
  else
    raise Exception.Create('GetTTAYbyNameGI. name=' + Name);
end;

function ParseEnabledNameGI(Name: WideString): Boolean;
begin
  if (Name = 'Yes')
      or (Name = 'yes')
      or (Name = 'True')
      or (Name = 'true')
      or (Name = 'TRUE')
      or (Name = '1') then
    Result := True
  else
    Result := False;
end;

function GetColorGI(ColorText: WideString): Cardinal;
begin
  if CountDelimitedPartsW(ColorText, ',') < 3 then
    raise Exception.Create('GetColorGI. color=' + ColorText);
  Result :=
      CurrentPixelFormat.PackRgbBytes(
          StrToInt(ExtractDelimitedPartW(ColorText, 0, ',')),
          StrToInt(ExtractDelimitedPartW(ColorText, 1, ',')),
          StrToInt(ExtractDelimitedPartW(ColorText, 2, ','))
      );
end;

function GetPointGI(PointText: WideString): TPoint;
begin
  if CountDelimitedPartsW(PointText, ',') < 2 then
    raise Exception.Create('GetPointGI. tstr=' + PointText);
  Result :=
      Classes.Point(
          StrToInt(ExtractDelimitedPartW(PointText, 0, ',')),
          StrToInt(ExtractDelimitedPartW(PointText, 1, ','))
      );
end;

function GetFloatPointGI(PointText: WideString): TPointF;
begin
  if CountDelimitedPartsW(PointText, ',') < 2 then
    raise Exception.Create('GetFloatPointGI. tstr=' + PointText);
  Result :=
      MakePointF(
          ExtractDecimalToSingleW(ExtractDelimitedPartW(PointText, 0, ',')),
          ExtractDecimalToSingleW(ExtractDelimitedPartW(PointText, 1, ','))
      );
end;

function GetRectGI(RectText: WideString): TRect;
begin
  if CountDelimitedPartsW(RectText, ',') < 4 then
    raise Exception.Create('GetRectGI. tstr=' + RectText);
  Result.Left := StrToInt(ExtractDelimitedPartW(RectText, 0, ','));
  Result.Top := StrToInt(ExtractDelimitedPartW(RectText, 1, ','));
  Result.Right := StrToInt(ExtractDelimitedPartW(RectText, 2, ','));
  Result.Bottom := StrToInt(ExtractDelimitedPartW(RectText, 3, ','));
end;

function ParseAutoGeometryFlagsGI(Values: WideString): Integer;
var
  Index, Count, Flags: Integer;
  Part: WideString;
begin
  Flags := 0;
  Count := CountDelimitedPartsW(Values, ',');
  for Index := 0 to Count - 1 do
  begin
    Part := LowerCaseWideString(TrimWideString(ExtractDelimitedPartW(Values, Index, ',')));
    if Part = 'pos' then
      Flags := Flags or agfPosition
    else if Part = 'size' then
      Flags := Flags or agfSize;
  end;
  Result := Flags;
end;

procedure BreakUiMessage;
begin
  SuppressExceptionLogCopy := True;
  raise EBreakMessageGI.Create('No error');
end;

end.
