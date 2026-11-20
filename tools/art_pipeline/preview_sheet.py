"""Monta uma prancha de revisão: corpo (+ físico) + cabelo + barba, quadros escolhidos, ampliados.

Uso: blender -b --factory-startup --python tools/art_pipeline/preview_sheet.py -- <pasta_biótipo> <saida.png> <escala> \
       <anim:quadro[:físico[:cabelo[:barba]]]> ...
Ex.:  ... -- assets/sprites/fighters/m_medium out.png 3 guard:0 jab:3:2:5:1 high_kick:6:3:0:2
"""
import json
import os
import sys

import bpy
import numpy as np

A = sys.argv[sys.argv.index("--") + 1:]
src, out, k = A[0], A[1], int(A[2])
meta = json.load(open(os.path.join(src, os.path.basename(os.path.normpath(src)) + ".json"), encoding="utf-8"))
fw, fh = meta["frame_size"]
default_build = meta.get("default_build", 1)


def load(path):
    if not os.path.exists(path):
        return None
    img = bpy.data.images.load(path)
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
    bpy.data.images.remove(img)
    return px


cells = []
for spec in A[3:]:
    parts = spec.split(":") + ["", "", ""]
    anim, frame = parts[0], int(parts[1])
    build = int(parts[2]) if parts[2] else default_build
    hair = int(parts[3]) if parts[3] else 2
    beard = int(parts[4]) if parts[4] else 0
    layers = [anim + ("" if build == default_build else "__b%d" % build)]
    if hair:
        layers.append("%s__hair%d" % (anim, hair))
    if beard:
        layers.append("%s__beard%d" % (anim, beard))
    cell = np.zeros((fh, fw, 4), dtype=np.float32)
    for name in layers:
        px = load(os.path.join(src, name + ".png"))
        if px is None:
            continue
        sl = px[:, frame * fw:(frame + 1) * fw]
        m = sl[:, :, 3:4]
        cell = sl * m + cell * (1 - m)
    cells.append(cell)
sheet = np.concatenate(cells, axis=1)
big = np.repeat(np.repeat(sheet, k, axis=0), k, axis=1)
bg = np.zeros_like(big)
bg[:, :, :3] = 0.07
bg[:, :, 3] = 1.0
m = big[:, :, 3:4]
big = big * m + bg * (1 - m)
h, w = big.shape[:2]
img = bpy.data.images.new("o", width=w, height=h, alpha=True)
img.pixels = big.ravel().tolist()
img.filepath_raw = out
img.file_format = "PNG"
img.save()
print("PREVIEW_OK", w, h)
