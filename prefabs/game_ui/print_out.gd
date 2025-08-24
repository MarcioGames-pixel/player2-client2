extends RichTextLabel
class_name PrintOut

onready var timer: Timer = $ClearTimer

func _ready():
	visible = false
	timer.connect("timeout", self, "_on_timeout")

func display(message: String, time: float):
	var parsed: String = Util.parse_chat_str(message)
	parsed = "[center]%s[/center]" % parsed
	bbcode_text = parsed
	visible = true
	timer.wait_time = time
	timer.start()

func _on_timeout():
	visible = false
