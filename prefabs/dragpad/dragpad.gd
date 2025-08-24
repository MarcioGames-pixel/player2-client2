extends Control

signal drag_factor
signal drag_relative
signal drag_start
signal drag_end
const DEADZONE: int = 8
export var use_indicator: bool = true
onready var indicator = $Indicator
var start_drag_position: Vector2 = Vector2.ZERO
var last_drag_position: Vector2 = Vector2.ZERO
var captured_drag_index: int = -1
var active: bool = false

func _ready():
	indicator.set_as_toplevel(true)

func in_bounds(point: Vector2) -> bool:
	return (point.x >= rect_global_position.x &&
		point.y >= rect_global_position.y &&
		point.x <= rect_global_position.x + rect_size.x &&
		point.y <= rect_global_position.y + rect_size.y)

func _input(event):
	if (event is InputEventScreenTouch):
		if (event.pressed && captured_drag_index == -1):
			if (in_bounds(event.position)):
				start_drag_position = event.position
				last_drag_position = event.position
				captured_drag_index = event.index
				indicator.points[0] = event.position
				indicator.points[1] = event.position
				if (use_indicator): indicator.show()
				active = true
				emit_signal("drag_start")
		else:
			if (captured_drag_index == event.index):
				captured_drag_index = -1
				indicator.hide()
				active = false
				emit_signal("drag_end")
	elif (event is InputEventScreenDrag):
		if (captured_drag_index == event.index):
			if (start_drag_position.distance_to(event.position) <= DEADZONE): return
			
			indicator.points[1] = event.position
			
			var difference: Vector2 = last_drag_position - event.position
			var factor = (event.position - start_drag_position) / (rect_size.x) * 4
			factor.x = clamp(factor.x, -1.0, 1.0)
			factor.y = clamp(factor.y, -1.0, 1.0)
			var angle: float = start_drag_position.angle_to(event.position)
			emit_signal("drag_relative", difference)
			emit_signal("drag_factor", factor, angle)
			last_drag_position = event.position
