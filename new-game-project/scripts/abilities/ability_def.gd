class_name AbilityDef
extends Resource
## Data-only definition for skills and spells (shared pipeline).

enum CastKind { INSTANT, GROUND_TARGET, CHANNELED }
enum DeliveryKind {
	SPAWN_SCENE,
	CONE_INSTANT,
	AURA_SELF,
	KINETIC_ANCHOR,
	ECHO_PAST,
	MAGNETIC_SCRAP,
	BLOOD_TRAIL_GLIDER,
	NEWTON_ORB,
}

@export var id: StringName
@export var display_name: String = "Ability"
## VFX pack folder under `Assets/Skills/VFX Free Pack/` (e.g. `Effect_Charged`). Empty = use [SpellIcons] mapping by spell id / delivery.
@export var icon_effect: String = ""
## Echo / Scrap / Trail run as passives (no auto-fire cooldown).
@export var passive_only: bool = false
@export var cooldown: float = 0.5
@export var mana_cost: float = 0.0
@export var cast_time: float = 0.0
@export var cast_kind: CastKind = CastKind.INSTANT
@export var delivery: DeliveryKind = DeliveryKind.SPAWN_SCENE
@export var projectile_scene: PackedScene
## Used when delivery is SPAWN_SCENE (overrides projectile scene Hitbox.damage when set).
@export var projectile_damage: float = 12.0
@export var cone_range: float = 120.0
@export var cone_arc_degrees: float = 45.0
@export var cone_damage: float = 8.0
@export var aura_radius: float = 80.0
@export var aura_tick_damage: float = 5.0
@export var aura_duration: float = 0.4

# Kinetic Anchor
@export var anchor_spawn_radius: float = 220.0
@export var anchor_tether_radius: float = 115.0
@export var anchor_snap_delay: float = 3.0
@export var anchor_pull_speed: float = 55.0
@export var anchor_cluster_offset: float = 96.0

# Echo of the Past
@export var echo_delay_sec: float = 4.0
@export var echo_burst_interval: float = 0.38
@export var echo_burst_radius: float = 88.0
@export var echo_burst_damage: float = 22.0

# Magnetic Scrap
@export var scrap_max_pieces: int = 20
@export var scrap_orbit_radius: float = 95.0
@export var scrap_orbit_speed: float = 2.1
@export var scrap_shrapnel_cooldown: float = 14.0
@export var scrap_shrapnel_damage_per_piece: float = 4.0

# Blood-Trail Glider
@export var trail_drop_interval: float = 0.1
@export var trail_hazard_radius: float = 26.0
@export var trail_dot_per_sec: float = 7.0
@export var trail_slow_scale: float = 0.5
@export var trail_boost_speed_mult: float = 2.0
@export var trail_invuln_sec: float = 0.4

# Newton's Cradle orb
@export var newton_speed: float = 210.0
@export var newton_hit_radius: float = 18.0
@export var newton_knockback: float = 340.0
@export var newton_scale_per_bounce: float = 1.1
