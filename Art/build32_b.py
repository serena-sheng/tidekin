"""DigiVice 32×32 精灵源文件（第二批）。

与原 16×16 的 Art/build.py 共享同一套配色语言：
1px 暗轮廓、左上 45° 光源、每种材质 3 级色阶、无抗锯齿、无抖动。

画法：用 Pillow 在 32×32 标签图上摆基本形，再按材质包围盒做对角
三段打光，最后向外膨胀 1px 生成闭合轮廓。

运行：python3 Art/build32_b.py
输出：DigimonWatch/Resources/Sprites/<name>32.png 与 <name>32_b.png
"""

from PIL import Image, ImageDraw
import os

W = H = 32
OUTLINE = (20, 16, 14, 255)

# 材质三阶：(高光, 中间调, 暗部)，取自 Art/build.py 的配色系
BODY = {
    "fire":   ((255, 176, 64), (224, 112, 0), (178, 44, 28)),
    "cream":  ((255, 255, 255), (234, 232, 224), (176, 176, 168)),
    "blue":   ((90, 176, 224), (42, 122, 176), (24, 72, 112)),
    "cyan":   ((120, 235, 235), (60, 200, 200), (28, 120, 132)),
    "green":  ((90, 208, 106), (47, 154, 64), (26, 106, 42)),
    "purple": ((96, 66, 124), (52, 34, 72), (24, 14, 36)),
    "metal":  ((222, 222, 220), (182, 183, 182), (106, 107, 112)),
    "yellow": ((255, 232, 112), (237, 198, 25), (150, 118, 8)),
}

# 不参与打光的固定色
FLAT = {
    "eye":    (255, 255, 255, 255),
    "eyered": (255, 90, 80, 255),
    "ink":    (0, 0, 0, 255),
    "eyeink": (0, 0, 0, 255),
    "mouth":  (88, 16, 18, 255),
    "heart":  (207, 31, 40, 255),
    "claw":   (234, 232, 224, 255),
}

EYE_MATS = {"eye", "eyered", "eyeink"}


class Canvas:
    """标签图：每个像素记录材质名，最后统一上色。"""

    def __init__(self):
        self.im = Image.new("L", (W, H), 0)
        self.d = ImageDraw.Draw(self.im)
        self.names = [None]
        self.lookup = {}

    def _idx(self, name):
        if name not in self.lookup:
            self.lookup[name] = len(self.names)
            self.names.append(name)
        return self.lookup[name]

    def ellipse(self, cx, cy, rx, ry, mat):
        self.d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=self._idx(mat))

    def rect(self, x0, y0, x1, y1, mat):
        self.d.rectangle([x0, y0, x1, y1], fill=self._idx(mat))

    def poly(self, pts, mat):
        self.d.polygon(pts, fill=self._idx(mat))

    def capsule(self, p0, p1, r, mat):
        i = self._idx(mat)
        self.d.line([p0, p1], fill=i, width=2 * r + 1)
        for p in (p0, p1):
            self.d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=i)

    def px(self, x, y, mat):
        self.im.putpixel((x, y), self._idx(mat))


# --------------------------------------------------------------- 造型

def meramon():
    """橙红火焰人：头顶三束火舌，火袖张开，双腿是两簇火苗。"""
    cv = Canvas()
    cv.poly([(10, 9), (7, 2), (13, 6)], "fire:spike1")
    cv.poly([(14, 8), (16, 2), (18, 7)], "fire:spike0")
    cv.poly([(19, 6), (23, 2), (21, 10)], "fire:spike2")
    cv.ellipse(16, 12, 7, 6, "fire:head")
    cv.poly([(13, 17), (19, 17), (20, 26), (12, 26)], "fire:torso")
    cv.poly([(12, 19), (8, 20), (5, 16), (3, 10), (7, 15)], "fire:armL")
    cv.poly([(20, 19), (24, 20), (27, 16), (29, 10), (25, 15)], "fire:armR")
    cv.poly([(12, 25), (15, 25), (15, 30), (10, 30)], "fire:legL")
    cv.poly([(17, 25), (20, 25), (22, 30), (17, 30)], "fire:legR")
    cv.rect(11, 10, 12, 11, "eye")
    cv.rect(19, 10, 20, 11, "eye")
    for p in [(14, 15), (15, 16), (16, 16), (17, 16), (18, 15)]:
        cv.px(*p, "mouth")
    return cv


