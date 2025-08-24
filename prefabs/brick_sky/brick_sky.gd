tool
extends WorldEnvironment
class_name BrickSky

const DEFAULT_COLOR: Color = Color("#7CB2E5")
const DEFAULT_AMBIENT: Color = Color("#DDDDDD")
onready var sunlight: DirectionalLight = $SunLight
onready var sky_color: Color = DEFAULT_COLOR
var sun: int = 400

func _ready():
	set_color(sky_color)
	$SunLight.shadow_bias = -0.005

func set_sun(val: int):
	sun = val

func set_color(val: Color):
	sky_color = val
	environment.fog_color = val
	environment.background_sky.set("sky_top_color", val)
	environment.background_sky.set("sky_horizon_color", val.lightened(0.2))
	environment.background_sky.set("ground_bottom_color", val.lightened(0.2))
	environment.background_sky.set("ground_horizon_color", val.lightened(0.2))

func set_ambient(val: Color):
	set("ambient_light_color", val)
