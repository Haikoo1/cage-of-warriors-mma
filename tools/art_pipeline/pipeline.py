"""Spike do pipeline 3D -> pixel art (E-06, R-036, ART_DIRECTION §11).

Uso (headless):
  blender -b --factory-startup --python tools/art_pipeline/pipeline.py -- <raiz_do_projeto>

O que faz:
  1. Gera por script um manequim humanoide de segmentos rígidos articulados (sem assets de terceiros).
  2. Anima guarda, andar, jab, direto, chute baixo e double leg. Os tempos vêm dos dados do jogo
     (data/strikes, data/grappling): a animação casa com a regra (ART §6.1), não o contrário.
  3. Renderiza em câmera ortográfica lateral com sombreamento toon de 3 tons, sem antisserrilhado.
  4. Pós-processa: quantiza para a paleta, adiciona contorno de 1 px, monta spritesheets PNG + JSON.
  5. Registra métricas (tempo por animação, quadros) para o marco M2.

Limitação conhecida: segmentos rígidos (sem skinning). Mede o pipeline, não a qualidade final da arte.
"""
import json
import math
import os
import re
import sys
import time

import bpy
import numpy as np

ROOT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.getcwd()
OUT_DIR = os.path.join(ROOT, "assets", "sprites", "fighters", "m_medium")
TMP_DIR = os.path.join(ROOT, "art_source", "render_tmp")

SIM_FPS = 60
SIM_FRAMES_PER_SPRITE = 4  # 15 fps de sprite
FIGHTER_HEIGHT_M = 1.80
TARGET_HEIGHT_PX = 136  # ART §3 [PROV]
FRAME_W, FRAME_H = 224, 160
PX_PER_M = TARGET_HEIGHT_PX / FIGHTER_HEIGHT_M
CAM_X_OFFSET = 0.45  # golpes avançam para +X: câmera deslocada para frente
CAM_Z = 0.95

# Paleta (ART §4): rampas de 3 tons por material + contorno escuro colorido.
PALETTE = {
    "skin": [(0.42, 0.25, 0.17), (0.66, 0.43, 0.30), (0.85, 0.62, 0.46)],
    "shorts": [(0.10, 0.16, 0.36), (0.18, 0.30, 0.62), (0.32, 0.48, 0.85)],
    "glove": [(0.38, 0.06, 0.06), (0.68, 0.12, 0.10), (0.90, 0.30, 0.22)],
    "hair": [(0.07, 0.05, 0.04), (0.14, 0.10, 0.08), (0.24, 0.18, 0.14)],
}
OUTLINE = (0.12, 0.07, 0.08)
FAR_SIDE_DARKEN = 0.72  # membros do lado longe da câmera mais escuros (leitura de profundidade)


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
    v = read_tres(os.path.join(ROOT, "data", "grappling", tech_id + ".tres"))
    return int(v["startup_frames"])


# ---------------------------------------------------------------------------- cena e materiais
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
    """Diffuse -> Shader to RGB -> ColorRamp constante (3 tons) -> Emission. Cores exatas da paleta."""
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
    stops = [0.0, 0.25, 0.6]
    els = cramp.color_ramp.elements
    while len(els) < 3:
        els.new(0.5)
    for el, pos, col in zip(els, stops, ramp):
        el.position = pos
        el.color = (col[0] * darken, col[1] * darken, col[2] * darken, 1.0)
    links.new(diffuse.outputs["BSDF"], to_rgb.inputs["Shader"])
    links.new(to_rgb.outputs["Color"], cramp.inputs["Fac"])
    links.new(cramp.outputs["Color"], emit.inputs["Color"])
    links.new(emit.outputs["Emission"], out.inputs["Surface"])
    return mat


