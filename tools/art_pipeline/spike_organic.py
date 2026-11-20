"""Spike E-10: corpo orgânico (Skin modifier + subdivisão) em 3/4, no estilo da referência do usuário,
com as variantes do criador de personagem (físico, cabelo, barba, pele, cores).

Uso: blender -b --factory-startup --python tools/art_pipeline/spike_organic.py -- <raiz>
Gera art_source/spike/variants_x2.png (folha de 12 variantes na pose de guarda, ampliada 2x) e
organic_guard_x4.png (variante 1 ampliada 4x). Serve para aprovar o visual antes de reescrever o pipeline.
"""
import math
import os
import sys

import bpy
import numpy as np

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
ROOT = ARGS[0] if ARGS else os.getcwd()
OUT = os.path.join(ROOT, "art_source", "spike")
W, H = 160, 160
PX_PER_M = 136 / 1.80


def lin(c):
    return tuple(((v + 0.055) / 1.055) ** 2.4 if v > 0.04045 else v / 12.92 for v in c)


def ramp(dark, light):
    """5 tons de tela (sRGB) do escuro ao claro, levemente mais quentes no meio."""
    return [tuple(dark[i] + (light[i] - dark[i]) * t for i in range(3)) for t in (0.0, 0.28, 0.52, 0.76, 1.0)]


SKINS = [ramp((0.38, 0.24, 0.18), (0.98, 0.84, 0.72)), ramp((0.30, 0.17, 0.12), (0.91, 0.71, 0.55)),
         ramp((0.22, 0.12, 0.08), (0.78, 0.55, 0.38)), ramp((0.12, 0.07, 0.05), (0.56, 0.38, 0.27))]
HAIRS = {"preto": ramp((0.04, 0.03, 0.03), (0.30, 0.24, 0.22)), "castanho": ramp((0.10, 0.06, 0.04), (0.50, 0.34, 0.22)),
         "loiro": ramp((0.36, 0.25, 0.10), (0.98, 0.88, 0.58)), "ruivo": ramp((0.28, 0.07, 0.03), (0.92, 0.50, 0.26)),
         "grisalho": ramp((0.28, 0.28, 0.30), (0.92, 0.92, 0.94))}
SHORTS = {"preto": ramp((0.05, 0.05, 0.06), (0.36, 0.36, 0.39)), "azul": ramp((0.04, 0.06, 0.24), (0.36, 0.52, 0.98)),
          "vermelho": ramp((0.26, 0.03, 0.04), (0.98, 0.38, 0.32)), "verde": ramp((0.03, 0.18, 0.07), (0.40, 0.84, 0.44)),
          "branco": ramp((0.50, 0.50, 0.50), (1.0, 1.0, 0.98)), "dourado": ramp((0.32, 0.20, 0.02), (1.0, 0.90, 0.44)),
          "roxo": ramp((0.18, 0.04, 0.26), (0.80, 0.46, 0.98))}
FIXED = {
    "glove": ramp((0.04, 0.04, 0.05), (0.33, 0.33, 0.36)),
    "accent": ramp((0.36, 0.04, 0.05), (0.96, 0.40, 0.36)),
    "white": ramp((0.55, 0.55, 0.55), (0.99, 0.99, 0.99)),
    "eye": [(0.05, 0.04, 0.04)] * 5,
}
OUTLINE = (0.12, 0.07, 0.06)

# Físico visual (dentro do biótipo da categoria): escala de tronco, membros, músculos e barriga.
BUILDS = {
    "magro": {"torso": 0.86, "limb": 0.84, "muscle": 0.75, "belly": 0.0},
    "atletico": {"torso": 1.0, "limb": 1.0, "muscle": 1.0, "belly": 0.0},
    "musculoso": {"torso": 1.1, "limb": 1.14, "muscle": 1.32, "belly": 0.0},
    "pesado": {"torso": 1.2, "limb": 1.12, "muscle": 0.95, "belly": 1.0},
}
HAIR_STYLES = ["careca", "raspado", "curto", "moicano", "coque", "black_power", "rabo", "dreads", "topete"]
BEARDS = ["nenhuma", "rente", "cheia", "cavanhaque", "bigode"]

