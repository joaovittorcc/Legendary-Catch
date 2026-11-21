"""Check a creature scene or reimported FBX in background Blender."""

import argparse
import json
import re
import sys
from pathlib import Path

import bpy
from mathutils import Vector


PARTS = {"Body", "Head", "Tail", "FinL", "FinR", "Fins", "Wings", "Tentacles", "Legs", "Claws", "Shell", "Extra"}
REQUIRED = {"Body", "Head", "Tail"}
BUDGETS = {
    "Common": (600, 200, 256, 2.7, 2.95),
    "Uncommon": (900, 300, 256, 2.7, 2.95),
    "Rare": (1500, 500, 512, 2.7, 2.95),
    "Epic": (2500, 800, 512, 3.0, 3.2),
    "Legendary": (6000, 1500, 1024, 3.2, 3.6),
}


def mesh_objects():
    return [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]


def bounds(objects):
    corners = [obj.matrix_world @ Vector(corner) for obj in objects for corner in obj.bound_box]
    return tuple(Vector([func(p[i] for p in corners) for i in range(3)]) for func in (min, max))


def part_name(obj):
    return obj.name.split(".")[0]


def inspect(creature_id, rarity, objects):
    total_limit, part_limit, atlas_limit, min_size, max_size = BUDGETS[rarity]
    if not re.fullmatch(r"C\d{2,}_[A-Za-z0-9_]+", creature_id):
        raise ValueError("Expected a Config creature ID")
    if any(obj.type == "ARMATURE" for obj in bpy.context.scene.objects):
        raise ValueError("Rigid creature scenes must not contain armatures")
    by_name = {part_name(obj): obj for obj in objects}
    if not REQUIRED <= by_name.keys() or not by_name.keys() <= PARTS:
        raise ValueError(f"Missing {sorted(REQUIRED - by_name.keys())}; unexpected {sorted(by_name.keys() - PARTS)}")
    if any(sum(part_name(obj) == name for obj in objects) > 1 for name in by_name.keys() - {"Extra"}):
        raise ValueError("Only Extra can repeat")
    world_min, world_max = bounds(objects)
    width, depth, height = world_max - world_min
    if not min_size - 0.005 <= max(width, depth, height) <= max_size + 0.005:
        raise ValueError(f"Largest dimension must be {min_size}–{max_size} studs")
    head, tail = (sum(bounds([by_name[n]]), Vector()) / 2 for n in ("Head", "Tail"))
    if tail.y - head.y <= 0.1:
        raise ValueError("Head must be in front of Tail along Blender -Y")
    if "FinL" in by_name and "FinR" in by_name:
        left, right = (sum(bounds([by_name[n]]), Vector()) / 2 for n in ("FinL", "FinR"))
        if left.x <= right.x:
            raise ValueError("FinL must be on the +X side")

    counts = {}
    maps = set()
    for obj in objects:
        mesh = obj.data
        mesh.calc_loop_triangles()
        if not 0 < len(mesh.loop_triangles) <= part_limit:
            raise ValueError(f"{obj.name}: {len(mesh.loop_triangles)} triangles (limit {part_limit})")
        if len(mesh.uv_layers) != 1 or len(mesh.materials) != 1:
            raise ValueError(f"{obj.name} must use one UV layer and one material")
        if any(not -0.0001 <= value <= 1.0001 for loop in mesh.uv_layers.active.data for value in loop.uv):
            raise ValueError(f"{obj.name} has UVs outside 0–1")
        if any(abs(scale - 1) > 0.0001 for scale in obj.scale):
            raise ValueError(f"{obj.name} has unapplied scale")
        if obj.parent is not None or obj.modifiers:
            raise ValueError(f"{obj.name} must be a direct mesh with baked geometry")
        counts[obj.name] = len(mesh.loop_triangles)
        material = mesh.materials[0]
        for node in material.node_tree.nodes if material and material.use_nodes else []:
            if node.type == "TEX_IMAGE" and node.image:
                maps.add(node.image)
    total = sum(counts.values())
    if total > total_limit:
        raise ValueError(f"{total} triangles exceeds the {total_limit} limit")
    if len(maps) != 1 or max(next(iter(maps)).size) > atlas_limit or min(next(iter(maps)).size) < 1:
        raise ValueError(f"Expected one shared atlas of at most {atlas_limit} px")
    return {
        "id": creature_id,
        "rarity": rarity,
        "roblox_xyz_studs": [round(x, 3) for x in (width, height, depth)],
        "head_minus_tail_z": round(tail.y - head.y, 3),
        "atlas_px": list(next(iter(maps)).size),
        "triangles": total,
        "parts": counts,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("asset", type=Path)
    parser.add_argument("id")
    parser.add_argument("rarity", choices=BUDGETS)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    if args.asset.suffix.lower() == ".blend":
        bpy.ops.wm.open_mainfile(filepath=str(args.asset.resolve()))
    elif args.asset.suffix.lower() == ".fbx":
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.fbx(filepath=str(args.asset.resolve()))
    else:
        parser.error("Use a .blend or .fbx")
    result = json.dumps(inspect(args.id, args.rarity, mesh_objects()), indent=2)
    if args.report:
        args.report.write_text(result + "\n", encoding="utf-8")
    print(result)


if __name__ == "__main__":
    main()
