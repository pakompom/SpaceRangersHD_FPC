{$EXCESSPRECISION OFF}
unit aPacket;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
function InitializePackageCollection: Boolean;
function LoadConfiguredPackages: Boolean;
procedure FinalizePackageCollection;
implementation
uses
  Math,
  Classes,
  SyncObjs,
  EC_HsFile,
  EC_BlockPar,
  GR_Main;

function InitializePackageCollection: Boolean;
var
  Pack: TPackFileEC;
begin
  PackageFileLock := TCriticalSection.Create;
  Result := True;
  PackageCollection := nil;
  PackageCollection := TPackCollectionEC.Create;
  Pack := TPackFileEC.Create;
  Pack.UseLooseFiles := True;
  Pack.SetPackagePath('');
  PackageCollection.AddPackToFront(Pack);
  PackageCollection.OpenAllPackages;
end;

function LoadConfiguredPackages: Boolean;
var
  Pack: TPackFileEC;
  Block: TBlockParEC;
  ParamIndex, ModIndex: Integer;
begin
  PackageCollection.CloseAllPackages;
  for ModIndex := 0 to ModLanguageInstallConfigs.Count - 1 do
  begin
    Block := ModLanguageInstallConfigs[ModIndex];
    Block := Block.GetBlock('Packages');
    for ParamIndex := 0 to Block.GetParamCount - 1 do
    begin
      Pack := TPackFileEC.Create;
      Pack.SetPackagePath(AnsiString(Block.GetParamValue(ParamIndex)));
      PackageCollection.AddPackToBack(Pack);
    end;
  end;
  Block := LanguageInstallConfig.GetBlock('Packages');
  for ParamIndex := 0 to Block.GetParamCount - 1 do
  begin
    Pack := TPackFileEC.Create;
    Pack.SetPackagePath(AnsiString(Block.GetParamValue(ParamIndex)));
    PackageCollection.AddPackToBack(Pack);
  end;
  for ModIndex := 0 to ModInstallConfigs.Count - 1 do
  begin
    Block := ModInstallConfigs[ModIndex];
    Block := Block.GetBlock('Packages');
    for ParamIndex := 0 to Block.GetParamCount - 1 do
    begin
      Pack := TPackFileEC.Create;
      Pack.SetPackagePath(AnsiString(Block.GetParamValue(ParamIndex)));
      PackageCollection.AddPackToBack(Pack);
    end;
  end;
  Block := InstallConfig.GetBlock('Packages');
  for ParamIndex := 0 to Block.GetParamCount - 1 do
  begin
    Pack := TPackFileEC.Create;
    Pack.SetPackagePath(AnsiString(Block.GetParamValue(ParamIndex)));
    PackageCollection.AddPackToBack(Pack);
  end;
  Result := PackageCollection.OpenAllPackages;
end;

procedure FinalizePackageCollection;
begin
  PackageCollection.CloseAllPackages;
  PackageCollection.Clear(True);
  PackageCollection.Free;
  PackageCollection := nil;
  if PackageFileLock <> nil then
  begin
    PackageFileLock.Free;
    PackageFileLock := nil;
  end;
end;

end.
