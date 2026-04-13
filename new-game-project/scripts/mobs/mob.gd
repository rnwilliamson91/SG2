extends CharacterBody2D
## Chases the player; uses Health + Hurtbox from scene.

const XP_GEM := preload("res://scenes/pickups/xp_gem.tscn")
const SPELL_TOME := preload("res://scenes/pickups/spell_tome.tscn")

@export var data: MobDef

@onready var _health: HealthComponent = $Health


func _ready() -> void:
	add_to_group(&"mobs")
	if data:
		_health.max_health = data.max_health
		_health.current_health = data.max_health
	_health.died.connect(_on_died)
	_health.health_changed.connect(_on_health_changed)


func _physics_process(_delta: float) -> void:
	if Run.is_paused or Run.is_game_over:
		return
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		return
	var spd := data.move_speed if data else 90.0
	var to_player := player.global_position - global_position
	if has_meta(&"kinetic_anchor_node"):
		var an: Node2D = get_meta(&"kinetic_anchor_node") as Node2D
		if an != null and is_instance_valid(an):
			var pull_spd: float = float(get_meta(&"kinetic_pull_spd", spd))
			var to_anchor := an.global_position - global_position
			if to_anchor.length_squared() > 4.0:
				velocity = to_anchor.normalized() * minf(spd, pull_spd)
			else:
				velocity = Vector2.ZERO
		else:
			remove_meta(&"kinetic_anchor_node")
			if has_meta(&"kinetic_pull_spd"):
				remove_meta(&"kinetic_pull_spd")
			velocity = to_player.normalized() * spd
	else:
		var slow_mult := 1.0
		if has_meta(&"trail_slow_mult"):
			slow_mult = float(get_meta(&"trail_slow_mult"))
			remove_meta(&"trail_slow_mult")
		velocity = to_player.normalized() * spd * slow_mult
	move_and_slide()


func _on_died() -> void:
	Events.enemy_died.emit(self)
	_spawn_xp_gem()
	if randf() < 0.045:
		_spawn_spell_tome()
	queue_free()


func _spawn_xp_gem() -> void:
	var root := get_tree().get_first_node_in_group(&"pickups_root") as Node2D
	if root == null:
		return
	var pos := global_position + Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0))
	var p := XP_GEM.instantiate() as Node2D
	# Death runs inside hurtbox/physics flush — defer add so Area2D setup isn't mid-query.
	root.call_deferred(&"add_child", p)
	p.call_deferred(&"set_global_position", pos)


func _spawn_spell_tome() -> void:
	var root := get_tree().get_first_node_in_group(&"pickups_root") as Node2D
	if root == null:
		return
	var pos := global_position + Vector2(randf_range(-14.0, 14.0), randf_range(-14.0, 14.0))
	var p := SPELL_TOME.instantiate() as Node2D
	root.call_deferred(&"add_child", p)
	p.call_deferred(&"set_global_position", pos)


func _on_health_changed(_c: float, _m: float) -> void:
	pass
