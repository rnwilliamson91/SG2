extends Node
## Registers WASD and ability keys if missing (keeps project.godot small).


func _ready() -> void:
	_bind_key(&"move_left", KEY_A)
	_bind_key(&"move_right", KEY_D)
	_bind_key(&"move_up", KEY_W)
	_bind_key(&"move_down", KEY_S)
	_bind_key(&"dash", KEY_SHIFT)
	_bind_key(&"shrapnel_burst", KEY_SPACE)


func _bind_key(action: StringName, code: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for e in InputMap.action_get_events(action):
		if e is InputEventKey and (e as InputEventKey).physical_keycode == code:
			return
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	InputMap.action_add_event(action, ev)
