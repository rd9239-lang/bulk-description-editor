"""タイル状につながる（シームレスな）質感画像を作るための部品。

すべての模様は周期的な関数（FFT による合成、周期的なセル配置）で作るので、
画像の端どうしが必ずつながる。
"""
import numpy as np
from PIL import Image


def fbm(size, beta=2.0, seed=0, stretch=(1.0, 1.0)):
    """スペクトル合成によるタイル可能なノイズ（0〜1）。

    beta が大きいほど滑らか。stretch=(sx, sy) を大きくした軸方向にはゆっくり変化する
    （例: (8, 1) で横に長い木目、(1, 8) で縦の雨だれ）。
    """
    rng = np.random.default_rng(seed)
    f = np.fft.fftfreq(size) * size
    fx, fy = np.meshgrid(f, f)
    r = np.sqrt((fx * stretch[0]) ** 2 + (fy * stretch[1]) ** 2)
    amp = np.zeros_like(r)
    nz = r > 0
    amp[nz] = r[nz] ** -beta
    spec = (rng.normal(size=r.shape) + 1j * rng.normal(size=r.shape)) * amp
    h = np.real(np.fft.ifft2(spec))
    h -= h.min()
    return h / h.max()


def worley(size, cells, seed=0, with_id=False):
    """周期的なセルノイズ。F1（最近点までの距離）と F2（2番目）をセル単位で返す。"""
    rng = np.random.default_rng(seed)
    pts = rng.random((cells, cells, 2))
    ids = rng.random((cells, cells))
    u = (np.arange(size) + 0.5) / size * cells
    ux, uy = np.meshgrid(u, u)
    cx = np.floor(ux).astype(int)
    cy = np.floor(uy).astype(int)
    f1 = np.full(ux.shape, np.inf)
    f2 = np.full(ux.shape, np.inf)
    nid = np.zeros(ux.shape)
    for oy in (-1, 0, 1):
        for ox in (-1, 0, 1):
            nx = cx + ox
            ny = cy + oy
            p = pts[ny % cells, nx % cells]
            d = np.sqrt((ux - (nx + p[..., 0])) ** 2 + (uy - (ny + p[..., 1])) ** 2)
            closer = d < f1
            f2 = np.where(closer, f1, np.minimum(f2, d))
            nid = np.where(closer, ids[ny % cells, nx % cells], nid)
            f1 = np.where(closer, d, f1)
    if with_id:
        return f1, f2, nid
    return f1, f2


def normal_from_height(h, strength):
    """高さ（0〜1）から OpenGL 形式（緑＝上）の法線マップ（uint8 RGB）を作る。"""
    g = strength * h.shape[1] / 256.0
    dx = (np.roll(h, -1, axis=1) - np.roll(h, 1, axis=1)) / 2.0
    drow = (np.roll(h, -1, axis=0) - np.roll(h, 1, axis=0)) / 2.0
    n = np.stack([-dx * g, drow * g, np.ones_like(h)], axis=-1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return np.round((n * 0.5 + 0.5) * 255).astype(np.uint8)


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def lerp(a, b, t):
    """色（長さ3）や配列どうしの補間。t は 2D 配列でもよい。"""
    a = np.asarray(a, dtype=np.float64)
    b = np.asarray(b, dtype=np.float64)
    if np.ndim(t) == 2 and (a.ndim == 1 or b.ndim == 1 or a.ndim == 3 or b.ndim == 3):
        t = t[..., None]
    return a + (b - a) * t


def save_rgb(path, rgb, quality=92):
    arr = np.clip(np.asarray(rgb), 0.0, 1.0) if np.asarray(rgb).dtype != np.uint8 else np.asarray(rgb)
    if arr.dtype != np.uint8:
        arr = np.round(arr * 255).astype(np.uint8)
    Image.fromarray(arr, "RGB").save(path, quality=quality, subsampling=0)


def save_gray_as_rgb(path, g, quality=92):
    g = np.clip(g, 0.0, 1.0)
    save_rgb(path, np.repeat(g[..., None], 3, axis=2), quality)
