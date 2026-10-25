#!/usr/bin/env python3
"""
SR3D Stage 1.5 — apply all working scale modifications.
Orbits stay at x1 (vanilla). Planets x3, ship speed = vanilla, star damage zone x2.7.

Idempotent: prints "ALREADY APPLIED" for each block that's already modified,
so the script can be re-run safely after partial application.

Run from project root (the folder that contains source/).
"""

import re
import sys
from pathlib import Path


def ensure_root():
    here = Path.cwd()
    if not (here / 'source' / 'game' / 'aPlanet.pas').exists():
        print('ERROR: run from project root (must contain source/game/aPlanet.pas)')
        sys.exit(1)


def read(rel):
    return (Path.cwd() / rel).read_text(encoding='utf-8-sig', errors='replace')


def write(rel, text):
    p = Path.cwd() / rel
    raw = p.read_bytes()
    if b'\r\n' in raw:
        text = text.replace('\n', '\r\n')
    p.write_text(text, encoding='utf-8')


def apply_block(label, path, find, replace, already_marker):
    text = read(path)
    if already_marker in text:
        print(f'  [SKIP] {label}: already applied')
        return True
    if find not in text:
        print(f'  [FAIL] {label}: anchor not found')
        return False
    text = text.replace(find, replace, 1)
    write(path, text)
    print(f'  [ OK ] {label}')
    return True


