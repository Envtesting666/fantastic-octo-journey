"""Build the footballer from MakeHuman CC0 assets with MPFB2 and export a skinned GLB.

Run (isolated Blender profile, so the user's own Blender setup is untouched):
  set BLENDER_USER_RESOURCES=C:\\Game deneme\\tools\\cache\\blender_profile
  blender --background --factory-startup --python tools/build_footballer.py

Kit: MakeHuman ships no football kit, so the t-shirt + jeans suit is split into a jersey and
jeans cut above the knee into shorts. Socks are the calf skin pushed out 5 mm, so they deform
exactly like the leg; the game attaches its own boots. Godot recolours the kit; the body
under cloth (and the feet inside the boots) stays masked.
"""
from pathlib import Path
import importlib

import bmesh
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
ASSET_PACK = ROOT / ".source/makehuman/makehuman_system_assets_cc0.zip"
OUTPUT = ROOT / "game/assets/characters/footballer_mh.glb"
BOOT_GLB = ROOT / "game/assets/boots/training_boot.glb"   # tools/build_boot.py; X forward, heel -129 mm, toe +166.5 mm
BOOT_HEEL, BOOT_LENGTH, BOOT_WIDTH = -0.129, 0.2955, 0.104
SERVICES = "bl_ext.user_default.mpfb.services."
HumanService = importlib.import_module(SERVICES + "humanservice").HumanService
AssetService = importlib.import_module(SERVICES + "assetservice").AssetService
TargetService = importlib.import_module(SERVICES + "targetservice").TargetService
LocationService = importlib.import_module(SERVICES + "locationservice").LocationService

# Athletic adult male, ~1.80 m: lean, muscular legs, idealised proportions.
PHENOTYPE = {"gender": 1.0, "age": 0.5, "muscle": 0.68, "weight": 0.42, "proportions": 0.85,
             "height": 0.52, "cupsize": 0.5, "firmness": 0.5,
             "race": {"asian": 0.1, "caucasian": 0.8, "african": 0.1}}
SHORTS_HEM = 0.56      # metres above the ground: just above the knee
SOCK_BOTTOM = 0.07     # socks start inside the boot collar
SOCK_TOP = 0.45        # football socks end just below the knee
SOCK_THICKNESS = 0.005
SKIN_OVERLAP = 0.03    # body stays masked this far under each cloth edge


def asset(*parts):
    path = Path(LocationService.get_user_data(), *parts)
    assert path.exists(), path
    return str(path)


def world_z(obj):
    matrix = obj.matrix_world
    return [(matrix @ v.co).z for v in obj.data.vertices]


def delete_vertices(obj, predicate):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    matrix = obj.matrix_world
    doomed = [v for v in bm.verts if predicate(matrix @ v.co)]
    bmesh.ops.delete(bm, geom=doomed, context='VERTS')
    bm.to_mesh(obj.data)
    bm.free()


def split_loose_parts(obj):
    """Return {component index: object} with each connected mesh island in its own copy."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.verts.ensure_lookup_table()
    island = [-1] * len(bm.verts)
    count = 0
    for start in bm.verts:
        if island[start.index] >= 0:
            continue
        stack = [start]
        island[start.index] = count
        while stack:
            vert = stack.pop()
            for edge in vert.link_edges:
                other = edge.other_vert(vert)
                if island[other.index] < 0:
                    island[other.index] = count
                    stack.append(other)
        count += 1
    bm.free()
    parts = []
    for index in range(count):
        copy = obj.copy()
        copy.data = obj.data.copy()
        bpy.context.scene.collection.objects.link(copy)
        keep = {i for i, owner in enumerate(island) if owner == index}
        bm = bmesh.new()
        bm.from_mesh(copy.data)
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.index not in keep], context='VERTS')
        bm.to_mesh(copy.data)
        bm.free()
        parts.append(copy)
    bpy.data.objects.remove(obj, do_unlink=True)
    return parts


def stand_on_ground(basemesh):
    """Lift rig and everything on it so the soles touch z = 0, then bake the move into bones and
    vertices. (MPFB's feet_on_ground lifts only the mesh, leaving the rig ~0.9 m below it.)"""
    rig = basemesh.parent
    rig.location.z -= min(world_z(basemesh))
    bpy.ops.object.select_all(action='DESELECT')
    for obj in [rig, *rig.children_recursive]:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)


