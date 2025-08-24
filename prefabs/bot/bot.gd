extends Spatial
class_name Bot

export var net_id: int = 0
export var display_name: String = ""
export var speech: String = "" setget _set_speech
onready var avatar: Avatar = $Avatar
var prev_position = Vector3.ZERO
var frame_velocity = Vector3.ZERO

func _ready():
	prev_position = global_transform.origin
	avatar.set_animation(0)
	_on_screen_exited()
	if (display_name == "_no_stem"):
		$SpeechBubble.no_stem()

func _physics_process(delta: float):
	_animate(delta)

func _animate(delta: float):
	# Arm lerp
	var arm_blend: float = avatar.animation_tree["parameters/figure_tool/blend_amount"]
	if (avatar.arm_up && arm_blend < 1):
		arm_blend = lerp(arm_blend, 1, delta * 8)
		avatar.animation_tree["parameters/figure_tool/blend_amount"] = arm_blend
	elif (arm_blend > 0):
		arm_blend = lerp(arm_blend, 0, delta * 8)
		avatar.animation_tree["parameters/figure_tool/blend_amount"] = arm_blend
	
	var curr_frame_velocity = (global_transform.origin - prev_position) / delta
	frame_velocity = frame_velocity.linear_interpolate(curr_frame_velocity, 0.7)
	prev_position = global_transform.origin
	
	if (frame_velocity.y > 0.01): # Jumping:
		avatar.set_animation(PlayerBase.player_animations.JUMP)
	elif (frame_velocity.y < -0.01): # Falling
		avatar.set_animation(PlayerBase.player_animations.FALLING)
	elif (frame_velocity.abs() * Vector3(1, 0, 1)).length() < 0.1: # Not moving
		avatar.set_animation(PlayerBase.player_animations.IDLE)
	else: # Moving
		avatar.set_animation(PlayerBase.player_animations.WALK)

func _set_speech(val: String):
	speech = val
	$SpeechBubble.text = val

func _on_screen_entered():
	#show()
	$SpeechBubble.show()

func _on_screen_exited():
	#hide()
	$SpeechBubble.hide()
