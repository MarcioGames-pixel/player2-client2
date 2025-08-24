extends Position3D

const BASE_MOTION_SPEED: float = 0.005
const BASE_ZOOM_SPEED: float = 1.0
const MAX_ZOOM: float = 64.0
const OFFSET: Vector3 = Vector3(0, 4.5, 0)
export var motion_speed: float = 1.0
export var zoom_speed: float = 1.0
export var zoom: float = 8.0 setget set_zoom
var player
var captured: bool = false
var original_cursor_pos: Vector2

func _enter_tree():
	player = get_parent().player

func _ready():
	# Initial zoom
	set_as_toplevel(true)

func set_zoom(val: float):
	# Clamp
	var release: bool = (zoom == 0)
	zoom = clamp(val, 0, MAX_ZOOM)
	player.first_person = (zoom == 0)
	if (player.first_person):
		mouse_capture()
	elif (release):
		mouse_release()

func _update_rig():
	global_transform.origin = player.global_transform.origin + OFFSET * player.scale
	var average_scale: float = (player.scale.x + player.scale.y + player.scale.z) / 3
	scale = Vector3(average_scale, average_scale, average_scale)
	player.walk_angle = $SpringArm/Camera.global_transform.basis.get_euler().y

func mouse_capture():
	captured = true
	original_cursor_pos = get_viewport().get_mouse_position()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func mouse_release():
	captured = false
	if (Input.get_mouse_mode() == Input.MOUSE_MODE_HIDDEN):
		get_viewport().warp_mouse(original_cursor_pos)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta):
	# Zoom intrepolate
	if (zoom == 0):
		$SpringArm.spring_length = 0
	else:
		$SpringArm.spring_length = lerp($SpringArm.spring_length, zoom, delta * 8)
	_update_rig()

func _unhandled_input(event):
	if (event is InputEventMouseButton):
		# Capture
		if (event.button_index == BUTTON_RIGHT):
			if (!player.first_person):
				captured = event.is_pressed()
				if (captured):
					mouse_capture()
				else:
					mouse_release()
				get_tree().set_input_as_handled()
		# Zoom in
		elif (event.button_index == BUTTON_WHEEL_UP):
			set_zoom(zoom - BASE_ZOOM_SPEED * zoom_speed)
		# Zoom out
		elif (event.button_index == BUTTON_WHEEL_DOWN):
			set_zoom(zoom + BASE_ZOOM_SPEED * zoom_speed)
	elif (event is InputEventPanGesture):
		set_zoom(zoom + event.delta.y)
	elif (event is InputEventMagnifyGesture):
		set_zoom(zoom + ((event.factor - 1.0) * 5.0 * BASE_ZOOM_SPEED * zoom_speed))
	elif (event is InputEventMouseMotion):
		# Rotate camera
		if (captured):
			if (Input.get_mouse_mode() != Input.MOUSE_MODE_HIDDEN):
				if (player.first_person):
					Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
					original_cursor_pos = event.position
				else:
					captured = false
				return
			var dif = original_cursor_pos - event.position
			rotation.y += dif.x * BASE_MOTION_SPEED * motion_speed
			rotation.x = clamp(rotation.x - dif.y * BASE_MOTION_SPEED * motion_speed, deg2rad(-89), deg2rad(89))
			if (player.first_person): player.avatar.rotation.y = rotation.y
			get_viewport().warp_mouse(original_cursor_pos)
			get_tree().set_input_as_handled()