def airdramon():
    """白蓝翼龙：左向龙首、蓝色巨翼、长尾带尾鳍。"""
    cv = Canvas()
    cv.poly([(16, 18), (25, 3), (29, 6), (30, 14), (30, 17), (23, 21)], "blue:wing")
    cv.capsule((16, 18), (25, 3), 0, "cream:leading")
    cv.capsule((16, 18), (29, 15), 0, "cream:rib")
    cv.capsule((16, 18), (28, 8), 0, "cream:rib2")
    cv.capsule((21, 21), (25, 24), 2, "cream:tail1")
    cv.capsule((25, 24), (28, 29), 1, "cream:tail2")
    cv.poly([(29, 30), (30, 26), (27, 29)], "cream:fin")
    cv.rect(17, 23, 20, 27, "cream:leg")
    cv.rect(16, 27, 20, 27, "claw")
    cv.ellipse(17, 20, 6, 4, "cream:body")
    cv.poly([(15, 16), (18, 13), (21, 17)], "blue:ridge")
    cv.capsule((12, 16), (16, 18), 2, "cream:neck")
    cv.ellipse(9, 12, 4, 4, "cream:head")
    cv.poly([(9, 8), (2, 10), (2, 13), (9, 13)], "cream:snout")
    cv.poly([(8, 14), (3, 14), (2, 16), (9, 16)], "cream:jaw")
    cv.rect(4, 14, 8, 14, "mouth")
    cv.poly([(10, 9), (16, 4), (13, 11)], "blue:horn1")
    cv.poly([(13, 10), (16, 8), (17, 12)], "blue:fin1")
    cv.poly([(15, 14), (19, 12), (20, 18)], "blue:fin2")
    cv.rect(6, 9, 7, 10, "eyered")
    cv.rect(3, 13, 8, 13, "mouth")
    return cv


def seadramon():
    """青蓝海蛇：竖向 S 形身躯、橙色背鳍、白色角。"""
    cv = Canvas()
    cv.capsule((14, 13), (10, 18), 3, "cyan:c1")
    cv.capsule((10, 18), (15, 22), 3, "cyan:c2")
    cv.capsule((15, 22), (11, 27), 2, "cyan:c3")
    cv.capsule((11, 27), (15, 29), 1, "cyan:tail")
    cv.ellipse(13, 8, 5, 4, "cyan:head")
    cv.poly([(13, 5), (4, 6), (4, 10), (13, 11)], "cyan:snout")
    cv.poly([(13, 5), (14, 2), (16, 6)], "cream:horn")
    cv.poly([(16, 11), (23, 8), (18, 16)], "fire:fin1")
    cv.poly([(16, 19), (24, 18), (18, 23)], "fire:fin2")
    cv.poly([(11, 25), (7, 28), (12, 29)], "fire:fin3")
    cv.poly([(17, 27), (23, 25), (21, 30)], "fire:tailfin")
    cv.ellipse(9, 18, 1, 2, "cream:belly1")
    cv.ellipse(12, 22, 1, 2, "cream:belly2")
    cv.rect(8, 7, 9, 8, "eyered")
    cv.rect(5, 9, 10, 9, "mouth")
    cv.px(5, 7, "ink")
    return cv


def numemon():
    """绿色黏液怪：软塌塌的团子、滴落边缘、红眼。"""
    cv = Canvas()
    cv.ellipse(16, 18, 11, 10, "green:body")
    cv.ellipse(16, 10, 6, 4, "green:head")
    cv.rect(7, 25, 10, 30, "green:drip1")
    cv.rect(15, 26, 18, 30, "green:drip2")
    cv.rect(21, 24, 24, 29, "green:drip3")
    cv.rect(10, 14, 13, 16, "eyered")
    cv.rect(19, 14, 22, 16, "eyered")
    cv.rect(12, 20, 19, 21, "mouth")
    cv.px(11, 19, "mouth")
    cv.px(20, 19, "mouth")
    return cv


