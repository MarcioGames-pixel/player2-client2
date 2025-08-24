extends KinematicBody
class_name PlayerBase

signal health_update
const ICON_MINT: StreamTexture = preload("res://prefabs/player/icons/mint.png")
const ICON_ACE: StreamTexture = preload("res://prefabs/player/icons/ace.png")
const ICON_ROYAL: StreamTexture = preload("res://prefabs/player/icons/royal.png")
const ICON_ADMIN: StreamTexture = preload("res://prefabs/player/icons/admin.png")
const ICON_SPACEBUILDER: StreamTexture = preload("res://prefabs/player/icons/spacebuilder.png")
const ICON_LEON: StreamTexture = preload("res://prefabs/player/icons/leon.png")
const ICON_JAKE: StreamTexture = preload("res://prefabs/player/icons/jake.png")
const ICON_EZCHA : StreamTexture= preload("res://prefabs/player/icons/ezcha.png")
enum {
	MEMBERSHIP_NONE = 1,
	MEMBERSHIP_MINT = 2,
	MEMBERSHIP_ACE = 3,
	MEMBERSHIP_ROYAL = 4
}
const BASE_SPEED: float = 2.666
const BASE_GRAVITY: float = 80.0
const BASE_JUMP_POWER: float = 16.0
const MAX_HEALTH: float = 100.0
const CUSTOM_LIST_DATA: Dictionary = { # SECRET GO AWAY !!!!!!!!!
	2: { "color": Color("#C42727"), "icon": ICON_SPACEBUILDER },
	27: { "color": Color("#BF6952"), "icon": ICON_LEON },
	2760: { "color": Color("#42B9F5"), "icon": ICON_JAKE },
	23615: { "color": Color("#EC7465"), "icon": ICON_EZCHA }
}
export var user_id: int = 1
export var username: String = "Player"
export var admin: bool = false
export var membership: int = 0
export var speed: float = 4.0
export var jump_power: float = 5.0
export var speech: String = "" setget _set_speech
onready var avatar: Avatar = $Avatar
enum player_animations {
	IDLE,
	WALK,
	JUMP,
	FALLING,
	LANDING
}
var net: Net
var game_ui: GameUI
var health: float = 100.0
var score: int = 0
var team: int = 0
var dead: bool = false setget _set_dead
var net_id: int = -1
var prev_position = Vector3.ZERO
var frame_velocity = Vector3.ZERO
var list_icon: StreamTexture = null
var list_color: Color = Color.white
var last_pos: Vector3 = Vector3.ZERO

func _ready():
	avatar.set_as_toplevel(true)
	_list_prep()

func _physics_process(delta):
	_avatar_transform()
	_animate(delta)

func _avatar_transform():
	# Rotation and scale is handled elsewhere
	avatar.global_transform.origin = global_transform.origin

func _animate(delta: float):
	# Arm lerp
	var arm_blend: float = avatar.animation_tree["parameters/figure_tool/blend_amount"]
	if (avatar.arm_up && arm_blend < 1):
		arm_blend = lerp(arm_blend, 1, delta * 8)
		avatar.animation_tree["parameters/figure_tool/blend_amount"] = arm_blend
	elif (arm_blend > 0):
		arm_blend = lerp(arm_blend, 0, delta * 8)
		avatar.animation_tree["parameters/figure_tool/blend_amount"] = arm_blend
	
	if (is_local()): return
	
	var curr_frame_velocity = (global_transform.origin - prev_position) / delta
	frame_velocity = frame_velocity.linear_interpolate(curr_frame_velocity, 0.7)
	prev_position = global_transform.origin
	
	if (frame_velocity.y > 0.01): # Jumping:
		avatar.set_animation(player_animations.JUMP)
	elif (frame_velocity.y < -0.01): # Falling
		avatar.set_animation(player_animations.FALLING)
	elif (frame_velocity.abs() * Vector3(1, 0, 1)).length() < 0.1: # Not moving
		avatar.set_animation(player_animations.IDLE)
	else: # Moving
		avatar.set_animation(player_animations.WALK)

func is_local():
	return (get("local") != null)

func _set_speech(val: String):
	speech = val
	$SpeechBubble.text = val

func _set_dead(val: bool):
	dead = val
	visible = !val
	if (is_local() && val):
		game_ui.set_tool(0)

