"""Geometry and painted atlas helpers for rigid Legendary Catch creatures.

Author in Blender XYZ with the face toward -Y and the top toward +Z.
Keep separate motion groups at the joints used by CreatureMotion.
"""

import math
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Vector


def rgb(hex_color):
    return np.array([int(hex_color[i:i + 2], 16) / 255 for i in (0, 2, 4)])


def atlas(path: Path, palette, size):
    columns = 4
    cell = size // columns
    if len(palette) > columns ** 2:
        raise ValueError("At most 16 atlas swatches are supported")
    pixels = np.ones((size, size, 4), dtype=np.float32)
    uv_cells = {}
    rng = np.random.default_rng(791)
    u, v = np.meshgrid(np.linspace(0, 1, cell), np.linspace(0, 1, cell))
    grain = rng.random((cell, cell)) - 0.5
    for index, (name, (colors, pattern)) in enumerate(palette.items()):
        x, y = (index % columns) * cell, (index // columns) * cell
        stops = np.array([rgb(color) for color in colors.split("/")])
        t = np.clip(0.1 + 0.73 * v + 0.14 * np.cos(math.tau * u), 0, 1)
        paint = np.stack([np.interp(t, np.linspace(0, 1, len(stops)), stops[:, i]) for i in range(3)], axis=-1)
        detail = 0.026 * grain
        if pattern == "scale":
            period = 8 * v
            arc = 0.27 * (1 - np.cos(math.tau * (8 * u + 0.5 * np.floor(period))))
            seam = np.abs((period + arc + 0.5) % 1 - 0.5)
            detail += -0.095 * np.exp(-(seam / 0.062) ** 2) + 0.052 * np.exp(-((seam - 0.15) / 0.08) ** 2)
        elif pattern == "armor":
            detail += 0.048 * np.cos(12 * math.tau * u + 0.3 * np.sin(math.tau * v))
            detail -= 0.12 * np.exp(-(np.sin(4 * math.pi * v) / 0.13) ** 2)
        elif pattern == "vein":
            detail += 0.15 * np.exp(-(np.sin(3 * math.tau * u + 1.2 * np.sin(math.tau * v)) / 0.23) ** 2)
        elif pattern == "bands":
            detail += 0.12 * np.tanh(3 * np.cos(3 * math.tau * v))
        elif pattern == "star":
            stars = np.zeros_like(u)
            for _ in range(34):
                sx, sy = rng.uniform(0.04, 0.96, 2)
                radius = rng.uniform(0.003, 0.014)
                stars += rng.uniform(0.16, 0.85) * np.exp(-((u - sx)**2 + (v - sy)**2) / radius**2)
            detail += stars
        pixels[y:y + cell, x:x + cell, :3] = np.clip(paint + detail[:, :, None], 0, 1)
        pad = max(4, cell // 16)
        uv_cells[name] = ((x + pad) / size, (y + pad) / size, (cell - 2 * pad) / size)

    image = bpy.data.images.new(path.name, width=size, height=size, alpha=False)
    image.pixels.foreach_set(pixels.ravel())
    image.file_format = "PNG"
    image.filepath_raw = str(path)
    image.save()
    image.pack()
    mat = bpy.data.materials.new("CreatureAtlas")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    shader = nodes.get("Principled BSDF")
    shader.inputs["Roughness"].default_value = 0.37
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = image
    nodes.active = tex
    mat.node_tree.links.new(tex.outputs["Color"], shader.inputs["Base Color"])
    return mat, uv_cells


class Piece:
    def __init__(self, name):
        self.name = name
        self.vertices = []
        self.faces = []
        self.paint = []

    def _rings(self, rings, swatch, smooth=True, v_range=(0, 1)):
        count = len(rings[0])
        start = len(self.vertices)
        self.vertices.extend(v for ring in rings for v in ring)
        height = len(rings) - 1
        span = v_range[1] - v_range[0]
        for j in range(height):
            v1, v2 = v_range[0] + span*j/height, v_range[0] + span*(j+1)/height
            for i in range(count):
                a, b = i, (i + 1) % count
                self.faces.append((start+j*count+a, start+j*count+b, start+(j+1)*count+b, start+(j+1)*count+a))
                self.paint.append((swatch, ((i/count,v1),((i+1)/count,v1),((i+1)/count,v2),(i/count,v2)),smooth))
        for j, reverse in ((0, True), (height, False)):
            order = list(range(count))
            if reverse:
                order.reverse()
            self.faces.append(tuple(start+j*count+i for i in order))
            self.paint.append((swatch, tuple((0.5+0.45*math.cos(math.tau*i/count),0.5+0.45*math.sin(math.tau*i/count)) for i in order),False))

    def sweep(self, stations, swatch, sides=10, reference=(1, 0, 0), smooth=True, steps=1, v_range=(0, 1)):
        """Sweep elliptical sections. Each station is (center, width radius, depth radius)."""
        if steps > 1:
            points = [np.array((*center, width, depth)) for center, width, depth in stations]
            padded = [points[0], *points, points[-1]]
            interpolated = []
            for a, b, c, d in zip(padded, padded[1:], padded[2:], padded[3:]):
                for step in range(steps):
                    t = step / steps
                    p = (2*b + (c-a)*t + (2*a-5*b+4*c-d)*t*t + (-a+3*b-3*c+d)*t*t*t) / 2
                    interpolated.append((p[:3], max(0.006,p[3]), max(0.004,p[4])))
            stations = [*interpolated, stations[-1]]
        centers = [Vector(station[0]) for station in stations]
        angles = [math.tau * i / sides for i in range(sides)]
        rings = []
        ref = Vector(reference)
        for index, (center, width, depth) in enumerate(stations):
            tangent = (centers[min(index + 1, len(centers) - 1)] - centers[max(index - 1, 0)]).normalized()
            side = ref - tangent * tangent.dot(ref)
            if side.length < 0.001:
                side = tangent.cross(Vector((0, 1, 0)) if abs(tangent.z) > 0.9 else Vector((0, 0, 1)))
            side.normalize()
            up = tangent.cross(side)
            rings.append([Vector(center) + side * width * math.cos(a) + up * depth * math.sin(a) for a in angles])
        self._rings(rings, swatch, smooth, v_range)

    def oval(self, center, radii, swatch, sides=12, levels=7, tilt=0):
        cx, cy, cz = center
        rx, ry, rz = radii
        rings = []
        for row in range(levels):
            p = math.pi * (0.03 + 0.94 * row / (levels - 1)) - math.pi / 2
            ring = []
            for col in range(sides):
                a = math.tau * col / sides
                x, y, z = rx * math.cos(p) * math.cos(a), ry * math.cos(p) * math.sin(a), rz * math.sin(p)
                ring.append((cx+x*math.cos(tilt)+z*math.sin(tilt),cy+y,cz-x*math.sin(tilt)+z*math.cos(tilt)))
            rings.append(ring)
        self._rings(rings, swatch)

    def gem(self, base, point, width, swatch, sides=6):
        a, b = Vector(base), Vector(point)
        self.sweep([(a,width*0.57,width*0.52),(a.lerp(b,0.34),width,width*0.72),(b,0.006,0.004)],
                   swatch,sides=sides,smooth=False)

    def make(self, material, cells):
        mid = Vector([(min(v[i] for v in self.vertices) + max(v[i] for v in self.vertices))/2 for i in range(3)])
        data = bpy.data.meshes.new(self.name)
        data.from_pydata([Vector(v)-mid for v in self.vertices], [], self.faces)
        data.update()
        ob = bpy.data.objects.new(self.name, data)
        bpy.context.collection.objects.link(ob)
        ob.location = mid
        data.materials.append(material)
        uv = data.uv_layers.new(name="Atlas")
        for face, (swatch, points, smooth) in zip(data.polygons, self.paint, strict=True):
            x, y, span = cells[swatch]
            face.use_smooth = smooth
            for loop, (u, v) in zip(face.loop_indices, points, strict=True):
                uv.data[loop].uv = (x+u*span,y+v*span)
        bm = bmesh.new()
        bm.from_mesh(data)
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
        bm.to_mesh(data)
        bm.free()
        return ob
