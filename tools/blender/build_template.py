"""Copy into art/creatures/<ConfigId>/ and replace the sample anatomy."""

import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
KIT = HERE if (HERE / "export_creature.py").is_file() else HERE.parents[2] / "tools" / "blender"
sys.path.insert(0, str(KIT))

from creature_mesh import Piece
from export_creature import build_cli

CREATURE_ID = "C123_Template"
PALETTE = {
    "skin": ("124263/1A9EAA/86DDCD", "scale"),
    "belly": ("AD5D56/F4C5A5", "armor"),
}


def build():
    body, head, tail = (Piece(name) for name in ("Body", "Head", "Tail"))
    body.oval((0,0,0), (0.63,0.86,0.63), "skin")
    head.oval((0,-0.75,0.16), (0.46,0.45,0.43), "belly")
    tail.sweep([((0,0.54,0),0.28,0.31),((0,0.91,0),0.19,0.23),((0,1.34,0.16),0.05,0.09)], "skin")
    return body, head, tail


if __name__ == "__main__":
    build_cli(__file__, CREATURE_ID, "Epic", build, PALETTE)
