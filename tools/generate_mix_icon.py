"""Generate the Spotify-inspired broadcast arcs / Absorb waveform icon.

Requires Pillow. This independent app is not endorsed by Spotify.
Run from anywhere; existing iOS asset dimensions are preserved.
"""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SCALE = 4
canvas = Image.new('RGB', (1024 * SCALE, 1024 * SCALE), '#101010')
draw = ImageDraw.Draw(canvas)

def curve(start, control, end, width, color):
    points = []
    for i in range(101):
        t = i / 100
        points.append(tuple(round(((1-t)**2 * start[j] + 2*(1-t)*t * control[j] + t*t * end[j]) * SCALE) for j in (0, 1)))
    draw.line(points, fill=color, width=width * SCALE)
    r = width * SCALE / 2
    for x, y in points:
        draw.ellipse((x-r, y-r, x+r, y+r), fill=color)

for a, b, c, width in [
    ((240, 280), (500, 135), (790, 300), 48),
    ((278, 362), (508, 238), (747, 378), 43),
    ((320, 438), (514, 338), (701, 449), 38),
]:
    curve(a, b, c, width, '#1ED760')

for index, height in enumerate([108, 182, 256, 330, 386, 330, 256, 182, 108]):
    x = 272 + index * 60
    y = 672
    color = '#BFA4FF' if index % 2 else '#48B5AD'
    draw.rounded_rectangle(tuple(round(v*SCALE) for v in (x-18, y-height/2, x+18, y+height/2)), radius=18*SCALE, fill=color)

icon = canvas.resize((1024, 1024), Image.Resampling.LANCZOS)
for relative in ['icon.png', 'assets/icon/app_icon.png']:
    icon.save(ROOT / relative)
for path in (ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset').glob('*.png'):
    with Image.open(path) as existing:
        size = existing.size
    icon.resize(size, Image.Resampling.LANCZOS).save(path)
print('Generated master and iOS app icons; original Absorb repository untouched.')
