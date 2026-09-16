// The game uses wrapping arithmetic and variable-sized buffers.
{$R-}
{$Q-}

// Boolean guards short-circuit unless a local B+ directive requests otherwise.
{$B-}

// Preserve Delphi's maximum field alignment across target CPUs.
{$A8}

// FPC enables pointer arithmetic by default only in fpc/objfpc modes, and its x86
// code generator needs the directive for the game's pointer arithmetic in DELPHI
// mode. The other targets compile the same expressions without it, so it stays
// scoped to x86 and leaves their builds untouched.
{$IFDEF CPUX86}
  {$POINTERMATH ON}
{$ENDIF}
