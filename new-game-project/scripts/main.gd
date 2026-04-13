extends Node
## Root scene: owns pause input and coordinates high-level flow.

@onready var pause_overlay: Control = $UILayer/PauseOverlay
@onready var _pause_label: Label = $UILayer/PauseOverlay/PauseLabel


func _ready() -> void:
	Run.reset_run()
	SpellProgress.reset_for_new_run()
	pause_overlay.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	Events.player_died.connect(_on_player_died)


func _on_player_died() -> void:
	pause_overlay.visible = true
	_pause_label.text = "GAME OVER"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		if Run.choosing_upgrade:
			return
		if Run.is_game_over:
			return
		Run.toggle_pause()
		pause_overlay.visible = Run.is_paused
		if Run.is_paused:
			_pause_label.text = "PAUSED — ESC to resume"
		get_viewport().set_input_as_handled()