# ---------------------------------------------------------------------------- manequim
def segment(name, parent, joint, length, radius_top, radius_bottom, material, up=False, offset=(0, 0, 0)):
    """Segmento com origem na junta. Por padrão aponta para -Z (membros); up=True aponta para +Z (tronco)."""
    bpy.ops.mesh.primitive_cone_add(vertices=10, radius1=radius_bottom if not up else radius_top,
                                    radius2=radius_top if not up else radius_bottom, depth=length)
    obj = bpy.context.active_object
    obj.name = name
    obj.data.materials.append(material)
    # move a geometria para que a origem fique na junta
    shift = length / 2.0 if up else -length / 2.0
    for v in obj.data.vertices:
        v.co.z += shift
    for v in obj.data.vertices:
        v.co.x += offset[0]
        v.co.y += offset[1]
    bpy.ops.object.shade_smooth()
    if parent is not None:
        obj.parent = parent
    obj.location = joint
    obj.rotation_mode = "XYZ"
    return obj


def ball(name, parent, location, radius, material, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=radius)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    obj.parent = parent
    obj.location = location
    return obj


def build_mannequin():
    """Proporção ~7 cabeças, luvas levemente maiores (ART §5.1). Base ortodoxa: lado esquerdo (longe) à frente."""
    m = {k: toon_material(k, v) for k, v in PALETTE.items()}
    far = {k: toon_material(k + "_far", v, FAR_SIDE_DARKEN) for k, v in PALETTE.items()}
    head_h = FIGHTER_HEIGHT_M / 7.0
    parts = {}
    bpy.ops.object.empty_add(location=(0, 0, 0.98))
    hips = bpy.context.active_object
    hips.name = "hips"
    hips.rotation_mode = "XYZ"
    parts["hips"] = hips
    parts["pelvis"] = ball("pelvis", hips, (0, 0, -0.02), 0.17, m["shorts"], (1.0, 1.15, 0.8))
    parts["torso"] = segment("torso", hips, (0, 0, 0.05), 0.52, 0.2, 0.15, m["skin"], up=True)
    parts["head"] = segment("head", parts["torso"], (0, 0, 0.52), 0.06, 0.05, 0.06, m["skin"], up=True)
    ball("skull", parts["head"], (0.02, 0, head_h * 0.55), head_h * 0.5, m["skin"], (0.9, 0.85, 1.05))
    ball("hair", parts["head"], (-0.02, 0, head_h * 0.72), head_h * 0.42, m["hair"], (1.0, 0.95, 0.7))
    for side, y, mats in (("L", 0.17, far), ("R", -0.17, m)):
        ua = segment("upper_arm_" + side, parts["torso"], (0, y, 0.47), 0.29, 0.055, 0.045, mats["skin"])
        fa = segment("forearm_" + side, ua, (0, 0, -0.29), 0.26, 0.045, 0.04, mats["skin"])
        ball("glove_" + side, fa, (0, 0, -0.29), 0.065, mats["glove"], (1.15, 1.0, 1.0))
        th = segment("thigh_" + side, hips, (0, y * 0.6, -0.05), 0.45, 0.085, 0.065, mats["shorts"] if True else mats["skin"])
        sh = segment("shin_" + side, th, (0, 0, -0.45), 0.44, 0.06, 0.045, mats["skin"])
        segment("foot_" + side, sh, (0, 0, -0.44), 0.05, 0.04, 0.05, mats["skin"], offset=(0.06, 0, 0))
        parts.update({"upper_arm_" + side: ua, "forearm_" + side: fa, "thigh_" + side: th, "shin_" + side: sh})
    return parts


def setup_camera_and_light():
    cam_data = bpy.data.cameras.new("cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = FRAME_W / PX_PER_M  # escala na maior dimensão (largura)
    cam = bpy.data.objects.new("cam", cam_data)
    bpy.context.collection.objects.link(cam)
    cam.location = (CAM_X_OFFSET, -6.0, CAM_Z)
    cam.rotation_euler = (math.radians(90), 0, 0)
    bpy.context.scene.camera = cam
    sun_data = bpy.data.lights.new("sun", "SUN")
    sun_data.energy = 3.0
    sun = bpy.data.objects.new("sun", sun_data)
    bpy.context.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(35), math.radians(-25), math.radians(20))  # de cima, levemente à frente (ART §10.1)


