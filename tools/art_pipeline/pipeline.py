"""Pipeline 3D -> pixel art v3: corpo ORGÂNICO em 3/4, no estilo da referência do usuário (D-022).

Uso (headless):
  blender -b --factory-startup --python tools/art_pipeline/pipeline.py -- <raiz> [biótipo ...]

O que faz:
  1. Poses por cinemática direta (FK) a partir de ângulos por articulação; tempos lidos dos dados do jogo
     (data/strikes, data/grappling). A cada quadro o corpo é reconstruído: malha contínua (Skin modifier +
     subdivisão) com músculos alinhados aos ossos, calção de MMA, luvas de MMA (dedos à mostra), cabeça.
  2. Renderiza em câmera ortográfica, corpo virado 30° para a câmera, toon de 6 tons com brilho, sem sombras
     projetadas, em CAMADAS: corpo (4 físicos) · cabelo (8 estilos) · barba (4 estilos).
  3. Pós-processo por camada: quantização na paleta da camada, limpeza de pixels isolados, linhas internas e
     vales/cristas musculares tirados de uma passada de PROFUNDIDADE (16 bits), contorno externo de 1 px.
  4. Spritesheets PNG + JSON com a paleta de origem; o jogo recolore pele, cabelo, calção, luvas e detalhe.
"""
import json
import math
import os
import re
import sys
import time

import bpy
import numpy as np

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
ROOT = ARGS[0] if ARGS else os.getcwd()
TMP_DIR = os.path.join(ROOT, "art_source", "render_tmp")

SIM_FPS = 60
SIM_FRAMES_PER_SPRITE = 3  # 20 fps de sprite
PX_PER_M = 105.0  # D-022: lutador médio de 1,80 m ≈ 189 px na área de luta 960x540
FRAME_W, FRAME_H = 320, 224
CAM_X_OFFSET = 0.42
CAM_Z = 0.95
TURN_DEG = -30.0  # 3/4: peito virado para a câmera (a leitura do alcance perde só ~13%)
DEPTH_NEAR, DEPTH_RANGE = 5.0, 2.0
INNER_EDGE_M = 0.05
CAVITY_M = 0.007


def lin(c):
    return tuple(((v + 0.055) / 1.055) ** 2.4 if v > 0.04045 else v / 12.92 for v in c)


# Paleta de ORIGEM em cores de tela (sRGB), 6 tons por material (escuro -> claro).
PALETTE = {
    "skin": [(0.24, 0.12, 0.08), (0.38, 0.21, 0.13), (0.54, 0.32, 0.20), (0.69, 0.45, 0.30), (0.82, 0.59, 0.42), (0.94, 0.76, 0.60)],
    "hair": [(0.05, 0.04, 0.04), (0.10, 0.07, 0.06), (0.16, 0.11, 0.09), (0.23, 0.16, 0.13), (0.30, 0.22, 0.18), (0.38, 0.29, 0.24)],
    "shorts": [(0.05, 0.05, 0.10), (0.09, 0.09, 0.17), (0.13, 0.13, 0.25), (0.18, 0.18, 0.34), (0.25, 0.25, 0.44), (0.34, 0.34, 0.55)],
    "glove": [(0.04, 0.05, 0.04), (0.07, 0.09, 0.07), (0.11, 0.14, 0.11), (0.16, 0.20, 0.16), (0.23, 0.28, 0.23), (0.32, 0.38, 0.32)],
    "accent": [(0.30, 0.03, 0.04), (0.46, 0.05, 0.06), (0.62, 0.08, 0.09), (0.76, 0.13, 0.13), (0.88, 0.22, 0.20), (0.97, 0.38, 0.34)],
    "white": [(0.50, 0.50, 0.47), (0.62, 0.62, 0.59), (0.74, 0.74, 0.71), (0.84, 0.84, 0.81), (0.92, 0.92, 0.89), (0.99, 0.99, 0.96)],
    "eye": [(0.03, 0.02, 0.02)] * 6,
}
STOPS = [0.0, 0.07, 0.18, 0.36, 0.60, 0.86]
LAYER_MATERIALS = {"body": ["skin", "hair", "shorts", "glove", "accent", "white", "eye"], "hair": ["hair"], "beard": ["hair"]}
OUTLINE = (0.11, 0.06, 0.05)
INNER = (0.16, 0.08, 0.06)

BUILDS = [  # físico visual (criador): 0 magro, 1 atlético (padrão), 2 musculoso, 3 pesado
    {"torso": 0.88, "limb": 0.86, "muscle": 0.75, "belly": 0.0},
    {"torso": 1.0, "limb": 1.0, "muscle": 1.0, "belly": 0.0},
    {"torso": 1.1, "limb": 1.13, "muscle": 1.3, "belly": 0.0},
    {"torso": 1.18, "limb": 1.12, "muscle": 0.95, "belly": 1.0},
]
DEFAULT_BUILD = 1
HAIR_STYLES = {1: "raspado", 2: "curto", 3: "moicano", 4: "coque", 5: "black_power", 6: "rabo", 7: "dreads", 8: "topete"}
BEARDS = {1: "rente", 2: "cheia", 3: "cavanhaque", 4: "bigode"}
BIOTYPES = {
    "m_medium": {"scale": 1.0, "female": False},
    "f_medium": {"scale": 0.935, "female": True},
}
BT = BIOTYPES["m_medium"]

