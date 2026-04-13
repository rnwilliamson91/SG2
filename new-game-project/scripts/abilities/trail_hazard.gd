class_name TrailHazard
extends Area2D
## Damages mobs in radius; buffs player on overlap.

@export var damage_per_sec: float = 7.0
@export var slow_scale: float = 0.55
@export var lifetime: float = 4.0
@export var hazard_radius: float = 26.0
@export var player_speed_mult: float = 3.0
@export var player_invuln_sec: float = 0.45

var _elapsed: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = GameLayers.MOB_HURTBOX | GameLayers.PLAYER_BODY
	monitoring = true
	monitorable = false
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = hazard_radius
	cs.shape = circle
	add_child(cs)
	var g := Polygon2D.new()
	var pts: PackedVector2Array = []
	for i in range(14):
		var t := float(i) / 14.0 * TAU
		pts.append(Vector2(cos(t), sin(t)) * hazard_radius * 0.92)
	g.polygon = pts
	g.color = Color(0.9, 0.2, 0.28, 0.38)
	add_child(g)


func _physics_process(delta: float) -> void:
	if Run.is_paused:
		return
	_elapsed += delta
	if _elapsed >= lifetime:
		queue_free()
		return
	for ar in get_overlapping_areas():
		if ar is Hurtbox and not (ar as Hurtbox).team_is_player:
			var hb := ar as Hurtbox
			var h: HealthComponent = hb.get_node_or_null(hb.health_path) as HealthComponent
			if h:
				h.take_damage(damage_per_sec * delta)
	for b in get_overlapping_bodies():
		if b.is_in_group(&"mobs") and b is CharacterBody2D:
			(b as CharacterBody2D).set_meta(&"trail_slow_mult", slow_scale)
		elif b.is_in_group(&"player"):
			b.set_meta(&"blood_trail_speed_mult", player_speed_mult)
			var hp: HealthComponent = b.get_node_or_null(^"Health") as HealthComponent
			if hp:
				var t := Time.get_ticks_msec() / 1000.0
				hp.invulnerable_until_sec = maxf(hp.invulnerable_until_sec, t + player_invuln_sec)
