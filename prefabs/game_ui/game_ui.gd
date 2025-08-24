extends Control
class_name GameUI

const PROFILE_URL: String = "https://www.brick-hill.com/user/%s/"
const ToolSelectScene: PackedScene = preload("res://prefabs/game_ui/tool_select.tscn")
const PlayerListItemScene: PackedScene = preload("res://prefabs/game_ui/player_list_item.tscn")
const TeamListItemScene: PackedScene = preload("res://prefabs/game_ui/team_list_item.tscn")
onready var messages_label: RichTextLabel = $Chat/VBox/MessagesMargin/Scroll/Messages
onready var chat_input: LineEdit = $Chat/VBox/OptionsMargin/Options/Input
onready var chat_toggle: ToggleArrow = $Chat/VBox/OptionsMargin/Options/Toggle
onready var print_top: PrintOut = $PrintOuts/Layout/Top
onready var print_center: PrintOut = $PrintOuts/Layout/Center
onready var print_bottom: PrintOut = $PrintOuts/Layout/Bottom
var net: Node
var tool_map: Dictionary = {}
var _score_map: Dictionary = {}
var _prompt_user: int = 23615

func _ready():
	net.connect("list_update", self, "update_player_list")
	
	if (BrickHill.game_mode == BrickHill.MODE_MOBILE):
		# Increase font size
		load("res://shared/fonts/default_font.tres").size = 24
		load("res://shared/fonts/bold_font.tres").size = 24
		load("res://shared/fonts/outline_font.tres").size = 24
		$Tools.rect_position.y -= 16
		$Chat.rect_min_size.x = 500
		$Chat/VBox/OptionsMargin/Options/Input.placeholder_text = "Tap to talk"
		$ProfilePrompt/CenterContainer/Popup.rect_min_size.x = 400

func notice(text: String = "", title: String = ""):
	if (text == ""):
		$Notice.hide()
	else:
		$Notice/Panel/Margins/VBox/Body.text = text
		if (title == ""): $Notice/Panel/Margins/VBox/Title.hide()
		else:
			$Notice/Panel/Margins/VBox/Title.text = title
			$Notice/Panel/Margins/VBox/Title.show()
		$Notice.show()

func is_menu_open():
	return $Menu.visible

func add_message(message: String):
	if (messages_label.text != ""):
		messages_label.add_text("\n")
	messages_label.append_bbcode(Util.parse_chat_str(message))
	yield(get_tree(),"idle_frame")
	$Chat/VBox/MessagesMargin/Scroll.scroll_vertical = messages_label.rect_size.y

func send_message(input: String):
	chat_input.text = ""
	chat_input.release_focus()
	if (input != ""):
		var command: String = "chat"
		var args: String = input
		if (input.begins_with("/")):
			var split: PoolStringArray = input.split(" ", true, 1)
			command = split[0].substr(1)
			if (split.size() > 1):
				args = split[1]
		var message_packet: AdaptedPacket = AdaptedPacket.new(NetID.OUTGOING_COMMAND)
		message_packet.put_string_nt(command)
		message_packet.put_string_nt(args)
		net.send(message_packet)

func _on_tool_button_press(selector: ToolSelect):
	var tool_packet: AdaptedPacket = AdaptedPacket.new(NetID.OUTGOING_INPUT)
	tool_packet.put_8(0)
	tool_packet.put_string_nt(str(selector.get_index() + 1))
	net.send(tool_packet)

func remove_tool(slot: int):
	if (tool_map.has(slot)):
		var selector = tool_map.get(slot)
		selector.queue_free()
		tool_map.erase(slot)

func add_tool(slot: int, set_name: String):
	if (!tool_map.has(slot)):
		var selector: ToolSelect = ToolSelectScene.instance()
		$Tools/Container.add_child(selector)
		#$Tools/Container.move_child(selector, slot)
		selector.connect("press", self, "_on_tool_button_press", [selector])
		selector.slot = slot
		selector.index = tool_map.size() + 1
		selector.set_name(set_name)
		tool_map[slot] = selector

func set_tool(slot: int):
	if (slot == 0):
		for child in $Tools/Container.get_children():
			child.select(false)
		return
	if (tool_map.has(slot)):
		for child in $Tools/Container.get_children():
			child.select(false)
		var selector: ToolSelect = tool_map[slot]
		selector.select(true)

func _team_sort(a: Dictionary, b: Dictionary):
	return _score_map[a.id] > _score_map[b.id]

func _score_sort(a: KinematicBody, b: KinematicBody):
	return a.score > b.score

func exit_game():
	get_tree().quit()

