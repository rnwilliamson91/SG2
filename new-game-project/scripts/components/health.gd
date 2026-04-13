class_name HealthComponent
extends Node
## Tracks HP; attach to player or mobs.

signal died
signal health_changed(current: float, max_health: float)

@export var max_health: float = 100.0
var current_health: float
## If > current time (sec), take_damage is ignored.
var invulnerable_until_sec: float = -1.0


func _ready() -> void:
	current_health = max_health


func take_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	var t := Time.get_ticks_msec() / 1000.0
	if invulnerable_until_sec > t:
		return
	current_health = maxf(current_health - amount, 0.0)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		died.emit()


func heal(amount: float) -> void:
	if amount <= 0.0:
		return
	current_health = minf(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
