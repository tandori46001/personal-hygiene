#!/usr/bin/env python3
"""
Generate the three iOS 18 AppIcon variants:
- AppIcon-1024.png            (light/default — full color, brand teal background)
- AppIcon-1024-dark.png       (dark — same composition, darker background)
- AppIcon-1024-tinted.png     (tinted — neutral grayscale that the system
                                tints; the gradient becomes a luminance map)

Idempotent: re-running overwrites the three files in
App/PersonalHygiene/Resources/Assets.xcassets/AppIcon.appiconset/.
"""
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw

REPO_ROOT = Path(__file__).resolve().parents[1]
ICON_DIR = REPO_ROOT / "App/PersonalHygiene/Resources/Assets.xcassets/AppIcon.appiconset"
SIZE = 1024


def draw_clock_face(image: Image.Image, *, fg: tuple[int, int, int]) -> None:
    """Mutates `image` in place: draws a minimalist clock face on top."""
    draw = ImageDraw.Draw(image)
    cx = cy = SIZE // 2
    radius = SIZE * 0.34

    # Outer ring (subtle)
    draw.ellipse(
        [cx - radius, cy - radius, cx + radius, cy + radius],
        outline=fg,
        width=18,
    )

    # Hour marks (12 ticks)
    import math

    for i in range(12):
        angle = math.radians(i * 30 - 90)
        inner = radius * 0.85
        outer = radius * 0.97
        x1 = cx + math.cos(angle) * inner
        y1 = cy + math.sin(angle) * inner
        x2 = cx + math.cos(angle) * outer
        y2 = cy + math.sin(angle) * outer
        draw.line([x1, y1, x2, y2], fill=fg, width=14)

    # Hour hand pointing at 10 (305°), minute hand at 2 (60°).
    def hand(angle_deg: float, length_factor: float, width: int) -> None:
        angle = math.radians(angle_deg - 90)
        x2 = cx + math.cos(angle) * radius * length_factor
        y2 = cy + math.sin(angle) * radius * length_factor
        draw.line([cx, cy, x2, y2], fill=fg, width=width)

    hand(305, 0.55, 26)  # hour
    hand(60, 0.78, 18)  # minute

    # Center dot
    dot_r = 24
    draw.ellipse([cx - dot_r, cy - dot_r, cx + dot_r, cy + dot_r], fill=fg)


def make_light() -> Image.Image:
    # Brand teal (#18769F) like the existing icon used.
    image = Image.new("RGBA", (SIZE, SIZE), color=(24, 118, 159, 255))
    draw_clock_face(image, fg=(255, 255, 255))
    return image


def make_dark() -> Image.Image:
    # Same composition, darker base — tweaks for OLED Home Screen "dark" mode.
    image = Image.new("RGBA", (SIZE, SIZE), color=(8, 32, 48, 255))
    draw_clock_face(image, fg=(120, 200, 230))
    return image


def make_tinted() -> Image.Image:
    # iOS 18 tinted appearance: grayscale luminance that the system re-colors.
    # Background is mid-gray; foreground white. The system's tint runs across
    # the alpha-aware luminance so contrast stays readable in any tint hue.
    image = Image.new("RGBA", (SIZE, SIZE), color=(32, 32, 32, 255))
    draw_clock_face(image, fg=(255, 255, 255))
    return image


def main() -> int:
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    make_light().save(ICON_DIR / "AppIcon-1024.png", format="PNG")
    make_dark().save(ICON_DIR / "AppIcon-1024-dark.png", format="PNG")
    make_tinted().save(ICON_DIR / "AppIcon-1024-tinted.png", format="PNG")
    print(f"==> wrote 3 app icon variants to {ICON_DIR.relative_to(REPO_ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