def metalgreymon():
    """橙龙 + 银甲：头盔双角、胸甲、右臂炮管、银爪。"""
    cv = Canvas()
    cv.poly([(10, 6), (5, 2), (11, 4)], "metal:hornL")
    cv.poly([(20, 6), (25, 2), (19, 4)], "metal:hornR")
    cv.ellipse(15, 8, 6, 2, "metal:helm")
    cv.ellipse(15, 11, 5, 3, "fire:head")
    cv.poly([(10, 13), (20, 13), (18, 16), (12, 16)], "fire:jaw")
    cv.ellipse(15, 21, 6, 6, "fire:body")
    cv.poly([(11, 17), (18, 17), (18, 20), (11, 20)], "metal:chest")
    cv.rect(12, 21, 18, 22, "metal:belt")
    cv.rect(14, 21, 15, 22, "metal:buckle")
    cv.rect(21, 18, 27, 22, "metal:cannon")
    cv.rect(28, 19, 30, 20, "metal:barrel")
    cv.rect(30, 19, 30, 20, "ink")
    cv.ellipse(8, 18, 3, 2, "metal:pad")
    cv.rect(4, 19, 8, 24, "fire:arm")
    cv.rect(3, 24, 4, 25, "claw")
    cv.rect(6, 24, 7, 25, "claw")
    cv.rect(10, 26, 13, 29, "fire:legL")
    cv.rect(17, 26, 20, 29, "fire:legR")
    cv.rect(9, 29, 13, 30, "claw")
    cv.rect(17, 29, 21, 30, "claw")
    cv.capsule((21, 27), (25, 29), 1, "fire:tail")
    cv.rect(11, 11, 12, 12, "eyered")
    cv.rect(17, 11, 18, 12, "eyered")
    cv.px(13, 14, "ink")
    cv.px(17, 14, "ink")
    return cv


def mamemon():
    """黑紫圆头小人：大圆头、金属腰带、金属靴。"""
    cv = Canvas()
    cv.ellipse(16, 13, 11, 10, "purple:head")
    cv.poly([(8, 5), (6, 2), (11, 4)], "purple:earL")
    cv.poly([(24, 5), (26, 2), (21, 4)], "purple:earR")
    cv.rect(2, 14, 6, 20, "purple:armL")
    cv.rect(26, 14, 30, 20, "purple:armR")
    cv.ellipse(4, 20, 2, 2, "purple:handL")
    cv.ellipse(28, 20, 2, 2, "purple:handR")
    cv.rect(9, 22, 13, 27, "purple:legL")
    cv.rect(19, 22, 23, 27, "purple:legR")
    cv.rect(8, 27, 13, 27, "metal:bootL")
    cv.rect(19, 27, 24, 27, "metal:bootR")
    cv.rect(7, 19, 24, 20, "metal:belt")
    cv.rect(14, 19, 17, 20, "metal:buckle")
    cv.rect(10, 10, 13, 12, "eye")
    cv.rect(19, 10, 22, 12, "eye")
    cv.rect(14, 16, 18, 16, "ink")
    return cv


def monzaemon():
    """黄色玩具熊：圆耳、奶白口鼻、胸口红心。"""
    cv = Canvas()
    cv.ellipse(9, 5, 3, 3, "yellow:earL")
    cv.ellipse(23, 5, 3, 3, "yellow:earR")
    cv.ellipse(9, 5, 1, 1, "cream:earinL")
    cv.ellipse(23, 5, 1, 1, "cream:earinR")
    cv.ellipse(16, 10, 7, 6, "yellow:head")
    cv.ellipse(16, 22, 8, 7, "yellow:body")
    cv.rect(5, 18, 8, 24, "yellow:armL")
    cv.rect(24, 18, 27, 24, "yellow:armR")
    cv.rect(10, 26, 14, 30, "yellow:legL")
    cv.rect(18, 26, 22, 30, "yellow:legR")
    cv.ellipse(16, 23, 4, 3, "cream:belly")
    # 心形：两瓣顶 + 收尖
    for x in (13, 14, 16, 17):
        cv.px(x, 18, "heart")
    cv.rect(12, 19, 18, 20, "heart")
    cv.rect(13, 21, 17, 21, "heart")
    cv.rect(14, 22, 16, 22, "heart")
    cv.px(15, 23, "heart")
    cv.ellipse(16, 14, 4, 2, "cream:muzzle")
    cv.rect(15, 12, 17, 13, "ink")
    cv.px(16, 14, "ink")
    cv.rect(11, 8, 12, 9, "eyeink")
    cv.rect(19, 8, 20, 9, "eyeink")
    return cv


SPRITES = {
    "meramon": meramon,
    "airdramon": airdramon,
    "seadramon": seadramon,
    "numemon": numemon,
    "metalgreymon": metalgreymon,
    "mamemon": mamemon,
    "monzaemon": monzaemon,
}


# --------------------------------------------------------------- 渲染

