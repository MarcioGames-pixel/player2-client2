extends Node

enum {
	MODE_DESKTOP = 0
	MODE_MOBILE = 1
	MODE_VR = 2
}
const VERSION: String = "0.3.1.0"

var game_mode: int = MODE_DESKTOP

func _init():
	# Create window
	OS.set_window_title("Brick Hill")
	
	# Create directories if not found
	var dir = Directory.new()
	if (!dir.dir_exists("user://cache")):
		dir.make_dir("user://cache")

func _ready():
	# Set game mode
	return # this is handled in the start scene for now
	var vr_interface = ARVRServer.find_interface("OpenVR")
	if (vr_interface && vr_interface.initialize()):
		game_mode = MODE_VR
		get_viewport().arvr = true
		get_viewport().keep_3d_linear = true
		OS.vsync_enabled = false
		Engine.target_fps = 90
	else:
		game_mode = MODE_DESKTOP
