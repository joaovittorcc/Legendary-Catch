"""Render six matching views of a Legendary Catch creature in Blender."""

import argparse
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from check_creature import bounds, mesh_objects


ANGLES = {
    "front": (0, -1, 0.03),
    "three-quarter-left": (0.83, -1, 0.28),
    "side": (1, 0, 0.08),
    "back": (0, 1, 0.06),
    "three-quarter-right": (-0.83, -1, 0.28),
    "top": (0, -0.13, 1),
}


def aim(obj, target):
    obj.rotation_euler = (target - obj.location).to_track_quat("-Z", "Y").to_euler()


def render(out, objects, size=640):
    scene = bpy.context.scene
    low, high = bounds(objects)
    center = (low + high) / 2
    stage = bpy.data.collections.new("Review lighting")
    scene.collection.children.link(stage)
    lens = bpy.data.cameras.new("Review")
    camera = bpy.data.objects.new("Review", lens)
    stage.objects.link(camera)
    scene.camera = camera
    lens.type = "ORTHO"
    for name, location, color, energy in [
        ("Key", (-3.8,-4.2,5.0),(1.0,0.87,0.72),525),
        ("Fill", (3.0,-3.5,2.2),(0.57,0.79,1.0),360),
        ("Rim", (1.5,3.0,4.5),(0.43,0.81,1.0),675),
        ("Face", (0,-4,-1.1),(0.96,0.97,1.0),100),
    ]:
        light = bpy.data.lights.new(name, "AREA")
        light.color, light.energy, light.shape, light.size = color, energy, "DISK", 4
        obj = bpy.data.objects.new(name, light)
        stage.objects.link(obj)
        obj.location = center + Vector(location)
        aim(obj, center)
    scene.world = bpy.data.worlds.new("Review world")
    scene.world.use_nodes = True
    background = scene.world.node_tree.nodes.get("Background")
    background.inputs[0].default_value = (0.035,0.056,0.105,1)
    background.inputs[1].default_value = 0.48
    scene.render.engine = "BLENDER_EEVEE"
    scene.eevee.taa_render_samples = 20
    scene.view_settings.view_transform = "AgX"
    scene.render.resolution_x = scene.render.resolution_y = size
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    out.mkdir(parents=True, exist_ok=True)
    for name, direction in ANGLES.items():
        camera.location = center + Vector(direction).normalized() * 8
        aim(camera, center)
        axis_x = camera.rotation_euler.to_quaternion() @ Vector((1,0,0))
        axis_y = camera.rotation_euler.to_quaternion() @ Vector((0,1,0))
        corners = [obj.matrix_world @ Vector(corner) - center for obj in objects for corner in obj.bound_box]
        lens.ortho_scale = max(abs(c.dot(axis)) for c in corners for axis in (axis_x, axis_y)) * 2.34
        scene.render.filepath = str(out / f"{name}.png")
        bpy.ops.render.render(write_still=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("blend", type=Path)
    parser.add_argument("out", type=Path)
    parser.add_argument("--size", type=int, default=640)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    bpy.ops.wm.open_mainfile(filepath=str(args.blend.resolve()))
    render(args.out.resolve(), mesh_objects(), args.size)


if __name__ == "__main__":
    main()
