extends Node
## Per-spell weapon level (from level-ups & rare tomes). Drives damage / CD scaling on AbilityController.

## weapon_level[id] = 1 first time acquired, +1 per upgrade pick.
var weapon_level: Dictionary = {}

signal weapon_level_changed(spell_id: StringName, new_level: int)


func get_level(spell_id: StringName) -> int:
	return int(weapon_level.get(spell_id, 0))


func set_level(spell_id: StringName, value: int) -> void:
	weapon_level[spell_id] = maxi(0, value)
	weapon_level_changed.emit(spell_id, value)


func add_level(spell_id: StringName, delta: int = 1) -> void:
	set_level(spell_id, get_level(spell_id) + delta)


func get_damage_multiplier(spell_id: StringName) -> float:
	var lv := get_level(spell_id)
	if lv < 1:
		return 1.0
	return pow(1.09, float(lv - 1))


func get_cooldown_multiplier(spell_id: StringName) -> float:
	var lv := get_level(spell_id)
	if lv < 1:
		return 1.0
	return pow(0.985, float(lv - 1))


func _notify_refresh() -> void:
	var p := get_tree().get_first_node_in_group(&"player")
	if p == null:
		return
	var ac = p.get_node_or_null(^"AbilityController") as AbilityController
	if ac and ac.has_method(&"refresh_from_progress"):
		ac.refresh_from_progress()


func apply_upgrade_and_refresh(spell_id: StringName) -> void:
	add_level(spell_id, 1)
	_notify_refresh()


func format_progress_summary(ac: AbilityController) -> String:
	var parts: PackedStringArray = []
	if ac != null:
		for i in range(ac.MAX_WEAPON_SLOTS):
			var id := ac.get_equipped_id(i)
			if id == StringName() or str(id).is_empty():
				continue
			var lv := get_level(id)
			parts.append("%s Lv.%d" % [String(id), lv])
	if parts.is_empty():
		return "Weapons: (none yet — level up!)"
	return "Weapons: " + ", ".join(parts)


func reset_for_new_run() -> void:
	weapon_level.clear()
