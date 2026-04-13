extends CharacterBody2D
## Top-down movement; abilities handled by AbilityController.

const SPEED := 280.0
const DASH_SPEED := 520.0
const DASH_TIME := 0.12
const DASH_COOLDOWN := 0.38

const BALL_CHAIN_PREFIX := "ball_chain_bot"

@onready var _health: HealthComponent = $Health
@onready var _spr: AnimatedSprite2D = get_node_or_null(^"CharacterSprite") as AnimatedSprite2D
@onready var _ac: AbilityController = $AbilityController

var _dash_cd: float = 0.0
var _dash_remain: float = 0.0
var _prev_hp: float = -1.0

## Ball & Chain Bot animation locks (priority: death > hit > attack > dash > move).
var _anim_death: bool = false
var _anim_hit_lock: bool = false
var _anim_attack_lock: bool = false
var _dash_transitioning: bool = false


func _ready() -> void:
	add_to_group(&"player")
	_health.died.connect(_on_player_died)
	_prev_hp = _health.max_health
	_health.health_changed.connect(_on_health_changed_anim)
	_apply_character_visual()
	if _use_ball_chain_visual() and _spr:
		if not _spr.animation_finished.is_connected(_on_sprite_anim_finished):
			_spr.animation_finished.connect(_on_sprite_anim_finished)
	if _ac and _use_ball_chain_visual():
		if not _ac.weapon_fired.is_connected(_on_weapon_fired_anim):
			_ac.weapon_fired.connect(_on_weapon_fired_anim)


func _use_ball_chain_visual() -> bool:
	return Run.selected_character_prefix == BALL_CHAIN_PREFIX


func _apply_character_visual() -> void:
	var spr := get_node_or_null(^"CharacterSprite") as AnimatedSprite2D
	var vis := get_node_or_null(^"Vis") as Polygon2D
	if spr == null:
		return

	var sf: SpriteFrames = null
	if _use_ball_chain_visual():
		sf = BallChainBotFrames.build_sprite_frames()
	else:
		var prefix: String = Run.selected_character_prefix.strip_edges()
		if prefix.is_empty():
			prefix = "manBlue"
		sf = SpriteFactory.get_sprite_frames(prefix)

	if sf == null or sf.get_animation_names().is_empty():
		return
	spr.sprite_frames = sf
	spr.visible = true
	if vis:
		vis.visible = false

	if _use_ball_chain_visual():
		spr.play(&"idle")
	else:
		if sf.has_animation(&"stand"):
			spr.play(&"stand")
		else:
			spr.play(sf.get_animation_names()[0])


func _on_health_changed_anim(current: float, _max_h: float) -> void:
	if not _use_ball_chain_visual() or _spr == null or _anim_death:
		_prev_hp = current
		return
	if current < _prev_hp and current > 0.0:
		_anim_hit_lock = true
		_spr.play(&"hit")
	_prev_hp = current


func _on_weapon_fired_anim(_slot: int) -> void:
	if not _use_ball_chain_visual() or _spr == null or _anim_death:
		return
	if _anim_hit_lock:
		return
	_anim_attack_lock = true
	_spr.play(&"attack")


func _on_sprite_anim_finished() -> void:
	if not _use_ball_chain_visual() or _spr == null:
		return
	var anim: StringName = _spr.animation
	match anim:
		&"death":
			Run.game_over()
		&"transition_to_charge":
			if _dash_remain > 0.0:
				_dash_transitioning = false
				_spr.play(&"charge")
			else:
				_dash_transitioning = false
				_refresh_ball_chain_locomotion()
		&"attack":
			_anim_attack_lock = false
			_refresh_ball_chain_locomotion()
		&"hit":
			_anim_hit_lock = false
			_refresh_ball_chain_locomotion()
		_:
			pass


func _on_player_died() -> void:
	if _use_ball_chain_visual() and _spr and _spr.sprite_frames and _spr.sprite_frames.has_animation(&"death"):
		_anim_death = true
		velocity = Vector2.ZERO
		_spr.play(&"death")
	else:
		Run.game_over()


func _physics_process(delta: float) -> void:
	if Run.is_paused or Run.is_game_over:
		return
	_dash_cd = maxf(_dash_cd - delta, 0.0)

	if _use_ball_chain_visual() and _anim_death:
		move_and_slide()
		return

	var dir := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if _dash_remain > 0.0:
		_dash_remain -= delta
		move_and_slide()
		if _use_ball_chain_visual() and _dash_remain <= 0.0 and _spr:
			_dash_transitioning = false
			if _spr.animation == &"charge" or _spr.animation == &"transition_to_charge":
				_refresh_ball_chain_locomotion()
		return

	var trail_boost := 1.0
	if has_meta(&"blood_trail_speed_mult"):
		trail_boost = float(get_meta(&"blood_trail_speed_mult"))
		remove_meta(&"blood_trail_speed_mult")

	if Input.is_action_just_pressed(&"dash") and _dash_cd <= 0.0 and dir.length_squared() > 0.0001:
		var d := dir.normalized()
		velocity = d * DASH_SPEED
		_dash_remain = DASH_TIME
		_dash_cd = DASH_COOLDOWN
		Events.player_dashed.emit(global_position, d)
		if _use_ball_chain_visual() and _spr and not _anim_hit_lock and not _anim_attack_lock:
			_dash_transitioning = true
			_spr.play(&"transition_to_charge")
		move_and_slide()
		_update_ball_chain_locomotion_after_move(dir)
		return

	velocity = dir * SPEED * trail_boost
	move_and_slide()
	_update_ball_chain_locomotion_after_move(dir)


func _update_ball_chain_locomotion_after_move(dir: Vector2) -> void:
	if not _use_ball_chain_visual() or _spr == null or _anim_death:
		return
	if _anim_hit_lock or _anim_attack_lock or _dash_remain > 0.0 or _dash_transitioning:
		return
	_refresh_ball_chain_locomotion()


func _refresh_ball_chain_locomotion() -> void:
	if not _use_ball_chain_visual() or _spr == null or _anim_death:
		return
	if _anim_hit_lock or _anim_attack_lock or _dash_remain > 0.0 or _dash_transitioning:
		return
	var dir := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if dir.length_squared() > 0.01:
		if _spr.animation != &"run":
			_spr.play(&"run")
	else:
		if _spr.animation != &"idle":
			_spr.play(&"idle")