def patch_gi_planet():
    print('[1/5] source/scene/GI_Planet.pas  (planet x3 with mask-safe rendering)')
    path = 'source/scene/GI_Planet.pas'
    text = read(path)
    ok = True

    if 'IsScaled: Boolean;' in text:
        print('  [SKIP] field IsScaled: already declared')
    else:
        anchor = '    AtmosphereTextureSize: TPoint;\n'
        if anchor not in text:
            print('  [FAIL] cannot find AtmosphereTextureSize declaration')
            ok = False
        else:
            text = text.replace(anchor, anchor + '    IsScaled: Boolean;\n', 1)
            print('  [ OK ] declared IsScaled field')

    find_b = (
        '    MapWidthMask := Image.Bitmap.Width - 1;\n'
        '    SetSize(Classes.Point(Radius * 2 + 1, Radius * 2 + 1));\n'
        '    TemplateCache.SetCacheKey(MaskPath + \'?\' + IntToStr(Cardinal(Image.Bitmap.Width)) + \',\' + IntToStr(Cardinal(Image.Bitmap.Height)));\n'
    )
    repl_b = (
        '    MapWidthMask := Image.Bitmap.Width - 1;\n'
        '    IsScaled := True;\n'
        '    SetSize(Classes.Point((Radius * 2 + 1) * 3, (Radius * 2 + 1) * 3));\n'
        '    SetOrigin(Classes.Point((Radius * 2 + 1) * 3 div 2, (Radius * 2 + 1) * 3 div 2));\n'
        '    UpdateSubtreeHitBounds;\n'
        '    TemplateCache.SetCacheKey(MaskPath + \'?\' + IntToStr(Cardinal(Image.Bitmap.Width)) + \',\' + IntToStr(Cardinal(Image.Bitmap.Height)));\n'
    )
    if 'IsScaled := True;' in text:
        print('  [SKIP] SetImageWithRadius: already patched')
    elif find_b not in text:
        print('  [FAIL] SetImageWithRadius: anchor not found')
        ok = False
    else:
        text = text.replace(find_b, repl_b, 1)
        print('  [ OK ] SetImageWithRadius: scaled x3 + origin + hit bounds')

    find_c = (
        '  TemplateCache.SetCacheKey(TemplateKey);\n'
        '  SetSize(Classes.Point(Radius * 2, Radius * 2));\n'
    )
    repl_c = (
        '  TemplateCache.SetCacheKey(TemplateKey);\n'
        '  IsScaled := False;\n'
        '  SetSize(Classes.Point(Radius * 2, Radius * 2));\n'
    )
    if 'IsScaled := False;' in text:
        print('  [SKIP] SetImageFromTemplate: already patched')
    elif find_c not in text:
        print('  [FAIL] SetImageFromTemplate: anchor not found')
        ok = False
    else:
        text = text.replace(find_c, repl_c, 1)
        print('  [ OK ] SetImageFromTemplate: satellite-safe (IsScaled=False)')

    find_d = (
        '      if ((HitTestBounds.Right - HitTestBounds.Left) <> TextureSize.X) or ((HitTestBounds.Bottom - HitTestBounds.Top) <> TextureSize.Y) then\n'
        '      begin\n'
        '        RenderedMapOffsets[0] := $FFFFFF;\n'
        '        RenderedMapOffsets[1] := RenderedMapOffsets[0];\n'
        '        RenderedMapOffsets[2] := RenderedMapOffsets[0];\n'
        '        RenderedMapOffsets[3] := RenderedMapOffsets[0];\n'
        '        for Index := 0 to 3 do\n'
        '          TextureCache.SetSurface(nil, Index);\n'
        '      end;\n'
        '      TextureSize := Classes.Point(HitTestBounds.Right - HitTestBounds.Left, HitTestBounds.Bottom - HitTestBounds.Top);\n'
    )
    repl_d = (
        '      if IsScaled then\n'
        '      begin\n'
        '        if ((HitTestBounds.Right - HitTestBounds.Left) div 3 <> TextureSize.X) or ((HitTestBounds.Bottom - HitTestBounds.Top) div 3 <> TextureSize.Y) then\n'
        '        begin\n'
        '          RenderedMapOffsets[0] := $FFFFFF;\n'
        '          RenderedMapOffsets[1] := RenderedMapOffsets[0];\n'
        '          RenderedMapOffsets[2] := RenderedMapOffsets[0];\n'
        '          RenderedMapOffsets[3] := RenderedMapOffsets[0];\n'
        '          for Index := 0 to 3 do\n'
        '            TextureCache.SetSurface(nil, Index);\n'
        '        end;\n'
        '        TextureSize := Classes.Point((HitTestBounds.Right - HitTestBounds.Left) div 3, (HitTestBounds.Bottom - HitTestBounds.Top) div 3);\n'
        '      end\n'
        '      else\n'
        '      begin\n'
        '        if ((HitTestBounds.Right - HitTestBounds.Left) <> TextureSize.X) or ((HitTestBounds.Bottom - HitTestBounds.Top) <> TextureSize.Y) then\n'
        '        begin\n'
        '          RenderedMapOffsets[0] := $FFFFFF;\n'
        '          RenderedMapOffsets[1] := RenderedMapOffsets[0];\n'
        '          RenderedMapOffsets[2] := RenderedMapOffsets[0];\n'
        '          RenderedMapOffsets[3] := RenderedMapOffsets[0];\n'
        '          for Index := 0 to 3 do\n'
        '            TextureCache.SetSurface(nil, Index);\n'
        '        end;\n'
        '        TextureSize := Classes.Point(HitTestBounds.Right - HitTestBounds.Left, HitTestBounds.Bottom - HitTestBounds.Top);\n'
        '      end;\n'
    )
    if 'if IsScaled then' in text:
        print('  [SKIP] Draw: condition already patched')
    elif find_d not in text:
        print('  [FAIL] Draw: condition anchor not found')
        ok = False
    else:
        text = text.replace(find_d, repl_d, 1)
        print('  [ OK ] Draw: condition + TextureSize div 3 (IsScaled branch)')

    draw_calls = [
        (
            '      DrawTexture(Texture, HitTestBounds.Left, HitTestBounds.Top, 255, RgbWhite, @ClipRect, False, False);\n'
            '      if HasCloud1 then',
            '      if IsScaled then\n'
            '        DrawTextureSized(Texture, HitTestBounds.Left, HitTestBounds.Top, HitTestBounds.Right - HitTestBounds.Left, HitTestBounds.Bottom - HitTestBounds.Top, 255, RgbWhite, @ClipRect, False, False)\n'
            '      else\n'
            '        DrawTexture(Texture, HitTestBounds.Left, HitTestBounds.Top, 255, RgbWhite, @ClipRect, False, False);\n'
            '      if HasCloud1 then',
            '      if IsScaled then\n'
            '        DrawTextureSized(Texture, HitTestBounds.Left, HitTestBounds.Top, HitTestBounds.Right - HitTestBounds.Left, HitTestBounds.Bottom - HitTestBounds.Top, 255, RgbWhite, @ClipRect, False, False)\n'
            '      else\n'
            '        DrawTexture(Texture, HitTestBounds.Left, HitTestBounds.Top, 255, RgbWhite, @ClipRect, False, False);\n'
            '      if HasCloud1 then',
            'DrawTextureSized (surface layer)',
        ),
        (
            '        DrawTexture(Texture, HitTestBounds.Left, HitTestBounds.Top, 255, RgbWhite, @ClipRect, False, False);\n'
            '      end\n'
            '      else\n'
            '        TextureCache.SetSurface(nil, 1);',
            '        if IsScaled then\n'
            '          DrawTextureSized(Texture, HitTestBounds.Left, HitTestBounds.Top, HitTestBounds.Right - HitTestBounds.Left, HitTestBounds.Bottom - HitTestBounds.Top, 255, RgbWhite, @ClipRect, False, False)\n'
            '        else\n'
            '          DrawTexture(Texture, HitTestBounds.Left, HitTestBounds.Top, 255, RgbWhite, @ClipRect, False, False);\n'
            '      end\n'
            '      else\n'
            '        TextureCache.SetSurface(nil, 1);',
            '        if IsScaled then\n'
            '          DrawTextureSized(Texture, HitTestBounds.Left, HitTestBounds.Top, HitTestBounds.Right - HitTestBounds.Left, HitTestBounds.Bottom - HitTestBounds.Top, 255, RgbWhite, @ClipRect, False, False)\n'
            '        else\n'
            '          DrawTexture(Texture, HitTestBounds.Left, HitTestBounds.Top, 255, RgbWhite, @ClipRect, False, False);\n'
            '      end\n'
            '      else\n'
            '        TextureCache.SetSurface(nil, 1);',
            'DrawTextureSized (cloud1 layer)',
        ),
        (
            '        DrawTexture(Texture, HitTestBounds.Left, HitTestBounds.Top, 255, RgbWhite, @ClipRect, False, False);\n'
            '      end\n'
            '      else\n'
            '        TextureCache.SetSurface(nil, 2);',
            '        if IsScaled then\n'
            '          DrawTextureSized(Texture, HitTestBounds.Left, HitTestBounds.Top, HitTestBounds.Right - HitTestBounds.Left, HitTestBounds.Bottom - HitTestBounds.Top, 255, RgbWhite, @ClipRect, False, False)\n'
            '        else\n'
            '          DrawTexture(Texture, HitTestBounds.Left, HitTestBounds.Top, 255, RgbWhite, @ClipRect, False, False);\n'
            '      end\n'
            '      else\n'
            '        TextureCache.SetSurface(nil, 2);',
            '        if IsScaled then\n'
            '          DrawTextureSized(Texture, HitTestBounds.Left, HitTestBounds.Top, HitTestBounds.Right - HitTestBounds.Left, HitTestBounds.Bottom - HitTestBounds.Top, 255, RgbWhite, @ClipRect, False, False)\n'
            '        else\n'
            '          DrawTexture(Texture, HitTestBounds.Left, HitTestBounds.Top, 255, RgbWhite, @ClipRect, False, False);\n'
            '      end\n'
            '      else\n'
            '        TextureCache.SetSurface(nil, 2);',
            'DrawTextureSized (cloud2 layer)',
        ),
        (
            '        DrawTexture(Texture, HitTestBounds.Left, HitTestBounds.Top, 255, RgbWhite, @ClipRect, False, False);\n'
            '      end\n'
            '      else\n'
            '        TextureCache.SetSurface(nil, 3);',
            '        if IsScaled then\n'
            '          DrawTextureSized(Texture, HitTestBounds.Left, HitTestBounds.Top, HitTestBounds.Right - HitTestBounds.Left, HitTestBounds.Bottom - HitTestBounds.Top, 255, RgbWhite, @ClipRect, False, False)\n'
            '        else\n'
            '          DrawTexture(Texture, HitTestBounds.Left, HitTestBounds.Top, 255, RgbWhite, @ClipRect, False, False);\n'
            '      end\n'
            '      else\n'
            '        TextureCache.SetSurface(nil, 3);',
            '        if IsScaled then\n'
            '          DrawTextureSized(Texture, HitTestBounds.Left, HitTestBounds.Top, HitTestBounds.Right - HitTestBounds.Left, HitTestBounds.Bottom - HitTestBounds.Top, 255, RgbWhite, @ClipRect, False, False)\n'
            '        else\n'
            '          DrawTexture(Texture, HitTestBounds.Left, HitTestBounds.Top, 255, RgbWhite, @ClipRect, False, False);\n'
            '      end\n'
            '      else\n'
            '        TextureCache.SetSurface(nil, 3);',
            'DrawTextureSized (cloud3 layer)',
        ),
        (
            '      if not AtmosphereImageCache.HasEmptyCacheKey and (Texture <> nil) and (AtmosphereColor <> 0) then\n'
            '        DrawTexture(Texture, HitTestBounds.Left, HitTestBounds.Top, 255, RgbWhite, @ClipRect, False, False);\n'
            '    end',
            '      if not AtmosphereImageCache.HasEmptyCacheKey and (Texture <> nil) and (AtmosphereColor <> 0) then\n'
            '        if IsScaled then\n'
            '          DrawTextureSized(Texture, HitTestBounds.Left, HitTestBounds.Top, HitTestBounds.Right - HitTestBounds.Left, HitTestBounds.Bottom - HitTestBounds.Top, 255, RgbWhite, @ClipRect, False, False)\n'
            '        else\n'
            '          DrawTexture(Texture, HitTestBounds.Left, HitTestBounds.Top, 255, RgbWhite, @ClipRect, False, False);\n'
            '    end',
            '      if not AtmosphereImageCache.HasEmptyCacheKey and (Texture <> nil) and (AtmosphereColor <> 0) then\n'
            '        if IsScaled then\n'
            '          DrawTextureSized(Texture, HitTestBounds.Left, HitTestBounds.Top, HitTestBounds.Right - HitTestBounds.Left, HitTestBounds.Bottom - HitTestBounds.Top, 255, RgbWhite, @ClipRect, False, False)\n'
            '        else\n'
            '          DrawTexture(Texture, HitTestBounds.Left, HitTestBounds.Top, 255, RgbWhite, @ClipRect, False, False);\n'
            '    end',
            'DrawTextureSized (atmosphere layer)',
        ),
    ]
    for find_e, repl_e, marker_e, label_e in draw_calls:
        if marker_e in text:
            print(f'  [SKIP] {label_e}: already patched')
            continue
        if find_e not in text:
            print(f'  [FAIL] {label_e}: anchor not found')
            ok = False
            continue
        text = text.replace(find_e, repl_e, 1)
        print(f'  [ OK ] {label_e}')

    if ok:
        write(path, text)
    return ok


