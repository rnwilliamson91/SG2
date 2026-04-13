extends Area2D
## Periodic damage while overlapping the player hurtbox.

@export var damage_per_tick: float = 8.0
@export var tick_interval: float = 0.45

var _cooldown: float = 0.0


func _ready() -> void:
	collision_layer = GameLayers.MOB_BODY
	collision_mask = GameLayers.PLAYER_HURTBOX
	monitoring = true
	monitorable = true


func _physics_process(delta: float) -> void:
	if Run.is_paused or Run.is_game_over:
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _cooldown > 0.0:
		return
	for a in get_overlapping_areas():
		if a is Hurtbox and (a as Hurtbox).team_is_player:
			var hb := a as Hurtbox
			var health := hb.get_node_or_null(hb.health_path) as HealthComponent
			if health:
				health.take_damage(damage_per_tick)
				Events.player_damaged.emit(damage_per_tick)
			_cooldown = tick_interval
			return
