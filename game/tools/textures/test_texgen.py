"""texgen / generate_textures のテスト。実行: python3 test_texgen.py"""
import os
import sys
import tempfile

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import texgen  # noqa: E402
import generate_textures  # noqa: E402
import import_photo  # noqa: E402


def _seam_ok(img):
    """右端→左端、下端→上端のつなぎ目の段差が、内部の隣接差と同程度であること。"""
    a = np.asarray(img, dtype=np.float64)
    if a.ndim == 3:
        a = a[..., :3].mean(axis=2)
    inner_x = np.abs(np.diff(a, axis=1)).mean()
    inner_y = np.abs(np.diff(a, axis=0)).mean()
    seam_x = np.abs(a[:, -1] - a[:, 0]).mean()
    seam_y = np.abs(a[-1, :] - a[0, :]).mean()
    # 画像（0〜255）は JPEG の量子化誤差として 1 段階までの差を許す
    tol = 1.0 if a.max() > 1.5 else 1e-6
    return seam_x <= 2.5 * inner_x + tol and seam_y <= 2.5 * inner_y + tol


def test_fbm_range_and_determinism():
    h = texgen.fbm(64, beta=2.0, seed=3)
    assert h.shape == (64, 64)
    assert abs(h.min()) < 1e-9 and abs(h.max() - 1) < 1e-9
    assert np.array_equal(h, texgen.fbm(64, beta=2.0, seed=3))
    assert not np.array_equal(h, texgen.fbm(64, beta=2.0, seed=4))


def test_fbm_is_tileable():
    assert _seam_ok(texgen.fbm(128, beta=1.5, seed=1))


def test_anisotropic_fbm_is_tileable():
    assert _seam_ok(texgen.fbm(128, beta=1.8, seed=2, stretch=(6.0, 1.0)))


def test_worley_is_tileable():
    f1, f2 = texgen.worley(128, cells=8, seed=5)
    assert _seam_ok(f1) and _seam_ok(f2)
    assert (f2 >= f1 - 1e-9).all()


def test_flat_height_gives_up_normal():
    n = texgen.normal_from_height(np.zeros((8, 8)), 4.0)
    assert (n[..., 0] == 128).all() and (n[..., 1] == 128).all() and (n[..., 2] == 255).all()


def test_normal_points_away_from_slope():
    # 右に行くほど高い → 法線は左（R < 128）。下に行くほど高い → OpenGL では上向き成分が正（G > 128）
    ramp_x = np.tile(np.linspace(0, 1, 16), (16, 1))
    assert texgen.normal_from_height(ramp_x, 4.0)[8, 8, 0] < 128
    ramp_down = ramp_x.T
    assert texgen.normal_from_height(ramp_down, 4.0)[8, 8, 1] > 128


def test_all_materials_generate_tileable_maps():
    with tempfile.TemporaryDirectory() as d:
        generate_textures.generate_all(d, size=96)
        for name in generate_textures.MATERIALS:
            for kind in ("albedo", "normal", "roughness"):
                path = os.path.join(d, name, kind + ".jpg")
                assert os.path.exists(path), path
                img = Image.open(path)
                assert img.size == (96, 96), path
                assert _seam_ok(img), path


def test_stop_marking_has_transparent_background():
    with tempfile.TemporaryDirectory() as d:
        generate_textures.generate_stop_marking(d, size=(256, 128))
        img = Image.open(os.path.join(d, "stop_marking.png"))
        assert img.mode == "RGBA"
        a = np.asarray(img)[..., 3]
        assert a.min() == 0 and a.max() > 200


def test_photo_maps_from_flat_image():
    rgb = np.full((64, 64, 3), 120, dtype=np.uint8)
    albedo, normal, rough = import_photo.derive_maps(rgb, size=32, normal_strength=4.0, rough_base=0.7, rough_range=0.3)
    assert albedo.shape == (32, 32, 3) and normal.shape == (32, 32, 3) and rough.shape == (32, 32)
    assert (normal[..., 2] == 255).all()
    assert np.allclose(rough, 0.7, atol=0.02)


def test_photo_maps_stay_tileable():
    h = texgen.fbm(128, 1.2, 9)
    rgb = np.round(np.repeat(h[..., None], 3, axis=2) * 255).astype(np.uint8)
    albedo, normal, rough = import_photo.derive_maps(rgb, size=96, normal_strength=4.0, rough_base=0.6, rough_range=0.4)
    assert _seam_ok(albedo) and _seam_ok(normal) and _seam_ok(rough)
    assert rough.min() >= 0.0 and rough.max() <= 1.0


if __name__ == "__main__":
    failed = 0
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        try:
            t()
            print("ok  ", t.__name__)
        except Exception as e:  # noqa: BLE001
            failed += 1
            print("FAIL", t.__name__, repr(e))
    print(f"{len(tests)} tests, {failed} failures")
    sys.exit(1 if failed else 0)
