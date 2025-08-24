extends Control

func _enter_tree():
	if (OS.get_name() == "Android" || OS.get_name() == "iOS"):
		mobile()
	else:
		desktop()

func _process(delta):
	$CenterContainer/Panel/MarginContainer/VBox/AutoStartLabel.text = "Opening desktop in %s..." % str(ceil($AutoStartTimer.time_left))

func desktop():
	BrickHill.game_mode = BrickHill.MODE_DESKTOP
	get_tree().change_scene("res://scenes/play/play.tscn")

func mobile():
	BrickHill.game_mode = BrickHill.MODE_MOBILE
	
	# Downgrade graphics
	ProjectSettings.set("display/window/vsync/use_vsync", true)
	
	get_tree().change_scene("res://scenes/play/play.tscn")