func _list_prep():
	if (CUSTOM_LIST_DATA.has(user_id)):
		var list_data: Dictionary = CUSTOM_LIST_DATA.get(user_id)
		list_color = list_data.color
		list_icon = list_data.icon
		return
	if (admin):
		list_color = Color("#FFFF00")
		list_icon = ICON_ADMIN
		return
	if (membership > 1):
		match(membership):
			MEMBERSHIP_MINT: list_icon = ICON_MINT
			MEMBERSHIP_ACE: list_icon = ICON_ACE
			MEMBERSHIP_ROYAL: list_icon = ICON_ROYAL
		return

func _handle_update_packet(packet: AdaptedPacket):
	# Check sub IDs
	var sub_id: String = packet.get_string_nt()
	for c in sub_id:
		match(c):
			"A":
				global_transform.origin.x = -packet.get_float()
			"B":
				global_transform.origin.z = -packet.get_float()
			"C":
				global_transform.origin.y = packet.get_float()
			"D":
				avatar.rotation.x = -deg2rad(packet.get_float())
			"E":
				avatar.rotation.z = -deg2rad(packet.get_float())
			"F":
				avatar.rotation.y = deg2rad(packet.get_float())
			"G":
				scale.x = packet.get_float()
				avatar.scale.x = scale.x
			"H":
				scale.y = packet.get_float()
				avatar.scale.y = scale.y
			"I":
				scale.z = packet.get_float()
				avatar.scale.z = scale.z
			"J":
				if (is_local()): game_ui.set_tool(packet.get_u32())
			"K":
				avatar.set_head_color(Util.convert_decimal_color(packet.get_u32()))
			"L":
				avatar.set_figure_color(avatar.SURFACE_TORSO, Util.convert_decimal_color(packet.get_u32()))
			"M":
				avatar.set_figure_color(avatar.SURFACE_LEFT_ARM, Util.convert_decimal_color(packet.get_u32()))
			"N":
				avatar.set_figure_color(avatar.SURFACE_RIGHT_ARM, Util.convert_decimal_color(packet.get_u32()))
			"O":
				avatar.set_figure_color(avatar.SURFACE_LEFT_LEG, Util.convert_decimal_color(packet.get_u32()))
			"P":
				avatar.set_figure_color(avatar.SURFACE_RIGHT_LEG, Util.convert_decimal_color(packet.get_u32()))
			"Q":
				avatar.set_face(packet.get_u32())
			"U":
				avatar.set_hat(0, packet.get_u32())
			"V":
				avatar.set_hat(1, packet.get_u32())
			"W":
				avatar.set_hat(2, packet.get_u32())
			"X":
				score = packet.get_u32()
				yield(get_tree(), "idle_frame")
				game_ui.update_player_list()
			"Y":
				team = packet.get_u32()
				if (!is_local()):
					$Nametag._set_color(net.team_map[team].color)
				yield(get_tree(), "idle_frame")
				game_ui.update_player_list()
			"1":
				speed = packet.get_u32()
			"2":
				jump_power = packet.get_u32()
			"3":
				var _fov: int = packet.get_u32()
			"4":
				var _zoom: int = packet.get_u32()
			"5":
				var _cam_pos_x: float = packet.get_float()
			"6":
				var _cam_pos_y: float = packet.get_float()
			"7":
				var _cam_pos_z: float = packet.get_float()
			"8":
				var _cam_rot_x: float = packet.get_float()
			"9":
				var _cam_rot_y: float = packet.get_float()
			"a":
				var _cam_rot_z: float = packet.get_float()
			"b":
				var _cam_type: String = packet.get_string_nt()
			"c":
				var _cam_id: int = packet.get_u32()
			"e":
				health = packet.get_float()
				emit_signal("health_update", health, MAX_HEALTH)
			"f":
				_set_speech(packet.get_string_nt())
			"g":
				# Set arm
				var slot: int = packet.get_u32()
				avatar.set_tool(packet.get_u32())
				if (is_local()): game_ui.set_tool(slot)
			"h":
				# Clear arm
				avatar.set_tool(0)
				if (is_local()): game_ui.set_tool(0)
			"R":
				avatar.set_shirt(packet.get_u32())
			"S":
				avatar.set_pants(packet.get_u32())
			"T":
				avatar.set_tshirt(packet.get_u32())
