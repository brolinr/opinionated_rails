#!/usr/bin/env python3
"""Generates the docs site's social-sharing image and icon PNGs.

    python3 docs/_tools/social_card.py

Writes docs/assets/images/social-card.png (1200x630, Open Graph / Twitter), favicon-32.png and
apple-touch-icon.png. The outputs are committed, so the site build needs neither Python nor fonts.
Needs Pillow (pip install pillow) and the system fonts listed below (macOS paths; edit for Linux).
"""
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "images")
FONT_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
FONT_REGULAR = "/System/Library/Fonts/Supplemental/Arial.ttf"
FONT_MONO = "/System/Library/Fonts/Menlo.ttc"

RUBY = (180, 35, 58)
INK = (20, 22, 28)
MUTED = (107, 100, 112)
TERM = (20, 22, 28)
WHITE = (255, 255, 255)


def font(path, size):
    return ImageFont.truetype(path, size)


def gradient(width, height, top, bottom):
    img = Image.new("RGB", (width, height), top)
    px = img.load()
    for y in range(height):
        t = y / (height - 1)
        row = tuple(round(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        for x in range(width):
            px[x, y] = row
    return img


def draw_mark(size):
    """The logo from assets/images/logo.svg (a 32-unit grid), at `size` pixels, with transparency."""
    scale = 4  # supersample for smooth edges
    s = size * scale
    k = s / 32.0
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, s - 1, s - 1], radius=8 * k, fill=RUBY + (255,))

    def line(points, alpha):
        d.line([(x * k, y * k) for x, y in points], fill=WHITE + (alpha,), width=round(2.2 * k), joint="curve")

    line([(8, 21.5), (16, 25), (24, 21.5)], 140)
    line([(8, 16.5), (16, 20), (24, 16.5)], 205)
    d.polygon([(8 * k, 11.5 * k), (16 * k, 8 * k), (24 * k, 11.5 * k), (16 * k, 15 * k)], fill=WHITE + (255,))
    return img.resize((size, size), Image.LANCZOS)


def social_card():
    w, h = 1200, 630
    card = gradient(w, h, (255, 255, 255), (251, 238, 240))
    d = ImageDraw.Draw(card)

    # soft ruby glow, top left
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([-260, -300, 620, 460], fill=RUBY + (46,))
    glow = glow.filter(ImageFilter.GaussianBlur(70))
    card = Image.alpha_composite(card.convert("RGBA"), glow)
    d = ImageDraw.Draw(card)

    card.alpha_composite(draw_mark(132), (84, 84))
    d.text((240, 112), "opinionated_rails", font=font(FONT_BOLD, 44), fill=INK)
    d.text((240, 168), "Rails 8 generator", font=font(FONT_REGULAR, 26), fill=MUTED)

    headline = font(FONT_BOLD, 74)
    d.text((84, 270), "Start a Rails app with", font=headline, fill=INK)
    d.text((84, 356), "your choices already made.", font=headline, fill=INK)

    d.text((84, 462), "Composable, tested options. Checked to boot and pass their own scans.",
           font=font(FONT_REGULAR, 28), fill=MUTED)

    # install command pill
    mono = font(FONT_MONO, 28)
    text = "gem install opinionated_rails"
    pad_x, pad_y = 26, 18
    tw = d.textlength("$ " + text, font=mono)
    box = [84, 520, 84 + tw + pad_x * 2, 520 + 28 + pad_y * 2 + 4]
    d.rounded_rectangle(box, radius=14, fill=TERM)
    d.text((84 + pad_x, 520 + pad_y), "$", font=mono, fill=(125, 134, 151))
    d.text((84 + pad_x + d.textlength("$ ", font=mono), 520 + pad_y), text, font=mono, fill=(230, 232, 238))

    d.text((w - 84, h - 72), "brolinr.github.io/opinionated_rails", font=font(FONT_REGULAR, 24),
           fill=MUTED, anchor="ra")
    d.rectangle([0, h - 10, w, h], fill=RUBY)
    card.convert("RGB").save(os.path.join(OUT, "social-card.png"), optimize=True)


def icons():
    draw_mark(32).save(os.path.join(OUT, "favicon-32.png"), optimize=True)
    # iOS draws its own rounded corners, so give it a full-bleed square.
    bg = Image.new("RGB", (180, 180), RUBY)
    mark = draw_mark(180).convert("RGBA")
    bg.paste(mark, (0, 0), mark)
    inner = Image.new("RGB", (180, 180), RUBY)
    inner.paste(draw_mark(124), (28, 28), draw_mark(124))
    inner.save(os.path.join(OUT, "apple-touch-icon.png"), optimize=True)


if __name__ == "__main__":
    social_card()
    icons()
    print("wrote social-card.png, favicon-32.png, apple-touch-icon.png in", os.path.normpath(OUT))
