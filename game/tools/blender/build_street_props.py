"""通りの小物と仮の人物（マネキン）。

約束：BlockWall_2m / GutterLid_2m / CurveMirror / ACUnit / GasMeter / Mannequin_F。
各部品の原点は底面中央。X 方向に 4m ずつずらして並べる（Godot ではメッシュだけ取り出して使う）。
材質名は Godot の質感一覧（data/materials.json）の別名と対応している。
"""
import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import RAD, box, cylinder, export, join, material, parse_args, reset  # noqa: E402

args = parse_args()
reset()

block = material("block_wall", (0.55, 0.54, 0.5))
concrete = material("concrete", (0.55, 0.54, 0.5))
grate = material("grate", (0.2, 0.2, 0.22), metal=0.6)
pole_paint = material("mirror_pole", (0.85, 0.38, 0.08), rough=0.5)
frame = material("mirror_frame", (0.85, 0.38, 0.08), rough=0.5)
mirror = material("mirror", (0.9, 0.9, 0.9), rough=0.03, metal=1.0)
ac_body = material("ac_body", (0.78, 0.76, 0.7), rough=0.55)
ac_grill = material("ac_grill", (0.08, 0.08, 0.08))
gas = material("gas_meter", (0.6, 0.62, 0.6), rough=0.5, metal=0.3)
steel = material("steel", (0.4, 0.4, 0.42), metal=0.6)
cloth = material("npc_cloth", (0.4, 0.35, 0.4))
skin = material("npc_skin", (0.85, 0.74, 0.64), rough=0.6)
hair = material("npc_hair", (0.05, 0.04, 0.04), rough=0.7)


def sphere(name, radius, loc, mat, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, location=loc, segments=20, ring_count=10)
    o = bpy.context.object
    o.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.name = name
    o.data.materials.append(mat)
    return o


# ブロック塀（長さ 2m、高さ 1.2m、笠木つき）
X = 0.0
join("BlockWall_2m", [
    box("bw_body", (2.0, 0.15, 1.2), (X, 0, 0.6), block),
    box("bw_cap", (2.0, 0.19, 0.06), (X, 0, 1.23), concrete),
], origin=(X, 0, 0))

# 側溝のふた（コンクリートの蓋と、中央に鉄の格子）
X = 4.0
parts = [box("gl_slab", (2.0, 0.4, 0.06), (X, 0, 0.03), concrete)]
for i in range(9):
    parts.append(box(f"gl_bar_{i}", (0.03, 0.3, 0.065), (X - 0.24 + i * 0.06, 0, 0.033), grate))
join("GutterLid_2m", parts, origin=(X, 0, 0))

# カーブミラー（高さ約 3.1m、鏡は Godot の +Z 方向を向く）
X = 8.0
join("CurveMirror", [
    cylinder("cm_pole", 0.03, 3.0, (X, 0, 1.5), pole_paint, verts=10),
    cylinder("cm_frame", 0.33, 0.05, (X, -0.06, 2.95), frame, verts=28, rot=(RAD(90), 0, 0)),
    cylinder("cm_glass", 0.29, 0.01, (X, -0.09, 2.95), mirror, verts=28, rot=(RAD(90), 0, 0)),
], origin=(X, 0, 0))

# 室外機（地面に置く。ファンの格子は Godot の +Z 側）
X = 12.0
join("ACUnit", [
    box("ac_body", (0.8, 0.3, 0.55), (X, 0, 0.32), ac_body),
    box("ac_foot_l", (0.06, 0.32, 0.05), (X - 0.3, 0, 0.025), steel),
    box("ac_foot_r", (0.06, 0.32, 0.05), (X + 0.3, 0, 0.025), steel),
    cylinder("ac_fan", 0.19, 0.02, (X - 0.12, -0.155, 0.32), ac_grill, verts=24, rot=(RAD(90), 0, 0)),
], origin=(X, 0, 0))

# ガスメーター（壁に付ける高さ 1.0〜1.3m、下に配管）
X = 16.0
join("GasMeter", [
    box("gm_body", (0.22, 0.12, 0.28), (X, 0, 1.14), gas),
    cylinder("gm_pipe", 0.015, 1.0, (X + 0.06, 0, 0.5), steel, verts=8),
], origin=(X, 0, 0))

# 仮の人物（女性、身長約 1.62m）。服の色は Godot 側で人物ごとに変える
X = 20.0
parts = []
for side in (-1, 1):
    parts.append(cylinder(f"mf_leg_{side}", 0.055, 0.6, (X + side * 0.08, 0, 0.3), skin, verts=10))
    parts.append(box(f"mf_shoe_{side}", (0.09, 0.2, 0.06), (X + side * 0.08, -0.04, 0.03), hair))
    arm = cylinder(f"mf_arm_{side}", 0.045, 0.58, (X + side * 0.21, 0, 1.09), cloth, verts=10)
    arm.rotation_euler = (0, RAD(side * 7), 0)
    parts.append(arm)
    parts.append(sphere(f"mf_hand_{side}", 0.045, (X + side * 0.245, 0, 0.78), skin))
parts += [
    cylinder("mf_skirt", 0.25, 0.48, (X, 0, 0.78), cloth, verts=20, radius_top=0.15),
    cylinder("mf_torso", 0.15, 0.42, (X, 0, 1.2), cloth, verts=16, radius_top=0.19),
    cylinder("mf_neck", 0.045, 0.08, (X, 0, 1.44), skin, verts=10),
    sphere("mf_head", 0.1, (X, 0, 1.53), skin, scale=(1, 1, 1.18)),
    sphere("mf_hair", 0.106, (X, 0.02, 1.56), hair, scale=(1, 1, 1.1)),
]
join("Mannequin_F", parts, origin=(X, 0, 0))

export(args.out)
