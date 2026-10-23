"""DigiVice 自绘精灵源文件。

全部原创，风格参照 Digital Monster Color 的 16×16 彩色语言：
1px 暗轮廓、左上光源、每种材质独立 3 级色阶、不用抗锯齿与抖动。

改法：只改 ROWS，跑 `python3 Art/build.py`，输出到 Resources/Sprites/。
"""

from PIL import Image
import os

# 统一调色板：跨兽共享，保证一套语言
C = {
    ".": (0, 0, 0, 0),
    "k": (20, 16, 14, 255),      # 轮廓
    "K": (0, 0, 0, 255),
    "g": (106, 112, 120, 255),   # 灰
    "G": (58, 64, 72, 255),      # 灰暗
    "w": (234, 232, 224, 255),   # 米白
    "W": (255, 255, 255, 255),   # 高光
    "y": (237, 198, 25, 255),    # 黄
    "Y": (255, 232, 112, 255),   # 黄亮
    "o": (224, 112, 0, 255),     # 橙
    "O": (255, 160, 32, 255),    # 橙亮
    "r": (207, 31, 40, 255),     # 红
    "R": (255, 90, 80, 255),     # 红亮
    "p": (237, 160, 180, 255),   # 粉
    "P": (255, 208, 220, 255),   # 粉亮
    "n": (47, 154, 64, 255),     # 绿
    "N": (90, 208, 106, 255),    # 绿亮
    "q": (26, 106, 42, 255),     # 绿暗
    "b": (42, 122, 176, 255),    # 蓝
    "B": (90, 176, 224, 255),    # 蓝亮
    "v": (90, 58, 112, 255),     # 紫
    "V": (138, 90, 160, 255),    # 紫亮
    "m": (182, 183, 182, 255),   # 金属
    "M": (106, 107, 112, 255),   # 金属暗
    "t": (106, 58, 32, 255),     # 棕
    "T": (160, 90, 48, 255),     # 棕亮
    "c": (60, 200, 200, 255),    # 青（水系）
    "C": (120, 235, 235, 255),   # 青亮
}

ROWS = {}

# ---------------------------------------------------------------- 蛋
ROWS["digitama"] = [
    "................",
    "................",
    "......kkkk......",
    "....kkwwwwkk....",
    "...kwwwwwwwwk...",
    "..kwwwWwwwwwwk..",
    "..kwwWwwwwWwwk..",
    "..kwwwwwwwwwwk..",
    "..kwWwwwwwwWwk..",
    "..kwwwwwwwwwwk..",
    "..kwwwWwwwwwwk..",
    "...kwwwwwwwwk...",
    "....kkwwwwkk....",
    "......kkkk......",
    "................",
    "................",
]

# ---------------------------------------------------------------- 幼年期 I
ROWS["botamon"] = [
    "................",
    "................",
    "................",
    ".....kkkkk......",
    "...kkgggggkk....",
    "...kgggggggk....",
    "..kgggggggggk...",
    "..kgYggYggggk...",
    "..kgYggYggggk...",
    "..kgggggggGGk...",
    "..kgggrrgggGk...",
    "...kgggggGGk....",
    "....kkgggkk.....",
    "......kkk.......",
    "................",
    "................",
]

# ---------------------------------------------------------------- 幼年期 II
ROWS["koromon"] = [
    "................",
    "................",
    "....k......k....",
    "....kk....kk....",
    "...kppkkkkppk...",
    "..kppppppppppk..",
    "..kppppppppppk..",
    ".kppRppppRppppk.",
    ".kppRppppRppppk.",
    ".kppppppppppppk.",
    ".kppppprrppppPk.",
    "..kppppppppppk..",
    "...kppppppppPk..",
    "....kkppppkk....",
    "......kkkk......",
    "................",
]