# Esqueleto (metros). Comprimentos dos ossos e pontos locais do tronco/pelve/cabeça.
L_UA, L_FA, L_TH, L_SH = 0.26, 0.25, 0.42, 0.40
TORSO_LOCAL = {"waist": (0.025, 0.0, 0.15), "chest": (0.05, 0.0, 0.35), "neck0": (0.065, 0.0, 0.50), "neck1": (0.085, 0.0, 0.58)}
HEAD_CENTER = (0.015, 0.115)  # do topo do pescoço ao centro da cabeça, no referencial da cabeça


# ---------------------------------------------------------------------------- dados do jogo
def read_tres(path):
    values = {}
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            m = re.match(r"^(\w+) = (.+)$", line.strip())
            if m:
                values[m.group(1)] = m.group(2)
    return values


def strike_phases(strike_id):
    v = read_tres(os.path.join(ROOT, "data", "strikes", strike_id + ".tres"))
    return int(v["startup_frames"]), int(v["active_frames"]), int(v["recovery_frames"])


def grapple_startup(tech_id):
    return int(read_tres(os.path.join(ROOT, "data", "grappling", tech_id + ".tres"))["startup_frames"])


# ---------------------------------------------------------------------------- cena, materiais, primitivas
def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    s = bpy.context.scene
    s.render.engine = "BLENDER_EEVEE"
    s.render.resolution_x, s.render.resolution_y = FRAME_W, FRAME_H
    s.render.resolution_percentage = 100
    s.render.film_transparent = True
    s.render.filter_size = 0.0
    s.render.image_settings.file_format = "PNG"
    s.render.image_settings.color_mode = "RGBA"
    s.view_settings.view_transform = "Standard"
    if hasattr(s.eevee, "taa_render_samples"):
        s.eevee.taa_render_samples = 1
    return s


def toon_material(name, ramp):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    n, l = m.node_tree.nodes, m.node_tree.links
    n.clear()
    out, emit, bsdf, rgb, cr = (n.new(t) for t in ("ShaderNodeOutputMaterial", "ShaderNodeEmission", "ShaderNodeBsdfPrincipled",
                                                   "ShaderNodeShaderToRGB", "ShaderNodeValToRGB"))
    bsdf.inputs["Roughness"].default_value = 0.42  # brilho nos volumes (definição muscular da referência)
    bsdf.inputs["Base Color"].default_value = (0.8, 0.8, 0.8, 1.0)
    cr.color_ramp.interpolation = "CONSTANT"
    els = cr.color_ramp.elements
    while len(els) < len(STOPS):
        els.new(0.5)
    for el, pos, col in zip(els, STOPS, ramp):
        el.position = pos
        el.color = lin(col) + (1.0,)
    l.new(bsdf.outputs["BSDF"], rgb.inputs["Shader"])
    l.new(rgb.outputs["Color"], cr.inputs["Fac"])
    l.new(cr.outputs["Color"], emit.inputs["Color"])
    l.new(emit.outputs["Emission"], out.inputs["Surface"])
    return m


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


class Builder:
    """Cria a geometria de um quadro. Esferas compartilham uma malha-modelo (rápido); material por objeto."""

    def __init__(self, mats, root):
        self.m = mats
        self.root = root
        bpy.ops.mesh.primitive_uv_sphere_add(segments=28, ring_count=14, radius=1.0)
        tpl = bpy.context.active_object
        bpy.ops.object.shade_smooth()
        self.sphere = tpl.data
        self.sphere.materials.append(mats["skin"])  # slot que cada objeto sobrescreve (link OBJECT)
        bpy.data.objects.remove(tpl)
        self.objects = []

    def clear(self):
        for o in self.objects:
            mesh = o.data
            bpy.data.objects.remove(o)
            if mesh is not self.sphere and mesh.users == 0:
                bpy.data.meshes.remove(mesh)
        self.objects = []

    def ball(self, name, loc, r, mat, scale=(1, 1, 1), rot_y=0.0, rot_x=0.0, rot_z=0.0):
        o = bpy.data.objects.new(name, self.sphere)
        bpy.context.collection.objects.link(o)
        o.location = loc
        o.scale = (r * scale[0], r * scale[1], r * scale[2])
        o.rotation_euler = (math.radians(rot_x), math.radians(rot_y), math.radians(rot_z))
        o.material_slots[0].link = "OBJECT"
        o.material_slots[0].material = self.m[mat]
        o.parent = self.root
        self.objects.append(o)
        return o

    def skin(self, name, pts, edges, radii, mat):
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(pts, edges, [])
        o = bpy.data.objects.new(name, mesh)
        bpy.context.collection.objects.link(o)
        o.data.materials.append(self.m[mat])
        mod = o.modifiers.new("skin", "SKIN")
        mod.use_smooth_shade = True
        for i, r in enumerate(radii):
            o.data.skin_vertices[0].data[i].radius = r if isinstance(r, tuple) else (r, r)
        o.data.skin_vertices[0].data[0].use_root = True
        sub = o.modifiers.new("sub", "SUBSURF")
        sub.levels = sub.render_levels = 2
        o.parent = self.root
        self.objects.append(o)
        return o

    def seg(self, name, a, b, t, r, mat, elong, front=0.0, side=0.0):
        """Elipsoide alinhado ao osso a->b, em t, deslocado para a frente (+) ou trás (-) do membro."""
        th = math.atan2(b[0] - a[0], b[2] - a[2])
        c = mid(a, b, t)
        return self.ball(name, (c[0] + math.cos(th) * front, c[1] + side, c[2] - math.sin(th) * front), r, mat,
                         (1.0, 1.0, elong), math.degrees(th))


