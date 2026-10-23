"""DigiVice 32×32 精灵 · 批次 A。

六只：digitama / botamon / betamon / greymon / tyranomon / devimon。
语言沿用 Art/build.py：1px 暗轮廓、左上 45° 光源、每种材质三级色阶、
无抗锯齿、无抖动。

画法：每行只写「填充色块」（"起点x:像素串"），轮廓由 outline() 在剪影外缘
统一补 1px 暗色，保证闭合；这样改形时不会漏描边。

跑 `python3 Art/build32_a.py`，输出到 Resources/Sprites/，并自检。
"""

from PIL import Image
import os

# 统一调色板（沿用 Art/build.py 的色系，补齐 32px 需要的暗阶）
PAL = {
    ".": (0, 0, 0, 0),
    "k": (20, 16, 14, 255),      # 轮廓

    # 蛋壳：亮/主/暗
    "W": (255, 255, 255, 255),
    "w": (234, 232, 224, 255),
    "d": (199, 193, 178, 255),
    # 蛋斑（蓝）：亮/主
    "B": (90, 176, 224, 255),
    "b": (42, 122, 176, 255),

    # 黑毛：亮/主/暗
    "F": (74, 69, 79, 255),
    "f": (43, 39, 49, 255),
    "D": (25, 22, 32, 255),

    # 眼：黄 / 红
    "Y": (255, 232, 112, 255),
    "E": (255, 90, 80, 255),

    # 绿：亮/主/暗
    "N": (90, 208, 106, 255),
    "n": (47, 154, 64, 255),
    "q": (26, 106, 42, 255),

    # 橙：亮/主/暗
    "O": (255, 160, 32, 255),
    "o": (224, 112, 0, 255),
    "u": (168, 74, 0, 255),

    # 棕：亮/主/暗
    "T": (160, 90, 48, 255),
    "t": (122, 66, 35, 255),
    "h": (96, 50, 26, 255),

    # 红：亮/主/暗
    "R": (255, 90, 80, 255),
    "r": (207, 31, 40, 255),
    "x": (143, 26, 32, 255),

    # 紫：亮/主/暗
    "V": (138, 90, 160, 255),
    "v": (90, 58, 112, 255),
    "z": (58, 35, 72, 255),

    # 牙/爪（与蛋壳同色系）
    "C": (234, 232, 224, 255),
}

EYE_CHARS = {"Y", "E"}


def parse_row(spec):
    row = ["."] * 32
    for part in spec.split():
        x_text, text = part.split(":", 1)
        x = int(x_text)
        assert 0 <= x and x + len(text) <= 32, f"越界: {part} in {spec!r}"
        for i, ch in enumerate(text):
            assert ch in PAL, f"未知色 {ch!r} in {spec!r}"
            assert row[x + i] == ".", f"重叠 @x={x + i} in {spec!r}"
            row[x + i] = ch
    return "".join(row)


ROWS = {}

# ---------------------------------------------------------------- 蛋
# 白壳 + 三处蓝斑；上左亮，下右暗
ROWS["digitama"] = [
    "",
    "",
    "",
    "14:WWWW",
    "13:WWWWWW",
    "11:WWWWWWWWWW",
    "10:WWWWWW 16:wwwwww",
    "9:WWWWWWW 16:wwwwwww",
    "9:WWWW 13:www 16:bBBb 20:www",
    "8:WWWWWWWW 16:bBBb 20:wwww",
    "8:WWWWWW 14:ww 16:bbbb 20:wwww",
    "8:WWWW 12:wwwwwwwwwwww",
    "8:WWW 11:wwwwwwwwwwwww",
    "7:WWW 10:wwwwwwwwwwwwwww",
    "7:WWW 10:wwwwwwwwwwwwww 24:d",
    "7:WW 9:bBB 12:wwwwwwwwww 22:ddd",
    "7:WW 9:bBB 12:wwwwwwwwwww 23:dd",
    "7:W 8:bBb 11:wwwwwwwwwwwww 24:d",
    "7:wwwwwwwwwwwww 20:ddddd",
    "7:wwwwwwwwwwww 19:dddddd",
    "8:wwwwwwwwwww 19:ddddd",
    "8:wwwwwww 15:bBB 18:dddddd",
    "8:wwwwww 14:bBB 17:ddddddd",
    "9:wwwww 14:bBB 17:dddddd",
    "9:wwww 13:dddddddddd",
    "10:www 13:ddddddddd",
    "11:dddddddddd",
    "12:dddddddd",
    "13:dddddd",
    "",
    "",
    "",
]