VARIANTS = [
    {"build": "atletico", "skin": 1, "hair": "curto", "hc": "castanho", "beard": "rente", "shorts": "preto"},
    {"build": "magro", "skin": 0, "hair": "raspado", "hc": "preto", "beard": "nenhuma", "shorts": "azul"},
    {"build": "musculoso", "skin": 3, "hair": "moicano", "hc": "preto", "beard": "cavanhaque", "shorts": "vermelho"},
    {"build": "pesado", "skin": 2, "hair": "careca", "hc": "preto", "beard": "cheia", "shorts": "preto"},
    {"build": "atletico", "skin": 2, "hair": "black_power", "hc": "preto", "beard": "nenhuma", "shorts": "verde"},
    {"build": "atletico", "skin": 0, "hair": "rabo", "hc": "loiro", "beard": "nenhuma", "shorts": "branco"},
    {"build": "musculoso", "skin": 3, "hair": "dreads", "hc": "preto", "beard": "bigode", "shorts": "dourado"},
    {"build": "magro", "skin": 1, "hair": "coque", "hc": "ruivo", "beard": "nenhuma", "shorts": "roxo"},
    {"build": "atletico", "skin": 0, "hair": "topete", "hc": "loiro", "beard": "rente", "shorts": "azul"},
    {"build": "pesado", "skin": 3, "hair": "curto", "hc": "grisalho", "beard": "cheia", "shorts": "vermelho"},
    {"build": "musculoso", "skin": 1, "hair": "careca", "hc": "castanho", "beard": "bigode", "shorts": "preto"},
    {"build": "atletico", "skin": 2, "hair": "coque", "hc": "preto", "beard": "cavanhaque", "shorts": "roxo"},
]


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    s = bpy.context.scene
    s.render.engine = "BLENDER_EEVEE"
    s.render.resolution_x, s.render.resolution_y = W, H
    s.render.film_transparent = True
    s.render.filter_size = 0.0
    s.view_settings.view_transform = "Standard"
    if hasattr(s.eevee, "taa_render_samples"):
        s.eevee.taa_render_samples = 1
    return s


def toon(name, rmp):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    n, l = m.node_tree.nodes, m.node_tree.links
    n.clear()
    out, emit, dif, rgb, cr = (n.new(t) for t in ("ShaderNodeOutputMaterial", "ShaderNodeEmission", "ShaderNodeBsdfDiffuse",
                                                  "ShaderNodeShaderToRGB", "ShaderNodeValToRGB"))
    cr.color_ramp.interpolation = "CONSTANT"
    els = cr.color_ramp.elements
    while len(els) < 5:
        els.new(0.5)
    for el, pos, col in zip(els, [0.0, 0.08, 0.22, 0.48, 0.80], rmp):
        el.position = pos
        el.color = lin(col) + (1.0,)
    l.new(dif.outputs["BSDF"], rgb.inputs["Shader"])
    l.new(rgb.outputs["Color"], cr.inputs["Fac"])
    l.new(cr.outputs["Color"], emit.inputs["Color"])
    l.new(emit.outputs["Emission"], out.inputs["Surface"])
    return m


def skin_body(name, verts, edges, radii, mat, subdiv=2):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, edges, [])
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    mod = obj.modifiers.new("skin", "SKIN")
    mod.use_smooth_shade = True
    for i, r in enumerate(radii):
        obj.data.skin_vertices[0].data[i].radius = r if isinstance(r, tuple) else (r, r)
    obj.data.skin_vertices[0].data[0].use_root = True
    sub = obj.modifiers.new("sub", "SUBSURF")
    sub.levels = sub.render_levels = subdiv
    return obj