# ---------------------------------------------------------------- 成长期
ROWS["agumon"] = [
    "................",
    "................",
    "......kkkk......",
    ".....kyyyyk.....",
    "....kyyyyyyk....",
    "....kRRyyRRk....",
    "....kRRyyRRk....",
    "....kyyyyyyk....",
    "....kkyyyykk....",
    "...kkkkkkkkkk...",
    "...kyyyyyyyyk...",
    "..kyYyyyyyyYyk..",
    "..kyykyyyykyyk..",
    "..kkyyyyyyyykk..",
    "....kyy..yyk....",
    "...kkyk..kykk...",
]

ROWS["betamon"] = [
    "................",
    ".......kk.......",
    "......koOk......",
    ".....koook......",
    "....kgggggk.....",
    "...kgggggggk....",
    "..kgggggggggk...",
    "..kgwgggggggk...",
    "..kgwgRgRgggk...",
    "..kgggggggggk...",
    "...kgggggggk....",
    "....kgggggk.....",
    ".....kgkgk......",
    ".....kk.kk......",
    "................",
    "................",
]

# ---------------------------------------------------------------- 成熟期
ROWS["greymon"] = [
    "................",
    "..kk.......kk...",
    ".kttk.....kttk..",
    "..kttkkkkkttk...",
    "...kktttttkk....",
    "...koooooook....",
    "..koRRoooRRok...",
    "..koRRoooRRok...",
    "..koooooooook...",
    "..kkkkkkkkkkkk..",
    ".ktoooooooootk..",
    "kgoooooooooooogk",
    "kgookkkkkkkkoogk",
    ".kook....kook...",
    "..kkk....kkk....",
    "................",
]

ROWS["tyranomon"] = [
    "................",
    ".....kkkkk......",
    "....krrrrrk.....",
    "...krrrrrrrk....",
    "...krRrrrRrk....",
    "...krrrrrrrk....",
    "....kkrrrkk.....",
    "...krgrrgrrk....",
    "..krrgrrgrrrk...",
    "..krrrrrrrrrk...",
    "...krrrrrrrk....",
    "....krkkkrk.....",
    "....kk...kk.....",
    "................",
    "................",
    "................",
]

ROWS["devimon"] = [
    "................",
    "..kk........kk..",
    ".kvvk......kvvk.",
    ".kvvvk....kvvvk.",
    "..kvvvkkkkvvvk..",
    "....kvvvvvvk....",
    "...kvRRvvRRvk...",
    "...kvRRvvRRvk...",
    "...kvvvvvvvvk...",
    "..kkvvvvvvvvkk..",
    ".kvvkvvvvvvkvvk.",
    ".kvvkvvvvvvkvvk.",
    "..kkkkvvvvkkkk..",
    "......kvvk......",
    "......kkkk......",
    "................",
]

ROWS["meramon"] = [
    "................",
    ".......O........",
    "......ORO.......",
    "......OROo......",
    ".....kOOOOk.....",
    "...kkoOOOookk...",
    "...koOOWWWOok...",
    "...koOOWWWOok...",
    "....kOOOOOk.....",
    "...koOkOOkoOk...",
    "..kOOOkOOkooOk..",
    "..kOOOkkkkOOOk..",
    "...kkk....kkk...",
    "................",
    "................",
    "................",
]

ROWS["airdramon"] = [
    "................",
    ".......kk.......",
    "......kwwk......",
    ".....kwwwwk.....",
    "..kkkwwwwkkk....",
    ".kwkwwwwwwkwk...",
    ".kwwwwbbwwwkk...",
    "..kwwwwwwwwk....",
    "...kwwRwRwwk....",
    "....kwwwwk......",
    "....kkwwkk......",
    "......kk........",
    ".....kbbk.......",
    "....kbbbbk......",
    ".....kkkk.......",
    "................",
]

