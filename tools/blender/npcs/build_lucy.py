"""Build high-craft stylized 3D model of Lucy (NPC_BaitVendor) for Legendary Catch.

Matches C:\\Users\\Evojota\\Downloads\\NPCs Legendary Cat\\Luz\\upgrade-variants.png,
character-sheet.png and hero.png with millimetric fidelity.

Objects in exported GLB:
  - Legs       : static grounded dark boots and navy trousers
  - Torso      : breathing/swaying cream shirt, pink apron with turquoise bow & coral pockets,
                 leather tool pouch (scissors + bobber), arms, held wooden bait bucket
  - Head       : look-at chibi head, face, chestnut hair + low bun with aqua tie, cyan hat + gold band
  - Props      : grounded wooden bait crate with golden rivets & cork jar lids
  - Glass_Jars : 3 thick translucent glass bait jars sitting on the crate (Roblox Material.Glass)
  - Glow_Cyan  : Neon cyan glowing bait inside left jar + inside Lucy's held bucket
  - Glow_Pink  : Neon rose-pink glowing bait inside middle jar
  - Glow_Gold  : Neon golden glowing bait inside right jar
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
    "skin": ("#FCD4B6", "skin"),
    "blush": ("#FF8CA8", "solid"),
    "eye_dark": ("#1C1E28", "solid"),
    "eye_white": ("#FFFFFF", "solid"),
    "smile_dark": ("#5A2D24", "solid"),
    "hair": ("#683D28", "hair"),
    "hat_cyan": ("#5EE3FF", "solid"),
    "hat_gold": ("#FFC245", "metal"),
    "shirt_cream": ("#FAF1E2", "knit"),
    "apron_pink": ("#FF8FC8", "fabric"),
    "apron_trim": ("#4DDAD6", "fabric"),
    "pocket_coral": ("#FF7A60", "coral_pocket"),
    "pants_navy": ("#2F4C74", "denim"),
    "boot_dark": ("#442F28", "leather"),
    "boot_sole": ("#281B17", "solid"),
    "leather": ("#8D532E", "leather"),
    "wood_crate": ("#A46234", "wood_plank"),
    "wood_frame": ("#874B24", "wood"),
    "wood_bucket": ("#B06E3C", "wood"),
    "cork": ("#A86836", "wood"),
    "rope": ("#D4A46A", "straw"),
    "bucket_hoop": ("#5B8894", "metal"),
    "gold": ("#FFC94A", "metal"),
    "scissor_yellow": ("#FFD648", "metal"),
    "bobber_red": ("#FF5A52", "solid"),
    "bobber_white": ("#FAF6EE", "solid"),
    "bait_cyan": ("#5CFFF0", "neon"),
    "bait_pink": ("#FF82D2", "neon"),
    "bait_gold": ("#FFD84C", "neon"),
}


def _add_bait_cluster(builder: PartBuilder, cx: float, cy: float, cz: float, swatch: str, uv: dict, seed: int):
    """Cute plump glowing bait curls/pellets inside a glass jar."""
    offsets = [
        (-0.08, -0.06, -0.09, 0.085),
        (0.08, -0.05, -0.08, 0.085),
        (0.00, 0.08, -0.08, 0.085),
        (-0.09, 0.04, 0.02, 0.082),
        (0.07, 0.05, 0.03, 0.082),
        (0.00, -0.08, 0.03, 0.085),
        (-0.04, -0.02, 0.11, 0.078),
        (0.06, -0.02, 0.10, 0.078),
    ]
    for dx, dy, dz, rad in offsets:
        # Slight per-jar swirl offset
        ang = seed * 1.1
        rx = dx * math.cos(ang) - dy * math.sin(ang)
        ry = dx * math.sin(ang) + dy * math.cos(ang)
        builder.sphere((cx + rx, cy + ry, cz + dz), (rad, rad, rad * 0.92), swatch, uv, u_segs=10, v_segs=8)


def build_lucy(out_dir: Path, render: bool = True):
    reset_scene()
    atlas_mat, uv = build_atlas(out_dir / "lucy_atlas.png", PALETTE, size=1024)
    mat_glass = build_solid_material("Glass_Jars", "#DCF8FF", roughness=0.08, alpha=0.35)
    mat_glow_cyan = build_solid_material("Glow_Cyan", "#5CFFF0", roughness=0.15, emission=2.6)
    mat_glow_pink = build_solid_material("Glow_Pink", "#FF86D2", roughness=0.15, emission=2.6)
    mat_glow_gold = build_solid_material("Glow_Gold", "#FFD84C", roughness=0.15, emission=2.6)

    torso_pivot = (0.0, 0.0, 2.55)
    head_pivot = (0.0, 0.0, 3.68)

    legs = PartBuilder("Legs", origin=(0.0, 0.0, 0.0))
    torso = PartBuilder("Torso", origin=torso_pivot)
    head = PartBuilder("Head", origin=head_pivot)
    props = PartBuilder("Props", origin=(0.0, 0.0, 0.0))
    glass_jars = PartBuilder("Glass_Jars", origin=(0.0, 0.0, 0.0))
    glow_cyan_torso = PartBuilder("Glow_Cyan_Bucket", origin=torso_pivot)
    glow_cyan_jar = PartBuilder("Glow_Cyan_Jar", origin=(0.0, 0.0, 0.0))
    glow_pink_jar = PartBuilder("Glow_Pink_Jar", origin=(0.0, 0.0, 0.0))
    glow_gold_jar = PartBuilder("Glow_Gold_Jar", origin=(0.0, 0.0, 0.0))

    # =========================================================================
    # 1. LEGS & CHUNKY TOY BOOTS (Z = 0.00 -> 1.65)
    # =========================================================================
    for side in (-1, 1):
        x = side * 0.39
        yaw = -side * 4.0
        # Dark sole
        legs.rounded_box((x, -0.08, 0.09), (0.68, 0.94, 0.18), "boot_sole", uv, rot=(0, 0, yaw), bevel=0.035, segments=2)
        # Main dark boot
        legs.rounded_box((x, -0.05, 0.39), (0.64, 0.86, 0.48), "boot_dark", uv, rot=(0, 0, yaw), bevel=0.08, segments=3)
        # Rounded boot toe front
        legs.sphere((x, -0.34, 0.34), (0.30, 0.24, 0.20), "boot_dark", uv, rot=(0, 0, yaw))
        # Navy trouser leg
        legs.rounded_box((x, 0.0, 1.15), (0.58, 0.62, 1.12), "pants_navy", uv, bevel=0.07, segments=3)

    # Hip block under apron skirt
    legs.rounded_box((0.0, 0.0, 1.62), (1.36, 0.72, 0.34), "pants_navy", uv, bevel=0.07, segments=2)

    # =========================================================================
    # 2. TORSO: CREAM SHIRT, PINK APRON, AQUA BOW, CORAL POCKETS, TOOL POUCH
    # =========================================================================
    # Cream inner shirt & folded collar (ends cleanly at waist Z=2.36 so it never pokes through pink skirt!)
    torso.rounded_box((0.0, 0.0, 2.90), (1.48, 0.86, 1.18), "shirt_cream", uv, bevel=0.14, segments=3, taper_top=0.95)
    # Cute collar flaps on front neck
    for side in (-1, 1):
        torso.rounded_box((side * 0.22, -0.44, 3.42), (0.30, 0.10, 0.16), "shirt_cream", uv, rot=(0, -side * 16, side * 8), bevel=0.03)
    # Neck
    torso.cylinder((0.0, 0.0, 3.58), 0.28, 0.26, 0.30, "skin", uv, bevel=0.03)

    # Pink apron bib (chest) + coral-edged straps + flared apron skirt!
    torso.rounded_box((0.0, -0.06, 2.84), (1.30, 0.88, 1.06), "apron_pink", uv, bevel=0.12, segments=3, taper_top=0.88)
    # Flared skirt covering waist down to Z=1.42 (A-line silhouette matching upgrade-variants!)
    skirt_prof = [
        (0.94, -0.58),
        (0.92, -0.48),
        (0.86, -0.22),
        (0.80, 0.08),
        (0.76, 0.30),
    ]
    torso.lathe((0.0, -0.02, 2.02), skirt_prof, "apron_pink", uv, segs=28, scale_xy=(1.04, 0.68))
    # Aqua bottom hem band along skirt edge!
    hem_prof = [
        (0.955, -0.60),
        (0.96, -0.53),
        (0.94, -0.47),
    ]
    torso.lathe((0.0, -0.02, 2.02), hem_prof, "apron_trim", uv, segs=28, scale_xy=(1.04, 0.68))
    # Cute golden dashed stitches along skirt hem
    for k in range(14):
        th = math.tau * k / 14.0
        sx = math.cos(th) * 0.95 * 1.04
        sy = -0.02 + math.sin(th) * 0.95 * 0.68
        torso.sphere((sx, sy, 1.50), (0.045, 0.045, 0.025), "gold", uv, u_segs=8, v_segs=6)

    # Shoulder straps (coral-pink straps reaching down to waist in back!) + 2 gold buttons on chest!
    for side in (-1, 1):
        strap_pts = [
            (side * 0.42, -0.48, 3.16),
            (side * 0.44, -0.44, 3.48),
            (side * 0.44, 0.0, 3.55),
            (side * 0.44, 0.44, 3.48),
            (side * 0.42, 0.46, 2.36),
        ]
        torso.tube(strap_pts, 0.075, "pocket_coral", uv, segs=10)
        torso.sphere((side * 0.42, -0.52, 3.12), (0.085, 0.055, 0.085), "gold", uv)

    # Aqua waist sash belt + adorable front bow!
    torso.torus((0.0, -0.02, 2.34), 0.77, 0.085, "apron_trim", uv, scale_xyz=(1.03, 0.68, 1.2))
    # Bow knot center + 2 puffy bow loops + 2 dangling ribbons
    torso.sphere((0.0, -0.58, 2.34), (0.11, 0.09, 0.11), "apron_trim", uv)
    for side in (-1, 1):
        torso.sphere((side * 0.21, -0.58, 2.36), (0.17, 0.08, 0.12), "apron_trim", uv, rot=(0, -side * 12, side * 14))
        torso.capsule((side * 0.06, -0.58, 2.28), (side * 0.16, -0.62, 1.98), 0.055, "apron_trim", uv, r1=0.045)

    # Two coral stitched pockets on apron skirt front (with tiny golden buttons!)
    for side in (-1, 1):
        px = side * 0.44
        torso.rounded_box((px, -0.56, 1.88), (0.42, 0.14, 0.40), "pocket_coral", uv, rot=(6, 0, -side * 12), bevel=0.04, segments=2, proj="front")
        torso.sphere((px, -0.64, 2.02), (0.042, 0.032, 0.042), "gold", uv)
    # Cute aqua anchor/fish charm between pockets
    torso.sphere((0.0, -0.63, 1.88), (0.06, 0.04, 0.14), "apron_trim", uv)
    torso.smile_arc((0.0, -0.64, 1.82), width=0.22, depth_y=0.03, drop_z=0.08, thickness=0.032, swatch="apron_trim", uv_cells=uv)

    # Leather tool pouch hanging at left hip (+X = 0.80, Z = 2.04) with scissors & fishing bobber!
    px, py, pz = 0.78, -0.34, 2.02
    torso.rounded_box((px, py, pz), (0.40, 0.26, 0.44), "leather", uv, rot=(0, 8, -28), bevel=0.05, segments=2)
    # Pouch top flap + gold button
    torso.rounded_box((px + 0.04, py - 0.06, pz + 0.14), (0.42, 0.18, 0.16), "leather", uv, rot=(0, 8, -28), bevel=0.035)
    torso.sphere((px + 0.08, py - 0.16, pz + 0.04), (0.048, 0.035, 0.048), "gold", uv)
    # Gold ring linking pouch to belt
    torso.torus((px - 0.02, py, pz + 0.28), 0.075, 0.022, "gold", uv, rot=(90, 0, -28), major_segs=14, minor_segs=6)
    # Yellow scissor handles poking out of pouch!
    torso.torus((px - 0.07, py + 0.02, pz + 0.30), 0.068, 0.022, "scissor_yellow", uv, rot=(90, 0, -24), major_segs=14, minor_segs=6)
    torso.torus((px + 0.06, py - 0.02, pz + 0.31), 0.068, 0.022, "scissor_yellow", uv, rot=(90, 0, -24), major_segs=14, minor_segs=6)
    # Red-and-white mini fishing bobber poking out beside scissors!
    torso.sphere((px + 0.14, py - 0.08, pz + 0.27), (0.078, 0.078, 0.078), "bobber_red", uv, u_segs=12, v_segs=8)
    torso.sphere((px + 0.14, py - 0.08, pz + 0.23), (0.076, 0.076, 0.052), "bobber_white", uv, u_segs=12, v_segs=8)

    # ARMS (matching upgrade-variants right: right hand holding glowing bait bucket, left relaxed!)
    # --- LEFT ARM (+X): cheerful slightly outward gesture ---
    l_sh = (0.94, 0.0, 3.22)
    l_elb = (1.24, -0.06, 2.74)
    l_hand = (1.30, -0.14, 2.34)
    torso.sphere(l_sh, (0.28, 0.28, 0.28), "shirt_cream", uv)
    torso.capsule(l_sh, l_elb, 0.24, "shirt_cream", uv, r1=0.22)
    torso.cylinder((1.22, -0.06, 2.76), 0.26, 0.26, 0.16, "shirt_cream", uv, rot=(0, -26, 0), bevel=0.04)
    torso.capsule(l_elb, l_hand, 0.19, "skin", uv, r1=0.18)
    torso.sphere(l_hand, (0.23, 0.22, 0.23), "skin", uv)
    torso.sphere((1.16, -0.26, 2.36), (0.095, 0.085, 0.095), "skin", uv)

    # --- RIGHT ARM (-X): bent forward holding the wooden bait bucket with cyan glowing bait! ---
    r_sh = (-0.94, 0.0, 3.22)
    r_elb = (-1.22, -0.12, 2.76)
    r_hand = (-1.24, -0.44, 2.94)
    torso.sphere(r_sh, (0.28, 0.28, 0.28), "shirt_cream", uv)
    torso.capsule(r_sh, r_elb, 0.24, "shirt_cream", uv, r1=0.22)
    torso.cylinder((-1.20, -0.11, 2.78), 0.26, 0.26, 0.16, "shirt_cream", uv, rot=(0, 26, 0), bevel=0.04)
    torso.capsule(r_elb, r_hand, 0.19, "skin", uv, r1=0.18)
    torso.sphere(r_hand, (0.23, 0.23, 0.23), "skin", uv)
    torso.sphere((-1.10, -0.56, 2.96), (0.095, 0.085, 0.095), "skin", uv)

    # HELD WOODEN BAIT BUCKET (hanging from right hand at X = -1.26, Y = -0.46, Z = 2.04)
    bx, by, bz = -1.28, -0.46, 2.02
    # Tapered wooden bucket body
    torso.cylinder((bx, by, bz), 0.34, 0.44, 0.72, "wood_bucket", uv, segs=20, bevel=0.03)
    # Two aqua/slate metal hoops with golden rivets around bucket
    torso.torus((bx, by, bz + 0.24), 0.43, 0.036, "bucket_hoop", uv, major_segs=24, minor_segs=8)
    torso.torus((bx, by, bz - 0.18), 0.37, 0.036, "bucket_hoop", uv, major_segs=24, minor_segs=8)
    for k in range(6):
        th = math.tau * k / 6.0
        torso.sphere((bx + math.cos(th) * 0.45, by + math.sin(th) * 0.45, bz + 0.24), (0.032, 0.032, 0.032), "gold", uv, u_segs=8, v_segs=6)
        torso.sphere((bx + math.cos(th) * 0.39, by + math.sin(th) * 0.39, bz - 0.18), (0.030, 0.030, 0.030), "gold", uv, u_segs=8, v_segs=6)
    # Rope handle arcing cleanly up into Lucy's right hand!
    handle_pts = []
    for i in range(13):
        t = i / 12.0
        ang = math.pi * t
        hx = bx + math.cos(ang) * 0.44
        hz = bz + 0.30 + math.sin(ang) * 0.66
        handle_pts.append((hx, by, hz))
    torso.tube(handle_pts, 0.046, "rope", uv, segs=10)
    # Glowing cyan bait mound inside bucket!
    for dx, dy, dz, r in [
        (0.0, 0.0, 0.34, 0.16),
        (-0.14, -0.08, 0.33, 0.12),
        (0.14, -0.06, 0.33, 0.12),
        (-0.08, 0.12, 0.33, 0.12),
        (0.11, 0.11, 0.32, 0.11),
    ]:
        glow_cyan_torso.sphere((bx + dx, by + dy, bz + dz), (r, r, r * 0.72), "bait_cyan", uv, u_segs=10, v_segs=8)

    # =========================================================================
    # 3. HEAD, CUTE FACE, CHESTNUT HAIR + LOW BUN & CYAN HAT WITH GOLD BAND
    # =========================================================================
    hc = Vector((0.0, 0.0, 4.10))
    head.sphere(hc, (0.78, 0.72, 0.70), "skin", uv, u_segs=24, v_segs=18)

    # Cute small round ears
    for side in (-1, 1):
        head.sphere((side * 0.78, 0.02, 4.04), (0.12, 0.14, 0.16), "skin", uv)

    # Big cute dot eyes + white shine + pink cheek blushes + cheerful smile
    for side in (-1, 1):
        ex = side * 0.27
        head.sphere((ex, -0.66, 4.12), (0.105, 0.075, 0.125), "eye_dark", uv, u_segs=14, v_segs=10)
        head.sphere((ex - 0.032, -0.725, 4.165), (0.036, 0.025, 0.036), "eye_white", uv, u_segs=10, v_segs=8)
        # Signature Lucy rounded-pill pink cheeks!
        head.rounded_box((side * 0.44, -0.60, 3.96), (0.19, 0.08, 0.10), "blush", uv, rot=(0, 0, -side * 16), bevel=0.035, segments=2)

    head.smile_arc((0.0, -0.71, 3.94), width=0.30, depth_y=0.06, drop_z=0.10, thickness=0.030, swatch="smile_dark", uv_cells=uv)

    # Chestnut hair: full cap covering crown seamlessly + parted bangs + visible low bun with aqua tie!
    head.sphere((0.0, 0.10, 4.20), (0.84, 0.78, 0.72), "hair", uv, u_segs=22, v_segs=16)
    for side in (-1, 1):
        bang_pts = [
            (side * 0.03, -0.66, 4.56),
            (side * 0.36, -0.63, 4.44),
            (side * 0.66, -0.42, 4.22),
            (side * 0.72, -0.14, 3.92),
        ]
        head.tube(bang_pts, [0.18, 0.22, 0.21, 0.16], "hair", uv, segs=12)
        head.sphere((side * 0.64, 0.14, 3.92), (0.24, 0.32, 0.32), "hair", uv)

    # Signature low chestnut bun clearly peeking on left-back (+X) with bright aqua scrunchie tie!
    bun_c = (0.74, 0.36, 3.78)
    head.sphere(bun_c, (0.32, 0.30, 0.29), "hair", uv, u_segs=18, v_segs=14)
    head.torus((0.56, 0.28, 3.82), 0.24, 0.072, "apron_trim", uv, rot=(0, 62, 24), major_segs=18, minor_segs=8)

    # Iconic broad cyan hat (#5EE3FF) seated flush on hair with golden band (#FFC245)!
    hat_c = (0.0, 0.0, 4.54)
    hat_prof = [
        (0.72, -0.04),
        (1.08, -0.05),
        (1.38, -0.09),
        (1.44, -0.03),
        (1.42, 0.04),
        (1.32, 0.07),
        (0.96, 0.10),
        (0.84, 0.15),
        (0.83, 0.56),
        (0.74, 0.68),
        (0.46, 0.73),
        (0.02, 0.74),
    ]
    head.lathe(hat_c, hat_prof, "hat_cyan", uv, rot=(-3.0, 0.0, 0.0), segs=36, scale_xy=(1.03, 0.98))
    # Thick golden hat band
    band_prof = [
        (0.855, 0.14),
        (0.865, 0.24),
        (0.855, 0.35),
        (0.835, 0.37),
    ]
    head.lathe(hat_c, band_prof, "hat_gold", uv, rot=(-3.0, 0.0, 0.0), segs=36, scale_xy=(1.03, 0.98))

    # =========================================================================
    # 4. GROUND PROPS: WOODEN BAIT CRATE + 3 THICK GLASS BAIT JARS (CYAN, PINK, GOLD)
    # =========================================================================
    cx, cy = 2.02, -0.08
    crate_w, crate_d, crate_h = 1.84, 1.04, 1.02
    # Main recessed plank core
    props.rounded_box((cx, cy, crate_h * 0.5), (crate_w - 0.10, crate_d - 0.10, crate_h - 0.06), "wood_crate", uv, bevel=0.04, segments=2)
    # 3 horizontal front/back slat planks
    for pz in (0.20, 0.51, 0.82):
        props.rounded_box((cx, cy - crate_d * 0.48, pz), (crate_w - 0.14, 0.09, 0.25), "wood_crate", uv, bevel=0.025)
        props.rounded_box((cx, cy + crate_d * 0.48, pz), (crate_w - 0.14, 0.09, 0.25), "wood_crate", uv, bevel=0.025)
    # 4 chunky corner posts + golden rivets on front face!
    for sx in (-1, 1):
        for sy in (-1, 1):
            px_c = cx + sx * (crate_w * 0.46)
            py_c = cy + sy * (crate_d * 0.44)
            props.rounded_box((px_c, py_c, crate_h * 0.5), (0.22, 0.22, crate_h + 0.04), "wood_frame", uv, bevel=0.04)
        # 3 golden rivets per front corner post (matches upgrade-variants!)
        for rz in (0.20, 0.51, 0.82):
            props.sphere((cx + sx * (crate_w * 0.46), cy - crate_d * 0.55, rz), (0.048, 0.036, 0.048), "gold", uv, u_segs=10, v_segs=8)
    # Top crate frame rim
    props.rounded_box((cx, cy, crate_h + 0.01), (crate_w + 0.04, crate_d + 0.04, 0.10), "wood_frame", uv, bevel=0.03)

    # 3 THICK GLASS JARS WITH WOOD/CORK LIDS & GLOWING BAIT INSIDE!
    jar_specs = [
        (cx - 0.56, cy - 0.02, glow_cyan_jar, "bait_cyan", 1),
        (cx + 0.00, cy - 0.02, glow_pink_jar, "bait_pink", 2),
        (cx + 0.56, cy - 0.02, glow_gold_jar, "bait_gold", 3),
    ]
    jar_base_z = crate_h + 0.06
    for jx, jy, glow_builder, swatch, seed in jar_specs:
        # Thick glass body (rounded jar cylinder + shoulder + neck lip)
        jar_prof = [
            (0.20, 0.00),
            (0.25, 0.05),
            (0.26, 0.44),
            (0.23, 0.53),
            (0.18, 0.57),
            (0.20, 0.61),
            (0.17, 0.62),
        ]
        glass_jars.lathe((jx, jy, jar_base_z), jar_prof, "bait_cyan", uv, segs=22)
        # Warm wooden cork lid on top (in opaque Props mesh!)
        props.cylinder((jx, jy, jar_base_z + 0.65), 0.21, 0.22, 0.12, "cork", uv, segs=18, bevel=0.03)
        props.cylinder((jx, jy, jar_base_z + 0.58), 0.16, 0.16, 0.08, "wood_frame", uv, segs=16, bevel=0.02)
        # Glowing bait curls inside the jar!
        _add_bait_cluster(glow_builder, jx, jy, jar_base_z + 0.26, swatch, uv, seed)

    # =========================================================================
    # FINALIZE, GROUND, SCALE, EXPORT & RENDER
    # =========================================================================
    objs = [
        legs.to_object(atlas_mat),
        torso.to_object(atlas_mat),
        head.to_object(atlas_mat),
        props.to_object(atlas_mat),
        glass_jars.to_object(mat_glass),
        glow_cyan_torso.to_object(mat_glow_cyan),
        glow_cyan_jar.to_object(mat_glow_cyan),
        glow_pink_jar.to_object(mat_glow_pink),
        glow_gold_jar.to_object(mat_glow_gold),
    ]
    # Scale so Lucy's soles-to-top-of-hat = 5.38 studs (matches current NPC_BaitVendor scale!)
    ground_and_scale(objs, target_height=5.38, measure_names={"Legs", "Torso", "Head"})

    out_dir.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(out_dir / "lucy.blend"))
    export_glb(out_dir / "lucy.glb", objs)

    stats = report_stats("Lucy", objs)
    (out_dir / "report.json").write_text(json.dumps(stats, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(stats, indent=2), flush=True)

    if render:
        render_review_views(out_dir / "views", objs, head_z_hint=4.15, size=768)


if __name__ == "__main__":
    no_render = "--no-render" in sys.argv
    out_path = Path(r"c:\Users\Evojota\dev\jogo ainda sem nome\art\npcs\exports\lucy")
    build_lucy(out_path, render=not no_render)
