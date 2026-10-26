"""昭和の炭鉱町の街灯：コンクリート柱＋腕金＋笠付きの灯具。

約束：Pole / LampHead（マテリアル lamp_emit）/ LightAnchor（高さ 4.5m）。
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import RAD, box, cylinder, empty, export, join, material, parse_args, reset  # noqa: E402

args = parse_args()
reset()

concrete = material("concrete", (0.55, 0.54, 0.5))
metal = material("shade_metal", (0.16, 0.22, 0.18), rough=0.5, metal=0.6)
lamp = material("lamp_emit", (0.95, 0.9, 0.78), rough=0.3, emission=(1.0, 0.85, 0.6))

cylinder("Pole", 0.11, 5.4, (0, 0, 2.7), concrete, verts=12, radius_top=0.08)
arm = box("Arm", (0.9, 0.05, 0.05), (0.42, 0, 4.95), metal)
stay = cylinder("ArmStay", 0.015, 0.75, (0.3, 0, 4.72), metal, verts=6, rot=(0, RAD(55), 0))
join("Arm", [arm, stay])
cylinder("Shade", 0.32, 0.18, (0.8, 0, 4.7), metal, verts=20, radius_top=0.06)
cylinder("LampHead", 0.09, 0.12, (0.8, 0, 4.57), lamp, verts=12)
empty("LightAnchor", (0.8, 0, 4.5))

export(args.out)
