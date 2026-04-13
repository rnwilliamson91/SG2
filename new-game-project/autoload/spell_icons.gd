extends Node
## UI icons + gameplay VFX from `Assets/Skills/VFX Free Pack` (frame sequences).

const VFX_ROOT := "res://Assets/Skills/VFX Free Pack"
## Max width/height for level-up button icons (source frames are often large).
const ICON_MAX_DIM := 56
## Downscale large frames for world/projectile VFX (keeps hitboxes unchanged).
const GAMEPLAY_VFX_MAX_SIDE := 96
## Playback rate for animated spell VFX in the world.
const GAMEPLAY_VFX_ANIM_FPS := 24.0

var _texture_cache: Dictionary = {} # String path -> Texture2D (full)
var _scaled_cache: Dictionary = {} # String key -> Texture2D
var _sprite_frames_cache: Dictionary = {} # String cache key -> SpriteFrames

## Per-spell override (spell id -> folder name like `Effect_Charged`).
const _BY_SPELL_ID: Dictionary = {
	&"bolt": "Effect_Charged",
	&"knife_fan": "Effect_SmallHit",
	&"cone_blast": "Effect_FastPixelFire",
	&"ring_pulse": "Effect_PuffAndStars",
	&"nova": "Effect_ElectricShield",
	&"meteor_cone": "Effect_Magma",
	&"kinetic_anchor": "Effect_TheVortex",
	&"newton_cradle": "Effect_Wheel",
	&"echo_of_past": "Effect_Hyperspeed",
	&"magnetic_scrap": "Effect_Kabooms",
	&"blood_trail_glider": "Effect_BloodImpact",
}

## When id is unknown and [member AbilityDef.icon_effect] is empty.
const _BY_DELIVERY: Dictionary = {
	AbilityDef.DeliveryKind.SPAWN_SCENE: "Effect_Charged",
	AbilityDef.DeliveryKind.CONE_INSTANT: "Effect_Impact",
	AbilityDef.DeliveryKind.AURA_SELF: "Effect_ElectricShield",
	AbilityDef.DeliveryKind.KINETIC_ANCHOR: "Effect_TheVortex",
	AbilityDef.DeliveryKind.ECHO_PAST: "Effect_Constellation",
	AbilityDef.DeliveryKind.MAGNETIC_SCRAP: "Effect_Kabooms",
	AbilityDef.DeliveryKind.BLOOD_TRAIL_GLIDER: "Effect_BloodImpact",
	AbilityDef.DeliveryKind.NEWTON_ORB: "Effect_Wheel",
}


func resolve_vfx_folder(def: AbilityDef) -> String:
	if def == null:
		return ""
	if not def.icon_effect.is_empty():
		return def.icon_effect.strip_edges()
	if _BY_SPELL_ID.has(def.id):
		return str(_BY_SPELL_ID[def.id])
	return str(_BY_DELIVERY.get(def.delivery, "Effect_Charged"))


func get_icon_texture_for_def(def: AbilityDef, max_dim: int = ICON_MAX_DIM) -> Texture2D:
	if def == null:
		return null
	var folder := resolve_vfx_folder(def)

	var path := _resolve_first_frame_path(folder)
	if path.is_empty():
		push_warning("SpellIcons: no frame *_000.png for effect folder '%s'" % folder)
		return null

	var full: Texture2D = _get_full_texture(path)
	if full == null:
		return null
	return _scaled_texture(path, full, max_dim)


func _resolve_first_frame_path(effect_folder: String) -> String:
	var anim := "%s_1" % effect_folder
	var file := "%s_000.png" % anim
	for fps in [&"60fps", &"30fps"]:
		var p := VFX_ROOT.path_join(effect_folder).path_join(fps).path_join("Frames").path_join(anim).path_join(file)
		if ResourceLoader.exists(p):
			return p
	return ""


func _get_full_texture(path: String) -> Texture2D:
	if _texture_cache.has(path):
		return _texture_cache[path]
	if not ResourceLoader.exists(path):
		return null
	var t: Texture2D = load(path)
	_texture_cache[path] = t
	return t


