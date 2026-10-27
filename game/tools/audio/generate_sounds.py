"""ゲームの効果音・環境音を合成して assets/audio/ に OGG で書き出す。

ループ（環境音）は周期的に作るので継ぎ目なく鳴り続ける。一発ものは後ろに残響の尾を含む。
使い方: python3 generate_sounds.py [--out ../../assets/audio]
"""
import argparse
import os

import numpy as np

from synth import SR, bandpass, normalize, periodic_lfo, periodic_noise, reverb, t_axis, wrap_add, write_ogg

SURFACES = ("asphalt", "gravel", "wood", "tatami")
STEP_VARIATIONS = 4


# ---------- 環境音（ループ） ----------

def waves(dur, seed=1):
    """桟橋に寄せる夜の波。ゆっくり寄せて砕け、引く音を周期的に並べる。"""
    n = int(dur * SR)
    t = t_axis(n)
    rumble = bandpass(periodic_noise(n, seed, "brown"), 40, 400) * 0.35
    body = periodic_noise(n, seed + 1, "pink", band=(150, 2500))
    hiss = periodic_noise(n, seed + 2, "white", band=(2500, 9000))
    env = np.zeros(n)
    wash = np.zeros(n)
    rng = np.random.default_rng(seed)
    count = max(2, int(dur / 4.0))
    for k in range(count):
        start = int((k + rng.uniform(-0.15, 0.15)) * n / count) % n
        length = int(rng.uniform(3.0, 4.5) * SR)
        tt = np.arange(length) / SR
        shape = np.minimum(tt / 1.2, 1.0) ** 2 * np.exp(-np.maximum(tt - 1.2, 0) / 1.1)
        wrap_add(env, start, shape * rng.uniform(0.6, 1.0))
        foam = np.clip((tt - 1.0) / 0.35, 0, 1) ** 2 * np.exp(-np.maximum(tt - 1.35, 0) / 0.7)
        wrap_add(wash, start, foam * rng.uniform(0.4, 0.8))
    x = rumble + body * (0.15 + 0.85 * env) * 0.6 + hiss * wash * 0.2
    return normalize(reverb(x, 1.2, 0.25), 0.8)


def wind(dur, seed=2):
    """低い夜風。ゆっくり強弱し、ときどき電線が鳴るような細い笛音が混じる。"""
    n = int(dur * SR)
    base = periodic_noise(n, seed, "pink", band=(60, 900))
    gust = 0.35 + 0.4 * periodic_lfo(n, max(1, int(dur / 10)), 0.3) + 0.25 * periodic_lfo(n, max(2, int(dur / 4)), 1.7)
    whistle = periodic_noise(n, seed + 1, "white", band=(520, 640))
    whistle_env = np.clip(periodic_lfo(n, max(1, int(dur / 12)), 2.0) - 0.6, 0, 1) * 2.5
    x = base * gust + whistle * whistle_env * 0.25
    return normalize(x, 0.7)


def insects(dur, seed=3):
    """秋の虫の声（コオロギ・鈴虫のような高い声）。数匹がそれぞれの節回しで鳴く。"""
    n = int(dur * SR)
    out = np.zeros(n)
    rng = np.random.default_rng(seed)
    for _ in range(7):
        carrier = rng.uniform(3800, 5200)
        pulse_rate = rng.uniform(28, 60)
        pulses = rng.integers(3, 9)
        gap = rng.uniform(0.35, 1.2)
        level = rng.uniform(0.25, 1.0)
        pulse_len = int(SR * 0.6 / pulse_rate)
        tp = np.arange(pulse_len) / SR
        pulse = np.sin(2 * np.pi * carrier * tp) * np.sin(np.pi * tp / tp[-1]) ** 2
        chirp = np.zeros(int(SR * pulses / pulse_rate) + pulse_len)
        for p in range(pulses):
            s = int(SR * p / pulse_rate)
            chirp[s:s + pulse_len] += pulse
        pos = rng.uniform(0, dur)
        while pos < dur + rng.uniform(0, gap):
            wrap_add(out, int(pos * SR) % n, chirp * level * rng.uniform(0.8, 1.0))
            pos += len(chirp) / SR + gap * rng.uniform(0.8, 1.2)
    bed = periodic_noise(n, seed + 9, "white", band=(3500, 6000)) * 0.03
    return normalize(reverb(out + bed, 0.8, 0.35), 0.5)


