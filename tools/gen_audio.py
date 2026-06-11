# -*- coding: utf-8 -*-
"""
Generador de audio sintetizado para Void Sentinel.
Solo stdlib (wave + math + random): produce WAV 44.1 kHz / 16-bit / mono en
audio/sfx/ y audio/music/ con los nombres que espera AudioManager.gd.

Uso:  python tools/gen_audio.py
Regenerable: ajusta parametros y vuelve a ejecutar.
"""
import math
import os
import random
import struct
import wave

SR = 44100
ROOT = os.path.join(os.path.dirname(__file__), "..", "audio")

rng = random.Random(20260611)


def write_wav(path, samples, peak=0.9):
    """Normaliza al pico dado y escribe WAV 16-bit mono."""
    m = max(1e-9, max(abs(s) for s in samples))
    k = peak / m
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = bytearray()
        for s in samples:
            v = int(max(-1.0, min(1.0, s * k)) * 32767)
            frames += struct.pack("<h", v)
        w.writeframes(bytes(frames))
    print("OK", os.path.relpath(path, os.path.dirname(ROOT)), f"({len(samples)/SR:.2f}s)")


def env_exp(i, n, k=5.0):
    """Decay exponencial 1 -> ~0."""
    return math.exp(-k * i / n)


def fade_in_out(samples, ms_in=5, ms_out=20):
    """Anti-click en los extremos."""
    n_in = int(SR * ms_in / 1000)
    n_out = int(SR * ms_out / 1000)
    for i in range(min(n_in, len(samples))):
        samples[i] *= i / n_in
    for i in range(min(n_out, len(samples))):
        samples[-1 - i] *= i / n_out
    return samples


# ════════════════════════════════════════════════════
# SFX
# ════════════════════════════════════════════════════

def sfx_disparo():
    """Zap laser corto: square con barrido 1400->300 Hz."""
    n = int(SR * 0.12)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / n
        f = 1400.0 * (300.0 / 1400.0) ** t
        ph += f / SR
        s = 1.0 if (ph % 1.0) < 0.5 else -1.0
        out.append(s * env_exp(i, n, 6.0) * 0.5)
    return fade_in_out(out)


def sfx_critico():
    """Zap + ping brillante ascendente."""
    n = int(SR * 0.22)
    out = []
    ph1 = ph2 = 0.0
    for i in range(n):
        t = i / n
        f1 = 1900.0 + 800.0 * t          # ping que sube
        f2 = f1 * 1.5                     # armonico brillante
        ph1 += f1 / SR
        ph2 += f2 / SR
        s = 0.7 * math.sin(2 * math.pi * ph1) + 0.3 * math.sin(2 * math.pi * ph2)
        out.append(s * env_exp(i, n, 5.5))
    return fade_in_out(out)


def sfx_muerte():
    """Pequena explosion: ruido con lowpass que se cierra + thump grave."""
    n = int(SR * 0.35)
    out = []
    lp = 0.0
    ph = 0.0
    for i in range(n):
        t = i / n
        # Ruido lowpass: alpha alto al inicio (brillante) -> bajo (apagado).
        alpha = 0.55 * (1.0 - t) + 0.04
        lp += alpha * (rng.uniform(-1, 1) - lp)
        # Thump: sine 150 -> 55 Hz.
        f = 150.0 * (55.0 / 150.0) ** t
        ph += f / SR
        thump = math.sin(2 * math.pi * ph)
        out.append((0.7 * lp + 0.6 * thump) * env_exp(i, n, 5.0))
    return fade_in_out(out)


def sfx_dano_nexus():
    """Golpe grave amenazante."""
    n = int(SR * 0.28)
    out = []
    ph = 0.0
    lp = 0.0
    for i in range(n):
        t = i / n
        f = 110.0 * (50.0 / 110.0) ** t
        ph += f / SR
        body = math.sin(2 * math.pi * ph) + 0.4 * math.sin(4 * math.pi * ph)
        lp += 0.12 * (rng.uniform(-1, 1) - lp)
        out.append((0.85 * body + 0.35 * lp) * env_exp(i, n, 4.5))
    return fade_in_out(out)


def sfx_compra():
    """Blip doble ascendente (confirmacion alegre)."""
    out = []
    for f0, dur in ((660.0, 0.07), (990.0, 0.11)):
        n = int(SR * dur)
        ph = 0.0
        for i in range(n):
            ph += f0 / SR
            s = math.sin(2 * math.pi * ph) + 0.25 * math.sin(6 * math.pi * ph)
            out.append(s * env_exp(i, n, 4.0) * 0.8)
    return fade_in_out(out)


def sfx_game_over():
    """Barrido descendente dramatico con sub."""
    n = int(SR * 1.3)
    out = []
    ph1 = ph2 = 0.0
    for i in range(n):
        t = i / n
        f = 440.0 * (55.0 / 440.0) ** t
        ph1 += f / SR
        ph2 += (f * 0.5) / SR
        saw = 2.0 * (ph1 % 1.0) - 1.0
        sub = math.sin(2 * math.pi * ph2)
        out.append((0.5 * saw + 0.6 * sub) * env_exp(i, n, 3.0))
    return fade_in_out(out, ms_out=120)


# ════════════════════════════════════════════════════
# MÚSICA (loops ambient, mono, volumen contenido)
# ════════════════════════════════════════════════════

