"""Generate original 32x32 pixel-art UI icons for the Digimon vpet game.

Each icon is authored as a 16x16 pixel map (list of 16 strings, 16 chars each)
with a per-icon colour legend, then scaled 2x with nearest-neighbour to 32x32
RGBA PNGs. '.' means transparent. Original art — not derived from Bandai glyphs.
"""
import os
from PIL import Image

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                   "assets", "ui")
os.makedirs(OUT, exist_ok=True)

T = (0, 0, 0, 0)  # transparent


def build(pixels, legend, name):
    assert len(pixels) == 16, f"{name}: need 16 rows, got {len(pixels)}"
    img = Image.new("RGBA", (16, 16), T)
    px = img.load()
    for y, row in enumerate(pixels):
        assert len(row) == 16, f"{name} row {y}: len {len(row)} != 16"
        for x, ch in enumerate(row):
            if ch != ".":
                px[x, y] = legend[ch]
    img.resize((32, 32), Image.NEAREST).save(os.path.join(OUT, name))
    print("wrote", name)


# ---- heart (play / affection) ----
heart = [
    "................",
    "................",
    "..dd......dd....",
    ".dhhd....dhhd...",
    "dhhhhd..dhhhhd..",
    "dhhhhhddhhhhhhd.",
    "dhhhhhhhhhhhhhd.",
    "dhhhhhhhhhhhhhd.",
    ".dhhhhhhhhhhhd..",
    "..dhhhhhhhhhd...",
    "...dhhhhhhhd....",
    "....dhhhhhd.....",
    ".....dhhhd......",
    "......dhd.......",
    ".......d........",
    "................",
]
build(heart, {"d": (150, 20, 30, 255), "h": (235, 60, 70, 255)}, "heart.png")

# ---- food (meat on bone) ----
food = [
    "................",
    "................",
    "...b..........b.",
    "..bkb........bkb",
    "..bkkmmmmmmmbkb.",
    "...bmmMMMMmmmb..",
    "..mmMMMMMMMMmm..",
    ".mmMMMMMMMMMMmm.",
    ".mMMMMMMMMMMMMm.",
    ".mmMMMMMMMMMMmm.",
    "..mmMMMMMMMMmm..",
    "...bmmmmmmmmb...",
    "..bkb......bkb..",
    ".bkb........bkb.",
    ".b............b.",
    "................",
]
build(food, {"b": (240, 225, 180, 255), "k": (120, 100, 70, 255),
             "m": (150, 80, 40, 255), "M": (110, 55, 25, 255)}, "food.png")

# ---- hunger (fork + knife crossed) ----
hunger = [
    "................",
    "..s.s.s....ss...",
    "..s.s.s....ss...",
    "..s.s.s....ss...",
    "..sssss....ss...",
    "...sss.....ss...",
    "...sss.....ss...",
    "....s......ss...",
    "....s......s....",
    "....s......s....",
    "....s......s....",
    "....s......s....",
    "....s......s....",
    "....s......s....",
    "................",
    "................",
]
build(hunger, {"s": (200, 200, 210, 255)}, "hunger.png")

# ---- poop (classic swirl) ----
poop = [
    "................",
    "................",
    ".......PP.......",
    "......PhhP......",
    "......PhhP......",
    ".....PhhhhP.....",
    "....PhhhhhhP....",
    "...PhhhhhhhhP...",
    "...PhpphpphpP...",
    "..PhhhhhhhhhhP..",
    "..PhppphhpppHP..",
    ".PhhhhhhhhhhhhP.",
    ".PhpphhpphhpppP.",
    ".PhhhhhhhhhhhhP.",
    "..PPPPPPPPPPPP..",
    "................",
]
build(poop, {"P": (70, 42, 18, 255), "h": (150, 95, 45, 255),
             "p": (95, 60, 25, 255), "H": (175, 120, 60, 255)}, "poop.png")

# ---- clean (broom) ----
clean = [
    "................",
    "..........nn....",
    ".........nn.....",
    "........nn......",
    ".......nn.......",
    "......nn........",
    ".....nn.........",
    "....nn..........",
    "...nyy..........",
    "..nyyyy.........",
    ".nyyyyyy........",
    ".yYyYyYy........",
    ".yYyYyYy........",
    ".yyYyYyy........",
    "..y.y.y.........",
    "................",
]
build(clean, {"n": (140, 90, 45, 255), "y": (225, 195, 95, 255),
              "Y": (190, 155, 70, 255)}, "clean.png")

# ---- medicine (capsule) ----
medicine = [
    "................",
    "................",
    "..........kk....",
    ".........krrk...",
    "........krrrrk..",
    ".......krrrrk...",
    "......krrrrk.k..",
    ".....krrrrk.k...",
    "....kwwwrk.k....",
    "...kwwwwwk......",
    "..kwwwwwk.......",
    "..kwwwwk........",
    "...kwwk.........",
    "....kk..........",
    "................",
    "................",
]
build(medicine, {"k": (70, 70, 80, 255), "r": (225, 70, 70, 255),
                 "w": (245, 245, 245, 255)}, "medicine.png")

# ---- skull (sick / danger) ----
skull = [
    "................",
    "....wwwwww......",
    "...wwwwwwww.....",
    "..wwwwwwwwww....",
    "..wwkkwwkkww....",
    "..wwkkwwkkww....",
    "..wwwwwwwwww....",
    "..wwwwkkwwww....",
    "..wwwwwwwwww....",
    "...wwwwwwww.....",
    "....wkwkwk......",
    "....wkwkwk......",
    "................",
    "................",
    "................",
    "................",
]
build(skull, {"w": (238, 238, 238, 255), "k": (50, 50, 55, 255)}, "skull.png")

print("done ->", OUT)