def mid(a, b, t=0.5):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def rot(v, deg):
    """Rotação em torno de Y (convenção do Blender): ângulo positivo leva +z para +x (inclinar para a frente)."""
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    return (v[0] * c + v[2] * s, v[1], -v[0] * s + v[2] * c)


def add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


# ---------------------------------------------------------------------------- esqueleto (FK) e corpo
def skeleton(p):
    H = (p["hips_x"], 0.0, p["hips_z"])
    T = p["torso"]
    J = {"hips": H}
    for k, v in TORSO_LOCAL.items():
        J[k] = add(H, rot(v, T))
    for side, s, ua, fa in (("L", 1, "upper_arm_L", "forearm_L"), ("R", -1, "upper_arm_R", "forearm_R")):
        sh = add(H, rot((0.06 if s > 0 else 0.02, 0.20 * s, 0.47), T))
        a1 = T + p[ua]
        el = add(sh, rot((0.0, -0.03 * s, -L_UA), a1))
        a2 = a1 + p[fa]
        wr = add(el, rot((0.0, -0.07 * s, -L_FA), a2))
        J["sh" + side], J["el" + side], J["wr" + side], J["fa_ang" + side] = sh, el, wr, a2
    for side, s, th, sn in (("L", 1, "thigh_L", "shin_L"), ("R", -1, "thigh_R", "shin_R")):
        hp = add(H, (0.03 if s > 0 else -0.04, 0.10 * s, -0.03))
        kn = add(hp, rot((0.0, 0.04 * s, -L_TH), p[th]))
        a2 = p[th] + p[sn]
        an = add(kn, rot((0.0, 0.02 * s, -L_SH), a2))
        to = add(an, rot((0.13, 0.01 * s, -0.045), a2 * 0.35))  # pé: acompanha pouco a canela (calcanhar sobe)
        J["hp" + side], J["kn" + side], J["an" + side], J["to" + side] = hp, kn, an, to
    J["T"], J["head_ang"] = T, T + p["head"]
    return J


