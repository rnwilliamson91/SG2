extends Area2D
## One collectible tied to a spell id (shard). Picked up by walking over it.

@export var ability_id: StringName = &"bolt"

var _colors := {
	&"bolt": Color(0.35, 0.85, 1.0),
	&"cone_blast": Color(1.0, 0.55, 0.2),
	&"nova": Color(0.75, 0.45, 1.0),
}


func _ready() -> void:
	collision_layer = GameLayers.PICKUP
	collision_mask = GameLayers.PLAYER_BODY
	set_deferred(&"monitoring", true)
	set_deferred(&"monitorable", true)
	body_entered.connect(_on_body_entered)
	_apply_color()


func setup_shard(id: StringName) -> void:
	ability_id = id
	_apply_color()


func _apply_color() -> void:
	var poly := get_node_or_null(^"Polygon2D") as Polygon2D
	if poly:
		poly.color = _colors.get(ability_id, Color.WHITE)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	SpellProgress.add_shards(ability_id, 1)
	queue_free()
