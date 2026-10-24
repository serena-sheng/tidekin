"""潮线（Whale Line）32×32 精灵 —— B 批：后六形态。

复用 Art/build32_b.py 的标签图 / 材质三阶打光 / 1px 暗轮廓管线，
只为 ABYSS / KUN / BREACHER / DRIFT / SIREN 追加需要的材质：
    deep   #1C3A66 深潜海军蓝（ABYSS / KRAKEN）
    abyss  #14283F 最深处（KUN）
    steel  #1E6BB8 跃潮的更深主色（BREACHER）
    ash    #7A8A99 褪色灰（DRIFT）
    mist   浅雾灰（DRIFT 白腹与雾絮）
    dusk   深灰纹（DRIFT 乱流纹）
    glow   #6BE0FF 额纹高亮 / 全身光标纹（ABYSS / KUN / KRAKEN）

贯穿全弧线的三要素在每只身上都保留：
    白腹（cream 材质，中间调 #EAE8E0；DRIFT 按设定褪成灰 mist）
    额头光标纹「▍」
    蓝白配色 + 左 45° 光源（管线自带）

运行：
    python3 Art/build_whale_b.py
    python3 Art/polish32.py
    python3 Art/build_whale_b.py --verify
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import build32_b as B
from build32_b import (Canvas, EYE_MATS, FLAT, H, OUTLINE, W,
                       bbox, body_dominant, check, check_blink, render)

# 新增材质的三个色阶直接写进共享 BODY，render() 才认得它们
EXTRA_BODY = {
    "steel": ((84, 158, 220), (30, 107, 184), (16, 62, 108)),    # #1E6BB8
    "deep":  ((54, 100, 150), (28, 58, 102), (12, 24, 44)),      # #1C3A66
    "abyss": ((58, 90, 120), (20, 40, 63), (8, 16, 28)),         # #14283F
    "ash":   ((176, 188, 198), (122, 138, 153), (78, 94, 108)),  # #7A8A99
    "mist":  ((226, 230, 234), (188, 194, 201), (146, 154, 163)),
    "dusk":  ((104, 116, 128), (70, 84, 98), (46, 58, 70)),
    "glow":  ((176, 244, 255), (107, 224, 255), (56, 152, 196)), # #6BE0FF
}
B.BODY.update(EXTRA_BODY)


# --------------------------------------------------------------- 画法工具

def stroke(cv, p0, p1, mat):
    """4-连通直线：每步只走一个轴，1px 线不会漏出对角缝。"""
    x0, y0 = p0
    x1, y1 = p1
    while True:
        cv.px(x0, y0, mat)
        if (x0, y0) == (x1, y1):
            return
        dx, dy = x1 - x0, y1 - y0
        if abs(dx) >= abs(dy):
            x0 += 1 if dx > 0 else -1
        else:
            y0 += 1 if dy > 0 else -1


def polyline(cv, pts, mat):
    for a, b in zip(pts, pts[1:]):
        stroke(cv, a, b, mat)


def arc(cv, cx, cy, r, a0, a1, mat, steps=None):
    """圆弧用折线连接，保证像素 4-连通。"""
    steps = steps or max(8, int(abs(a1 - a0) / 8))
    pts = []
    for i in range(steps + 1):
        a = math.radians(a0 + (a1 - a0) * i / steps)
        pts.append((int(round(cx + r * math.cos(a))),
                    int(round(cy + r * math.sin(a)))))
    polyline(cv, pts, mat)


def mark(cv, x, y0, n, mat="cyan:mark"):
    """额纹「▍」：2px 宽的实心竖条，随成长变长。"""
    cv.rect(x, y0, x + 1, y0 + n - 1, mat)


def eye(cv, x, y, lid=False):
    """2×2 眼白 + 1px 瞳；lid=True 时下睑压成半闭（涣散）。"""
    cv.rect(x, y, x + 1, y + 1, "eye")
    if lid:
        cv.rect(x, y + 1, x + 1, y + 1, "eyeink")
    else:
        cv.px(x, y + 1, "eyeink")


# --------------------------------------------------------------- 造型

def breacher():
    """跃潮：肌肉化的跃浪鲸，背鳍与胸鳍刃化，额纹转白，尾鳍后掠。"""
    cv = Canvas()
    # 尾鳍两叶，向上后掠
    cv.poly([(23, 17), (30, 10), (30, 15), (26, 19)], "steel:flukeU")
    cv.poly([(24, 20), (30, 19), (29, 24), (25, 22)], "steel:flukeL")
    cv.capsule((21, 19), (26, 18), 1, "steel:tail")
    # 躯干：胸背加厚
    cv.ellipse(15, 18, 7, 6, "steel:body")
    cv.ellipse(16, 16, 5, 4, "steel:chest")
    cv.ellipse(8, 15, 6, 6, "steel:head")
    # 背鳍变刃
    cv.poly([(15, 13), (17, 4), (21, 13)], "steel:dorsal")
    # 胸鳍变刃（尖端留 2px 宽，避免被清噪点啃掉）
    cv.poly([(13, 22), (7, 29), (16, 26)], "steel:pect")
    cv.px(8, 29, "steel:pect2")
    # 白腹
    cv.ellipse(13, 21, 5, 2, "cream:belly")
    # 肌肉线
    polyline(cv, [(13, 14), (16, 16)], "steel:m1")
    polyline(cv, [(18, 14), (21, 16)], "steel:m2")
    # 额纹转白，成年加长
    mark(cv, 9, 10, 4, "cream:mark")
    eye(cv, 4, 14)
    # 嘴线
    polyline(cv, [(2, 17), (6, 18)], "ink")
    return cv


def abyss():
    """潜渊：全身深海军蓝，鳍长，额纹最亮，向右上潜行。"""
    cv = Canvas()
    # 尾向上扬
    cv.capsule((19, 18), (25, 13), 2, "deep:tail")
    cv.poly([(25, 13), (30, 5), (30, 12), (27, 15)], "deep:flukeU")
    cv.poly([(26, 16), (30, 14), (29, 19), (25, 18)], "deep:flukeL")
    # 补掉鳍与尾之间的 1px 内缝
    cv.px(29, 14, "deep:seam1")
    cv.px(25, 17, "deep:seam2")
    # 躯干下俯
    cv.capsule((9, 18), (18, 19), 5, "deep:body")
    cv.ellipse(7, 18, 5, 4, "deep:head")
    # 背鳍
    cv.poly([(12, 12), (15, 7), (18, 13)], "deep:dorsal")
    # 深潜者的长胸鳍
    cv.poly([(11, 22), (5, 28), (14, 25)], "deep:pect")
    cv.px(6, 28, "deep:pect2")
    # 白腹
    cv.ellipse(14, 21, 7, 2, "cream:belly")
    # 额纹最亮，比成年再长一档
    mark(cv, 8, 13, 5, "glow:mark")
    eye(cv, 4, 17)
    polyline(cv, [(2, 20), (5, 21)], "ink")
    return cv


def drift():
    """漂雾：灰鲸，软塌下垂、乱流纹、半闭的涣散眼。"""
    cv = Canvas()
    # 塌陷的躯干 + 下垂的腹缘
    cv.ellipse(14, 18, 9, 6, "ash:body")
    cv.poly([(6, 20), (9, 27), (14, 29), (20, 27), (24, 22)], "ash:sag")
    cv.ellipse(6, 14, 5, 4, "ash:head")
    # 低垂的尾
    cv.capsule((22, 21), (26, 23), 1, "ash:tail")
    cv.poly([(26, 23), (30, 22), (30, 27), (27, 28)], "ash:fluke")
    # 灰鲸的小背峰
    cv.ellipse(18, 12, 2, 1, "ash:hump")
    # 白腹褪成灰雾
    cv.ellipse(13, 24, 6, 2, "mist:belly")
    # 乱流纹：4-连通折线，深浅两色
    polyline(cv, [(9, 14), (10, 15), (11, 14)], "dusk:s1")
    polyline(cv, [(16, 12), (17, 13), (18, 12)], "dusk:s2")
    polyline(cv, [(12, 17), (13, 18), (14, 17)], "dusk:s3")
    polyline(cv, [(18, 24), (19, 25), (20, 24)], "dusk:s4")
    polyline(cv, [(10, 19), (11, 20), (12, 19)], "mist:r1")
    polyline(cv, [(21, 15), (22, 16)], "mist:r2")
    # 漂在背上的雾絮
    cv.ellipse(20, 7, 4, 2, "mist:wisp")
    cv.rect(24, 9, 25, 9, "mist:wisp2")
    # 额纹褪成暗灰，仍在原位
    mark(cv, 7, 11, 3, "dusk:mark")
    # 涣散眼：瞳朝下、嘴角下坠
    eye(cv, 4, 14)
    polyline(cv, [(3, 17), (7, 18)], "ink")
    return cv


def kun():
    """鲲：体量最大，巨尾鳍展开如鹏翼，全身光标纹发光。"""
    cv = Canvas()
    # 鹏翼状巨尾鳍（上叶大、下叶长）
    cv.poly([(24, 16), (30, 2), (30, 12), (26, 18)], "abyss:wingU")
    cv.poly([(24, 20), (30, 19), (30, 29), (27, 22)], "abyss:wingL")
    stroke(cv, (25, 17), (29, 4), "glow:rib1")
    stroke(cv, (25, 18), (30, 10), "glow:rib2")
    stroke(cv, (26, 20), (30, 27), "glow:rib3")
    # 巨大身躯与头
    cv.ellipse(14, 18, 11, 9, "abyss:body")
    cv.ellipse(6, 15, 4, 5, "abyss:head")
    # 背鳍
    cv.poly([(12, 10), (15, 5), (18, 11)], "abyss:dorsal")
    # 巨胸鳍
    cv.poly([(9, 25), (3, 29), (14, 28)], "abyss:pect")
    # 白腹
    cv.ellipse(12, 24, 6, 2, "cream:belly")
    # 全身光标纹
    cv.rect(8, 14, 12, 14, "glow:line1")
    cv.rect(17, 13, 20, 13, "glow:line4")
    cv.rect(15, 20, 20, 20, "glow:line2")
    cv.rect(10, 21, 14, 21, "glow:line3")
    # 额纹最长
    mark(cv, 7, 11, 6, "glow:mark")
    eye(cv, 4, 15)
    polyline(cv, [(3, 18), (7, 19)], "ink")
    return cv


def kraken():
    """沧主：深海霸主，白角、四条触腕、压眉的锐眼。"""
    cv = Canvas()
    # 四条触腕
    cv.capsule((10, 17), (7, 23), 1, "deep:t1")
    cv.capsule((7, 23), (4, 26), 1, "deep:t1b")
    cv.capsule((4, 26), (3, 28), 0, "deep:t1c")
    cv.capsule((14, 19), (14, 25), 1, "deep:t2")
    cv.capsule((14, 25), (16, 28), 1, "deep:t2b")
    cv.capsule((20, 19), (22, 24), 1, "deep:t3")
    cv.capsule((22, 24), (20, 27), 1, "deep:t3b")
    cv.capsule((25, 17), (27, 22), 1, "deep:t4")
    cv.capsule((27, 22), (29, 24), 1, "deep:t4b")
    # 躯干与头
    cv.ellipse(17, 13, 10, 6, "deep:body")
    cv.ellipse(9, 13, 6, 5, "deep:head")
    # 白角（粗根细尖，向两侧斜出）
    cv.poly([(7, 9), (10, 9), (3, 4)], "cream:hornL")
    cv.px(4, 4, "cream:hornLb")
    cv.poly([(12, 9), (15, 9), (17, 4)], "cream:hornR")
    cv.px(16, 5, "cream:hornRb")
    # 背鳍
    cv.poly([(22, 8), (25, 3), (27, 9)], "deep:dorsal")
    cv.px(26, 9, "deep:seam1")
    # 白腹
    cv.ellipse(14, 16, 5, 2, "cream:belly")
    # 额纹高亮
    mark(cv, 10, 11, 4, "glow:mark")
    # 锐眼 + 压眉
    eye(cv, 4, 12)
    polyline(cv, [(3, 10), (6, 11)], "ink")
    polyline(cv, [(2, 15), (7, 16)], "ink")
    # 触腕吸盘
    cv.rect(6, 24, 6, 25, "cream:sucker1")
    cv.rect(21, 26, 21, 27, "cream:sucker2")
    return cv


def siren():
    """歌潮：优雅的鲸，头顶两道声波、喉部声纹、鳍尖泛青。"""
    cv = Canvas()
    # 尾优雅上扬
    cv.capsule((21, 14), (26, 10), 1, "blue:tail")
    cv.poly([(26, 10), (30, 4), (30, 9), (28, 13)], "blue:flukeU")
    cv.poly([(27, 13), (30, 12), (28, 17), (24, 15)], "blue:flukeL")
    cv.px(29, 12, "blue:seam1")
    # 流线躯干
    cv.capsule((12, 15), (21, 14), 5, "blue:body")
    cv.ellipse(8, 14, 5, 5, "blue:head")
    # 背鳍
    cv.poly([(14, 9), (16, 5), (18, 9)], "blue:dorsal")
    # 长胸鳍（尖端两像素宽）
    cv.poly([(13, 20), (8, 25), (16, 22)], "blue:pect")
    cv.px(7, 25, "blue:pect2")
    # 白腹（后段留白，不加纹路）
    cv.ellipse(16, 18, 8, 1, "cream:belly")
    # 环身声波：一道长弧贴着背线，前端一小粒起音
    polyline(cv, [(3, 12), (5, 9), (8, 7), (12, 6), (16, 6), (20, 7), (23, 9), (25, 11)],
             "cyan:wave1")
    polyline(cv, [(2, 9), (3, 8)], "cyan:wave2")
    # 鳍尖泛青
    cv.px(30, 5, "cyan:tip1")
    cv.px(8, 25, "cyan:tip2")
    # 额纹
    mark(cv, 7, 10, 4, "cyan:mark")
    eye(cv, 4, 15)
    polyline(cv, [(2, 18), (6, 19)], "ink")
    return cv


SPRITES = {
    "breacher": breacher,
    "abyss": abyss,
    "drift": drift,
    "kun": kun,
    "kraken": kraken,
    "siren": siren,
}


# --------------------------------------------------------------- 自检

def isolated(im):
    """噪点（与 polish32.py 同一判据）：四邻域无同色、且邻域只有一种颜色。

    1px 暗轮廓本身就是斜向像素串，不计入；四邻域多色的 1px 细节也不算噪点。
    返回 (噪点数, 参与统计的不透明数, 占比)。
    """
    px = im.load()
    iso = 0
    op = 0
    for y in range(H):
        for x in range(W):
            c = px[x, y]
            if c[3] == 0 or c == OUTLINE:
                continue
            op += 1
            ns = []
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < W and 0 <= ny < H and px[nx, ny][3] > 0:
                    ns.append(px[nx, ny])
            if not ns or c in ns:
                continue
            if len(set(ns)) == 1:
                iso += 1
    return iso, op, iso / op


def out_dir():
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), "..",
                        "DigimonWatch", "Resources", "Sprites")


def build():
    d = out_dir()
    os.makedirs(d, exist_ok=True)
    for name, fn in SPRITES.items():
        cv = fn()
        used = {}
        im = render(cv, levels=used)
        dom = body_dominant(im)
        blink = render(cv, eye_color=dom)
        n, c = check(name, im)
        check(name + "_b", blink)
        blinked = check_blink(name, im, blink, dom)
        levels = {fam: len(v) for fam, v in used.items()}
        for fam, lv in levels.items():
            assert 2 <= lv <= 3, f"{name}: material {fam} has {lv} levels (need 2-3)"
        iso, op, ratio = isolated(im)
        assert ratio <= 0.05, f"{name}: isolated {iso}/{op} = {ratio:.1%} > 5%"
        im.save(os.path.join(d, f"{name}32.png"))
        blink.save(os.path.join(d, f"{name}32_b.png"))
        print(f"{name:9s} opaque={n:3d} colors={c:2d} bbox={bbox(im)} "
              f"blink={blinked}px iso={iso}/{op}={ratio:.1%} "
              f"lo={dom[:3]} levels={levels}")


def verify():
    """polish32.py 之后重新验一遍落盘文件。"""
    from PIL import Image
    d = out_dir()
    for name in SPRITES:
        im = Image.open(os.path.join(d, f"{name}32.png")).convert("RGBA")
        bl = Image.open(os.path.join(d, f"{name}32_b.png")).convert("RGBA")
        n, c = check(name, im)
        check(name + "_b", bl)
        dom = body_dominant(im)
        blinked = check_blink(name, im, bl, dom)
        iso, op, ratio = isolated(im)
        assert ratio <= 0.05, f"{name}: isolated {iso}/{op} = {ratio:.1%} > 5%"
        print(f"{name:9s} opaque={n:3d} colors={c:2d} bbox={bbox(im)} "
              f"blink={blinked}px iso={iso}/{op}={ratio:.1%}")


if __name__ == "__main__":
    if "--verify" in sys.argv:
        verify()
    else:
        build()
