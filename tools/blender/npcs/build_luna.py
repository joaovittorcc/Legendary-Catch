"""Build high-craft stylized 3D model of Luna (NPC_ShellGirl) for Legendary Catch.

Matches C:\\Users\\Evojota\\Downloads\\NPCs Legendary Cat\\Luna\\upgrade-variants.png (right),
hero.png and all four distinct shell designs (scallop, spiral, conch, nautilus) with
millimetric fidelity.

Objects in exported GLB:
  - Legs            : static grounded bare feet (5 cartoon toes), rolled-cuff sea-blue pants
  - Torso           : breathing/swaying lilac tee, butter-yellow vest with turquoise piping & pockets,
                      arms, raised pink scallop shell, held shallow wooden basket of pastel shells
  - Head            : look-at chibi head, big bright eyes with lashes, blush, sweet smile,
                      fluffy deep-plum curly hair & bangs, woven straw hat with pink band & shell clasp
  - Props           : subtle sandy beach patch, sleeping coral starfish, and all 4 sculpted seashells
                      (pink scallop, lilac spiral, turquoise conch, golden nautilus)
  - Glow_Pink_Basket: soft glowing pink core inside Luna's shell basket (follows Torso)
"""

import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

from npc_lib import (
    PartBuilder,
    build_atlas,
    build_solid_material,
    export_glb,
    ground_and_scale,
    render_review_views,
    report_stats,
    reset_scene,
)

PALETTE = {
    "skin": ("#F8CBAE", "skin"),
    "blush": ("#FF889C", "solid"),
    "eye_dark": ("#24161A", "solid"),
    "eye_white": ("#FFFFFF", "solid"),
    "smile_dark": ("#7A3936", "solid"),
    "hair_plum": ("#42264E", "hair"),
    "hair_deep": ("#331C3E", "hair"),
    "hat_straw": ("#F4C878", "straw"),
    "hat_pink": ("#FF7CC4", "fabric"),
    "tee_lilac": ("#D6B4FF", "knit"),
    "vest_yellow": ("#FFD984", "fabric"),
    "trim_aqua": ("#6ED6D6", "fabric"),
    "pants_blue": ("#5494C8", "denim"),
    "pants_cuff": ("#68A8DC", "denim"),
    "basket_wood": ("#C28246", "wood"),
    "basket_rim": ("#A86A34", "wood"),
    "gold": ("#FFD052", "metal"),
    "shell_pink": ("#FF9AC4", "scallop"),
    "shell_cream": ("#FFF0D8", "solid"),
    "shell_lilac": ("#D4A4FF", "solid"),
    "shell_lilac_in": ("#FFBCD6", "solid"),
    "shell_aqua": ("#72E4F0", "solid"),
    "shell_gold": ("#FFE082", "nautilus"),
    "starfish_coral": ("#FF806C", "starfish"),
    "sand": ("#F2C98A", "sand"),
    "pebble": ("#C8B4AE", "solid"),
    "glow_pink": ("#FF9AD8", "neon"),
}


