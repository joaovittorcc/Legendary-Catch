"""Export the rigged C93 from Blender 5.3 with its color atlas and swim action.

blender --background c93-ouroboros-final.blend --python-exit-code 1 --python export_c93.py
"""

from pathlib import Path

import bpy


ATLAS_SIZE = 512
GRID_SIZE = 4
TRIANGLE_LIMIT = 6000


def linear_to_srgb(value):
    return 12.92 * value if value <= 0.0031308 else 1.055 * value ** (1 / 2.4) - 0.055


def make_atlas(materials, output):
    if len(materials) > GRID_SIZE**2:
        raise ValueError("The C93 palette does not fit the atlas")

    swatches = [(*map(linear_to_srgb, mat.diffuse_color[:3]), 1.0) for mat in materials]
    swatches.extend([(0.0, 0.0, 0.0, 1.0)] * (GRID_SIZE**2 - len(swatches)))
    tile = ATLAS_SIZE // GRID_SIZE
    pixels = [
        value
        for y in range(ATLAS_SIZE)
        for x in range(ATLAS_SIZE)
        for value in swatches[y // tile * GRID_SIZE + x // tile]
    ]
    image = bpy.data.images.new("C93 Base Color", ATLAS_SIZE, ATLAS_SIZE, alpha=False)
    image.colorspace_settings.name = "sRGB"
    image.pixels.foreach_set(pixels)
    image.filepath_raw = str(output)
    image.file_format = "PNG"
    image.save()
    image.pack()

    material = bpy.data.materials.new("C93 Base Color")
    material.use_nodes = True
    shader = next(node for node in material.node_tree.nodes if node.type == "BSDF_PRINCIPLED")
    shader.inputs["Roughness"].default_value = 0.4
    tex = material.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = image
    material.node_tree.links.new(tex.outputs["Color"], shader.inputs["Base Color"])
    return material


def color_uvs(mesh, materials):
    uv = mesh.uv_layers.new(name="Atlas")
    slots = [materials.index(mat) for mat in mesh.materials]
    for face in mesh.polygons:
        swatch = slots[face.material_index]
        normal_axis = max(range(3), key=lambda axis: abs(face.normal[axis]))
        axes = [axis for axis in range(3) if axis != normal_axis]
        points = [mesh.vertices[mesh.loops[index].vertex_index].co for index in face.loop_indices]
        low = [min(point[axis] for point in points) for axis in axes]
        spans = [max(point[axis] for point in points) - base for axis, base in zip(axes, low)]
        for index, point in zip(face.loop_indices, points):
            u, v = [
                (point[axis] - base) / span if span > 1e-8 else 0.5
                for axis, base, span in zip(axes, low, spans)
            ]
            uv.uv[index].vector = (
                (swatch % GRID_SIZE + 0.2 + 0.6 * u) / GRID_SIZE,
                (swatch // GRID_SIZE + 0.2 + 0.6 * v) / GRID_SIZE,
            )


def validate(rig, meshes):
    if rig.type != "ARMATURE" or not rig.animation_data or not rig.animation_data.action:
        raise ValueError("The armature must have the swim action active")
    triangle_count = 0
    for obj in meshes:
        obj.data.calc_loop_triangles()
        triangle_count += len(obj.data.loop_triangles)
        root_group = obj.vertex_groups.get("Root")
        for vertex in obj.data.vertices:
            groups = [group for group in vertex.groups if group.weight > 0]
            if not 1 <= len(groups) <= 4 or abs(sum(g.weight for g in groups) - 1) > 1e-5:
                raise ValueError(f"Invalid weights at {obj.name} vertex {vertex.index}")
            if root_group and any(g.group == root_group.index for g in groups):
                raise ValueError(f"Assigned a vertex on {obj.name} to the non-deforming root")
    if triangle_count > TRIANGLE_LIMIT:
        raise ValueError(f"Triangle budget exceeded: {triangle_count}")
    print(f"Triangles: {triangle_count}; bones: {len(rig.data.bones)}")


def export():
    folder = Path(bpy.data.filepath).parent
    rig = bpy.data.objects["C93_Armature"]
    meshes = [bpy.data.objects[name] for name in ("Body", "Core")]
    validate(rig, meshes)

    materials = sorted({mat for obj in meshes for mat in obj.data.materials}, key=lambda mat: mat.name)
    baked = make_atlas(materials, folder / "c93-color-atlas.png")

    bpy.ops.object.select_all(action="DESELECT")
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    for obj in meshes:
        color_uvs(obj.data, materials)
        obj.data.materials.clear()
        obj.data.materials.append(baked)
        obj.select_set(True)

    bpy.context.scene.frame_set(bpy.context.scene.frame_start)
    settings = dict(
        use_selection=True,
        object_types={"ARMATURE", "MESH"},
        global_scale=float(rig.get("RobloxExportScale", 0.01)),
        apply_scale_options="FBX_SCALE_UNITS",
        axis_forward=str(rig.get("RobloxExportForward", "-Z")),
        axis_up="Y",
        add_leaf_bones=False,
        use_mesh_modifiers=False,
        use_triangles=True,
        path_mode="COPY",
        embed_textures=True,
        bake_anim_use_nla_strips=False,
        bake_anim_use_all_actions=False,
        bake_anim_simplify_factor=0.0,
    )
    for filename, animation in (
        ("c93-ouroboros-rig.fbx", False),
        ("c93-ouroboros-swim.fbx", True),
    ):
        result = bpy.ops.export_scene.fbx(
            filepath=str(folder / filename), bake_anim=animation, **settings
        )
        if "FINISHED" not in result:
            raise RuntimeError(f"FBX export failed: {filename}: {result}")


if __name__ == "__main__":
    export()