ROWS["seadramon"] = [
    "................",
    "......kkkk......",
    ".....kcccck.....",
    "....kcCcccok....",
    "....kccRcRck....",
    "....kcccccck....",
    ".....kcccck.....",
    "......kcck......",
    "......kCCk......",
    ".....kcccck.....",
    "....kcccccc k...".replace(" ", "c"),
    ".....kccccck....",
    "......kCCk......",
    ".......kck......",
    "........k.......",
    "................",
]

ROWS["numemon"] = [
    "................",
    "................",
    "...kkkkkkkkkk...",
    "..knnnnnnnnnnk..",
    "..knnnnnnnnnnk..",
    "..knRnnnnnnRnk..",
    "..knnnnnnnnnnk..",
    "..knnnkkkknnnk..",
    "..knnnnnnnnnnk..",
    ".knnnnnnnnnnnnk.",
    ".knnnnnnnnnnnnk.",
    "..knnnnnnnnnnk..",
    "...kknnnnnnkk...",
    ".....kkkkkk.....",
    "................",
    "................",
]

# ---------------------------------------------------------------- 完全体
ROWS["metalgreymon"] = [
    "................",
    "..kk.......kk...",
    "..kMk.....kMk...",
    "...kMkkkkkMk....",
    "....kmmmmmk.....",
    "...koooooook....",
    "..koRoooooRok...",
    "..koooooooook...",
    ".kkoottttttookk.",
    "kmooottttttoo o mk".replace(" ", "o")[:16],
    "kmoOooooooooOomk",
    ".kkoooooooooook.",
    "..koookkkkoook..",
    "...kkk....kkk...",
    "................",
    "................",
]

ROWS["mamemon"] = [
    "................",
    "...kkkkkkkkkk...",
    "..kvvvvvvvvvvk..",
    "..kvvvvvvvvvvk..",
    "..kvvRvvvvRvvk..",
    "..kvvvvvvvvvvk..",
    "..kvvvvvvvvvvk..",
    "..kkvvvvvvvvkk..",
    ".kkkkvvvvvvkkkk.",
    "kvvvkkvvvvkkvvvk",
    "kvvvkkvvvvkkvvvk",
    "kkkkkksssskkkkkk".replace("s", "m"),
    "....kssssssk....".replace("s", "m"),
    "...kkkkkkkkkk...",
    "................",
    "................",
]

ROWS["monzaemon"] = [
    "................",
    "....kk....kk....",
    "...kyyk..kyyk...",
    "...kyyyyyyyyk...",
    "..kyyyyyyyyyyk..",
    "..kyRyyyyyRy k..".replace(" ", "y"),
    "..kyyyyyyyyyyk..",
    "..kyyyyYyyyyyk..",
    "...kyyyyyyyyk...",
    "..kyyyyyyyyyyk..",
    ".kyyyyRyyyyyyyk.",
    ".kyyyyyyyyyyyyk.",
    "..kyyyyyyyyyyk..",
    "...kkkkkkkkkk...",
    "................",
    "................",
]


def validate():
    problems = []
    for name, rows in ROWS.items():
        if len(rows) != 16:
            problems.append(f"{name}: {len(rows)} rows (need 16)")
        for i, row in enumerate(rows):
            if len(row) != 16:
                problems.append(f"{name} row {i}: {len(row)} chars — {row!r}")
            bad = set(row) - set(C)
            if bad:
                problems.append(f"{name} row {i}: unknown symbols {bad}")
    return problems


def main():
    out = os.path.join(os.path.dirname(__file__), "..",
                       "DigimonWatch", "Resources", "Sprites")
    os.makedirs(out, exist_ok=True)

    problems = validate()
    if problems:
        print("VALIDATION FAILED")
        for p in problems:
            print("  ", p)
        raise SystemExit(1)

    for name, rows in ROWS.items():
        im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        px = im.load()
        for y, row in enumerate(rows):
            for x, ch in enumerate(row):
                px[x, y] = C[ch]
        im.save(os.path.join(out, f"{name}.png"))
    print(f"wrote {len(ROWS)} sprites to {out}")


if __name__ == "__main__":
    main()
