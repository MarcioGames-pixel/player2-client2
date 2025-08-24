extends PlayerBase
class_name PlayerLocal

const DESKTOP_CONTROLLER = preload("res://prefabs/player/controllers/desktop_controller.tscn")
const MOBILE_CONTROLLER = preload("res://prefabs/player/controllers/mobile_controller.tscn")

var local: bool = true
var controller
var input_vector: Vector3 = Vector3.ZERO
var walk_angle: float = 0
var direction: Vector3 = Vector3.ZERO
var jumping: bool = false
var velocity: Vector3 = Vector3.ZERO
var first_person: bool = false setget set_first_person
var last_sync_pos: Vector3 = Vector3.ZERO
var moving: bool = false
var grounded: bool = false
var _landing_time: int = 0

func _ready():
	game_ui.connect("visibility_changed", self, "_on_vis_toggle")
	match(BrickHill.game_mode):
		BrickHill.MODE_DESKTOP:
			controller = DESKTOP_CONTROLLER.instance()
		BrickHill.MODE_MOBILE:
			controller = MOBILE_CONTROLLER.instance()
	add_child(controller)

func lerp_angle(from: float, to: float, weight: float) -> float:
	return from + short_angle_dist(from, to) * weight

func short_angle_dist(from: float, to: float) -> float:
	var difference = fmod(to - from, PI * 2)
	return fmod(2 * difference, PI * 2) - difference

func set_first_person(val: bool):
	first_person = val
	$PlayerUI/Crosshair.visible = val
	var update_list: Array = avatar.hats.values()
	update_list.append(avatar)
	if (val):
		for m in update_list:
			m.set_shadow_mode(MeshInstance.SHADOW_CASTING_SETTING_SHADOWS_ONLY)
	else:
		for m in update_list:
			m.set_shadow_mode(MeshInstance.SHADOW_CASTING_SETTING_ON)

func _on_vis_toggle():
	$PlayerUI.visible = game_ui.visible

func _send_update_packet():
	if (global_transform.origin.distance_to(last_sync_pos) >= 0.05):
		var update_packet: AdaptedPacket = AdaptedPacket.new(NetID.OUTGOING_PLAYER_UPDATE)
		update_packet.put_float(-global_transform.origin.x)
		update_packet.put_float(-global_transform.origin.z)
		update_packet.put_float(global_transform.origin.y)
		update_packet.put_float(rad2deg(avatar.rotation.y))
		update_packet.put_float(0) # x
		net.send(update_packet)
		last_sync_pos = global_transform.origin

func _physics_process(delta):
	# Freeze if dead
	if (dead): return
	
	# Reset
	velocity.x = 0
	velocity.z = 0
	moving = false
	
	# Prevents janky collisions near brick edges
	grounded = is_on_floor()
	#if (!grounded && velocity.y == 0):
	#	grounded = test_move(transform, Vector3(0, -0.01, 0))
	
	# Movement
	direction = input_vector.rotated(Vector3.UP, walk_angle)
	if (input_vector.x != 0 || input_vector.z != 0):
		# Direction
		velocity.x = direction.x * BASE_SPEED * speed
		velocity.z = direction.z * BASE_SPEED * speed
		
		moving = true
		
		# First person rotation is handled in camera_rig.gd
		if ((input_vector.x != 0 || input_vector.z != 0) && !first_person):
			avatar.rotation.y = lerp_angle(avatar.rotation.y, atan2(direction.x, direction.z) - rotation.y, delta * 16)
	
	# Gravity
	if (grounded):
		velocity.y = 0
		if (jumping):
			velocity.y = BASE_JUMP_POWER * jump_power
	else:
		if (velocity.y > 0 && is_on_ceiling()):
			velocity.y = 0
		else:
			velocity.y = lerp(velocity.y, -BASE_GRAVITY, delta * 2)
	
	# Auto step
	if (grounded && (input_vector.x != 0 || input_vector.z != 0)):
		var step_transform: Transform = global_transform
		var step_velocity: Vector3 = direction / 4
		if (test_move(global_transform, step_velocity)):
			for offset_base in range(0, 25):
				step_transform.origin.y += (0.1 * scale.y)
				if (!test_move(step_transform, step_velocity)):
					global_transform.origin.y = step_transform.origin.y + (0.1 * scale.y)
					break
	
	# Apply velocity
	var _slide = move_and_slide(velocity, Vector3.UP)
	
	_local_animate()

func _local_animate():
	if (grounded):
		var current_anim: int = avatar.get_animation()
		match current_anim:
			player_animations.FALLING:
				_landing_time = OS.get_ticks_msec()
				avatar.set_animation(player_animations.LANDING)
			player_animations.LANDING:
				var now: int = OS.get_ticks_msec()
				if (now - _landing_time >= 200):
					avatar.set_animation(player_animations.IDLE)
			_:
				if (moving):
					avatar.set_animation(player_animations.WALK)
				else:
					avatar.set_animation(player_animations.IDLE)
	else:
		if (velocity.y >= 1):
			avatar.set_animation(player_animations.JUMP)
		elif (!test_move(global_transform, Vector3(0, -4, 0))):
			avatar.set_animation(player_animations.FALLING)


func _block_raycast():
	var space_state = get_world().get_direct_space_state()
	for block_node in get_tree().get_nodes_in_group("block_raycast"):
		if (!block_node.visible && !block_node.position_blocked): continue
		var hit = space_state.intersect_ray(block_node.global_transform.origin, controller.get_camera().global_transform.origin)
		block_node.position_blocked = !!hit
