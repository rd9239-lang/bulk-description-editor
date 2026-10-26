"""Poly Haven の .blend をゲーム用の軽い .glb に変換する。

テクスチャを指定サイズ（既定 1024px）に縮め、glTF（GLB）で書き出す。
.blend 内の Python スクリプトは実行しない。

使い方: python3 convert_polyhaven.py --in <file.blend> --out <file.glb> [--size 1024]
（Blender 本体なら: blender -b -P convert_polyhaven.py -- --in ... --out ...）
"""
import argparse
import sys

import bpy

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
p = argparse.ArgumentParser()
p.add_argument("--in", dest="src", required=True)
p.add_argument("--out", required=True)
p.add_argument("--size", type=int, default=1024)
args = p.parse_args(argv)

bpy.context.preferences.filepaths.use_scripts_auto_execute = False
bpy.ops.wm.open_mainfile(filepath=args.src, load_ui=False, use_scripts=False)

for img in bpy.data.images:
    if img.size[0] > args.size:
        img.scale(args.size, int(args.size * img.size[1] / img.size[0]))

meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
lo = [min(v[i] for o in meshes for v in (o.matrix_world @ c for c in [__import__("mathutils").Vector(b) for b in o.bound_box])) for i in range(3)]
hi = [max(v[i] for o in meshes for v in (o.matrix_world @ c for c in [__import__("mathutils").Vector(b) for b in o.bound_box])) for i in range(3)]
print("SIZE_M", [round(hi[i] - lo[i], 3) for i in range(3)], "MIN_Z", round(lo[2], 3))

bpy.ops.export_scene.gltf(filepath=args.out, export_format="GLB", export_yup=True,
                          export_apply=True, export_image_format="AUTO")
