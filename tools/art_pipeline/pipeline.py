"""Pipeline 3D -> pixel art em CAMADAS (E-06 v2, D-017, criador de visual).

Uso (headless):
  blender -b --factory-startup --python tools/art_pipeline/pipeline.py -- <raiz_do_projeto>

O que faz:
  1. Gera por script um manequim humanoide de segmentos rígidos (sem assets de terceiros): tronco anatômico,
     rosto (olho, sobrancelha, nariz, orelha), luvas com fita e polegar, calção com cós e faixa lateral.
  2. Anima as ações com tempos lidos dos dados do jogo (data/strikes, data/grappling): a arte acompanha a regra.
  3. Renderiza em câmera ortográfica lateral, toon de 4 tons + luz de contorno, sem antisserrilhado, em CAMADAS:
       corpo · cabelo (estilos 1..3) · barba   (as outras camadas viram holdout: oclusão correta)
  4. Quantiza CADA camada só com as rampas dos seus materiais (sem manchas entre materiais), contorno de 1 px,
     spritesheets PNG + JSON com a paleta de origem — o jogo troca as cores em tempo real (criador de visual).
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
OUT_DIR = ""  # definido por biótipo em main()
TMP_DIR = os.path.join(ROOT, "art_source", "render_tmp")

SIM_FPS = 60
SIM_FRAMES_PER_SPRITE = 3  # 20 fps de sprite
FIGHTER_HEIGHT_M = 1.80
TARGET_HEIGHT_PX = 136  # ART §3 [PROV]
FRAME_W, FRAME_H = 224, 160
PX_PER_M = TARGET_HEIGHT_PX / FIGHTER_HEIGHT_M
CAM_X_OFFSET = 0.45
CAM_Z = 0.95
FAR_SIDE_DARKEN = 0.72

# Paleta de ORIGEM (4 tons por material). O jogo recolore skin/hair/shorts/stripe/glove por shader.
PALETTE = {
    "skin": [(0.40, 0.22, 0.14), (0.62, 0.38, 0.25), (0.80, 0.55, 0.39), (0.94, 0.74, 0.58)],
    "hair": [(0.10, 0.06, 0.03), (0.22, 0.13, 0.07), (0.36, 0.22, 0.12), (0.52, 0.34, 0.20)],
    "shorts": [(0.05, 0.07, 0.30), (0.10, 0.16, 0.55), (0.16, 0.28, 0.80), (0.32, 0.48, 0.98)],
    "stripe": [(0.55, 0.55, 0.50), (0.75, 0.75, 0.70), (0.90, 0.90, 0.86), (1.00, 1.00, 0.97)],
    "glove": [(0.32, 0.03, 0.04), (0.58, 0.06, 0.07), (0.82, 0.13, 0.12), (1.00, 0.38, 0.30)],
    "tape": [(0.45, 0.62, 0.60), (0.60, 0.78, 0.76), (0.76, 0.90, 0.88), (0.90, 0.99, 0.97)],
    "eye": [(0.04, 0.03, 0.04), (0.06, 0.05, 0.06), (0.08, 0.07, 0.08), (0.10, 0.09, 0.10)],
}
LAYER_MATERIALS = {
    "body": ["skin", "shorts", "stripe", "glove", "tape", "eye", "hair"],  # sobrancelha usa "hair"
    "hair": ["hair"],
    "beard": ["hair"],
}
OUTLINE = (0.10, 0.06, 0.07)
HAIR_STYLES = [1, 2, 3]  # 0 = careca (sem camada)
# Biótipos renderizados. A escala é uniforme sobre o boneco inteiro (px por metro constante = tamanho físico real);
# as proporções mudam ombro, peito e quadril. O top esportivo usa o material do calção (mesma cor no criador).
BIOTYPES = {
    "m_medium": {"scale": 1.0, "shoulder": 0.19, "chest": (0.8, 1.15, 0.9), "pec": True, "top": False, "pelvis": (0.95, 1.25, 0.85)},
    "f_medium": {"scale": 0.935, "shoulder": 0.165, "chest": (0.76, 1.0, 0.84), "pec": False, "top": True, "pelvis": (0.98, 1.36, 0.88)},
}
BODY = BIOTYPES["m_medium"]


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
    v = read_tres(os.path.join(ROOT, "data", "grappling", tech_id + ".tres"))
    return int(v["startup_frames"])


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = FRAME_W
    scene.render.resolution_y = FRAME_H
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.filter_size = 0.0
    scene.render.fps = SIM_FPS
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    if hasattr(scene, "eevee") and hasattr(scene.eevee, "taa_render_samples"):
        scene.eevee.taa_render_samples = 1
    scene.view_settings.view_transform = "Standard"
    return scene


def toon_material(name, ramp, darken=1.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    emit = nodes.new("ShaderNodeEmission")
    diffuse = nodes.new("ShaderNodeBsdfDiffuse")
    to_rgb = nodes.new("ShaderNodeShaderToRGB")
    cramp = nodes.new("ShaderNodeValToRGB")
    cramp.color_ramp.interpolation = "CONSTANT"
    els = cramp.color_ramp.elements
    while len(els) < 4:
        els.new(0.5)
    for el, pos, col in zip(els, [0.0, 0.16, 0.42, 0.78], ramp):
        el.position = pos
        el.color = (col[0] * darken, col[1] * darken, col[2] * darken, 1.0)
    links.new(diffuse.outputs["BSDF"], to_rgb.inputs["Shader"])
    links.new(to_rgb.outputs["Color"], cramp.inputs["Fac"])
    links.new(cramp.outputs["Color"], emit.inputs["Color"])
    links.new(emit.outputs["Emission"], out.inputs["Surface"])
    return mat


def segment(name, parent, joint, length, radius_top, radius_bottom, material, up=False, offset=(0, 0, 0)):
    bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=radius_bottom if not up else radius_top,
                                    radius2=radius_top if not up else radius_bottom, depth=length)
    obj = bpy.context.active_object
    obj.name = name
    obj.data.materials.append(material)
    shift = length / 2.0 if up else -length / 2.0
    for v in obj.data.vertices:
        v.co.z += shift
        v.co.x += offset[0]
        v.co.y += offset[1]
    bpy.ops.object.shade_smooth()
    if parent is not None:
        obj.parent = parent
    obj.location = joint
    obj.rotation_mode = "XYZ"
    return obj


def ball(name, parent, location, radius, material, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=18, ring_count=10, radius=radius)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    obj.parent = parent
    obj.location = location
    return obj


def build_mannequin():
    """~7 cabeças (ART §5.1). Base ortodoxa: lado esquerdo (longe) à frente.
    Objetos de cabelo têm prefixo hair<N>_ e barba beard_ (camadas separadas)."""
    m = {k: toon_material(k, v) for k, v in PALETTE.items()}
    far = {k: toon_material(k + "_far", v, FAR_SIDE_DARKEN) for k, v in PALETTE.items()}
    hh = FIGHTER_HEIGHT_M / 7.0
    parts = {}
    bpy.ops.object.empty_add(location=(0, 0, 0.98))
    hips = bpy.context.active_object
    hips.name = "hips"
    hips.rotation_mode = "XYZ"
    parts["hips"] = hips
    hips.scale = (BODY["scale"],) * 3
    ball("pelvis", hips, (0, 0, -0.03), 0.16, m["shorts"], BODY["pelvis"])
    ball("waistband", hips, (0, 0, 0.065), 0.152, m["stripe"], (0.96, 1.21, 0.22))
    torso = segment("torso", hips, (0, 0, 0.05), 0.24, 0.15, 0.14, m["skin"], up=True)
    parts["torso"] = torso
    ball("abdomen", torso, (0.012, 0, 0.14), 0.15, m["skin"], (0.85, 1.05, 1.0))
    ball("chest", torso, (0.02, 0, 0.36), 0.19, m["skin"], BODY["chest"])
    if BODY["pec"]:
        ball("pec", torso, (0.075, 0, 0.36), 0.12, m["skin"], (0.7, 1.4, 0.72))
    if BODY["top"]:
        ball("top", torso, (0.03, 0, 0.34), 0.18, m["shorts"], (0.92, 1.12, 0.58))
        ball("top_band", torso, (0.03, 0, 0.26), 0.172, m["stripe"], (0.9, 1.1, 0.1))
    ball("trap", torso, (-0.02, 0, 0.45), 0.1, m["skin"], (0.9, 1.5, 0.6))
    neck = segment("neck", torso, (0, 0, 0.47), 0.08, 0.055, 0.068, m["skin"], up=True)
    head = segment("head", neck, (0, 0, 0.06), 0.04, 0.05, 0.055, m["skin"], up=True)
    parts["head"] = head
    ball("skull", head, (0.015, 0, hh * 0.5), hh * 0.47, m["skin"], (0.92, 0.85, 1.08))
    ball("jaw", head, (0.05, 0, hh * 0.27), hh * 0.3, m["skin"], (0.9, 0.8, 0.72))
    ball("nose", head, (0.11, 0, hh * 0.45), 0.018, m["skin"], (1.3, 0.8, 1.2))
    ball("ear", head, (-0.005, -0.085, hh * 0.48), 0.026, m["skin"], (0.6, 0.6, 1.0))
    ball("eye", head, (0.085, -0.04, hh * 0.53), 0.012, m["eye"], (0.7, 1.0, 1.0))
    ball("brow", head, (0.09, -0.035, hh * 0.6), 0.014, m["hair"], (0.9, 1.6, 0.45))
    ball("hair1_cap", head, (-0.02, 0, hh * 0.7), hh * 0.45, m["hair"], (1.0, 0.95, 0.66))
    ball("hair2_strip", head, (-0.005, 0, hh * 0.86), hh * 0.36, m["hair"], (1.1, 0.32, 0.55))
    ball("hair3_cap", head, (-0.025, 0, hh * 0.68), hh * 0.47, m["hair"], (1.02, 0.97, 0.7))
    ball("hair3_bun", head, (-0.11, 0, hh * 0.8), 0.055, m["hair"])
    ball("beard_jaw", head, (0.05, 0, hh * 0.24), hh * 0.31, m["hair"], (0.95, 0.88, 0.62))
    sh_y = BODY["shoulder"]
    for side, y, mats in (("L", sh_y, far), ("R", -sh_y, m)):
        ball("shoulder_" + side, torso, (0, y, 0.42), 0.078, mats["skin"], (1.0, 0.9, 0.95))
        ua = segment("upper_arm_" + side, torso, (0, y, 0.42), 0.28, 0.062, 0.048, mats["skin"])
        ball("bicep_" + side, ua, (0.02, 0, -0.12), 0.05, mats["skin"], (1.0, 1.0, 1.7))
        ball("elbow_" + side, ua, (0, 0, -0.28), 0.046, mats["skin"])
        fa = segment("forearm_" + side, ua, (0, 0, -0.28), 0.24, 0.05, 0.042, mats["skin"])
        ball("wrap_" + side, fa, (0, 0, -0.23), 0.05, mats["tape"], (1.0, 1.0, 0.8))
        ball("glove_" + side, fa, (0.012, 0, -0.29), 0.07, mats["glove"], (1.2, 1.0, 1.05))
        ball("thumb_" + side, fa, (0.05, 0, -0.26), 0.028, mats["glove"])
        ball("hip_" + side, hips, (0, y * 0.55, -0.06), 0.088, mats["shorts"])
        th = segment("thigh_" + side, hips, (0, y * 0.55, -0.06), 0.44, 0.088, 0.062, mats["shorts"])
        ball("sidestripe_" + side, th, (0, -0.075 if side == "R" else 0.075, -0.12), 0.028, mats["stripe"], (0.6, 0.4, 3.2))
        ball("knee_" + side, th, (0, 0, -0.44), 0.058, mats["skin"])
        sh = segment("shin_" + side, th, (0, 0, -0.44), 0.42, 0.06, 0.042, mats["skin"])
        ball("calf_" + side, sh, (-0.018, 0, -0.14), 0.062, mats["skin"], (1.0, 1.0, 1.6))
        ball("ankle_" + side, sh, (0, 0, -0.42), 0.04, mats["skin"])
        foot = segment("foot_" + side, sh, (0, 0, -0.43), 0.045, 0.035, 0.045, mats["skin"], offset=(0.065, 0, 0))
        ball("toe_" + side, foot, (0.11, 0, -0.035), 0.035, mats["skin"], (1.4, 1.0, 0.7))
        parts.update({"upper_arm_" + side: ua, "forearm_" + side: fa, "thigh_" + side: th, "shin_" + side: sh})
    return parts


def setup_camera_and_lights():
    cam_data = bpy.data.cameras.new("cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = FRAME_W / PX_PER_M
    cam = bpy.data.objects.new("cam", cam_data)
    bpy.context.collection.objects.link(cam)
    cam.location = (CAM_X_OFFSET, -6.0, CAM_Z)
    cam.rotation_euler = (math.radians(90), 0, 0)
    bpy.context.scene.camera = cam
    for name, energy, rot in (("key", 3.0, (35, -25, 20)), ("rim", 1.6, (-20, 40, 160))):
        data = bpy.data.lights.new(name, "SUN")
        data.energy = energy
        obj = bpy.data.objects.new(name, data)
        bpy.context.collection.objects.link(obj)
        obj.rotation_euler = tuple(math.radians(a) for a in rot)


GUARD = {
    "hips_z": 0.95, "hips_x": 0.0, "torso": 8, "head": -8,
    "upper_arm_L": -45, "forearm_L": -105, "upper_arm_R": -25, "forearm_R": -125,
    "thigh_L": -22, "shin_L": 18, "thigh_R": 16, "shin_R": 16,
}


def pose(base, **changes):
    p = dict(base)
    p.update(changes)
    return p


def apply_pose(parts, p, frame):
    hips = parts["hips"]
    hips.location = (p["hips_x"] * BODY["scale"], 0, p["hips_z"] * BODY["scale"])
    hips.keyframe_insert("location", frame=frame)
    for key, val in p.items():
        if key in ("hips_z", "hips_x"):
            continue
        obj = parts[key]
        obj.rotation_euler = (0, math.radians(val), 0)
        obj.keyframe_insert("rotation_euler", frame=frame)


def strike_anim(sid, *poses_at):
    s, a, r = strike_phases(sid)
    keys = [(0, GUARD)]
    for frac, p in poses_at:
        keys.append((max(1, int(round(s * frac))), p))
    keys.append((s + a, keys[-1][1]))
    keys.append((s + a + r, GUARD))
    return keys


def animations():
    anims = {}
    anims["guard"] = [(0, GUARD), (15, pose(GUARD, hips_z=0.94, torso=10, head=-6)), (30, GUARD)]
    step_a = pose(GUARD, hips_x=0.08, thigh_L=-30, shin_L=10, thigh_R=22, shin_R=26)
    step_b = pose(GUARD, hips_x=0.16, thigh_L=-16, shin_L=24, thigh_R=8, shin_R=10)
    anims["walk"] = [(0, GUARD), (8, step_a), (16, step_b), (24, pose(GUARD, hips_x=0.2))]
    anims["jab"] = strike_anim("jab", (1.0, pose(GUARD, torso=12, upper_arm_L=-90, forearm_L=-4, head=-12)))
    anims["cross"] = strike_anim("cross", (0.5, pose(GUARD, torso=14, upper_arm_R=-50, forearm_R=-90)),
                                 (1.0, pose(GUARD, hips_x=0.06, torso=22, upper_arm_R=-92, forearm_R=-4, upper_arm_L=-30, forearm_L=-130, thigh_R=24, shin_R=8)))
    anims["lead_hook"] = strike_anim("lead_hook", (1.0, pose(GUARD, torso=20, head=-10, upper_arm_L=-78, forearm_L=-80)))
    anims["uppercut"] = strike_anim("uppercut", (0.5, pose(GUARD, hips_z=0.9, torso=14, upper_arm_R=-10, forearm_R=-140)),
                                    (1.0, pose(GUARD, hips_z=0.97, torso=0, head=-14, upper_arm_R=-60, forearm_R=-115)))
    anims["low_kick"] = strike_anim("low_kick", (0.5, pose(GUARD, torso=-6, thigh_R=-30, shin_R=60)),
                                    (1.0, pose(GUARD, torso=-18, thigh_R=-62, shin_R=12, upper_arm_R=10, forearm_R=-110)))
    anims["body_kick"] = strike_anim("body_kick", (0.5, pose(GUARD, torso=-8, thigh_R=-45, shin_R=75)),
                                     (1.0, pose(GUARD, torso=-28, thigh_R=-88, shin_R=20, upper_arm_R=15, forearm_R=-100)))
    anims["high_kick"] = strike_anim("high_kick", (0.5, pose(GUARD, torso=-15, thigh_R=-70, shin_R=90, upper_arm_R=20, forearm_R=-90)),
                                     (1.0, pose(GUARD, torso=-38, head=20, thigh_R=-125, shin_R=8, upper_arm_R=30, forearm_R=-60, thigh_L=-5, shin_L=8)))
    anims["teep"] = strike_anim("teep", (0.5, pose(GUARD, torso=-8, thigh_L=-75, shin_L=95)),
                                (1.0, pose(GUARD, torso=-20, hips_x=-0.05, thigh_L=-88, shin_L=8)))
    anims["calf_kick"] = strike_anim("calf_kick", (1.0, pose(GUARD, torso=-10, thigh_L=-30, shin_L=35)))
    s = grapple_startup("double_leg")
    level = pose(GUARD, hips_z=0.72, torso=40, thigh_L=-55, shin_L=75, thigh_R=30, shin_R=40, head=-30)
    shoot = pose(GUARD, hips_x=0.45, hips_z=0.58, torso=62, head=-40, thigh_L=-80, shin_L=95, thigh_R=55, shin_R=10,
                 upper_arm_L=-80, forearm_L=-20, upper_arm_R=-75, forearm_R=-25)
    anims["double_leg"] = [(0, GUARD), (s // 2, level), (s, shoot), (s + 8, shoot)]
    slip = pose(GUARD, hips_z=0.9, torso=20, head=-18, thigh_L=-28, shin_L=26)
    duck = pose(GUARD, hips_z=0.76, torso=36, head=-20, thigh_L=-55, shin_L=75, thigh_R=38, shin_R=60)
    pull = pose(GUARD, hips_x=-0.08, torso=-24, head=12, thigh_R=24, shin_R=22)
    for name, p in (("slip", slip), ("duck", duck), ("pull", pull)):
        anims[name] = [(0, GUARD), (4, p), (10, p), (14, GUARD)]
    down = pose(GUARD, hips_z=0.16, hips_x=-0.3, torso=-88, head=10, upper_arm_L=-150, forearm_L=-20,
                upper_arm_R=-160, forearm_R=-15, thigh_L=-82, shin_L=10, thigh_R=-70, shin_R=30)
    anims["down"] = [(0, down), (4, down)]
    anims["hit_head"] = [(0, GUARD), (4, pose(GUARD, torso=-12, head=24, hips_x=-0.05)), (16, GUARD)]
    # Grappling (posições do par): clinch em pé, por cima ajoelhado, por baixo na guarda.
    clinch = pose(GUARD, torso=22, head=-16, upper_arm_L=-98, forearm_L=-38, upper_arm_R=-86, forearm_R=-48, thigh_L=-26, shin_L=24)
    anims["clinch"] = [(0, clinch), (12, pose(clinch, hips_z=0.94, torso=25)), (24, clinch)]
    top = pose(GUARD, hips_z=0.5, torso=42, head=-26, upper_arm_L=-72, forearm_L=-36, upper_arm_R=-52, forearm_R=-62,
               thigh_L=-12, shin_L=96, thigh_R=4, shin_R=92)
    anims["ground_top"] = [(0, top), (12, pose(top, torso=46, upper_arm_R=-60)), (24, top)]
    bottom = pose(GUARD, hips_z=0.14, hips_x=0.15, torso=-86, head=14, upper_arm_L=-45, forearm_L=-105, upper_arm_R=-25,
                  forearm_R=-125, thigh_L=-112, shin_L=78, thigh_R=-100, shin_R=88)
    anims["ground_bottom"] = [(0, bottom), (12, pose(bottom, thigh_L=-118, thigh_R=-106)), (24, bottom)]
    return anims


def configure_layer(layer):
    """Mostra a camada pedida; o corpo vira holdout nas camadas de cabelo/barba (oclusão correta)."""
    for obj in bpy.data.objects:
        if obj.type != "MESH":
            continue
        is_hair = obj.name.startswith("hair")
        is_beard = obj.name.startswith("beard")
        if layer == "body":
            visible = not (is_hair or is_beard)
        elif layer == "beard":
            visible = is_beard
        else:
            visible = obj.name.startswith("hair%d_" % layer)
        other_overlay = (is_hair or is_beard) and not visible
        obj.hide_render = other_overlay
        obj.is_holdout = (not visible) and (not other_overlay)


def ramps_for(layer_key):
    cols = []
    for mat in LAYER_MATERIALS[layer_key]:
        for c in PALETTE[mat]:
            cols.append(c)
            cols.append(tuple(v * FAR_SIDE_DARKEN for v in c))
    return np.array(cols, dtype=np.float32)


def load_rgba(path):
    img = bpy.data.images.load(path)
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
    bpy.data.images.remove(img)
    return px


def postprocess(px, colors):
    alpha = px[:, :, 3] > 0.5
    rgb = px[:, :, :3].copy()
    flat = rgb[alpha]
    if flat.size:
        # O render sai codificado em sRGB; a paleta está em valores lineares. Compara no mesmo espaço (sRGB)
        # e grava a cor da paleta original (é ela que o shader do jogo procura).
        enc = np.where(colors <= 0.0031308, colors * 12.92, 1.055 * np.power(colors, 1.0 / 2.4) - 0.055)
        d = ((flat[:, None, :] - enc[None, :, :]) ** 2).sum(axis=2)
        rgb[alpha] = colors[d.argmin(axis=1)]
    out = np.zeros_like(px)
    out[:, :, :3] = rgb
    out[:, :, 3] = alpha.astype(np.float32)
    neighbor = np.zeros_like(alpha)
    neighbor[1:, :] |= alpha[:-1, :]
    neighbor[:-1, :] |= alpha[1:, :]
    neighbor[:, 1:] |= alpha[:, :-1]
    neighbor[:, :-1] |= alpha[:, 1:]
    edge = neighbor & ~alpha
    out[edge, :3] = OUTLINE
    out[edge, 3] = 1.0
    return out


def save_png(px, path):
    h, w = px.shape[:2]
    img = bpy.data.images.new("out", width=w, height=h, alpha=True)
    img.pixels = px.ravel().tolist()
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()
    bpy.data.images.remove(img)


def render_layer(scene, keys, name, layer, suffix):
    configure_layer(layer)
    colors = ramps_for("body" if layer == "body" else ("beard" if layer == "beard" else "hair"))
    last = keys[-1][0]
    frames = list(range(0, last + 1, SIM_FRAMES_PER_SPRITE))
    sheet = np.zeros((FRAME_H, FRAME_W * len(frames), 4), dtype=np.float32)
    for k, f in enumerate(frames):
        scene.frame_set(f)
        tmp = os.path.join(TMP_DIR, "%s%s_%03d.png" % (name, suffix, k))
        scene.render.filepath = tmp
        bpy.ops.render.render(write_still=True)
        sheet[:, k * FRAME_W:(k + 1) * FRAME_W] = postprocess(load_rgba(tmp), colors)
    save_png(sheet, os.path.join(OUT_DIR, name + suffix + ".png"))
    return len(frames), last


def main():
    global OUT_DIR, BODY
    t0 = time.time()
    wanted = ARGS[1:] or list(BIOTYPES)
    all_metrics = {}
    for bt in wanted:
        BODY = BIOTYPES[bt]
        OUT_DIR = os.path.join(ROOT, "assets", "sprites", "fighters", bt)
        all_metrics[bt] = render_biotype(bt)
    total = round(time.time() - t0, 1)
    with open(os.path.join(ROOT, "tools", "art_pipeline", "last_metrics.json"), "w", encoding="utf-8", newline="\n") as fh:
        json.dump({"total_seconds": total, "layers": 5, "biotypes": all_metrics, "blender": bpy.app.version_string}, fh, indent=2)
    print("PIPELINE_OK total=%ss" % total)


def render_biotype(bt):
    scene = reset_scene()
    parts = build_mannequin()
    setup_camera_and_lights()
    os.makedirs(OUT_DIR, exist_ok=True)
    os.makedirs(TMP_DIR, exist_ok=True)
    for f in os.listdir(OUT_DIR):
        if f.endswith(".png"):
            os.remove(os.path.join(OUT_DIR, f))
    meta = {"frame_size": [FRAME_W, FRAME_H], "sim_frames_per_sprite": SIM_FRAMES_PER_SPRITE,
            "anchor": [round(FRAME_W / 2 - CAM_X_OFFSET * PX_PER_M), round(FRAME_H / 2 + CAM_Z * PX_PER_M)],
            "px_per_m": PX_PER_M, "far_darken": FAR_SIDE_DARKEN, "hair_styles": HAIR_STYLES, "beard": True,
            "palette": {k: [list(c) for c in v] for k, v in PALETTE.items()}, "animations": {}}
    metrics = {}
    for name, keys in animations().items():
        ta = time.time()
        for obj in parts.values():
            obj.animation_data_clear()
        for frame, p in keys:
            apply_pose(parts, p, frame)
        frames, last = render_layer(scene, keys, name, "body", "")
        for style in HAIR_STYLES:
            render_layer(scene, keys, name, style, "__hair%d" % style)
        render_layer(scene, keys, name, "beard", "__beard")
        meta["animations"][name] = {"frames": frames, "sim_frames": last}
        metrics[name] = {"sprite_frames": frames, "seconds": round(time.time() - ta, 2)}
        print("ANIM", bt, name, metrics[name])
    with open(os.path.join(OUT_DIR, bt + ".json"), "w", encoding="utf-8", newline="\n") as fh:
        json.dump(meta, fh, indent=2)
    return metrics


main()
