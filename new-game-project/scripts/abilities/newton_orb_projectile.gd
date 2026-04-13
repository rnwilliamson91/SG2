extends Area2D
## Pinball orb: damages on hit, knockback, ricochets toward next mob, grows slightly each bounce.

var _def: AbilityDef
var _velocity: Vector2
var _bounce_idx: int = 0


func configure(def: AbilityDef, dir: Vector2) -> void:
	_def = def
	_velocity = dir.normalized() * def.newton_speed
	collision_layer = GameLayers.PROJECTILE_PLAYER
	collision_mask = GameLayers.MOB_HURTBOX
	monitoring = true
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	apply_spell_visual(def)


func apply_spell_visual(def: AbilityDef) -> void:
	if def == null:
		return
	var sf := SpellIcons.get_sprite_frames_for_def(def)
	var vfx := get_node_or_null(^"VfxSprite") as AnimatedSprite2D
	var vis := get_node_or_null(^"Vis") as Polygon2D
	if sf == null or vfx == null:
		return
	if vis:
		vis.visible = false
	vfx.sprite_frames = sf
	vfx.visible = true
	vfx.play(&"default")


func _physics_process(delta: float) -> void:
	if Run.is_paused or Run.is_game_over:
		return
	global_position += _velocity * delta
	if _bounce_idx > 48:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _def == null or not (area is Hurtbox):
		return
	var hb := area as Hurtbox
	if hb.team_is_player:
		return
	var mob := hb.get_parent() as Node2D
	if mob == null:
		return
	var dmg := _def.projectile_damage * pow(_def.newton_scale_per_bounce, float(_bounce_idx)) * SpellProgress.get_damage_multiplier(_def.id)
	var h: HealthComponent = hb.get_node_or_null(hb.health_path) as HealthComponent
	if h:
		h.take_damage(dmg)
	if mob is CharacterBody2D:
		var away := (mob.global_position - global_position).normalized()
		(mob as CharacterBody2D).velocity += away * _def.newton_knockback
	_bounce_idx += 1
	scale *= Vector2.ONE * minf(1.08, pow(_def.newton_scale_per_bounce, 0.25))
	_ricochet(mob)


func _ricochet(ignore: Node2D) -> void:
	var best = null
	var best_d := 1.0e12
	for n in get_tree().get_nodes_in_group(&"mobs"):
		if n == ignore or not (n is Node2D):
			continue
		var d := global_position.distance_squared_to((n as Node2D).global_position)
		if d < best_d and d > 2.0:
			best_d = d
			best = n as Node2D
	if best:
		_velocity = (best.global_position - global_position).normalized() * _def.newton_speed
	else:
		_velocity = -_velocity
