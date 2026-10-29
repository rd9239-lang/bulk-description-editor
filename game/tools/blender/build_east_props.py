"""第2章の東地区と自宅の小物。

約束：Barrier / Bench / Kettle / Stove / Phone / Memo / NoticeBoard / LongTable / LongBench /
Switchboard / Locker / OldWire / Chimney / RoofBroken / BoardedWindow。
各部品の原点は底面中央。X 方向にずらして並べる（Godot ではメッシュだけ取り出して使う）。
材質名は Godot の質感一覧（data/materials.json）の別名と対応している。
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import RAD, box, cylinder, export, join, material, parse_args, reset  # noqa: E402

args = parse_args()
reset()

concrete = material("concrete", (0.55, 0.54, 0.5))
plank = material("plank", (0.5, 0.4, 0.3))
plank_dark = material("plank_dark", (0.3, 0.25, 0.2))
tin = material("tin_roof", (0.45, 0.3, 0.2), metal=0.3)
steel = material("steel", (0.4, 0.4, 0.42), metal=0.6)
paint = material("shade_metal", (0.35, 0.42, 0.38), rough=0.6, metal=0.3)
yellow = material("barrier_yellow", (0.85, 0.65, 0.1), rough=0.6)
black = material("barrier_black", (0.05, 0.05, 0.05), rough=0.6)
paper = material("paper", (0.86, 0.83, 0.74), rough=0.95)
phone_body = material("phone_body", (0.03, 0.03, 0.035), rough=0.25)
phone_screen = material("phone_screen", (0.02, 0.03, 0.05), rough=0.05)
cable = material("cable", (0.02, 0.02, 0.02), rough=0.6)
porcelain = material("porcelain", (0.85, 0.85, 0.82), rough=0.3)
cabinet = material("ac_body", (0.74, 0.72, 0.66), rough=0.55)

# 工事柵（幅 2m、高さ 1m。黄色と黒のしま模様の横板2枚）
X = 0.0
parts = [box("ba_foot_l", (0.3, 0.5, 0.08), (X - 0.95, 0, 0.04), concrete),
         box("ba_foot_r", (0.3, 0.5, 0.08), (X + 0.95, 0, 0.04), concrete),
         box("ba_post_l", (0.05, 0.05, 1.0), (X - 0.95, 0, 0.5), steel),
         box("ba_post_r", (0.05, 0.05, 1.0), (X + 0.95, 0, 0.5), steel)]
for row, z in enumerate((0.55, 0.9)):
    for i in range(8):
        parts.append(box(f"ba_s{row}_{i}", (0.24, 0.03, 0.14), (X - 0.84 + i * 0.24, 0, z), yellow if (i + row) % 2 == 0 else black))
join("Barrier", parts, origin=(X, 0, 0))

# 港のベンチ（座面 0.45m、背もたれなし）
X = 4.0
join("Bench", [
    box("be_seat", (1.6, 0.4, 0.05), (X, 0, 0.45), plank),
    box("be_leg_l", (0.1, 0.35, 0.43), (X - 0.65, 0, 0.215), concrete),
    box("be_leg_r", (0.1, 0.35, 0.43), (X + 0.65, 0, 0.215), concrete),
], origin=(X, 0, 0))

# やかん（直径 18cm）
X = 8.0
spout = cylinder("ke_spout", 0.012, 0.12, (X + 0.1, 0, 0.11), steel, verts=8, rot=(0, RAD(55), 0))
join("Kettle", [
    cylinder("ke_body", 0.09, 0.13, (X, 0, 0.065), steel, verts=20, radius_top=0.07),
    cylinder("ke_lid", 0.05, 0.02, (X, 0, 0.14), steel, verts=16),
    box("ke_handle", (0.02, 0.14, 0.02), (X, 0, 0.2), black),
    spout,
], origin=(X, 0, 0))

# 台所のガス台（流しの横の台。高さ 0.8m）
X = 12.0
join("Stove", [
    box("st_cab", (0.6, 0.45, 0.8), (X, 0, 0.4), cabinet),
    box("st_top", (0.56, 0.4, 0.06), (X, 0, 0.83), steel),
    cylinder("st_burner_l", 0.07, 0.02, (X - 0.13, 0, 0.87), black, verts=16),
    cylinder("st_burner_r", 0.07, 0.02, (X + 0.13, 0, 0.87), black, verts=16),
], origin=(X, 0, 0))

# スマホ（机の上に伏せずに置く）
X = 16.0
join("Phone", [
    box("ph_body", (0.075, 0.155, 0.008), (X, 0, 0.004), phone_body),
    box("ph_screen", (0.068, 0.145, 0.001), (X, 0, 0.0085), phone_screen),
], origin=(X, 0, 0))

# 書き置き
X = 18.0
join("Memo", [box("me_paper", (0.15, 0.1, 0.002), (X, 0, 0.001), paper),
              box("me_pen", (0.012, 0.13, 0.01), (X + 0.1, 0, 0.005), black)], origin=(X, 0, 0))

# 掲示板（柱2本と板。貼り紙つき。紙は Godot の +Z 側）
X = 22.0
parts = [box("nb_post_l", (0.08, 0.08, 1.9), (X - 0.65, 0, 0.95), plank_dark),
         box("nb_post_r", (0.08, 0.08, 1.9), (X + 0.65, 0, 0.95), plank_dark),
         box("nb_board", (1.3, 0.04, 0.8), (X, 0, 1.3), plank_dark),
         box("nb_roof", (1.5, 0.3, 0.04), (X, 0, 1.78), tin)]
for i, (dx, dz) in enumerate(((-0.35, 1.38), (0.1, 1.42), (0.42, 1.22), (-0.2, 1.12))):
    parts.append(box(f"nb_paper_{i}", (0.3, 0.005, 0.38 if i == 0 else 0.22), (X + dx, -0.025, dz), paper))
join("NoticeBoard", parts, origin=(X, 0, 0))

# 寮の食堂の長机（3m）と長いす
X = 28.0
parts = [box("lt_top", (3.0, 0.8, 0.05), (X, 0, 0.72), plank)]
for sx in (-1.35, 1.35):
    for sy in (-0.32, 0.32):
        parts.append(box(f"lt_leg_{sx}_{sy}", (0.06, 0.06, 0.7), (X + sx, sy, 0.35), plank_dark))
join("LongTable", parts, origin=(X, 0, 0))
X = 33.0
parts = [box("lb_top", (3.0, 0.3, 0.04), (X, 0, 0.42), plank)]
for sx in (-1.3, 0, 1.3):
    parts.append(box(f"lb_leg_{sx}", (0.06, 0.26, 0.4), (X + sx, 0, 0.2), plank_dark))
join("LongBench", parts, origin=(X, 0, 0))

# 配電盤（幅 2.4m、高さ 2m。札と開閉器が並ぶ面は Godot の +Z 側）
X = 38.0
parts = [box("sw_panel", (2.4, 0.3, 2.0), (X, 0, 1.0), paint)]
for r in range(3):
    for c in range(6):
        px, pz = X - 0.95 + c * 0.38, 1.55 - r * 0.45
        parts.append(box(f"sw_box_{r}_{c}", (0.22, 0.08, 0.28), (px, -0.19, pz), steel))
        parts.append(box(f"sw_tag_{r}_{c}", (0.2, 0.005, 0.06), (px, -0.235, pz - 0.2), paper))
join("Switchboard", parts, origin=(X, 0, 0))

# ロッカー（3連、高さ 1.8m）
X = 43.0
parts = [box("lo_body", (0.9, 0.5, 1.8), (X, 0, 0.9), paint)]
for i in range(3):
    parts.append(box(f"lo_line_{i}", (0.01, 0.005, 1.7), (X - 0.15 + i * 0.3, -0.252, 0.9), black))
    parts.append(box(f"lo_vent_{i}", (0.16, 0.005, 0.1), (X - 0.3 + i * 0.3, -0.252, 1.6), black))
join("Locker", parts, origin=(X, 0, 0))

# 古い太い線（床から立ち上がり、碍子を経て壁へ）
X = 47.0
join("OldWire", [
    cylinder("ow_up", 0.03, 2.3, (X, 0, 1.15), cable, verts=10),
    cylinder("ow_across", 0.03, 1.2, (X + 0.6, 0, 2.3), cable, verts=10, rot=(0, RAD(90), 0)),
    cylinder("ow_insulator", 0.05, 0.12, (X, 0, 2.3), porcelain, verts=12),
    box("ow_tag", (0.12, 0.005, 0.07), (X, -0.035, 1.4), paper),
], origin=(X, 0, 0))

# 煙突（高さ 18m、上へ細くなる。帯が3本）
X = 52.0
parts = [cylinder("ch_body", 1.2, 18.0, (X, 0, 9.0), concrete, verts=24, radius_top=0.85)]
for i, z in enumerate((5.0, 10.0, 15.0)):
    r = 1.2 - (1.2 - 0.85) * z / 18.0 + 0.04
    parts.append(cylinder(f"ch_band_{i}", r, 0.3, (X, 0, z), steel, verts=24))
join("Chimney", parts, origin=(X, 0, 0))

# 崩れかけのトタン屋根（2m 四方。1枚は垂れ下がる）
X = 57.0
sag = box("rb_sag", (0.65, 2.0, 0.02), (X + 0.68, 0, -0.35), tin)
sag.rotation_euler = (0, RAD(38), 0)
join("RoofBroken", [
    box("rb_a", (0.65, 2.0, 0.02), (X - 0.68, 0, 0.0), tin),
    box("rb_b", (0.65, 1.3, 0.02), (X, -0.35, 0.0), tin),
    box("rb_beam", (2.0, 0.08, 0.08), (X, 0, -0.06), plank_dark),
    sag,
], origin=(X, 0, -0.5))

# 板でふさいだ窓（0.9m × 1.0m、斜めの板つき）
X = 61.0
diag = box("bw_diag", (1.2, 0.03, 0.14), (X, -0.03, 1.4), plank)
diag.rotation_euler = (0, RAD(35), 0)
join("BoardedWindow", [
    box("bw_a", (1.0, 0.03, 0.18), (X, 0, 1.1), plank),
    box("bw_b", (1.0, 0.03, 0.18), (X, 0, 1.4), plank_dark),
    box("bw_c", (1.0, 0.03, 0.18), (X, 0, 1.7), plank),
    diag,
], origin=(X, 0, 0.8))

export(args.out)
