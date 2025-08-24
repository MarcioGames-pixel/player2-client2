extends Control
class_name Joystick

signal motion
const RADIUS: Vector2 = Vector2(192, 192)
const BOUNDS: float = 64.0
const CLICK_DIST: float = 128.0
onready var center: Vector2 = get_global_rect().position + (RADIUS / 2.0)
var captured: bool = false
var current_pos: Vector2 = Vector2.ZERO
var input: Vector2 = Vector2.ZERO
var press_count: int = 0

func in_bounds(pos: Vector2):
	return (pos.distance_to(center) <= BOUNDS)

func in_click_dist(pos: Vector2):
	return (pos.distance_to(center) <= CLICK_DIST)

func _input(event):
	if (event is InputEventScreenTouch):
		if (event.pressed):
			press_count += 1
			if (in_click_dist(event.position)):
				captured = true
		else:
			press_count -= 1
			if (captured && (press_count == 0 || in_click_dist(event.position))):
				captured = false
				$ButtonOffset/Button.rect_position = Vector2.ZERO
				input = Vector2.ZERO
				current_pos = Vector2.ZERO
				emit_signal("motion", input)
	elif (event is InputEventScreenDrag):
		if (captured && in_click_dist(event.position)):
			var dif: Vector2 = event.position - center
			$ButtonOffset/Button.rect_position = dif
			
			if (dif.length() > BOUNDS):
				$ButtonOffset/Button.rect_position = dif.normalized() * BOUNDS
			
			current_pos = $ButtonOffset/Button.rect_global_position
			input = $ButtonOffset/Button.rect_position / BOUNDS;
			emit_signal("motion", input)
