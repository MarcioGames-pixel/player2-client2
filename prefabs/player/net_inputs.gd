extends Node

# Used for sending clicks and key presses to the server
# player input handling is in player_local.gd

const CLICK_RANGE: float = 1000.0
onready var player: PlayerLocal = get_parent()

func _handle_click(event):
	# Send click packet
	var click_packet: AdaptedPacket = AdaptedPacket.new(NetID.OUTGOING_INPUT)
	click_packet.put_8(1)
	click_packet.put_string_nt("")
	player.net.send(click_packet)
	
	# Check if clicked on brick
	var camera: Camera = player.controller.get_camera()
	var from: Vector3 = camera.project_ray_origin(event.position)
	var to: Vector3 = from + camera.project_ray_normal(event.position) * CLICK_RANGE
	var space_state: PhysicsDirectSpaceState = player.get_world().get_direct_space_state()
	var result: Dictionary = space_state.intersect_ray(from, to, get_tree().get_nodes_in_group("character"))
	if (!result.has("collider")): return
	var check_node: Spatial = result.collider.get_parent()
	if (check_node == null): return
	if (check_node.is_in_group("part")): # Brick click
		if (check_node.click_distance <= 0 || check_node.net_id == -1): return
		var click_brick_packet: AdaptedPacket = AdaptedPacket.new(NetID.OUTGOING_BRICK_CLICK)
		click_brick_packet.put_32(check_node.net_id)
		player.net.send(click_brick_packet)
		return

func _unhandled_input(event):
	# Click detection
	if (event is InputEventMouseButton && BrickHill.game_mode == BrickHill.MODE_DESKTOP):
		if (event.button_index == BUTTON_LEFT && event.pressed): _handle_click(event)
	# Tap
	elif (event is InputEventScreenTouch && BrickHill.game_mode == BrickHill.MODE_MOBILE):
		if (!event.pressed): _handle_click(event)
	# Key
	elif (event is InputEventKey):
		if (!event.pressed): return
		var key_str: String = ""
		# Check for special keys
		match(event.scancode):
			KEY_ENTER: key_str = "enter"
			KEY_SPACE: key_str = "space"
			KEY_SHIFT: key_str = "shift"
			KEY_CONTROL: key_str = "control"
			KEY_BACKSPACE: key_str = "backspace"
		# Filter input
		if (key_str == ""):
			if ((event.scancode >= 48 && event.scancode <= 57) ||
			(event.scancode >= 65 && event.scancode <= 90)):
				key_str = char(event.scancode)
		# Send packet
		if (key_str == ""): return
		var key_packet: AdaptedPacket = AdaptedPacket.new(NetID.OUTGOING_INPUT)
		key_packet.put_8(0)
		key_packet.put_string_nt(key_str)
		player.net.send(key_packet)