def build_frame(bd, p, build, female):
    b = BUILDS[build]
    t, lb, mu = b["torso"], b["limb"], b["muscle"]
    J = skeleton(p)
    T = J["T"]
    H = J["hips"]
    names = ["hips", "waist", "chest", "neck0", "neck1", "shL", "elL", "wrL", "shR", "elR", "wrR",
             "hpL", "knL", "anL", "toL", "hpR", "knR", "anR", "toR"]
    fw = 0.88 if female else 1.0  # ombros mais estreitos
    R = {
        "hips": (0.125 * t, 0.155 * t * (1.08 if female else 1.0)), "waist": (0.11 * t * (1 + 0.15 * b["belly"]), 0.135 * t),
        "chest": (0.15 * t * mu ** 0.25, 0.21 * t * fw), "neck0": 0.072 * t * fw, "neck1": 0.064 * t * fw,
        "shL": 0.08 * lb * fw, "elL": 0.05 * lb, "wrL": 0.036 * lb, "shR": 0.08 * lb * fw, "elR": 0.05 * lb, "wrR": 0.036 * lb,
        "hpL": 0.138 * lb, "knL": 0.072 * lb, "anL": 0.043, "toL": (0.03, 0.046),
        "hpR": 0.138 * lb, "knR": 0.072 * lb, "anR": 0.043, "toR": (0.03, 0.046),
    }
    idx = {k: i for i, k in enumerate(names)}
    E = [("hips", "waist"), ("waist", "chest"), ("chest", "neck0"), ("neck0", "neck1"), ("chest", "shL"), ("shL", "elL"), ("elL", "wrL"),
         ("chest", "shR"), ("shR", "elR"), ("elR", "wrR"), ("hips", "hpL"), ("hpL", "knL"), ("knL", "anL"), ("anL", "toL"),
         ("hips", "hpR"), ("hpR", "knR"), ("knR", "anR"), ("anR", "toR")]
    bd.skin("body", [J[k] for k in names], [(idx[a], idx[c]) for a, c in E], [R[k] for k in names], "skin")
    tp = lambda v: add(H, rot((v[0], v[1], v[2] - 0.89), T))  # ponto do tronco (coordenadas da pose de referência)
    for s in (1, -1):
        bd.ball("lat%d" % s, tp((0.02, 0.15 * s * fw, 1.20)), 0.075 * t, "skin", (0.8, 0.7, 1.5), T, 12 * s)
        bd.ball("trap%d" % s, tp((0.03, 0.095 * s * fw, 1.40)), 0.062 * t * mu ** 0.5, "skin", (0.9, 1.1, 0.7), T)
        if not female:
            bd.ball("pec%d" % s, tp((0.135, 0.08 * s, 1.275)), 0.082 * t * mu ** 0.5, "skin", (0.7, 1.05, 0.72), T, 0, 8 * s)
            if b["belly"] == 0:
                for k, z in enumerate((1.165, 1.105, 1.045)):
                    bd.ball("ab%d_%d" % (s, k), tp((0.112, 0.034 * s, z)), 0.031 * mu ** 0.5, "skin", (0.75, 0.95, 0.85), T)
        bd.ball("obl%d" % s, tp((0.07, 0.11 * s, 1.07)), 0.05 * t, "skin", (0.8, 0.6, 1.3), T)
    if female:
        bd.ball("top", tp((0.06, 0.0, 1.26)), 0.165 * t, "shorts", (0.9, 1.12 * fw, 0.62), T)
        bd.ball("top_band", tp((0.055, 0.0, 1.19)), 0.152 * t, "accent", (0.92, 1.12 * fw, 0.12), T)
    if b["belly"] > 0:
        bd.ball("belly", tp((0.10, -0.01, 1.11)), 0.13 * t, "skin", (0.85, 1.1, 1.0), T)
    for side, s in (("L", 1), ("R", -1)):
        sh, el, wr = J["sh" + side], J["el" + side], J["wr" + side]
        bd.ball("delt" + side, add(sh, (0.0, 0.012 * s, -0.01)), 0.07 * lb * mu ** 0.5 * fw, "skin", (0.95, 0.9, 1.1), T)
        bd.seg("bicep" + side, sh, el, 0.55, 0.046 * lb * mu, "skin", 1.6, front=0.025)
        bd.seg("tricep" + side, sh, el, 0.45, 0.044 * lb * mu ** 0.7, "skin", 1.7, front=-0.022, side=0.008 * s)
        bd.seg("fore" + side, el, wr, 0.3, 0.046 * lb, "skin", 1.6, front=0.008)
        # Luva de MMA: almofada dos nós além do punho, punho preto com faixa de detalhe, dedos à mostra.
        d = (wr[0] - el[0], wr[1] - el[1], wr[2] - el[2])
        n = math.sqrt(d[0] ** 2 + d[1] ** 2 + d[2] ** 2) or 1.0
        d = (d[0] / n, d[1] / n, d[2] / n)
        ga = math.degrees(math.atan2(d[0], d[2]))
        bd.ball("glove" + side, add(wr, (d[0] * 0.06, d[1] * 0.06, d[2] * 0.06)), 0.052, "glove", (1.0, 0.95, 1.2), ga)
        bd.ball("cuff" + side, add(wr, (d[0] * 0.005, 0, d[2] * 0.005)), 0.044, "glove", (1.0, 1.0, 0.85), ga)
        bd.ball("trim" + side, add(wr, (-d[0] * 0.016, 0, -d[2] * 0.016)), 0.042, "accent", (1.0, 1.0, 0.22), ga)
        fx, fz = math.cos(math.radians(ga)), -math.sin(math.radians(ga))
        bd.ball("fingers" + side, add(wr, (d[0] * 0.05 + fx * 0.035, d[1] * 0.05, d[2] * 0.05 + fz * 0.035)), 0.024, "skin", (0.75, 1.0, 1.25), ga)
        kn, an, hp = J["kn" + side], J["an" + side], J["hp" + side]
        bd.seg("calf" + side, kn, an, 0.3, 0.062 * lb * mu ** 0.5, "skin", 1.9, front=-0.024)
        bd.seg("quadtip" + side, hp, kn, 0.85, 0.064 * lb * mu ** 0.5, "skin", 1.3, front=0.02)
    # Calção de MMA: casca do cós às coxas, pernas no eixo das coxas; cós da cor do calção, faixa lateral de detalhe.
    sp = [tp((0.03, 0.0, 1.10)), tp((0.025, 0.0, 1.0)), H, J["hpL"], mid(J["hpL"], J["knL"], 0.72), J["hpR"], mid(J["hpR"], J["knR"], 0.72)]
    belly = 1 + 0.1 * b["belly"]
    bd.skin("shorts", sp, [(0, 1), (1, 2), (2, 3), (3, 4), (2, 5), (5, 6)],
            [(0.095 * t, 0.115 * t), (0.132 * t * belly, 0.162 * t), (0.16 * t, 0.19 * t), 0.158 * lb, 0.12 * lb, 0.158 * lb, 0.12 * lb], "shorts")
    bd.ball("crotch", add(H, (0.02, 0.0, -0.07)), 0.11 * t, "shorts", (1.0, 1.3, 0.9))
    bd.ball("waistband", tp((0.025, 0.0, 1.015)), 0.142 * t * belly, "shorts", (0.97, 1.2, 0.16), T)
    bd.ball("band_logo", tp((0.15 * t * belly, -0.04, 1.015)), 0.02, "white", (0.5, 2.2, 0.5), T)  # logo fictício
    bd.seg("stripe", J["hpR"], J["knR"], 0.42, 0.014, "accent", 5.0, side=-0.118 * lb)
    build_head(bd, J, female)


