class_name BallChainBotFrames
extends RefCounted
## Slices `Ball and Chain Bot` PNG strips (126×39 px frames, vertical) into [SpriteFrames].

const FRAME_W := 126
const FRAME_H := 39

const BASE := "res://Assets/Character/Ball and Chain Bot/"

## Playback rates (frames per second) per clip.
const FPS_IDLE := 7.0
const FPS_RUN := 11.0
const FPS_TRANSITION_CHARGE := 14.0
const FPS_CHARGE := 12.0
const FPS_ATTACK := 14.0
const FPS_HIT := 16.0
const FPS_DEATH := 9.0


static func build_sprite_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()

	_add_vertical_strip(sf, &"idle", BASE.path_join("idle.png"), FPS_IDLE, true)
	_add_vertical_strip(sf, &"run", BASE.path_join("run.png"), FPS_RUN, true)
	_add_vertical_strip(sf, &"transition_to_charge", BASE.path_join("transition to charge.png"), FPS_TRANSITION_CHARGE, false)
	_add_vertical_strip(sf, &"charge", BASE.path_join("charge.png"), FPS_CHARGE, true)
	_add_vertical_strip(sf, &"attack", BASE.path_join("attack.png"), FPS_ATTACK, false)
	_add_vertical_strip(sf, &"hit", BASE.path_join("hit.png"), FPS_HIT, false)
	_add_vertical_strip(sf, &"death", BASE.path_join("death.png"), FPS_DEATH, false)

	return sf


static func _add_vertical_strip(sf: SpriteFrames, anim: StringName, image_path: String, fps: float, loop: bool) -> void:
	var tex: Texture2D = load(image_path)
	if tex == null:
		push_error("BallChainBotFrames: missing texture %s" % image_path)
		return
	var h := tex.get_height()
	var w := tex.get_width()
	if w != FRAME_W or h < FRAME_H or h % FRAME_H != 0:
		push_error("BallChainBotFrames: unexpected size %dx%d for %s" % [w, h, image_path])
		return
	var n := h / FRAME_H
	if not sf.has_animation(anim):
		sf.add_animation(anim)
	sf.set_animation_loop(anim, loop)
	var frame_dt := 1.0 / maxf(1.0, fps)
	for i in n:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(0, float(i * FRAME_H), float(FRAME_W), float(FRAME_H))
		sf.add_frame(anim, at, frame_dt)
