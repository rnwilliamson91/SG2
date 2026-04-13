extends Area2D

const SPEED = 300

func _process(delta) -> void:
	if Input.is_action_pressed("ui_left"):
		position += Vector2(-SPEED * delta, 0)
	if Input.is_action_pressed("ui_right"):
		position += Vector2(SPEED * delta, 0)
	if Input.is_action_pressed("ui_up"):
		position += Vector2(0, -SPEED * delta)
	if Input.is_action_pressed("ui_down"):
		position += Vector2(0, SPEED * delta)

func _on_area_entered(area: Area2D) -> void:
	print("Player detected :", area.get_parent().name)
