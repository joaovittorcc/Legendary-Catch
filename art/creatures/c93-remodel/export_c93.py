"""Run with blender --background c93-ouroboros-v2.blend --python export_c93.py."""

from pathlib import Path
from mathutils import Matrix

import bpy


PARTS = ("Body", "Head", "Tail", "Fins", "FinL", "FinR", "Extra")
ATLAS_SIZE = 512
GRID_SIZE = 4


def export():
    folder = Path(bpy.data.filepath).parent
    parts = [bpy.data.collections["C93 | Ouroboros"].objects[name] for name in PARTS]
    materials = sorted({mat for obj in parts for mat in obj.data.materials}, key=lambda mat: mat.name)
    assert len(materials) <= GRID_SIZE**2, "Palette does not fit the atlas"

    atlas = bpy.data.images.new("C93 Base Color", ATLAS_SIZE, ATLAS_SIZE, alpha=False)
    atlas.colorspace_settings.name = "sRGB"
    colors = [tuple(mat.diffuse_color[:3]) for mat in materials]

    def srgb(v):
        return 12.92 * v if v <= 0.0031308 else 1.055 * v ** (1 / 2.4) - 0.055

    swatches = [(*map(srgb, rgb), 1.0) for rgb in colors]
    swatches.extend([(0.0, 0.0, 0.0, 1.0)] * (GRID_SIZE**2 - len(swatches)))
    tile = ATLAS_SIZE // GRID_SIZE
    pixels = [
        channel
        for y in range(ATLAS_SIZE)
        for x in range(ATLAS_SIZE)
        for channel in swatches[y // tile * GRID_SIZE + x // tile]
    ]
    atlas.pixels.foreach_set(pixels)
    atlas.filepath_raw = str(folder / "c93-color-atlas.png")
    atlas.file_format = "PNG"
    atlas.save()
    atlas.pack()
    baked = bpy.data.materials.new("C93 Atlas")
    baked.use_nodes = True
    shader = next(node for node in baked.node_tree.nodes if node.type == "BSDF_PRINCIPLED")
    shader.inputs["Roughness"].default_value = 0.42
    tex = baked.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = atlas
    baked.node_tree.links.new(tex.outputs["Color"], shader.inputs["Base Color"])

    # With default settings the Studio importer uses a stud per GLB unit
    # and reverses glTF Z. Blender +Y exports to glTF -Z and imports as +Z.
    transform = Matrix.Diagonal((-1.0, 1.0, 1.0, 1.0))
    bpy.context.scene.name = "C93_Ouroboros_Review"
    bpy.ops.object.select_all(action="DESELECT")
    for obj in parts:
        mesh = obj.data
        uv = mesh.uv_layers.new(name="Atlas")
        slots = [materials.index(mat) for mat in mesh.materials]
        for face in mesh.polygons:
            swatch = slots[face.material_index]
            normal_axis = max(range(3), key=lambda axis: abs(face.normal[axis]))
            axes = [axis for axis in range(3) if axis != normal_axis]
            coords = [mesh.vertices[mesh.loops[i].vertex_index].co for i in face.loop_indices]
            low = [min(point[a] for point in coords) for a in axes]
            spans = [max(point[a] for point in coords) - base for a, base in zip(axes, low)]
            for index, point in zip(face.loop_indices, coords):
                local = [(point[a] - base) / span if span > 1e-8 else 0.5
                         for a, base, span in zip(axes, low, spans)]
                uv.data[index].uv = (
                    (swatch % GRID_SIZE + 0.2 + 0.6 * local[0]) / GRID_SIZE,
                    (swatch // GRID_SIZE + 0.2 + 0.6 * local[1]) / GRID_SIZE,
                )
        mesh.materials.clear()
        mesh.materials.append(baked)
        mesh.transform(transform)
        mesh.flip_normals()
        obj.location = transform.to_3x3() @ obj.location
        obj.select_set(True)

    # Keep the project convention: FinL is on the positive X side.
    left, right = parts[4:6]
    left.name = "SwapFin"
    right.name = "FinL"
    left.name = "FinR"
    for obj in parts:
        obj.data.name = f"Export_{obj.name}"
    for obj in parts:
        obj.data.name = obj.name

    target = folder / "c93-ouroboros-v2.glb"
    result = bpy.ops.export_scene.gltf(
        filepath=str(target),
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_animations=False,
    )
    if "FINISHED" not in result:
        raise RuntimeError(f"glTF export failed: {result}")
    print(f"Exported {target}")


if __name__ == "__main__":
    export()
