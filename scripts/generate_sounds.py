#!/usr/bin/env python3
"""Синтез игровых звуков TiltMerge в WAV (без внешних файлов).
Запуск: python3 scripts/generate_sounds.py
Создаёт res://assets/audio/*.wav, которые подбирает AudioManager.gd.

Звуки: merge, spawn, combo, game_over, button, music_menu, music_game
"""
import math
import os
import struct
import wave

AUDIO_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
os.makedirs(AUDIO_DIR, exist_ok=True)

SR = 44100  # частота дискретизации


def write_wav(path, samples):
    """samples: list[float] в [-1, 1]"""
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples
        )
        w.writeframes(frames)
    print(f"  ✓ {path}")


def envelope(n, attack=0.01, decay=6.0):
    """ADSR-подобная огибающая: быстрый атак + экспоненциальный спад."""
    return [math.exp(-decay * i / SR) * (1.0 - math.exp(-i / (SR * attack))) for i in range(n)]


def sine(freq, n, amp=0.5):
    return [amp * math.sin(2 * math.pi * freq * i / SR) for i in range(n)]


def merge_sound():
    """Двунотный блик (низкая→высокая), приятный 'клик слияния'."""
    n = int(SR * 0.18)
    out = []
    for i in range(n):
        t = i / SR
        # частота растёт 400 → 800 Гц
        freq = 400 + 400 * (i / n)
        env = math.exp(-8.0 * t)
        out.append(0.5 * env * math.sin(2 * math.pi * freq * t))
    write_wav(os.path.join(AUDIO_DIR, "merge.wav"), out)


def spawn_sound():
    """Короткий низкий 'пуф' появления."""
    n = int(SR * 0.08)
    out = []
    for i in range(n):
        t = i / SR
        env = (1.0 - math.exp(-i / (SR * 0.005))) * math.exp(-25.0 * t)
        out.append(0.35 * env * math.sin(2 * math.pi * 220 * t))
    write_wav(os.path.join(AUDIO_DIR, "spawn.wav"), out)


def combo_sound():
    """Восходящее глиссандо для комбо."""
    n = int(SR * 0.25)
    out = []
    for i in range(n):
        t = i / SR
        freq = 500 + 1200 * (i / n)
        env = math.exp(-5.0 * t)
        out.append(0.4 * env * math.sin(2 * math.pi * freq * t))
    write_wav(os.path.join(AUDIO_DIR, "combo.wav"), out)


def game_over_sound():
    """Нисходящий 'провал'."""
    n = int(SR * 0.7)
    out = []
    for i in range(n):
        t = i / SR
        freq = 400 * math.exp(-1.5 * t)
        env = math.exp(-2.5 * t)
        out.append(0.5 * env * math.sin(2 * math.pi * freq * t))
    write_wav(os.path.join(AUDIO_DIR, "game_over.wav"), out)


def button_sound():
    """Короткий UI-клик."""
    n = int(SR * 0.05)
    out = []
    for i in range(n):
        t = i / SR
        env = math.exp(-40.0 * t)
        out.append(0.3 * env * math.sin(2 * math.pi * 880 * t))
    write_wav(os.path.join(AUDIO_DIR, "button.wav"), out)


def music_track(name, base_freq, duration=8.0):
    """Простая зацикленная подложка (низкая амплитуда)."""
    n = int(SR * duration)
    out = []
    for i in range(n):
        t = i / SR
        # мягкая пульсация + основной тон + квинта
        amp = 0.12 + 0.04 * math.sin(2 * math.pi * 0.25 * t)
        s = amp * (
            0.6 * math.sin(2 * math.pi * base_freq * t)
            + 0.3 * math.sin(2 * math.pi * base_freq * 1.5 * t)
            + 0.1 * math.sin(2 * math.pi * base_freq * 2 * t)
        )
        out.append(s)
    write_wav(os.path.join(AUDIO_DIR, f"{name}.wav"), out)


if __name__ == "__main__":
    print("Синтез звуков TiltMerge...")
    merge_sound()
    spawn_sound()
    combo_sound()
    game_over_sound()
    button_sound()
    music_track("music_menu", 130.81)   # C3
    music_track("music_game", 164.81)   # E3
    print("Готово.")
