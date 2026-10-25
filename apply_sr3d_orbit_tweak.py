#!/usr/bin/env python3
"""
SR3D orbit gap tweak — small targeted adjustment to make inter-orbit spacing
scale with planet size while preserving the vanilla structure.

Change (in all 9 orbit-gap locations in aPlanet.pas):
  Before:  PreviousPlanet.Radius + Radius + 200
  After:   PreviousPlanet.Radius * 2 + Radius * 2 + 350

Effect on inter-orbit gap (vs vanilla +200 base gap):
  Two 60-radius planets:   320 -> 390  (+22%)
  Two 80-radius planets:   360 -> 470  (+31%)
  Two 100-radius planets:  400 -> 550  (+38%)

The gap now scales meaningfully with planet size, so outer planets are visibly
farther apart than inner ones. No cumulative multipliers, no * 3 disaster.

Idempotent: detects the "* 2 + Radius * 2 + 350" pattern as already-applied.

Run from project root (folder that contains source/).
"""

import re
import sys
from pathlib import Path


# Vanilla form (single-line and multi-line both contain this fragment):
OLD_FRAG = 'PreviousPlanet.Radius + Radius + 200'
NEW_FRAG = 'PreviousPlanet.Radius * 2 + Radius * 2 + 350'

# Already-applied marker:
NEW_MARKER = 'PreviousPlanet.Radius * 2 + Radius * 2 + 350'


def main():
    src = Path.cwd() / 'source' / 'game' / 'aPlanet.pas'
    if not src.exists():
        print('ERROR: run from project root (must contain source/game/aPlanet.pas)')
        return 1

    raw = src.read_bytes()
    text = raw.decode('utf-8-sig', errors='replace')

    # --- Form 1: single-line ---
    # "PreviousPlanet.Radius + Radius + 200"
    OLD_FRAG_1 = 'PreviousPlanet.Radius + Radius + 200'
    NEW_FRAG_1 = 'PreviousPlanet.Radius * 2 + Radius * 2 + 350'

    # --- Form 2: multi-line (3 lines) ---
    # "    + PreviousPlanet.Radius\n    + Radius\n    + 200"
    # The indentation varies (16 spaces for cases 3-6, 12 spaces for line 828).
    # Match the structure regardless of indentation.
    OLD_FRAG_2_RE = re.compile(
        r'(\+[ \t]+PreviousPlanet\.Radius)\n'
        r'([ \t]*)\+[ \t]+Radius\n'
        r'(\2)\+[ \t]+200'
    )
    NEW_FRAG_2_TEMPLATE = (
        '{first}\n'
        '{indent}+ Radius * 2\n'
        '{indent}+ 350'
    )

    # Count occurrences of each form.
    n1 = text.count(OLD_FRAG_1)
    n2 = len(OLD_FRAG_2_RE.findall(text))

    if n1 == 0 and n2 == 0:
        if NEW_MARKER in text or '* 2 + Radius * 2 + 350' in text or '+ Radius * 2\n                + 350' in text:
            print('[SKIP] orbit gap already tweaked')
            return 0
        print('[FAIL] no vanilla orbit gap patterns found')
        print('       Make sure aPlanet.pas is vanilla (run: git restore --source=origin/main source\\game\\aPlanet.pas)')
        return 1

    print(f'Found {n1} single-line and {n2} multi-line orbit gap formula(s) to tweak')

    new_text = text

    if n1 > 0:
        new_text = new_text.replace(OLD_FRAG_1, NEW_FRAG_1)
        print(f'  [ OK ] tweaked {n1} single-line formula(s)')

    if n2 > 0:
        def replace_ml(m):
            first = m.group(1)
            indent = m.group(2)
            return NEW_FRAG_2_TEMPLATE.format(first=first, indent=indent)
        new_text = OLD_FRAG_2_RE.sub(replace_ml, new_text)
        print(f'  [ OK ] tweaked {n2} multi-line formula(s)')

    # Verify "Size + 200" (hull size on line ~5363) is untouched.
    if 'MaxSize := Size + 200;' not in new_text:
        print('[FAIL] "Size + 200" was unexpectedly modified — aborting')
        return 1

    # Preserve line endings.
    out = new_text.encode('utf-8')
    if b'\r\n' in raw:
        out = out.replace(b'\n', b'\r\n')
    src.write_bytes(out)

    print()
    print(f'Total: {n1 + n2} orbit gap formula(s) tweaked')
    print()
    print('Effect on inter-orbit spacing:')
    print('  Two 60-radius planets:   320 -> 390  (+22%)')
    print('  Two 80-radius planets:   360 -> 470  (+31%)')
    print('  Two 100-radius planets:  400 -> 550  (+38%)')
    print()
    print('Next:')
    print('  1. python tools/build.py --release')
    print('  2. python tools/run.py --release --game-dir="D:\\Games\\Space Rangers HD A War Apart"')
    print('  3. Start new game, check orbit spacing between planets')
    print()
    print('If too tight:  change 350 -> 250 (more gap)')
    print('If too loose:  change 350 -> 100 (less gap)')
    print('If still want vanilla:  git restore --source=origin/main source\\game\\aPlanet.pas')
    return 0


if __name__ == '__main__':
    sys.exit(main())
