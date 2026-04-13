class_name MobDef
extends Resource
## Designer-tunable mob stats (optional; scenes can override).

@export var id: StringName
@export var display_name: String = "Mob"
@export var max_health: float = 30.0
@export var move_speed: float = 90.0
@export var tier: int = 0
