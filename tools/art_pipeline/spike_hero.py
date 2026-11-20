"""Spike E-10 (qualidade): aproximar o boneco da referência do usuário.

Uso: blender -b --factory-startup --python tools/art_pipeline/spike_hero.py -- <raiz> [altura_px]
Gera art_source/spike/hero_<altura>_x4.png (ampliado para revisão) e hero_<altura>.png (tamanho de jogo).

Diferenças para spike_organic.py:
  - passada de PROFUNDIDADE: linhas internas onde um membro passa na frente de outro (como na referência);
  - anatomia "herói": ombros largos, cintura fina, peitoral, abdômen, trapézio, deltoides, bíceps, antebraços;
  - pose da referência: base larga, joelhos flexionados, guarda alta, tronco mais de frente;
  - 6 tons de pele com brilho especular discreto.
"""
import math
import os
import sys

import bpy
import numpy as np

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
ROOT = ARGS[0] if ARGS else os.getcwd()
HEIGHT_PX = int(ARGS[1]) if len(ARGS) > 1 else 136
OUT = os.path.join(ROOT, "art_source", "spike")
PX_PER_M = HEIGHT_PX / 1.80
W = H = int(round(HEIGHT_PX * 1.25))
TURN_DEG = -40  # tronco virado para a câmera
DEPTH_NEAR, DEPTH_RANGE = 5.2, 1.6
INNER_EDGE_M = 0.05
CAVITY_M = 0.007  # vale entre músculos (desce 1 tom) / crista (sobe 1 tom), medido na profundidade  # salto de profundidade que vira linha interna


def lin(c):
    return tuple(((v + 0.055) / 1.055) ** 2.4 if v > 0.04045 else v / 12.92 for v in c)


def ramp(cols):
    return [tuple(c) for c in cols]


PALETTE = {
    # pele morena clara como na referência: 6 tons (sombra profunda -> brilho)
    "skin": ramp([(0.24, 0.12, 0.08), (0.38, 0.21, 0.13), (0.54, 0.32, 0.20), (0.69, 0.45, 0.30), (0.82, 0.59, 0.42), (0.94, 0.76, 0.60)]),
    "hair": ramp([(0.05, 0.04, 0.04), (0.10, 0.07, 0.06), (0.16, 0.11, 0.09), (0.23, 0.16, 0.13), (0.30, 0.22, 0.18), (0.38, 0.29, 0.24)]),
    "shorts": ramp([(0.05, 0.05, 0.06), (0.09, 0.09, 0.10), (0.13, 0.13, 0.15), (0.18, 0.18, 0.20), (0.25, 0.25, 0.27), (0.34, 0.34, 0.37)]),
    "glove": ramp([(0.04, 0.04, 0.05), (0.07, 0.07, 0.08), (0.11, 0.11, 0.12), (0.16, 0.16, 0.18), (0.23, 0.23, 0.25), (0.32, 0.32, 0.35)]),
    "accent": ramp([(0.30, 0.03, 0.04), (0.46, 0.05, 0.06), (0.62, 0.08, 0.09), (0.76, 0.13, 0.13), (0.88, 0.22, 0.20), (0.97, 0.38, 0.34)]),
    "white": ramp([(0.50, 0.50, 0.50), (0.62, 0.62, 0.62), (0.74, 0.74, 0.74), (0.84, 0.84, 0.84), (0.92, 0.92, 0.92), (0.99, 0.99, 0.99)]),
    "eye": ramp([(0.05, 0.04, 0.04)] * 6),
}
STOPS = [0.0, 0.07, 0.18, 0.36, 0.60, 0.86]
OUTLINE = (0.11, 0.06, 0.05)
INNER = (0.16, 0.08, 0.06)


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
    out, emit, dif, rgb, cr = (n.new(t) for t in ("ShaderNodeOutputMaterial", "ShaderNodeEmission", "ShaderNodeBsdfPrincipled",
                                                  "ShaderNodeShaderToRGB", "ShaderNodeValToRGB"))
    cr.color_ramp.interpolation = "CONSTANT"
    els = cr.color_ramp.elements
    while len(els) < len(STOPS):
        els.new(0.5)
    for el, pos, col in zip(els, STOPS, rmp):
        el.position = pos
        el.color = lin(col) + (1.0,)
    dif.inputs["Roughness"].default_value = 0.42  # brilho nos volumes musculares (definição da referência)
    dif.inputs["Base Color"].default_value = (0.8, 0.8, 0.8, 1.0)
    l.new(dif.outputs["BSDF"], rgb.inputs["Shader"])
    l.new(rgb.outputs["Color"], cr.inputs["Fac"])
    l.new(cr.outputs["Color"], emit.inputs["Color"])
    l.new(emit.outputs["Emission"], out.inputs["Surface"])
    return m