def patch_se_planet():
    print('[2/5] source/scene/SE_Planet.pas  (rings x3, collision circle x3)')
    path = 'source/scene/SE_Planet.pas'
    text = read(path)
    ok = True

    find_a = (
        '    CollisionCircle := AllocatePlanetCollisionCircle;\n'
        '    CollisionCircle.Position.X := Position.X;\n'
        '    CollisionCircle.Position.Y := Position.Y;\n'
        '    CollisionCircle.Radius := Radius;\n'
        '    RebuildRings;\n'
    )
    repl_a = (
        '    CollisionCircle := AllocatePlanetCollisionCircle;\n'
        '    CollisionCircle.Position.X := Position.X;\n'
        '    CollisionCircle.Position.Y := Position.Y;\n'
        '    CollisionCircle.Radius := Radius * 3;\n'
        '    CollisionCircle.RadiusSquared := (Radius * 3) * (Radius * 3);\n'
        '    RebuildRings;\n'
    )
    if 'CollisionCircle.Radius := Radius * 3;\n    CollisionCircle.RadiusSquared' in text:
        print('  [SKIP] AttachToSpace CollisionCircle: already patched')
    elif find_a not in text:
        print('  [FAIL] AttachToSpace CollisionCircle: anchor not found')
        ok = False
    else:
        text = text.replace(find_a, repl_a, 1)
        print('  [ OK ] AttachToSpace CollisionCircle x3')

    find_b = (
        '    if CollisionCircle <> nil then\n'
        '    begin\n'
        '      CollisionCircle.Position.X := Position.X;\n'
        '      CollisionCircle.Position.Y := Position.Y;\n'
        '      CollisionCircle.Radius := Radius;\n'
        '      CollisionCircle.RadiusSquared := Radius * Radius;\n'
        '    end;\n'
    )
    repl_b = (
        '    if CollisionCircle <> nil then\n'
        '    begin\n'
        '      CollisionCircle.Position.X := Position.X;\n'
        '      CollisionCircle.Position.Y := Position.Y;\n'
        '      CollisionCircle.Radius := Radius * 3;\n'
        '      CollisionCircle.RadiusSquared := (Radius * 3) * (Radius * 3);\n'
        '    end;\n'
    )
    if 'CollisionCircle.Radius := Radius * 3;\n      CollisionCircle.RadiusSquared := (Radius * 3) * (Radius * 3);' in text:
        print('  [SKIP] SetPosition CollisionCircle: already patched')
    elif find_b not in text:
        print('  [FAIL] SetPosition CollisionCircle: anchor not found')
        ok = False
    else:
        text = text.replace(find_b, repl_b, 1)
        print('  [ OK ] SetPosition CollisionCircle x3')

    find_c = (
        '    RingControl1 := TImageGI.Create(Space.MapPanel);\n'
        '    RingControl1.SetPositionModeW(True);\n'
        '    RingControl1.SetDepth(PlanetControl.Depth - 0.01);\n'
        '    RingControl1.SetImagePath(Path + \'_1\');\n'
        '    RingControl1.SetSize(RingControl1.GetContentSize);\n'
        '    RingControl1.SetPosition(PlanetControl.LocalPosition);\n'
        '    RingControl2 := TImageGI.Create(Space.MapPanel);\n'
        '    RingControl2.SetPositionModeW(True);\n'
        '    RingControl2.SetDepth(PlanetControl.Depth + 0.01);\n'
        '    RingControl2.SetImagePath(Path + \'_2\');\n'
        '    RingControl2.SetSize(RingControl2.GetContentSize);\n'
        '    RingControl2.SetPosition(PlanetControl.LocalPosition);\n'
    )
    repl_c = (
        '    RingControl1 := TImageGI.Create(Space.MapPanel);\n'
        '    RingControl1.SetPositionModeW(True);\n'
        '    RingControl1.SetDepth(PlanetControl.Depth - 0.01);\n'
        '    RingControl1.SetImagePath(Path + \'_1\');\n'
        '    RingControl1.SetSize(Classes.Point(RingControl1.GetContentSize.X * 3, RingControl1.GetContentSize.Y * 3));\n'
        '    RingControl1.AutoUpdateFlags := RingControl1.AutoUpdateFlags and not agfSize;\n'
        '    RingControl1.SetPosition(PlanetControl.LocalPosition);\n'
        '    RingControl2 := TImageGI.Create(Space.MapPanel);\n'
        '    RingControl2.SetPositionModeW(True);\n'
        '    RingControl2.SetDepth(PlanetControl.Depth + 0.01);\n'
        '    RingControl2.SetImagePath(Path + \'_2\');\n'
        '    RingControl2.SetSize(Classes.Point(RingControl2.GetContentSize.X * 3, RingControl2.GetContentSize.Y * 3));\n'
        '    RingControl2.AutoUpdateFlags := RingControl2.AutoUpdateFlags and not agfSize;\n'
        '    RingControl2.SetPosition(PlanetControl.LocalPosition);\n'
    )
    if 'RingControl1.GetContentSize.X * 3' in text:
        print('  [SKIP] RebuildRings ring SetSize x3: already patched')
    elif find_c not in text:
        print('  [FAIL] RebuildRings ring SetSize x3: anchor not found')
        ok = False
    else:
        text = text.replace(find_c, repl_c, 1)
        print('  [ OK ] RebuildRings ring SetSize x3')

    if ok:
        write(path, text)
    return ok