def build_head(bd, J, female):
    n1, A = J["neck1"], J["head_ang"]
    hp = lambda dx, dy, dz: add(n1, rot((HEAD_CENTER[0] + dx, dy, HEAD_CENTER[1] + dz), A))
    bd.ball("skull", hp(0, 0, 0.02), 0.108 * (0.95 if female else 1.0), "skin", (0.95, 0.86, 1.05), A)
    bd.ball("jaw", hp(0.045, 0, -0.06), 0.074 * (0.88 if female else 1.0), "skin", (0.95, 0.9, 0.8), A)
    bd.ball("nose", hp(0.1, -0.005, -0.005), 0.018, "skin", (1.2, 0.8, 1.3), A)
    bd.ball("ear", hp(-0.02, -0.088, 0.005), 0.024, "skin", (0.6, 0.6, 1.0), A)
    bd.ball("eye", hp(0.082, -0.043, 0.02), 0.011, "eye", (1, 1, 1), A)
    bd.ball("brow", hp(0.088, -0.04, 0.042), 0.015, "hair", (0.9, 1.7, 0.45), A)
    cap = lambda tag: bd.ball("hair%d_cap" % tag, hp(-0.01, 0, 0.08), 0.106, "hair", (1.0, 0.9, 0.6), A)
    # Cabelos (camadas): objetos hair<N>_*.
    bd.ball("hair1_buzz", hp(-0.004, 0, 0.05), 0.111, "hair", (0.97, 0.89, 0.7), A)
    cap(2)
    bd.ball("hair2_fade", hp(-0.03, 0, 0.03), 0.108, "hair", (0.92, 0.88, 0.7), A)
    bd.ball("hair3_mohawk", hp(-0.02, 0, 0.13), 0.095, "hair", (1.12, 0.28, 0.62), A)
    cap(4)
    bd.ball("hair4_bun", hp(-0.125, 0, 0.17), 0.045, "hair", (1, 1, 1), A)
    bd.ball("hair5_afro", hp(-0.03, 0, 0.09), 0.14, "hair", (1.0, 1.04, 0.9), A)
    cap(6)
    bd.ball("hair6_tail", hp(-0.15, 0, 0.0), 0.036, "hair", (1.0, 1.0, 2.6), A - 22)
    cap(7)
    for k, (x, y) in enumerate(((-0.12, 0.0), (-0.10, -0.07), (-0.10, 0.07), (-0.06, -0.09), (-0.06, 0.09), (-0.14, -0.04), (-0.14, 0.04))):
        bd.ball("hair7_lock%d" % k, hp(x, y, -0.02), 0.021, "hair", (1.0, 1.0, 3.2), A - 10)
    cap(8)
    bd.ball("hair8_quiff", hp(0.05, 0, 0.13), 0.05, "hair", (1.3, 1.4, 0.8), A - 20)
    # Barbas (camadas): objetos beard<N>_*.
    if not female:
        bd.ball("beard1_stubble", hp(0.045, 0, -0.07), 0.073, "hair", (0.98, 0.9, 0.75), A)
        bd.ball("beard2_full", hp(0.04, 0, -0.085), 0.082, "hair", (1.0, 0.9, 0.85), A)
        bd.ball("beard2_mustache", hp(0.098, 0, -0.035), 0.02, "hair", (0.8, 2.0, 0.6), A)
        bd.ball("beard3_goatee", hp(0.088, 0, -0.105), 0.03, "hair", (1.0, 1.2, 1.3), A)
        bd.ball("beard4_mustache", hp(0.102, 0, -0.03), 0.02, "hair", (0.8, 2.2, 0.6), A)


def setup_camera_and_lights():
    cd = bpy.data.cameras.new("cam")
    cd.type = "ORTHO"
    cd.ortho_scale = FRAME_W / PX_PER_M
    cam = bpy.data.objects.new("cam", cd)
    bpy.context.collection.objects.link(cam)
    cam.location = (CAM_X_OFFSET, -6.0, CAM_Z)
    cam.rotation_euler = (math.radians(90), 0, 0)
    bpy.context.scene.camera = cam
    for name, e, r in (("key", 3.6, (48, 0, 38)), ("fill", 0.6, (70, 0, -30)), ("rim", 1.6, (55, 0, -120))):
        d = bpy.data.lights.new(name, "SUN")
        d.energy = e
        d.use_shadow = False  # sombra projetada vira serrilhado; o toon + profundidade dão o volume
        o = bpy.data.objects.new(name, d)
        bpy.context.collection.objects.link(o)
        o.rotation_euler = tuple(math.radians(a) for a in r)


# ---------------------------------------------------------------------------- poses e animações
GUARD = {
    "hips_z": 0.89, "hips_x": 0.0, "torso": 8, "head": -8,
    "upper_arm_L": -37, "forearm_L": -122, "upper_arm_R": -31, "forearm_R": -127,
    "thigh_L": -27, "shin_L": 30, "thigh_R": 12, "shin_R": 11,
}


def pose(base, **changes):
    p = dict(base)
    p.update(changes)
    return p


def strike_anim(sid, *poses_at):
    s, a, r = strike_phases(sid)
    keys = [(0, GUARD)]
    for frac, p in poses_at:
        keys.append((max(1, int(round(s * frac))), p))
    keys.append((s + a, keys[-1][1]))
    keys.append((s + a + r, GUARD))
    return keys