# ---------------------------------------------------------------- 黑毛球
# 两只耳状毛簇 + 圆身；黄眼；底部收暗
ROWS["botamon"] = [
    "",
    "",
    "",
    "10:FF 20:FF",
    "10:FFF 20:FFF",
    "9:FFf 19:fFF",
    "10:FFFFFF 16:ffffff",
    "9:FFFFFFF 16:fffffff",
    "8:FFFFFFF 15:fffffffff",
    "7:FFFFFFF 14:fffffffffff",
    "6:FFFFFF 12:ffffffffffff",
    "5:FFFFF 10:fffffffffffffffff",
    "4:FFFFF 9:fffffffffffffffff 26:DD",
    "4:FFFF 8:ffffffffffffffff 24:DDDD",
    "4:FFF 7:fff 10:YYY 13:ffffff 19:YYY 22:DDDDDD",
    "4:FFF 7:fff 10:YYY 13:ffffff 19:YYY 22:DDDDDD",
    "4:FF 6:ffffffffffffffff 22:DDDDDD",
    "4:FF 6:ffffffffffffff 20:DDDDDDDD",
    "4:F 5:fffffffffffffff 20:DDDDDDDD",
    "4:F 5:ffffffff 13:DDD 16:fffff 21:DDDDDDD",
    "4:F 5:ffffffffffffff 19:DDDDDDDDD",
    "4:F 5:fffffffffffff 18:DDDDDDDDDD",
    "4:ffffffffffffff 18:DDDDDDDDDD",
    "5:fffffffffff 16:DDDDDDDDDDD",
    "6:fffffffff 15:DDDDDDDDDDD",
    "7:fffffff 14:DDDDDDDDDDD",
    "9:fffff 14:DDDDDDDDD",
    "11:DDDDDDDDDD",
    "",
    "",
    "",
    "",
]

# ---------------------------------------------------------------- 电鲶
# 橙背鳍 + 绿身 + 红眼；左侧胸鳍、右侧橙尾
ROWS["betamon"] = [
    "",
    "",
    "",
    "15:OO",
    "14:OOoo",
    "13:OOOooo",
    "12:OOOOoooo",
    "11:OOOOOooooo",
    "10:OOOOOooooooo",
    "10:OOOOOooooooo",
    "10:OOOOOooooooo",
    "10:NNNNnnnnnn",
    "8:NNNNNnnnnnnnnnnn",
    "7:NNNNNNnnnnnnnnnnnn",
    "6:NNNNNNnnnnnnnnnnnnnn",
    "5:NNN 8:n 9:EEE 12:nnnnnnnn 20:EEE 23:qqqq",
    "5:NNN 8:n 9:EEE 12:nnnnnnnn 20:EEE 23:qqqq",
    "5:NNN 8:nnnnnnnn 16:qqqqqqqqqqq",
    "5:NN 7:nnnnnnnnnn 17:qqqqqqqqqq",
    "5:NN 7:nnnnnnnn 15:qqqqqqqqqqqq",
    "5:NN 7:nnnnn 12:q 13:W 14:qqqq 18:W 19:q 20:qqqqqqq",
    "5:NN 7:nnnnnn 13:qqqqqqqqqqqqqq",
    "5:nnnnnnnnnn 15:qqqqqqqqqqqq",
    "6:nnnnnnnn 14:qqqqqqqqqqqq",
    "7:nnnnnn 13:qqqqqqqqqqqq",
    "9:nnn 12:qqqqqqqqqqq",
    "11:qqqqqqqqqq",
    "13:qqqqqq",
    "",
    "",
    "",
    "",
]

