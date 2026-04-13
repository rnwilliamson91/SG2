extends Node2D
## Drops TrailHazard puddles while moving; dash drops a larger blob via Events.player_dashed.

var _def: AbilityDef
var _accum: float = 0.0
var _last_p: Vector2


func configure(def: AbilityDef) -> void:
	_def = def
	_last_p = global_position
	if not Events.player_dashed.is_connected(_on_dash):
		Events.player_dashed.connect(_on_dash)


func _exit_tree() -> void:
	if Events.player_dashed.is_connected(_on_dash):
		Events.player_dashed.disconnect(_on_dash)


func _on_dash(world_pos: Vector2, _dir: Vector2) -> void:
	_spawn(world_pos, 1.55)


func _process(delta: float) -> void:
	if Run.is_paused or Run.is_game_over:
		return
	var p := get_parent() as Node2D
	if p == null:
		return
	if p.global_position.distance_squared_to(_last_p) < 2.0:
		return
	_accum += delta
	if _accum < _def.trail_drop_interval:
		return
	_accum = 0.0
	_last_p = p.global_position
	_spawn(p.global_position, 1.0)


func _spawn(world_pos: Vector2, size_scale: float) -> void:
	var root := get_tree().get_first_node_in_group(&"world_vfx") as Node2D
	if root == null:
		return
	var h := TrailHazard.new()
	var dm := SpellProgress.get_damage_multiplier(_def.id)
	h.damage_per_sec = _def.trail_dot_per_sec * dm
	h.slow_scale = _def.trail_slow_scale
	h.lifetime = 4.0 * size_scale
	h.hazard_radius = _def.trail_hazard_radius * size_scale
	h.player_speed_mult = _def.trail_boost_speed_mult
	h.player_invuln_sec = _def.trail_invuln_sec
	root.add_child(h)
	h.global_position = world_pos
