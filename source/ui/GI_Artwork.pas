unit GI_Artwork;

{$I GameOptions.inc}

interface

uses
  GR_GraphBuf;

// Read unmodified artwork so custom layouts use stable source-pixel cuts.
procedure LoadOriginalGiArtwork(const Path: WideString; Buffer: TGraphBufGR);

implementation

uses
  EC_Cache,
  EC_CacheBuf,
  GR_gi,
  GR_Main;

procedure LoadOriginalGiArtwork(const Path: WideString; Buffer: TGraphBufGR);
var
  Control: TCBufControlEC;
  Data: TCBufEC;
  Image: TgiGR;
begin
  // The ordinary GI cache has already adapted these assets to desktop layout.
  // Read the original through the buffer cache so the skin's cuts stay stable.
  Control := TCBufControlEC.Create;
  Image := TgiGR.Create;
  try
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(Path);
    Data := AcquireOrCreateBuffer(Control);
    Image.LoadRawGiFromBuffer(Data.Buffer);
    Image.DecodeToGraphBuf(Buffer, False);
  finally
    Image.Free;
    Control.Free;
  end;
end;

end.
