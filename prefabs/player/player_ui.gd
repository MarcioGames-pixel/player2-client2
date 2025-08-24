extends Control

onready var player: PlayerLocal = get_parent()
onready var healthbar = $Healthbar/Margins/Bar
onready var bar_style = healthbar.get("custom_styles/fg")

func _ready():
	player.connect("health_update", self, "_update_healthbar")

func _update_healthbar(new_health: float, max_health: float):
	var new_color = Color.green
	if (new_health < max_health / 2.0):
		new_color = lerp(Color.red, Color.yellow, healthbar.get_as_ratio() * 2.0)
	else:
		new_color = lerp(Color.green, Color.yellow, healthbar.get_as_ratio() - 0.5)
	healthbar.max_value = max_health
	healthbar.value = new_health
	bar_style.bg_color = new_color