def helper_free_points(basemesh, keep):
    helpers = {g.index for g in basemesh.vertex_groups if "helper" in g.name.lower()}
    matrix = basemesh.matrix_world
    return [matrix @ v.co for v in basemesh.data.vertices
            if keep(matrix @ v.co) and not any(g.group in helpers for g in v.groups)]


def fit_boots(rig, basemesh):
    """Skinned boots sized to each foot: heel-to-toe and width from the foot vertices; the
    front blends from the foot bone to the ball bone so the toe box bends with the toes."""
    bpy.ops.object.select_all(action='DESELECT')
    bpy.ops.import_scene.gltf(filepath=str(BOOT_GLB))
    imported = [o.name for o in bpy.context.selected_objects]
    meshes = [bpy.data.objects[n] for n in imported if bpy.data.objects[n].type == 'MESH']
    bpy.ops.object.select_all(action='DESELECT')
    for mesh in meshes:
        mesh.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.join()
    template = bpy.context.view_layer.objects.active
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for name in imported:  # joined meshes are gone already; drop leftover empties
        if name in bpy.data.objects and name != template.name:
            bpy.data.objects.remove(bpy.data.objects[name], do_unlink=True)
    boots = []
    for side in ("l", "r"):
        ankle = rig.data.bones["foot_" + side].head_local
        ball = rig.data.bones["ball_" + side].head_local
        forward = Vector((ball.x - ankle.x, ball.y - ankle.y, 0.0)).normalized()
        right = Vector((forward.y, -forward.x, 0.0))   # boot +Y is the wearer's right
        base = Vector((ankle.x, ankle.y, 0.0))
        foot = helper_free_points(basemesh, lambda p: p.z < 0.12 and abs(p.x - ankle.x) < 0.12)
        along = [(p - base).dot(forward) for p in foot]
        across = [(p - base).dot(right) for p in foot]
        heel, toe = min(along) - 0.01, max(along) + 0.012
        centre = (min(across) + max(across)) * 0.5
        length_scale = (toe - heel) / BOOT_LENGTH
        width_scale = (max(across) - min(across) + 0.016) / BOOT_WIDTH
        ball_along = (ball - base).dot(forward)
        boot = template.copy()
        boot.data = template.data.copy()
        bpy.context.scene.collection.objects.link(boot)
        foot_group = boot.vertex_groups.new(name="foot_" + side)
        ball_group = boot.vertex_groups.new(name="ball_" + side)
        for vert in boot.data.vertices:
            local = vert.co.copy()
            distance = heel + (local.x - BOOT_HEEL) * length_scale
            vert.co = base + forward * distance + right * (centre + local.y * width_scale) + Vector((0.0, 0.0, local.z * width_scale))
            bend = min(max((distance - ball_along + 0.02) / 0.05, 0.0), 1.0)
            foot_group.add([vert.index], 1.0 - bend, 'REPLACE')
            ball_group.add([vert.index], bend, 'REPLACE')
        boot.parent = rig
        boot.modifiers.new("Armature", 'ARMATURE').object = rig
        boots.append(boot)
    bpy.data.objects.remove(template, do_unlink=True)
    return boots


def mask_groups(basemesh):
    """Vertex groups of the cloth masks MPFB put on the body (each hides its group)."""
    return [basemesh.vertex_groups[m.vertex_group] for m in basemesh.modifiers
            if m.type == 'MASK' and "helper" not in m.name.lower() and m.vertex_group in basemesh.vertex_groups]


def set_masked(basemesh, low, high, hidden):
    band = [v.index for v in basemesh.data.vertices if low < (basemesh.matrix_world @ v.co).z < high]
    groups = mask_groups(basemesh)
    if hidden:
        groups[0].add(band, 1.0, 'REPLACE')
    else:
        for group in groups:
            group.remove(band)