# ---------------------------------------------------------------- 巨角龙
# 棕色双角 + 头盔；橙红脸与躯干；红眼、白牙
ROWS["greymon"] = [
    "",
    "",
    "4:TT 26:TT",
    "3:TTT 25:TTT",
    "3:TTTT 24:TTTT",
    "3:TTTTT 24:TTTTT",
    "3:TTTTT 10:TTTTTTTTTT 23:TTTTT",
    "3:TTTTTT 9:TTTTTTTTTTTTTT 23:TTTTTT",
    "3:TTTTttttttttttttttttttTTTT",
    "5:TTTTTTTTTTTTTTTTTTTTTT",
    "6:OOOO 10:oooooooooooo 22:uuuu",
    "6:OOOOO 11:ooooooooooo 22:uuuu",
    "6:OOO 9:EEE 12:oooooooo 20:EEE 23:ooo",
    "6:OOO 9:EEE 12:oooooooo 20:EEE 23:ooo",
    "6:O 7:oooooooooooooooo 23:uuu",
    "6:OO 8:ooooooooooooooo 23:uuu",
    "5:OO 7:oooooooooooooooooo 25:uu",
    "5:O 6:ooo 9:CC 11:ooooo 16:CC 18:ooooo 23:uuuu",
    "6:oooooooooooooooo 22:uuuu",
    "5:OOOO 9:oooooooooooooo 23:uuuu",
    "5:OOOO 9:ooooooooooooo 22:uuuuu",
    "4:OOOOO 9:oooooooooooooo 23:uuuuu",
    "4:OOOOO 9:ooooooooooooo 22:uuuuuu",
    "5:OOOO 9:oooooooooooo 21:uuuuuu",
    "5:OOOO 9:ooooooooooo 20:uuuuuuu",
    "5:OOOO 9:oooooooooo 19:uuuuuuuu",
    "5:OOOOoo 19:ooOOOO",
    "6:OOOOo 19:oOOOO",
    "5:OOOOOOooo 18:oooOOOOOO",
    "5:OOOOOOooo 18:oooOOOOOO",
    "",
    "",
]

# ---------------------------------------------------------------- 暴龙
# 红色头身 + 顶部三根骨冠；绿背纹；开嘴白牙
ROWS["tyranomon"] = [
    "",
    "",
    "",
    "11:RR 16:RR 21:RR",
    "10:RRR 15:RRR 20:RRR",
    "9:RRRRR 15:rrrrrrrrr",
    "8:RRRRR 13:rrrrrrrrrrr",
    "7:RRRRRR 13:rrrrrrrrrrrr",
    "6:RRRRRR 12:rrrrrrrrrrrrrr",
    "5:RRRRRR 11:rrrrrrrrrrrrrrrr",
    "5:RRRR 9:EEE 12:rrrrrrrr 20:EEE 23:rrrr",
    "5:RRRR 9:EEE 12:rrrrrrrr 20:EEE 23:rrrr",
    "5:RRR 8:rrrrrrrrrrrrrrrrrrr",
    "4:RRRR 8:rrrrrrrrrrrrrrrrrrrr",
    "4:RRRR 8:rrrrrrrrrrrrrrrrrr 22:xx",
    "4:RRR 7:x 8:C 9:xxxxx 14:C 15:xxxx 19:C 20:xxx 23:RRRRR",
    "4:rrrrrrrrrrrrrrrrrrrrrrrr",
    "4:RRRR 8:rrrrrrrrrrrrrrrrrrrr",
    "5:NNNN 9:rrrrrrrrrrrrrr 23:NNNN",
    "5:NNNN 9:rrrrrrrrrrrrrr 23:NNNN",
    "5:NNNN 9:rrrrrrrrrrrrrr 23:NNNN",
    "5:NNN 8:rrrrrrrrrrrrrrrr 23:NNN",
    "5:NN 7:rrrrrrrrrrrrrrrrrr 23:NN",
    "6:NN 8:rrrrrrrrrrrrrrrr 24:NN",
    "6:N 7:rrrrrrrrrrrrrrrrrr 24:N",
    "6:RRRRrrrr 18:rrrrRRRR",
    "7:RRRrrr 19:rrrRRR",
    "6:RRRRRRRR 18:RRRRRRRR",
    "6:RRRRRRRR 18:RRRRRRRR",
    "",
    "",
    "",
]

