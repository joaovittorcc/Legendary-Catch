"""Starry Whale Shark (C50): plush cartoony whale shark with smooth rounded body, curved fins and constellation glow."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "tools" / "blender"))
from creature_mesh import Piece
from export_creature import build_cli

ID = "C50_Tubarao_Baleia_Estrelado"
PALETTE = {
    "back": ("1E1863/4436BA/7E6EFF", "star"),
    "belly": ("CFE0FF/EDF4FF/FFFFFF", "plain"),
    "fin": ("2B2282/594AD4/988EFF", "star"),
    "eye": ("090C1C/1B2654", "plain"),
    "shine": ("EBF7FF/FFFFFF", "plain"),
    "mouth": ("661A48/B8377A/FF85B8", "plain"),
    "gold": ("D48315/FFD652/FFF8C4", "plain"),
    "cheek": ("FF8FB8/FFC7DD", "plain"),
}


def build():
    body, head, fin_l, fin_r, fins, tail = (
        Piece(name) for name in ("Body", "Head", "FinL", "FinR", "Fins", "Tail")
    )

    # Smooth chubby whale-shark torso (16 sides, 6 stations)
    body.sweep(
        [
            ((0, -0.34, -0.02), 0.56, 0.37),
            ((0, -0.04, 0.01), 0.63, 0.42),
            ((0, 0.28, 0.02), 0.54, 0.36),
            ((0, 0.60, 0.03), 0.37, 0.26),
            ((0, 0.88, 0.04), 0.20, 0.16),
            ((0, 1.08, 0.05), 0.10, 0.10),
        ],
        "back",
        sides=14,
    )
    body.oval((0, 0.06, -0.17), (0.53, 0.58, 0.24), "belly", sides=12, levels=5)

    # Smooth wide whale-shark head facing -Y (+Z in Roblox)
    head.sweep(
        [
            ((0, -0.30, 0.00), 0.55, 0.36),
            ((0, -0.58, 0.00), 0.60, 0.36),
            ((0, -0.86, -0.02), 0.54, 0.30),
            ((0, -1.06, -0.04), 0.40, 0.20),
            ((0, -1.16, -0.06), 0.20, 0.10),
        ],
        "back",
        sides=12,
    )
    head.oval((0, -0.70, -0.16), (0.50, 0.38, 0.18), "belly", sides=10, levels=4)
    # Expressive wide smiling mouth + pink cheeks
    head.oval((0, -1.01, -0.10), (0.30, 0.11, 0.065), "mouth", sides=8, levels=3)
    for s in (-1, 1):
        # Cute glossy eyes set forward so they read clearly in +Z reveal
        head.oval((s * 0.31, -0.88, 0.13), (0.11, 0.10, 0.11), "eye", sides=8, levels=4)
        head.oval((s * 0.29, -0.96, 0.17), (0.042, 0.032, 0.042), "shine", sides=5, levels=3)
        head.oval((s * 0.37, -0.82, 0.00), (0.075, 0.055, 0.045), "cheek", sides=5, levels=3)
    # Subtle golden constellation star emblem on forehead
    head.gem((0, -0.76, 0.31), (0, -0.78, 0.41), 0.075, "gold", sides=5)

    # Broad curved pectoral fins (FinL on +X)
    for fin, s in ((fin_l, 1), (fin_r, -1)):
        fin.sweep(
            [
                ((s * 0.48, -0.20, -0.06), 0.16, 0.06),
                ((s * 0.78, -0.08, -0.11), 0.22, 0.055),
                ((s * 1.06, 0.10, -0.16), 0.16, 0.04),
                ((s * 1.26, 0.30, -0.20), 0.07, 0.02),
                ((s * 1.32, 0.38, -0.22), 0.02, 0.012),
            ],
            "fin",
            sides=10,
        )

    # Curved dorsal fin + small rear dorsal
    fins.sweep(
        [
            ((0, -0.02, 0.35), 0.055, 0.18),
            ((0, 0.14, 0.56), 0.045, 0.16),
            ((0, 0.28, 0.76), 0.025, 0.09),
            ((0, 0.36, 0.84), 0.012, 0.03),
        ],
        "fin",
        sides=10,
    )
    fins.sweep(
        [
            ((0, 0.58, 0.23), 0.03, 0.08),
            ((0, 0.68, 0.36), 0.015, 0.04),
        ],
        "fin",
        sides=8,
    )

    # Swept crescent whale-shark tail
    tail.sweep(
        [
            ((0, 1.00, 0.05), 0.065, 0.15),
            ((0, 1.22, 0.28), 0.05, 0.16),
            ((0, 1.44, 0.54), 0.03, 0.09),
            ((0, 1.54, 0.64), 0.012, 0.03),
        ],
        "fin",
        sides=10,
    )
    tail.sweep(
        [
            ((0, 1.00, 0.01), 0.06, 0.12),
            ((0, 1.20, -0.16), 0.045, 0.13),
            ((0, 1.40, -0.34), 0.02, 0.06),
        ],
        "fin",
        sides=10,
    )

    return [body, head, fin_l, fin_r, fins, tail]


if __name__ == "__main__":
    build_cli(__file__, ID, "Rare", build, PALETTE, atlas_size=512)