def room_tone(dur, seed=4):
    """屋内の静けさ：電灯と冷蔵庫の低いうなり（60Hz 地域）。"""
    n = int(dur * SR)
    t = t_axis(n)
    hum = 0.5 * np.sin(2 * np.pi * 60 * t) + 0.3 * np.sin(2 * np.pi * 120 * t) + 0.1 * np.sin(2 * np.pi * 180 * t)
    air = periodic_noise(n, seed, "brown", band=(30, 400))
    return normalize(0.35 * hum * (0.8 + 0.2 * periodic_lfo(n, max(1, int(dur / 5)))) + air * 0.6, 0.3)


def lamp_buzz(dur, seed=5):
    """古い街灯の安定器のうなり（120Hz とその倍音）と、かすかなジリジリ音。"""
    n = int(dur * SR)
    t = t_axis(n)
    buzz = sum(np.sign(np.sin(2 * np.pi * 120 * k * t)) / k ** 1.5 for k in (1, 2, 3))
    buzz = bandpass(buzz, 100, 3000)
    sizzle = periodic_noise(n, seed, "white", band=(4000, 10000)) * (0.6 + 0.4 * periodic_lfo(n, max(3, int(dur * 3))))
    return normalize(buzz * 0.8 + sizzle * 0.12, 0.6)


LOOPS = {
    "amb_waves": (waves, 24.0),
    "amb_wind": (wind, 30.0),
    "amb_insects": (insects, 20.0),
    "amb_room": (room_tone, 10.0),
    "lamp_buzz": (lamp_buzz, 4.0),
}


# ---------- 一発もの ----------

def _env(n, attack, decay):
    t = np.arange(n) / SR
    return np.minimum(t / max(attack, 1e-4), 1.0) * np.exp(-np.maximum(t - attack, 0) / decay)


def lamp_click(seed=6):
    """街灯のリレーが入る「カチッ」。"""
    n = int(0.25 * SR)
    tick = periodic_noise(n, seed, "white") * _env(n, 0.0005, 0.003)
    ring = np.sin(2 * np.pi * 2300 * t_axis(n)) * _env(n, 0.0005, 0.02)
    thunk = np.sin(2 * np.pi * 180 * t_axis(n)) * _env(n, 0.001, 0.015)
    return normalize(tick * 0.6 + ring * 0.25 + thunk * 0.4, 0.8)


def footstep(surface, i):
    rng = np.random.default_rng(100 + SURFACES.index(surface) * 10 + i)
    n = int(0.45 * SR)
    t = t_axis(n)
    thump = np.sin(2 * np.pi * rng.uniform(70, 110) * t) * _env(n, 0.002, 0.035)
    if surface == "asphalt":
        scuff = bandpass(periodic_noise(n, rng.integers(1e6), "white"), 700, 4500, periodic=False) * _env(n, 0.004, 0.05)
        x = thump * 0.7 + scuff * rng.uniform(0.35, 0.5)
    elif surface == "gravel":
        grains = np.zeros(n)
        for _ in range(int(rng.integers(40, 70))):
            s = int(abs(rng.normal(0.06, 0.04)) * SR)
            g = periodic_noise(256, int(rng.integers(1e6)), "white") * np.exp(-np.arange(256) / 30)
            if s + 256 < n:
                grains[s:s + 256] += g * rng.uniform(0.2, 1.0)
        x = thump * 0.5 + bandpass(grains, 900, 8000, periodic=False) * 0.6
    elif surface == "wood":
        modes = sum(np.sin(2 * np.pi * f * rng.uniform(0.95, 1.05) * t) * _env(n, 0.001, d)
                    for f, d in ((190, 0.12), (430, 0.08), (780, 0.05)))
        creak = bandpass(periodic_noise(n, int(rng.integers(1e6)), "white"), 400, 1500, periodic=False) * _env(n, 0.02, 0.06)
        x = thump * 0.6 + modes * 0.45 + creak * rng.uniform(0.0, 0.25)
    else:  # tatami
        soft = bandpass(periodic_noise(n, int(rng.integers(1e6)), "pink"), 80, 900, periodic=False) * _env(n, 0.01, 0.06)
        rustle = bandpass(periodic_noise(n, int(rng.integers(1e6)), "white"), 2500, 7000, periodic=False) * _env(n, 0.02, 0.08)
        x = thump * 0.35 + soft * 0.8 + rustle * 0.1
    return normalize(x, rng.uniform(0.6, 0.8))


