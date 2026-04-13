extends Node2D
## Junk pieces orbit the player; Space fires shrapnel shockwave (scales with orb count).

var _def: AbilityDef
var _orbiters: Array[Node2D] = []
var _shrapnel_cd: float = 0.0


func configure(def: AbilityDef) -> void:
	_def = def
	Events.enemy_died.connect(_on_enemy_died)


func _exit_tree() -> void:
	if Events.enemy_died.is_connected(_on_enemy_died):
		Events.enemy_died.disconnect(_on_enemy_died)


func _on_enemy_died(_mob: Node2D) -> void:
	if _orbiters.size() >= _def.scrap_max_pieces:
		return
	var holder := Node2D.new()
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([-9, -5, 7, -4, 6, 7, -8, 5])
	poly.color = Color(0.52, 0.4, 0.36, 1.0)
	holder.add_child(poly)
	holder.set_meta(&"orbit_a", randf() * TAU)
	add_child(holder)
	_orbiters.append(holder)


func _process(delta: float) -> void:
	if Run.is_paused or Run.is_game_over:
		return
	for h in _orbiters:
		if h == null or not is_instance_valid(h):
			continue
		var a := float(h.get_meta(&"orbit_a", 0.0)) + _def.scrap_orbit_speed * delta
		h.set_meta(&"orbit_a", a)
		h.position = Vector2(cos(a), sin(a)) * _def.scrap_orbit_radius
	_shrapnel_cd -= delta
	if Input.is_action_just_pressed(&"shrapnel_burst") and _shrapnel_cd <= 0.0:
		_shrapnel_burst()
		_shrapnel_cd = _def.scrap_shrapnel_cooldown


func _shrapnel_burst() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		return
	var n := _orbiters.size()
	if n < 1:
		return
	var pack := maxi(1, n)
	var dmg := _def.scrap_shrapnel_damage_per_piece * float(pack) * SpellProgress.get_damage_multiplier(_def.id)
	var space := player.get_world_2d().direct_space_state
	var q := PhysicsShapeQueryParameters2D.new()
	var c := CircleShape2D.new()
	c.radius = 240.0
	q.shape = c
	q.transform = Transform2D(0.0, player.global_position)
	q.collide_with_areas = true
	q.collision_mask = GameLayers.MOB_HURTBOX
	for item in space.intersect_shape(q, 48):
		var ar: Area2D = item.collider as Area2D
		if ar and ar is Hurtbox:
			var hb := ar as Hurtbox
			if hb.team_is_player:
				continue
			var h: HealthComponent = hb.get_node_or_null(hb.health_path) as HealthComponent
			if h:
				h.take_damage(dmg / float(pack))
	for h in _orbiters:
		if h and is_instance_valid(h):
			h.queue_free()
	_orbiters.clear()
