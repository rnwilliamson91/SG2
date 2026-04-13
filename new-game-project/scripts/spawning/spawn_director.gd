extends Node
## Spawns mobs from wave tiers; advances difficulty over time.

@export var tiers: Array[WaveTierDef] = []
@export var time_per_tier_advance: float = 30.0

var _mobs_root: Node2D

var _tier_index: int = 0
var _spawn_accum: float = 0.0
var _tier_timer: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	call_deferred(&"_resolve_mobs_root")


func _resolve_mobs_root() -> void:
	_mobs_root = get_tree().get_first_node_in_group(&"mobs_root") as Node2D
	if tiers.is_empty():
		tiers.assign(_make_default_tiers())


func _make_default_tiers() -> Array[WaveTierDef]:
	var mob := preload("res://scenes/mobs/mob_grunt.tscn") as PackedScene
	var w1 := WaveTierDef.new()
	w1.label = "Swarm"
	w1.tier_index = 0
	w1.spawn_interval = 2.2
	w1.mobs = [mob]
	w1.weights = [1.0]
	var w2 := WaveTierDef.new()
	w2.label = "Pressure"
	w2.tier_index = 1
	w2.spawn_interval = 1.35
	w2.mobs = [mob]
	w2.weights = [1.0]
	var out: Array[WaveTierDef] = []
	out.append(w1)
	out.append(w2)
	return out


func _process(delta: float) -> void:
	if Run.is_paused or Run.is_game_over:
		return
	_tier_timer += delta
	if _tier_index < tiers.size() - 1 and _tier_timer >= time_per_tier_advance:
		_tier_timer = 0.0
		_tier_index += 1
		Run.difficulty_stage = _tier_index

	var tier = _current_tier() as WaveTierDef
	if tier == null or tier.mobs.is_empty():
		return
	_spawn_accum += delta
	if _spawn_accum < tier.spawn_interval:
		return
	_spawn_accum = 0.0
	var scene = _pick_mob_scene(tier) as PackedScene
	if scene and _mobs_root:
		var mob := scene.instantiate() as Node2D
		_mobs_root.add_child(mob)
		mob.global_position = _random_spawn_around_player(420.0, 620.0)


func _current_tier():
	if tiers.is_empty():
		return null
	return tiers[clampi(_tier_index, 0, tiers.size() - 1)] as WaveTierDef


func _pick_mob_scene(tier: WaveTierDef):
	if tier.mobs.is_empty():
		return null
	var wsum := 0.0
	for w in tier.weights:
		wsum += w
	if wsum <= 0.0:
		return tier.mobs[_rng.randi() % tier.mobs.size()]
	var r := _rng.randf() * wsum
	var acc := 0.0
	for i in tier.mobs.size():
		var wi := tier.weights[i] if i < tier.weights.size() else 1.0
		acc += wi
		if r <= acc:
			return tier.mobs[i]
	return tier.mobs.back()


func _random_spawn_around_player(min_r: float, max_r: float) -> Vector2:
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	var center := Vector2.ZERO if player == null else player.global_position
	var ang := _rng.randf() * TAU
	var rad := _rng.randf_range(min_r, max_r)
	return center + Vector2(cos(ang), sin(ang)) * rad
