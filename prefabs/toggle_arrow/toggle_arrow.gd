extends Button
class_name ToggleArrow

signal toggle

export var toggled: bool = false
export(String, "right", "left", "up", "down") var direction: String = "right"

const ARROW_RIGHT: StreamTexture = preload("res://shared/icons/arrow/arrow_right.png")
const ARROW_LEFT: StreamTexture = preload("res://shared/icons/arrow/arrow_left.png")
const ARROW_UP: StreamTexture = preload("res://shared/icons/arrow/arrow_up.png")
const ARROW_DOWN: StreamTexture = preload("res://shared/icons/arrow/arrow_down.png")
const _direction_map: Dictionary = {
	"right": [ARROW_RIGHT, ARROW_LEFT],
	"left": [ARROW_LEFT, ARROW_RIGHT],
	"up": [ARROW_UP, ARROW_DOWN],
	"down": [ARROW_DOWN, ARROW_UP]
}

func _ready():
	connect("pressed", self, "_on_pressed")
	_update_icon()

func _on_pressed():
	toggled = !toggled
	emit_signal("toggle", toggled)
	_update_icon()

func _update_icon():
	if (!toggled):
		$Arrow.texture = _direction_map[direction][0]
	else:
		$Arrow.texture = _direction_map[direction][1]
