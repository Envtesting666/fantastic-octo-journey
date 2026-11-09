"""Asset Forge entry point: recipe -> editable source + game GLB + inspected views.
Geometry is constructed by the deterministic executor; this wrapper only orchestrates it.
"""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
FORGE = Path(r"C:\Users\fatih\.agents\skills\asset-forge\scripts\forge.py")
exec(compile(FORGE.read_text(encoding="utf-8"), str(FORGE), "exec"))
build(str(ROOT / "tools/recipes/training_boot.json"))
source_dir = ROOT / ".source/boots"
output_dir = ROOT / "game/assets/boots"
evidence_dir = ROOT / "evidence/m01/boots"
for directory in (source_dir, output_dir, evidence_dir):
    directory.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(source_dir / "training_boot.blend"))
bpy.ops.object.select_all(action='DESELECT')
for obj in bpy.data.objects:
    if obj.type == 'MESH':
        obj.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(output_dir / "training_boot.glb"), use_selection=True, export_format='GLB')
for label, angle, distance, target in [
    ("hero", -35, 620, [10, 0, 47]),
    ("opposite", 45, 620, [10, 0, 47]),
    ("profile", -90, 620, [10, 0, 47]),
    ("detail", -40, 360, [0, 0, 70]),
]:
    camera_spec = {**_RECIPE['camera'], 'azim': angle, 'dist': distance, 'target': target}
    build_camera(camera_spec)
    image_path = str(evidence_dir / (label + '.png'))
    render(image_path, res=(960, 600), samples=24, engine='cycles')
    probe(image_path, label)
print("BOOT_BUILD_COMPLETE")