def animations():
    A = {}
    A["guard"] = [(0, GUARD), (15, pose(GUARD, hips_z=0.875, torso=10, head=-6)), (30, GUARD)]
    step_a = pose(GUARD, hips_x=0.08, thigh_L=-34, shin_L=22, thigh_R=20, shin_R=22)
    step_b = pose(GUARD, hips_x=0.16, thigh_L=-20, shin_L=34, thigh_R=6, shin_R=14)
    A["walk"] = [(0, GUARD), (8, step_a), (16, step_b), (24, pose(GUARD, hips_x=0.2))]
    A["jab"] = strike_anim("jab", (1.0, pose(GUARD, torso=12, upper_arm_L=-88, forearm_L=-6, head=-12)))
    A["cross"] = strike_anim("cross", (0.5, pose(GUARD, torso=14, upper_arm_R=-50, forearm_R=-90)),
                             (1.0, pose(GUARD, hips_x=0.06, torso=22, upper_arm_R=-92, forearm_R=-4, upper_arm_L=-30, forearm_L=-130, thigh_R=24, shin_R=4)))
    A["lead_hook"] = strike_anim("lead_hook", (1.0, pose(GUARD, torso=20, head=-10, upper_arm_L=-80, forearm_L=-78)))
    A["uppercut"] = strike_anim("uppercut", (0.5, pose(GUARD, hips_z=0.84, torso=14, upper_arm_R=-10, forearm_R=-140)),
                                (1.0, pose(GUARD, hips_z=0.9, torso=0, head=-14, upper_arm_R=-60, forearm_R=-115)))
    A["low_kick"] = strike_anim("low_kick", (0.5, pose(GUARD, torso=-6, thigh_R=-30, shin_R=60)),
                                (1.0, pose(GUARD, torso=-18, thigh_R=-62, shin_R=12, upper_arm_R=10, forearm_R=-110, thigh_L=-12, shin_L=14)))
    A["body_kick"] = strike_anim("body_kick", (0.5, pose(GUARD, torso=-8, thigh_R=-45, shin_R=75)),
                                 (1.0, pose(GUARD, torso=-28, thigh_R=-88, shin_R=20, upper_arm_R=15, forearm_R=-100, thigh_L=-8, shin_L=10)))
    A["high_kick"] = strike_anim("high_kick", (0.5, pose(GUARD, torso=-15, thigh_R=-70, shin_R=90, upper_arm_R=20, forearm_R=-90)),
                                 (1.0, pose(GUARD, torso=-38, head=20, thigh_R=-125, shin_R=8, upper_arm_R=30, forearm_R=-60, thigh_L=-5, shin_L=8)))
    A["teep"] = strike_anim("teep", (0.5, pose(GUARD, torso=-8, thigh_L=-75, shin_L=95)),
                            (1.0, pose(GUARD, torso=-20, hips_x=-0.05, thigh_L=-88, shin_L=8, thigh_R=8, shin_R=6)))
    A["calf_kick"] = strike_anim("calf_kick", (1.0, pose(GUARD, torso=-10, thigh_L=-30, shin_L=35)))
    s = grapple_startup("double_leg")
    level = pose(GUARD, hips_z=0.68, torso=40, thigh_L=-55, shin_L=75, thigh_R=30, shin_R=40, head=-30)
    shoot = pose(GUARD, hips_x=0.45, hips_z=0.55, torso=62, head=-40, thigh_L=-80, shin_L=95, thigh_R=55, shin_R=10,
                 upper_arm_L=-80, forearm_L=-20, upper_arm_R=-75, forearm_R=-25)
    A["double_leg"] = [(0, GUARD), (s // 2, level), (s, shoot), (s + 8, shoot)]
    slip = pose(GUARD, hips_z=0.85, torso=20, head=-18, thigh_L=-32, shin_L=36)
    duck = pose(GUARD, hips_z=0.72, torso=36, head=-20, thigh_L=-55, shin_L=75, thigh_R=38, shin_R=60)
    pull = pose(GUARD, hips_x=-0.08, torso=-24, head=12, thigh_R=22, shin_R=20)
    for name, p in (("slip", slip), ("duck", duck), ("pull", pull)):
        A[name] = [(0, GUARD), (4, p), (10, p), (14, GUARD)]
    down = pose(GUARD, hips_z=0.16, hips_x=-0.3, torso=-88, head=10, upper_arm_L=-150, forearm_L=-20,
                upper_arm_R=-160, forearm_R=-15, thigh_L=-82, shin_L=10, thigh_R=-70, shin_R=30)
    A["down"] = [(0, down), (4, down)]
    A["hit_head"] = [(0, GUARD), (4, pose(GUARD, torso=-12, head=24, hips_x=-0.05)), (16, GUARD)]
    clinch = pose(GUARD, torso=22, head=-16, upper_arm_L=-98, forearm_L=-38, upper_arm_R=-86, forearm_R=-48, thigh_L=-26, shin_L=24)
    A["clinch"] = [(0, clinch), (12, pose(clinch, hips_z=0.875, torso=25)), (24, clinch)]
    top = pose(GUARD, hips_z=0.5, torso=42, head=-26, upper_arm_L=-72, forearm_L=-36, upper_arm_R=-52, forearm_R=-62,
               thigh_L=-12, shin_L=96, thigh_R=4, shin_R=92)
    A["ground_top"] = [(0, top), (12, pose(top, torso=46, upper_arm_R=-60)), (24, top)]
    bottom = pose(GUARD, hips_z=0.14, hips_x=0.15, torso=-86, head=14, upper_arm_L=-45, forearm_L=-105, upper_arm_R=-25,
                  forearm_R=-125, thigh_L=-112, shin_L=78, thigh_R=-100, shin_R=88)
    A["ground_bottom"] = [(0, bottom), (12, pose(bottom, thigh_L=-118, thigh_R=-106)), (24, bottom)]
    return A


def pose_at(keys, f):
    """Interpolação suave (smoothstep) entre as chaves; ângulos e posição do quadril."""
    for (f0, p0), (f1, p1) in zip(keys, keys[1:]):
        if f0 <= f <= f1:
            t = 0.0 if f1 == f0 else (f - f0) / (f1 - f0)
            t = t * t * (3 - 2 * t)
            return {k: p0[k] + (p1[k] - p0[k]) * t for k in p0}
    return dict(keys[-1][1])


# ---------------------------------------------------------------------------- camadas, render, pós-processo
def configure_layer(layer):
    """layer: ("body",) | ("hair", n) | ("beard", n). Na camada de cabelo/barba o corpo vira holdout (oclusão)."""
    for o in bpy.data.objects:
        if o.type != "MESH":
            continue
        name = o.name
        hair = re.match(r"hair(\d)_", name)
        beard = re.match(r"beard(\d)_", name)
        if layer[0] == "body":
            visible = not (hair or beard)
        elif layer[0] == "hair":
            visible = bool(hair) and int(hair.group(1)) == layer[1]
        else:
            visible = bool(beard) and int(beard.group(1)) == layer[1]
        overlay = bool(hair or beard)
        o.hide_render = overlay and not visible
        o.is_holdout = (not visible) and (not overlay)


def render_png(scene, path):
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    img = bpy.data.images.load(path)
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
    bpy.data.images.remove(img)
    return px


class Quantizer:
    def __init__(self, mats):
        cols, ramp_of, tone_of = [], [], []
        for ri, m in enumerate(mats):
            for ti, c in enumerate(PALETTE[m]):
                cols.append(c)
                ramp_of.append(ri)
                tone_of.append(ti)
        self.colors = np.array(cols, dtype=np.float32)
        self.ramp_of = np.array(ramp_of)
        self.tone_of = np.array(tone_of)
        self.ramp_len = np.array([len(PALETTE[m]) for m in mats])
        # índice do tom (ramp, tom) -> índice global
        self.index = {(r, t): i for i, (r, t) in enumerate(zip(ramp_of, tone_of))}

    def __call__(self, px, depth=None):
        a = px[:, :, 3] > 0.5
        h, w = a.shape
        idx = np.full((h, w), -1, dtype=np.int32)
        flat = px[:, :, :3][a]
        if flat.size:
            d = ((flat[:, None, :] - self.colors[None, :, :]) ** 2).sum(axis=2)
            idx[a] = d.argmin(axis=1)
        inner = np.zeros_like(a)
        if depth is not None and a.any():
            dv = depth[:, :, 0] * DEPTH_RANGE + DEPTH_NEAR  # PNG de 16 bits volta linear ao carregar
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                inner |= a & np.roll(a, (dy, dx), (0, 1)) & (dv - np.roll(dv, (dy, dx), (0, 1)) > INNER_EDGE_M)
            offs = ((2, 0), (-2, 0), (0, 2), (0, -2), (2, 2), (-2, -2), (2, -2), (-2, 2))
            smooth = a.copy()
            acc = np.zeros_like(dv)
            for dy, dx in offs:
                nd = np.roll(dv, (dy, dx), (0, 1))
                smooth &= np.roll(a, (dy, dx), (0, 1)) & (np.abs(nd - dv) < INNER_EDGE_M)
                acc += nd
            lap = dv - acc / len(offs)
            sel = smooth & (np.abs(lap) >= CAVITY_M) & (idx >= 0)
            r = self.ramp_of[idx[sel]]
            t = self.tone_of[idx[sel]] + np.where(lap[sel] > 0, -1, 1)  # vale desce 1 tom, crista sobe 1
            t = np.clip(t, 0, self.ramp_len[r] - 1)
            lut = np.full((len(self.ramp_len), int(self.ramp_len.max())), 0, dtype=np.int32)
            for (rr, tt), gi in self.index.items():
                lut[rr, tt] = gi
            idx[sel] = lut[r, t]
        idx = despeckle(idx, a)
        out = np.zeros((h, w, 4), dtype=np.float32)
        out[a, :3] = self.colors[idx[a]]
        out[:, :, 3] = a
        out[inner, :3] = INNER
        nb = np.zeros_like(a)
        nb[1:, :] |= a[:-1, :]
        nb[:-1, :] |= a[1:, :]
        nb[:, 1:] |= a[:, :-1]
        nb[:, :-1] |= a[:, 1:]
        edge = nb & ~a
        out[edge, :3] = OUTLINE
        out[edge, 3] = 1.0
        return out


def despeckle(idx, a, passes=2):
    """Pixel sem nenhum vizinho (4) de mesma cor assume a cor do primeiro vizinho válido (vetorizado)."""
    for _ in range(passes):
        nbs = [(np.roll(idx, s, (0, 1)), np.roll(a, s, (0, 1))) for s in ((1, 0), (-1, 0), (0, 1), (0, -1))]
        same = np.zeros_like(a)
        for n, na in nbs:
            same |= na & (n == idx)
        iso = a & ~same
        repl = idx.copy()
        done = np.zeros_like(a)
        for n, na in nbs:
            take = iso & na & ~done
            repl[take] = n[take]
            done |= take
        idx = repl
    return idx


def save_png(px, path):
    h, w = px.shape[:2]
    img = bpy.data.images.new("out", width=w, height=h, alpha=True)
    img.pixels = px.ravel().tolist()
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()
    bpy.data.images.remove(img)


def render_biotype(bt_name):
    global BT
    BT = BIOTYPES[bt_name]
    female = BT["female"]
    # Ensaio: JAULA_OUT muda a pasta de saída e JAULA_ANIMS=guard,jab limita as animações.
    out_dir = os.path.join(os.environ.get("JAULA_OUT") or os.path.join(ROOT, "assets", "sprites", "fighters"), bt_name)
    only = [a for a in os.environ.get("JAULA_ANIMS", "").split(",") if a]
    scene = reset_scene()
    mats = {k: toon_material(k, v) for k, v in PALETTE.items()}
    depth_mat = depth_material()
    bpy.ops.object.empty_add(location=(0, 0, 0))
    root = bpy.context.active_object
    root.rotation_euler = (0, 0, math.radians(TURN_DEG))
    root.scale = (BT["scale"],) * 3
    setup_camera_and_lights()
    bd = Builder(mats, root)
    os.makedirs(out_dir, exist_ok=True)
    os.makedirs(TMP_DIR, exist_ok=True)
    for f in os.listdir(out_dir):
        if f.endswith(".png"):
            os.remove(os.path.join(out_dir, f))
    q_body = Quantizer(LAYER_MATERIALS["body"])
    q_hair = Quantizer(LAYER_MATERIALS["hair"])
    beards = [] if female else list(BEARDS)
    meta = {"frame_size": [FRAME_W, FRAME_H], "sim_frames_per_sprite": SIM_FRAMES_PER_SPRITE,
            "anchor": [round(FRAME_W / 2 - CAM_X_OFFSET * PX_PER_M), round(FRAME_H / 2 + CAM_Z * PX_PER_M)],
            "px_per_m": PX_PER_M, "far_darken": 1.0, "builds": len(BUILDS), "default_build": DEFAULT_BUILD,
            "hair_styles": list(HAIR_STYLES), "beards": beards, "beard": bool(beards),
            "palette": {k: [list(c) for c in v] for k, v in PALETTE.items()}, "animations": {}}
    tmp = os.path.join(TMP_DIR, "frame.png")
    metrics = {}
    for name, keys in animations().items():
        if only and name not in only:
            continue
        ta = time.time()
        last = keys[-1][0]
        frames = list(range(0, last + 1, SIM_FRAMES_PER_SPRITE))
        sheets = {}

        def put(key, k, px):
            if key not in sheets:
                sheets[key] = np.zeros((FRAME_H, FRAME_W * len(frames), 4), dtype=np.float32)
            sheets[key][:, k * FRAME_W:(k + 1) * FRAME_W] = px

        for k, f in enumerate(frames):
            p = pose_at(keys, f)
            for build in range(len(BUILDS)):
                bd.clear()
                build_frame(bd, p, build, female)
                configure_layer(("body",))
                scene.render.image_settings.color_depth = "8"
                color = render_png(scene, tmp)
                bpy.context.view_layer.material_override = depth_mat
                scene.render.image_settings.color_depth = "16"
                depth = render_png(scene, tmp)
                bpy.context.view_layer.material_override = None
                scene.render.image_settings.color_depth = "8"
                put("" if build == DEFAULT_BUILD else "__b%d" % build, k, q_body(color, depth))
                if build != DEFAULT_BUILD:
                    continue
                for hs in HAIR_STYLES:
                    configure_layer(("hair", hs))
                    put("__hair%d" % hs, k, q_hair(render_png(scene, tmp)))
                for bs in beards:
                    configure_layer(("beard", bs))
                    put("__beard%d" % bs, k, q_hair(render_png(scene, tmp)))
        for suffix, sheet in sheets.items():
            save_png(sheet, os.path.join(out_dir, name + suffix + ".png"))
        meta["animations"][name] = {"frames": len(frames), "sim_frames": last}
        metrics[name] = {"sprite_frames": len(frames), "seconds": round(time.time() - ta, 1)}
        print("ANIM", bt_name, name, metrics[name], flush=True)
    bd.clear()
    with open(os.path.join(out_dir, bt_name + ".json"), "w", encoding="utf-8", newline="\n") as fh:
        json.dump(meta, fh, indent=2)
    return metrics


def main():
    t0 = time.time()
    wanted = ARGS[1:] or list(BIOTYPES)
    all_metrics = {bt: render_biotype(bt) for bt in wanted}
    total = round(time.time() - t0, 1)
    with open(os.path.join(ROOT, "tools", "art_pipeline", "last_metrics.json"), "w", encoding="utf-8", newline="\n") as fh:
        json.dump({"total_seconds": total, "version": 3, "biotypes": all_metrics, "blender": bpy.app.version_string}, fh, indent=2)
    print("PIPELINE_OK total=%ss" % total, flush=True)


main()
