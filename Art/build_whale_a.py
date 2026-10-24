"""潮线（Whale Line）32×32 精灵 · 批次 A（前 6 形态）。

tideseed / spume / calf / cetal / mael / current

复用 Art/build32_b.py 的渲染机制：材质三阶打光、整只共用一套光源（左 45°）、
1px 闭合暗轮廓、眨眼帧只换眼睛材质像素。这里只补三件事：

  · 新增鲸系材质：foam（浮沫 #7FD0E8）、dusk（涡仔 #3A5B8C）、fog（灰涡纹）
  · glow 固定色：潮种蛋内的光标光点，在眨眼帧里作为「眼」脉动
  · mask_* 工具：白腹、额纹这类细节只落在剪影内部，不会挂到身体外面

运行：python3 Art/build_whale_a.py
输出：DigimonWatch/Resources/Sprites/<id>32.png 与 <id>32_b.png
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import build32_b as base  # noqa: E402

W = H = base.W

# 鲸系材质三阶：(高光, 中间调, 暗部)。中间调即规格表的主色。
WHALE_BODY = {
    "blue":  ((90, 176, 224), (42, 122, 176), (24, 72, 112)),   # #2A7AB0
    "cyan":  ((120, 235, 235), (60, 200, 200), (28, 120, 132)),  # #3CC8C8 光标纹
    "cream": ((255, 255, 255), (234, 232, 224), (176, 176, 168)),  # #EAE8E0 白腹
    "foam":  ((196, 240, 252), (127, 208, 232), (74, 150, 180)),  # #7FD0E8 浮沫
    "dusk":  ((96, 130, 178), (58, 91, 140), (30, 52, 88)),      # #3A5B8C 失养
    "fog":   ((198, 204, 212), (150, 158, 170), (104, 114, 130)),  # 灰涡纹
}

# 不参与打光的固定色
WHALE_FLAT = {"glow": (60, 200, 200, 255)}

base.BODY.update(WHALE_BODY)
base.FLAT.update(WHALE_FLAT)
# glow 是蛋里的「未睁之眼」：眨眼帧里跟着脉动，其余像素不动
base.EYE_MATS = set(base.EYE_MATS) | {"glow"}


# --------------------------------------------------------------- 绘制工具

def mask_paint(cv, pts, mat):
    """只画在已有剪影上——细节永远不会跑到身体外面去。"""
    for x, y in pts:
        if 0 <= x < W and 0 <= y < H and cv.im.getpixel((x, y)) != 0:
            cv.px(x, y, mat)


def mask_ellipse(cv, cx, cy, rx, ry, mat):
    pts = []
    for y in range(cy - ry, cy + ry + 1):
        for x in range(cx - rx, cx + rx + 1):
            if ((x - cx) / max(rx, 1)) ** 2 + ((y - cy) / max(ry, 1)) ** 2 <= 1.0:
                pts.append((x, y))
    mask_paint(cv, pts, mat)


def orth(pts):
    """把折线拆成四邻域相接的像素串：按比例错步，斜线才是平滑的阶梯而不是 L 形。"""
    out = [pts[0]]
    x, y = pts[0]
    for nx, ny in pts[1:]:
        dx, dy = nx - x, ny - y
        n = max(abs(dx), abs(dy))
        for i in range(1, n + 1):
            tx, ty = x + round(dx * i / n), y + round(dy * i / n)
            while out[-1][0] != tx:
                cx, cy = out[-1]
                out.append((cx + (1 if tx > cx else -1), cy))
            while out[-1][1] != ty:
                cx, cy = out[-1]
                out.append((cx, cy + (1 if ty > cy else -1)))
        x, y = nx, ny
    return out


def paint(cv, pts, mat):
    """画在剪影上（用于尾巴这类新长出来的部分）。"""
    for x, y in pts:
        if 0 <= x < W and 0 <= y < H:
            cv.px(x, y, mat)


def band(cv, pts, mat, masked=False):
    """2px 粗的折线：orth 路径 + 下方一行，四邻域必连。"""
    path = orth(pts)
    pts2 = path + [(x, y + 1) for x, y in path]
    (mask_paint if masked else paint)(cv, pts2, mat)


def tidy(cv):
    """修整标签图，让轮廓阶段不产生脏点。

    多个椭圆拼接时，接缝处会留下被身体四面包围的透明洞——轮廓会把它填成
    一个暗色点（polish32 眼里的噪点）。这里先把洞补成邻居的材质，再剪掉
    只有 1px 的凸起，保证轮廓始终贴着连续的身体。
    """
    lab = cv.im.load()

    changed = True
    while changed:                          # 补内部空洞
        changed = False
        for y in range(H):
            for x in range(W):
                if lab[x, y]:
                    continue
                nb = [lab[x + dx, y + dy] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
                      if 0 <= x + dx < W and 0 <= y + dy < H]
                if len(nb) == 4 and all(nb):
                    lab[x, y] = max(set(nb), key=nb.count)
                    changed = True

    changed = True
    while changed:                          # 剪 1px 凸起
        changed = False
        for y in range(H):
            for x in range(W):
                if not lab[x, y]:
                    continue
                nb = [lab[x + dx, y + dy] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
                      if 0 <= x + dx < W and 0 <= y + dy < H]
                if len(nb) == 4 and nb.count(0) >= 3:
                    lab[x, y] = 0
                    changed = True


# --------------------------------------------------------------- 造型

def tideseed():
    """潮种：蓝白潮纹蛋，壳内隐一点青蓝光标光点（还没睁眼）。"""
    cv = base.Canvas()
    cv.ellipse(16, 23, 8, 4, "blue:shell")     # 下盘 x8..24 y19..27
    cv.ellipse(16, 17, 8, 6, "blue:shell")     # 中段 x8..24 y11..23
    cv.ellipse(16, 10, 6, 4, "blue:shell")     # 上收 x10..22 y6..14

    # 白潮纹：两道平行的缠绕带，从蛋身左下绕到右上
    band(cv, [(8, 22), (12, 20), (16, 16), (20, 12), (23, 10)],
         "cream:tide", masked=True)
    band(cv, [(8, 26), (12, 25), (16, 22), (20, 19), (23, 17)],
         "cream:tide", masked=True)

    # 壳内光标光点：夹在两道潮纹中间，蛋还没睁眼，它只是亮着
    mask_paint(cv, [(16, 18), (16, 19)], "glow")
    return cv


def spume():
    """沫沫：浮沫团，无尾，软的；顶部一小撮亮光。全员最小。"""
    cv = base.Canvas()
    cv.ellipse(16, 19, 7, 5, "foam:body")      # 主体 x9..23 y14..24
    cv.ellipse(16, 12, 4, 3, "foam:body")      # 中央圆顶 x12..20 y9..15
    cv.ellipse(10, 20, 2, 2, "foam:body")      # 左侧泡
    cv.ellipse(22, 20, 2, 2, "foam:body")      # 右侧泡

    # 顶部一小撮亮光：从圆顶冒出来的一缕白沫
    paint(cv, [(16, 8), (16, 9), (17, 9)], "cream:crest")
    mask_paint(cv, [(10, 21), (11, 21), (10, 22), (11, 22)], "cream:crest")

    # 一双没睡醒的小眼
    cv.rect(11, 15, 12, 16, "eye")
    cv.rect(19, 15, 20, 16, "eye")
    cv.px(12, 16, "eyeink")
    cv.px(19, 16, "eyeink")
    return cv


def calf():
    """鲸苗：首次长出鲸尾，白腹确立，体量仍小。"""
    cv = base.Canvas()
    cv.ellipse(17, 19, 8, 4, "blue:body")      # 躯干 x9..25 y15..23
    cv.ellipse(10, 17, 5, 5, "blue:head")      # 头 x5..15 y12..22
    cv.ellipse(6, 18, 3, 2, "blue:snout")      # 吻 x3..9 y16..20

    band(cv, [(24, 18), (26, 17), (27, 16)], "blue:tail")
    cv.poly([(26, 17), (30, 13), (29, 18), (27, 18)], "blue:fin")

    mask_ellipse(cv, 16, 21, 6, 2, "cream:belly")
    mask_ellipse(cv, 7, 20, 3, 1, "cream:jaw")

    cv.rect(7, 15, 8, 16, "eye")
    cv.px(7, 16, "eyeink")
    return cv


def cetal():
    """汐仔：被照顾的幼鲸，胸鳍成形，额纹短光标「▍」初现。"""
    cv = base.Canvas()
    cv.ellipse(17, 18, 8, 4, "blue:body")      # 躯干 x9..25 y14..22
    cv.ellipse(10, 16, 6, 5, "blue:head")      # 头 x4..16 y11..21

    cv.poly([(14, 20), (18, 20), (16, 25), (12, 23)], "blue:flipper")
    band(cv, [(25, 16), (27, 15), (28, 13)], "blue:tail")
    cv.poly([(27, 15), (30, 10), (30, 15), (28, 16)], "blue:fin")

    mask_ellipse(cv, 16, 20, 7, 2, "cream:belly")
    mask_ellipse(cv, 7, 19, 3, 1, "cream:jaw")

    # 额纹：短的竖光标，尾鳍上留一点同色冷光把色阶撑开
    mask_paint(cv, [(9, 12), (9, 13), (9, 14)], "cyan:mark")
    mask_paint(cv, [(28, 13), (29, 13)], "cyan:mark")

    cv.rect(7, 15, 8, 16, "eye")
    cv.px(7, 16, "eyeink")
    return cv


def mael():
    """涡仔：失养的幼鲸，主色暗一档，纹路拧成漩涡，眼神疏离。"""
    cv = base.Canvas()
    cv.ellipse(17, 19, 8, 4, "dusk:body")      # 躯干（整体下沉 1px）
    cv.ellipse(10, 17, 6, 5, "dusk:head")

    cv.poly([(14, 21), (12, 26), (16, 25)], "dusk:flipper")   # 鳍塌下来
    band(cv, [(24, 19), (27, 20), (28, 22)], "dusk:tail")     # 尾也垂着
    cv.poly([(27, 21), (30, 23), (29, 27), (26, 25)], "dusk:fin")

    # 侧腹的漩涡：一圈半的方涡，1px 线留 1px 缝；白腹压低，别把涡盖住
    mask_paint(cv, orth([(22, 19), (22, 16), (17, 16), (17, 20), (21, 20),
                     (21, 18), (19, 18)]), "fog:swirl")

    mask_ellipse(cv, 16, 22, 5, 1, "cream:belly")
    mask_ellipse(cv, 7, 19, 3, 1, "cream:jaw")

    # 额纹变灰，只有两格
    mask_paint(cv, [(9, 13), (9, 14)], "fog:mark")

    # 疏离：半睁的眼，只剩一条横缝
    cv.rect(7, 16, 8, 16, "eye")
    cv.px(7, 16, "eyeink")
    return cv


def current():
    """游潮：标准鲸，背鳍流线，白腹完整、额纹加长。"""
    cv = base.Canvas()
    cv.ellipse(17, 18, 9, 4, "blue:body")      # 躯干 x8..26 y14..22
    cv.ellipse(10, 16, 6, 6, "blue:head")      # 头 x4..16 y10..22

    cv.poly([(19, 15), (21, 9), (24, 15)], "blue:dorsal")     # 流线背鳍
    cv.poly([(13, 21), (18, 21), (16, 26), (12, 24)], "blue:flipper")   # 胸鳍
    band(cv, [(26, 17), (27, 16), (28, 14)], "blue:tail")
    cv.poly([(28, 15), (30, 10), (30, 15), (28, 16)], "blue:fin")

    mask_ellipse(cv, 16, 21, 7, 2, "cream:belly")
    mask_ellipse(cv, 7, 20, 3, 1, "cream:jaw")

    # 额纹加长到 4 格，尾鳍边缘一点冷光
    mask_paint(cv, [(9, 11), (9, 12), (9, 13), (9, 14)], "cyan:mark")
    mask_paint(cv, [(29, 13), (29, 14)], "cyan:mark")

    cv.rect(7, 15, 8, 16, "eye")
    cv.px(7, 16, "eyeink")
    return cv


SPRITES = {
    "tideseed": tideseed,
    "spume": spume,
    "calf": calf,
    "cetal": cetal,
    "mael": mael,
    "current": current,
}


# --------------------------------------------------------------- 自检

def isolated(im):
    """孤立像素：非轮廓、且四邻域里没有同色（真噪点）。"""
    px = im.load()
    iso = total = 0
    for y in range(H):
        for x in range(W):
            p = px[x, y]
            if p[3] == 0 or p == base.OUTLINE:
                continue
            total += 1
            nb = [px[x + dx, y + dy] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
                  if 0 <= x + dx < W and 0 <= y + dy < H]
            if p not in nb:
                iso += 1
    return iso, total


def main():
    out_dir = os.path.join(os.path.dirname(__file__), "..",
                           "DigimonWatch", "Resources", "Sprites")
    os.makedirs(out_dir, exist_ok=True)

    for name, fn in SPRITES.items():
        cv = fn()
        tidy(cv)
        used = {}
        im = base.render(cv, levels=used)
        dom = base.body_dominant(im)
        blink = base.render(cv, eye_color=dom)
        n, c = base.check(name, im)
        base.check(name + "_b", blink)
        blinked = base.check_blink(name, im, blink, dom)
        levels = {fam: len(v) for fam, v in used.items()}
        for fam, lv in levels.items():
            assert 2 <= lv <= 3, f"{name}: material {fam} has {lv} levels (need 2-3)"
        iso, total = isolated(im)
        ratio = iso / total
        assert ratio <= 0.05, f"{name}: {iso}/{total} isolated pixels ({ratio:.1%})"
        im.save(os.path.join(out_dir, f"{name}32.png"))
        blink.save(os.path.join(out_dir, f"{name}32_b.png"))
        print(f"{name:9s} opaque={n:3d} colors={c:2d} bbox={base.bbox(im)} "
              f"blink={blinked}px iso={iso}/{total} ({ratio:4.1%}) "
              f"dom={dom} levels={levels}")


if __name__ == "__main__":
    main()
