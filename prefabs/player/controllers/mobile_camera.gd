extends Position3D

const BASE_MOTION_SPEED: float = 0.01
const BASE_ZOOM_SPEED: float = 1.0
const MAX_ZOOM: float = 64.0
const OFFSET: Vector3 = Vector3(0, 4.5, 0)
export var motion_speed: float = 1.0
export var zoom_speed: float = 1.0
export var zoom: float = 8.0 setget set_zoom
var player
var captured: bool = false

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

func _update_rig():
	global_transform.origin = player.global_transform.origin + OFFSET * player.scale
	var average_scale: float = (player.scale.x + player.scale.y + player.scale.z) / 3
	scale = Vector3(average_scale, average_scale, average_scale)
	player.walk_angle = $SpringArm/Camera.global_transform.basis.get_euler().y

func _process(delta):
	# Zoom intrepolate
	if (zoom == 0):
		$SpringArm.spring_length = 0
	else:
		$SpringArm.spring_length = lerp($SpringArm.spring_length, zoom, delta * 8)
	_update_rig()

func _unhandled_input(event):
	if (event is InputEventScreenDrag):
		return
		if (event.position.x >= $"../Control".get_rect().size.x / 2.0):
			var dif = event.get_relative() * -1
			rotation.y += dif.x * BASE_MOTION_SPEED * motion_speed
			rotation.x = clamp(rotation.x - dif.y * BASE_MOTION_SPEED * motion_speed, deg2rad(-89), deg2rad(89))
			if (player.first_person): player.avatar.rotation.y = rotation.y
			#get_tree().set_input_as_handled()
	elif (event is InputEventMagnifyGesture):
		set_zoom(zoom + ((event.factor - 1.0) * 5.0 * BASE_ZOOM_SPEED * zoom_speed))