def patch_fstarmap():
    print('[3/5] source/screens/fStarMap.pas  (planet/star hit zones x3, mouse-wheel zoom)')
    path = 'source/screens/fStarMap.pas'
    text = read(path)
    ok = True

    find_a = 'Sqr(Point.X - Planet.GetPosition.X) + Sqr(Point.Y - Planet.GetPosition.Y) < Sqr(Planet.GraphicRadius)'
    repl_a = 'Sqr(Point.X - Planet.GetPosition.X) + Sqr(Point.Y - Planet.GetPosition.Y) < Sqr(Planet.GraphicRadius * 3)'
    if 'Sqr(Planet.GraphicRadius * 3)' in text:
        print('  [SKIP] planet hit test x3: already patched')
    elif find_a not in text:
        print('  [FAIL] planet hit test x3: anchor not found')
        ok = False
    else:
        text = text.replace(find_a, repl_a, 1)
        print('  [ OK ] planet hit test x3')

    find_b = 'Point.X * Point.X + Point.Y * Point.Y < Sqr(PlayerStar.Radius)'
    repl_b = 'Point.X * Point.X + Point.Y * Point.Y < Sqr(PlayerStar.Radius * 3)'
    if 'Sqr(PlayerStar.Radius * 3)' in text:
        print('  [SKIP] star hit test x3: already patched')
    elif find_b not in text:
        print('  [FAIL] star hit test x3: anchor not found')
        ok = False
    else:
        text = text.replace(find_b, repl_b, 1)
        print('  [ OK ] star hit test x3')

    find_c = (
        '  if not HardwareRenderingEnabled then\n'
        '    Scale := 1;\n'
        '  MapControls.ChildWorldScale := Scale;\n'
    )
    repl_c = (
        '  { SR3D: zoom unlocked for desktop so mouse-wheel can change ChildWorldScale }\n'
        '  { if not HardwareRenderingEnabled then Scale := 1; }\n'
        '  MapControls.ChildWorldScale := Scale;\n'
    )
    if 'SR3D: zoom unlocked' in text:
        print('  [SKIP] zoom unlock: already patched')
    elif find_c not in text:
        print('  [FAIL] zoom unlock: anchor not found')
        ok = False
    else:
        text = text.replace(find_c, repl_c, 1)
        print('  [ OK ] zoom unlock')

    find_d = (
        'procedure TfStarMap.ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer);\n'
        'var\n'
        '  FollowMode: Integer;\n'
        '  Ship: TShip;\n'
        'begin\n'
        '  if (Mode = smmOrders) and ((GetPlayer.Order = soFollowShip) or (PendingPlayerFollowTarget <> nil)) then\n'
    )
    repl_d = (
        'procedure TfStarMap.ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer);\n'
        'var\n'
        '  FollowMode: Integer;\n'
        '  Ship: TShip;\n'
        '  SR3D_NewScale: Single;\n'
        'begin\n'
        '  { SR3D: mouse-wheel zoom — only when NOT in follow-mode orders (those use the wheel for follow distance) }\n'
        '  if not ((Mode = smmOrders) and ((GetPlayer.Order = soFollowShip) or (PendingPlayerFollowTarget <> nil))) then\n'
        '  begin\n'
        '    SR3D_NewScale := MapControls.ChildWorldScale;\n'
        '    if Delta > 0 then\n'
        '      SR3D_NewScale := SR3D_NewScale + 0.05\n'
        '    else if Delta < 0 then\n'
        '      SR3D_NewScale := SR3D_NewScale - 0.05;\n'
        '    if SR3D_NewScale < 0.10 then SR3D_NewScale := 0.10;\n'
        '    if SR3D_NewScale > 1.00 then SR3D_NewScale := 1.00;\n'
        '    if Abs(SR3D_NewScale - MapControls.ChildWorldScale) > 0.001 then\n'
        '      ApplySpaceZoom(SR3D_NewScale);\n'
        '    Exit;\n'
        '  end;\n'
        '  if (Mode = smmOrders) and ((GetPlayer.Order = soFollowShip) or (PendingPlayerFollowTarget <> nil)) then\n'
    )
    if 'SR3D: mouse-wheel zoom' in text:
        print('  [SKIP] mouse-wheel zoom: already patched')
    elif find_d not in text:
        print('  [FAIL] mouse-wheel zoom: anchor not found')
        ok = False
    else:
        text = text.replace(find_d, repl_d, 1)
        print('  [ OK ] mouse-wheel zoom (10%-100%, step 5%)')

    if ok:
        write(path, text)
    return ok


