"""Frost King Crab (C55): chunky royal ice crab with raised frosted claws, curved legs and crystal crown."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "tools" / "blender"))
from creature_mesh import Piece
from export_creature import build_cli

ID = "C55_Caranguejo_Rei_Gelo"
PALETTE = {
    "shell": ("185694/46A4EB/B5ECFF", "armor"),
    "belly": ("B3E0F5/E8F8FF/FFFFFF", "plain"),
    "claw": ("2473BD/69C4FF/E6FAFF", "armor"),
    "ice": ("47C4FF/A8EEFF/FFFFFF", "vein"),
    "gold": ("C97A18/FFD24D/FFF5B8", "plain"),
    "eye": ("091126/1B3358", "plain"),
    "shine": ("EBF9FF/FFFFFF", "plain"),
    "cheek": ("FF8AB4/FFC4DC", "plain"),
}


def build():
    body, head, shell, claws, legs, tail, crown = (
        Piece(name) for name in ("Body", "Head", "Shell", "Claws", "Legs", "Tail", "Extra")
    )

    # Smooth rounded underbody
    body.oval((0, 0.08, -0.05), (0.64, 0.52, 0.29), "belly", sides=14, levels=7)

    # Expressive front-facing Head at -Y (+Z in Roblox) with big glossy eyes & cute smile
    head.oval((0, -0.35, 0.04), (0.43, 0.25, 0.24), "shell", sides=12, levels=5)
    for s in (-1, 1):
        head.oval((s * 0.18, -0.53, 0.14), (0.095, 0.09, 0.105), "eye", sides=8, levels=4)
        head.oval((s * 0.16, -0.61, 0.18), (0.04, 0.03, 0.04), "shine", sides=5, levels=3)
        head.oval((s * 0.27, -0.48, 0.02), (0.075, 0.045, 0.045), "cheek", sides=5, levels=3)
    # Cute little smile line
    head.oval((0, -0.57, -0.02), (0.11, 0.04, 0.03), "eye", sides=6, levels=3)

    # Smooth glacial carapace with layered rim
    shell.sweep(
        [
            ((0, -0.34, 0.12), 0.52, 0.16),
            ((0, -0.08, 0.19), 0.74, 0.22),
            ((0, 0.20, 0.18), 0.72, 0.21),
            ((0, 0.44, 0.13), 0.56, 0.16),
            ((0, 0.62, 0.07), 0.28, 0.10),
        ],
        "shell",
        sides=14,
    )

    # Big raised king-crab pincers framing the face (hero silhouette!)
    for s in (-1, 1):
        # Arm + big upper claw
        claws.sweep(
            [
                ((s * 0.52, -0.14, -0.02), 0.10, 0.085),
                ((s * 0.80, -0.26, 0.14), 0.12, 0.10),
                ((s * 0.88, -0.44, 0.40), 0.17, 0.14),
                ((s * 0.76, -0.58, 0.64), 0.18, 0.14),
                ((s * 0.58, -0.64, 0.74), 0.06, 0.05),
            ],
            "claw",
            sides=10,
        )
        # Inner icy pincer thumb
        claws.sweep(
            [
                ((s * 0.76, -0.48, 0.42), 0.09, 0.075),
                ((s * 0.62, -0.58, 0.56), 0.07, 0.06),
                ((s * 0.54, -0.62, 0.66), 0.03, 0.025),
            ],
            "ice",
            sides=8,
        )

    # 3 pairs of naturally curved segmented crab legs
    for s in (-1, 1):
        for idx, y_off in enumerate((-0.06, 0.16, 0.36)):
            sweep_y = y_off + idx * 0.09
            legs.sweep(
                [
                    ((s * 0.56, y_off, -0.08), 0.075, 0.065),
                    ((s * 0.86, sweep_y, 0.04), 0.07, 0.06),
                    ((s * 1.04, sweep_y + 0.05, -0.14), 0.055, 0.05),
                    ((s * 1.06, sweep_y + 0.08, -0.38), 0.025, 0.025),
                ],
                "claw",
                sides=6,
            )

    # Tucked rear crab abdomen flap (Tail at +Y so Head.Z - Tail.Z > 0)
    tail.sweep(
        [
            ((0, 0.50, 0.00), 0.24, 0.08),
            ((0, 0.68, -0.05), 0.18, 0.06),
            ((0, 0.78, -0.10), 0.10, 0.04),
        ],
        "belly",
        sides=8,
    )

    # Signature: 3-point royal ice-crystal crown with golden base ring
    crown.sweep(
        [
            ((0, -0.05, 0.34), 0.30, 0.05),
            ((0, -0.05, 0.40), 0.32, 0.05),
        ],
        "gold",
        sides=12,
    )
    crown.gem((0, -0.05, 0.38), (0, -0.08, 0.76), 0.12, "ice", sides=6)
    for s in (-1, 1):
        crown.gem((s * 0.18, -0.03, 0.37), (s * 0.27, -0.06, 0.64), 0.085, "ice", sides=5)

    return [body, head, shell, claws, legs, tail, crown]


if __name__ == "__main__":
    build_cli(__file__, ID, "Rare", build, PALETTE, atlas_size=512)
