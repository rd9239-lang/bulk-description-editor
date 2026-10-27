"""効果音合成の部品（numpy のみ）。

ループ用の音は「周期的」に作る（FFT で合成・加工する）ので、最後と最初が自然につながる。
"""
import os
import subprocess
import tempfile
import wave

import numpy as np

SR = 44100


def t_axis(n):
    return np.arange(n) / SR


def periodic_noise(n, seed=0, color="white", band=None):
    """周期的なノイズ（-1〜1）。color: white / pink / brown。band=(lo, hi) で帯域を絞る。"""
    rng = np.random.default_rng(seed)
    spec = rng.normal(size=n // 2 + 1) + 1j * rng.normal(size=n // 2 + 1)
    f = np.fft.rfftfreq(n, 1 / SR)
    f[0] = f[1]
    if color == "pink":
        spec /= np.sqrt(f)
    elif color == "brown":
        spec /= f
    spec[0] = 0
    if band:
        spec *= _band_mask(f, band[0], band[1])
    x = np.fft.irfft(spec, n)
    return x / np.abs(x).max()


def _band_mask(f, lo, hi, soft=0.15):
    """なめらかな肩をもつ帯域通過のマスク（リンギングを抑える）。"""
    m = np.ones_like(f)
    if lo:
        w = max(lo * soft, 5.0)
        m *= np.clip((f - (lo - w)) / (2 * w), 0, 1)
    if hi:
        w = max(hi * soft, 5.0)
        m *= np.clip(((hi + w) - f) / (2 * w), 0, 1)
    return m


def bandpass(x, lo, hi, periodic=True):
    """FFT による帯域通過。periodic=False ならゼロ詰めして端の回り込みを防ぐ。"""
    n = len(x)
    m = n if periodic else int(2 ** np.ceil(np.log2(n * 2)))
    spec = np.fft.rfft(x, m)
    spec *= _band_mask(np.fft.rfftfreq(m, 1 / SR), lo, hi)
    return np.fft.irfft(spec, m)[:n]


def reverb(x, seconds=1.5, wet=0.3, periodic=True, seed=99, damp=4000.0):
    """減衰するノイズとの畳み込みによる簡易残響。一発ものは尾の分の無音を後ろに足しておくこと。"""
    n_ir = int(seconds * SR)
    t = t_axis(n_ir)
    ir = periodic_noise(n_ir, seed, "white") * np.exp(-t * 6.9 / seconds)
    ir = bandpass(ir, 80, damp, periodic=False)
    ir /= np.sqrt(np.sum(ir ** 2)) + 1e-12
    n = len(x)
    if periodic:
        h = np.zeros(n)
        h[:min(n, n_ir)] = ir[:n]
        wet_sig = np.fft.irfft(np.fft.rfft(x) * np.fft.rfft(h), n)
    else:
        m = int(2 ** np.ceil(np.log2(n + n_ir)))
        wet_sig = np.fft.irfft(np.fft.rfft(x, m) * np.fft.rfft(ir, m), m)[:n]
    return (1 - wet) * x + wet * wet_sig


def wrap_add(buf, start, sig):
    """ループ用：はみ出した部分を先頭へ回り込ませて足す。"""
    n = len(buf)
    for i in range(0, len(sig), n):
        part = sig[i:i + n]
        s = (start + i) % n
        k = min(len(part), n - s)
        buf[s:s + k] += part[:k]
        if k < len(part):
            buf[:len(part) - k] += part[k:]


def normalize(x, peak=0.9):
    m = np.abs(x).max()
    return x * (peak / m) if m > 0 else x


def periodic_lfo(n, cycles, phase=0.0):
    """ループ長にちょうど cycles 周期入る 0〜1 のゆらぎ。"""
    return 0.5 + 0.5 * np.sin(2 * np.pi * cycles * np.arange(n) / n + phase)


def write_wav(path, x):
    pcm = np.clip(np.round(x * 32767), -32768, 32767).astype(np.int16)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def write_ogg(path, x, quality=5):
    with tempfile.TemporaryDirectory() as d:
        tmp = os.path.join(d, "in.wav")
        write_wav(tmp, x)
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", tmp, "-c:a", "libvorbis", "-q:a", str(quality), path], check=True)
