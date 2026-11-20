"""Crystal Guardian (C09): ancient sea turtle with a sapphire-crystal carapace crown."""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "tools" / "blender"))
from creature_mesh import Piece
from export_creature import build_cli

ID = "C09_Guardiao_Cristal"
PALETTE = {
    "skin": ("10305A/1E639B/57B8D9", "scale"),
    "belly": ("9C6B43/E2B679/FFF1C9", "armor"),
    "shell": ("0E2148/1D4887/3B87C4", "armor"),
    "rim": ("8C5A32/E6AD55/FFE999", "plain"),
    "crystal": ("2299E6/6EEBFF/E6FFFF", "vein"),
    "prism": ("5949C9/A384FF/F2D6FF", "vein"),
    "dark": ("091126/172647", "plain"),
    "gold": ("B56A2B/FFCC52/FFF6B3", "plain"),
}


def build():
    body, head, shell, fin_l, fin_r, tail, crystals, accents = (
        Piece(name)
        for name in ("Body", "Head", "Shell", "FinL", "FinR", "Tail", "Extra", "Extra.001")
    )

    # Torso and golden plastron (under-armor)
    body.sweep(
        [
            ((0, -0.58, -0.08), 0.42, 0.24),
            ((0, -0.28, -0.10), 0.68, 0.32),
            ((0, 0.08, -0.10), 0.72, 0.34),
            ((0, 0.44, -0.08), 0.56, 0.28),
            ((0, 0.68, -0.05), 0.32, 0.18),
        ],
        "skin",
        sides=14,
    )
    body.oval((0, -0.02, -0.22), (0.62, 0.58, 0.18), "belly", sides=14, levels=6)
    # Hind flippers attached to Body
    for s in (-1, 1):
        body.sweep(
            [
                ((s * 0.44, 0.42, -0.16), 0.16, 0.08),
                ((s * 0.68, 0.64, -0.22), 0.20, 0.07),
                ((s * 0.84, 0.86, -0.26), 0.12, 0.04),
                ((s * 0.88, 0.96, -0.28), 0.03, 0.02),
            ],
            "skin",
            sides=8,
        )

    # Expressive turtle head facing -Y (+Z in Roblox)
    head.sweep(
        [
            ((0, -0.52, -0.02), 0.26, 0.22),
            ((0, -0.76, 0.05), 0.32, 0.27),
            ((0, -1.00, 0.07), 0.30, 0.25),
            ((0, -1.18, 0.03), 0.17, 0.15),
        ],
        "skin",
        sides=12,
    )
    head.oval((0, -0.96, -0.07), (0.23, 0.24, 0.12), "belly", sides=10, levels=5)
    # Guardian brow crest and crystal diadem
    head.gem((0, -0.92, 0.24), (0, -1.04, 0.56), 0.11, "crystal", sides=6)
    for s in (-1, 1):
        head.gem(
            (s * 0.15, -0.88, 0.22),
            (s * 0.28, -0.94, 0.46),
            0.075,
            "prism",
            sides=5,
        )
        # Large readable eyes tilted slightly forward
        head.oval((s * 0.22, -1.02, 0.11), (0.10, 0.09, 0.11), "dark", sides=8, levels=5)
        head.oval((s * 0.23, -1.06, 0.11), (0.075, 0.055, 0.085), "gold", sides=8, levels=4)
        head.oval((s * 0.235, -1.09, 0.11), (0.038, 0.028, 0.055), "dark", sides=6, levels=4)
        accents.gem(
            (s * 0.21, -1.11, 0.14),
            (s * 0.21, -1.14, 0.17),
            0.022,
            "crystal",
            sides=5,
        )
        # Cheek armor plates
        head.gem(
            (s * 0.26, -0.86, 0.02),
            (s * 0.40, -0.78, 0.06),
            0.065,
            "rim",
            sides=5,
        )

    # Domed carapace shell with golden rim
    shell.oval((0, 0.02, 0.14), (0.86, 0.88, 0.44), "shell", sides=16, levels=7)
    shell.sweep(
        [
            ((0, -0.82, 0.02), 0.46, 0.09),
            ((0, -0.44, 0.00), 0.84, 0.10),
            ((0, 0.04, -0.01), 0.92, 0.10),
            ((0, 0.52, 0.00), 0.78, 0.09),
            ((0, 0.86, 0.03), 0.40, 0.08),
        ],
        "rim",
        sides=12,
    )
    for s in (-1, 1):
        for j in range(3):
            y = -0.36 + j * 0.34
            shell.gem(
                (s * 0.76, y, 0.03),
                (s * 0.96, y + 0.06, 0.08),
                0.085,
                "gold",
                sides=5,
            )

    # Front flippers: FinL on +X, FinR on -X
    for s, piece in ((1, fin_l), (-1, fin_r)):
        piece.sweep(
            [
                ((s * 0.56, -0.38, -0.10), 0.18, 0.09),
                ((s * 0.92, -0.48, -0.16), 0.26, 0.08),
                ((s * 1.28, -0.36, -0.22), 0.21, 0.06),
                ((s * 1.48, -0.16, -0.26), 0.08, 0.035),
                ((s * 1.56, -0.04, -0.27), 0.02, 0.015),
            ],
            "skin",
            sides=9,
            reference=(0, 0, 1),
        )
        for j in range(2):
            piece.gem(
                (s * (0.86 + j * 0.28), -0.52 + j * 0.06, -0.12),
                (s * (0.98 + j * 0.32), -0.66 + j * 0.06, -0.06),
                0.065,
                "crystal",
                sides=5,
            )

    # Tail with crystal finial
    tail.sweep(
        [
            ((0, 0.66, -0.06), 0.20, 0.15),
            ((0, 0.94, -0.04), 0.14, 0.11),
            ((0, 1.18, 0.02), 0.07, 0.06),
            ((0, 1.32, 0.08), 0.02, 0.02),
        ],
        "skin",
        sides=8,
    )
    tail.gem((0, 1.12, 0.04), (0, 1.42, 0.18), 0.095, "crystal", sides=6)

    # Signature dorsal crystal cluster (Extra & Extra.001)
    crystals.gem((0, -0.04, 0.38), (0, -0.08, 1.34), 0.24, "crystal", sides=6)
    crystals.gem((0, -0.34, 0.34), (0, -0.52, 1.02), 0.17, "prism", sides=6)
    crystals.gem((0, 0.30, 0.34), (0, 0.50, 1.04), 0.18, "prism", sides=6)
    for s in (-1, 1):
        crystals.gem(
            (s * 0.26, -0.16, 0.34),
            (s * 0.54, -0.28, 1.08),
            0.165,
            "crystal",
            sides=6,
        )
        crystals.gem(
            (s * 0.32, 0.18, 0.32),
            (s * 0.64, 0.30, 0.98),
            0.155,
            "prism",
            sides=6,
        )
        accents.gem(
            (s * 0.52, -0.02, 0.24),
            (s * 0.84, 0.02, 0.68),
            0.125,
            "crystal",
            sides=5,
        )
        accents.gem(
            (s * 0.44, -0.42, 0.22),
            (s * 0.68, -0.58, 0.62),
            0.105,
            "gold",
            sides=5,
        )
        accents.gem(
            (s * 0.44, 0.42, 0.22),
            (s * 0.70, 0.58, 0.62),
            0.105,
            "crystal",
            sides=5,
        )

    return body, head, shell, fin_l, fin_r, tail, crystals, accents


if __name__ == "__main__":
    build_cli(__file__, ID, "Epic", build, PALETTE)
