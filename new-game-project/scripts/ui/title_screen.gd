extends Control
## Character pick then loads the main game scene.

const MAIN_SCENE := "res://scenes/main/main.tscn"

const CHARACTERS: Array[Dictionary] = [
	{"prefix": "ball_chain_bot", "label": "Ball & Chain Bot"},
	{"prefix": "manBlue", "label": "Survivor — Blue"},
	{"prefix": "manBrown", "label": "Survivor — Brown"},
	{"prefix": "manOld", "label": "Survivor — Veteran"},
	{"prefix": "womanGreen", "label": "Survivor — Green"},
	{"prefix": "soldier1", "label": "Soldier"},
	{"prefix": "survivor1", "label": "Survivor — Tan"},
	{"prefix": "hitman1", "label": "Hitman"},
	{"prefix": "robot1", "label": "Robot"},
	{"prefix": "zoimbie1", "label": "Zombie"},
]

@onready var _grid: GridContainer = $Center/VBox/Grid


func _ready() -> void:
	for c in CHARACTERS:
		var b := Button.new()
		b.text = str(c["label"])
		b.custom_minimum_size = Vector2(260, 40)
		b.pressed.connect(_on_character_pressed.bind(str(c["prefix"])))
		_grid.add_child(b)


func _on_character_pressed(prefix: String) -> void:
	Run.selected_character_prefix = prefix
	get_tree().change_scene_to_file(MAIN_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()
