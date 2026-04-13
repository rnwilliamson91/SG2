class_name WaveTierDef
extends Resource
## One difficulty band for SpawnDirector: which mobs spawn and how often.

@export var tier_index: int = 0
@export var label: String = "Tier 1"
@export var spawn_interval: float = 2.0
@export var mobs: Array[PackedScene] = []
@export var weights: Array[float] = []