def ball(name, loc, r, mat, scale=(1, 1, 1), rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=r, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = scale
    o.rotation_euler = tuple(math.radians(a) for a in rot)
    o.data.materials.append(mat)
    bpy.ops.object.shade_smooth()
    return o


def sc(r, k):
    return tuple(v * k for v in r) if isinstance(r, tuple) else r * k


def build_body(m, b):
    """Esqueleto na guarda (ortodoxo; esquerda à frente, lado longe = +y). Pernas um pouco mais curtas que o real
    (estilização da referência: tronco e braços dominam a leitura)."""
    V = {
        "hips": (0.0, 0.0, 0.93), "waist": (0.03, 0.0, 1.10), "chest": (0.06, 0.0, 1.29), "neck0": (0.07, 0.0, 1.45), "neck1": (0.09, 0.0, 1.53),
        "shL": (0.07, 0.17, 1.41), "elL": (0.18, 0.21, 1.20), "wrL": (0.30, 0.14, 1.40),
        "shR": (0.03, -0.17, 1.41), "elR": (0.11, -0.21, 1.17), "wrR": (0.21, -0.10, 1.43),
        "hpL": (0.02, 0.10, 0.90), "knL": (0.19, 0.12, 0.50), "anL": (0.23, 0.13, 0.08), "toL": (0.36, 0.13, 0.025),
        "hpR": (-0.03, -0.10, 0.90), "knR": (-0.10, -0.12, 0.49), "anR": (-0.24, -0.14, 0.10), "toR": (-0.12, -0.17, 0.025),
    }
    t, lb, mu = b["torso"], b["limb"], b["muscle"]
    R = {
        "hips": sc((0.13, 0.16), t), "waist": sc((0.12, 0.14), t * (1.0 + 0.12 * b["belly"])), "chest": sc((0.15, 0.18), t * mu ** 0.25),
        "neck0": 0.065 * t, "neck1": 0.058 * t,
        "shL": 0.075 * lb, "elL": 0.045 * lb, "wrL": 0.034 * lb, "shR": 0.075 * lb, "elR": 0.045 * lb, "wrR": 0.034 * lb,
        "hpL": 0.12 * lb, "knL": 0.064 * lb, "anL": 0.042, "toL": (0.03, 0.045),
        "hpR": 0.12 * lb, "knR": 0.064 * lb, "anR": 0.042, "toR": (0.03, 0.045),
    }
    names = list(V)
    idx = {k: i for i, k in enumerate(names)}
    E = [("hips", "waist"), ("waist", "chest"), ("chest", "neck0"), ("neck0", "neck1"), ("chest", "shL"), ("shL", "elL"), ("elL", "wrL"),
         ("chest", "shR"), ("shR", "elR"), ("elR", "wrR"), ("hips", "hpL"), ("hpL", "knL"), ("knL", "anL"), ("anL", "toL"),
         ("hips", "hpR"), ("hpR", "knR"), ("knR", "anR"), ("anR", "toR")]
    skin_body("body", [V[k] for k in names], [(idx[a], idx[bb]) for a, bb in E], [R[k] for k in names], m["skin"])
    mu = b["muscle"]
    ball("delt_R", (0.04, -0.19, 1.39), 0.072 * mu ** 0.5 * lb, m["skin"])
    ball("delt_L", (0.08, 0.19, 1.39), 0.07 * mu ** 0.5 * lb, m["skin"])
    ball("bicep_R", (0.09, -0.21, 1.26), 0.05 * mu * lb, m["skin"], (1.0, 1.0, 1.5), (0, -20, 0))
    ball("fore_R", (0.17, -0.16, 1.28), 0.042 * lb, m["skin"], (1.0, 1.0, 1.7), (0, 40, 0))
    ball("calf_L", (0.18, 0.13, 0.31), 0.058 * mu ** 0.5 * lb, m["skin"], (1.0, 1.0, 1.9), (0, 5, 0))
    ball("calf_R", (-0.20, -0.13, 0.31), 0.058 * mu ** 0.5 * lb, m["skin"], (1.0, 1.0, 1.9), (0, -25, 0))
    if b["belly"] > 0:
        ball("belly", (0.10, -0.01, 1.11), 0.13 * t, m["skin"], (0.85, 1.1, 1.0))
    # Calção: casca do cós às coxas; o cós branco fica ENCAIXADO na borda de cima (sem vão).
    # O vértice "top" fica acima do cós: a tampa arredondada do Skin modifier some por baixo do corpo.
    sv = {"top": (0.035, 0.0, 1.13), "w": (0.03, 0.0, 1.05), "h": (0.0, 0.0, 0.93),
          "hL": (0.02, 0.10, 0.90), "tL": (0.1475, 0.115, 0.60), "hR": (-0.03, -0.10, 0.90), "tR": (-0.081, -0.115, 0.60)}  # pernas seguem o eixo da coxa
    sn = list(sv)
    si = {k: i for i, k in enumerate(sn)}
    skin_body("shorts", [sv[k] for k in sn], [(si["top"], si["w"]), (si["w"], si["h"]), (si["h"], si["hL"]), (si["hL"], si["tL"]), (si["h"], si["hR"]), (si["hR"], si["tR"])],
              [sc((0.10, 0.12), t), sc((0.142, 0.172), t * (1.0 + 0.1 * b["belly"])), sc((0.152, 0.182), t), 0.136 * lb, 0.106 * lb, 0.136 * lb, 0.106 * lb], m["shorts"])
    ball("waistband", (0.03, 0.0, 1.06), 0.15 * t * (1.0 + 0.1 * b["belly"]), m["white"], (0.96, 1.16, 0.17))
    ball("short_stripe", (-0.05, -0.18 * t, 0.78), 0.03, m["accent"], (0.7, 0.4, 3.0), (0, -12, 0))
    for side, wr in (("L", V["wrL"]), ("R", V["wrR"])):
        ball("glove_" + side, (wr[0] + 0.03, wr[1], wr[2] + 0.05), 0.05, m["glove"], (1.1, 0.95, 1.15))
        ball("cuff_" + side, (wr[0] + 0.005, wr[1], wr[2] + 0.005), 0.042 * lb, m["glove"], (1.0, 1.0, 0.8))
        ball("trim_" + side, (wr[0], wr[1], wr[2] - 0.012), 0.04 * lb, m["accent"], (1.0, 1.0, 0.25))
        ball("fingers_" + side, (wr[0] + 0.065, wr[1], wr[2] + 0.045), 0.025, m["skin"], (0.7, 1.0, 1.2))


def build_head(m, hair, beard):
    ball("skull", (0.09, 0.0, 1.66), 0.105, m["skin"], (0.95, 0.85, 1.05))
    ball("jaw", (0.135, 0.0, 1.585), 0.068, m["skin"], (0.95, 0.85, 0.8))
    ball("nose", (0.195, -0.005, 1.635), 0.018, m["skin"], (1.2, 0.8, 1.3))
    ball("ear", (0.07, -0.088, 1.645), 0.024, m["skin"], (0.6, 0.6, 1.0))
    ball("eye", (0.172, -0.045, 1.66), 0.011, m["eye"])
    ball("brow", (0.178, -0.04, 1.68), 0.014, m["hair"], (0.9, 1.6, 0.45))
    h = m["hair"]
    cap = lambda: ball("hair_cap", (0.075, 0.0, 1.71), 0.104, h, (1.0, 0.92, 0.62))
    if hair == "raspado":
        ball("hair_buzz", (0.082, 0.0, 1.69), 0.107, h, (0.97, 0.89, 0.66))
    elif hair == "curto":
        cap()
    elif hair == "moicano":
        ball("hair_mohawk", (0.07, 0.0, 1.755), 0.095, h, (1.12, 0.28, 0.62))
    elif hair == "coque":
        cap()
        ball("hair_bun", (-0.035, 0.0, 1.765), 0.045, h)
    elif hair == "black_power":
        ball("hair_afro", (0.065, 0.0, 1.715), 0.14, h, (1.0, 1.04, 0.9))
    elif hair == "rabo":
        cap()
        ball("hair_tail", (-0.055, 0.0, 1.60), 0.036, h, (1.0, 1.0, 2.6), (0, -22, 0))
    elif hair == "dreads":
        cap()
        for k, (x, y) in enumerate(((-0.03, 0.0), (-0.01, -0.07), (-0.01, 0.07), (0.03, -0.09), (0.03, 0.09), (-0.05, -0.04), (-0.05, 0.04))):
            ball("hair_lock%d" % k, (x, y, 1.59), 0.021, h, (1.0, 1.0, 3.2), (0, -10, 0))
    elif hair == "topete":
        cap()
        ball("hair_quiff", (0.14, 0.0, 1.755), 0.05, h, (1.3, 1.4, 0.8), (0, -20, 0))
    if beard == "rente":
        ball("beard_stubble", (0.135, 0.0, 1.575), 0.07, h, (0.97, 0.87, 0.72))
    elif beard == "cheia":
        ball("beard_full", (0.13, 0.0, 1.56), 0.08, h, (1.0, 0.9, 0.85))
    elif beard == "cavanhaque":
        ball("beard_goatee", (0.178, 0.0, 1.553), 0.03, h, (1.0, 1.2, 1.3))
    elif beard == "bigode":
        ball("beard_mustache", (0.192, 0.0, 1.613), 0.02, h, (0.8, 2.2, 0.6))


def camera_lights():
    cd = bpy.data.cameras.new("cam")
    cd.type = "ORTHO"
    cd.ortho_scale = W / PX_PER_M
    cam = bpy.data.objects.new("cam", cd)
    bpy.context.collection.objects.link(cam)
    cam.location = (0.0, -6.0, 0.95)
    cam.rotation_euler = (math.radians(90), 0, 0)
    bpy.context.scene.camera = cam
    for name, e, rot in (("key", 3.4, (50, 0, 30)), ("rim", 1.4, (60, 0, -110))):  # chave de cima-frente, contorno atrás
        d = bpy.data.lights.new(name, "SUN")
        d.energy = e
        d.use_shadow = False  # sombras projetadas viram serrilhado no peito; o toon já dá o volume
        o = bpy.data.objects.new(name, d)
        bpy.context.collection.objects.link(o)
        o.rotation_euler = tuple(math.radians(a) for a in rot)


def despeckle(rgb, a, passes=2):
    """Pixel isolado (nenhum vizinho de 4 com a mesma cor) vira a cor mais comum entre os vizinhos."""
    for _ in range(passes):
        h, w = a.shape
        out = rgb.copy()
        for y in range(1, h - 1):
            for x in range(1, w - 1):
                if not a[y, x]:
                    continue
                c = rgb[y, x]
                nbs = [rgb[y - 1, x], rgb[y + 1, x], rgb[y, x - 1], rgb[y, x + 1]]
                ok = [a[y - 1, x], a[y + 1, x], a[y, x - 1], a[y, x + 1]]
                if sum(1 for n, o in zip(nbs, ok) if o and np.allclose(n, c)) == 0:
                    cands = [tuple(n) for n, o in zip(nbs, ok) if o]
                    if cands:
                        out[y, x] = max(set(cands), key=cands.count)
        rgb = out
    return rgb


def post(px, palette):
    colors = np.array([c for rmp in palette.values() for c in rmp], dtype=np.float32)
    a = px[:, :, 3] > 0.5
    rgb = px[:, :, :3].copy()
    flat = rgb[a]
    d = ((flat[:, None, :] - colors[None, :, :]) ** 2).sum(axis=2)
    rgb[a] = colors[d.argmin(axis=1)]
    rgb = despeckle(rgb, a)
    out = np.zeros_like(px)
    out[:, :, :3] = rgb
    out[:, :, 3] = a
    nb = np.zeros_like(a)
    nb[1:, :] |= a[:-1, :]
    nb[:-1, :] |= a[1:, :]
    nb[:, 1:] |= a[:, :-1]
    nb[:, :-1] |= a[:, 1:]
    edge = nb & ~a
    out[edge, :3] = OUTLINE
    out[edge, 3] = 1.0
    return out


def save(px, path):
    h, w = px.shape[:2]
    img = bpy.data.images.new("o", width=w, height=h, alpha=True)
    img.pixels = px.ravel().tolist()
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()
    bpy.data.images.remove(img)


def render_variant(v):
    s = reset()
    palette = dict(FIXED)
    palette.update({"skin": SKINS[v["skin"]], "hair": HAIRS[v["hc"]], "shorts": SHORTS[v["shorts"]]})
    m = {k: toon(k, rmp) for k, rmp in palette.items()}
    build_body(m, BUILDS[v["build"]])
    build_head(m, v["hair"], v["beard"])
    bpy.ops.object.empty_add(location=(0, 0, 0))
    root = bpy.context.active_object
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.parent = root
    root.rotation_euler = (0, 0, math.radians(-30))  # 3/4: peito virado para a câmera, como na referência
    camera_lights()
    tmp = os.path.join(OUT, "_raw.png")
    s.render.filepath = tmp
    bpy.ops.render.render(write_still=True)
    img = bpy.data.images.load(tmp)
    px = np.array(img.pixels[:], dtype=np.float32).reshape(H, W, 4)
    bpy.data.images.remove(img)
    os.remove(tmp)
    return post(px, palette)


def on_bg(px, k):
    big = np.repeat(np.repeat(px, k, axis=0), k, axis=1)
    bg = np.zeros_like(big)
    bg[:, :, :3] = 0.07
    bg[:, :, 3] = 1.0
    mask = big[:, :, 3:4]
    return big * mask + bg * (1 - mask)


def main():
    os.makedirs(OUT, exist_ok=True)
    cols = 6
    rows = (len(VARIANTS) + cols - 1) // cols
    sheet = np.zeros((H * rows, W * cols, 4), dtype=np.float32)
    for i, v in enumerate(VARIANTS):
        px = render_variant(v)
        r, c = i // cols, i % cols
        sheet[(rows - 1 - r) * H:(rows - r) * H, c * W:(c + 1) * W] = px  # imagens do Blender começam por baixo
        if i == 0:
            save(on_bg(px, 4), os.path.join(OUT, "organic_guard_x4.png"))
        print("VARIANT", i + 1, v)
    save(on_bg(sheet, 2), os.path.join(OUT, "variants_x2.png"))
    print("SPIKE_OK")


main()
