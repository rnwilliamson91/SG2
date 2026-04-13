class_name GameLayers
extends Object
## Bit masks matching project 2D physics layer order (1–8).

const WORLD := 1 << 0
const PLAYER_BODY := 1 << 1
const MOB_BODY := 1 << 2
const PLAYER_HURTBOX := 1 << 3
const MOB_HURTBOX := 1 << 4
const PROJECTILE_PLAYER := 1 << 5
const PROJECTILE_ENEMY := 1 << 6
const PICKUP := 1 << 7
