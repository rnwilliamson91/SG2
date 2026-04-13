class_name AbilityController
extends Node
## Up to MAX_WEAPON_SLOTS spells (Vampire Survivors–style loadout). Auto-fires each toward nearest mob.

signal weapon_fired(slot: int)

const MAX_WEAPON_SLOTS := 6

@export var auto_cast: bool = true

## Parallel to slots — empty StringName means no weapon in that slot.
var equipped_ids: Array[StringName] = []

var _base_abilities: Array[AbilityDef] = []
var abilities: Array[AbilityDef] = []
var _cooldown_remaining: Array[float] = []
var _projectiles_root
var _vfx_root
var _pool
var _booted: bool = false

const _PASSIVE_SCENES: Dictionary = {
	&"echo_of_past": preload("res://scenes/abilities/echo_of_past_skill.tscn"),
	&"magnetic_scrap": preload("res://scenes/abilities/magnetic_scrap_skill.tscn"),
	&"blood_trail_glider": preload("res://scenes/abilities/blood_trail_skill.tscn"),
}
var _passive_nodes: Dictionary = {} # StringName -> Node


func _ready() -> void:
	equipped_ids.resize(MAX_WEAPON_SLOTS)
	for i in MAX_WEAPON_SLOTS:
		equipped_ids[i] = &""
	_base_abilities.resize(MAX_WEAPON_SLOTS)
	abilities.resize(MAX_WEAPON_SLOTS)
	for i in MAX_WEAPON_SLOTS:
		_base_abilities[i] = null
		abilities[i] = null
	_cooldown_remaining.clear()
	for _i in MAX_WEAPON_SLOTS:
		_cooldown_remaining.append(0.0)
	_resolve_world_refs()
	call_deferred(&"_deferred_boot")


func _deferred_boot() -> void:
	if _booted:
		return
	_booted = true
	LevelUp.grant_starter_weapon_if_empty()
	rebuild_loadout_arrays()
	for i in MAX_WEAPON_SLOTS:
		_cooldown_remaining[i] = float(i) * 0.12


func has_any_weapon() -> bool:
	for id in equipped_ids:
		if id != StringName() and not str(id).is_empty():
			return true
	return false


func has_empty_weapon_slot() -> bool:
	for id in equipped_ids:
		if id == StringName() or str(id).is_empty():
			return true
	return false


func first_empty_slot_index() -> int:
	for i in MAX_WEAPON_SLOTS:
		if equipped_ids[i] == StringName() or str(equipped_ids[i]).is_empty():
			return i
	return -1


func is_equipped(spell_id: StringName) -> bool:
	for id in equipped_ids:
		if id == spell_id:
			return true
	return false


func get_equipped_id(slot: int) -> StringName:
	if slot < 0 or slot >= MAX_WEAPON_SLOTS:
		return &""
	return equipped_ids[slot]


func random_equipped_id(rng: RandomNumberGenerator) -> StringName:
	var owned: Array[StringName] = []
	for id in equipped_ids:
		if id != StringName() and not str(id).is_empty():
			owned.append(id)
	if owned.is_empty():
		return &""
	return owned[rng.randi() % owned.size()]


func rebuild_loadout_arrays() -> void:
	for i in MAX_WEAPON_SLOTS:
		_base_abilities[i] = null
		abilities[i] = null
	for i in MAX_WEAPON_SLOTS:
		var id := equipped_ids[i]
		if id == StringName() or str(id).is_empty():
			continue
		var base = SpellCatalog.get_template(id) as AbilityDef
		if base == null:
			continue
		_base_abilities[i] = base
		abilities[i] = base.duplicate(true)
	while _cooldown_remaining.size() < MAX_WEAPON_SLOTS:
		_cooldown_remaining.append(0.0)
	refresh_from_progress()


func apply_new_weapon(spell_id: StringName) -> bool:
	var idx := first_empty_slot_index()
	if idx < 0:
		return false
	equipped_ids[idx] = spell_id
	if SpellProgress.get_level(spell_id) < 1:
		SpellProgress.set_level(spell_id, 1)
	rebuild_loadout_arrays()
	return true


func apply_upgrade_weapon(spell_id: StringName) -> void:
	SpellProgress.add_level(spell_id, 1)
	rebuild_loadout_arrays()


func refresh_from_progress() -> void:
	for i in MAX_WEAPON_SLOTS:
		var base := _base_abilities[i] as AbilityDef
		if base == null:
			abilities[i] = null
			continue
		var id := base.id
		var dm := SpellProgress.get_damage_multiplier(id)
		var cm := SpellProgress.get_cooldown_multiplier(id)
		var cur := base.duplicate(true)
		cur.cooldown = maxf(0.08, cur.cooldown * cm)
		cur.cone_damage *= dm
		cur.cone_range *= sqrt(dm)
		cur.aura_tick_damage *= dm
		cur.aura_radius *= sqrt(dm)
		cur.projectile_damage *= dm
		cur.echo_burst_damage *= dm
		cur.echo_burst_radius *= sqrt(dm)
		cur.scrap_shrapnel_damage_per_piece *= dm
		cur.trail_dot_per_sec *= dm
		cur.newton_knockback *= sqrt(dm)
		cur.anchor_pull_speed *= sqrt(dm)
		cur.anchor_tether_radius *= sqrt(dm)
		abilities[i] = cur
		if i < _cooldown_remaining.size() and abilities[i]:
			_cooldown_remaining[i] = minf(_cooldown_remaining[i], cur.cooldown)
	_sync_passive_skills()


