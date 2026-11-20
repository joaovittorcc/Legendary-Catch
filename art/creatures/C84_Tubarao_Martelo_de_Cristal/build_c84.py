"""Crystal Hammerhead (C84): hydrodynamic shark with a diamond-faceted hammerhead and crystal fins."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "tools" / "blender"))
from creature_mesh import Piece
from export_creature import build_cli

ID = "C84_Tubarao_Martelo_de_Cristal"
PALETTE = {
    "skin": ("132A5E/2357A6/55A8E8", "scale"),
    "belly": ("A8B8E8/E1EEFF/FFFFFF", "plain"),
    "crystal": ("27A8F2/7AF2FF/F0FFFF", "vein"),
    "rose": ("A82E8B/F266C9/FFD4F4", "vein"),
    "armor": ("1B3B7A/3B78C4/82C8FA", "armor"),
    "gold": ("AD652B/FCC858/FFF6B8", "plain"),
    "dark": ("0A1026/1A2447", "plain"),
}


def build():
    body, head, fin_l, fin_r, fins, tail, crystals, accents = (
        Piece(name)
        for name in ("Body", "Head", "FinL", "FinR", "Fins", "Tail", "Extra", "Extra.001")
    )

    # Streamlined shark torso along Y (face toward -Y)
    body.sweep(
        [
            ((0, -0.68, 0.02), 0.34, 0.32),
            ((0, -0.32, 0.04), 0.48, 0.44),
            ((0, 0.08, 0.04), 0.44, 0.40),
            ((0, 0.48, 0.02), 0.30, 0.28),
            ((0, 0.84, 0.00), 0.16, 0.16),
        ],
        "skin",
        sides=14,
    )
    body.oval((0, -0.14, -0.14), (0.38, 0.56, 0.22), "belly", sides=12, levels=6)

    # Diamond-faceted Hammerhead (Head) facing -Y (+Z in Roblox)
    head.sweep(
        [
            ((0, -0.58, 0.03), 0.34, 0.28),
            ((0, -0.86, 0.04), 0.40, 0.26),
            ((0, -1.12, 0.03), 0.32, 0.18),
            ((0, -1.26, 0.02), 0.18, 0.10),
        ],
        "skin",
        sides=12,
    )
    head.oval((0, -0.92, -0.09), (0.28, 0.24, 0.12), "belly", sides=10, levels=5)
    # Central forehead diamond horn
    head.gem((0, -1.04, 0.14), (0, -1.34, 0.34), 0.11, "crystal", sides=6)

    # Left & Right hammerhead wings + faceted crystal tips + expressive front-readable eyes
    for s in (-1, 1):
        head.sweep(
            [
                ((s * 0.24, -0.96, 0.04), 0.20, 0.15),
                ((s * 0.64, -1.00, 0.06), 0.19, 0.14),
                ((s * 0.96, -0.96, 0.08), 0.16, 0.12),
            ],
            "armor",
            sides=8,
            reference=(0, 1, 0),
        )
        # Giant diamond hammer tips
        head.gem(
            (s * 0.78, -0.98, 0.07),
            (s * 1.28, -0.94, 0.12),
            0.20,
            "rose",
            sides=6,
        )
        head.gem(
            (s * 0.88, -1.08, 0.08),
            (s * 1.18, -1.24, 0.14),
            0.11,
            "crystal",
            sides=6,
        )
        # Front-facing expressive eyes on the front edge of the hammerhead
        head.oval((s * 0.48, -1.13, 0.06), (0.095, 0.075, 0.095), "dark", sides=8, levels=5)
        head.oval((s * 0.48, -1.16, 0.06), (0.072, 0.05, 0.075), "gold", sides=8, levels=4)
        head.oval((s * 0.48, -1.185, 0.06), (0.036, 0.025, 0.046), "dark", sides=6, levels=4)
        accents.gem(
            (s * 0.45, -1.20, 0.09),
            (s * 0.45, -1.23, 0.12),
            0.02,
            "crystal",
            sides=5,
        )

    # Pectoral fins: FinL on +X, FinR on -X
    for s, piece in ((1, fin_l), (-1, fin_r)):
        piece.sweep(
            [
                ((s * 0.38, -0.26, -0.12), 0.18, 0.07),
                ((s * 0.74, -0.18, -0.20), 0.22, 0.06),
                ((s * 1.08, 0.02, -0.28), 0.14, 0.045),
                ((s * 1.28, 0.20, -0.32), 0.03, 0.02),
            ],
            "armor",
            sides=8,
            reference=(0, 0, 1),
        )
        piece.gem(
            (s * 0.68, -0.22, -0.14),
            (s * 1.06, -0.06, -0.10),
            0.085,
            "crystal",
            sides=5,
        )

    # Tall crystal-blade dorsal fin (Fins)
    fins.sweep(
        [
            ((0, -0.18, 0.36), 0.11, 0.24),
            ((0, -0.02, 0.74), 0.085, 0.20),
            ((0, 0.18, 1.08), 0.045, 0.11),
            ((0, 0.32, 1.26), 0.015, 0.03),
        ],
        "crystal",
        sides=8,
    )
    fins.gem((0, -0.22, 0.38), (0, -0.10, 1.12), 0.14, "rose", sides=6)

    # Crescent shark tail with crystal blades (Tail)
    tail.sweep(
        [
            ((0, 0.80, 0.00), 0.16, 0.16),
            ((0, 1.08, 0.02), 0.11, 0.14),
            ((0, 1.38, 0.34), 0.06, 0.14),
            ((0, 1.58, 0.64), 0.02, 0.04),
        ],
        "skin",
        sides=8,
    )
    tail.sweep(
        [
            ((0, 1.08, -0.02), 0.09, 0.11),
            ((0, 1.32, -0.28), 0.05, 0.10),
            ((0, 1.48, -0.48), 0.02, 0.03),
        ],
        "armor",
        sides=7,
    )
    tail.gem((0, 1.24, 0.18), (0, 1.64, 0.68), 0.11, "crystal", sides=6)

    # Dorsal & flank crystal clusters (Extra & Extra.001)
    for j in range(3):
        y = 0.26 + j * 0.22
        crystals.gem(
            (0, y, 0.28 - j * 0.05),
            (0, y + 0.14, 0.66 - j * 0.08),
            0.10 - j * 0.015,
            "rose" if j % 2 == 0 else "crystal",
            sides=6,
        )
    for s in (-1, 1):
        for j in range(3):
            y = -0.34 + j * 0.28
            crystals.gem(
                (s * 0.36, y, 0.16),
                (s * 0.62, y + 0.10, 0.44),
                0.095 - j * 0.01,
                "crystal" if j % 2 == 0 else "rose",
                sides=5,
            )

    return body, head, fin_l, fin_r, fins, tail, crystals, accents


if __name__ == "__main__":
    build_cli(__file__, ID, "Epic", build, PALETTE)