def patch_aship():
    print('[4/5] source/game/aShip.pas  (DISABLED — keeping vanilla ship speed)')
    return True


def patch_agalaxy():
    print('[5/5] source/game/aGalaxy.pas  (star safe/damage zone x2.7)')
    path = 'source/game/aGalaxy.pas'
    text = read(path)
    ok = True

    find = (
        '  SafeRadius := ExtractDecimalToSingleW(Definition.GetParam(\'SafeRadius\'));\n'
        '  DamageRadius := ExtractDecimalToSingleW(Definition.GetParam(\'DamageRadius\'));\n'
    )
    repl = (
        '  SafeRadius := ExtractDecimalToSingleW(Definition.GetParam(\'SafeRadius\')) * 2.7;\n'
        '  DamageRadius := ExtractDecimalToSingleW(Definition.GetParam(\'DamageRadius\')) * 2.7;\n'
    )
    if 'ExtractDecimalToSingleW(Definition.GetParam(\'SafeRadius\')) * 2.7' in text:
        print('  [SKIP] star SafeRadius/DamageRadius x2.7: already patched')
    elif find not in text:
        print('  [FAIL] star SafeRadius/DamageRadius x2.7: anchor not found')
        ok = False
    else:
        text = text.replace(find, repl, 1)
        print('  [ OK ] star SafeRadius/DamageRadius x2.7')
        write(path, text)
    return ok


def main():
    ensure_root()
    print()
    print('=== SR3D Stage 1.5 — applying all working modifications ===')
    print('Orbits stay at x1 (vanilla). Planets x3, ship speed = vanilla, star damage zone x2.7.')
    print()
    results = []
    results.append(patch_gi_planet())
    print()
    results.append(patch_se_planet())
    print()
    results.append(patch_fstarmap())
    print()
    results.append(patch_aship())
    print()
    results.append(patch_agalaxy())
    print()
    if all(results):
        print('=== ALL PATCHES APPLIED SUCCESSFULLY ===')
        return 0
    else:
        print('=== SOME PATCHES FAILED — review output above ===')
        return 1


if __name__ == '__main__':
    sys.exit(main())