# ---------------------------------------------------------------- 蝙蝠人
# 双翼展开；紫黑身体；双角 + 红眼
ROWS["devimon"] = [
    "",
    "10:VV 19:VV",
    "9:VVv 19:vVV",
    "9:VVvv 18:vvVV",
    "9:VVvv 18:vvVV",
    "10:VVVV 16:vvvv",
    "9:VVVVV 16:vvvvvvv",
    "9:VVVVV 16:vvvvvvv",
    "4:VV 9:VVVVV 16:vvvvvvv 26:VV",
    "3:VVVV 9:VVVVV 16:vvvvvvv 25:VVVV",
    "2:VVVVV 9:VVVVV 16:vvvvvvv 25:VVVVV",
    "1:VVVVVVV 9:VVVVV 16:vvvvvvv 24:VVVVVVV",
    "1:VVVVVVVV 9:VVV 12:EEE 15:vvvvv 18:EEE 21:vvv 23:VVVVVVVV",
    "1:VVVVVVVV 9:VVV 12:EEE 15:vvvvv 18:EEE 21:vvv 23:VVVVVVVV",
    "1:zzzzzzzzz 11:VVV 14:vvvvvvv 22:zzzzzzzzz",
    "1:zzzzzzzzz 11:VVV 14:vvvvvvv 22:zzzzzzzzz",
    "2:zzzzzzzz 10:VVVVVVVVVVVV 22:zzzzzzzz",
    "3:zzzzzzz 10:VVVVVVVVVVVV 23:zzzzzzz",
    "4:zzzzzz 10:VVVVVVVVVVVV 24:zzzzzz",
    "5:zzzz 10:VVVVVVVVVVVV 24:zzzz",
    "6:zz 10:VVVVVVVVVVVV 25:zz",
    "11:VVVV 17:VVVV",
    "11:VVVV 17:VVVV",
    "11:VVVV 17:VVVV",
    "11:VVVV 17:VVVV",
    "10:VVVVV 17:VVVVV",
    "10:VVVVV 17:VVVVV",
    "10:CCCCC 17:CCCCC",
    "",
    "",
    "",
]


def outline(matrix):
    """在剪影外缘补 1px 暗轮廓。"""
    out = [list(row) for row in matrix]
    for y in range(32):
        for x in range(32):
            if matrix[y][x] != ".":
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < 32 and 0 <= ny < 32 and matrix[ny][nx] != ".":
                    out[y][x] = "k"
                    break
    return ["".join(row) for row in out]


def blink_rows(rows):
    """眨眼帧：眼睛像素换成该角色用得最多的身体色。"""
    counts = {}
    for row in rows:
        for ch in row:
            if ch not in "." and ch not in EYE_CHARS:
                counts[ch] = counts.get(ch, 0) + 1
    if not counts:
        return list(rows)
    body = max(counts, key=counts.get)
    return ["".join(body if ch in EYE_CHARS else ch for ch in row) for row in rows]


def to_image(rows):
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    px = im.load()
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            px[x, y] = PAL[ch]
    return im


def check(name, rows, im, verbose=True):
    assert len(rows) == 32, name
    assert all(len(r) == 32 for r in rows), name
    assert im.size == (32, 32), name
    assert im.mode == "RGBA", name

    px = im.load()
    for x, y in [(0, 0), (31, 0), (0, 31), (31, 31)]:
        assert px[x, y][3] == 0, f"{name}: 角落不透明 @{x},{y}"

    opaque = [(x, y) for y in range(32) for x in range(32) if px[x, y][3]]
    assert len(opaque) > 60, f"{name}: 不透明像素仅 {len(opaque)}"

    colors = {px[x, y] for x, y in opaque}
    assert len(colors) <= 24, f"{name}: 颜色 {len(colors)} > 24"

    # 轮廓闭合：身体像素不得与透明像素四邻相接
    leaks = []
    for x, y in opaque:
        if px[x, y] == PAL["k"]:
            continue
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if not (0 <= nx < 32 and 0 <= ny < 32):
                leaks.append((x, y, "edge"))
            elif px[nx, ny][3] == 0:
                leaks.append((x, y, (nx, ny)))
    assert not leaks, f"{name}: 轮廓漏 {leaks[:8]}"

    # 剪影单连通
    seen = {opaque[0]}
    stack = [opaque[0]]
    opaque_set = set(opaque)
    while stack:
        x, y = stack.pop()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            p = (x + dx, y + dy)
            if p in opaque_set and p not in seen:
                seen.add(p)
                stack.append(p)
    assert seen == opaque_set, f"{name}: 剪影不连通"

    bbox = im.getbbox()
    if verbose:
        print(f"{name:<12} bbox={bbox}  opaque={len(opaque):>3}  colors={len(colors)}")
    return bbox


def main():
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "..", "DigimonWatch", "Resources", "Sprites")
    os.makedirs(out, exist_ok=True)

    for name in ["digitama", "botamon", "betamon",
                 "greymon", "tyranomon", "devimon"]:
        rows = outline([parse_row(s) for s in ROWS[name]])
        im = to_image(rows)
        check(name + "32", rows, im)
        im.save(os.path.join(out, name + "32.png"))

        brow = blink_rows(rows)
        bim = to_image(brow)
        check(name + "32_b", brow, bim)
        bim.save(os.path.join(out, name + "32_b.png"))

    print("wrote 12 sprites to", os.path.abspath(out))


if __name__ == "__main__":
    main()
