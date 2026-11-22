"""Make the step pictures for the in-app Shortcut guides.

    python3 scripts/guide-images.py

Sources are full iPhone 17 Pro simulator screenshots (1206x2622) in
docs/guide-source/, taken while making an "Open Contacts" and an
"Open YouTube" shortcut. Each picture is a crop with the button to tap
circled in red, written to Launcher/Assets.xcassets/<name>.imageset/.
Boxes and crops are in points (screenshot pixels / 3). Needs Pillow.
"""
import json, os
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "docs/guide-source")
OUT = os.path.join(ROOT, "Launcher/Assets.xcassets")
S = 3
# name: (source, crop top, crop bottom, box to circle (x0, y0, x1, y1))
STEPS = {
    "guide-open-app":      ("vk9hq5", 420, 690, (22, 622, 380, 676)),
    "guide-pick-app":      ("pjq64p",  55, 215, (113, 140, 180, 180)),
    "guide-rename":        ("ry0sym",  60, 330, (75, 82, 330, 128)),
    "guide-allow":         ("y6bkek", 400, 625, (16, 553, 386, 612)),
    "guide-open-urls":     ("dgx4s0",  55, 270, (16, 198, 386, 248)),
    "guide-type-url":      ("vsoxvz",  55, 215, (113, 140, 180, 180)),
    "guide-allow-website": ("jumu8g", 400, 625, (16, 553, 386, 612)),
}
for name, (src, top, bottom, box) in STEPS.items():
    im = Image.open(os.path.join(SRC, src + ".png")).convert("RGB")
    draw = ImageDraw.Draw(im)
    x0, y0, x1, y1 = [v * S for v in box]
    for w in range(10):
        draw.rounded_rectangle((x0 - w, y0 - w, x1 + w, y1 + w), radius=36 + w, outline=(255, 69, 58))
    im = im.crop((0, top * S, im.width, bottom * S))
    im = im.resize((900, int(im.height * 900 / im.width)), Image.LANCZOS)
    folder = os.path.join(OUT, name + ".imageset")
    os.makedirs(folder, exist_ok=True)
    im.save(os.path.join(folder, name + ".png"), optimize=True)
    with open(os.path.join(folder, "Contents.json"), "w") as f:
        json.dump({"images": [{"idiom": "universal", "filename": name + ".png", "scale": "1x"}], "info": {"author": "xcode", "version": 1}}, f)
    print(name, im.size)
