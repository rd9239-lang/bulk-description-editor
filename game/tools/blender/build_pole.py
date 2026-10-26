"""電柱：コンクリート柱＋腕木。電線の取り付け位置を空ノードで示す。

約束：Pole / CrossArm / WireAnchor_L / WireAnchor_R。
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import box, cylinder, empty, export, material, parse_args, reset  # noqa: E402

args = parse_args()
reset()

concrete = material("concrete", (0.52, 0.51, 0.48))
wood = material("crossarm", (0.32, 0.25, 0.18))
insulator = material("insulator", (0.85, 0.85, 0.82), rough=0.3)

cylinder("Pole", 0.15, 9.0, (0, 0, 4.5), concrete, verts=12, radius_top=0.1)
box("CrossArm", (1.6, 0.09, 0.09), (0, 0, 8.2), wood)
for side, x in (("L", -0.7), ("R", 0.7)):
    cylinder("Insulator_" + side, 0.04, 0.1, (x, 0, 8.3), insulator, verts=8)
    empty("WireAnchor_" + side, (x, 0, 8.36))

export(args.out)
