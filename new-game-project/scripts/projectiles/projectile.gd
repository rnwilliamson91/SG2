extends Hitbox
## Player-fired projectile; pool-friendly via setup().

@export var speed: float = 480.0
@export var max_distance: float = 2000.0

var _direction: Vector2 = Vector2.RIGHT
var _travelled: float = 0.0
var _pool_key = null
var _recycled: bool = false


func _ready() -> void:
	team_is_player = true
	collision_layer = GameLayers.PROJECTILE_PLAYER
	collision_mask = GameLayers.MOB_HURTBOX
	area_entered.connect(_on_area_entered)


func setup(direction: Vector2, _from_player: bool, pool_scene = null, damage_override: float = -1.0) -> void:
	_recycled = false
	_pool_key = pool_scene
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	monitoring = true
	monitorable = true
	if damage_override >= 0.0:
		damage = damage_override
	_direction = direction.normalized()
	if _direction.length_squared() < 0.001:
		_direction = Vector2.RIGHT
	rotation = _direction.angle()
	_travelled = 0.0
	_reset_projectile_visual()


func _reset_projectile_visual() -> void:
	var vfx := get_node_or_null(^"VfxSprite") as AnimatedSprite2D
	var body := get_node_or_null(^"Body") as Polygon2D
	if vfx:
		vfx.visible = false
		vfx.stop()
	if body:
		body.visible = true


func apply_spell_visual(def: AbilityDef) -> void:
	if def == null:
		return
	var sf := SpellIcons.get_sprite_frames_for_def(def)
	var vfx := get_node_or_null(^"VfxSprite") as AnimatedSprite2D
	var body := get_node_or_null(^"Body") as Polygon2D
	if sf == null or vfx == null:
		return
	if body:
		body.visible = false
	vfx.sprite_frames = sf
	vfx.visible = true
	vfx.play(&"default")


func _physics_process(delta: float) -> void:
	if _recycled:
		return
	global_position += _direction * speed * delta
	_travelled += speed * delta
	if _travelled >= max_distance:
		_recycle()


func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		var hb := area as Hurtbox
		if not hb.team_is_player:
			_recycle()


func _recycle() -> void:
	if _recycled:
		return
	_recycled = true
	var pool = get_tree().get_first_node_in_group(&"projectile_pool") as ProjectilePool
	var key = _pool_key
	if pool == null or key == null:
		call_deferred(&"queue_free")
		return
	# Do not call_deferred(pool) — can still flush in the same physics step. Pool drains in _process only.
	pool.queue_return(key, self)
