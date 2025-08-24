tool
extends Position3D

export var text: String = "" setget _set_text
onready var player: Spatial = get_parent()
onready var message_label: RichTextLabel = $Bubble/PanelContainer/MarginContainer/Message
var position_blocked: bool = false setget _set_position_blocked
onready var bbcode_regex: RegEx = RegEx.new()

func get_bubble_width(text: String):
	var stripped_text = bbcode_regex.sub(text, "", true)
	return message_label.get_font("normal_font").get_string_size(stripped_text).x

func _ready():
	bbcode_regex.compile("\\[(.*?)\\]")
	$Bubble.visible = (text != "")
	if (text != ""):
		message_label.bbcode_text = Util.parse_chat_str(text)
		message_label.rect_min_size.x = get_bubble_width(message_label.bbcode_text)

func no_stem():
	$Bubble/CenterContainer/Stem.hide()

func _set_text(val: String):
	text = val
	if (is_inside_tree()):
		$Bubble.visible = (text != "")
		if (text != ""):
			message_label.bbcode_text = Util.parse_chat_str(text)
			message_label.rect_min_size.x = get_bubble_width(message_label.bbcode_text)

func _process(_delta):
	if ($Bubble.visible && !Engine.editor_hint && player):
		var cam: Camera = get_viewport().get_camera()
		var new_pos: Vector2 = cam.unproject_position(global_transform.origin)
		var offset: Vector2 = $Bubble.get_global_rect().size * Vector2(0.5, 1)
		$Bubble.margin_left = new_pos.x - offset.x
		$Bubble.margin_top = new_pos.y - offset.y

func _on_visibility_changed():
	if (text != "" && !position_blocked): $Bubble.visible = visible

func _set_position_blocked(val: bool):
	if (val):
		$Bubble.visible = false
	elif (text != ""):
		$Bubble.visible = true
	position_blocked = val