def seg_ball(name, a, b, t, r, mat, elong, front=0.0, side=0.0):
    """Elipsoide alinhado ao osso a->b, em t, deslocado para a frente (+) ou trás (-) do membro."""
    dx, dz = b[0] - a[0], b[2] - a[2]
    th = math.atan2(dx, dz)
    c = mid(a, b, t)
    px, pz = math.cos(th), -math.sin(th)
    return ball(name, (c[0] + px * front, c[1] + side, c[2] + pz * front), r, mat, (1.0, 1.0, elong), (0, math.degrees(th), 0))


def depth_material():
    m = bpy.data.materials.new("depth")
    m.use_nodes = True
    n, l = m.node_tree.nodes, m.node_tree.links
    n.clear()
    out, emit, cam = n.new("ShaderNodeOutputMaterial"), n.new("ShaderNodeEmission"), n.new("ShaderNodeCameraData")
    sub, mul = n.new("ShaderNodeMath"), n.new("ShaderNodeMath")
    sub.operation, mul.operation = "SUBTRACT", "MULTIPLY"
    sub.inputs[1].default_value = DEPTH_NEAR
    mul.inputs[1].default_value = 1.0 / DEPTH_RANGE
    l.new(cam.outputs["View Distance"], sub.inputs[0])
    l.new(sub.outputs[0], mul.inputs[0])
    l.new(mul.outputs[0], emit.inputs["Color"])
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
    bpy.ops.mesh.primitive_uv_sphere_add(segments=28, ring_count=14, radius=r, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = scale
    o.rotation_euler = tuple(math.radians(a) for a in rot)
    o.data.materials.append(mat)
    bpy.ops.object.shade_smooth()
    return o


def chain(name, pts, radii, mat):
    keys = list(pts)
    idx = {k: i for i, k in enumerate(keys)}
    edges = [(idx[a], idx[b]) for a, b in zip(keys, keys[1:])]
    return skin_body(name, [pts[k] for k in keys], edges, [radii[k] for k in keys], mat)


def mid(a, b, t=0.5):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def build(m):
    # Pose "guarda alta" da referência. x = frente, y = profundidade (+ longe da câmera), z = cima.
    P = {
        "hips": (0.0, 0.0, 0.89), "waist": (0.025, 0.0, 1.04), "chest": (0.05, 0.0, 1.24), "neck0": (0.065, 0.0, 1.39), "neck1": (0.085, 0.0, 1.47),
        "shL": (0.06, 0.20, 1.36), "elL": (0.17, 0.18, 1.16), "wrL": (0.29, 0.10, 1.38),
        "shR": (0.02, -0.20, 1.36), "elR": (0.12, -0.19, 1.12), "wrR": (0.24, -0.14, 1.33),
        "hpL": (0.03, 0.10, 0.86), "knL": (0.22, 0.15, 0.49), "anL": (0.20, 0.17, 0.08), "toL": (0.33, 0.18, 0.02),
        "hpR": (-0.04, -0.10, 0.86), "knR": (-0.12, -0.16, 0.47), "anR": (-0.28, -0.19, 0.10), "toR": (-0.17, -0.22, 0.02),
    }
    names = list(P)
    idx = {k: i for i, k in enumerate(names)}
    R = {
        "hips": (0.125, 0.155), "waist": (0.11, 0.135), "chest": (0.15, 0.21), "neck0": 0.072, "neck1": 0.064,
        "shL": 0.08, "elL": 0.05, "wrL": 0.036, "shR": 0.08, "elR": 0.05, "wrR": 0.036,
        "hpL": 0.138, "knL": 0.072, "anL": 0.043, "toL": (0.03, 0.046),
        "hpR": 0.138, "knR": 0.072, "anR": 0.043, "toR": (0.03, 0.046),
    }
    E = [("hips", "waist"), ("waist", "chest"), ("chest", "neck0"), ("neck0", "neck1"), ("chest", "shL"), ("shL", "elL"), ("elL", "wrL"),
         ("chest", "shR"), ("shR", "elR"), ("elR", "wrR"), ("hips", "hpL"), ("hpL", "knL"), ("knL", "anL"), ("anL", "toL"),
         ("hips", "hpR"), ("hpR", "knR"), ("knR", "anR"), ("anR", "toR")]
    skin_body("body", [P[k] for k in names], [(idx[a], idx[b]) for a, b in E], [R[k] for k in names], m["skin"])
    sk = m["skin"]
    # Tronco em V: dorsais, peitorais, trapézio, abdômen em 3 linhas, oblíquos.
    for s in (1, -1):
        ball("lat%d" % s, (0.02, 0.15 * s, 1.20), 0.075, sk, (0.8, 0.7, 1.5), (12 * s, 0, 0))
        ball("pec%d" % s, (0.135, 0.08 * s, 1.275), 0.082, sk, (0.7, 1.05, 0.72), (0, 0, 8 * s))
        ball("trap%d" % s, (0.03, 0.095 * s, 1.40), 0.062, sk, (0.9, 1.1, 0.7))
        for k, z in enumerate((1.165, 1.105, 1.045)):
            ball("ab%d_%d" % (s, k), (0.112, 0.034 * s, z), 0.031, sk, (0.75, 0.95, 0.85))
        ball("obl%d" % s, (0.07, 0.11 * s, 1.07), 0.05, sk, (0.8, 0.6, 1.3))
    # Braços: deltoide (3 cabeças em uma), bíceps, tríceps, antebraço.
    for side, s in (("L", 1), ("R", -1)):
        sh, el, wr = P["sh" + side], P["el" + side], P["wr" + side]
        ball("delt" + side, (sh[0] + 0.01, sh[1] + 0.012 * s, sh[2] - 0.01), 0.07, sk, (0.95, 0.9, 1.1))
        seg_ball("bicep" + side, sh, el, 0.55, 0.046, sk, 1.6, front=0.025)
        seg_ball("tricep" + side, sh, el, 0.45, 0.044, sk, 1.7, front=-0.022, side=0.008 * s)
        seg_ball("fore" + side, el, wr, 0.3, 0.046, sk, 1.6, front=0.008)
        # Luva de MMA: almofada dos nós voltada para cima/frente, punho preto com faixa vermelha, dedos à mostra.
        ball("glove" + side, (wr[0] + 0.02, wr[1], wr[2] + 0.06), 0.052, m["glove"], (1.0, 0.95, 1.2))
        ball("cuff" + side, (wr[0] + 0.005, wr[1], wr[2] + 0.005), 0.044, m["glove"], (1.0, 1.0, 0.85))
        ball("trim" + side, (wr[0], wr[1], wr[2] - 0.016), 0.042, m["accent"], (1.0, 1.0, 0.22))
        ball("fingers" + side, (wr[0] + 0.058, wr[1], wr[2] + 0.05), 0.024, sk, (0.75, 1.0, 1.25))
        # Pernas: panturrilha e joelho marcados.
        kn, an = P["kn" + side], P["an" + side]
        seg_ball("calf" + side, kn, an, 0.3, 0.062, sk, 1.9, front=-0.024)
        seg_ball("quadtip" + side, P["hp" + side], kn, 0.85, 0.064, sk, 1.3, front=0.02)
    # Calção de MMA: casca do cós às coxas, pernas no eixo das coxas; cós branco e faixa vermelha lateral.
    sp = {"top": (0.03, 0.0, 1.10), "w": (0.025, 0.0, 1.0), "h": (0.0, 0.0, 0.89), "hL": P["hpL"], "tL": mid(P["hpL"], P["knL"], 0.72),
          "hR": P["hpR"], "tR": mid(P["hpR"], P["knR"], 0.72)}
    sn = list(sp)
    si = {k: i for i, k in enumerate(sn)}
    skin_body("shorts", [sp[k] for k in sn], [(si["top"], si["w"]), (si["w"], si["h"]), (si["h"], si["hL"]), (si["hL"], si["tL"]),
                                               (si["h"], si["hR"]), (si["hR"], si["tR"])],
              [(0.095, 0.115), (0.132, 0.162), (0.16, 0.19), 0.158, 0.12, 0.158, 0.12], m["shorts"])
    ball("crotch", (0.02, 0.0, 0.82), 0.11, m["shorts"], (1.0, 1.3, 0.9))
    ball("waistband", (0.025, 0.0, 1.015), 0.142, m["shorts"], (0.97, 1.2, 0.16))
    ball("band_logo", (0.15, -0.04, 1.015), 0.02, m["white"], (0.5, 2.2, 0.5))  # logo fictício no cós
    ball("stripe", mid(P["hpR"], P["knR"], 0.4)[:1] + (-0.215,) + (mid(P["hpR"], P["knR"], 0.4)[2],), 0.022, m["accent"], (0.6, 0.4, 3.2), (0, -15, 0))
    # Cabeça: queixo um pouco baixo (guarda), cabelo curto com laterais raspadas, barba cheia aparada.
    hx, hz = 0.10, 1.585
    ball("skull", (hx, 0.0, hz + 0.02), 0.108, sk, (0.95, 0.86, 1.05))
    ball("jaw", (hx + 0.045, 0.0, hz - 0.06), 0.074, sk, (0.95, 0.9, 0.8))
    ball("nose", (hx + 0.1, -0.005, hz - 0.005), 0.018, sk, (1.2, 0.8, 1.3))
    ball("ear", (hx - 0.02, -0.088, hz + 0.005), 0.024, sk, (0.6, 0.6, 1.0))
    ball("eye", (hx + 0.082, -0.043, hz + 0.02), 0.011, m["eye"])
    ball("brow", (hx + 0.088, -0.04, hz + 0.042), 0.015, m["hair"], (0.9, 1.7, 0.45))
    ball("hair_top", (hx - 0.01, 0.0, hz + 0.08), 0.106, m["hair"], (1.0, 0.9, 0.6))
    ball("hair_fade", (hx - 0.03, 0.0, hz + 0.03), 0.108, m["hair"], (0.92, 0.88, 0.7))
    ball("beard", (hx + 0.045, 0.0, hz - 0.07), 0.073, m["hair"], (0.98, 0.9, 0.75))
    ball("mustache", (hx + 0.098, 0.0, hz - 0.035), 0.02, m["hair"], (0.8, 2.0, 0.6))


def camera_lights():
    cd = bpy.data.cameras.new("cam")
    cd.type = "ORTHO"
    cd.ortho_scale = W / PX_PER_M
    cam = bpy.data.objects.new("cam", cd)
    bpy.context.collection.objects.link(cam)
    cam.location = (0.0, -6.0, 0.95)
    cam.rotation_euler = (math.radians(90), 0, 0)
    bpy.context.scene.camera = cam
    for name, e, rot in (("key", 3.6, (48, 0, 38)), ("fill", 0.6, (70, 0, -30)), ("rim", 1.6, (55, 0, -120))):
        d = bpy.data.lights.new(name, "SUN")
        d.energy = e
        d.use_shadow = False
        o = bpy.data.objects.new(name, d)
        bpy.context.collection.objects.link(o)
        o.rotation_euler = tuple(math.radians(a) for a in rot)


def render(s, path):
    s.render.filepath = path
    bpy.ops.render.render(write_still=True)
    img = bpy.data.images.load(path)
    px = np.array(img.pixels[:], dtype=np.float32).reshape(H, W, 4)
    bpy.data.images.remove(img)
    os.remove(path)
    return px


def despeckle(rgb, a, passes=2):
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


def post(color, depth):
    colors = np.array([c for rmp in PALETTE.values() for c in rmp], dtype=np.float32)
    a = color[:, :, 3] > 0.5
    rgb = color[:, :, :3].copy()
    flat = rgb[a]
    d = ((flat[:, None, :] - colors[None, :, :]) ** 2).sum(axis=2)
    rgb[a] = colors[d.argmin(axis=1)]
    # Profundidade em metros a partir do PNG (codificado em sRGB pelo Blender).
    dv = depth[:, :, 0]
    dv = dv * DEPTH_RANGE + DEPTH_NEAR
    inner = np.zeros_like(a)
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        nb_d = np.roll(dv, (dy, dx), axis=(0, 1))
        nb_a = np.roll(a, (dy, dx), axis=(0, 1))
        inner |= a & nb_a & (dv - nb_d > INNER_EDGE_M)  # este pixel está ATRÁS do vizinho: linha do lado de trás
    # Vales e cristas (cavidade): compara com a média dos vizinhos a 2 px; ignora bordas e saltos.
    nbs = [np.roll(dv, (dy, dx), axis=(0, 1)) for dy, dx in ((2, 0), (-2, 0), (0, 2), (0, -2), (2, 2), (-2, -2), (2, -2), (-2, 2))]
    nba = [np.roll(a, (dy, dx), axis=(0, 1)) for dy, dx in ((2, 0), (-2, 0), (0, 2), (0, -2), (2, 2), (-2, -2), (2, -2), (-2, 2))]
    smooth = a.copy()
    for nd, na in zip(nbs, nba):
        smooth &= na & (np.abs(nd - dv) < INNER_EDGE_M)
    lap = dv - sum(nbs) / len(nbs)
    tone_of, ramps = {}, list(PALETTE.values())
    for ri, rmp in enumerate(ramps):
        for ti, c in enumerate(rmp):
            tone_of.setdefault(tuple(np.round(np.array(c, dtype=np.float32), 4)), (ri, ti))
    h, w = a.shape
    shifted = rgb.copy()
    for y in range(h):
        for x in range(w):
            if not smooth[y, x] or abs(lap[y, x]) < CAVITY_M:
                continue
            key = tone_of.get(tuple(np.round(rgb[y, x], 4)))
            if key is None:
                continue
            ri, ti = key
            ti = max(0, ti - 1) if lap[y, x] > 0 else min(len(ramps[ri]) - 1, ti + 1)
            shifted[y, x] = ramps[ri][ti]
    rgb = despeckle(shifted, a)
    rgb[inner] = INNER
    out = np.zeros_like(color)
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


def on_bg(px, k):
    big = np.repeat(np.repeat(px, k, axis=0), k, axis=1)
    bg = np.zeros_like(big)
    bg[:, :, :3] = 0.07
    bg[:, :, 3] = 1.0
    mask = big[:, :, 3:4]
    return big * mask + bg * (1 - mask)


def main():
    os.makedirs(OUT, exist_ok=True)
    s = reset()
    m = {k: toon(k, v) for k, v in PALETTE.items()}
    build(m)
    bpy.ops.object.empty_add(location=(0, 0, 0))
    root = bpy.context.active_object
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.parent = root
    root.rotation_euler = (0, 0, math.radians(TURN_DEG))
    camera_lights()
    s.render.image_settings.color_depth = "8"
    color = render(s, os.path.join(OUT, "_c.png"))
    s.render.image_settings.color_depth = "16"  # profundidade precisa; PNG de 16 bits volta linear ao carregar
    bpy.context.view_layer.material_override = depth_material()
    depth = render(s, os.path.join(OUT, "_d.png"))
    bpy.context.view_layer.material_override = None
    out = post(color, depth)
    save(out, os.path.join(OUT, "hero_%d.png" % HEIGHT_PX))
    save(on_bg(out, max(1, 640 // W)), os.path.join(OUT, "hero_%d_x4.png" % HEIGHT_PX))
    print("SPIKE_OK", W, H)


main()
