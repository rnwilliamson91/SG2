extends Node
## Run state: time survived, pause, game over, XP / level (Vampire Survivors–style).

## Kenney atlas prefix (e.g. `manBlue`) — set from title screen before [code]main[/code] loads.
var selected_character_prefix: String = "manBlue"

var time_survived: float = 0.0
var difficulty_stage: int = 0
var is_game_over: bool = false
var is_paused: bool = false
## True while the level-up / spell tome UI is open (blocks manual pause).
var choosing_upgrade: bool = false

var player_level: int = 1
var xp: float = 0.0


func _ready() -> void:
	Events.xp_gained.connect(_on_xp_gained)


func _on_xp_gained(amount: float) -> void:
	add_xp(amount)


func xp_for_next_level() -> float:
	return 8.0 + 6.0 * float(player_level)


func add_xp(amount: float) -> void:
	if is_game_over:
		return
	xp += amount
	while xp >= xp_for_next_level():
		xp -= xp_for_next_level()
		player_level += 1
		Events.level_up.emit(player_level)


func _process(delta: float) -> void:
	if is_game_over or is_paused:
		return
	time_survived += delta


func set_paused(value: bool) -> void:
	is_paused = value
	get_tree().paused = value


func toggle_pause() -> void:
	if is_game_over or choosing_upgrade:
		return
	set_paused(not is_paused)


func game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	set_paused(true)
	Events.player_died.emit()


func reset_run() -> void:
	time_survived = 0.0
	difficulty_stage = 0
	is_game_over = false
	is_paused = false
	choosing_upgrade = false
	player_level = 1
	xp = 0.0
	get_tree().paused = false
