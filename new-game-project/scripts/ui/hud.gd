extends Control
## HP, time, XP/level, weapon slots (auto), loadout summary.

@onready var _health_label: Label = $MarginContainer/VBox/HealthLabel
@onready var _time_label: Label = $MarginContainer/VBox/TimeLabel
@onready var _xp_label: Label = $MarginContainer/VBox/XpLevelLabel
@onready var _weapons_label: Label = $MarginContainer/VBox/WeaponsLabel
@onready var _progress: Label = $MarginContainer/VBox/ProgressLabel
@onready var _game_over: Label = $MarginContainer/VBox/GameOverLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	var p := get_tree().get_first_node_in_group(&"player") as CharacterBody2D
	if p:
		var h := p.get_node_or_null(^"Health") as HealthComponent
		var ac = p.get_node_or_null(^"AbilityController") as AbilityController
		if h:
			_health_label.text = "HP: %.0f / %.0f" % [h.current_health, h.max_health]
		if ac:
			_weapons_label.text = _weapons_block(ac)
		if _progress and ac:
			_progress.text = SpellProgress.format_progress_summary(ac)
	_xp_label.text = "Lv %d   XP %.0f / %.0f" % [
		Run.player_level,
		Run.xp,
		Run.xp_for_next_level(),
	]
	_time_label.text = "Time: %.1f s   Stage: %d" % [Run.time_survived, Run.difficulty_stage]
	_game_over.visible = Run.is_game_over


func _weapons_block(ac: AbilityController) -> String:
	var lines: PackedStringArray = []
	for i in range(ac.MAX_WEAPON_SLOTS):
		var def = ac.get_ability(i) as AbilityDef
		if def == null:
			lines.append("%d: —" % (i + 1))
			continue
		var rem := ac.get_cooldown_remaining(i)
		var lv := SpellProgress.get_level(def.id)
		if rem > 0.0:
			lines.append("%d: %s  Lv.%d  %.1fs" % [i + 1, def.display_name, lv, rem])
		else:
			lines.append("%d: %s  Lv.%d  ready" % [i + 1, def.display_name, lv])
	return "\n".join(lines)
