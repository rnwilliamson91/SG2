extends Control
## Four-button choice UI; group "level_up_ui".

@onready var _title: Label = $Center/Panel/VBox/Title
@onready var _b1: Button = $Center/Panel/VBox/Grid/Button1
@onready var _b2: Button = $Center/Panel/VBox/Grid/Button2
@onready var _b3: Button = $Center/Panel/VBox/Grid/Button3
@onready var _b4: Button = $Center/Panel/VBox/Grid/Button4

var _buttons: Array[Button] = []


func _ready() -> void:
	add_to_group(&"level_up_ui")
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_buttons = [_b1, _b2, _b3, _b4]
	for i in _buttons.size():
		_buttons[i].pressed.connect(_on_pressed.bind(i))


func open_with_offers(title: String, offers: Array) -> void:
	_title.text = title
	for i in _buttons.size():
		if i < offers.size():
			var o: Dictionary = offers[i]
			var t: String = str(o.get(&"title", "?"))
			var r: int = int(o.get(&"rarity", SpellCatalog.Rarity.COMMON))
			var def := o.get(&"def") as AbilityDef
			var icon_tex: Texture2D = SpellIcons.get_icon_texture_for_def(def) if def else null
			_buttons[i].icon = icon_tex
			_buttons[i].text = _prefix_rarity(r) + t
			_buttons[i].visible = true
			_buttons[i].disabled = false
		else:
			_buttons[i].icon = null
			_buttons[i].visible = false
	visible = true


func _prefix_rarity(r: int) -> String:
	match r:
		SpellCatalog.Rarity.RARE:
			return "[RARE] "
		SpellCatalog.Rarity.UNCOMMON:
			return "[UNC] "
		_:
			return ""


func _on_pressed(index: int) -> void:
	visible = false
	for b in _buttons:
		b.disabled = true
	LevelUp.apply_choice(index)
