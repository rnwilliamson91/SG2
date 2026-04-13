@tool
extends SuddenSprite2D

## Example of how to get collisions feedback
## from a SuddenSprite2D.

func _on_area_entered(area: Area2D) -> void:
	print("Soldier detected :", area.get_parent().name)

func _process(delta: float) -> void:
	for a in get_overlapping_areas():
		print("Colliding with: ", a.get_parent().name)

	for b in get_overlapping_bodies():
		print("Colliding with: ", b.name)
