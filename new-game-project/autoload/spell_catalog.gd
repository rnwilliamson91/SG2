extends Node
## All spells in the run with rarity for weighted level-up rolls (Vampire Survivors–style pool).

enum Rarity { COMMON, UNCOMMON, RARE }

## [resource_path, rarity]
const SPELL_ROWS: Array = [
	["res://data/abilities/bolt.tres", Rarity.COMMON],
	["res://data/abilities/knife_fan.tres", Rarity.COMMON],
	["res://data/abilities/cone.tres", Rarity.UNCOMMON],
	["res://data/abilities/ring_pulse.tres", Rarity.UNCOMMON],
	["res://data/abilities/aura.tres", Rarity.UNCOMMON],
	["res://data/abilities/meteor_cone.tres", Rarity.RARE],
	["res://data/abilities/kinetic_anchor.tres", Rarity.UNCOMMON],
	["res://data/abilities/newton_cradle.tres", Rarity.UNCOMMON],
	["res://data/abilities/echo_of_past.tres", Rarity.RARE],
	["res://data/abilities/magnetic_scrap.tres", Rarity.UNCOMMON],
	["res://data/abilities/blood_trail_glider.tres", Rarity.UNCOMMON],
]

var _by_id: Dictionary = {} # StringName -> AbilityDef (read-only template)
var _rarity_by_id: Dictionary = {} # StringName -> Rarity


func _ready() -> void:
	for row in SPELL_ROWS:
		var path: String = str(row[0])
		var r: int = int(row[1])
		var def := load(path) as AbilityDef
		if def:
			_by_id[def.id] = def
			_rarity_by_id[def.id] = r


func get_template(id: StringName):
	return _by_id.get(id) as AbilityDef


func list_all_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for k in _by_id.keys():
		out.append(k)
	return out


func get_rarity(id: StringName) -> Rarity:
	return int(_rarity_by_id.get(id, Rarity.COMMON)) as Rarity


func get_by_rarity(r: Rarity) -> Array[AbilityDef]:
	var out: Array[AbilityDef] = []
	for id in _rarity_by_id.keys():
		if int(_rarity_by_id[id]) != r:
			continue
		var d = get_template(id) as AbilityDef
		if d:
			out.append(d)
	return out


func pick_random_by_rarity(r: Rarity, rng: RandomNumberGenerator):
	var pool := get_by_rarity(r)
	if pool.is_empty():
		return null
	return pool[rng.randi() % pool.size()]


func roll_rarity(rng: RandomNumberGenerator) -> Rarity:
	var roll := rng.randf()
	if roll < 0.58:
		return Rarity.COMMON
	if roll < 0.88:
		return Rarity.UNCOMMON
	return Rarity.RARE
