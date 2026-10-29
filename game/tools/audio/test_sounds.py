"""synth / generate_sounds のテスト。実行: python3 test_sounds.py"""
import os
import sys
import tempfile

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import synth  # noqa: E402
import generate_sounds  # noqa: E402

SR = synth.SR


def loop_ok(x):
    """ループの継ぎ目：端どうしの段差が、波形の中で普通に起きる段差の範囲（99.9%点）に収まり、
    前後の音量もそろっていること。"""
    typical = np.percentile(np.abs(np.diff(x)), 99.9)
    jump = abs(x[-1] - x[0])
    n = int(0.05 * SR)
    rms = lambda a: np.sqrt(np.mean(a ** 2)) + 1e-9  # noqa: E731
    ratio = rms(x[:n]) / rms(x[-n:])
    return jump <= 1.2 * typical + 1e-4 and 0.5 <= ratio <= 2.0


def test_periodic_noise_loops_and_is_normalized():
    x = synth.periodic_noise(SR * 2, seed=1, color="pink")
    assert abs(np.abs(x).max() - 1.0) < 1e-9
    assert loop_ok(x)


def test_bandpass_removes_out_of_band():
    t = np.arange(SR) / SR
    low = np.sin(2 * np.pi * 50 * t)
    mid = np.sin(2 * np.pi * 2000 * t)
    y = synth.bandpass(low + mid, 1000, 5000)
    # 50Hz はほぼ消え、2kHz は残る
    assert np.abs(np.fft.rfft(y))[50] < 0.02 * np.abs(np.fft.rfft(low))[50]
    assert np.abs(np.fft.rfft(y))[2000] > 0.8 * np.abs(np.fft.rfft(mid))[2000]


def test_all_sounds_have_safe_levels_and_loops_are_seamless():
    sounds = generate_sounds.render_all(quick=True)
    assert set(generate_sounds.LOOPS) <= set(sounds)
    for name, x in sounds.items():
        assert np.isfinite(x).all(), name
        peak = np.abs(x).max()
        assert 0.05 < peak <= 0.98, (name, peak)
        if name in generate_sounds.LOOPS:
            assert loop_ok(x), name


def test_one_shots_end_in_silence():
    sounds = generate_sounds.render_all(quick=True)
    for name, x in sounds.items():
        if name not in generate_sounds.LOOPS:
            assert np.abs(x[-64:]).max() < 0.01, name


def test_footstep_variations_differ():
    sounds = generate_sounds.render_all(quick=True)
    for surface in generate_sounds.SURFACES:
        a = sounds[f"step_{surface}_0"]
        b = sounds[f"step_{surface}_1"]
        n = min(len(a), len(b))
        assert np.abs(a[:n] - b[:n]).mean() > 1e-3, surface


def test_lamp_buzz_has_mains_hum():
    x = generate_sounds.render_all(quick=True)["lamp_buzz"]
    spec = np.abs(np.fft.rfft(x))
    f = np.fft.rfftfreq(len(x), 1 / SR)
    band = (f > 60) & (f < 400)
    peak_f = f[band][np.argmax(spec[band])]
    assert abs(peak_f - 120) < 3 or abs(peak_f - 240) < 3, peak_f


def test_chapter2_sounds_exist_with_expected_lengths():
    sounds = generate_sounds.render_all(quick=True)
    lengths = {"phone_vibrate": (1.4, 1.9), "finger_tap": (0.08, 0.25), "power_down": (2.2, 3.0)}
    for name, (lo, hi) in lengths.items():
        assert name in sounds, name
        assert lo <= len(sounds[name]) / SR <= hi, (name, len(sounds[name]) / SR)
    assert "earphone_static" in generate_sounds.LOOPS


def test_phone_vibrate_is_a_low_buzz():
    x = generate_sounds.render_all(quick=True)["phone_vibrate"]
    spec = np.abs(np.fft.rfft(x))
    f = np.fft.rfftfreq(len(x), 1 / SR)
    band = (f > 50) & (f < 2000)
    peak_f = f[band][np.argmax(spec[band])]
    assert 140 <= peak_f <= 210, peak_f


def test_power_down_fades_away():
    x = generate_sounds.render_all(quick=True)["power_down"]
    rms = lambda a: np.sqrt(np.mean(a ** 2))  # noqa: E731
    q = len(x) // 4
    assert rms(x[:q]) > 4 * rms(x[-q:])


def test_write_ogg():
    with tempfile.TemporaryDirectory() as d:
        p = os.path.join(d, "t.ogg")
        synth.write_ogg(p, 0.5 * np.sin(2 * np.pi * 440 * np.arange(SR // 4) / SR))
        assert os.path.getsize(p) > 500


def test_loop_check_detects_a_cut():
    # 途中で切っただけの波形（継ぎ目で値が飛ぶ）は不合格になること
    t = np.arange(int(1.37 * SR)) / SR
    assert not loop_ok(np.sin(2 * np.pi * 3.3 * t) * 0.5 + 0.01 * np.sin(2 * np.pi * 200 * t))


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