def build_luna(out_dir: Path, render: bool = True):
    reset_scene()
    atlas_mat, uv = build_atlas(out_dir / "luna_atlas.png", PALETTE, size=1024)
    mat_glow_pink = build_solid_material("Glow_Pink_Basket", "#FF9AD8", roughness=0.18, emission=2.4)

    torso_pivot = (0.0, 0.0, 2.38)
    head_pivot = (0.0, 0.0, 3.45)

    legs = PartBuilder("Legs", origin=(0.0, 0.0, 0.0))
    torso = PartBuilder("Torso", origin=torso_pivot)
    head = PartBuilder("Head", origin=head_pivot)
    props = PartBuilder("Props", origin=(0.0, 0.0, 0.0))
    glow_basket = PartBuilder("Glow_Pink_Basket", origin=torso_pivot)

    # =========================================================================
    # 1. GROUNDED BARE FEET (5 TOES!) & ROLLED-CUFF SEA-BLUE PANTS (Z = 0.08 -> 1.65)
    # =========================================================================
    # Subtle soft sandy mound patch underneath feet & shells (Z = 0 -> 0.10)
    sand_prof = [
        (0.02, 0.00),
        (1.65, 0.00),
        (1.75, 0.03),
        (1.72, 0.08),
        (1.45, 0.11),
        (0.80, 0.115),
        (0.02, 0.115),
    ]
    props.lathe((0.08, -0.08, 0.0), sand_prof, "sand", uv, segs=32, scale_xy=(1.12, 0.92))

    foot_z = 0.11
    for side in (-1, 1):
        fx = side * 0.37
        yaw = -side * 7.0
        # Soft cartoon bare foot sole + arch + ankle
        legs.sphere((fx, -0.10, foot_z + 0.10), (0.24, 0.42, 0.12), "skin", uv, rot=(0, 0, yaw))
        legs.cylinder((fx, 0.05, foot_z + 0.28), 0.20, 0.21, 0.34, "skin", uv, segs=16, bevel=0.03)
        # 5 cute little cartoon toes along front of foot (big toe on inner side!)
        for t_i in range(5):
            # t_i = 0 is inner big toe, 4 is outer pinky toe
            toe_frac = (t_i - 2.0) / 2.0
            tx = fx + side * (-0.16 + t_i * 0.082)
            ty = -0.49 + abs(t_i - 0.8) * 0.028
            tr = 0.068 if t_i == 0 else (0.054 - t_i * 0.005)
            legs.sphere((tx, ty, foot_z + 0.075), (tr, tr * 1.15, tr * 0.92), "skin", uv, u_segs=10, v_segs=8)

        # Rolled blue trouser cuffs right above ankles!
        legs.cylinder((fx, 0.0, foot_z + 0.56), 0.34, 0.33, 0.28, "pants_cuff", uv, segs=18, bevel=0.055)
        legs.torus((fx, 0.0, foot_z + 0.69), 0.31, 0.035, "pants_blue", uv, major_segs=18, minor_segs=6)
        # Sea-blue trouser legs going up to hips
        legs.cylinder((fx * 0.96, 0.0, foot_z + 1.16), 0.31, 0.33, 0.98, "pants_blue", uv, segs=18, bevel=0.05)

    # Hip block uniting pants
    legs.rounded_box((0.0, 0.0, foot_z + 1.54), (1.30, 0.72, 0.38), "pants_blue", uv, bevel=0.10, segments=2)

    # =========================================================================
    # 2. TORSO: LILAC TEE, BUTTER-YELLOW VEST WITH AQUA PIPING & POCKETS, ARMS
    # =========================================================================
    # Lilac t-shirt core
    torso.rounded_box((0.0, 0.0, 2.52), (1.38, 0.84, 1.44), "tee_lilac", uv, bevel=0.16, segments=3, taper_top=0.92)
    # Crew neckline rim
    torso.torus((0.0, -0.02, 3.24), 0.34, 0.06, "tee_lilac", uv, major_segs=20, minor_segs=8)
    # Warm peach neck
    torso.cylinder((0.0, 0.0, 3.38), 0.25, 0.24, 0.28, "skin", uv, bevel=0.03)

    # Butter-yellow open vest (matching upgrade-variants right!)
    # Back panel
    torso.rounded_box((0.0, 0.16, 2.50), (1.46, 0.56, 1.38), "vest_yellow", uv, bevel=0.14, segments=3, taper_top=0.90)
    for side in (-1, 1):
        # Left & right front vest panels leaving central lilac stripe visible
        torso.rounded_box((side * 0.44, -0.10, 2.50), (0.58, 0.72, 1.38), "vest_yellow", uv, bevel=0.11, segments=3, taper_top=0.88)
        # Turquoise piping trim along front vertical edges & hem (signature upgrade-variants right detail!)
        pipe_pts = [
            (side * 0.16, -0.46, 3.16),
            (side * 0.18, -0.48, 2.50),
            (side * 0.18, -0.47, 1.84),
            (side * 0.46, -0.46, 1.82),
            (side * 0.72, -0.26, 1.83),
        ]
        torso.tube(pipe_pts, 0.038, "trim_aqua", uv, segs=8)
        # Turquoise armhole piping
        torso.torus((side * 0.68, -0.02, 2.94), 0.30, 0.034, "trim_aqua", uv, rot=(0, 90, 0), major_segs=18, minor_segs=6)
        # Cute little yellow front pocket with turquoise border trim!
        torso.rounded_box((side * 0.46, -0.48, 2.12), (0.34, 0.10, 0.30), "vest_yellow", uv, bevel=0.035, segments=2)
        p_trim = [
            (side * 0.30, -0.52, 2.26),
            (side * 0.62, -0.52, 2.26),
            (side * 0.62, -0.52, 1.98),
            (side * 0.30, -0.52, 1.98),
            (side * 0.30, -0.52, 2.26),
        ]
        torso.tube(p_trim, 0.024, "trim_aqua", uv, segs=6, closed=False)

    # ARMS & HELD PROPS (matching upgrade-variants right!)
    # --- LEFT ARM (+X): bent upward holding a radiant pink scallop shell! ---
    l_sh = (0.82, 0.0, 2.98)
    l_slv = (1.12, -0.06, 2.66)
    l_elb = (1.24, -0.14, 2.54)
    l_hand = (1.36, -0.44, 3.04)
    # Lilac short t-shirt sleeve
    torso.sphere(l_sh, (0.26, 0.26, 0.26), "tee_lilac", uv)
    torso.capsule(l_sh, l_slv, 0.23, "tee_lilac", uv, r1=0.21)
    torso.torus(l_slv, 0.21, 0.035, "tee_lilac", uv, rot=(0, -45, 0), major_segs=16, minor_segs=6)
    # Peach arm & cute mitten hand raised holding scallop
    torso.capsule(l_slv, l_elb, 0.165, "skin", uv, r1=0.16)
    torso.capsule(l_elb, l_hand, 0.16, "skin", uv, r1=0.15)
    torso.sphere(l_hand, (0.20, 0.19, 0.20), "skin", uv)
    torso.sphere((1.24, -0.56, 3.08), (0.085, 0.08, 0.085), "skin", uv)  # thumb
    # Large sculpted pink scallop shell held proudly in left hand!
    torso.shell_scallop((1.42, -0.50, 3.46), scale=0.66, swatch="shell_pink", uv_cells=uv, rot=(6, -12, -16))

    # --- RIGHT ARM (-X): holding shallow wooden shell basket glowing softly pink! ---
    r_sh = (-0.82, 0.0, 2.98)
    r_slv = (-1.10, -0.08, 2.66)
    r_elb = (-1.22, -0.18, 2.50)
    r_hand = (-1.24, -0.46, 2.26)
    torso.sphere(r_sh, (0.26, 0.26, 0.26), "tee_lilac", uv)
    torso.capsule(r_sh, r_slv, 0.23, "tee_lilac", uv, r1=0.21)
    torso.torus(r_slv, 0.21, 0.035, "tee_lilac", uv, rot=(0, 45, 0), major_segs=16, minor_segs=6)
    torso.capsule(r_slv, r_elb, 0.165, "skin", uv, r1=0.16)
    torso.capsule(r_elb, r_hand, 0.16, "skin", uv, r1=0.15)
    torso.sphere(r_hand, (0.20, 0.19, 0.20), "skin", uv)
    torso.sphere((-1.11, -0.56, 2.28), (0.085, 0.08, 0.085), "skin", uv)

    # SHALLOW WOODEN SHELL BASKET hanging from right hand (X = -1.24, Y = -0.48, Z = 1.44)
    bkx, bky, bkz = -1.24, -0.48, 1.42
    # Shallow bowl-like wooden basket with thickened woven rim & gold studs
    basket_prof = [
        (0.02, -0.22),
        (0.42, -0.22),
        (0.54, -0.10),
        (0.60, 0.16),
        (0.62, 0.24),
        (0.54, 0.24),
        (0.50, 0.06),
        (0.36, -0.10),
        (0.02, -0.10),
    ]
    torso.lathe((bkx, bky, bkz), basket_prof, "basket_wood", uv, segs=24, scale_xy=(1.05, 0.90))
    torso.torus((bkx, bky, bkz + 0.19), 0.60, 0.055, "basket_rim", uv, scale_xyz=(1.05, 0.90, 1.0), major_segs=24, minor_segs=8)
    for k in range(6):
        th = math.tau * k / 6.0
        torso.sphere((bkx + math.cos(th) * 0.64 * 1.05, bky + math.sin(th) * 0.64 * 0.90, bkz + 0.19), (0.04, 0.04, 0.04), "gold", uv, u_segs=8, v_segs=6)
    # Arched wooden basket handle reaching right into Luna's hand!
    h_pts = []
    for i in range(13):
        t = i / 12.0
        ang = math.pi * t
        hx = bkx + math.cos(ang) * 0.60
        hz = bkz + 0.18 + math.sin(ang) * 0.68
        h_pts.append((hx, bky, hz))
    torso.tube(h_pts, 0.058, "basket_rim", uv, segs=10)

    # Pastel shells overflowing inside the basket + soft pink glow core!
    torso.shell_scallop((bkx + 0.02, bky + 0.05, bkz + 0.36), scale=0.44, swatch="shell_pink", uv_cells=uv, rot=(-12, 8, 10))
    torso.shell_nautilus((bkx - 0.24, bky - 0.12, bkz + 0.28), scale=0.38, swatch="shell_aqua", uv_cells=uv, rot=(10, 15, -20))
    torso.shell_spiral((bkx + 0.26, bky - 0.10, bkz + 0.32), scale=0.36, swatch="shell_gold", inner_swatch="shell_cream", uv_cells=uv, rot=(12, -25, 30))
    torso.shell_spiral((bkx - 0.16, bky + 0.14, bkz + 0.34), scale=0.34, swatch="shell_lilac", inner_swatch="shell_lilac_in", uv_cells=uv, rot=(-10, 20, -40))
    # Soft glowing pink pearl/light nested inside the shells!
    glow_basket.sphere((bkx, bky - 0.04, bkz + 0.22), (0.34, 0.26, 0.14), "glow_pink", uv, u_segs=14, v_segs=10)

    # =========================================================================
    # 3. HEAD, BIG BRIGHT EYES, FLUFFY PLUM CURLY HAIR & STRAW HAT WITH SHELL CLASP
    # =========================================================================
    hc = Vector((0.0, 0.0, 3.92))
    # Big adorable chibi round head
    head.sphere(hc, (0.80, 0.74, 0.72), "skin", uv, u_segs=24, v_segs=18)

    # Cute round ears peeking out beneath hair
    for side in (-1, 1):
        head.sphere((side * 0.78, 0.0, 3.84), (0.14, 0.15, 0.18), "skin", uv)

    # Big bright dark eyes with double white catchlights + cute little outer eyelash + tiny brows!
    for side in (-1, 1):
        ex = side * 0.28
        # Main large eye
        head.sphere((ex, -0.68, 3.92), (0.125, 0.085, 0.145), "eye_dark", uv, u_segs=16, v_segs=12)
        # Main top-left white highlight + tiny bottom-right sparkle!
        head.sphere((ex - 0.040, -0.755, 3.98), (0.046, 0.028, 0.048), "eye_white", uv, u_segs=10, v_segs=8)
        head.sphere((ex + 0.042, -0.750, 3.86), (0.020, 0.016, 0.020), "eye_white", uv, u_segs=8, v_segs=6)
        # Cute little curved outer eyelash flick!
        lash_pts = [
            (ex + side * 0.08, -0.70, 4.02),
            (ex + side * 0.15, -0.67, 4.04),
            (ex + side * 0.19, -0.64, 4.07),
        ]
        head.tube(lash_pts, [0.024, 0.022, 0.014], "eye_dark", uv, segs=6)
        # Small sweet curved plum eyebrow
        head.capsule((ex - side * 0.05, -0.68, 4.16), (ex + side * 0.09, -0.65, 4.14), 0.028, "hair_plum", uv)
        # Round warm pink cheek blush
        head.sphere((side * 0.45, -0.62, 3.74), (0.13, 0.06, 0.10), "blush", uv, u_segs=12, v_segs=8)

    # Tiny sweet smile right between cheeks
    head.smile_arc((0.0, -0.73, 3.74), width=0.22, depth_y=0.05, drop_z=0.075, thickness=0.024, swatch="smile_dark", uv_cells=uv)

    # --- FLUFFY DEEP-PLUM HAIR (seamless crown cap + soft merged bangs + big bouncy curls!) ---
    # Crown cap recessed cleanly above brows so delicate forehead & brows show naturally
    head.sphere((0.0, 0.15, 4.18), (0.85, 0.74, 0.68), "hair_plum", uv, u_segs=22, v_segs=16)
    # Soft sculpted bangs framing forehead smoothly without dropping onto the eyes
    head.sphere((-0.30, -0.52, 4.30), (0.36, 0.28, 0.24), "hair_plum", uv, rot=(8, -16, -20))
    head.sphere((0.30, -0.52, 4.30), (0.36, 0.28, 0.24), "hair_plum", uv, rot=(8, 16, 20))
    # Central soft swooping bang tuft dipping playfully between brows
    head.capsule((0.03, -0.58, 4.40), (-0.05, -0.68, 4.16), 0.22, "hair_plum", uv, r1=0.10, segs=12)
    # Two soft side locks framing cheeks neatly
    for side in (-1, 1):
        head.capsule((side * 0.56, -0.44, 4.24), (side * 0.68, -0.34, 3.80), 0.20, "hair_plum", uv, r1=0.13, segs=12)

    # Big signature bouncy curly hair clouds framing the lower back & sides (matching upgrade-variants!)
    curl_puffs = [
        ((-0.78, 0.24, 3.52), (0.36, 0.34, 0.35)),
        ((0.78, 0.24, 3.52), (0.36, 0.34, 0.35)),
        ((-0.62, 0.48, 3.44), (0.34, 0.34, 0.34)),
        ((0.62, 0.48, 3.44), (0.34, 0.34, 0.34)),
        ((-0.34, 0.62, 3.44), (0.34, 0.34, 0.34)),
        ((0.34, 0.62, 3.44), (0.34, 0.34, 0.34)),
        ((0.00, 0.68, 3.46), (0.36, 0.34, 0.34)),
        ((-0.88, 0.14, 3.74), (0.30, 0.30, 0.30)),
        ((0.88, 0.14, 3.74), (0.30, 0.30, 0.30)),
    ]
    for pos, rad in curl_puffs:
        head.sphere(pos, rad, "hair_plum", uv, u_segs=16, v_segs=12)

    # --- WIDE WOVEN STRAW HAT WITH PINK BAND & GOLDEN-RIMMED SCALLOP CLASP ---
    hat_c = (0.0, 0.10, 4.38)
    hat_rot = (-12.0, 0.0, 0.0)
    hat_prof = [
        (0.76, -0.06),
        (1.18, -0.09),
        (1.56, -0.14),
        (1.62, -0.07),
        (1.58, 0.01),
        (1.42, 0.06),
        (1.02, 0.11),
        (0.86, 0.18),
        (0.84, 0.44),
        (0.74, 0.68),
        (0.52, 0.84),
        (0.24, 0.90),
        (0.02, 0.91),
    ]
    head.lathe(hat_c, hat_prof, "hat_straw", uv, rot=hat_rot, segs=38, scale_xy=(1.04, 1.00))

    # Wide pink hat ribbon band
    band_prof = [
        (0.88, 0.17),
        (0.89, 0.28),
        (0.87, 0.40),
        (0.845, 0.42),
    ]
    head.lathe(hat_c, band_prof, "hat_pink", uv, rot=hat_rot, segs=38, scale_xy=(1.04, 1.00))

    # Signature scallop shell hat-band clasp: crisp pink scallop sitting cleanly over a golden rim!
    head.shell_scallop((-0.36, -0.78, 4.74), scale=0.40, swatch="gold", uv_cells=uv, rot=(-16, 12, 24))
    head.shell_scallop((-0.38, -0.85, 4.74), scale=0.35, swatch="shell_pink", uv_cells=uv, rot=(-16, 12, 24))

    # =========================================================================
    # 4. GROUND BEACH PROPS: SLEEPING STARFISH + ALL 4 DISTINCT SHELLS!
    # =========================================================================
    props.starfish((1.22, -0.58, 0.08), scale=0.72, swatch="starfish_coral", eye_swatch="eye_dark", uv_cells=uv, rot=(4, -4, -18))

    # All 4 sculpted shells resting cleanly ON TOP of the sand (zero clipping below Z=0!)
    props.shell_nautilus((-1.10, -0.52, 0.36), scale=0.62, swatch="shell_gold", uv_cells=uv, rot=(14, 10, 32))
    props.shell_scallop((1.36, 0.26, 0.24), scale=0.56, swatch="shell_pink", uv_cells=uv, rot=(68, 10, -40))
    props.shell_conch((0.74, -1.04, 0.25), scale=0.56, swatch="shell_aqua", inner_swatch="shell_cream", uv_cells=uv, rot=(20, 12, -25))
    props.shell_spiral((-1.18, 0.42, 0.30), scale=0.56, swatch="shell_lilac", inner_swatch="shell_lilac_in", uv_cells=uv, rot=(38, -18, 35))

    # Tiny smooth beach pebbles for extra natural polish
    for px, py, r in [(-0.75, -0.92, 0.14), (0.85, 0.68, 0.13), (-1.45, -0.05, 0.11), (1.58, -0.22, 0.10)]:
        props.sphere((px, py, 0.11), (r * 1.2, r, r * 0.65), "pebble", uv, u_segs=10, v_segs=8)

    # =========================================================================
    # FINALIZE, GROUND, SCALE, EXPORT & RENDER
    # =========================================================================
    objs = [
        legs.to_object(atlas_mat),
        torso.to_object(atlas_mat),
        head.to_object(atlas_mat),
        props.to_object(atlas_mat),
        glow_basket.to_object(mat_glow_pink),
    ]
    # Scale so Luna's height = 5.18 studs (adorable slightly shorter than Lucy 5.38 & Vo Anzol 6.46!)
    ground_and_scale(objs, target_height=5.18, measure_names={"Legs", "Torso", "Head"})

    out_dir.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(out_dir / "luna.blend"))
    export_glb(out_dir / "luna.glb", objs)

    stats = report_stats("Luna", objs)
    (out_dir / "report.json").write_text(json.dumps(stats, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(stats, indent=2), flush=True)

    if render:
        render_review_views(out_dir / "views", objs, head_z_hint=3.95, size=768)


if __name__ == "__main__":
    no_render = "--no-render" in sys.argv
    out_path = Path(r"c:\Users\Evojota\dev\jogo ainda sem nome\art\npcs\exports\luna")
    build_luna(out_path, render=not no_render)