# ---------------------------------------------------------------------------- poses e animações
# Ângulos em graus no plano sagital (rotação em Y). Membros: negativo = para frente. Tronco: positivo = inclina à frente.
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
    hips.location = (p["hips_x"], 0, p["hips_z"])
    hips.keyframe_insert("location", frame=frame)
    for key, val in p.items():
        if key in ("hips_z", "hips_x"):
            continue
        obj = parts[key]
        obj.rotation_euler = (0, math.radians(val), 0)
        obj.keyframe_insert("rotation_euler", frame=frame)


def animations():
    """Cada animação: lista de (quadro de simulação, pose). Fases dos golpes lidas dos dados."""
    anims = {}
    anims["guard"] = [(0, GUARD), (16, pose(GUARD, hips_z=0.94, torso=10)), (32, GUARD)]
    step_a = pose(GUARD, hips_x=0.08, thigh_L=-30, shin_L=10, thigh_R=22, shin_R=26)
    step_b = pose(GUARD, hips_x=0.16, thigh_L=-16, shin_L=24, thigh_R=8, shin_R=10)
    anims["walk"] = [(0, GUARD), (8, step_a), (16, step_b), (24, pose(GUARD, hips_x=0.2))]
    s, a, r = strike_phases("jab")
    jab_out = pose(GUARD, torso=12, upper_arm_L=-90, forearm_L=-4, head=-12)
    anims["jab"] = [(0, GUARD), (s, jab_out), (s + a, jab_out), (s + a + r, GUARD)]
    s, a, r = strike_phases("cross")
    cross_out = pose(GUARD, hips_x=0.06, torso=22, upper_arm_R=-92, forearm_R=-4, upper_arm_L=-30, forearm_L=-130, thigh_R=24, shin_R=8)
    anims["cross"] = [(0, GUARD), (s, cross_out), (s + a, cross_out), (s + a + r, GUARD)]
    s, a, r = strike_phases("low_kick")
    chamber = pose(GUARD, torso=-6, thigh_R=-30, shin_R=60)
    kick_out = pose(GUARD, torso=-18, thigh_R=-62, shin_R=12, upper_arm_R=10, forearm_R=-110)
    anims["low_kick"] = [(0, GUARD), (s // 2, chamber), (s, kick_out), (s + a, kick_out), (s + a + r, GUARD)]
    s = grapple_startup("double_leg")
    level = pose(GUARD, hips_z=0.72, torso=40, thigh_L=-55, shin_L=75, thigh_R=30, shin_R=40, head=-30)
    shoot = pose(GUARD, hips_x=0.45, hips_z=0.58, torso=62, head=-40, thigh_L=-80, shin_L=95, thigh_R=55, shin_R=10,
                 upper_arm_L=-80, forearm_L=-20, upper_arm_R=-75, forearm_R=-25)
    anims["double_leg"] = [(0, GUARD), (s // 2, level), (s, shoot), (s + 8, shoot)]
    s, a, r = strike_phases("lead_hook")
    hook_out = pose(GUARD, torso=20, head=-10, upper_arm_L=-78, forearm_L=-80)
    anims["lead_hook"] = [(0, GUARD), (s, hook_out), (s + a, hook_out), (s + a + r, GUARD)]
    s, a, r = strike_phases("body_kick")
    chamber_b = pose(GUARD, torso=-8, thigh_R=-45, shin_R=75)
    body_out = pose(GUARD, torso=-28, thigh_R=-88, shin_R=20, upper_arm_R=15, forearm_R=-100)
    anims["body_kick"] = [(0, GUARD), (s // 2, chamber_b), (s, body_out), (s + a, body_out), (s + a + r, GUARD)]
    # Esquivas: duração = evade_frames do balanceamento (14 quadros [PROV])
    slip = pose(GUARD, hips_z=0.9, torso=20, head=-18, thigh_L=-28, shin_L=26)
    duck = pose(GUARD, hips_z=0.76, torso=36, head=-20, thigh_L=-55, shin_L=75, thigh_R=38, shin_R=60)
    pull = pose(GUARD, hips_x=-0.08, torso=-24, head=12, thigh_R=24, shin_R=22)
    for name, p in (("slip", slip), ("duck", duck), ("pull", pull)):
        anims[name] = [(0, GUARD), (4, p), (10, p), (14, GUARD)]
    down = pose(GUARD, hips_z=0.16, hips_x=-0.3, torso=-88, head=10, upper_arm_L=-150, forearm_L=-20,
                upper_arm_R=-160, forearm_R=-15, thigh_L=-82, shin_L=10, thigh_R=-70, shin_R=30)
    anims["down"] = [(0, down), (4, down)]
    hit = pose(GUARD, torso=-12, head=24, hips_x=-0.05)
    anims["hit_head"] = [(0, GUARD), (4, hit), (16, GUARD)]
    return anims


def clear_animation(parts):
    for obj in parts.values():
        obj.animation_data_clear()


# ---------------------------------------------------------------------------- render e pós-processo
def load_rgba(path):
    img = bpy.data.images.load(path)
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
    bpy.data.images.remove(img)
    return px


def postprocess(px, colors):
    """Quantiza cada pixel opaco para a cor de paleta mais próxima e adiciona contorno de 1 px."""
    alpha = px[:, :, 3] > 0.5
    rgb = px[:, :, :3]
    flat = rgb[alpha]
    if flat.size:
        d = ((flat[:, None, :] - colors[None, :, :]) ** 2).sum(axis=2)
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


def palette_array():
    cols = []
    for ramp in PALETTE.values():
        for c in ramp:
            cols.append(c)
            cols.append(tuple(v * FAR_SIDE_DARKEN for v in c))
    return np.array(cols, dtype=np.float32)


def main():
    t0 = time.time()
    scene = reset_scene()
    parts = build_mannequin()
    setup_camera_and_light()
    os.makedirs(OUT_DIR, exist_ok=True)
    os.makedirs(TMP_DIR, exist_ok=True)
    colors = palette_array()
    meta = {"frame_size": [FRAME_W, FRAME_H], "sim_frames_per_sprite": SIM_FRAMES_PER_SPRITE,
            "anchor": [round(FRAME_W / 2 - CAM_X_OFFSET * PX_PER_M), round(FRAME_H / 2 + CAM_Z * PX_PER_M)],
            "px_per_m": PX_PER_M, "animations": {}}
    metrics = {}
    for name, keys in animations().items():
        ta = time.time()
        clear_animation(parts)
        for frame, p in keys:
            apply_pose(parts, p, frame)
        last = keys[-1][0]
        sprite_frames = list(range(0, last + 1, SIM_FRAMES_PER_SPRITE))
        sheet = np.zeros((FRAME_H, FRAME_W * len(sprite_frames), 4), dtype=np.float32)
        for k, f in enumerate(sprite_frames):
            scene.frame_set(f)
            tmp = os.path.join(TMP_DIR, "%s_%03d.png" % (name, k))
            scene.render.filepath = tmp
            bpy.ops.render.render(write_still=True)
            sheet[:, k * FRAME_W:(k + 1) * FRAME_W] = postprocess(load_rgba(tmp), colors)
        save_png(sheet, os.path.join(OUT_DIR, name + ".png"))
        meta["animations"][name] = {"frames": len(sprite_frames), "sim_frames": last}
        metrics[name] = {"sprite_frames": len(sprite_frames), "seconds": round(time.time() - ta, 2)}
        print("ANIM", name, metrics[name])
    with open(os.path.join(OUT_DIR, "m_medium.json"), "w", encoding="utf-8") as fh:
        json.dump(meta, fh, indent=2)
    total = round(time.time() - t0, 1)
    with open(os.path.join(ROOT, "tools", "art_pipeline", "last_metrics.json"), "w", encoding="utf-8") as fh:
        json.dump({"total_seconds": total, "animations": metrics, "blender": bpy.app.version_string}, fh, indent=2)
    print("PIPELINE_OK total=%ss" % total)


main()