def ship_horn(seed=7):
    """遠くの船の汽笛。低く、長く、霧の向こうから響く。"""
    n = int(9.0 * SR)
    t = t_axis(n)
    f0 = 108.0
    tone = sum(np.sin(2 * np.pi * f0 * k * t + 0.3 * np.sin(2 * np.pi * 4.5 * t)) / k for k in range(1, 9))
    env = np.clip(t / 0.5, 0, 1) * np.clip((4.2 - t) / 1.2, 0, 1)
    x = bandpass(tone * env, 60, 900, periodic=False)
    return normalize(reverb(x, 4.0, 0.55, periodic=False, damp=1500), 0.8)


def stinger(seed=8):
    """驚かせる演出の音：低いうなりが膨らみ、不協和音の一撃で途切れる。"""
    n = int(5.0 * SR)
    t = t_axis(n)
    swell = np.clip(t / 2.2, 0, 1) ** 2 * (t < 2.4)
    freqs = (196.0, 207.6, 233.1, 311.1)
    cluster = sum(np.sin(2 * np.pi * f * t + 2 * np.sin(2 * np.pi * 5.5 * t)) for f in freqs)
    rise = bandpass(periodic_noise(n, seed, "pink"), 200, 6000, periodic=False) * swell
    hit = (t >= 2.4) * np.exp(-np.maximum(t - 2.4, 0) / 0.9)
    sub = np.sin(2 * np.pi * 42 * t) * hit
    x = cluster * (swell * 0.35 + hit * 0.6) + rise * 0.25 + sub * 0.8
    return normalize(reverb(x, 2.5, 0.4, periodic=False), 0.9)


def ui_page(seed=9):
    """手帳をめくる紙の音。"""
    n = int(0.5 * SR)
    rng = np.random.default_rng(seed)
    crinkle = np.zeros(n)
    for _ in range(25):
        s = int(abs(rng.normal(0.12, 0.08)) * SR)
        g = periodic_noise(400, int(rng.integers(1e6)), "white") * np.exp(-np.arange(400) / 60)
        if s + 400 < n:
            crinkle[s:s + 400] += g * rng.uniform(0.2, 1.0)
    swish = bandpass(periodic_noise(n, seed, "pink"), 1500, 8000, periodic=False) * _env(n, 0.05, 0.12)
    return normalize(bandpass(crinkle, 1800, 9000, periodic=False) * 0.6 + swish * 0.5, 0.6)


def fade_out(x, seconds=0.03):
    """一発ものの末尾をなめらかに消す（途中で切れたときのプチッという音を防ぐ）。"""
    n = min(len(x), int(seconds * SR))
    y = x.copy()
    y[-n:] *= np.cos(np.linspace(0, np.pi / 2, n)) ** 2
    return y


def render_all(quick=False):
    """すべての音を配列で返す（quick=True ならループを短くしてテストを速くする）。"""
    out = {}
    for name, (fn, dur) in LOOPS.items():
        out[name] = fn(min(dur, 3.0) if quick else dur)
    shots = {"lamp_click": lamp_click(), "ship_horn": ship_horn(), "stinger": stinger(), "ui_page": ui_page()}
    for s in SURFACES:
        for i in range(STEP_VARIATIONS):
            shots[f"step_{s}_{i}"] = footstep(s, i)
    for name, x in shots.items():
        out[name] = fade_out(x)
    return out


def generate_all(out_dir):
    os.makedirs(out_dir, exist_ok=True)
    for name, x in render_all().items():
        write_ogg(os.path.join(out_dir, name + ".ogg"), x)


if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    p = argparse.ArgumentParser()
    p.add_argument("--out", default=os.path.join(here, "..", "..", "assets", "audio"))
    a = p.parse_args()
    generate_all(a.out)
    print("sounds written to", os.path.abspath(a.out))
