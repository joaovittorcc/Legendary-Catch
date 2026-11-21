"""Build, validate and export rigid creature meshes with their painted atlas."""

import argparse
import json
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
from check_creature import BUDGETS, bounds, inspect, mesh_objects
from creature_mesh import atlas


def export_fbx(path, objects):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.ops.export_scene.fbx(
        filepath=str(path), use_selection=True, object_types={"MESH"},
        axis_forward="-Z", axis_up="Y", global_scale=1.0,
        apply_unit_scale=True, apply_scale_options="FBX_SCALE_UNITS",
        mesh_smooth_type="FACE", use_triangles=True,
        path_mode="COPY", embed_textures=True, bake_anim=False,
    )


def pack(creature_id, rarity, build, palette, out, atlas_size, render=False):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "NONE"
    scene.unit_settings.scale_length = 1.0
    scene.render.image_settings.file_format = "PNG"
    bpy.context.preferences.filepaths.save_version = 0
    out.mkdir(parents=True, exist_ok=True)
    material, cells = atlas(out / "color-atlas.png", palette, atlas_size)
    objects = [piece.make(material, cells) for piece in build()]
    bpy.context.view_layer.update()
    low, high = bounds(objects)
    center = (low + high) / 2
    target_size = {"Epic": 3.14, "Legendary": 3.48}.get(rarity, 2.86)
    scale = target_size / max(high - low)
    for obj in objects:
        obj.location = (obj.location - center) * scale
        for v in obj.data.vertices:
            v.co *= scale
        obj.data.update()
    bpy.context.view_layer.update()
    report = inspect(creature_id, rarity, objects)
    scene["creature_id"] = creature_id
    scene["rarity"] = rarity
    bpy.ops.wm.save_as_mainfile(filepath=str(out / f"{creature_id}.blend"))
    export_fbx(out / f"{creature_id}.fbx", objects)
    (out / "mesh-report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2), flush=True)
    if render:
        from preview_creature import render as render_views
        render_views(out / "views", objects)


def build_cli(script, creature_id, rarity, build, palette, atlas_size=512):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, default=Path(script).resolve().parent / "model")
    parser.add_argument("--no-render", action="store_true")
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    args = parser.parse_args(argv)
    pack(creature_id, rarity, build, palette, args.out.resolve(), atlas_size, render=not args.no_render)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("blend", type=Path)
    parser.add_argument("id")
    parser.add_argument("rarity", choices=BUDGETS)
    parser.add_argument("fbx", type=Path)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    bpy.ops.wm.open_mainfile(filepath=str(args.blend.resolve()))
    objects = mesh_objects()
    print(json.dumps(inspect(args.id, args.rarity, objects), indent=2))
    export_fbx(args.fbx.resolve(), objects)


if __name__ == "__main__":
    main()
