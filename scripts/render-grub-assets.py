#!/usr/bin/env python3
"""Génère les ressources raster statiques du thème GRUB Nexora.

Prérequis : Pillow. Aucun périphérique bloc ni fichier système n'est touché.
"""
from pathlib import Path
from math import cos, pi
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "branding"
OUT.mkdir(parents=True, exist_ok=True)
W, H = 1920, 1080

# Dégradé sombre horizontal, adapté à un menu placé à gauche.
pixels = []
for y in range(H):
    fy = y / (H - 1)
    for x in range(W):
        fx = x / (W - 1)
        # Légèrement plus sombre sous le menu, avec une lueur bleu-nuit à droite.
        glow = max(0.0, 1.0 - (((x - 1450) / 900) ** 2 + ((y - 490) / 700) ** 2) ** 0.5)
        r = int(8 + 7 * fx + 3 * glow)
        g = int(11 + 7 * fx + 5 * glow)
        b = int(21 + 17 * fx + 20 * glow)
        pixels.append((min(r, 22), min(g, 30), min(b, 58)))
image = Image.new("RGB", (W, H))
image.putdata(pixels)

# Voile radial bleu-violet derrière l'emblème.
light = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ld = ImageDraw.Draw(light)
for radius, alpha in [(390, 5), (310, 7), (230, 9)]:
    ld.ellipse((1450-radius, 500-radius, 1450+radius, 500+radius), fill=(81, 89, 255, alpha))
light = light.filter(ImageFilter.GaussianBlur(85))
image = Image.alpha_composite(image.convert("RGBA"), light)

# Dessine l'hexagone et son étoile en couches, pour un halo discret compatible GRUB.
mark_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(mark_layer)
cx, cy, radius = 1450, 500, 275
points = [(cx + radius*cos(pi/3*i), cy + radius*__import__('math').sin(pi/3*i)) for i in range(6)]
points = [(round(x), round(y)) for x, y in points]
d.line(points + [points[0]], fill=(79, 218, 255, 90), width=7, joint="curve")
inner_r = 226
inner = [(round(cx + inner_r*cos(pi/3*i)), round(cy + inner_r*__import__('math').sin(pi/3*i))) for i in range(6)]
d.line(inner + [inner[0]], fill=(143, 105, 255, 50), width=3, joint="curve")
star = [(cx,cy-120),(cx+30,cy-30),(cx+120,cy),(cx+30,cy+30),(cx,cy+120),(cx-30,cy+30),(cx-120,cy),(cx-30,cy-30)]
d.polygon(star, fill=(104, 225, 255, 115))
mark_layer = mark_layer.filter(ImageFilter.GaussianBlur(13))
image = Image.alpha_composite(image, mark_layer)
sharp = Image.new("RGBA", (W, H), (0, 0, 0, 0))
s = ImageDraw.Draw(sharp)
s.line(points + [points[0]], fill=(107, 135, 255, 118), width=3, joint="curve")
s.line(inner + [inner[0]], fill=(72, 223, 255, 52), width=2, joint="curve")
s.polygon(star, fill=(174, 242, 255, 150))
image = Image.alpha_composite(image, sharp)

# Identité de marque en haut à gauche, loin du menu principal.
def load_font(size: int, bold: bool = False):
    candidates = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation2/LiberationSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/liberation2/LiberationSans-Regular.ttf",
    ]
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()

brand = Image.new("RGBA", (W, H), (0, 0, 0, 0))
b = ImageDraw.Draw(brand)
small_cx, small_cy, small_r = 115, 136, 42
small = [(round(small_cx+small_r*cos(pi/3*i)),round(small_cy+small_r*__import__('math').sin(pi/3*i))) for i in range(6)]
b.line(small+[small[0]], fill=(147, 127, 255, 235), width=3, joint="curve")
b.polygon([(small_cx,small_cy-20),(small_cx+5,small_cy-5),(small_cx+20,small_cy),(small_cx+5,small_cy+5),(small_cx,small_cy+20),(small_cx-5,small_cy+5),(small_cx-20,small_cy),(small_cx-5,small_cy-5)], fill=(95,224,255,235))
b.text((177, 94), "NEXORA OS", font=load_font(34, True), fill=(237,240,255,245), stroke_width=0)
b.text((179, 140), "UEFI START MENU", font=load_font(15), fill=(132,151,189,230))
b.line((177, 171, 414, 171), fill=(113,112,255,120), width=2)
image = Image.alpha_composite(image, brand)

# Fine accent line at the bottom, purely decorative.
footer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
f = ImageDraw.Draw(footer)
f.line((110, 1000, 1810, 1000), fill=(101, 126, 190, 35), width=1)
f.text((112, 1018), "NEXORA  /  SECURE STARTUP", font=load_font(12), fill=(118, 136, 173, 150))
image = Image.alpha_composite(image, footer)

bg_path = OUT / "nexora-grub-bg.png"
image.convert("RGB").save(bg_path, optimize=True)

# Petit emblème transparent utilisable comme icône dans d'autres composants GRUB.
SIZE = 256
icon = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
idraw = ImageDraw.Draw(icon)
icx, icy, ir = 128, 128, 105
ip = [(round(icx+ir*cos(pi/3*i)),round(icy+ir*__import__('math').sin(pi/3*i))) for i in range(6)]
idraw.line(ip+[ip[0]], fill=(151, 119, 255, 245), width=5, joint="curve")
idraw.line([(round(icx+ir*.78*cos(pi/3*i)),round(icy+ir*.78*__import__('math').sin(pi/3*i))) for i in range(6)]+[(round(icx+ir*.78),icy)], fill=(65,231,255,90), width=2, joint="curve")
idraw.polygon([(128,76),(140,116),(180,128),(140,140),(128,180),(116,140),(76,128),(116,116)], fill=(192,247,255,245))
icon = icon.filter(ImageFilter.GaussianBlur(0.35))
icon_path = OUT / "nexora-grub-mark.png"
icon.save(icon_path, optimize=True)
print(f"Créé : {bg_path}")
print(f"Créé : {icon_path}")
