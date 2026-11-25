"""Shared high-craft 3D modeling, atlas painting, studio rendering and GLB export
toolkit for Legendary Catch NPCs (Blender 5.3 headless).

Coordinate convention in Blender:
  - 1 unit = 1 stud
  - Ground at Z = 0, Up = +Z
  - Character Front = -Y (exports to Roblox +Z with glTF Y-up!)
  - Character's Right = -X (viewer's left when looking at front)
  - Character's Left  = +X (viewer's right when looking at front)
"""

import json
import math
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Euler, Matrix, Vector


# ---------------------------------------------------------------------------
# Color & Atlas Painting (1024x1024 tiled procedural painted atlas)
# ---------------------------------------------------------------------------

def hex_to_srgb(hex_str: str) -> np.ndarray:
    h = hex_str.lstrip("#")
    return np.array([int(h[0:2], 16) / 255.0, int(h[2:4], 16) / 255.0, int(h[4:6], 16) / 255.0], dtype=np.float32)


def _blend(base: np.ndarray, col, mask: np.ndarray):
    a = np.clip(mask, 0.0, 1.0)[..., None]
    base[:] = base * (1.0 - a) + np.asarray(col, dtype=np.float32) * a


def _paint_tile(tile_px: int, hex_color: str, style: str, rng: np.random.Generator) -> np.ndarray:
    """Paint a rich stylized candy-toy swatch tile in sRGB [0..1]."""
    base_col = hex_to_srgb(hex_color)
    coords = np.linspace(0.0, 1.0, tile_px, dtype=np.float32)
    u, v = np.meshgrid(coords, coords)
    # Soft toy vertical gradient (slightly warmer/brighter on top, cooler shadow at bottom)
    grad = 0.90 + 0.14 * v + 0.03 * np.cos(math.tau * u)
    img = np.clip(base_col[None, None, :] * grad[:, :, None], 0.0, 1.0).copy()
    noise = (rng.random((tile_px, tile_px), dtype=np.float32) - 0.5) * 0.025

    if style == "solid":
        img += noise[:, :, None] * 0.4
    elif style == "skin":
        # Ultra-clean vinyl peach with warm top highlight
        soft = 0.94 + 0.08 * v
        img = np.clip(base_col[None, None, :] * soft[:, :, None], 0.0, 1.0)
        img += noise[:, :, None] * 0.25
    elif style == "straw":
        # Woven straw hat texture
        weave_h = 0.055 * np.sin(18.0 * math.tau * v)
        weave_v = 0.035 * np.sin(24.0 * math.tau * u + 1.5 * np.floor(18.0 * v))
        img += (weave_h + weave_v + noise * 1.1)[:, :, None]
    elif style == "knit":
        # Soft ribbed knit sweater/sleeves
        rib = 0.042 * np.sin(16.0 * math.tau * u) + 0.02 * np.sin(22.0 * math.tau * v)
        img += (rib + noise * 0.8)[:, :, None]
    elif style == "fabric":
        # Subtle woven cloth crosshatch
        weave = 0.026 * np.sin(26.0 * math.tau * u) * np.sin(26.0 * math.tau * v)
        img += (weave + noise * 0.9)[:, :, None]
    elif style == "denim":
        # Diagonal twill fabric
        twill = 0.032 * np.sin(24.0 * math.tau * (u + v * 0.7))
        img += (twill + noise * 0.9)[:, :, None]
    elif style == "leather":
        # Fine leather pebble + warm sheen
        grain = 0.03 * np.sin(20.0 * math.tau * u) * np.cos(18.0 * math.tau * v) + noise * 1.3
        img += grain[:, :, None]
    elif style == "wood":
        # Warm crafted honey wood planks with grain
        grain = 0.055 * np.sin(10.0 * math.tau * v + 1.4 * np.sin(2.0 * math.tau * u))
        grain += 0.025 * np.sin(24.0 * math.tau * v + 0.6 * np.cos(3.0 * math.tau * u))
        img += (grain + noise * 0.8)[:, :, None]
    elif style == "wood_plank":
        # Wood with horizontal plank seams
        grain = 0.05 * np.sin(12.0 * math.tau * v + 1.2 * np.sin(2.0 * math.tau * u))
        seams = np.exp(-((np.abs((v * 3.0) % 1.0 - 0.5) - 0.5) / 0.035) ** 2)
        img += (grain - 0.16 * seams + noise * 0.7)[:, :, None]
    elif style == "hair":
        # Smooth stylized hair strands
        strands = 0.045 * np.sin(12.0 * math.tau * u + 0.5 * np.sin(math.tau * v))
        img += (strands + noise * 0.4)[:, :, None]
    elif style == "metal":
        # Polished stylized gold/brass sheen
        sheen = 0.12 * np.exp(-((v - 0.68) / 0.16) ** 2) - 0.08 * np.exp(-((v - 0.2) / 0.14) ** 2)
        img += sheen[:, :, None]
    elif style == "pocket_x":
        # Leather pocket with stitched border and X cross-stitching (Vo Anzol)
        img += (noise * 1.1)[:, :, None]
        stitch_col = hex_to_srgb("#F5DFB0")
        # Border dashed frame
        border_m = (
            ((np.abs(u - 0.12) < 0.022) | (np.abs(u - 0.88) < 0.022)) & (v > 0.10) & (v < 0.90)
            | ((np.abs(v - 0.12) < 0.022) | (np.abs(v - 0.88) < 0.022)) & (u > 0.10) & (u < 0.90)
        )
        dash = (np.sin(20.0 * math.tau * (u + v)) > -0.15)
        # X cross inside
        diag1 = np.abs((u - 0.5) - (v - 0.5)) < 0.024
        diag2 = np.abs((u - 0.5) + (v - 0.5)) < 0.024
        inner = (u > 0.18) & (u < 0.82) & (v > 0.18) & (v < 0.82)
        x_dash = (np.sin(22.0 * math.tau * u) > -0.2)
        mask = ((border_m & dash) | ((diag1 | diag2) & inner & x_dash)).astype(np.float32)
        _blend(img, stitch_col, mask * 0.92)
    elif style == "patch":
        # Patched straw hat leather patch with cream edge stitches
        img += (noise * 1.2)[:, :, None]
        stitch_col = hex_to_srgb("#FFF2D0")
        edge = (
            ((np.abs(u - 0.09) < 0.03) | (np.abs(u - 0.91) < 0.03))
            | ((np.abs(v - 0.09) < 0.03) | (np.abs(v - 0.91) < 0.03))
        )
        dash = (np.sin(10.0 * math.tau * (u + v)) > 0.1)
        _blend(img, stitch_col, (edge & dash).astype(np.float32) * 0.95)
    elif style == "coral_pocket":
        # Lucy's coral apron pocket with gold dashed stitching
        img += (noise * 0.6)[:, :, None]
        gold = hex_to_srgb("#FFD25A")
        border_m = (
            ((np.abs(u - 0.11) < 0.026) | (np.abs(u - 0.89) < 0.026)) & (v > 0.09) & (v < 0.88)
            | ((np.abs(v - 0.11) < 0.026)) & (u > 0.09) & (u < 0.91)
        )
        dash = np.sin(18.0 * math.tau * (u + v)) > -0.1
        _blend(img, gold, (border_m & dash).astype(np.float32) * 0.95)
    elif style == "scallop":
        # Pink coral scallop shell with radial ribs and cream outer edge
        ribs = 0.11 * np.cos(7.0 * math.pi * u)
        img += (ribs + noise * 0.4)[:, :, None]
        rim = np.clip((v - 0.80) * 8.0, 0.0, 1.0)
        _blend(img, hex_to_srgb("#FFEED6"), rim * 0.85)
    elif style == "nautilus":
        # Golden nautilus shell with warm amber wavy stripes
        wave = np.sin(8.0 * math.tau * u + 1.2 * np.sin(3.0 * math.tau * v))
        stripe = np.clip((wave - 0.25) * 4.0, 0.0, 1.0)
        _blend(img, hex_to_srgb("#E07818"), stripe * 0.85)
    elif style == "starfish":
        # Coral starfish with tiny pale cream dots
        img += (noise * 0.6)[:, :, None]
        dots = np.zeros_like(u)
        for du, dv in [(0.3, 0.3), (0.7, 0.3), (0.5, 0.7), (0.35, 0.62), (0.65, 0.62), (0.5, 0.25)]:
            dots += np.exp(-((u - du) ** 2 + (v - dv) ** 2) / (0.045 ** 2))
        _blend(img, hex_to_srgb("#FFDCC8"), np.clip(dots, 0.0, 1.0) * 0.75)
    elif style == "sand":
        # Warm golden beach sand with subtle grain
        speck = (rng.random((tile_px, tile_px), dtype=np.float32) - 0.5) * 0.07
        img += speck[:, :, None]
    elif style == "neon":
        # Pure bright saturated color for Neon glowing elements
        img[:] = base_col[None, None, :]
    elif style == "glass":
        # Soft pale sky tint for glass jars
        img[:] = base_col[None, None, :]

    return np.clip(img, 0.0, 1.0)


