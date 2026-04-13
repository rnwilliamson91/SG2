class_name AbilityExecutors
extends RefCounted
## Static helpers to run AbilityDef delivery types.

static func execute(
	def: AbilityDef,
	origin: Node2D,
	target_hint: Vector2,
	projectiles_root: Node2D,
	vfx_root: Node2D,
	pool = null
) -> void:
	if def == null or origin == null:
		return
	match def.delivery:
		AbilityDef.DeliveryKind.SPAWN_SCENE:
			_spawn_projectile(def, origin, target_hint, projectiles_root, pool)
		AbilityDef.DeliveryKind.CONE_INSTANT:
			_cone_damage(def, origin, target_hint, vfx_root)
		AbilityDef.DeliveryKind.AURA_SELF:
			_aura_pulse(def, origin, vfx_root)
		AbilityDef.DeliveryKind.KINETIC_ANCHOR:
			_spawn_kinetic_anchor(def, origin, vfx_root)
		AbilityDef.DeliveryKind.NEWTON_ORB:
			_spawn_newton_orb(def, origin, target_hint, projectiles_root)
		AbilityDef.DeliveryKind.ECHO_PAST:
			pass
		AbilityDef.DeliveryKind.MAGNETIC_SCRAP:
			pass
		AbilityDef.DeliveryKind.BLOOD_TRAIL_GLIDER:
			pass


static func _spawn_projectile(
	def: AbilityDef,
	origin: Node2D,
	target_hint: Vector2,
	projectiles_root: Node2D,
	pool
) -> void:
	if def.projectile_scene == null:
		return
	if projectiles_root == null:
		push_warning("AbilityExecutors: world_projectiles group node missing; cannot spawn projectile.")
		return
	var proj: Node2D
	if pool:
		proj = pool.acquire(def.projectile_scene) as Node2D
	if proj == null:
		proj = def.projectile_scene.instantiate() as Node2D
	# Pool acquire returns a node still parented to ProjectilePool — detach before reparenting.
	var pp := proj.get_parent()
	if pp:
		pp.remove_child(proj)
	projectiles_root.add_child(proj)
	var dir := (target_hint - origin.global_position).normalized()
	if dir.length_squared() < 0.001:
		dir = Vector2.RIGHT
	proj.global_position = origin.global_position + dir * 16.0
	if proj.has_method(&"setup"):
		proj.call(&"setup", dir, true, def.projectile_scene, def.projectile_damage)
	if proj.has_method(&"apply_spell_visual"):
		proj.call(&"apply_spell_visual", def)


static func _spawn_kinetic_anchor(def: AbilityDef, origin: Node2D, vfx_root: Node2D) -> void:
	if def.projectile_scene == null or vfx_root == null:
		return
	var node := def.projectile_scene.instantiate() as Node2D
	vfx_root.add_child(node)
	if node.has_method(&"setup_from_def"):
		node.call(&"setup_from_def", def, origin, vfx_root)


static func _spawn_newton_orb(def: AbilityDef, origin: Node2D, target_hint: Vector2, projectiles_root: Node2D) -> void:
	if def.projectile_scene == null or projectiles_root == null:
		return
	var orb := def.projectile_scene.instantiate() as Node2D
	projectiles_root.add_child(orb)
	var dir := (target_hint - origin.global_position).normalized()
	if dir.length_squared() < 0.001:
		dir = Vector2.RIGHT
	orb.global_position = origin.global_position + dir * 20.0
	if orb.has_method(&"configure"):
		orb.call(&"configure", def, dir)


static func _cone_damage(def: AbilityDef, origin: Node2D, target_hint: Vector2, vfx_root: Node2D) -> void:
	var forward := (target_hint - origin.global_position).normalized()
	if forward.length_squared() < 0.001:
		forward = Vector2.RIGHT
	if vfx_root:
		SpellIcons.spawn_burst_vfx(vfx_root, def, origin.global_position, forward.angle())
	var half_rad := deg_to_rad(def.cone_arc_degrees * 0.5)
	var space := origin.get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = def.cone_range
	query.shape = circle
	query.transform = Transform2D(0.0, origin.global_position)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = GameLayers.MOB_HURTBOX
	var results := space.intersect_shape(query, 32)
	for item in results:
		var area: Area2D = item.collider as Area2D
		if area == null or not (area is Hurtbox):
			continue
		var hb := area as Hurtbox
		if hb.team_is_player:
			continue
		var to_target := area.global_position - origin.global_position
		var dist := to_target.length()
		if dist > def.cone_range or dist < 0.001:
			continue
		var nd := to_target / dist
		if forward.dot(nd) < cos(half_rad):
			continue
		var health: HealthComponent = hb.get_node_or_null(hb.health_path) as HealthComponent
		if health:
			health.take_damage(def.cone_damage)


static func _aura_pulse(def: AbilityDef, origin: Node2D, vfx_root: Node2D) -> void:
	var space := origin.get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = def.aura_radius
	query.shape = circle
	query.transform = Transform2D(0.0, origin.global_position)
	query.collide_with_areas = true
	query.collision_mask = GameLayers.MOB_HURTBOX
	var results := space.intersect_shape(query, 64)
	for item in results:
		var area: Area2D = item.collider as Area2D
		if area == null or not (area is Hurtbox):
			continue
		var hb := area as Hurtbox
		if hb.team_is_player:
			continue
		var health: HealthComponent = hb.get_node_or_null(hb.health_path) as HealthComponent
		if health:
			health.take_damage(def.aura_tick_damage)
	var sf := SpellIcons.get_sprite_frames_for_def(def)
	if sf and vfx_root:
		var loop := AnimatedSprite2D.new()
		loop.sprite_frames = sf
		loop.animation = &"default"
		var s := def.aura_radius / 80.0
		loop.scale = Vector2(s, s)
		vfx_root.add_child(loop)
		loop.global_position = origin.global_position
		loop.z_index = 1
		loop.play()
		var twl := loop.create_tween()
		twl.tween_property(loop, ^"modulate:a", 0.0, def.aura_duration)
		twl.finished.connect(loop.queue_free)
	# Simple VFX ring
	var ring := Line2D.new()
	ring.width = 2.0
	var pts: PackedVector2Array = []
	var segs := 24
	for i in range(segs + 1):
		var t := float(i) / float(segs) * TAU
		pts.append(Vector2(cos(t), sin(t)) * def.aura_radius)
	ring.points = pts
	ring.default_color = Color(0.4, 0.8, 1.0, 0.7)
	vfx_root.add_child(ring)
	ring.global_position = origin.global_position
	var tw := ring.create_tween()
	tw.tween_property(ring, ^"modulate:a", 0.0, def.aura_duration)
	tw.finished.connect(ring.queue_free)
