# nextpnr --post-route script: write every bel (chip site) and the cell placed
# on it as JSON. The output file is taken from $PNR_DUMP (default: pnr_dump.json).
#
# Used by `make floorplan`, see tools/floorplan.py.

import json
import os

bels = []
for bel in ctx.getBels():
    loc = ctx.getBelLocation(bel)
    cell = ctx.getBoundBelCell(bel)
    bels.append({
        "type": str(ctx.getBelType(bel)),
        "x": loc.x,
        "y": loc.y,
        "z": loc.z,
        "cell": None if cell is None else str(cell.name),
    })

with open(os.environ.get("PNR_DUMP", "pnr_dump.json"), "w") as f:
    json.dump({"bels": bels}, f)
