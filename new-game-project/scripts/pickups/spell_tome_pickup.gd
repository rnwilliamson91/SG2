extends Area2D
## Rare drop: opens the same 1-of-4 spell UI as a level up.


func _ready() -> void:
	collision_layer = GameLayers.PICKUP
	collision_mask = GameLayers.PLAYER_BODY
	set_deferred(&"monitoring", true)
	set_deferred(&"monitorable", true)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	LevelUp.open_bonus_spell_pick()
	queue_free()