def render(cv, eye_color=None, levels=None):
    lab = cv.im.load()
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    o = out.load()

    for idx in range(1, len(cv.names)):
        name = cv.names[idx]
        key = name.split(":")[0]
        if key in EYE_MATS and eye_color is not None:
            col = eye_color
            for y in range(H):
                for x in range(W):
                    if lab[x, y] == idx:
                        o[x, y] = col
            continue
        if key not in BODY:
            col = FLAT[key]
            for y in range(H):
                for x in range(W):
                    if lab[x, y] == idx:
                        o[x, y] = col
            continue
        # 该材质的所有像素，用自身包围盒做左上打光
        pts = [(x, y) for y in range(H) for x in range(W) if lab[x, y] == idx]
        if not pts:
            continue
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        cx, cy = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
        rx = max((max(xs) - min(xs)) / 2, 0.5)
        ry = max((max(ys) - min(ys)) / 2, 0.5)
        hi, base, lo = BODY[key]
        for (x, y) in pts:
            s = 0.6 * (x - cx) / rx + 0.85 * (y - cy) / ry
            col = hi if s < -0.5 else (lo if s > 0.55 else base)
            o[x, y] = col
            if levels is not None:
                levels.setdefault(key, set()).add(col[:3])

    # 1px 轮廓：向透明邻域膨胀，保证闭合
    opaque = [[o[x, y][3] > 0 for x in range(W)] for y in range(H)]
    ring = []
    for y in range(H):
        for x in range(W):
            if opaque[y][x]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < W and 0 <= ny < H and opaque[ny][nx]:
                    ring.append((x, y))
                    break
    for x, y in ring:
        o[x, y] = OUTLINE
    return out


def body_dominant(im):
    from collections import Counter
    c = Counter()
    eyes = tuple(FLAT[k] for k in EYE_MATS)
    for y in range(H):
        for x in range(W):
            p = im.getpixel((x, y))
            if p[3] == 0 or p == OUTLINE or p in eyes:
                continue
            c[p] += 1
    return c.most_common(1)[0][0]


def bbox(im):
    xs, ys = [], []
    for y in range(H):
        for x in range(W):
            if im.getpixel((x, y))[3] > 0:
                xs.append(x)
                ys.append(y)
    return (min(xs), min(ys), max(xs), max(ys))


def check(name, im):
    px = im.load()
    assert im.size == (32, 32), f"{name}: size {im.size}"
    assert im.mode == "RGBA", f"{name}: mode {im.mode}"
    for x, y in ((0, 0), (31, 0), (0, 31), (31, 31)):
        assert px[x, y][3] == 0, f"{name}: corner {x},{y} not transparent"
    opaque = [(x, y) for y in range(H) for x in range(W) if px[x, y][3] > 0]
    assert len(opaque) > 60, f"{name}: only {len(opaque)} opaque pixels"
    cols = {px[x, y] for x, y in opaque}
    assert len(cols) <= 24, f"{name}: {len(cols)} colors > 24"
    # 轮廓闭合：任何非轮廓的不透明像素，四邻域都必须不透明
    for x, y in opaque:
        if px[x, y] == OUTLINE:
            continue
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            assert 0 <= nx < W and 0 <= ny < H, f"{name}: body at border {x},{y}"
            assert px[nx, ny][3] > 0, f"{name}: outline gap at {nx},{ny}"
    # 轮廓必须都在边界（贴着身体）
    for x, y in opaque:
        if px[x, y] != OUTLINE:
            continue
        nb = [(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
        nb = [(a, b) for a, b in nb if 0 <= a < W and 0 <= b < H]
        assert any(px[a, b] != OUTLINE and px[a, b][3] > 0 for a, b in nb), \
            f"{name}: floating outline at {x},{y}"
    return len(opaque), len(cols)


def check_blink(name, open_im, blink_im, dom):
    eyes = tuple(FLAT[k] for k in EYE_MATS)
    differ = []
    for y in range(H):
        for x in range(W):
            a = open_im.getpixel((x, y))
            b = blink_im.getpixel((x, y))
            if a != b:
                differ.append((x, y))
                assert a in eyes, \
                    f"{name}_b: non-eye pixel changed at {x},{y}: {a}"
                assert b == dom, f"{name}_b: eye at {x},{y} -> {b}, want {dom}"
    assert differ, f"{name}_b: no eye pixels blinked"
    return len(differ)


def main():
    out_dir = os.path.join(os.path.dirname(__file__), "..",
                           "DigimonWatch", "Resources", "Sprites")
    os.makedirs(out_dir, exist_ok=True)

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
            assert lv == 3, f"{name}: material {fam} has {lv} levels (need 3)"
        im.save(os.path.join(out_dir, f"{name}32.png"))
        blink.save(os.path.join(out_dir, f"{name}32_b.png"))
        bx = bbox(im)
        print(f"{name:14s} opaque={n:4d} colors={c:2d} bbox={bx} "
              f"blink={blinked}px -> {dom} levels={levels}")


if __name__ == "__main__":
    main()
