"""32×32 精灵的噪点清理。

build32_a.py / build32_b.py 生成后跑一次：

    python3 Art/polish32.py

只清理"真噪点"——四邻域都实心、都没有同色、且四邻域颜色一致（说明它只是浮在一个平面上的错色点）。
四邻域颜色不一致的孤立像素保留：那通常是鳍尖、高光、眼白这类 1px 细节，删掉就没特征了。
四邻域里有透明格的像素也保留：那是剪影外缘的轮廓拐角，改成身体色会把轮廓开口。
"""

from PIL import Image
import glob
import os

ROOT = os.path.join(os.path.dirname(__file__), "..",
                    "DigimonWatch", "Resources", "Sprites")


def neighbours(px, x, y, w, h):
    out = []
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        ny, nx = y + dy, x + dx
        if 0 <= ny < h and 0 <= nx < w:
            c = px[nx, ny]
            if c[3] > 0:
                out.append(c)
    return out


def clean(path):
    im = Image.open(path).convert("RGBA")
    px = im.load()
    w, h = im.size
    fixed = 0

    for y in range(h):
        for x in range(w):
            c = px[x, y]
            if c[3] == 0:
                continue
            ns = neighbours(px, x, y, w, h)
            if len(ns) != 4:
                continue                     # 贴边/外角上的像素：轮廓拐角，不是噪点
            if c in ns:
                continue                     # 有同色邻居 → 不是孤立
            distinct = set(ns)
            if len(distinct) != 1:
                continue                     # 邻域多色 → 可能是细节，保留
            px[x, y] = ns[0]
            fixed += 1

    if fixed:
        im.save(path)
    return fixed


def main():
    total = 0
    for f in sorted(glob.glob(os.path.join(ROOT, "*32*.png"))):
        n = clean(f)
        if n:
            print(f"{os.path.basename(f):22s} cleaned {n} px")
        total += n
    print(f"\ntotal {total} noisy pixels removed")


if __name__ == "__main__":
    main()