func _ability_for_id(spell_id: StringName):
	for i in MAX_WEAPON_SLOTS:
		if equipped_ids[i] == spell_id and abilities[i]:
			return abilities[i]
	return null


func _sync_passive_skills() -> void:
	var player := get_parent() as Node2D
	if player == null:
		return
	var vfx := get_tree().get_first_node_in_group(&"world_vfx") as Node2D
	var echo_parent: Node2D = vfx if vfx else player
	_sync_one_passive(&"echo_of_past", echo_parent, player)
	_sync_one_passive(&"magnetic_scrap", player, player)
	_sync_one_passive(&"blood_trail_glider", player, player)


func _sync_one_passive(id: StringName, parent: Node2D, player: Node2D) -> void:
	if not is_equipped(id):
		if _passive_nodes.has(id):
			var old: Node = _passive_nodes[id] as Node
			if is_instance_valid(old):
				old.queue_free()
			_passive_nodes.erase(id)
		return
	if parent == null:
		return
	var existing: Node = _passive_nodes.get(id, null) as Node
	if existing != null and is_instance_valid(existing):
		return
	var scn: PackedScene = _PASSIVE_SCENES.get(id) as PackedScene
	if scn == null:
		return
	var def = _ability_for_id(id) as AbilityDef
	if def == null:
		return
	var inst := scn.instantiate()
	parent.add_child(inst)
	if id == &"echo_of_past" and inst.has_method(&"configure"):
		inst.call(&"configure", def, player)
	elif inst.has_method(&"configure"):
		inst.call(&"configure", def)
	_passive_nodes[id] = inst


func _resolve_world_refs() -> void:
	_projectiles_root = get_tree().get_first_node_in_group(&"world_projectiles") as Node2D
	_vfx_root = get_tree().get_first_node_in_group(&"world_vfx") as Node2D
	_pool = get_tree().get_first_node_in_group(&"projectile_pool") as ProjectilePool


func _process(delta: float) -> void:
	for i in _cooldown_remaining.size():
		if _cooldown_remaining[i] > 0.0:
			_cooldown_remaining[i] = maxf(_cooldown_remaining[i] - delta, 0.0)
	if Run.is_paused or Run.is_game_over or Run.choosing_upgrade:
		return
	if not auto_cast:
		return
	for i in MAX_WEAPON_SLOTS:
		if abilities[i] == null:
			continue
		if abilities[i].passive_only:
			continue
		if i >= _cooldown_remaining.size():
			continue
		if _cooldown_remaining[i] > 0.0:
			continue
		try_activate_slot(i, true)


func _get_auto_aim_point(origin: Node2D) -> Vector2:
	var best_d := 1.0e12
	var best := origin.get_global_mouse_position()
	for n in get_tree().get_nodes_in_group(&"mobs"):
		if n is Node2D and is_instance_valid(n):
			var mp := (n as Node2D).global_position
			var d := origin.global_position.distance_squared_to(mp)
			if d < best_d:
				best_d = d
				best = mp
	return best


func try_activate_slot(slot: int, use_auto_aim: bool = false) -> bool:
	if Run.is_paused or Run.is_game_over:
		return false
	if _projectiles_root == null or _vfx_root == null:
		_resolve_world_refs()
	if slot < 0 or slot >= MAX_WEAPON_SLOTS:
		return false
	if slot >= _cooldown_remaining.size():
		return false
	if _cooldown_remaining[slot] > 0.0:
		return false
	var def := abilities[slot] as AbilityDef
	if def == null or def.passive_only:
		return false
	var origin := get_parent() as Node2D
	if origin == null:
		return false
	var target := _get_auto_aim_point(origin) if use_auto_aim else origin.get_global_mouse_position()
	AbilityExecutors.execute(def, origin, target, _projectiles_root, _vfx_root, _pool)
	_cooldown_remaining[slot] = def.cooldown
	weapon_fired.emit(slot)
	return true


func get_cooldown_ratio(slot: int) -> float:
	if slot < 0 or slot >= MAX_WEAPON_SLOTS:
		return 0.0
	var def := abilities[slot] as AbilityDef
	if def == null or def.cooldown <= 0.0:
		return 0.0
	return clampf(_cooldown_remaining[slot] / def.cooldown, 0.0, 1.0)


func get_cooldown_remaining(slot: int) -> float:
	if slot < 0 or slot >= _cooldown_remaining.size():
		return 0.0
	return _cooldown_remaining[slot]


func get_ability(slot: int):
	if slot < 0 or slot >= MAX_WEAPON_SLOTS:
		return null
	return abilities[slot] as AbilityDef
