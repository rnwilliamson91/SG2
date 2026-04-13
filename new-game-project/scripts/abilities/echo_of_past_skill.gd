extends Node2D
## Ghost at delayed position along your path; periodic cleave damage.

var _def: AbilityDef
var _player: Node2D
var _pos_hist: Array[Vector2] = []
var _t_hist: Array[float] = []
var _ghost_poly := Polygon2D.new()
var _burst_acc: float = 0.0


func configure(def: AbilityDef, player: Node2D) -> void:
	_def = def
	_player = player
	_ghost_poly.color = Color(0.62, 0.88, 1.0, 0.42)
	_ghost_poly.polygon = PackedVector2Array([-24, -10, 32, 0, -24, 10])
	add_child(_ghost_poly)
	z_index = 4


func _process(delta: float) -> void:
	if Run.is_paused or Run.is_game_over or _player == null:
		return
	var now := Time.get_ticks_msec() / 1000.0
	_pos_hist.append(_player.global_position)
	_t_hist.append(now)
	var keep_from := now - 6.0
	while _t_hist.size() > 0 and _t_hist[0] < keep_from:
		_t_hist.remove_at(0)
		_pos_hist.remove_at(0)
	var want_t := now - _def.echo_delay_sec
	var gp := _player.global_position
	if _t_hist.size() >= 1 and want_t < _t_hist[0]:
		gp = _pos_hist[0]
	elif _t_hist.size() >= 2:
		for i in range(_t_hist.size() - 1):
			if _t_hist[i] <= want_t and _t_hist[i + 1] >= want_t:
				var span := _t_hist[i + 1] - _t_hist[i]
				var u := (want_t - _t_hist[i]) / maxf(span, 0.0001)
				gp = _pos_hist[i].lerp(_pos_hist[i + 1], clampf(u, 0.0, 1.0))
				break
			elif _t_hist[i + 1] < want_t and i == _t_hist.size() - 2:
				gp = _pos_hist[i + 1]
	global_position = gp
	_burst_acc += delta
	if _burst_acc >= _def.echo_burst_interval:
		_burst_acc = 0.0
		_burst_damage()


func _burst_damage() -> void:
	var id := _def.id
	var dm := SpellProgress.get_damage_multiplier(id)
	var dmg := _def.echo_burst_damage * dm
	var space := get_world_2d().direct_space_state
	var q := PhysicsShapeQueryParameters2D.new()
	var c := CircleShape2D.new()
	c.radius = _def.echo_burst_radius
	q.shape = c
	q.transform = Transform2D(0.0, global_position)
	q.collide_with_areas = true
	q.collision_mask = GameLayers.MOB_HURTBOX
	for item in space.intersect_shape(q, 32):
		var ar: Area2D = item.collider as Area2D
		if ar and ar is Hurtbox:
			var hb := ar as Hurtbox
			if hb.team_is_player:
				continue
			var h: HealthComponent = hb.get_node_or_null(hb.health_path) as HealthComponent
			if h:
				h.take_damage(dmg)
