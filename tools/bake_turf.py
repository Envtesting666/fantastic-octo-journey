"""Bake a seamless mown-turf tile (albedo with blade self-shadowing + tangent normal map).

Thousands of modelled blades are rendered straight down with an orthographic camera.
Blades lean toward +Y (the mowing direction); the game rotates the tile 180 degrees on
alternate stripes, so stripes come from real blade orientation rather than paint.

Run: blender --background --factory-startup --python tools/bake_turf.py
"""
from pathlib import Path
import math
import random

import bmesh
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "game/assets/turf"
TILE = 0.5            # metres covered by one texture tile
BLADES = 11000        # ~44k shoots per m², a dense match pitch
RESOLUTION = 1024
SEED = 7


def blade(bm, root, rng):
    heading = math.pi / 2 + rng.gauss(0.0, 0.55)        # lean around +Y
    direction = Vector((math.cos(heading), math.sin(heading), 0.0))
    side = Vector((-direction.y, direction.x, 0.0))
    lean = math.radians(rng.uniform(38.0, 72.0))           # mown blades lie over
    length = rng.uniform(0.022, 0.038)
    width = rng.uniform(0.0025, 0.004)
    rows = []
    for step in range(4):
        t = step / 3.0
        tilt = lean * (0.55 + 0.45 * t)                    # curls further over toward the tip
        spine = root + (direction * math.sin(tilt) + Vector((0.0, 0.0, math.cos(tilt)))) * length * t
        half = side * width * 0.5 * (1.0 - 0.85 * t)
        rows.append((bm.verts.new(spine - half), bm.verts.new(spine + half)))
    for (a, b), (c, d) in zip(rows, rows[1:]):
        face = bm.faces.new((a, b, d, c))
        face.normal_update()
        if face.normal.z < 0.0:
            face.normal_flip()
    shade = rng.random()
    return [shade] * 8


def build_turf():
    rng = random.Random(SEED)
    bm = bmesh.new()
    shades = []
    for _ in range(BLADES):
        root = Vector((rng.uniform(0.0, TILE), rng.uniform(0.0, TILE), 0.0))
        # Wrap blades near the edges so the tile repeats without seams.
        for dx in (-TILE, 0.0, TILE):
            for dy in (-TILE, 0.0, TILE):
                offset = root + Vector((dx, dy, 0.0))
                if -0.05 < offset.x < TILE + 0.05 and -0.05 < offset.y < TILE + 0.05:
                    shades += blade(bm, offset, random.Random(hash((round(root.x, 6), round(root.y, 6)))))
    mesh = bpy.data.meshes.new("Turf")
    bm.to_mesh(mesh)
    bm.free()
    colors = mesh.color_attributes.new("shade", 'FLOAT_COLOR', 'POINT')
    for index, value in enumerate(shades):
        # Green blades; some sun-dried, some fresher.
        g = Vector((0.06, 0.17, 0.035)).lerp(Vector((0.13, 0.25, 0.05)), value)
        colors.data[index].color = (g.x, g.y, g.z, 1.0)
    turf = bpy.data.objects.new("Turf", mesh)
    bpy.context.scene.collection.objects.link(turf)
    return turf


def material(name, build):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    nodes.clear()
    output = nodes.new("ShaderNodeOutputMaterial")
    links.new(build(nodes, links), output.inputs["Surface"])
    return mat


def blade_surface(nodes, links):
    shader = nodes.new("ShaderNodeBsdfDiffuse")
    attribute = nodes.new("ShaderNodeAttribute")
    attribute.attribute_name = "shade"
    links.new(attribute.outputs["Color"], shader.inputs["Color"])
    return shader.outputs[0]


def soil_surface(nodes, links):
    shader = nodes.new("ShaderNodeBsdfDiffuse")
    shader.inputs["Color"].default_value = (0.02, 0.035, 0.012, 1.0)
    return shader.outputs[0]


def normal_surface(nodes, links):
    # World normal -> 0..1 colour. Camera looks down -Z, so world X/Y/Z = tangent/bitangent/normal.
    geometry = nodes.new("ShaderNodeNewGeometry")
    remap = nodes.new("ShaderNodeVectorMath")
    remap.operation = 'MULTIPLY_ADD'
    remap.inputs[1].default_value = (0.5, 0.5, 0.5)
    remap.inputs[2].default_value = (0.5, 0.5, 0.5)
    links.new(geometry.outputs["Normal"], remap.inputs[0])
    emission = nodes.new("ShaderNodeEmission")
    links.new(remap.outputs[0], emission.inputs["Color"])
    return emission.outputs[0]


def set_view(transform):
    settings = bpy.context.scene.view_settings
    for name in (transform, "Standard"):
        try:
            settings.view_transform = name
            settings.look = 'None'
            return
        except TypeError:
            continue


def render(path):
    bpy.context.scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    print("TURF_RENDER", path)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 64
    scene.cycles.use_denoising = True
    try:
        prefs = bpy.context.preferences.addons['cycles'].preferences
        prefs.compute_device_type = 'OPTIX'
        prefs.get_devices()
        for device in prefs.devices:
            device.use = device.type != 'CPU'
        scene.cycles.device = 'GPU'
    except Exception:
        scene.cycles.device = 'CPU'
    scene.render.resolution_x = scene.render.resolution_y = RESOLUTION
    scene.render.image_settings.file_format = 'PNG'

    turf = build_turf()
    bpy.ops.mesh.primitive_plane_add(size=TILE * 3, location=(TILE / 2, TILE / 2, 0.0))
    soil = bpy.context.active_object
    camera_data = bpy.data.cameras.new("Top")
    camera_data.type = 'ORTHO'
    camera_data.ortho_scale = TILE
    camera = bpy.data.objects.new("Top", camera_data)
    camera.location = (TILE / 2, TILE / 2, 1.0)
    scene.collection.objects.link(camera)
    scene.camera = camera
    world = bpy.data.worlds.new("Sky")
    world.use_nodes = True
    background = next(n for n in world.node_tree.nodes if n.type == 'BACKGROUND')
    scene.world = world

    # Albedo with self-shadowing: uniform white sky, so shading = sky visibility between blades.
    turf.data.materials.append(material("Blade", blade_surface))
    soil.data.materials.append(material("Soil", soil_surface))
    background.inputs["Color"].default_value = (1.0, 1.0, 1.0, 1.0)
    background.inputs["Strength"].default_value = 1.0
    set_view("Standard")
    render(OUT / "turf_albedo.png")

    # Tangent-space normals, unlit and untransformed.
    normal = material("Normal", normal_surface)
    turf.data.materials[0] = normal
    soil.data.materials[0] = normal
    background.inputs["Strength"].default_value = 0.0
    scene.cycles.samples = 16
    scene.cycles.use_denoising = False
    set_view("Raw")
    render(OUT / "turf_normal.png")
    print("TURF_BAKE_COMPLETE", turf.data.vertices.__len__(), "verts")


main()
