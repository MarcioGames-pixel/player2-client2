extends HBoxContainer

func set_data(team_name: String, score: int, color: Color):
	$Name.text = team_name
	$Score.text = str(score)
	$Name.modulate = color