def sock_shell(basemesh):
    """Football socks: the calf/shin skin band pushed out a few mm, deforming exactly like the leg."""
    socks = basemesh.copy()
    socks.data = basemesh.data.copy()
    bpy.context.scene.collection.objects.link(socks)
    for modifier in [m for m in socks.modifiers if m.type == 'MASK']:
        socks.modifiers.remove(modifier)
    helpers = {g.index for g in socks.vertex_groups if "helper" in g.name.lower()}
    matrix = socks.matrix_world
    bm = bmesh.new()
    bm.from_mesh(socks.data)
    deform = bm.verts.layers.deform.active
    doomed = [v for v in bm.verts if not SOCK_BOTTOM < (matrix @ v.co).z < SOCK_TOP
              or (deform is not None and any(g in helpers for g in v[deform].keys()))]
    bmesh.ops.delete(bm, geom=doomed, context='VERTS')
    bm.normal_update()
    offset = SOCK_THICKNESS / matrix.to_scale().x
    for vert in bm.verts:
        vert.co += vert.normal * offset
    bm.to_mesh(socks.data)
    bm.free()
    material = bpy.data.materials.new("Socks")
    material.diffuse_color = (0.85, 0.86, 0.82, 1.0)
    socks.data.materials.clear()
    socks.data.materials.append(material)
    return socks


def main():
    if not AssetService.system_assets_pack_is_installed():
        bpy.ops.mpfb.load_pack(filepath=str(ASSET_PACK))
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)

    basemesh = HumanService.create_human(mask_helpers=True, detailed_helpers=False, extra_vertex_groups=True,
                                         feet_on_ground=False, scale=0.1, macro_detail_dict=PHENOTYPE)
    HumanService.set_character_skin(asset("skins", "young_caucasian_male", "young_caucasian_male.mhmat"),
                                    basemesh, skin_type='MAKESKIN', material_instances=False)
    HumanService.add_builtin_rig(basemesh, "game_engine")
    parts = {}
    for label, kind, folder, name in [("Eyes", "Eyes", "eyes", "low-poly"), ("Eyebrows", "Eyebrows", "eyebrows", "eyebrow001"),
                                      ("Eyelashes", "Eyelashes", "eyelashes", "eyelashes01"), ("Hair", "Hair", "hair", "short02"),
                                      ("Suit", "Clothes", "clothes", "male_casualsuit06")]:
        parts[label] = HumanService.add_mhclo_asset(asset(folder, name, name + ".mhclo"), basemesh, asset_type=kind,
                                                    subdiv_levels=0, material_type='MAKESKIN')
    TargetService.bake_targets(basemesh)
    stand_on_ground(basemesh)

    # Suit = shirt island above, jeans below: the higher mean is the jersey.
    islands = sorted(split_loose_parts(parts.pop("Suit")), key=lambda p: sum(world_z(p)) / len(p.data.vertices))
    parts["Shorts"], parts["Jersey"] = islands[0], islands[-1]
    for extra in islands[1:-1]:
        bpy.data.objects.remove(extra, do_unlink=True)
    delete_vertices(parts["Shorts"], lambda co: co.z < SHORTS_HEM)
    parts["Socks"] = sock_shell(basemesh)
    # Feet (in boots) and calves (in socks) hidden; bare knee between sock top and shorts hem.
    set_masked(basemesh, -1.0, SOCK_TOP - SKIN_OVERLAP, hidden=True)
    set_masked(basemesh, SOCK_TOP - SKIN_OVERLAP, min(world_z(parts["Shorts"])) + SKIN_OVERLAP, hidden=False)
    parts["Body"] = basemesh
    parts["LeftBoot"], parts["RightBoot"] = fit_boots(basemesh.parent, basemesh)

    for label, obj in parts.items():
        obj.name = label
        if obj.active_material and label not in ("Socks", "LeftBoot", "RightBoot"):
            obj.active_material.name = label
    names = list(parts.values())

    rig = next(obj for obj in bpy.data.objects if obj.type == 'ARMATURE')
    rig.name = "Footballer"
    print("RIG pelvis head", tuple(round(c, 3) for c in rig.data.bones["pelvis"].head_local))
    bpy.ops.object.select_all(action='DESELECT')
    for obj in [rig, *names]:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = rig
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(OUTPUT), export_format='GLB', use_selection=True,
                              export_apply=True, export_yup=True, export_animations=False, export_morph=False)
    height = max(world_z(basemesh))
    print("FOOTBALLER_BUILT", OUTPUT, "height=%.3f" % height, "objects=", sorted(o.name for o in names))


main()