NOTE = {  # frecuencias base (octava 2)
    "A": 110.00, "B": 123.47, "C": 130.81, "D": 146.83,
    "E": 164.81, "F": 174.61, "G": 196.00,
}


def freq(name, octave):
    return NOTE[name] * (2 ** (octave - 2))


def pad_chord(out, start, dur, freqs, amp):
    """Suma un acorde 'pad' (sines detuned con ataque/caida suaves)."""
    n = int(SR * dur)
    s0 = int(SR * start)
    for f in freqs:
        det = rng.uniform(-1.5, 1.5)
        ph = rng.uniform(0, 1)
        for i in range(n):
            t = i / n
            # Envelope trapezoidal suave.
            e = min(1.0, t / 0.15, (1.0 - t) / 0.25)
            ph += (f + det) / SR
            idx = s0 + i
            if idx < len(out):
                out[idx] += amp * e * math.sin(2 * math.pi * ph)


def pluck(out, start, dur, f, amp):
    """Nota corta tipo arpegio con decay."""
    n = int(SR * dur)
    s0 = int(SR * start)
    ph = 0.0
    for i in range(n):
        ph += f / SR
        e = math.exp(-5.0 * i / n)
        idx = s0 + i
        if idx < len(out):
            out[idx] += amp * e * (math.sin(2 * math.pi * ph) + 0.3 * math.sin(4 * math.pi * ph))


def music_menu():
    """Pad ambient: Am - F - C - G, 8s por acorde (32s loop)."""
    total = 32.0
    out = [0.0] * int(SR * total)
    prog = [
        [freq("A", 2), freq("C", 3), freq("E", 3)],
        [freq("F", 2), freq("A", 2), freq("C", 3)],
        [freq("C", 2), freq("E", 2), freq("G", 2), freq("C", 3)],
        [freq("G", 2), freq("B", 2), freq("D", 3)],
    ]
    for k, chord in enumerate(prog):
        pad_chord(out, k * 8.0, 8.2 if k < 3 else 8.0, chord, 0.16)
        # Una octava arriba, mas suave (brillo).
        pad_chord(out, k * 8.0, 8.2 if k < 3 else 8.0, [f * 2 for f in chord], 0.05)
    # Destellos de arpegio esporadicos (escala Am pentatonica).
    esc = [freq("A", 3), freq("C", 4), freq("D", 4), freq("E", 4), freq("G", 4)]
    for k in range(16):
        if rng.random() < 0.7:
            pluck(out, k * 2.0 + rng.uniform(0, 0.4), 1.2, rng.choice(esc), 0.05)
    return out


def music_combate():
    """Loop con pulso: bajo en negras (100 BPM) + arpegio menor + hats."""
    bpm = 100.0
    beat = 60.0 / bpm
    bars = 16              # 16 compases de 4/4 ~ 38.4s
    total = bars * 4 * beat
    out = [0.0] * int(SR * total)

    # Progresion por compas: Am Am F G  (x4)
    roots = ["A", "A", "F", "G"]
    for bar in range(bars):
        r = roots[bar % 4]
        base = freq(r, 1)  # bajo profundo
        for b in range(4):
            t0 = (bar * 4 + b) * beat
            pluck(out, t0, beat * 0.9, base, 0.30)          # bajo
            if b % 2 == 1:
                _hat(out, t0 + beat * 0.5, 0.05, 0.045)     # hat en contratiempo
        # Arpegio por compas (corcheas) sobre el acorde.
        chord = [freq(r, 3), freq(r, 3) * 1.1892, freq(r, 3) * 1.4983]  # menor: 1, b3, 5
        for e in range(8):
            if rng.random() < 0.8:
                pluck(out, bar * 4 * beat + e * beat * 0.5, 0.35, chord[e % 3], 0.07)
    # Pad tenue de fondo, todo el loop.
    pad_chord(out, 0.0, total, [freq("A", 2), freq("E", 3)], 0.05)
    return out


def _hat(out, start, dur, amp):
    n = int(SR * dur)
    s0 = int(SR * start)
    hp_prev = 0.0
    prev = 0.0
    for i in range(n):
        x = rng.uniform(-1, 1)
        hp = x - prev + 0.6 * hp_prev   # highpass simple
        prev = x
        hp_prev = hp
        idx = s0 + i
        if idx < len(out):
            out[idx] += amp * hp * math.exp(-8.0 * i / n)


# ════════════════════════════════════════════════════
if __name__ == "__main__":
    write_wav(os.path.join(ROOT, "sfx", "disparo.wav"), sfx_disparo(), peak=0.5)
    write_wav(os.path.join(ROOT, "sfx", "critico.wav"), sfx_critico(), peak=0.6)
    write_wav(os.path.join(ROOT, "sfx", "muerte.wav"), sfx_muerte(), peak=0.7)
    write_wav(os.path.join(ROOT, "sfx", "dano_nexus.wav"), sfx_dano_nexus(), peak=0.8)
    write_wav(os.path.join(ROOT, "sfx", "compra.wav"), sfx_compra(), peak=0.6)
    write_wav(os.path.join(ROOT, "sfx", "game_over.wav"), sfx_game_over(), peak=0.85)
    write_wav(os.path.join(ROOT, "music", "menu.wav"), music_menu(), peak=0.5)
    write_wav(os.path.join(ROOT, "music", "combate.wav"), music_combate(), peak=0.55)
    print("Audio generado.")
