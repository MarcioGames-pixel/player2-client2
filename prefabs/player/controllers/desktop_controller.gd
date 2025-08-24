extends Spatial

var player

func _enter_tree():
	player = get_parent()

func get_camera():
	return $DesktopCamera/SpringArm/Camera

func _unhandled_input(event):
	# Reset
	player.input_vector = Vector3.ZERO
	player.jumping = false
	if (player.game_ui.is_menu_open() || (player.game_ui && player.game_ui.get_focus_owner() != null)): return
	
	# Jumping
	player.jumping = Input.is_action_pressed("jump")
	# X
	player.input_vector.x -= Input.get_action_strength("move_left")
	player.input_vector.x += Input.get_action_strength("move_right")
	# Z
	player.input_vector.z -= Input.get_action_strength("move_forward")
	player.input_vector.z += Input.get_action_strength("move_backward")
