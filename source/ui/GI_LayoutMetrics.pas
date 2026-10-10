unit GI_LayoutMetrics;

{$I GameOptions.inc}

interface

type
  TDialogueExpansion = record
    Text, Choices: Integer;
  end;

  TShopExpansion = record
    Width, Columns: Integer;
  end;

// These measurements are shared by the controls and their generated artwork.
function MeasureDialogueExpansion(ContentHeight: Integer): TDialogueExpansion;
function MeasureShopExpansion(LayoutWidth: Integer): TShopExpansion;

implementation

uses
  Math;

function MeasureDialogueExpansion(ContentHeight: Integer): TDialogueExpansion;
var
  Rows: Integer;
begin
  // The original desktop skin can repeat its middle strips, but its fixed
  // corners and separators cannot shrink. Mobile uses a separate composition.
  Rows := EnsureRange(ContentHeight - 768, 0, 250) div 3;
  Result.Choices := Rows div 4 * 3;
  Result.Text := Rows * 3 - Result.Choices;
end;

function MeasureShopExpansion(LayoutWidth: Integer): TShopExpansion;
begin
  Result.Width := Min(Max(0, LayoutWidth - 1024) div 198 * 198, 198);
  Result.Columns := 6 + Result.Width div 99;
end;

end.