func update_player_list():
	# Reset
	_score_map = {}
	var player_team_map: Dictionary = {}
	var teams: Array = net.team_map.values()
	teams.append({ id = 0, name = "(No team)", color = Color.white })
	
	# Total player scores
	for team in teams:
		player_team_map[team.id] = []
		_score_map[team.id] = 0
	for player in get_tree().get_nodes_in_group("player"):
		player_team_map[player.team].append(player)
		_score_map[player.team] += player.score
	
	# Sort
	teams.sort_custom(self, "_team_sort")
	for p_t in player_team_map.values():
		p_t.sort_custom(self, "_score_sort")
	
	# Clear
	var container: VBoxContainer = $Teams/Scrollable/Margins/List
	for child in container.get_children():
		child.queue_free()
	
	# Rebuild
	for team in teams:
		var team_item: Control = TeamListItemScene.instance()
		if !(team.id == 0 && (teams.size() == 1 || player_team_map[0].size() == 0)):
			team_item.set_data(team.name, _score_map[team.id], team.color)
			container.add_child(team_item)
		
		for p in player_team_map[team.id]:
			var player_item: Control = PlayerListItemScene.instance()
			player_item.set_data(p.user_id, p.username, p.score, p.list_color, p.list_icon)
			player_item.game_ui = self
			container.add_child(player_item)

func profile_prompt(id: int, username: String):
	var prompt_text: String = "Visit %s's profile on brick-hill.com?" % username
	_prompt_user = id
	$ProfilePrompt/CenterContainer/Popup/MarginContainer/VBoxContainer/Label.text = prompt_text
	$ProfilePrompt.show()

func _profile_prompt_cancel():
	$ProfilePrompt.hide()

func _profile_prompt_confirm():
	$ProfilePrompt.hide()
	OS.shell_open(PROFILE_URL % _prompt_user)

func toggle_fps():
	$FramesPanel.visible = !$FramesPanel.visible
	if ($FramesPanel.visible):
		$Menu/CenterContainer/VBoxContainer/Hackz/FPS.text = "Hide FPS"
	else:
		$Menu/CenterContainer/VBoxContainer/Hackz/FPS.text = "Show FPS"

func toggle_teams():
	$Teams.visible = !$Teams.visible
	if ($Teams.visible):
		$Menu/CenterContainer/VBoxContainer/Hackz/List.text = "Hide list"
	else:
		$Menu/CenterContainer/VBoxContainer/Hackz/List.text = "Show list"

func _process(_delta):
	var FPS: float = Performance.get_monitor(Performance.TIME_FPS)
	$FramesPanel/Margins/FPS.text = "%s FPS" % str(FPS)

func _unhandled_input(event):
	if (event is InputEventKey):
		if (event.pressed):
			match(event.scancode):
				KEY_T: # Focus chat input
					if (!$Menu.visible && visible): chat_input.grab_focus()
				KEY_SLASH: # Focus chat input with /
					if (!$Menu.visible && visible):
						chat_input.grab_focus()
						if (chat_input.text == ""):
							chat_input.text = "/"
							chat_input.caret_position = 1
				KEY_ESCAPE:
					# Profile prompt
					if ($ProfilePrompt.visible):
						_profile_prompt_cancel()
						return
					# Chat input
					if (chat_input.has_focus()):
						chat_input.release_focus()
						return
					# Menu
					if (visible):
						$Menu.visible = !$Menu.visible
						if ($Menu.visible): Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				KEY_F1:
					if (visible): toggle_fps()
				KEY_F2:
					if (!$Menu.visible): visible = !visible
				KEY_TAB:
					toggle_teams()
				KEY_F11:
					OS.window_fullscreen = !OS.window_fullscreen
	elif (event is InputEventMouseButton):
		if (event.button_index == BUTTON_LEFT && event.pressed):
			if (chat_input.has_focus()): chat_input.release_focus()

func _on_close_menu():
	$Menu.hide()

func _on_chat_toggle(toggled):
	if (chat_input.has_focus()): chat_input.release_focus()
	if (toggled):
		$Chat/VBox/MessagesMargin.show()
		$Chat.rect_size.y = 242
	else:
		$Chat/VBox/MessagesMargin.hide()
		$Chat.rect_size.y = 0
	$Chat.update()

func _on_chat_input_focus():
	if (!chat_toggle.toggled):
		$Chat/VBox/MessagesMargin.show()
		$Chat.rect_size.y = 242

func _on_chat_input_unfocus():
	if (!chat_toggle.toggled):
		$Chat/VBox/MessagesMargin.hide()
		$Chat.rect_size.y = 0
