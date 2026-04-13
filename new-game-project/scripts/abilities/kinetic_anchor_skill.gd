extends Node2D
## Tethers mobs in radius with chains; after delay, snaps to player and yanks victims into a cluster.

var _def: AbilityDef
var _player: Node2D
var _tethered: Array[CharacterBody2D] = []
var _chain_lines: Dictionary = {} # CharacterBody2D -> Line2D
var _rng := RandomNumberGenerator.new()


func setup_from_def(def: AbilityDef, player: Node2D, _vfx: Node2D) -> void:
	_def = def
	_player = player
	_rng.randomize()
	var off := Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)).normalized() * _rng.randf_range(80.0, def.anchor_spawn_radius)
	global_position = player.global_position + off
	z_index = 2
	_build_zone()
	var sf := SpellIcons.get_sprite_frames_for_def(def)
	if sf:
		var spr := AnimatedSprite2D.new()
		spr.sprite_frames = sf
		spr.play(&"default")
		add_child(spr)
	else:
		var core := Polygon2D.new()
		core.polygon = PackedVector2Array([-14, -18, 14, -18, 10, 14, -10, 14])
		core.color = Color(0.45, 0.55, 0.95, 0.85)
		add_child(core)
	get_tree().create_timer(_def.anchor_snap_delay, false, true).timeout.connect(_snap_to_player, Object.CONNECT_ONE_SHOT)


func _build_zone() -> void:
	var zone := Area2D.new()
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = _def.anchor_tether_radius
	cs.shape = circle
	zone.add_child(cs)
	zone.collision_layer = 0
	zone.collision_mask = GameLayers.MOB_BODY
	zone.monitoring = true
	zone.body_entered.connect(_on_body_entered)
	zone.body_exited.connect(_on_body_exited)
	add_child(zone)


func _process(_delta: float) -> void:
	if Run.is_paused or Run.is_game_over:
		return
	for m in _tethered:
		if m == null or not is_instance_valid(m):
			continue
		var ln: Line2D = _chain_lines.get(m, null) as Line2D
		if ln:
			ln.clear_points()
			ln.add_point(Vector2.ZERO)
			ln.add_point(m.global_position - global_position)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"mobs"):
		return
	var m := body as CharacterBody2D
	if m == null or _chain_lines.has(m):
		return
	m.set_meta(&"kinetic_anchor_node", self)
	m.set_meta(&"kinetic_pull_spd", _def.anchor_pull_speed)
	_tethered.append(m)
	var ln := Line2D.new()
	ln.width = 2.5
	ln.default_color = Color(0.55, 0.75, 1.0, 0.9)
	add_child(ln)
	_chain_lines[m] = ln


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_clear_tether(body as CharacterBody2D)


func _clear_tether(m: CharacterBody2D) -> void:
	var i := _tethered.find(m)
	if i >= 0:
		_tethered.remove_at(i)
	if _chain_lines.has(m):
		(_chain_lines[m] as Line2D).queue_free()
		_chain_lines.erase(m)
	if m.has_meta(&"kinetic_anchor_node"):
		m.remove_meta(&"kinetic_anchor_node")
	if m.has_meta(&"kinetic_pull_spd"):
		m.remove_meta(&"kinetic_pull_spd")


func _snap_to_player() -> void:
	if _player == null or not is_instance_valid(_player):
		queue_free()
		return
	var forward := Vector2.RIGHT
	if _player is CharacterBody2D:
		var v := (_player as CharacterBody2D).velocity
		if v.length_squared() > 25.0:
			forward = v.normalized()
	var cluster := _player.global_position + forward * _def.anchor_cluster_offset
	var victims: Array[CharacterBody2D] = []
	for m in _tethered.duplicate():
		if m and is_instance_valid(m):
			victims.append(m)
	for m in victims:
		_clear_tether(m)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, ^"global_position", _player.global_position, 0.32).set_trans(Tween.TRANS_QUAD)
	for m in victims:
		if m and is_instance_valid(m):
			var j := Vector2(_rng.randf_range(-22.0, 22.0), _rng.randf_range(-22.0, 22.0))
			tw.tween_property(m, ^"global_position", cluster + j, 0.34).set_trans(Tween.TRANS_BACK)
	await tw.finished
	queue_free()
