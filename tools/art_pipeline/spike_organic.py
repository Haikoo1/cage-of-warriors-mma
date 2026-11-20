"""Spike E-10: corpo orgânico (Skin modifier + subdivisão) no estilo da referência do usuário.

Uso: blender -b --factory-startup --python tools/art_pipeline/spike_organic.py -- <raiz>
Gera art_source/spike/organic_guard.png (tamanho de jogo) e organic_guard_x4.png (ampliado para revisão).
Só a pose de guarda: mede se o visual chega perto da referência antes de reescrever o pipeline.
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


# Paleta em cores de TELA (sRGB), 5 tons por material, escuro -> claro.
PALETTE = {
    "skin": [(0.30, 0.17, 0.12), (0.46, 0.28, 0.19), (0.62, 0.40, 0.28), (0.78, 0.55, 0.40), (0.91, 0.71, 0.55)],
    "hair": [(0.07, 0.05, 0.05), (0.13, 0.09, 0.08), (0.20, 0.14, 0.12), (0.28, 0.20, 0.17), (0.36, 0.27, 0.23)],
    "shorts": [(0.06, 0.06, 0.07), (0.11, 0.11, 0.13), (0.17, 0.17, 0.19), (0.25, 0.25, 0.28), (0.35, 0.35, 0.38)],
    "glove": [(0.04, 0.04, 0.05), (0.09, 0.09, 0.10), (0.15, 0.15, 0.17), (0.23, 0.23, 0.26), (0.33, 0.33, 0.36)],
    "accent": [(0.36, 0.04, 0.05), (0.55, 0.07, 0.08), (0.72, 0.12, 0.12), (0.86, 0.22, 0.20), (0.96, 0.40, 0.36)],
    "white": [(0.55, 0.55, 0.55), (0.70, 0.70, 0.70), (0.82, 0.82, 0.82), (0.92, 0.92, 0.92), (0.99, 0.99, 0.99)],
    "eye": [(0.05, 0.04, 0.04)] * 5,
}
OUTLINE = (0.12, 0.07, 0.06)


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


def toon(name, ramp):
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
    for el, pos, col in zip(els, [0.0, 0.10, 0.25, 0.50, 0.80], ramp):
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
        sv = obj.data.skin_vertices[0].data[i]
        sv.radius = r if isinstance(r, tuple) else (r, r)
    obj.data.skin_vertices[0].data[0].use_root = True
    obj.modifiers.new("sub", "SUBSURF").levels = subdiv
    obj.modifiers["sub"].render_levels = subdiv
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


def build(m):
    # Esqueleto na pose de guarda (ortodoxo; perna/braço esquerdos à frente, lado longe = +y).
    V = {
        "hips": (0.0, 0.0, 0.96), "waist": (0.03, 0.0, 1.12), "chest": (0.06, 0.0, 1.30), "neck0": (0.07, 0.0, 1.45), "neck1": (0.09, 0.0, 1.53),
        "shL": (0.07, 0.17, 1.41), "elL": (0.18, 0.21, 1.20), "wrL": (0.30, 0.14, 1.40),
        "shR": (0.03, -0.17, 1.41), "elR": (0.11, -0.21, 1.17), "wrR": (0.21, -0.10, 1.43),
        "hpL": (0.02, 0.10, 0.93), "knL": (0.20, 0.12, 0.52), "anL": (0.24, 0.13, 0.08), "toL": (0.37, 0.13, 0.025),
        "hpR": (-0.03, -0.10, 0.93), "knR": (-0.10, -0.12, 0.51), "anR": (-0.26, -0.13, 0.13), "toR": (-0.15, -0.13, 0.025),
    }
    R = {
        "hips": (0.13, 0.16), "waist": (0.12, 0.14), "chest": (0.14, 0.18), "neck0": 0.065, "neck1": 0.058,
        "shL": 0.075, "elL": 0.045, "wrL": 0.034, "shR": 0.075, "elR": 0.045, "wrR": 0.034,
        "hpL": 0.118, "knL": 0.062, "anL": 0.04, "toL": (0.03, 0.045), "hpR": 0.118, "knR": 0.062, "anR": 0.04, "toR": (0.03, 0.045),
    }
    names = list(V)
    idx = {k: i for i, k in enumerate(names)}
    E = [("hips", "waist"), ("waist", "chest"), ("chest", "neck0"), ("neck0", "neck1"), ("chest", "shL"), ("shL", "elL"), ("elL", "wrL"),
         ("chest", "shR"), ("shR", "elR"), ("elR", "wrR"), ("hips", "hpL"), ("hpL", "knL"), ("knL", "anL"), ("anL", "toL"), ("hips", "hpR"), ("hpR", "knR"), ("knR", "anR"), ("anR", "toR")]
    skin_body("body", [V[k] for k in names], [(idx[a], idx[b]) for a, b in E], [R[k] for k in names], m["skin"])
    # Músculos (volumes que a referência marca): peitoral, deltoides, bíceps, antebraço, quadríceps, panturrilha, trapézio.
    ball("pec", (0.14, -0.05, 1.33), 0.085, m["skin"], (0.6, 1.3, 0.75))
    ball("delt_R", (0.04, -0.19, 1.39), 0.072, m["skin"])
    ball("delt_L", (0.08, 0.19, 1.39), 0.07, m["skin"])
    ball("bicep_R", (0.09, -0.21, 1.26), 0.05, m["skin"], (1.0, 1.0, 1.5), (0, -20, 0))
    ball("fore_R", (0.17, -0.16, 1.28), 0.042, m["skin"], (1.0, 1.0, 1.7), (0, 40, 0))
    ball("quad_L", (0.12, 0.11, 0.72), 0.085, m["skin"], (1.0, 1.0, 1.8), (0, 25, 0))
    ball("calf_L", (0.19, 0.13, 0.32), 0.058, m["skin"], (1.0, 1.0, 1.9), (0, 5, 0))
    ball("calf_R", (-0.22, -0.13, 0.33), 0.058, m["skin"], (1.0, 1.0, 1.9), (0, -25, 0))
    ball("trap", (0.04, 0.0, 1.44), 0.09, m["skin"], (0.9, 1.6, 0.55))
    ball("abs", (0.135, -0.02, 1.13), 0.05, m["skin"], (0.5, 1.4, 1.8))
    # Calção de MMA (casca sobre quadril e coxas) com faixa de cor e cós claro.
    sv = {"w": (0.03, 0.0, 1.07), "h": (0.0, 0.0, 0.95), "tL": (0.15, 0.115, 0.62), "tR": (-0.09, -0.115, 0.62)}
    sn = list(sv)
    si = {k: i for i, k in enumerate(sn)}
    skin_body("shorts", [sv[k] for k in sn], [(si["w"], si["h"]), (si["h"], si["tL"]), (si["h"], si["tR"])],
              [(0.14, 0.17), (0.15, 0.18), 0.112, 0.112], m["shorts"])
    ball("waistband", (0.03, 0.0, 1.035), 0.142, m["white"], (0.97, 1.2, 0.14))
    ball("short_stripe", (-0.05, -0.17, 0.80), 0.03, m["accent"], (0.7, 0.4, 3.0), (0, -12, 0))
    # Cabeça: crânio, mandíbula, nariz, orelha, olho, sobrancelha, cabelo curto, barba rente.
    ball("skull", (0.09, 0.0, 1.66), 0.105, m["skin"], (0.95, 0.85, 1.05))
    ball("jaw", (0.135, 0.0, 1.585), 0.068, m["skin"], (0.95, 0.85, 0.8))
    ball("nose", (0.195, -0.005, 1.635), 0.018, m["skin"], (1.2, 0.8, 1.3))
    ball("ear", (0.07, -0.088, 1.645), 0.024, m["skin"], (0.6, 0.6, 1.0))
    ball("eye", (0.172, -0.045, 1.66), 0.011, m["eye"])
    ball("brow", (0.178, -0.04, 1.68), 0.014, m["hair"], (0.9, 1.6, 0.45))
    ball("hair", (0.075, 0.0, 1.71), 0.104, m["hair"], (1.0, 0.92, 0.62))
    ball("beard", (0.135, 0.0, 1.575), 0.07, m["hair"], (0.97, 0.87, 0.72))
    # Luvas de MMA (4 oz): almofada nos nós dos dedos, punho com velcro e detalhe vermelho; dedos à mostra.
    for side, wr, k in (("L", V["wrL"], 1.0), ("R", V["wrR"], 1.0)):
        ball("glove_" + side, (wr[0] + 0.03, wr[1], wr[2] + 0.05), 0.05, m["glove"], (1.1, 0.95, 1.15))
        ball("cuff_" + side, (wr[0] + 0.005, wr[1], wr[2] + 0.005), 0.042, m["glove"], (1.0, 1.0, 0.8))
        ball("trim_" + side, (wr[0] + 0.0, wr[1], wr[2] - 0.012), 0.04, m["accent"], (1.0, 1.0, 0.25))
        ball("fingers_" + side, (wr[0] + 0.065, wr[1], wr[2] + 0.045), 0.025, m["skin"], (0.7, 1.0, 1.2))


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
                same = sum(1 for n, o in zip(nbs, ok) if o and np.allclose(n, c))
                if same == 0:
                    cands = [tuple(n) for n, o in zip(nbs, ok) if o]
                    if cands:
                        out[y, x] = max(set(cands), key=cands.count)
        rgb = out
    return rgb


def post(px):
    colors = np.array([c for ramp in PALETTE.values() for c in ramp], dtype=np.float32)
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


def main():
    s = reset()
    m = {k: toon(k, v) for k, v in PALETTE.items()}
    build(m)
    bpy.ops.object.empty_add(location=(0, 0, 0))
    root = bpy.context.active_object
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.parent = root
    root.rotation_euler = (0, 0, math.radians(-30))  # 3/4: peito virado para a câmera, como na referência
    camera_lights()
    os.makedirs(OUT, exist_ok=True)
    tmp = os.path.join(OUT, "_raw.png")
    s.render.filepath = tmp
    bpy.ops.render.render(write_still=True)
    img = bpy.data.images.load(tmp)
    px = np.array(img.pixels[:], dtype=np.float32).reshape(H, W, 4)
    out = post(px)
    save(out, os.path.join(OUT, "organic_guard.png"))
    big = np.repeat(np.repeat(out, 4, axis=0), 4, axis=1)
    bg = np.zeros_like(big)
    bg[:, :, :3] = 0.07
    bg[:, :, 3] = 1.0
    mask = big[:, :, 3:4]
    save(big * mask + bg * (1 - mask), os.path.join(OUT, "organic_guard_x4.png"))
    print("SPIKE_OK")


main()
