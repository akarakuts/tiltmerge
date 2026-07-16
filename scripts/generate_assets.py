#!/usr/bin/env python3
"""Генератор плейсхолдер-ассетов TiltMerge.
Создаёт: иконку 512x512, фичеринг-графику 1024x500, и 4 базовых цвета кубиков (для UI-превью).
Не зависит от внешних шрифтов — использует встроенную отрисовку фигур.

Запуск (нужен Pillow):
    python3 scripts/generate_assets.py
"""
import os
from PIL import Image, ImageDraw, ImageFilter

# Палитра tier из data/config.json
PALETTE = {
    1: "#E63946", 2: "#F4A261", 3: "#E9C46A", 4: "#2A9D8F",
    5: "#264653", 6: "#8338EC", 7: "#6A4C2A", 8: "#F1FAEE",
}
BG_DARK = (18, 20, 31)         # #12141F
BG_DARK2 = (28, 31, 46)

ASSETS_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "graphics")
os.makedirs(ASSETS_DIR, exist_ok=True)


def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))


def rounded_square(draw, xy, radius, fill, outline=None, width=0):
    """Скруглённый квадрат."""
    x0, y0, x1, y1 = xy
    draw.rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=fill, outline=outline, width=width)


def draw_cube(draw, cx, cy, size, color_hex, with_glow=False):
    """Рисует один кубик (скруглённый квадрат с бликом)."""
    half = size / 2
    rgb = hex_to_rgb(color_hex)
    # glow (мягкая обводка)
    if with_glow:
        for i in range(6, 0, -1):
            alpha_rgb = tuple(min(255, c + 20) for c in rgb)
            rounded_square(draw, (cx-half-i*2, cy-half-i*2, cx+half+i*2, cy+half+i*2),
                           radius=size*0.25, fill=None, outline=alpha_rgb, width=2)
    # тело
    rounded_square(draw, (cx-half, cy-half, cx+half, cy+half), radius=size*0.25, fill=rgb)
    # блик (верхний левый угол)
    highlight = tuple(min(255, c + 60) for c in rgb)
    hl_size = size * 0.28
    rounded_square(draw, (cx-half*0.55, cy-half*0.55, cx-half*0.55+hl_size, cy-half*0.55+hl_size),
                   radius=hl_size*0.3, fill=highlight)
    # внутренняя обводка для глубины
    dark = tuple(max(0, c - 50) for c in rgb)
    rounded_square(draw, (cx-half, cy-half, cx+half, cy+half), radius=size*0.25,
                   fill=None, outline=dark, width=max(2, int(size*0.03)))


def make_icon(path):
    """Иконка 512x512: 4 кубика разных цветов, сливающиеся в центре."""
    img = Image.new("RGB", (512, 512), BG_DARK)
    draw = ImageDraw.Draw(img)
    # радиальный градиент фона (имитация)
    for r in range(512, 0, -8):
        t = r / 512
        c = tuple(int(BG_DARK[i] * t + BG_DARK2[i] * (1-t)) for i in range(3))
        draw.ellipse((256-r/2, 256-r/2, 256+r/2, 256+r/2), fill=c)
    # кубики: два внизу сливаются → один сверху (композиция)
    draw_cube(draw, 170, 330, 130, PALETTE[1], with_glow=True)  # red
    draw_cube(draw, 342, 330, 130, PALETTE[1], with_glow=True)  # red (merge pair)
    draw_cube(draw, 256, 150, 150, PALETTE[2], with_glow=True)  # orange (result)
    # стрелки слияния (тонкие линии)
    draw.line((200, 290, 240, 210), fill=(255,255,255,128), width=4)
    draw.line((312, 290, 272, 210), fill=(255,255,255,128), width=4)
    img.save(path, "PNG")
    print(f"  ✓ {path}")


def make_feature(path):
    """Фичеринг-графика 1024x500 для Google Play."""
    img = Image.new("RGB", (1024, 500), BG_DARK)
    draw = ImageDraw.Draw(img)
    # градиент слева направо
    for x in range(1024):
        t = x / 1024
        c = tuple(int(BG_DARK[i] * (1-t) + BG_DARK2[i] * t) for i in range(3))
        draw.line((x, 0, x, 500), fill=c)
    # кубики справа (геймплей-намёк)
    draw_cube(draw, 760, 180, 90, PALETTE[1], with_glow=True)
    draw_cube(draw, 870, 180, 90, PALETTE[1], with_glow=True)
    draw_cube(draw, 815, 320, 110, PALETTE[2], with_glow=True)
    draw_cube(draw, 640, 330, 70, PALETTE[3], with_glow=True)
    img.save(path, "PNG")
    print(f"  ✓ {path}")


def make_tier_preview(path):
    """Превью первых 8 tier-цветов как полоска (для UI-заглушки)."""
    img = Image.new("RGB", (512, 64), BG_DARK)
    draw = ImageDraw.Draw(img)
    for i in range(8):
        draw_cube(draw, 32 + i*64, 32, 50, PALETTE[i+1])
    img.save(path, "PNG")
    print(f"  ✓ {path}")


if __name__ == "__main__":
    print("Генерация ассетов TiltMerge...")
    make_icon(os.path.join(ASSETS_DIR, "icon.png"))
    make_feature(os.path.join(ASSETS_DIR, "feature_graphic.png"))
    make_tier_preview(os.path.join(ASSETS_DIR, "tier_preview.png"))
    print("Готово.")
