"""炭鉱住宅の組み立て部品（2m グリッド）：板張りの外壁、窓付きの壁、戸口、床、トタン屋根。

約束：Wall_2m / Wall_Window_2m / Door_Frame / Floor_2m / Roof_Tile_2m。
部品は X 方向に 3m ずつずらして並べる。各部品の原点は底面中央なので、Godot 側ではメッシュだけ取り出して使う。
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import box, export, join, material, parse_args, reset, set_origin  # noqa: E402

args = parse_args()
reset()

plank = material("plank", (0.36, 0.29, 0.22))
plank_dark = material("plank_dark", (0.25, 0.2, 0.15))
glass = material("glass", (0.5, 0.6, 0.65), rough=0.1)
floor = material("tatami_floor", (0.6, 0.55, 0.38))
tin = material("tin_roof", (0.38, 0.27, 0.22), rough=0.6, metal=0.5)

H = 2.6   # 壁の高さ
T = 0.12  # 壁の厚さ


def planks(x0, y_center, width, z0, height, name_prefix):
    """横板を重ねた壁面。板の段差で板張りに見せる。"""
    parts = []
    n = int(height / 0.2)
    for i in range(n):
        parts.append(box(f"{name_prefix}_{i}", (width, T if i % 2 else T * 0.9, 0.19),
                         (x0, y_center, z0 + 0.1 + i * 0.2), plank if i % 2 else plank_dark))
    return parts


# Wall_2m
join("Wall_2m", planks(0, 0, 2.0, 0, H, "w"), origin=(0, 0, 0))

# Wall_Window_2m（幅 0.9m・高さ 0.9m の窓、下端 0.9m）
X = 3.0
parts = planks(X, 0, 2.0, 0, 0.9, "ww_low")
parts += planks(X, 0, 2.0, 1.8, H - 1.8, "ww_top")
parts.append(box("ww_left", (0.55, T, 0.9), (X - 0.725, 0, 1.35), plank))
parts.append(box("ww_right", (0.55, T, 0.9), (X + 0.725, 0, 1.35), plank))
parts.append(box("ww_glass", (0.9, 0.02, 0.9), (X, 0, 1.35), glass))
for dz in (0.0, 0.45, 0.9):
    parts.append(box(f"ww_bar_{dz}", (0.9, 0.04, 0.03), (X, 0, 0.9 + dz), plank_dark))
parts.append(box("ww_mullion", (0.03, 0.04, 0.9), (X, 0, 1.35), plank_dark))
join("Wall_Window_2m", parts, origin=(X, 0, 0))

# Door_Frame（開口 0.9m×1.9m）
X = 6.0
parts = [
    box("df_left", (0.55, T, H), (X - 0.725, 0, H / 2), plank),
    box("df_right", (0.55, T, H), (X + 0.725, 0, H / 2), plank),
    box("df_top", (0.9, T, H - 1.9), (X, 0, 1.9 + (H - 1.9) / 2), plank),
    box("df_trim", (1.0, T + 0.02, 0.06), (X, 0, 1.92), plank_dark),
]
join("Door_Frame", parts, origin=(X, 0, 0))

# Floor_2m
X = 9.0
set_origin(box("Floor_2m", (2.0, 2.0, 0.05), (X, 0, 0.025), floor), (X, 0, 0))

# Roof_Tile_2m（波板トタン）
X = 12.0
parts = [box("rt_base", (2.0, 2.0, 0.02), (X, 0, 0.01), tin)]
for i in range(10):
    parts.append(box(f"rt_rib_{i}", (0.04, 2.0, 0.03), (X - 0.9 + i * 0.2, 0, 0.035), tin))
join("Roof_Tile_2m", parts, origin=(X, 0, 0))

export(args.out)