func _scaled_texture(source_path: String, src: Texture2D, max_dim: int) -> Texture2D:
	var cache_key := "%s|%d" % [source_path, max_dim]
	if _scaled_cache.has(cache_key):
		return _scaled_cache[cache_key]

	var img: Image = src.get_image()
	if img == null:
		_scaled_cache[cache_key] = src
		return src

	var w := img.get_width()
	var h := img.get_height()
	if w <= 0 or h <= 0:
		_scaled_cache[cache_key] = src
		return src

	var scale := minf(minf(float(max_dim) / float(w), float(max_dim) / float(h)), 1.0)
	if scale >= 1.0:
		_scaled_cache[cache_key] = src
		return src

	var nw := maxi(1, int(floor(float(w) * scale)))
	var nh := maxi(1, int(floor(float(h) * scale)))
	img = img.duplicate()
	img.resize(nw, nh, Image.INTERPOLATE_LANCZOS)
	var out := ImageTexture.create_from_image(img)
	_scaled_cache[cache_key] = out
	return out


## Full frame sequence for [AnimatedSprite2D] (projectiles, bursts, etc.). Cached per folder/size/fps-folder.
func get_sprite_frames_for_def(
	def: AbilityDef,
	max_side: int = GAMEPLAY_VFX_MAX_SIDE,
	fps_folder: String = "60fps",
	anim_fps: float = GAMEPLAY_VFX_ANIM_FPS
) -> SpriteFrames:
	if def == null:
		return null
	var folder := resolve_vfx_folder(def)
	return _get_sprite_frames_for_folder(folder, max_side, fps_folder, anim_fps)


func _get_sprite_frames_for_folder(
	folder: String,
	max_side: int,
	fps_folder: String,
	anim_fps: float
) -> SpriteFrames:
	var cache_key := "%s|%s|%d|%.2f" % [folder, fps_folder, max_side, anim_fps]
	if _sprite_frames_cache.has(cache_key):
		return _sprite_frames_cache[cache_key] as SpriteFrames

	var paths := _list_frame_paths(folder, fps_folder)
	if paths.is_empty():
		paths = _list_frame_paths(folder, "30fps" if fps_folder != "30fps" else "60fps")
	if paths.is_empty():
		push_warning("SpellIcons: no PNG frames for effect folder '%s'" % folder)
		return null

	var sf := SpriteFrames.new()
	const ANIM := "default"
	# Godot 4 may create an empty "default" animation on new SpriteFrames.
	if not sf.has_animation(ANIM):
		sf.add_animation(ANIM)
	sf.set_animation_speed(ANIM, 1.0)
	sf.set_animation_loop(ANIM, true)
	var frame_dt := 1.0 / maxf(1.0, anim_fps)
	for p in paths:
		var tex := _get_scaled_texture_at_path(str(p), max_side)
		if tex:
			sf.add_frame(ANIM, tex, frame_dt)

	if sf.get_frame_count(ANIM) < 1:
		return null

	_sprite_frames_cache[cache_key] = sf
	return sf


func _list_frame_paths(folder: String, fps_folder: String) -> PackedStringArray:
	var anim := "%s_1" % folder
	var dir_path := VFX_ROOT.path_join(folder).path_join(fps_folder).path_join("Frames").path_join(anim)
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return PackedStringArray()
	var names: Array[String] = []
	dir.list_dir_begin()
	var fn := dir.get_next()
	while fn != "":
		if not dir.current_is_dir() and fn.ends_with(".png"):
			names.append(fn)
		fn = dir.get_next()
	dir.list_dir_end()
	names.sort()
	var out: PackedStringArray = []
	for n in names:
		out.append(dir_path.path_join(n))
	return out


func _get_scaled_texture_at_path(path: String, max_side: int) -> Texture2D:
	var full := _get_full_texture(path)
	if full == null:
		return null
	return _scaled_texture(path, full, max_side)


## One-shot burst in world space (cone / custom). Frees itself when the animation finishes.
func spawn_burst_vfx(world_parent: Node2D, def: AbilityDef, global_pos: Vector2, rotation_rad: float, z_index_offset: int = 1) -> void:
	var sf := get_sprite_frames_for_def(def)
	if sf == null:
		return
	var dup := sf.duplicate(true) as SpriteFrames
	dup.set_animation_loop(&"default", false)
	var spr := AnimatedSprite2D.new()
	spr.z_index = z_index_offset
	spr.sprite_frames = dup
	spr.animation = &"default"
	spr.global_position = global_pos
	spr.rotation = rotation_rad
	world_parent.add_child(spr)
	spr.animation_finished.connect(spr.queue_free)
	spr.play()
