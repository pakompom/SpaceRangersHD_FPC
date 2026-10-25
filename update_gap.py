#!/usr/bin/env python3
"""Update orbit gap. Gap grows with planet index."""
import re
from pathlib import Path

GAP_BASE = 450           # базовый зазор (было 350)
GAP_PER_INDEX = 120      # +120 за каждый последующий индекс (было 80)
FIRST_OFFSET = 400       # 1-я планета от звезды

src = Path('source/game/aPlanet.pas')
raw = src.read_bytes()
text = raw.decode('utf-8-sig', errors='replace')

old1 = 'PreviousPlanet.Radius + Radius + 200'
new1 = f'PreviousPlanet.Radius * 2 + Radius * 2 + {GAP_BASE} + Star.Planets.Count * {GAP_PER_INDEX}'
n1 = text.count(old1)
text = text.replace(old1, new1)

old2_re = re.compile(
    r'(\+ PreviousPlanet\.Radius)\r?\n'
    r'([ \t]*)\+ Radius\r?\n'
    r'\2\+ 200'
)
def repl2(m):
    indent = m.group(2)
    return (f'{m.group(1)} * 2\r\n'
            f'{indent}+ Radius * 2\r\n'
            f'{indent}+ {GAP_BASE} + Star.Planets.Count * {GAP_PER_INDEX}')
n2 = len(old2_re.findall(text))
text = old2_re.sub(repl2, text)

old3 = 'Orbit.Radius := Radius + Star.SystemRadius + 175;'
new3 = f'Orbit.Radius := Radius + Star.SystemRadius + {FIRST_OFFSET};'
n3 = text.count(old3)
text = text.replace(old3, new3)

old4 = 'Orbit.Radius := Radius + Star.SystemRadius + 350'
new4 = f'Orbit.Radius := Radius + Star.SystemRadius + {FIRST_OFFSET * 2}'
n4 = text.count(old4)
text = text.replace(old4, new4)

out = text.encode('utf-8')
if b'\r\n' not in raw:
    out = out.replace(b'\r\n', b'\n')
src.write_bytes(out)

print(f'Base gap: {GAP_BASE}, per-index: +{GAP_PER_INDEX}')
print(f'  P1->P2 gap base: {GAP_BASE + 1 * GAP_PER_INDEX}')
print(f'  P2->P3 gap base: {GAP_BASE + 2 * GAP_PER_INDEX}')
print(f'  P3->P4 gap base: {GAP_BASE + 3 * GAP_PER_INDEX}')
print(f'  P4->P5 gap base: {GAP_BASE + 4 * GAP_PER_INDEX}')
print(f'  P5->P6 gap base: {GAP_BASE + 5 * GAP_PER_INDEX}')
print(f'First offset: {FIRST_OFFSET} (solar), {FIRST_OFFSET * 2} (non-solar)')
print(f'Replaced {n1} single + {n2} multi gap, {n3} solar first, {n4} non-solar first')