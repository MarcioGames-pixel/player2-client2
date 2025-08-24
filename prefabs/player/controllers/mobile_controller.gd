extends Spatial

const AUTO_CAM_WAIT_TIME = 3000

enum {
	MODE_INACTIVE,
	MODE_TOUCH,
	MODE_KEYBOARD
}

onready var jump_button: TouchScreenButton = $UI/Jump/JumpInput
onready var camera: Position3D = $MobileCamera
var player
var input_mode: int = MODE_INACTIVE
var update_auto_cam: bool = false
var manual_cam_control: bool = false 
var last_input_tick: int = -1

func _enter_tree():
	player = get_parent()

func get_camera():
	return $MobileCamera/SpringArm/Camera

func _on_walk_input_start():
	if (input_mode == MODE_INACTIVE || input_mode == MODE_TOUCH):
		input_mode = MODE_TOUCH
		last_input_tick = OS.get_ticks_msec()
		update_auto_cam = false

func _on_walk_input_factor(factor: Vector2, angle: float):
	if (input_mode == MODE_TOUCH):
		player.input_vector = Vector3(factor.x, 0, factor.y)
		
		if (OS.get_ticks_msec() - last_input_tick > AUTO_CAM_WAIT_TIME):
			update_auto_cam = true

func _on_walk_input_end():
	if (input_mode == MODE_TOUCH):
		player.input_vector = Vector3.ZERO
		if (!$UI/DragInputs/Camera.active): input_mode = MODE_INACTIVE
		update_auto_cam = false

func _on_camera_input_relative(difference: Vector2):
	if (input_mode == MODE_INACTIVE || input_mode == MODE_TOUCH):
		input_mode = MODE_TOUCH
		manual_cam_control = true
		last_input_tick = OS.get_ticks_msec()
		camera.rotation.y += difference.x * camera.BASE_MOTION_SPEED * camera.motion_speed
		camera.rotation.x = clamp(camera.rotation.x - difference.y * camera.BASE_MOTION_SPEED * camera.motion_speed, deg2rad(-89), deg2rad(89))

func _on_camera_input_end():
	if (input_mode == MODE_TOUCH):
		if (!$UI/DragInputs/Walk.active): input_mode = MODE_INACTIVE
		manual_cam_control = false

func _physics_process(delta):
	# Auto camera rotate
	if (update_auto_cam && !manual_cam_control):
		var last_quat: Quat = Quat($MobileCamera.global_transform.basis)
		var target_quat: Quat = Quat(Vector3(camera.rotation.x, player.avatar.rotation.y, 0))
		var slerp_slerp_mmm: Quat = last_quat.slerp(target_quat, delta)
		$MobileCamera.global_transform.basis = Basis(slerp_slerp_mmm)
	
	# Jump controls
	if (player.game_ui.is_menu_open() || (player.game_ui && player.game_ui.get_focus_owner() != null)): return
	player.jumping = Input.is_action_pressed("jump") || jump_button.is_pressed()

func _unhandled_input(event):
	# Reset
	var key_inputs: Vector3 = Vector3.ZERO
	key_inputs.x -= Input.get_action_strength("move_left")
	key_inputs.x += Input.get_action_strength("move_right")
	key_inputs.z -= Input.get_action_strength("move_forward")
	key_inputs.z += Input.get_action_strength("move_backward")
	
	if (input_mode == MODE_INACTIVE):
		if (key_inputs.length() > 0 || Input.is_action_pressed("jump")): input_mode = MODE_KEYBOARD
	
	if (input_mode == MODE_KEYBOARD):
		if (key_inputs.length() == 0 && !Input.is_action_pressed("jump")): input_mode = MODE_INACTIVE
		
		player.input_vector = Vector3.ZERO
		if (player.game_ui.is_menu_open() || (player.game_ui && player.game_ui.get_focus_owner() != null)): return
		
		player.input_vector = key_inputs
