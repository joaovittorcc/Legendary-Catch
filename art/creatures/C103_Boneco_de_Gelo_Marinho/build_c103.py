"""Sea Snowman (C103): plush rounded snowman facing -Y (+Z in Roblox) with carrot nose, top hat and fish tail."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "tools" / "blender"))
from creature_mesh import Piece
from export_creature import build_cli

ID = "C103_Boneco_de_Gelo_Marinho"
PALETTE = {
    "snow": ("C2EBFF/EEFAFF/FFFFFF", "plain"),
    "ice": ("2FA4E7/73D7FF/D9F7FF", "vein"),
    "hat": ("1A237E/3949AB/7986CB", "armor"),
    "gold": ("C97A18/FFD24D/FFF5B8", "plain"),
    "scarf": ("D92B4B/FF5C77/36C9A5", "armor"),
    "carrot": ("D95B16/FF8A2B/FFC46B", "plain"),
    "eye": ("091126/1B3358", "plain"),
    "shine": ("EBF9FF/FFFFFF", "plain"),
    "cheek": ("FF8AB4/FFC2D9", "plain"),
}


def build():
    body, head, fin_l, fin_r, tail, scarf = (
        Piece(name) for name in ("Body", "Head", "FinL", "FinR", "Tail", "Extra")
    )

    # Plush smooth lower snow-foam body + icy buttons + scarf collar
    body.oval((0, 0.00, -0.22), (0.52, 0.49, 0.45), "snow", sides=14, levels=7)
    # Cute icy buttons on belly facing -Y (+Z)
    for bz, by in ((0.00, -0.45), (-0.18, -0.48)):
        body.oval((0, by, bz), (0.055, 0.035, 0.055), "ice", sides=6, levels=3)
    # Plush scarf collar
    body.sweep(
        [
            ((0, -0.04, 0.13), 0.39, 0.095),
            ((0, 0.00, 0.18), 0.41, 0.095),
            ((0, 0.04, 0.23), 0.37, 0.085),
        ],
        "scarf",
        sides=12,
    )

    # Plush snowman head facing -Y (+Z in Roblox)
    head.oval((0, -0.05, 0.47), (0.39, 0.37, 0.35), "snow", sides=10, levels=5)
    # Carrot nose pointing straight toward -Y (+Z in Roblox)
    head.sweep(
        [
            ((0, -0.38, 0.46), 0.075, 0.075),
            ((0, -0.54, 0.46), 0.048, 0.048),
            ((0, -0.69, 0.45), 0.015, 0.015),
        ],
        "carrot",
        sides=7,
    )
    # Cheerful glossy eyes + highlights + rosy cheeks + dotted smile
    for s in (-1, 1):
        head.oval((s * 0.14, -0.37, 0.56), (0.068, 0.055, 0.075), "eye", sides=6, levels=4)
        head.oval((s * 0.125, -0.42, 0.59), (0.026, 0.02, 0.026), "shine", sides=5, levels=3)
        head.oval((s * 0.22, -0.34, 0.42), (0.072, 0.042, 0.048), "cheek", sides=5, levels=3)
    # Cheerful pebble smile
    for sx, sz in ((-0.08, 0.35), (0.0, 0.33), (0.08, 0.35)):
        head.oval((sx, -0.39, sz), (0.026, 0.022, 0.026), "eye", sides=4, levels=3)

    # Festive top hat
    head.sweep(
        [
            ((0, -0.04, 0.74), 0.38, 0.04),
            ((0, -0.04, 0.79), 0.38, 0.04),
        ],
        "hat",
        sides=10,
    )
    head.sweep(
        [
            ((0, -0.04, 0.78), 0.25, 0.04),
            ((0, -0.04, 0.86), 0.25, 0.04),
        ],
        "gold",
        sides=10,
    )
    head.sweep(
        [
            ((0, -0.04, 0.85), 0.25, 0.06),
            ((0, -0.04, 1.09), 0.29, 0.06),
        ],
        "hat",
        sides=10,
    )

    # Cute curved icy flipper arms angled warmly forward/down (FinL on +X)
    for fin, s in ((fin_l, 1), (fin_r, -1)):
        fin.sweep(
            [
                ((s * 0.44, -0.04, -0.04), 0.10, 0.08),
                ((s * 0.64, -0.16, -0.14), 0.12, 0.075),
                ((s * 0.76, -0.24, -0.24), 0.08, 0.045),
                ((s * 0.80, -0.27, -0.28), 0.03, 0.02),
            ],
            "ice",
            sides=10,
        )

    # Broad curved icy fish tail at +Y (-Z in Roblox) so Head.Z - Tail.Z > 0
    tail.sweep(
        [
            ((0, 0.42, -0.24), 0.075, 0.14),
            ((0, 0.66, -0.08), 0.055, 0.16),
            ((0, 0.86, 0.10), 0.025, 0.08),
        ],
        "ice",
        sides=10,
    )
    tail.sweep(
        [
            ((0, 0.42, -0.28), 0.075, 0.13),
            ((0, 0.64, -0.38), 0.055, 0.15),
            ((0, 0.84, -0.52), 0.025, 0.07),
        ],
        "ice",
        sides=10,
    )

    # Fluttering festive scarf tail
    scarf.sweep(
        [
            ((0.28, -0.16, 0.15), 0.08, 0.045),
            ((0.44, -0.26, 0.02), 0.095, 0.04),
            ((0.54, -0.24, -0.14), 0.065, 0.03),
        ],
        "scarf",
        sides=8,
    )

    return [body, head, fin_l, fin_r, tail, scarf]


if __name__ == "__main__":
    build_cli(__file__, ID, "Rare", build, PALETTE, atlas_size=512)
