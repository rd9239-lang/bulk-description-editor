"""音の試聴用ミックス（約45秒）を作る。ゲームの序盤をなぞる：桟橋 → 通り → 自宅 → ラジオ → 驚かせる演出。

使い方: python3 make_preview.py --out preview.mp3
"""
import argparse
import os
import subprocess
import tempfile

import numpy as np

import generate_sounds as g
from synth import SR, bandpass, normalize, write_wav

DUR = 46.0


def place(buf, start_s, sig, gain=1.0):
    s = int(start_s * SR)
    e = min(len(buf), s + len(sig))
    if s < len(buf):
        buf[s:e] += sig[:e - s] * gain


def looped(sig, n):
    reps = int(np.ceil(n / len(sig)))
    return np.tile(sig, reps)[:n]


def ramp(n, points):
    """points: [(秒, 値), ...] を直線でつないだ音量の変化"""
    t = np.arange(n) / SR
    xs, ys = zip(*points)
    return np.interp(t, xs, ys)


def sos_timeline(unit=0.22, dash=3.6, char_gap=3.4):
    """本物の娘の打ち癖での SOS（揺らぎなし）。(点灯開始, 長さ) の列"""
    on, t = [], 0.0
    for ci, ch in enumerate(["...", "---", "..."]):
        if ci:
            t += unit * char_gap
        for si, sym in enumerate(ch):
            if si:
                t += unit
            d = unit if sym == "." else unit * dash
            on.append((t, d))
            t += d
    return on, t


def main(out):
    s = g.render_all()
    n = int(DUR * SR)
    mix = np.zeros(n)
    outdoor = np.zeros(n)

    outdoor += looped(s["amb_waves"], n) * ramp(n, [(0, 0.9), (9, 0.9), (16, 0.25), (46, 0.15)])
    outdoor += looped(s["amb_wind"], n) * 0.25
    outdoor += looped(s["amb_insects"], n) * ramp(n, [(0, 0.05), (9, 0.1), (13, 0.55), (46, 0.55)])
    outdoor += looped(s["lamp_buzz"], n) * ramp(n, [(0, 0), (12, 0), (14.5, 0.25), (17, 0)])
    place(outdoor, 3.5, s["ship_horn"], 0.6)
    # 遠くの路地の街灯：SOS のたびにリレーが鳴る
    on, cycle = sos_timeline()
    for start in np.arange(14.0, 30.0, cycle + 4.0):
        for t, d in on:
            place(outdoor, start + t, s["lamp_click"], 0.18)
            place(outdoor, start + t + d, s["lamp_click"], 0.12)
    # 22 秒で家に入る：外の音をこもらせて小さくする
    muffled = bandpass(outdoor, 0, 900, periodic=False) * 0.35
    inside = ramp(n, [(0, 0), (21.5, 0), (22.5, 1), (46, 1)])
    mix += outdoor * (1 - inside) + muffled * inside
    mix += looped(s["amb_room"], n) * inside * 0.35

    # 足音：桟橋（木）→ 道（アスファルト）→ 空き地（砂利）→ 室内（畳）
    t, i = 1.5, 0
    for surface, until in (("wood", 9.0), ("asphalt", 15.5), ("gravel", 21.0), ("tatami", 25.0)):
        while t < until:
            place(mix, t, s[f"step_{surface}_{i % 4}"], 0.55)
            t += 0.28
            i += 1
        t += 0.1 if surface != "gravel" else 0.6
    place(mix, 26.0, s["ui_page"], 0.6)

    # ラジオ：雑音の中から SOS のビープ
    rn = int(8.0 * SR)
    rng = np.random.default_rng(3)
    static = bandpass(rng.normal(size=rn), 300, 5000, periodic=False) * 0.12
    tone = np.zeros(rn)
    tt = np.arange(rn) / SR
    for t0, d in on:
        for k in range(2):
            m = (tt >= t0 + k * (cycle + 0.8)) & (tt < t0 + d + k * (cycle + 0.8))
            tone[m] = np.sin(2 * np.pi * 600 * tt[m]) * 0.25
    radio = (static + tone) * np.minimum(tt / 1.5, 1.0)
    place(mix, 29.0, radio)

    place(mix, 39.5, s["stinger"], 0.9)
    mix = normalize(mix, 0.9)
    with tempfile.TemporaryDirectory() as d:
        wav = os.path.join(d, "p.wav")
        write_wav(wav, mix)
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", wav, "-c:a", "libmp3lame", "-q:a", "3", out], check=True)


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--out", default="preview.mp3")
    main(p.parse_args().out)
