extends Node
## Queues Vampire Survivors–style pick-1-of-4 panels on level up and on rare spell tomes.

var rng := RandomNumberGenerator.new()
var _queued_titles: Array[String] = []
var _offers: Array[Dictionary] = []


func _ready() -> void:
	rng.randomize()
	Events.level_up.connect(_on_level_up)


func _on_level_up(_new_level: int) -> void:
	queue_level_up_panel()


func queue_level_up_panel() -> void:
	_queued_titles.append("LEVEL UP — choose one upgrade")
	call_deferred(&"_try_open_next")


func open_bonus_spell_pick() -> void:
	_queued_titles.append("RARE SPELL TOME — choose one")
	call_deferred(&"_try_open_next")


func grant_starter_weapon_if_empty() -> void:
	var ac = _get_ac() as AbilityController
	if ac == null or ac.has_any_weapon():
		return
	var pool := SpellCatalog.get_by_rarity(SpellCatalog.Rarity.COMMON)
	if pool.is_empty():
		return
	var def := pool[rng.randi() % pool.size()]
	if def:
		ac.apply_new_weapon(def.id)


func _get_ac():
	var p := get_tree().get_first_node_in_group(&"player")
	if p == null:
		return null
	return p.get_node_or_null(^"AbilityController") as AbilityController


func _try_open_next() -> void:
	if Run.is_game_over:
		_queued_titles.clear()
		return
	if Run.choosing_upgrade:
		return
	if _queued_titles.is_empty():
		return
	var title: String = _queued_titles[0]
	Run.choosing_upgrade = true
	get_tree().paused = true
	_offers = _build_offers()
	var ui := get_tree().get_first_node_in_group(&"level_up_ui")
	if ui and ui.has_method(&"open_with_offers"):
		ui.call(&"open_with_offers", title, _offers)
	else:
		push_warning("LevelUp: no level_up_ui in tree.")
		if _queued_titles.size() > 0:
			_queued_titles.remove_at(0)
		Run.choosing_upgrade = false
		get_tree().paused = false


func apply_choice(index: int) -> void:
	if index < 0 or index >= _offers.size():
		return
	var ac = _get_ac() as AbilityController
	if ac == null:
		return
	var o: Dictionary = _offers[index]
	var k := str(o.get(&"kind", &"new"))
	var sid: StringName = o.get(&"id", &"")
	if k == "upgrade":
		ac.apply_upgrade_weapon(sid)
	else:
		if not ac.apply_new_weapon(sid):
			ac.apply_upgrade_weapon(sid)
	if _queued_titles.size() > 0:
		_queued_titles.remove_at(0)
	if _queued_titles.is_empty():
		Run.choosing_upgrade = false
		get_tree().paused = false
	else:
		call_deferred(&"_try_open_next")


func _build_offers() -> Array[Dictionary]:
	var ac = _get_ac() as AbilityController
	var out: Array[Dictionary] = []
	for _i in 4:
		out.append(_roll_single_offer(ac))
	return out


func _roll_single_offer(ac):
	if ac == null:
		var fb = SpellCatalog.get_template(&"bolt") as AbilityDef
		if fb:
			return _mk_new(fb, SpellCatalog.Rarity.COMMON)
		return {}
	var r := SpellCatalog.roll_rarity(rng)
	var def = SpellCatalog.pick_random_by_rarity(r, rng) as AbilityDef
	if def == null:
		def = SpellCatalog.get_template(&"bolt") as AbilityDef
	if def == null:
		return {}
	var ctr: AbilityController = ac as AbilityController
	if ctr == null:
		return {}
	var id: StringName = def.id
	if ctr.is_equipped(id):
		return _mk_upgrade(def)
	if ctr.has_empty_weapon_slot():
		return _mk_new(def, r)
	var oid: StringName = ctr.random_equipped_id(rng)
	var odef = SpellCatalog.get_template(oid) as AbilityDef
	if odef:
		return _mk_upgrade(odef)
	return _mk_upgrade(def)


func _mk_new(def: AbilityDef, r: int) -> Dictionary:
	return {
		&"kind": &"new",
		&"id": def.id,
		&"def": def,
		&"title": "New: " + def.display_name,
		&"rarity": r,
	}


func _mk_upgrade(def: AbilityDef) -> Dictionary:
	return {
		&"kind": &"upgrade",
		&"id": def.id,
		&"def": def,
		&"title": "Upgrade: " + def.display_name + " +1",
		&"rarity": SpellCatalog.get_rarity(def.id),
	}
