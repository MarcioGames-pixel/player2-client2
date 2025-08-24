extends HBoxContainer

const PROFILE_URL: String = "https://www.brick-hill.com/user/%s/"
var user_id: int = 1
var username: String = ""
var game_ui: Control

func set_data(set_user_id: int, set_username: String, score: int, color: Color, icon: Texture):
	user_id = set_user_id
	username = set_username
	$Username.text = set_username
	$Score.text = str(score)
	$Username.modulate = color
	if (icon != null):
		$Icon.texture = icon
		$Icon.visible = true

func _gui_input(event):
	if (event is InputEventMouseButton && event.button_index == BUTTON_LEFT && event.pressed):
		game_ui.profile_prompt(user_id, username)
