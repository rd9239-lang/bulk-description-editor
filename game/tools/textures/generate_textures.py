"""ゲーム用の質感画像（色・凹凸・ツヤ）を手続き的に作る。

写真素材（Poly Haven など）が手に入ったら、同じ場所の同じ名前のファイルを
差し替えるだけでよい（assets/textures/<名前>/albedo.jpg, normal.jpg, roughness.jpg）。

使い方: python3 generate_textures.py [--out ../../assets/textures] [--size 1024]
"""
import argparse
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFont

from texgen import fbm, lerp, normal_from_height, save_gray_as_rgb, save_rgb, smoothstep, worley


def asphalt(s, seed):
    """濡れたアスファルト（1枚で約2m）。水たまりはツヤが高く、凹凸が平ら。"""
    fine = fbm(s, 0.9, seed)
    low = fbm(s, 2.2, seed + 1)
    f1, _, sid = worley(s, max(8, s // 7), seed + 2, with_id=True)
    stone = smoothstep(0.42, 0.18, f1) * (sid > 0.55)
    c1, c2 = worley(s, 5, seed + 3)
    crack = smoothstep(0.035, 0.0, c2 - c1) * (fbm(s, 2.0, seed + 4) > 0.55)
    puddle = fbm(s, 2.4, seed + 5)
    wet = smoothstep(0.63, 0.70, puddle)
    damp = smoothstep(0.48, 0.63, puddle)
    g = 0.085 + 0.05 * fine + 0.03 * (low - 0.5) + 0.13 * stone * (0.5 + 0.5 * sid)
    g = g * (1 - 0.7 * crack) * (1 - 0.35 * damp) * (1 - 0.25 * wet)
    albedo = lerp([1.0, 1.0, 1.0], [0.95, 0.97, 1.03], 0.5)[None, None, :] * g[..., None]
    rough = (0.9 - 0.12 * stone) * (1 - damp * 0.45)
    rough = lerp(rough, 0.04, wet)
    height = 0.55 * fine + 0.45 * stone - 0.6 * crack
    height = lerp(height, height.mean(), wet)
    return albedo, height, rough, 3.0


def concrete(s, seed):
    """風雨にさらされたコンクリート（1枚で約2m）。縦の雨だれと気泡の穴。"""
    fine = fbm(s, 1.0, seed)
    stain = fbm(s, 2.4, seed + 1)
    streak = fbm(s, 1.6, seed + 2, stretch=(1.0, 9.0))
    f1, _, pid = worley(s, max(8, s // 10), seed + 3, with_id=True)
    pore = smoothstep(0.12, 0.03, f1) * (pid > 0.6)
    tone = 0.85 + 0.12 * fine + 0.2 * (stain - 0.5) - 0.12 * smoothstep(0.55, 0.8, streak)
    tone = tone * (1 - 0.45 * pore)
    albedo = lerp([0.0, 0.0, 0.0], [0.56, 0.55, 0.52], tone)
    rough = 0.86 + 0.08 * fine
    height = 0.35 * fine + 0.1 * stain - 0.6 * pore
    return albedo, height, rough, 2.0


def block_wall(s, seed):
    """コンクリートブロック塀（1枚で 0.8m 角：横2個×縦4段、段ごとに半個ずらし）。"""
    base_a, base_h, base_r, _ = concrete(s, seed)
    y, x = (np.mgrid[0:s, 0:s] + 0.5) / s
    # 画像の端が目地にかからないよう、半段・4分の1個ずらす
    y = (y + 0.125) % 1.0
    row = np.floor(y * 4).astype(int)
    bx = x * 2 + 0.25 + 0.5 * (row % 2)
    xs = bx % 1.0
    col = np.floor(bx % 2).astype(int)
    edge = np.minimum(np.minimum(xs, 1 - xs) * 0.4, np.minimum((y * 4) % 1, 1 - (y * 4) % 1) * 0.2)
    groove = smoothstep(0.006, 0.0, edge)
    rng = np.random.default_rng(seed + 9)
    tones = rng.uniform(0.88, 1.08, size=(4, 2))
    tone = tones[row, col]
    albedo = base_a * tone[..., None] * (1 - 0.35 * groove[..., None])
    height = base_h * 0.4 + (1 - groove)
    rough = np.clip(base_r + 0.04 * groove, 0, 1)
    return albedo, height, rough, 3.0


def wood_weathered(s, seed):
    """風雨で銀色がかった古い板（1枚で約1m）。横方向の木目。"""
    grain = fbm(s, 1.5, seed, stretch=(14.0, 1.0))
    fiber = fbm(s, 0.8, seed + 1, stretch=(30.0, 1.0))
    weather = fbm(s, 1.8, seed + 2, stretch=(6.0, 1.0))
    k1, _, kid = worley(s, 4, seed + 3, with_id=True)
    knot = smoothstep(0.09, 0.0, k1) * (kid > 0.6)
    split = smoothstep(0.86, 0.95, fiber)
    t = 0.45 * grain + 0.35 * fiber
    albedo = lerp([0.24, 0.18, 0.13], [0.46, 0.39, 0.31], t)
    albedo = lerp(albedo, [0.43, 0.42, 0.40], smoothstep(0.4, 0.8, weather) * 0.45)
    albedo = albedo * (1 - 0.55 * split[..., None]) * (1 - 0.5 * knot[..., None])
    rough = 0.82 + 0.1 * weather
    height = 0.6 * grain + 0.4 * fiber - 0.7 * split - 0.3 * knot
    return albedo, height, rough, 3.0


def corrugated_rust(s, seed):
    """錆の浮いた波板トタン（1枚で約1m、波 13 本）。縦向きの波と錆の流れ。"""
    x = np.arange(s) / s
    wave = np.tile(0.5 + 0.5 * np.sin(2 * np.pi * 13 * x), (s, 1))
    rust_n = fbm(s, 1.5, seed)
    blotch = fbm(s, 2.2, seed + 1)
    streak = fbm(s, 1.4, seed + 2, stretch=(1.0, 12.0))
    rust = np.clip(smoothstep(0.55, 0.75, 0.6 * blotch + 0.4 * rust_n) + 0.6 * smoothstep(0.6, 0.85, streak), 0, 1)
    paint = lerp([0.36, 0.15, 0.11], [0.48, 0.22, 0.16], fbm(s, 2.0, seed + 3))
    rust_col = lerp([0.22, 0.11, 0.05], [0.55, 0.27, 0.10], rust_n)
    albedo = lerp(paint, rust_col, rust)
    albedo = albedo * (0.82 + 0.18 * wave[..., None])
    rough = lerp(0.55, 0.92, rust)
    height = 0.75 * wave + 0.25 * rust_n * rust
    return albedo, height, rough, 6.0


def painted_metal(s, seed):
    """塗装のはげた濃緑の鉄（1枚で約0.5m）。街灯の笠や腕金。"""
    n = fbm(s, 1.4, seed)
    dust = fbm(s, 1.0, seed + 1)
    chip = smoothstep(0.66, 0.72, 0.7 * n + 0.3 * fbm(s, 1.0, seed + 2))
    paint = lerp([0.11, 0.18, 0.14], [0.17, 0.25, 0.19], dust)
    bare = lerp([0.25, 0.17, 0.11], [0.42, 0.33, 0.25], n)
    albedo = lerp(paint, bare, chip)
    rough = lerp(0.42 + 0.15 * dust, 0.82, chip)
    height = 0.2 * dust - 0.6 * chip
    return albedo, height, rough, 2.0


def plaster(s, seed):
    """くすんだ漆喰・モルタルの壁（1枚で約2m）。"""
    trowel = fbm(s, 1.6, seed)
    stain = fbm(s, 2.0, seed + 1, stretch=(1.0, 5.0))
    tone = 0.93 + 0.08 * (trowel - 0.5) - 0.07 * smoothstep(0.55, 0.9, stain)
    albedo = lerp([0.0, 0.0, 0.0], [0.80, 0.76, 0.67], tone)
    rough = 0.9 + 0.05 * trowel
    return albedo, 0.3 * trowel, rough, 1.0


def gravel_dirt(s, seed):
    """砂利まじりの土（1枚で約2m）。路地や空き地。"""
    dirt = fbm(s, 1.2, seed)
    warp = fbm(s, 1.0, seed + 7)
    albedo = lerp([0.20, 0.16, 0.12], [0.33, 0.27, 0.21], dirt)
    height = 0.25 * dirt
    rough = np.full((s, s), 0.95)
    for layer, (cells, keep) in enumerate(((max(6, s // 40), 0.5), (max(10, s // 18), 0.35))):
        f1, _, pid = worley(s, cells, seed + 1 + layer * 10, with_id=True)
        radius = 0.22 + 0.22 * pid
        d = f1 + 0.08 * (warp - 0.5)
        peb = smoothstep(radius, radius - 0.06, d) * (pid > keep)
        dome = np.sqrt(np.clip(1 - d / radius, 0, 1)) * peb
        stone = lerp([0.28, 0.27, 0.25], [0.56, 0.53, 0.48], fbm(s, 1.3, seed + 20 + layer) * 0.5 + pid * 0.5)
        albedo = lerp(albedo, stone, peb)
        height = np.maximum(height, 0.25 * dirt + 0.75 * dome)
        rough = lerp(rough, 0.72, peb)
    return albedo, height, rough, 4.0


def wood_floor(s, seed):
    """板張りの床・桟橋（1枚で約2m、横方向の板 12 枚）。"""
    rows = 12
    y, x = (np.mgrid[0:s, 0:s] + 0.5) / s
    y = (y + 0.5 / rows) % 1.0  # 画像の端が板の継ぎ目にかからないようにする
    row = np.floor(y * rows).astype(int)
    rng = np.random.default_rng(seed + 5)
    cut = rng.random(rows)
    tone = rng.uniform(0.8, 1.15, size=(rows, 2))
    seg = ((x - cut[row]) % 1.0 < 0.5).astype(int)
    vy = (y * rows) % 1.0
    vx = (x - cut[row]) % 0.5
    gap = smoothstep(0.03, 0.0, np.minimum(vy, 1 - vy)) + smoothstep(0.004, 0.0, np.minimum(vx, 0.5 - vx))
    gap = np.clip(gap, 0, 1)
    grain = fbm(s, 1.4, seed, stretch=(12.0, 1.0))
    albedo = lerp([0.22, 0.15, 0.10], [0.42, 0.30, 0.20], grain) * tone[row, seg][..., None]
    albedo = albedo * (1 - 0.7 * gap[..., None])
    rough = 0.62 + 0.15 * grain
    height = 0.4 * grain + (1 - gap)
    return albedo, height, rough, 3.0


def tatami(s, seed):
    """古い畳（1枚で約1m）。い草の細かい織り目。"""
    y = np.arange(s) / s
    weave = np.tile((0.5 + 0.5 * np.sin(2 * np.pi * 128 * y))[:, None], (1, s))
    age = fbm(s, 2.2, seed)
    fiber = fbm(s, 0.9, seed + 1, stretch=(1.0, 20.0))
    albedo = lerp([0.48, 0.44, 0.26], [0.66, 0.60, 0.38], 0.5 * weave + 0.3 * fiber)
    albedo = albedo * (0.85 + 0.15 * age[..., None])
    rough = 0.78 + 0.1 * fiber
    height = 0.7 * weave + 0.3 * fiber
    return albedo, height, rough, 2.0


MATERIALS = {
    "asphalt": asphalt,
    "concrete": concrete,
    "block_wall": block_wall,
    "wood_weathered": wood_weathered,
    "corrugated_rust": corrugated_rust,
    "painted_metal": painted_metal,
    "plaster": plaster,
    "gravel_dirt": gravel_dirt,
    "wood_floor": wood_floor,
    "tatami": tatami,
}


def generate_all(out_dir, size=1024, seed=7):
    for i, (name, fn) in enumerate(MATERIALS.items()):
        albedo, height, rough, strength = fn(size, seed + i * 100)
        d = os.path.join(out_dir, name)
        os.makedirs(d, exist_ok=True)
        save_rgb(os.path.join(d, "albedo.jpg"), albedo)
        save_rgb(os.path.join(d, "normal.jpg"), normal_from_height(height, strength))
        save_gray_as_rgb(os.path.join(d, "roughness.jpg"), rough)


JP_FONT = "/usr/share/fonts/truetype/fonts-japanese-gothic.ttf"


def generate_stop_marking(out_dir, size=(1024, 512), seed=3):
    """路面標示「止まれ」（透過 PNG）。道路の進行方向に縦長に引き伸ばし、かすれを入れる。"""
    w, h = size
    canvas = Image.new("L", (w, w // 2), 0)
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.truetype(JP_FONT, int(w * 0.3)) if os.path.exists(JP_FONT) else ImageFont.load_default()
    box = draw.textbbox((0, 0), "止まれ", font=font)
    draw.text(((w - (box[2] - box[0])) / 2 - box[0], (w // 2 - (box[3] - box[1])) / 2 - box[1]), "止まれ", fill=255, font=font)
    mask = np.asarray(canvas.resize((w, h)), dtype=np.float64) / 255.0
    n = max(w, h)
    wear = fbm(n, 1.1, seed)[:h, :w]
    alpha = mask * smoothstep(0.25, 0.45, wear)
    rgba = np.zeros((h, w, 4), dtype=np.uint8)
    rgba[..., :3] = 235
    rgba[..., 3] = np.round(alpha * 255).astype(np.uint8)
    os.makedirs(out_dir, exist_ok=True)
    Image.fromarray(rgba, "RGBA").save(os.path.join(out_dir, "stop_marking.png"))


if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    p = argparse.ArgumentParser()
    p.add_argument("--out", default=os.path.join(here, "..", "..", "assets", "textures"))
    p.add_argument("--size", type=int, default=1024)
    a = p.parse_args()
    generate_all(a.out, a.size)
    generate_stop_marking(a.out)
    print("textures written to", os.path.abspath(a.out))
