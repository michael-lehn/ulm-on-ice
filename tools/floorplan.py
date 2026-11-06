#!/usr/bin/env python3
"""
Visualize where a design ends up on the iCE40 chip.

Input:  JSON written by tools/pnr_dump.py (nextpnr --post-route script)
Output: self-contained HTML page with
          - a floorplan: every logic tile with its 8 logic cells, colored by
            the top-level instance that owns them
          - a treemap: logic cells per instance and sub-instance
          - a table with the numbers

Ownership comes from cell names. yosys names a cell after the net it drives,
and that name carries the instance path (e.g. "dev_alu0.acc_..."). This is a
good approximation, but a cell that sits at a module boundary may be counted
for the neighbouring instance.

Usage: floorplan.py DUMP.json OUT.html [TITLE]
"""

import html
import json
import sys
from collections import Counter, defaultdict

MAX_COLORS = 7  # categorical slots used; everything else goes to "Other"
TOP = "(top-level logic)"
OTHER = "Other"
OWN = "(own logic)"

LC = "ICESTORM_LC"
BLOCKS = {  # non-logic sites worth drawing: label, height in tiles
    "ICESTORM_RAM": ("block RAM", 2),
    "ICESTORM_DSP": ("DSP", 4),
    "ICESTORM_SPRAM": ("SPRAM", 1),
    "SB_IO": ("I/O pin", 1),
}

TILE = 22
GAP = 1


def owner(cell):
    """Top-level group and sub-group of a cell name."""
    if cell.startswith("$nextpnr"):
        return TOP, "route-through"
    if "$sb_io" in cell or "." not in cell:
        return TOP, None
    parts = cell.split(".")
    return parts[0], parts[1] if len(parts) > 2 else OWN


def squarify(items, x, y, w, h):
    """Squarified treemap. items: list of (value, payload), value > 0."""
    items = sorted(items, key=lambda i: -i[0])
    total = sum(v for v, _ in items)
    out = []

    def worst(row, side, scale):
        s = sum(v for v, _ in row) * scale
        return max(max(side * side * v * scale / (s * s),
                       s * s / (side * side * v * scale)) for v, _ in row)

    while items:
        scale = w * h / total
        side = min(w, h)
        row = [items.pop(0)]
        while items and worst(row + [items[0]], side, scale) <= worst(row, side, scale):
            row.append(items.pop(0))
        rsum = sum(v for v, _ in row)
        thick = rsum * scale / side
        pos = 0.0
        for v, p in row:
            length = v * scale / thick
            if w >= h:  # row is a column on the left
                out.append((x, y + pos, thick, length, v, p))
            else:  # row is a strip on top
                out.append((x + pos, y, length, thick, v, p))
            pos += length
        if w >= h:
            x, w = x + thick, w - thick
        else:
            y, h = y + thick, h - thick
        total -= rsum
    return out


