{$EXCESSPRECISION OFF}
unit ab_W17;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
uses
  EC_Struct,
  GI_Tail,
  ab_Global,
  ab_Object,
  ab_WorldImage;
type
  TabW17 = class;
  TabW17 = class(TabObject)
    Damage: Integer;
    Image: PabWorldImage;
    Phase: Integer;
    ExpireTick: Integer;
    Partner: TabW17;
    procedure Advance; override;
    procedure UpdateVisuals; override;
    constructor Create;
    destructor Destroy; override;
    procedure Launch(Owner: TabObject; Amount: Integer);
    procedure LaunchPartner(Other: TabW17; Owner: TabObject; Amount: Integer);
  end;
implementation
uses
  Math,
  aMyFunction,
  ab_Ship,
  GlobalsV;

constructor TabW17.Create;
begin
  inherited Create;
  MaxSpeed := 20;
  Mass := 0.1;
  Thrust := 1;
  CollisionRadius := 5;
  Collidable := False;
end;

destructor TabW17.Destroy;
begin
  if Image <> nil then
  begin
    ab_WorldImage_Delete(Image);
    Image := nil;
  end;
  if Partner <> nil then
    Partner.Partner := nil;
  inherited Destroy;
end;

procedure TabW17.Launch(Owner: TabObject; Amount: Integer);
var
  Other: TabW17;
begin
  SourceObject := Owner;
  Damage := Amount;
  State := Owner.State;
  Velocity := Owner.Velocity;
  State.BearingDegrees := State.BearingDegrees + 30;
  Phase := 0;
  ExpireTick := ArcadeTickCount + 120;
  Partner := nil;
  Image := ab_WorldImage_Create(MakeVector3D(0, 0, 0), 'GAI,Bm.AB.w17_f', 'GAI,Bm.AB.w17_s', False);
  ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
  Other := TabW17.Create;
  ab_Object_Add(Other);
  Other.LaunchPartner(Self, Owner, Amount);
end;

procedure TabW17.LaunchPartner(Other: TabW17; Owner: TabObject; Amount: Integer);
begin
  SourceObject := Owner;
  Damage := Amount;
  State := Owner.State;
  Velocity := Owner.Velocity;
  State.BearingDegrees := State.BearingDegrees - 30;
  Phase := 2;
  ExpireTick := ArcadeTickCount + 120;
  Partner := Other;
  Other.Partner := Self;
  Image :=
      ab_WorldImage_Create(MakeVector3D(0, 0, 0), 'GAI,Bm.AB.w17b_f', 'GAI,Bm.AB.w17b_s', False);
  ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
end;

procedure TabW17.Advance;
var
  Collision: TabObject;
  Delta: Double;
begin
  inherited Advance;
  if (Phase <> 1) and (Phase <> 3) then
    ab_WorldImage_SetPosition(Image, GetWorldPosition);
  if (Phase in [0, 2]) and (DistanceTravelled > 200) then
    MaxSpeed := 11;
  Collision := nil;
  if (Phase <> 1) and (Phase <> 3) then
  begin
    Collision := FindCollision;
    if (DistanceTravelled < 300) and (Phase in [0, 2]) and (Collision = SourceObject) then
      Collision := nil;
    if Partner = Collision then
      Collision := nil;
  end;
  if ((ArcadeTickCount > ExpireTick) or (Collision <> nil)) and (Phase <> 1) and (Phase <> 3) then
  begin
    if Collision <> nil then
    begin
      Collision.ApplyDamage(Damage, SourceObject, False);
      if Partner <> nil then
      begin
        Partner.Velocity := Collision.Velocity;
        Partner.State.BearingDegrees :=
            Partner.BearingAndDistanceTo(Collision).BearingDeltaDegrees
                + Partner.State.BearingDegrees;
        Partner.MaxSpeed := Partner.MaxSpeed * 1.5;
        Partner.Thrust := 2;
        Partner.Partner := nil;
        Partner := nil;
      end;
    end;
    if Phase = 0 then
    begin
      Phase := 1;
      ab_WorldImage_Set(Image, GetWorldPosition, 'GAI,Bm.AB.w17a_f', 'GAI,Bm.AB.w17a_s');
      ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
      ab_WorldImage_SetLooping(Image, False);
    end
    else
    begin
      Phase := 3;
      ab_WorldImage_Set(Image, GetWorldPosition, 'GAI,Bm.AB.w17c_f', 'GAI,Bm.AB.w17c_s');
      ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
      ab_WorldImage_SetLooping(Image, False);
    end;
  end
  else if (Phase in [0, 2]) and (Partner <> nil) then
  begin
    with BearingAndDistanceTo(Partner) do
    begin
      Delta := BearingDeltaDegrees;
      while Delta > 180 do
        Delta := Delta - 360;
      while Delta < -180 do
        Delta := Delta + 360;
      if (Distance > 100) and (Abs(Delta) > 60) then
      begin
        if Delta > 0 then
          Delta := Delta - 60
        else
          Delta := Delta + 60;
        State.BearingDegrees := WrapHeadingDegrees(State.BearingDegrees + Delta);
      end;
    end;
  end
  else if (Phase = 1) or (Phase = 3) then
    DeletionPending := Image.Finished;
end;

procedure TabW17.UpdateVisuals;
begin
  inherited UpdateVisuals;
end;

end.
