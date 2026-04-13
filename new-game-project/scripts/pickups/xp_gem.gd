extends Area2D
## XP pickup (green gem).


func _ready() -> void:
	collision_layer = GameLayers.PICKUP
	collision_mask = GameLayers.PLAYER_BODY
	# Spawns from mob death inside area callbacks — defer so physics isn't mid-flush.
	set_deferred(&"monitoring", true)
	set_deferred(&"monitorable", true)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	Events.xp_gained.emit(3.0)
	queue_free()
