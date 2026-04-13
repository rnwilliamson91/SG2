@icon("res://addons/sudden_auto_collision_shape_sprite2d_plugin/plugin-icon2.png")

@tool
class_name SuddenSprite2D
extends Sprite2D

## A Sprite2D that generates collision polygons for its texture at runtime and 
## in editor.
signal area_entered(area : Area2D)
signal visible_collision_polygons_changed(new_value)

## SuddenSprite2D's collision layers
@export_flags_2d_physics var collision_layer : int = 1

## SuddenSprite2D's collision masks
@export_flags_2d_physics var collision_mask  : int = 1

## Specify if the collision polygons should be visible on the Editor.
@export var visible_collision_polygons = false:
	set(value):
		visible_collision_polygons = value
		visible_collision_polygons_changed.emit(value)

var area2d : Area2D

var collision_polygons = []

var node_ready = false
var done = false

func _ready() -> void:
	create_collision_shape_from_sprite()
	_set_layer_and_mask.call_deferred()
	add_child.call_deferred(area2d)
	visible_collision_polygons_changed.connect(_on_visible_collision_polygons_changed)
	
func create_collision_shape_from_sprite():
	var img = texture.get_image()
	var bmp = BitMap.new()
	bmp.create_from_image_alpha(img)

	var polygons = bmp.opaque_to_polygons(Rect2(Vector2.ZERO, img.get_size()))
	area2d = Area2D.new()
	area2d.area_entered.connect(_has_collided)
	
	for p in polygons:
		var collision : CollisionPolygon2D = CollisionPolygon2D.new()
		collision.polygon = p
		collision.position = -img.get_size() / 2
		collision_polygons.append(collision)
		area2d.add_child(collision)	
		
func _set_layer_and_mask():
	area2d.collision_layer = collision_layer
	area2d.collision_mask = collision_mask
	
func get_overlapping_areas():
	return area2d.get_overlapping_areas()
	
func get_overlapping_bodies():
	return area2d.get_overlapping_bodies()

func _on_visible_collision_polygons_changed(value):
	area2d.visible = value

func _has_collided(area):
	emit_signal("area_entered", area)
