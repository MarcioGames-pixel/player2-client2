extends Panel
class_name ToolSelect

export var slot: int
export var index: int = -1 setget _set_index
export var selected: bool = false

signal press

func _ready():
	if (BrickHill.game_mode == BrickHill.MODE_MOBILE):
		rect_min_size = Vector2(96, 96)

func _set_index(val: int):
	index = val
	$Number.text = str(index)
	$Number.visible = (index > -1 && BrickHill.game_mode == BrickHill.MODE_DESKTOP)

func set_name(new_name: String):
	$Margins/Label.text = new_name

func select(val: bool):
	selected = val
	$Outline.visible = val

func _gui_input(event):
	if (event is InputEventMouseButton && event.button_index == BUTTON_LEFT && event.pressed):
		emit_signal("press")
