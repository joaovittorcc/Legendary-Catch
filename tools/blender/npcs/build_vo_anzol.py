"""Build high-craft stylized 3D model of Vô Anzol (GuideNPC) for Legendary Catch.

Matches C:\\Users\\Evojota\\Downloads\\NPCs Legendary Cat\\Vô Anzol\\upgrade-variants.png
and character-sheet.png / speech-portrait.png with millimetric fidelity.

Objects in exported GLB:
  - Legs       : static grounded boots, tan cuffs, slate trousers
  - Torso      : breathing/swaying shirt, petrol vest, pockets, tools, belt, lantern frame, arms, rod + lure
  - Head       : look-at head, face, nose, eyes, brows, curly cloud beard & mustache, straw hat + patch
  - Glow_Cyan  : Neon cyan vest crystal pin & glowing blue rod tip (follows Torso)
  - Glow_Amber : Neon warm amber core of belt lantern (follows Torso)
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
    "skin": ("#F2C29E", "skin"),
    "nose": ("#E59A78", "skin"),
    "cheek_line": ("#D49070", "solid"),
    "white_hair": ("#F5F6F8", "hair"),
    "white_shade": ("#E4E8EE", "hair"),
    "eye_dark": ("#1C202B", "solid"),
    "eye_white": ("#FFFFFF", "solid"),
    "smile_dark": ("#7A3F32", "solid"),
    "hat_straw": ("#F4B84E", "straw"),
    "hat_under": ("#D4882E", "straw"),
    "hat_band": ("#243A73", "fabric"),
    "hat_band_dark": ("#192852", "fabric"),
    "hat_stitch": ("#38C6F2", "solid"),
    "hat_patch": ("#A46A3C", "patch"),
    "shirt_cream": ("#F8EED6", "knit"),
    "vest_petrol": ("#2C5E6E", "fabric"),
    "vest_trim": ("#224B58", "fabric"),
    "pocket_tan": ("#B87A42", "pocket_x"),
    "leather_dark": ("#422C22", "leather"),
    "boot_leather": ("#4E3328", "leather"),
    "boot_sole": ("#2B1C16", "solid"),
    "boot_cuff": ("#C4854C", "fabric"),
    "pants_slate": ("#3E556B", "denim"),
    "gold": ("#FFC64A", "metal"),
    "lantern_brass": ("#9E5C28", "metal"),
    "rod_wood": ("#6E5340", "wood"),
    "rod_wrap": ("#F0DEC0", "fabric"),
    "metal_steel": ("#98A4B0", "metal"),
    "lure_blue": ("#3CC6E8", "solid"),
    "lure_gold": ("#FFD048", "solid"),
    "tool_handle": ("#965B30", "wood"),
}


def build_vo_anzol(out_dir: Path, render: bool = True):
    reset_scene()
    atlas_mat, uv = build_atlas(out_dir / "vo_anzol_atlas.png", PALETTE, size=1024)
    mat_glow_cyan = build_solid_material("Glow_Cyan", "#4AE4FF", roughness=0.15, emission=2.5)
    mat_glow_amber = build_solid_material("Glow_Amber", "#FFC840", roughness=0.15, emission=3.0)

    torso_pivot = (0.0, 0.0, 3.35)
    head_pivot = (0.0, 0.0, 4.78)

    legs = PartBuilder("Legs", origin=(0.0, 0.0, 0.0))
    torso = PartBuilder("Torso", origin=torso_pivot)
    head = PartBuilder("Head", origin=head_pivot)
    glow_cyan = PartBuilder("Glow_Cyan", origin=torso_pivot)
    glow_amber = PartBuilder("Glow_Amber", origin=torso_pivot)

    # =========================================================================
    # 1. LEGS & BOOTS (Z = 0.00 -> 2.46)
    # =========================================================================
    for side in (-1, 1):
        x = side * 0.54
        foot_yaw = -side * 5.0
        legs.rounded_box((x, -0.10, 0.11), (0.94, 1.24, 0.22), "boot_sole", uv, rot=(0, 0, foot_yaw), bevel=0.04, segments=2)
        legs.rounded_box((x, -0.06, 0.52), (0.88, 1.12, 0.68), "boot_leather", uv, rot=(0, 0, foot_yaw), bevel=0.10, segments=3)
        legs.sphere((x - side * 0.02, -0.44, 0.42), (0.41, 0.34, 0.27), "boot_leather", uv, rot=(0, 0, foot_yaw))
        legs.rounded_box((x, -0.01, 1.00), (0.96, 1.00, 0.32), "boot_cuff", uv, rot=(0, 0, foot_yaw * 0.5), bevel=0.07, segments=3)
        legs.rounded_box((x * 0.94, 0.0, 1.78), (0.86, 0.88, 1.38), "pants_slate", uv, rot=(0, side * 3.0, 0), bevel=0.09, segments=3)

    legs.rounded_box((0.0, 0.0, 2.28), (1.76, 0.92, 0.44), "pants_slate", uv, bevel=0.09, segments=2)

    # =========================================================================
    # 2. TORSO, BELT, VEST, POCKETS, TOOLS, LANTERN & ARMS (Z = 2.40 -> 4.50)
    # =========================================================================
    torso.rounded_box((0.0, 0.0, 3.44), (1.92, 1.12, 1.98), "shirt_cream", uv, bevel=0.16, segments=3, taper_top=0.96)
    torso.cylinder((0.0, 0.0, 4.44), 0.42, 0.44, 0.14, "shirt_cream", uv, bevel=0.04)
    torso.cylinder((0.0, 0.0, 4.62), 0.34, 0.32, 0.36, "skin", uv, bevel=0.03)

    # Petrol fisherman vest (open down the front center with soft rounded shoulders)
    torso.rounded_box((0.0, 0.26, 3.46), (2.06, 0.72, 1.88), "vest_petrol", uv, bevel=0.18, segments=3, taper_top=0.92)
    for side in (-1, 1):
        torso.rounded_box((side * 0.62, -0.14, 3.46), (0.84, 0.94, 1.88), "vest_petrol", uv, bevel=0.16, segments=3, taper_top=0.92)
        torso.rounded_box((side * 0.65, -0.62, 2.98), (0.50, 0.18, 0.48), "pocket_tan", uv, bevel=0.04, segments=2, proj="front")
        torso.rounded_box((side * 0.65, -0.63, 3.21), (0.52, 0.20, 0.08), "vest_trim", uv, bevel=0.02, segments=2)
        torso.sphere((side * 0.30, -0.63, 3.55), (0.075, 0.055, 0.075), "gold", uv)

    # Pocket tools (matching upgrade-variants right!)
    torso.rounded_box((-0.68, -0.60, 3.36), (0.14, 0.10, 0.34), "tool_handle", uv, rot=(0, -14, 0), bevel=0.03)
    torso.sphere((-0.71, -0.65, 3.44), (0.025, 0.02, 0.025), "gold", uv)
    torso.capsule((0.55, -0.60, 3.22), (0.50, -0.61, 3.48), 0.038, "metal_steel", uv, r1=0.028)
    torso.capsule((0.63, -0.60, 3.22), (0.68, -0.61, 3.48), 0.038, "metal_steel", uv, r1=0.028)
    torso.sphere((0.59, -0.61, 3.34), (0.055, 0.045, 0.055), "metal_steel", uv)
    torso.cylinder((0.79, -0.60, 3.34), 0.095, 0.095, 0.22, "rod_wrap", uv, bevel=0.02)
    torso.cylinder((0.79, -0.60, 3.44), 0.115, 0.115, 0.035, "tool_handle", uv, bevel=0.01)

    # Glowing cyan crystal brooch pin on left chest (+X)
    glow_cyan.rounded_box((0.66, -0.63, 3.86), (0.20, 0.12, 0.32), "hat_stitch", uv, rot=(0, -16, 0), bevel=0.03, segments=2)

    # Diagonal brown leather strap
    front_strap = [
        (-0.74, -0.58, 4.38),
        (-0.35, -0.63, 3.88),
        (0.05, -0.64, 3.35),
        (0.45, -0.63, 2.86),
        (0.76, -0.56, 2.55),
    ]
    torso.tube(front_strap, 0.095, "leather_dark", uv, segs=10)
    back_strap = [
        (-0.74, 0.56, 4.38),
        (-0.30, 0.64, 3.85),
        (0.15, 0.65, 3.32),
        (0.55, 0.62, 2.82),
        (0.76, 0.54, 2.55),
    ]
    torso.tube(back_strap, 0.095, "leather_dark", uv, segs=10)
    torso.tube([(-0.74, -0.58, 4.38), (-0.74, 0.0, 4.46), (-0.74, 0.56, 4.38)], 0.095, "leather_dark", uv, segs=10)

    # Belt around waist + gold rectangular buckle
    torso.rounded_box((0.0, 0.0, 2.52), (2.12, 1.24, 0.28), "leather_dark", uv, bevel=0.06, segments=2)
    torso.rounded_box((0.0, -0.64, 2.52), (0.48, 0.14, 0.40), "gold", uv, bevel=0.05, segments=2)
    torso.rounded_box((0.0, -0.66, 2.52), (0.28, 0.14, 0.20), "leather_dark", uv, bevel=0.02, segments=2)
    torso.capsule((-0.14, -0.71, 2.52), (0.04, -0.71, 2.52), 0.028, "gold", uv)

    # Warm amber belt lantern hanging at left hip (+X = +0.78, Y = -0.62, Z = 1.96)
    lx, ly, lz = 0.78, -0.62, 1.96
    torso.torus((lx, ly, lz + 0.46), 0.12, 0.032, "gold", uv, rot=(90, 0, 0), major_segs=18, minor_segs=8)
    torso.cylinder((lx, ly, lz + 0.28), 0.24, 0.11, 0.16, "lantern_brass", uv, segs=16, bevel=0.02)
    torso.cylinder((lx, ly, lz + 0.19), 0.27, 0.27, 0.05, "lantern_brass", uv, segs=16, bevel=0.015)
    torso.cylinder((lx, ly, lz - 0.19), 0.25, 0.27, 0.06, "lantern_brass", uv, segs=16, bevel=0.015)
    torso.cylinder((lx, ly, lz - 0.26), 0.18, 0.23, 0.09, "lantern_brass", uv, segs=16, bevel=0.02)
    for k in range(4):
        ang = math.radians(45 + k * 90)
        bx = lx + math.cos(ang) * 0.21
        by = ly + math.sin(ang) * 0.21
        torso.capsule((bx, by, lz - 0.18), (bx, by, lz + 0.18), 0.024, "lantern_brass", uv, segs=8)
    glow_amber.sphere((lx, ly, lz), (0.17, 0.17, 0.19), "gold", uv, u_segs=14, v_segs=10)

    # ARMS (expressive pose matching upgrade-variants!)
    # LEFT ARM (+X): hand confidently resting on hip
    l_sh = (1.16, 0.0, 4.10)
    l_elb = (1.66, -0.05, 3.40)
    l_wri = (1.22, -0.18, 2.82)
    torso.sphere(l_sh, (0.37, 0.37, 0.37), "shirt_cream", uv)
    torso.capsule(l_sh, (1.48, -0.03, 3.64), 0.33, "shirt_cream", uv, r1=0.31)
    torso.cylinder((1.50, -0.04, 3.60), 0.36, 0.36, 0.22, "shirt_cream", uv, rot=(0, -35, 0), bevel=0.05)
    torso.capsule((1.54, -0.05, 3.52), l_elb, 0.24, "skin", uv, r1=0.23)
    torso.capsule(l_elb, l_wri, 0.23, "skin", uv, r1=0.21)
    torso.sphere((1.12, -0.22, 2.78), (0.26, 0.24, 0.26), "skin", uv)
    torso.sphere((1.05, -0.34, 2.86), (0.11, 0.10, 0.11), "skin", uv)

    # RIGHT ARM (-X): holding fishing rod planted outside silhouette
    r_sh = (-1.16, 0.0, 4.10)
    r_elb = (-1.58, -0.16, 3.44)
    r_hand = (-1.46, -0.52, 3.52)
    torso.sphere(r_sh, (0.37, 0.37, 0.37), "shirt_cream", uv)
    torso.capsule(r_sh, (-1.44, -0.10, 3.66), 0.33, "shirt_cream", uv, r1=0.31)
    torso.cylinder((-1.46, -0.11, 3.62), 0.36, 0.36, 0.22, "shirt_cream", uv, rot=(0, 32, 0), bevel=0.05)
    torso.capsule((-1.48, -0.12, 3.56), r_elb, 0.24, "skin", uv, r1=0.23)
    torso.capsule(r_elb, r_hand, 0.23, "skin", uv, r1=0.22)
    torso.sphere(r_hand, (0.27, 0.27, 0.27), "skin", uv)
    torso.sphere((-1.32, -0.68, 3.62), (0.12, 0.11, 0.12), "skin", uv)

    # =========================================================================
    # 3. FISHING ROD + REPAIRS + LURE (held in right hand, planted on ground!)
    # =========================================================================
    rod_bot = Vector((-1.26, -0.45, 0.06))
    rod_top = Vector((-1.92, -0.60, 5.95))
    torso.capsule(rod_bot, rod_top, 0.095, "rod_wood", uv, r1=0.048, segs=14)
    for t_wrap in (0.38, 0.72, 0.87):
        wp = rod_bot.lerp(rod_top, t_wrap)
        rod_dir = (rod_top - rod_bot).normalized()
        w_start = wp - rod_dir * 0.14
        w_end = wp + rod_dir * 0.14
        r_shaft = 0.095 + (0.048 - 0.095) * t_wrap
        torso.capsule(w_start, w_end, r_shaft + 0.022, "rod_wrap", uv, r1=r_shaft + 0.022, segs=12)
    glow_cyan.sphere(rod_top + Vector((-0.02, -0.01, 0.08)), (0.14, 0.14, 0.14), "hat_stitch", uv, u_segs=14, v_segs=10)

    reel_p = rod_bot.lerp(rod_top, 0.20)
    torso.cylinder(reel_p + Vector((-0.14, 0.0, 0.0)), 0.18, 0.18, 0.14, "metal_steel", uv, rot=(0, 90, 0), bevel=0.03)
    torso.cylinder(reel_p + Vector((-0.14, 0.0, 0.0)), 0.12, 0.12, 0.18, "rod_wrap", uv, rot=(0, 90, 0), bevel=0.02)

    line_top = rod_bot.lerp(rod_top, 0.96)
    lure_pos = line_top + Vector((-0.24, -0.02, -0.95))
    torso.tube([line_top, line_top + Vector((-0.22, -0.02, -0.18)), lure_pos + Vector((0, 0, 0.22))], 0.014, "rod_wrap", uv, segs=6)
    torso.sphere(lure_pos, (0.11, 0.09, 0.22), "lure_blue", uv)
    torso.sphere(lure_pos + Vector((0.0, 0.0, -0.02)), (0.118, 0.095, 0.08), "lure_gold", uv)
    hook_pts = [
        lure_pos + Vector((0, 0, -0.22)),
        lure_pos + Vector((0, 0, -0.34)),
        lure_pos + Vector((-0.08, 0, -0.38)),
        lure_pos + Vector((-0.12, 0, -0.30)),
    ]
    torso.tube(hook_pts, 0.018, "leather_dark", uv, segs=6)

    # =========================================================================
    # 4. HEAD, FACE, CLOUD BEARD, MUSTACHE & STRAW HAT (Z = 4.65 -> 6.50)
    # =========================================================================
    hc = Vector((0.0, 0.0, 5.14))
    head.sphere(hc, (0.76, 0.72, 0.72), "skin", uv, u_segs=24, v_segs=18)

    for side in (-1, 1):
        head.sphere((side * 0.77, 0.02, 5.10), (0.15, 0.17, 0.21), "skin", uv)

    head.sphere((0.0, -0.73, 5.12), (0.17, 0.16, 0.15), "nose", uv, u_segs=16, v_segs=12)

    for side in (-1, 1):
        ex = side * 0.28
        head.sphere((ex, -0.66, 5.23), (0.095, 0.075, 0.11), "eye_dark", uv, u_segs=14, v_segs=10)
        head.sphere((ex - 0.032, -0.725, 5.27), (0.032, 0.025, 0.032), "eye_white", uv, u_segs=10, v_segs=8)
        head.rounded_box(
            (side * 0.30, -0.66, 5.42),
            (0.36, 0.13, 0.14),
            "white_hair",
            uv,
            rot=(0, -side * 10.0, side * 12.0),
            bevel=0.04,
            segments=2,
        )
        for dz_i in (-0.03, 0.04):
            p_a = (side * 0.48, -0.58, 5.14 + dz_i)
            p_b = (side * 0.56, -0.53, 5.12 + dz_i - 0.02)
            head.tube([p_a, p_b], 0.015, "cheek_line", uv, segs=6)

    # Clear warm smile tucked right below mustache wings
    head.smile_arc((0.0, -0.82, 4.90), width=0.28, depth_y=0.04, drop_z=0.085, thickness=0.032, swatch="smile_dark", uv_cells=uv)

    for side in (-1, 1):
        m_pts = [
            (side * 0.07, -0.76, 5.02),
            (side * 0.25, -0.78, 5.01),
            (side * 0.45, -0.71, 4.96),
            (side * 0.58, -0.61, 5.03),
            (side * 0.50, -0.62, 5.12),
        ]
        m_rads = [0.115, 0.145, 0.145, 0.11, 0.07]
        head.tube(m_pts, m_rads, "white_hair", uv, segs=12)

    beard_puffs = [
        ((0.00, -0.66, 4.58), (0.27, 0.25, 0.25)),
        ((-0.26, -0.62, 4.66), (0.25, 0.24, 0.24)),
        ((0.26, -0.62, 4.66), (0.25, 0.24, 0.24)),
        ((-0.46, -0.50, 4.78), (0.24, 0.23, 0.24)),
        ((0.46, -0.50, 4.78), (0.24, 0.23, 0.24)),
        ((-0.56, -0.34, 4.90), (0.22, 0.22, 0.22)),
        ((0.56, -0.34, 4.90), (0.22, 0.22, 0.22)),
        ((-0.16, -0.54, 4.46), (0.22, 0.22, 0.21)),
        ((0.16, -0.54, 4.46), (0.22, 0.22, 0.21)),
        ((0.00, -0.45, 4.54), (0.36, 0.28, 0.24)),
    ]
    for pos, rad in beard_puffs:
        head.sphere(pos, rad, "white_hair", uv, u_segs=14, v_segs=10)

    for side in (-1, 1):
        head.sphere((side * 0.67, -0.14, 5.26), (0.16, 0.20, 0.25), "white_hair", uv)
        head.sphere((side * 0.66, 0.14, 5.14), (0.18, 0.24, 0.24), "white_hair", uv)
        head.sphere((side * 0.44, 0.54, 5.06), (0.28, 0.26, 0.26), "white_shade", uv)
    head.sphere((0.0, 0.60, 5.08), (0.48, 0.32, 0.34), "white_shade", uv)
    head.sphere((0.0, 0.56, 4.92), (0.36, 0.26, 0.24), "white_hair", uv)

    # --- GOLDEN STRAW FISHERMAN HAT WITH WAVY BRIM, NAVY BAND, BLUE X & VISIBLE PATCH ---
    hat_c = (0.0, 0.04, 5.64)

    def brim_wave(theta, idx, r, z):
        if r < 0.85:
            return (0.0, 0.0)
        strength = (r - 0.85) / 0.68
        # Classic droopy wavy fishing hat brim (higher in front, softly dipped on sides)
        dz = (-0.11 * math.cos(2.0 * theta) - 0.055 * math.sin(theta) + 0.03 * math.sin(3.0 * theta)) * strength
        return (0.0, dz)

    hat_profile = [
        (0.70, -0.05),
        (1.06, -0.07),
        (1.44, -0.14),
        (1.52, -0.09),
        (1.50, -0.01),
        (1.38, 0.05),
        (1.02, 0.10),
        (0.84, 0.17),
        (0.82, 0.39),
        (0.76, 0.67),
        (0.62, 0.85),
        (0.36, 0.93),
        (0.02, 0.95),
    ]
    head.lathe(hat_c, hat_profile, "hat_straw", uv, rot=(-6.0, 0.0, 0.0), segs=36, wave_fn=brim_wave, scale_xy=(1.04, 0.98))

    band_profile = [
        (0.855, 0.17),
        (0.865, 0.26),
        (0.850, 0.37),
        (0.830, 0.39),
    ]
    head.lathe(hat_c, band_profile, "hat_band", uv, rot=(-6.0, 0.0, 0.0), segs=36, scale_xy=(1.04, 0.98))
    head.rounded_box((0.46, -0.74, 5.90), (0.14, 0.10, 0.26), "hat_band_dark", uv, rot=(-6, 0, -28), bevel=0.025)

    head.capsule((-0.34, -0.78, 6.14), (-0.18, -0.81, 6.20), 0.028, "hat_stitch", uv)
    head.capsule((-0.32, -0.79, 6.21), (-0.20, -0.80, 6.13), 0.028, "hat_stitch", uv)

    # Clearly visible stitched leather mend on top of left brim edge!
    head.rounded_box((1.06, -0.68, 5.71), (0.48, 0.38, 0.09), "hat_patch", uv, rot=(14, 16, -34), bevel=0.025, proj="top")

    objs = [
        legs.to_object(atlas_mat),
        torso.to_object(atlas_mat),
        head.to_object(atlas_mat),
        glow_cyan.to_object(mat_glow_cyan),
        glow_amber.to_object(mat_glow_amber),
    ]
    ground_and_scale(objs, target_height=6.46, measure_names={"Legs", "Torso", "Head"})

    out_dir.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(out_dir / "vo_anzol.blend"))
    export_glb(out_dir / "vo_anzol.glb", objs)

    stats = report_stats("VoAnzol", objs)
    (out_dir / "report.json").write_text(json.dumps(stats, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(stats, indent=2), flush=True)

    if render:
        render_review_views(out_dir / "views", objs, head_z_hint=5.15, size=768)


if __name__ == "__main__":
    no_render = "--no-render" in sys.argv
    out_path = Path(r"c:\Users\Evojota\dev\jogo ainda sem nome\art\npcs\exports\vo_anzol")
    build_vo_anzol(out_path, render=not no_render)
