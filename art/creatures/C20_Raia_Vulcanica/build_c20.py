"""Volcanic Ray (C20): basalt manta glider with magma veins, horn lobes and an ember-spear tail."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "tools" / "blender"))
from creature_mesh import Piece
from export_creature import build_cli

ID = "C20_Raia_Vulcanica"
PALETTE = {
    "basalt": ("16111F/2D2036/593854", "armor"),
    "wing": ("1E142B/4A223B/9E373B", "vein"),
    "belly": ("471D2B/9C3B38/F28852", "scale"),
    "magma": ("C4301C/FF6E26/FFD866", "vein"),
    "ember": ("E0431F/FF9B38/FFF2A6", "plain"),
    "gold": ("9E5224/F5B342/FFF0A8", "plain"),
    "dark": ("0B0812/1C1326", "plain"),
}


def build():
    body, head, wings, tail, dorsal_core, vents = (
        Piece(name)
        for name in ("Body", "Head", "Wings", "Tail", "Extra", "Extra.001")
    )

    # Central torso and glowing magma belly
    body.sweep(
        [
            ((0, -0.58, 0.00), 0.34, 0.16),
            ((0, -0.26, 0.02), 0.56, 0.23),
            ((0, 0.10, 0.03), 0.52, 0.22),
            ((0, 0.46, 0.02), 0.34, 0.16),
            ((0, 0.74, 0.00), 0.16, 0.10),
        ],
        "basalt",
        sides=14,
    )
    body.oval((0, -0.06, -0.10), (0.46, 0.52, 0.12), "belly", sides=12, levels=5)
    for s in (-1, 1):
        for j in range(3):
            y = -0.24 + j * 0.18
            vents.gem(
                (s * 0.30, y, -0.15),
                (s * 0.42, y + 0.04, -0.22),
                0.045,
                "magma",
                sides=5,
            )

    # Expressive manta head facing -Y (+Z in Roblox) with cephalic horn-lobes and bright eyes
    head.sweep(
        [
            ((0, -0.48, 0.02), 0.34, 0.17),
            ((0, -0.74, 0.04), 0.42, 0.21),
            ((0, -0.96, 0.03), 0.32, 0.16),
            ((0, -1.10, 0.01), 0.16, 0.09),
        ],
        "basalt",
        sides=12,
    )
    head.oval((0, -0.88, -0.05), (0.28, 0.22, 0.09), "belly", sides=10, levels=5)
    head.gem((0, -0.82, 0.18), (0, -0.96, 0.44), 0.095, "magma", sides=6)

    for s in (-1, 1):
        # Cephalic magma horn-lobes curving forward outside the eyes
        head.sweep(
            [
                ((s * 0.36, -0.76, 0.03), 0.095, 0.07),
                ((s * 0.48, -0.98, 0.06), 0.085, 0.06),
                ((s * 0.54, -1.18, 0.12), 0.055, 0.045),
                ((s * 0.50, -1.32, 0.18), 0.02, 0.02),
            ],
            "magma",
            sides=7,
            reference=(0, 0, 1),
        )
        # Brow ridge and large glowing front-facing eyes
        head.gem(
            (s * 0.18, -0.78, 0.15),
            (s * 0.34, -0.70, 0.36),
            0.07,
            "gold",
            sides=5,
        )
        head.oval((s * 0.20, -1.00, 0.08), (0.095, 0.08, 0.095), "dark", sides=8, levels=5)
        head.oval((s * 0.205, -1.04, 0.08), (0.072, 0.055, 0.075), "ember", sides=8, levels=4)
        head.oval((s * 0.21, -1.07, 0.08), (0.036, 0.025, 0.048), "dark", sides=6, levels=4)
        vents.gem(
            (s * 0.185, -1.085, 0.105),
            (s * 0.185, -1.115, 0.135),
            0.02,
            "gold",
            sides=5,
        )

    # Broad sweeping volcanic wings with magma veins and ember wingtip spikes
    for s in (-1, 1):
        wings.sweep(
            [
                ((s * 0.38, -0.10, 0.02), 0.46, 0.13),
                ((s * 0.86, -0.14, 0.06), 0.44, 0.11),
                ((s * 1.36, -0.02, 0.14), 0.32, 0.08),
                ((s * 1.78, 0.18, 0.24), 0.16, 0.045),
                ((s * 2.02, 0.36, 0.32), 0.03, 0.02),
            ],
            "wing",
            sides=10,
            reference=(0, 1, 0),
        )
        # Glowing magma ridges along the wing span
        for j in range(3):
            wx = s * (0.66 + j * 0.38)
            wy = -0.22 + j * 0.10
            wz = 0.08 + j * 0.06
            wings.gem(
                (wx, wy, wz),
                (wx + s * 0.20, wy - 0.16, wz + 0.12),
                0.085 - j * 0.015,
                "magma",
                sides=5,
            )
            vents.gem(
                (wx, wy + 0.26, wz + 0.02),
                (wx + s * 0.14, wy + 0.42, wz + 0.16),
                0.075 - j * 0.012,
                "ember",
                sides=5,
            )

    # Dorsal volcanic crown and lava core (Extra)
    for j in range(4):
        y = -0.34 + j * 0.26
        h = 0.46 - abs(j - 1.2) * 0.08
        dorsal_core.gem(
            (0, y, 0.14),
            (0, y + 0.12, 0.14 + h),
            0.13 - j * 0.015,
            "magma" if j % 2 == 0 else "ember",
            sides=6,
        )
    for s in (-1, 1):
        dorsal_core.gem(
            (s * 0.24, -0.06, 0.14),
            (s * 0.46, 0.04, 0.48),
            0.11,
            "gold",
            sides=6,
        )

    # Whip tail ending in a diamond magma spear
    tail.sweep(
        [
            ((0, 0.68, 0.00), 0.15, 0.11),
            ((0, 1.06, 0.04), 0.11, 0.08),
            ((0, 1.46, 0.12), 0.075, 0.06),
            ((0, 1.84, 0.22), 0.045, 0.04),
            ((0, 2.12, 0.30), 0.02, 0.02),
        ],
        "basalt",
        sides=8,
    )
    tail.gem((0, 1.78, 0.20), (0, 2.28, 0.36), 0.14, "magma", sides=6)
    for s in (-1, 1):
        tail.gem(
            (s * 0.06, 1.84, 0.22),
            (s * 0.28, 2.08, 0.32),
            0.075,
            "gold",
            sides=5,
        )

    return body, head, wings, tail, dorsal_core, vents


if __name__ == "__main__":
    build_cli(__file__, ID, "Epic", build, PALETTE)
