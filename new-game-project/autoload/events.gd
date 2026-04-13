@warning_ignore("unused_signal")
extends Node
## Global signal bus — decouples UI and systems from entities.
## Signals are emitted/connected from other scripts; unused_signal is intentional here.

signal enemy_died(mob: Node2D)
signal player_damaged(amount: float)
signal xp_gained(amount: float)
signal level_up(new_level: int)
signal player_dashed(world_pos: Vector2, direction: Vector2)
signal player_died
