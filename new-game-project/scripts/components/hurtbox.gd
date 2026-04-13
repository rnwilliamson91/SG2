class_name Hurtbox
extends Area2D
## Receives hits from opposing projectiles / hazards. Owner must have HealthComponent.

@export var health_path: NodePath
@export var team_is_player: bool = true

var _health: HealthComponent


func _ready() -> void:
	_health = get_node_or_null(health_path) as HealthComponent
	if _health == null:
		push_error("Hurtbox: set health_path to HealthComponent.")
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if not (area is Hitbox):
		return
	var hb := area as Hitbox
	if hb.team_is_player == team_is_player:
		return
	if _health:
		_health.take_damage(hb.damage)
		if team_is_player:
			Events.player_damaged.emit(hb.damage)