def build_atlas(path: Path, palette: dict, size: int = 1024):
    """Build a tiled PNG texture atlas and a Blender Principled BSDF material.

    palette: { swatch_name: (hex_color, style) }
    Returns (material, uv_cells) where uv_cells[name] = (u0, v0, du, dv).
    """
    n = len(palette)
    cols = max(4, math.ceil(math.sqrt(n)))
    tile = size // cols
    pad = max(6, tile // 14)

    pixels = np.ones((size, size, 4), dtype=np.float32)
    uv_cells = {}
    rng = np.random.default_rng(2026)

    for idx, (name, (hex_col, style)) in enumerate(palette.items()):
        cx = (idx % cols) * tile
        cy = (idx // cols) * tile
        painted = _paint_tile(tile, hex_col, style, rng)
        pixels[cy:cy + tile, cx:cx + tile, :3] = painted
        # UV coordinates in [0..1] (Blender image origin is bottom-left, matching numpy row 0!)
        u0 = (cx + pad) / size
        v0 = (cy + pad) / size
        span = (tile - 2 * pad) / size
        uv_cells[name] = (u0, v0, span, span)

    path.parent.mkdir(parents=True, exist_ok=True)
    img = bpy.data.images.new(path.name, width=size, height=size, alpha=False)
    img.colorspace_settings.name = "sRGB"
    img.pixels.foreach_set(pixels.ravel())
    img.file_format = "PNG"
    img.filepath_raw = str(path)
    img.save()
    img.pack()

    mat = bpy.data.materials.new(path.stem)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = 0.42
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.35
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = img
    nodes.active = tex
    links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    return mat, uv_cells


def build_solid_material(name: str, hex_color: str, roughness: float = 0.35, alpha: float = 1.0, emission: float = 0.0):
    """Build a standalone Principled BSDF material (for Glass or Neon meshes)."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    srgb = hex_to_srgb(hex_color)
    # Convert sRGB to linear for Principled BSDF
    lin = tuple(float(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4) for c in srgb)
    bsdf.inputs["Base Color"].default_value = (*lin, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    if alpha < 1.0:
        bsdf.inputs["Alpha"].default_value = alpha
        if hasattr(mat, "blend_method"):
            mat.blend_method = "BLEND"
    if emission > 0.0 and "Emission Color" in bsdf.inputs:
        bsdf.inputs["Emission Color"].default_value = (*lin, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission
    return mat


# ---------------------------------------------------------------------------
# High-Craft Stylized BMesh Builder
# ---------------------------------------------------------------------------

class PartBuilder:
    """Accumulates smooth beveled / organic primitives into a single named Mesh Object."""

    def __init__(self, name: str, origin=(0.0, 0.0, 0.0)):
        self.name = name
        self.origin = Vector(origin)
        self.bm = bmesh.new()
        self.uv_layer = self.bm.loops.layers.uv.new("UVMap")
        self._face_swatches = []  # (bmface, swatch_name)

    def _to_local(self, mat: Matrix) -> Matrix:
        return Matrix.Translation(-self.origin) @ mat

    def _assign_uv_planar_or_box(self, faces, swatch: str, uv_cells: dict, proj: str = "box"):
        u0, v0, du, dv = uv_cells[swatch]
        for f in faces:
            n = f.normal
            ax, ay, az = abs(n.x), abs(n.y), abs(n.z)
            # Compute local face bounds for nice normalized UVs
            coords = []
            for loop in f.loops:
                co = loop.vert.co
                if proj == "front":
                    coords.append((co.x, co.z))
                elif proj == "cyl":
                    ang = (math.atan2(co.y, co.x) / math.tau) % 1.0
                    coords.append((ang, co.z))
                else:
                    if az >= ax and az >= ay:
                        coords.append((co.x, co.y))
                    elif ay >= ax:
                        coords.append((co.x, co.z))
                    else:
                        coords.append((co.y, co.z))
            xs = [c[0] for c in coords]
            ys = [c[1] for c in coords]
            min_x, max_x = min(xs), max(xs)
            min_y, max_y = min(ys), max(ys)
            sx = max(max_x - min_x, 1e-4)
            sy = max(max_y - min_y, 1e-4)
            for loop, (lx, ly) in zip(f.loops, coords):
                lu = (lx - min_x) / sx
                lv = (ly - min_y) / sy
                loop[self.uv_layer].uv = (u0 + lu * du, v0 + lv * dv)

    def _finish_submesh(self, sub_bm: bmesh.types.BMesh, swatch: str, uv_cells: dict, smooth: bool = True, proj: str = "box"):
        # Compute UVs on sub_bm before merging, using its bounding box for smooth continuity!
        uv_layer = sub_bm.loops.layers.uv.verify()
        u0, v0, du, dv = uv_cells[swatch]
        verts = list(sub_bm.verts)
        if not verts:
            sub_bm.free()
            return
        xs = [v.co.x for v in verts]
        ys = [v.co.y for v in verts]
        zs = [v.co.z for v in verts]
        min_x, max_x = min(xs), max(xs)
        min_y, max_y = min(ys), max(ys)
        min_z, max_z = min(zs), max(zs)
        cx, cy = (min_x + max_x) * 0.5, (min_y + max_y) * 0.5
        rx = max(max_x - min_x, 1e-4)
        ry = max(max_y - min_y, 1e-4)
        rz = max(max_z - min_z, 1e-4)

        bmesh.ops.recalc_face_normals(sub_bm, faces=sub_bm.faces)
        for f in sub_bm.faces:
            f.smooth = smooth
            n = f.normal
            ax, ay, az = abs(n.x), abs(n.y), abs(n.z)
            for loop in f.loops:
                co = loop.vert.co
                if proj == "front":
                    lu = (co.x - min_x) / rx
                    lv = (co.z - min_z) / rz
                elif proj == "cyl":
                    lu = (math.atan2(co.y - cy, co.x - cx) / math.tau) % 1.0
                    lv = (co.z - min_z) / rz
                elif proj == "top":
                    lu = (co.x - min_x) / rx
                    lv = (co.y - min_y) / ry
                else:
                    if az >= ax and az >= ay:
                        lu = (co.x - min_x) / rx
                        lv = (co.y - min_y) / ry
                    elif ay >= ax:
                        lu = (co.x - min_x) / rx
                        lv = (co.z - min_z) / rz
                    else:
                        lu = (co.y - min_y) / ry
                        lv = (co.z - min_z) / rz
                loop[uv_layer].uv = (u0 + np.clip(lu, 0.0, 1.0) * du, v0 + np.clip(lv, 0.0, 1.0) * dv)

        # Merge sub_bm into self.bm (preserving UVs)
        v_map = {}
        for v in sub_bm.verts:
            v_map[v.index] = self.bm.verts.new(v.co)
        sub_bm.verts.index_update()
        for f in sub_bm.faces:
            try:
                nf = self.bm.faces.new([v_map[v.index] for v in f.verts])
                nf.smooth = f.smooth
                for src_l, dst_l in zip(f.loops, nf.loops):
                    dst_l[self.uv_layer].uv = src_l[uv_layer].uv
            except ValueError:
                pass
        sub_bm.free()

    def _xform(self, center, rot=(0.0, 0.0, 0.0), scale=(1.0, 1.0, 1.0)) -> Matrix:
        m_t = Matrix.Translation(Vector(center) - self.origin)
        m_r = Euler(tuple(math.radians(a) for a in rot), "XYZ").to_matrix().to_4x4()
        m_s = Matrix.Diagonal((scale[0], scale[1], scale[2], 1.0))
        return m_t @ m_r @ m_s

    def rounded_box(self, center, size, swatch, uv_cells, rot=(0, 0, 0), bevel=0.06, segments=3, proj="box", taper_top=1.0):
        """Soft beveled toy block with optional top taper."""
        sub = bmesh.new()
        bmesh.ops.create_cube(sub, size=1.0)
        sx, sy, sz = size
        for v in sub.verts:
            v.co.x *= sx
            v.co.y *= sy
            v.co.z *= sz
            if taper_top != 1.0 and v.co.z > 0:
                v.co.x *= taper_top
                v.co.y *= taper_top
        max_b = min(sx, sy, sz) * 0.45
        b = min(bevel, max_b)
        if b > 1e-4:
            bmesh.ops.bevel(
                sub,
                geom=list(sub.edges),
                offset=b,
                segments=segments,
                profile=0.5,
                affect="EDGES",
                clamp_overlap=True,
            )
        bmesh.ops.transform(sub, matrix=self._xform(center, rot), verts=sub.verts)
        self._finish_submesh(sub, swatch, uv_cells, smooth=True, proj=proj)

    def sphere(self, center, radii, swatch, uv_cells, rot=(0, 0, 0), u_segs=20, v_segs=14, proj="cyl"):
        """Smooth ellipsoid."""
        sub = bmesh.new()
        bmesh.ops.create_uvsphere(sub, u_segments=u_segs, v_segments=v_segs, radius=1.0)
        rx, ry, rz = radii
        for v in sub.verts:
            v.co.x *= rx
            v.co.y *= ry
            v.co.z *= rz
        bmesh.ops.transform(sub, matrix=self._xform(center, rot), verts=sub.verts)
        self._finish_submesh(sub, swatch, uv_cells, smooth=True, proj=proj)

    def cylinder(self, center, r_bot, r_top, height, swatch, uv_cells, rot=(0, 0, 0), segs=22, bevel=0.03, proj="cyl"):
        """Smooth capped cylinder/frustum with optional rim bevel."""
        sub = bmesh.new()
        bmesh.ops.create_cone(
            sub,
            cap_ends=True,
            cap_tris=False,
            segments=segs,
            radius1=r_bot,
            radius2=r_top,
            depth=height,
        )
        if bevel > 1e-4:
            rim_edges = [e for e in sub.edges if abs(e.verts[0].co.z - e.verts[1].co.z) < 1e-4]
            if rim_edges:
                bmesh.ops.bevel(
                    sub,
                    geom=rim_edges,
                    offset=min(bevel, height * 0.35, min(r_bot, r_top) * 0.45),
                    segments=2,
                    profile=0.5,
                    affect="EDGES",
                    clamp_overlap=True,
                )
        bmesh.ops.transform(sub, matrix=self._xform(center, rot), verts=sub.verts)
        self._finish_submesh(sub, swatch, uv_cells, smooth=True, proj=proj)

    def capsule(self, p0, p1, radius, swatch, uv_cells, r1=None, segs=16, rings=5, proj="cyl"):
        """Smooth capsule / tapered limb connecting p0 to p1."""
        v0, v1 = Vector(p0), Vector(p1)
        r0 = radius
        r_end = radius if r1 is None else r1
        axis = v1 - v0
        length = axis.length
        if length < 1e-5:
            self.sphere(p0, (r0, r0, r0), swatch, uv_cells)
            return
        z_dir = axis.normalized()
        up = Vector((0, 0, 1)) if abs(z_dir.z) < 0.9 else Vector((1, 0, 0))
        x_dir = up.cross(z_dir).normalized()
        y_dir = z_dir.cross(x_dir).normalized()

        sub = bmesh.new()
        profile = []
        # Bottom hemisphere
        for i in range(rings):
            ang = -math.pi * 0.5 + (math.pi * 0.5) * (i / rings)
            profile.append((math.cos(ang) * r0, math.sin(ang) * r0))
        # Mid shaft rings
        profile.append((r0, 0.0))
        profile.append(((r0 + r_end) * 0.5, length * 0.5))
        profile.append((r_end, length))
        # Top hemisphere
        for i in range(1, rings + 1):
            ang = (math.pi * 0.5) * (i / rings)
            profile.append((math.cos(ang) * r_end, length + math.sin(ang) * r_end))

        ring_verts = []
        for rad, z_off in profile:
            rv = []
            for s in range(segs):
                th = math.tau * s / segs
                pt = v0 + z_dir * z_off + (x_dir * math.cos(th) + y_dir * math.sin(th)) * max(rad, 1e-4) - self.origin
                rv.append(sub.verts.new(pt))
            ring_verts.append(rv)

        for j in range(len(ring_verts) - 1):
            r_a, r_b = ring_verts[j], ring_verts[j + 1]
            for s in range(segs):
                sn = (s + 1) % segs
                try:
                    sub.faces.new((r_a[s], r_a[sn], r_b[sn], r_b[s]))
                except ValueError:
                    pass
        # Cap ends if non-degenerate
        try:
            sub.faces.new(list(reversed(ring_verts[0])))
        except ValueError:
            pass
        try:
            sub.faces.new(ring_verts[-1])
        except ValueError:
            pass

        self._finish_submesh(sub, swatch, uv_cells, smooth=True, proj=proj)

    def tube(self, points, radii, swatch, uv_cells, segs=14, closed=False, cap_ends=True, proj="cyl"):
        """Smooth swept tube along 3D polyline with variable radius (for smiles, handles, braids, ropes, worms)."""
        pts = [Vector(p) for p in points]
        if isinstance(radii, (int, float)):
            rads = [float(radii)] * len(pts)
        else:
            rads = list(radii)

        sub = bmesh.new()
        rings = []
        prev_x = None
        n = len(pts)
        for i, p in enumerate(pts):
            if closed:
                t = (pts[(i + 1) % n] - pts[(i - 1) % n]).normalized()
            elif i == 0:
                t = (pts[1] - pts[0]).normalized()
            elif i == n - 1:
                t = (pts[-1] - pts[-2]).normalized()
            else:
                t = (pts[i + 1] - pts[i - 1]).normalized()

            if prev_x is None:
                ref = Vector((0, 0, 1)) if abs(t.z) < 0.9 else Vector((1, 0, 0))
                x_dir = ref.cross(t).normalized()
            else:
                x_dir = (prev_x - t * prev_x.dot(t))
                if x_dir.length < 1e-4:
                    ref = Vector((0, 0, 1)) if abs(t.z) < 0.9 else Vector((1, 0, 0))
                    x_dir = ref.cross(t).normalized()
                else:
                    x_dir.normalize()
            y_dir = t.cross(x_dir).normalized()
            prev_x = x_dir

            r = rads[i]
            rv = []
            for s in range(segs):
                th = math.tau * s / segs
                co = p + (x_dir * math.cos(th) + y_dir * math.sin(th)) * r - self.origin
                rv.append(sub.verts.new(co))
            rings.append(rv)

        ring_count = n if closed else n - 1
        for j in range(ring_count):
            ra = rings[j]
            rb = rings[(j + 1) % n]
            for s in range(segs):
                sn = (s + 1) % segs
                try:
                    sub.faces.new((ra[s], ra[sn], rb[sn], rb[s]))
                except ValueError:
                    pass

        if not closed and cap_ends:
            # Rounded cap tips
            p_start = pts[0] - (pts[1] - pts[0]).normalized() * (rads[0] * 0.7) - self.origin
            v_start = sub.verts.new(p_start)
            for s in range(segs):
                sn = (s + 1) % segs
                try:
                    sub.faces.new((v_start, rings[0][sn], rings[0][s]))
                except ValueError:
                    pass
            p_end = pts[-1] + (pts[-1] - pts[-2]).normalized() * (rads[-1] * 0.7) - self.origin
            v_end = sub.verts.new(p_end)
            for s in range(segs):
                sn = (s + 1) % segs
                try:
                    sub.faces.new((v_end, rings[-1][s], rings[-1][sn]))
                except ValueError:
                    pass

        self._finish_submesh(sub, swatch, uv_cells, smooth=True, proj=proj)

    def torus(self, center, major_r, minor_r, swatch, uv_cells, rot=(0, 0, 0), major_segs=28, minor_segs=12, scale_xyz=(1, 1, 1), proj="cyl"):
        """Smooth torus ring (belts, hat bands, bucket hoops, cuffs, handles)."""
        pts = []
        m = self._xform(center, rot, scale_xyz)
        for i in range(major_segs):
            th = math.tau * i / major_segs
            local_p = Vector((math.cos(th) * major_r, math.sin(th) * major_r, 0.0))
            pts.append(m @ local_p + self.origin)
        self.tube(pts, minor_r, swatch, uv_cells, segs=minor_segs, closed=True, proj=proj)

    def lathe(self, center, profile_rz, swatch, uv_cells, rot=(0, 0, 0), segs=32, wave_fn=None, scale_xy=(1.0, 1.0), proj="cyl"):
        """Surface of revolution around local Z axis.
        profile_rz: list of (radius, z) tuples.
        wave_fn: optional callable(theta, idx, r, z) -> (dr, dz) for wavy hat brims!
        """
        sub = bmesh.new()
        m = self._xform(center, rot)
        rings = []
        for idx, (r, z) in enumerate(profile_rz):
            rv = []
            for s in range(segs):
                th = math.tau * s / segs
                dr, dz = (0.0, 0.0) if wave_fn is None else wave_fn(th, idx, r, z)
                rr = max(r + dr, 1e-4)
                lx = math.cos(th) * rr * scale_xy[0]
                ly = math.sin(th) * rr * scale_xy[1]
                lz = z + dz
                rv.append(sub.verts.new(m @ Vector((lx, ly, lz))))
            rings.append(rv)

        for j in range(len(rings) - 1):
            ra, rb = rings[j], rings[j + 1]
            for s in range(segs):
                sn = (s + 1) % segs
                try:
                    sub.faces.new((ra[s], ra[sn], rb[sn], rb[s]))
                except ValueError:
                    pass
        # Cap bottom & top if open
        if profile_rz[0][0] > 0.01:
            try:
                sub.faces.new(list(reversed(rings[0])))
            except ValueError:
                pass
        if profile_rz[-1][0] > 0.01:
            try:
                sub.faces.new(rings[-1])
            except ValueError:
                pass
        self._finish_submesh(sub, swatch, uv_cells, smooth=True, proj=proj)

    def smile_arc(self, center, width, depth_y, drop_z, thickness, swatch, uv_cells, rot=(0, 0, 0), steps=11):
        """Cute curved 3D smile arc facing -Y."""
        m = self._xform(center, rot)
        pts = []
        for i in range(steps):
            t = -1.0 + 2.0 * (i / (steps - 1))
            x = t * width * 0.5
            z = -drop_z * (1.0 - t * t)
            y = depth_y * (t * t)
            pts.append(m @ Vector((x, y, z)) + self.origin)
        self.tube(pts, thickness, swatch, uv_cells, segs=8, closed=False, cap_ends=True)

    def shell_scallop(self, center, scale, swatch, uv_cells, rot=(0, 0, 0)):
        """Sculpted fan-shaped scallop shell with 7 radial ribs (matching shell-scallop.png)."""
        sub = bmesh.new()
        m = self._xform(center, rot, (scale, scale, scale))
        # Build fan from hinge at (0,0,-0.45) fanning up to +Z
        n_ribs = 7
        ang_steps = n_ribs * 4 + 1
        rad_steps = 8
        grid_front = []
        grid_back = []
        for r_i in range(rad_steps):
            rf = r_i / (rad_steps - 1)  # 0 at hinge, 1 at rim
            row_f, row_b = [], []
            for a_i in range(ang_steps):
                af = -1.0 + 2.0 * (a_i / (ang_steps - 1))
                ang = af * math.radians(66)
                rib_wave = 0.5 + 0.5 * math.cos(af * math.pi * n_ribs)
                rim_bump = 1.0 + 0.07 * rib_wave * (rf ** 1.5)
                rad = (0.14 + 0.86 * rf) * rim_bump
                x = math.sin(ang) * rad * 0.62
                z = -0.45 + math.cos(ang) * rad * 0.92
                thick = (0.08 + 0.16 * math.sin(rf * math.pi) + 0.055 * rib_wave * rf)
                y_curve = -0.10 * math.sin(rf * math.pi)
                row_f.append(sub.verts.new(m @ Vector((x, y_curve - thick * 0.65, z))))
                row_b.append(sub.verts.new(m @ Vector((x, y_curve + thick * 0.55, z))))
            grid_front.append(row_f)
            grid_back.append(row_b)

        for r_i in range(rad_steps - 1):
            for a_i in range(ang_steps - 1):
                sub.faces.new((grid_front[r_i][a_i], grid_front[r_i][a_i + 1], grid_front[r_i + 1][a_i + 1], grid_front[r_i + 1][a_i]))
                sub.faces.new((grid_back[r_i][a_i], grid_back[r_i + 1][a_i], grid_back[r_i + 1][a_i + 1], grid_back[r_i][a_i + 1]))
        # Stitch outer rim and sides
        for a_i in range(ang_steps - 1):
            sub.faces.new((grid_front[-1][a_i], grid_front[-1][a_i + 1], grid_back[-1][a_i + 1], grid_back[-1][a_i]))
            sub.faces.new((grid_front[0][a_i + 1], grid_front[0][a_i], grid_back[0][a_i], grid_back[0][a_i + 1]))
        for r_i in range(rad_steps - 1):
            sub.faces.new((grid_front[r_i][0], grid_front[r_i + 1][0], grid_back[r_i + 1][0], grid_back[r_i][0]))
            sub.faces.new((grid_front[r_i + 1][-1], grid_front[r_i][-1], grid_back[r_i][-1], grid_back[r_i + 1][-1]))

        self._finish_submesh(sub, swatch, uv_cells, smooth=True, proj="front")

    def shell_spiral(self, center, scale, swatch, inner_swatch, uv_cells, rot=(0, 0, 0)):
        """Elongated 4-whorl spiral turret shell (matching shell-spiral.png)."""
        m = self._xform(center, rot, (scale, scale, scale))
        pts, rads = [], []
        steps = 44
        for i in range(steps):
            t = i / (steps - 1)
            th = t * 3.6 * math.tau
            r_spiral = 0.24 * (1.0 - t * 0.85)
            z = -0.35 + t * 0.92
            x = math.cos(th) * r_spiral
            y = math.sin(th) * r_spiral
            pts.append(m @ Vector((x, y, z)) + self.origin)
            rads.append(0.24 * (1.0 - t * 0.68) * scale)
        self.tube(pts, rads, swatch, uv_cells, segs=12, closed=False, cap_ends=True)
        # Cream-pink aperture lip at base
        self.sphere(
            (m @ Vector((0.18, -0.14, -0.26)) + self.origin),
            (0.18 * scale, 0.14 * scale, 0.22 * scale),
            inner_swatch, uv_cells, rot=rot
        )

    def shell_conch(self, center, scale, swatch, inner_swatch, uv_cells, rot=(0, 0, 0)):
        """Flared asymmetrical turquoise conch shell (matching shell-conch.png)."""
        m = self._xform(center, rot, (scale, scale, scale))
        # Stacked spiral crown + flared body
        for idx, (z, rx, ry, rz) in enumerate([
            (-0.12, 0.34, 0.28, 0.28),
            (0.10, 0.26, 0.24, 0.20),
            (0.26, 0.18, 0.18, 0.15),
            (0.38, 0.11, 0.11, 0.10),
        ]):
            self.sphere(m @ Vector((0.0, 0.0, z)) + self.origin, (rx * scale, ry * scale, rz * scale), swatch, uv_cells, rot=rot)
        # Flared cream-pearl lip
        self.sphere(m @ Vector((0.20, -0.18, -0.14)) + self.origin, (0.28 * scale, 0.18 * scale, 0.24 * scale), inner_swatch, uv_cells, rot=rot)
        # Soft ridges along back
        for k in range(3):
            ang = math.radians(-30 + k * 35)
            p = m @ Vector((math.cos(ang) * 0.30, math.sin(ang) * 0.26, -0.05 + k * 0.04)) + self.origin
            self.sphere(p, (0.11 * scale, 0.11 * scale, 0.11 * scale), swatch, uv_cells)

    def shell_nautilus(self, center, scale, swatch, uv_cells, rot=(0, 0, 0)):
        """Broad flat curling chambered nautilus shell (matching shell-nautilus.png)."""
        m = self._xform(center, rot, (scale, scale, scale))
        pts, rads = [], []
        steps = 40
        for i in range(steps):
            t = i / (steps - 1)
            th = t * 2.15 * math.tau
            rad_orbit = 0.04 + 0.34 * (t ** 1.25)
            x = math.cos(th) * rad_orbit
            z = math.sin(th) * rad_orbit
            pts.append(m @ Vector((x, 0.0, z)) + self.origin)
            rads.append((0.04 + 0.20 * (t ** 1.3)) * scale)
        self.tube(pts, rads, swatch, uv_cells, segs=14, closed=False, cap_ends=True)

    def starfish(self, center, scale, swatch, eye_swatch, uv_cells, rot=(0, 0, 0)):
        """Chubby sleeping coral starfish on the sand (matching Luna hero/upgrade-variants)."""
        m = self._xform(center, rot, (scale, scale, scale))
        # Center plump body
        self.sphere(m @ Vector((0, 0, 0.10)) + self.origin, (0.28 * scale, 0.28 * scale, 0.16 * scale), swatch, uv_cells, rot=rot)
        # 5 rounded chubby arms
        for k in range(5):
            ang = math.radians(90 + k * 72)
            p0 = m @ Vector((math.cos(ang) * 0.12, math.sin(ang) * 0.12, 0.11)) + self.origin
            p1 = m @ Vector((math.cos(ang) * 0.56, math.sin(ang) * 0.56, 0.08)) + self.origin
            self.capsule(p0, p1, 0.145 * scale, swatch, uv_cells, r1=0.065 * scale, segs=12, rings=4)
        # Cute closed sleepy eyes + tiny smile on top
        for sx in (-0.11, 0.11):
            pts = []
            for i in range(7):
                t = -1.0 + 2.0 * (i / 6.0)
                lx = sx + t * 0.055
                ly = 0.02 - 0.028 * (1.0 - t * t)
                lz = 0.255
                pts.append(m @ Vector((lx, ly, lz)) + self.origin)
            self.tube(pts, 0.015 * scale, eye_swatch, uv_cells, segs=6)
        # Little smile
        spts = []
        for i in range(7):
            t = -1.0 + 2.0 * (i / 6.0)
            lx = t * 0.045
            ly = -0.075 - 0.024 * (1.0 - t * t)
            lz = 0.255
            spts.append(m @ Vector((lx, ly, lz)) + self.origin)
        self.tube(spts, 0.014 * scale, eye_swatch, uv_cells, segs=6)

    def to_object(self, material) -> bpy.types.Object:
        bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces)
        mesh = bpy.data.meshes.new(self.name)
        self.bm.to_mesh(mesh)
        self.bm.free()
        mesh.materials.append(material)
        obj = bpy.data.objects.new(self.name, mesh)
        obj.location = self.origin
        bpy.context.scene.collection.objects.link(obj)
        return obj


# ---------------------------------------------------------------------------
# Export, Bounds & Studio Review Renderer
# ---------------------------------------------------------------------------

def world_bounds(objects):
    low = Vector((math.inf, math.inf, math.inf))
    high = Vector((-math.inf, -math.inf, -math.inf))
    for obj in objects:
        for v in obj.data.vertices:
            wp = obj.matrix_world @ v.co
            low.x = min(low.x, wp.x)
            low.y = min(low.y, wp.y)
            low.z = min(low.z, wp.z)
            high.x = max(high.x, wp.x)
            high.y = max(high.y, wp.y)
            high.z = max(high.z, wp.z)
    return low, high


def ground_and_scale(objects, target_height: float, measure_names=None):
    """Scale whole NPC so height (measured on measure_names or all) equals target_height,
    and shift Z so lowest point sits cleanly at Z = 0."""
    bpy.context.view_layer.update()
    subset = [o for o in objects if measure_names is None or o.name in measure_names]
    low, high = world_bounds(subset)
    cur_h = high.z - low.z
    scale = target_height / max(cur_h, 1e-4)

    all_low, _ = world_bounds(objects)
    ground_z = low.z

    for obj in objects:
        obj.location = Vector((obj.location.x * scale, obj.location.y * scale, (obj.location.z - ground_z) * scale))
        for v in obj.data.vertices:
            v.co *= scale
        obj.data.update()
    bpy.context.view_layer.update()


def export_glb(path: Path, objects):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(path),
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_apply=True,
        export_texcoords=True,
        export_normals=True,
        export_materials="EXPORT",
        export_image_format="AUTO",
        export_cameras=False,
        export_lights=False,
        export_animations=False,
    )


def _aim(obj, target: Vector):
    obj.rotation_euler = (target - obj.location).to_track_quat("-Z", "Y").to_euler()


def render_review_views(out_dir: Path, objects, head_z_hint: float = None, size: int = 512):
    """Render ultra-lightweight Workbench studio turnaround views (near-zero GPU load)."""
    scene = bpy.context.scene
    low, high = world_bounds(objects)
    center = (low + high) * 0.5
    span = high - low

    stage = bpy.data.collections.new("ReviewStage")
    scene.collection.children.link(stage)
    cam_data = bpy.data.cameras.new("ReviewCam")
    cam = bpy.data.objects.new("ReviewCam", cam_data)
    stage.objects.link(cam)
    scene.camera = cam
    cam_data.type = "ORTHO"

    scene.world = bpy.data.worlds.new("StudioWorld")
    scene.world.use_nodes = True
    bg = scene.world.node_tree.nodes.get("Background")
    bg.inputs[0].default_value = (0.95, 0.91, 0.85, 1.0)
    bg.inputs[1].default_value = 1.0

    # Use ultra-lightweight BLENDER_WORKBENCH (renders in <0.2s, zero GPU power spike)
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "TEXTURE"
    scene.display.shading.show_shadows = False
    scene.display.shading.show_cavity = True
    scene.display.shading.cavity_type = "SCREEN"
    scene.view_settings.view_transform = "Standard"
    scene.render.resolution_x = size
    scene.render.resolution_y = size
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"

    out_dir.mkdir(parents=True, exist_ok=True)
    angles = {
        "front": (0.0, -1.0, 0.04),
        "three-quarter": (-0.65, -1.0, 0.14),
        "back": (0.0, 1.0, 0.05),
    }
    for name, direction in angles.items():
        cam.location = center + Vector(direction).normalized() * 14.0
        _aim(cam, center)
        ax = cam.rotation_euler.to_quaternion() @ Vector((1, 0, 0))
        ay = cam.rotation_euler.to_quaternion() @ Vector((0, 1, 0))
        corners = [o.matrix_world @ Vector(c) - center for o in objects for c in o.bound_box]
        cam_data.ortho_scale = max(abs(c.dot(a)) for c in corners for a in (ax, ay)) * 2.28
        scene.render.filepath = str(out_dir / f"{name}.png")
        bpy.ops.render.render(write_still=True)

    # Close-up portrait of head & chest
    head_target = Vector((0.0, 0.0, head_z_hint if head_z_hint else high.z - span.z * 0.26))
    cam.location = head_target + Vector((-0.24, -1.0, 0.06)).normalized() * 10.0
    _aim(cam, head_target)
    cam_data.ortho_scale = span.z * 0.56
    scene.render.filepath = str(out_dir / "closeup.png")
    bpy.ops.render.render(write_still=True)

    for obj in list(stage.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    bpy.data.collections.remove(stage)


def report_stats(npc_name: str, objects) -> dict:
    low, high = world_bounds(objects)
    parts = {}
    total_tris = 0
    for obj in objects:
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        bmesh.ops.triangulate(bm, faces=bm.faces)
        tris = len(bm.faces)
        bm.free()
        parts[obj.name] = {
            "tris": tris,
            "location": [round(c, 4) for c in obj.location],
        }
        total_tris += tris
    return {
        "npc": npc_name,
        "total_tris": total_tris,
        "bounds_min": [round(c, 4) for c in low],
        "bounds_max": [round(c, 4) for c in high],
        "size_studs": [round(high.x - low.x, 4), round(high.y - low.y, 4), round(high.z - low.z, 4)],
        "parts": parts,
    }


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "NONE"
    scene.unit_settings.scale_length = 1.0
    bpy.context.preferences.filepaths.save_version = 0
