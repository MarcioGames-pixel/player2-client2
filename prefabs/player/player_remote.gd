extends PlayerBase
class_name PlayerRemote

func _ready():
	if ($VisibilityNotifier.is_on_screen()): _on_screen_entered()

func _on_screen_entered():
	if (!dead):
		show()
		$SpeechBubble.show()
		$Nametag.show()

func _on_screen_exited():
	hide()
	$SpeechBubble.hide()
	$Nametag.hide()

func _register_nametag(manager: NametagManager):
	manager.create_nametag($Nametag, username)