def main():
    dump, out_path = sys.argv[1], sys.argv[2]
    title = sys.argv[3] if len(sys.argv) > 3 else "design"
    bels = json.load(open(dump))["bels"]

    lcs = [b for b in bels if b["type"] == LC]
    used = [b for b in lcs if b["cell"]]
    nx = max(b["x"] for b in bels) + 1
    ny = max(b["y"] for b in bels) + 1

    # groups: the largest instances get a color, the rest is folded together
    count = Counter(owner(b["cell"])[0] for b in used)
    named = [g for g, _ in count.most_common() if g != TOP][:MAX_COLORS]
    group_of = {g: (g if g in named or g == TOP else OTHER) for g in count}
    group_of[TOP] = TOP
    order = named + [g for g in (OTHER, TOP) if g in group_of.values()]
    css_class = {g: f"s{i + 1}" for i, g in enumerate(named)}
    css_class[OTHER] = "so"
    css_class[TOP] = "st"

    lc_count = Counter()
    sub_count = defaultdict(Counter)
    block_count = defaultdict(Counter)
    for b in used:
        top, sub = owner(b["cell"])
        g = group_of[top]
        lc_count[g] += 1
        sub_count[g][sub if g == top else top] += 1
    for b in bels:
        if b["type"] in BLOCKS and b["cell"]:
            g = group_of.get(owner(b["cell"])[0], TOP)
            group_of.setdefault(owner(b["cell"])[0], g)
            block_count[g][b["type"]] += 1
            if g not in order:
                order.append(g)
                css_class.setdefault(g, "st")

    # ---------------------------------------------------------- floorplan
    def ty(y):  # y = 0 is the bottom row of the chip
        return (ny - 1 - y) * TILE

    tiles = defaultdict(list)
    for b in lcs:
        tiles[(b["x"], b["y"])].append(b)

    svg = []
    strip = (TILE - 2 * GAP) / 8
    for (x, y), cells in sorted(tiles.items()):
        px, py = x * TILE, ty(y)
        tip = Counter()
        for b in sorted(cells, key=lambda b: b["z"]):
            sy = py + GAP + b["z"] * strip
            if b["cell"]:
                g = group_of[owner(b["cell"])[0]]
                tip[g] += 1
                svg.append(f'<rect class="{css_class[g]}" x="{px + GAP}" y="{sy:.2f}" '
                           f'width="{TILE - 2 * GAP}" height="{strip - 1:.2f}" rx="0.5"/>')
            else:
                tip["empty"] += 1
                svg.append(f'<rect class="free" x="{px + GAP}" y="{sy:.2f}" '
                           f'width="{TILE - 2 * GAP}" height="{strip - 1:.2f}" rx="0.5"/>')
        text = f"logic tile ({x},{y})&#10;" + "&#10;".join(
            f"{html.escape(g)}: {n} cell{'s' if n != 1 else ''}" for g, n in tip.most_common())
        svg.append(f'<rect class="hit" x="{px}" y="{py}" width="{TILE}" height="{TILE}" '
                   f'data-tip="{text}"/>')

    seen = set()
    for b in bels:
        if b["type"] not in BLOCKS:
            continue
        label, height = BLOCKS[b["type"]]
        x, y = b["x"], b["y"]
        if b["type"] == "SB_IO" or b["type"] == "ICESTORM_SPRAM":
            # several per tile: small squares side by side
            size = TILE / 2 - 2
            px = x * TILE + 1 + (b["z"] % 2) * (TILE / 2)
            py = ty(y) + 1 + (b["z"] // 2) * (TILE / 2)
            w = h = size
        else:
            if (b["type"], x, y) in seen:
                continue
            seen.add((b["type"], x, y))
            px, py = x * TILE + GAP, ty(y + height - 1) + GAP
            w, h = TILE - 2 * GAP, height * TILE - 2 * GAP
        if b["cell"]:
            g = group_of.get(owner(b["cell"])[0], TOP)
            cls, who = css_class.get(g, "st") + " block", g
        else:
            cls, who = "freeblock", "unused"
        svg.append(f'<rect class="{cls}" x="{px:.2f}" y="{py:.2f}" width="{w:.2f}" '
                   f'height="{h:.2f}" rx="2" data-tip="{label} ({x},{y})&#10;{html.escape(who)}"/>')

    fw, fh = nx * TILE, ny * TILE
    floorplan = (f'<svg viewBox="0 0 {fw} {fh}" width="{fw}" height="{fh}" role="img" '
                 f'aria-label="Floorplan of the chip">{"".join(svg)}</svg>')

    # ---------------------------------------------------------- treemap
    TW, TH = 720, 440
    tm = []
    top_items = [(lc_count[g], g) for g in order if lc_count[g]]
    for x, y, w, h, v, g in squarify(top_items, 0, 0, TW, TH):
        subs = [(n, s) for s, n in sub_count[g].items() if n]
        inner = squarify(subs, x + 2, y + 2, max(w - 4, 1), max(h - 4, 1))
        for sx, sy, sw, sh, sv, s in inner:
            name = g if s in (OWN, None) else (f"{g}.{s}" if g not in (OTHER, TOP) else s)
            if s == OWN:
                name = f"{g} {OWN}"
            tm.append(f'<rect class="{css_class[g]} tm" x="{sx + 1:.1f}" y="{sy + 1:.1f}" '
                      f'width="{max(sw - 2, 0.5):.1f}" height="{max(sh - 2, 0.5):.1f}" rx="3" '
                      f'data-tip="{html.escape(name)}&#10;{sv} logic cells '
                      f'({100 * sv / len(used):.1f}%)"/>')
            dark = " dk" if css_class[g] == "st" else ""
            if sw > 70 and sh > 34:
                short = s if s not in (OWN, None) else OWN
                tm.append(f'<text x="{sx + 7:.1f}" y="{sy + 18:.1f}" class="tml{dark}">'
                          f'{html.escape(short)}</text>'
                          f'<text x="{sx + 7:.1f}" y="{sy + 32:.1f}" class="tmv{dark}">{sv}</text>')
        if w > 90 and h > 50:
            dark = " dk" if css_class[g] == "st" else ""
            tm.append(f'<text x="{x + w - 8:.1f}" y="{y + h - 9:.1f}" class="tmg{dark}" '
                      f'text-anchor="end">{html.escape(g)} · {v}</text>')
    treemap = (f'<svg viewBox="0 0 {TW} {TH}" width="100%" role="img" '
               f'aria-label="Treemap of logic cells per instance">{"".join(tm)}</svg>')

    # ---------------------------------------------------------- table
    rows = []
    for g in order:
        blocks = ", ".join(f"{n} {BLOCKS[t][0]}{'s' if n != 1 else ''}"
                           for t, n in sorted(block_count[g].items()))
        subs = ", ".join(f"{html.escape(s)} {n}" for s, n in sub_count[g].most_common()
                         if s not in (OWN, None) and g not in (OTHER,))
        if g == OTHER:
            subs = ", ".join(f"{html.escape(s)} {n}" for s, n in sub_count[g].most_common())
        rows.append(f'<tr><td><span class="sw {css_class[g]}"></span>{html.escape(g)}</td>'
                    f'<td class="num">{lc_count[g]}</td>'
                    f'<td class="num">{100 * lc_count[g] / len(used):.1f}%</td>'
                    f'<td>{blocks}</td><td class="muted">{subs}</td></tr>')
    table = "".join(rows)

    page = PAGE.format(
        title=html.escape(title), floorplan=floorplan, treemap=treemap, table=table,
        used=len(used), total=len(lcs), pct=100 * len(used) / len(lcs))
    open(out_path, "w").write(page)


PAGE = """<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Floorplan {title}</title>
<style>
:root {{
  color-scheme: light;
  --surface-1: #fcfcfb; --surface-2: #efeeea; --border: #dcdbd5;
  --text-primary: #0b0b0b; --text-secondary: #52514e; --text-muted: #77766f;
  --s1: #2a78d6; --s2: #eb6834; --s3: #1baf7a; --s4: #eda100;
  --s5: #e87ba4; --s6: #008300; --s7: #6250d6; --so: #9a9992; --st: #c3c2b7;
}}
@media (prefers-color-scheme: dark) {{
  :root {{
    color-scheme: dark;
    --surface-1: #1a1a19; --surface-2: #262624; --border: #3a3a37;
    --text-primary: #f0efec; --text-secondary: #c3c2b7; --text-muted: #9a9992;
    --s1: #3987e5; --s2: #d95926; --s3: #199e70; --s4: #c98500;
    --s5: #d55181; --s6: #008300; --s7: #9085e9; --so: #77766f; --st: #52514e;
  }}
}}
* {{ box-sizing: border-box; }}
body {{ margin: 0; background: var(--surface-1); color: var(--text-primary);
  font: 14px/1.45 -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }}
main {{ max-width: 1180px; margin: 0 auto; padding: 24px 16px 48px; }}
h1 {{ font-size: 20px; margin: 0 0 4px; }}
h2 {{ font-size: 15px; margin: 0 0 4px; }}
p.lead, p.note {{ color: var(--text-secondary); margin: 0 0 16px; }}
p.note {{ font-size: 12.5px; color: var(--text-muted); }}
.row {{ display: flex; gap: 32px; flex-wrap: wrap; align-items: flex-start; }}
.card {{ min-width: 0; }}
.fp {{ overflow-x: auto; max-width: 100%; }}
.tmwrap {{ flex: 1 1 440px; }}
.s1 {{ fill: var(--s1); background: var(--s1); }} .s2 {{ fill: var(--s2); background: var(--s2); }}
.s3 {{ fill: var(--s3); background: var(--s3); }} .s4 {{ fill: var(--s4); background: var(--s4); }}
.s5 {{ fill: var(--s5); background: var(--s5); }} .s6 {{ fill: var(--s6); background: var(--s6); }}
.s7 {{ fill: var(--s7); background: var(--s7); }} .so {{ fill: var(--so); background: var(--so); }}
.st {{ fill: var(--st); background: var(--st); }}
.free {{ fill: var(--surface-2); }}
.freeblock {{ fill: var(--surface-1); stroke: var(--text-muted); stroke-width: 1; stroke-dasharray: 3 2; }}
.block {{ stroke: var(--surface-1); stroke-width: 1; }}
.hit {{ fill: transparent; }}
.hit:hover {{ stroke: var(--text-primary); stroke-width: 1.5; }}
.block:hover, .freeblock:hover, .tm:hover {{ stroke: var(--text-primary); stroke-width: 1.5; }}
.tml {{ font-size: 12px; font-weight: 600; fill: #fff; pointer-events: none; }}
.tmv {{ font-size: 11.5px; fill: #fff; opacity: .9; pointer-events: none;
  font-variant-numeric: tabular-nums; }}
.tmg {{ font-size: 11px; font-weight: 600; fill: #fff; opacity: .85; pointer-events: none; }}
.tml, .tmv, .tmg {{ paint-order: stroke; stroke: rgba(0,0,0,.35); stroke-width: 2px; }}
.tml.dk, .tmv.dk, .tmg.dk {{ fill: var(--text-primary); stroke: none; }}
table {{ border-collapse: collapse; margin-top: 8px; width: 100%; }}
th, td {{ text-align: left; padding: 6px 10px; border-bottom: 1px solid var(--border);
  vertical-align: top; }}
th {{ color: var(--text-secondary); font-weight: 600; font-size: 12.5px; }}
td.num {{ text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap; }}
td.muted {{ color: var(--text-muted); font-size: 12.5px; }}
.sw {{ display: inline-block; width: 10px; height: 10px; border-radius: 2px;
  margin-right: 8px; vertical-align: -1px; }}
#tip {{ position: fixed; pointer-events: none; display: none; white-space: pre;
  background: var(--surface-1); color: var(--text-primary); border: 1px solid var(--border);
  border-radius: 6px; padding: 6px 9px; font-size: 12.5px; box-shadow: 0 2px 10px rgba(0,0,0,.15); }}
</style></head>
<body><main>
<h1>Floorplan: {title}</h1>
<p class="lead">{used} of {total} logic cells used ({pct:.0f}%), iCE40 UP5K. Hover over tiles and boxes for details.</p>
<div class="row">
  <div class="card">
    <h2>Chip</h2>
    <p class="note">Each square is a logic tile with 8 logic cells (one LUT + flip-flop each); grey = free.<br>
    Tall boxes: block RAMs (middle columns) and DSPs (edges). Small squares: SPRAMs and I/O pins. Dashed = unused.</p>
    <div class="fp">{floorplan}</div>
  </div>
  <div class="card tmwrap">
    <h2>Logic cells per instance</h2>
    <p class="note">Area = number of logic cells. Inner boxes are sub-instances; "(own logic)" is logic of the instance itself.</p>
    {treemap}
    <table>
      <thead><tr><th>Instance</th><th class="num">Logic cells</th><th class="num">Share</th><th>Blocks</th><th>Largest parts</th></tr></thead>
      <tbody>{table}</tbody>
    </table>
    <p class="note">Ownership is taken from cell names (instance path of the net a cell drives). Cells at module boundaries can be
    counted for a neighbouring instance.</p>
  </div>
</div>
</main>
<div id="tip"></div>
<script>
const tip = document.getElementById('tip');
document.addEventListener('mousemove', e => {{
  const t = e.target.closest('[data-tip]');
  if (!t) {{ tip.style.display = 'none'; return; }}
  tip.textContent = t.getAttribute('data-tip');
  tip.style.display = 'block';
  const r = tip.getBoundingClientRect();
  let x = e.clientX + 14, y = e.clientY + 14;
  if (x + r.width > innerWidth - 8) x = e.clientX - r.width - 14;
  if (y + r.height > innerHeight - 8) y = e.clientY - r.height - 14;
  tip.style.left = x + 'px'; tip.style.top = y + 'px';
}});
</script>
</body></html>
"""

if __name__ == "__main__":
    main()
