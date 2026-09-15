{$EXCESSPRECISION OFF}
unit GI_PSWeapon14Vertix;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
type
  TGAISet = array[0..0] of WideString;
var
  Weapon14AnimationPaths: array of TGAISet;
procedure LoadWeapon14AnimationPaths;
implementation
uses
  GR_Main,
  SysUtils,
  Math,
  EC_BlockPar,
  EC_Str,
  Globals;
// @unit-initialization $87794C
// @unit-finalization $695E74

procedure LoadWeapon14AnimationPaths;
var
  Block, PaletteBlock: TBlockParEC;
  Index, BlockCount, Count: Integer;
  Text: WideString;
begin
  Block := GameDataConfig.GetBlockByPath('SE.Weapon.13.Palettes');
  BlockCount := Block.GetBlockCount;
  Count := 0;
  for Index := 0 to BlockCount - 1 do
    Count := Math.Max(Count, ExtractDigitsToIntW(Block.GetBlockNameByIndex(Index)) + 1);
  SetLength(Weapon14AnimationPaths, Count);
  for Index := 0 to Count - 1 do
  begin
    Text := IntToStr(Index);
    if Block.CountBlocks(Text) <> 0 then
    begin
      PaletteBlock := Block.GetBlockByPath(Text);
      if PaletteBlock.CountParams('GAI') > 0 then
        Weapon14AnimationPaths[Index][0] := PaletteBlock.GetParam('GAI');
    end;
  end;
end;

end.
