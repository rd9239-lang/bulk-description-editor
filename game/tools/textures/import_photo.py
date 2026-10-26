"""写真の色画像（Poly Haven の diff など）から、ゲーム用の3枚（色・凹凸・ツヤ）を作る。

凹凸とツヤの画像がない場合でも、色の濃淡から近似して作る：
- 凹凸（法線）：明るさの細かい変化だけを取り出して高さとみなす
- ツヤ（ラフネス）：暗い溝ほど粗く、明るく盛り上がった所ほど滑らか

使い方:
  python3 import_photo.py --src wood.jpg --name photo_wood_floor [--size 1024]
        [--normal 4.0] [--rough 0.7] [--rough-range 0.3]
出力: assets/textures/<name>/albedo.jpg, normal.jpg, roughness.jpg
"""
import argparse
import os

import numpy as np
from PIL import Image

from texgen import normal_from_height, save_gray_as_rgb, save_rgb


def periodic_blur(a, sigma):
    """端がつながる前提のガウスぼかし（FFT）。"""
    if sigma <= 0:
        return a
    h, w = a.shape
    fy = np.fft.fftfreq(h)[:, None]
    fx = np.fft.fftfreq(w)[None, :]
    g = np.exp(-2 * (np.pi * sigma) ** 2 * (fx ** 2 + fy ** 2))
    return np.real(np.fft.ifft2(np.fft.fft2(a) * g))


def resize_tileable(rgb, size):
    """端のつながりを保ったまま縮小する（周囲を折り返して広げてから縮め、中央を切り出す）。"""
    src = rgb.shape[0]
    if src == size:
        return rgb
    m = max(8, src // 32)
    padded = np.pad(rgb, ((m, m), (m, m), (0, 0)), mode="wrap")
    scale = size / src
    big = int(round(padded.shape[0] * scale))
    out = np.asarray(Image.fromarray(padded).resize((big, big), Image.LANCZOS))
    o = int(round(m * scale))
    return out[o:o + size, o:o + size]


def derive_maps(rgb, size=1024, normal_strength=4.0, rough_base=0.7, rough_range=0.3, detail=1 / 48):
    albedo = resize_tileable(np.asarray(rgb, dtype=np.uint8), size)
    lum = albedo.astype(np.float64).mean(axis=2) / 255.0
    high = lum - periodic_blur(lum, size * detail)
    high = periodic_blur(high, 0.6)
    lo, hi = np.percentile(high, 1), np.percentile(high, 99)
    height = np.clip((high - lo) / (hi - lo), 0, 1) if hi - lo > 1e-6 else np.full_like(high, 0.5)
    normal = normal_from_height(height, normal_strength)
    rough = np.clip(rough_base + rough_range * (0.5 - height), 0.0, 1.0)
    return albedo, normal, rough


def import_texture(src, out_dir, name, size=1024, **kw):
    rgb = np.asarray(Image.open(src).convert("RGB"))
    albedo, normal, rough = derive_maps(rgb, size=size, **kw)
    d = os.path.join(out_dir, name)
    os.makedirs(d, exist_ok=True)
    save_rgb(os.path.join(d, "albedo.jpg"), albedo)
    save_rgb(os.path.join(d, "normal.jpg"), normal)
    save_gray_as_rgb(os.path.join(d, "roughness.jpg"), rough)
    return d


if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    p = argparse.ArgumentParser()
    p.add_argument("--src", required=True)
    p.add_argument("--name", required=True)
    p.add_argument("--out", default=os.path.join(here, "..", "..", "assets", "textures"))
    p.add_argument("--size", type=int, default=1024)
    p.add_argument("--normal", type=float, default=4.0)
    p.add_argument("--rough", type=float, default=0.7)
    p.add_argument("--rough-range", type=float, default=0.3)
    a = p.parse_args()
    print(import_texture(a.src, a.out, a.name, a.size, normal_strength=a.normal, rough_base=a.rough, rough_range=a.rough_range))
