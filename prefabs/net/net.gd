extends Node
class_name Net

signal connected
signal authenticated
signal bricks_loading
signal bricks_loaded
signal list_update
const STATE_DISCONNECTED: int = 0
const STATE_CONNECTING: int = 1
const STATE_CONNECTED: int = 2
export var server_address: String = "localhost"
export var server_port: int = 42480
onready var player_container: Spatial = get_node("../Players")
onready var bot_container: Spatial = get_node("../Bots")
onready var brick_system: Spatial = get_node("../BrickSystem")
onready var game_ui: GameUI = get_node("../GameUI")
onready var sky: BrickSky = get_node("../BrickSky")
onready var nametag_manager: NametagManager = get_node("../NametagManager")
onready var packet_thread: Thread = Thread.new()
var _cut_off_data: PoolByteArray = PoolByteArray()
var state: int = STATE_DISCONNECTED
var token: String = "player2_testing"
var kicked: bool = false
var initial_load: bool = true
var set_id: int = 0
var total_brick_count: int = 0
var loaded_brick_count: int = 0
var local_player: KinematicBody
var team_map: Dictionary = {}
var player_map: Dictionary = {}
var bot_map: Dictionary = {}
var part_id_map: Dictionary = {}
var connection: StreamPeerTCP
var auth_data: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	# Create baseplate
	var bp_size: Vector3 = Vector3(100, 0.1, 100)
	var bp_pos: Vector3 = -(bp_size / 2.0)
	bp_pos.y = -0.1
	brick_system.add_instance(-1, bp_pos, bp_size, Color("#248233"), 1.0, 0.0, true, "plate")
	
	# Wire signals
	$RequestSet.connect("request_completed", self, "_on_set_request_completed")
	
	# Get GameUI and set net controller
	game_ui.net = self
	
	# Handle URI
	var url: String = ""
	
	if (OS.get_name() == "Android" && Engine.has_singleton('AppLinks')):
		var applinks = Engine.get_singleton('AppLinks')
		url = applinks.getUrl()
	elif (OS.get_cmdline_args().size() > 0):
		url = OS.get_cmdline_args()[0]
	
	if (url != ""):
		var uri_regex: RegEx = RegEx.new()
		uri_regex.compile("brickhill.legacy:\/\/client\/(.*)\/(.*)\/(.*)")
		var uri_match: RegExMatch = uri_regex.search(url)
		if (uri_match != null && uri_match.get_group_count() == 3):
			token = uri_match.strings[1]
			server_address = uri_match.strings[2]
			server_port = int(uri_match.strings[3])
	
	if (BrickHill.game_mode == BrickHill.MODE_MOBILE):
		if (token == "player2_testing"):
			OS.shell_open("https://brick-hill.com/play/")
			get_tree().quit()
	
	# Connect to server
	#BrickHill.game_mode = BrickHill.MODE_MOBILE
	open_connection(server_address, server_port)

func open_connection(ip: String, port: int):
	game_ui.notice("Connecting...", "Status")
	print("Connecting to \"%s:%s\"..." % [ip, port])
	state = STATE_CONNECTING
	connection = StreamPeerTCP.new()
	if (ip == "localhost"): ip = "127.0.0.1"
	var _connect = connection.connect_to_host(ip, port)

func close_connection():
	connection.disconnect_from_host()

func send(packet: AdaptedPacket):
	if (state == STATE_CONNECTED): packet.send_to(connection)

func _send_auth():
	game_ui.notice("Authenticating...", "Status")
	var packet: AdaptedPacket = AdaptedPacket.new(NetID.OUTGOING_AUTH)
	packet.put_string_nt(token)
	packet.put_string_nt(BrickHill.VERSION)
	packet.put_u8(2)
	packet.send_to(connection, false)

func _notification(notification):
	# Ensure connection closes
	if (OS.get_name() != "Windows" && OS.get_name() != "OSX"): return
	if (notification == MainLoop.NOTIFICATION_WM_QUIT_REQUEST):
		DiscordIntegrator.activity_clear()
		if (state != STATE_DISCONNECTED): connection.disconnect_from_host()

func _process(_delta):
	if (connection.get_status() == StreamPeerTCP.STATUS_CONNECTED):
		if (state == STATE_CONNECTING):
			state = STATE_CONNECTED
			emit_signal("connected")
			connection.set_no_delay(true)
			print("Connected to server.")
			_send_auth()
		_handle_incoming()
	else:
		if (state == STATE_CONNECTED):
			state = STATE_DISCONNECTED
			print("Disconnected from the server.")
			if (!kicked): game_ui.notice("Disconnected", "Status")

func _heartbeat():
	if (state == STATE_CONNECTED):
		var packet: AdaptedPacket = AdaptedPacket.new(NetID.OUTGOING_HEARTBEAT)
		packet.send_to(connection, false)

func _create_local_player():
	if (local_player != null): return
	game_ui.notice()
	var new_player = Loader.LocalPlayerScene.instance()
	new_player.net = self
	new_player.game_ui = game_ui
	new_player.net_id = auth_data.net_id
	new_player.user_id = auth_data.user_id
	new_player.username = auth_data.username
	new_player.admin = auth_data.admin
	new_player.membership = auth_data.membership
	player_container.add_child(new_player)
	player_map[new_player.net_id] = new_player
	local_player = new_player
	emit_signal("list_update")

func set_discord_rpc(set_name: String, set_owner: String):
	if (OS.get_name() != "Windows" && OS.get_name() != "OSX"): return
	var num_gen: RandomNumberGenerator = RandomNumberGenerator.new()
	num_gen.randomize()
	if (BrickHill.game_mode == BrickHill.MODE_VR):
		DiscordIntegrator.activity_map("(VR) %s" % set_name, set_owner, "set_%s" % str(num_gen.randi_range(1, 7)))
	else:
		DiscordIntegrator.activity_map(set_name, set_owner, "set_%s" % str(num_gen.randi_range(1, 7)))

func _on_set_request_completed(result, response_code, headers, body):
	var json: JSONParseResult = JSON.parse(body.get_string_from_utf8())
	var set_name: String = json.result.data.name
	var set_owner: String = json.result.data.creator.username
	OS.set_window_title("Brick Hill - %s" % set_name)
	set_discord_rpc(set_name, "By %s" % set_owner)

func _handle_incoming():
	var incoming_size: int = connection.get_available_bytes()
	if (incoming_size > 0):
		# Get full buffer
		var full_buffer: PoolByteArray = _cut_off_data + connection.get_data(incoming_size)[1]
		_cut_off_data = PoolByteArray()
		var buffer_size: int = full_buffer.size()
		
		# Split packets
		var incoming_packets: Array = []
		var cursor: int = 0
		while (cursor < buffer_size):
			var raw_data: PoolByteArray = full_buffer.subarray(cursor, buffer_size - 1)
			var s_data: Dictionary = PacketUtil.decode_uintv(raw_data)
			var packet_size: int = s_data.value + s_data.size
			if (cursor + packet_size > buffer_size):
				_cut_off_data = raw_data
				break
			var packet_data: PoolByteArray = raw_data.subarray(s_data.size, packet_size - 1)
			incoming_packets.append(AdaptedPacket._from_incoming(packet_data))
			cursor += packet_size
		
		for packet in incoming_packets:
			match(packet.net_id):
				NetID.INCOMING_AUTHENTICATION:
					# Get data
					auth_data.net_id = packet.get_u32()
					total_brick_count = packet.get_u32()
					auth_data.user_id = packet.get_u32()
					auth_data.username = packet.get_string_nt()
					auth_data.admin = packet.get_u8() == 1
					auth_data.membership = packet.get_u8()
					_create_local_player()
					if (packet.get_position() < packet.get_size()):
						set_id = packet.get_u32()
					
					# Create player if no bricks
					if (total_brick_count == 0):
						initial_load = true
						#_create_local_player()
					else:
						emit_signal("bricks_loading")
					emit_signal("authenticated")
					emit_signal("list_update")
					
					# Request set information
					if (set_id != 0):
						$RequestSet.request("https://api.brick-hill.com/v1/sets/%s" % str(set_id))
					else:
						set_discord_rpc("Unknown set", "(Player2)")
				NetID.INCOMING_SEND_BRICK:
					while (packet.get_available_bytes() > 0):
						emit_signal("bricks_loading")
						$PartHelper.parse_brick_string(packet)
						loaded_brick_count += 1
						emit_signal("bricks_loaded")
						if (!initial_load): game_ui.notice("%s/%s bricks" % [loaded_brick_count, total_brick_count], "Loading")
						if (loaded_brick_count >= total_brick_count && initial_load):
							#_create_local_player()
							initial_load = false
				NetID.INCOMING_SEND_PLAYERS:
					var player_count: int = packet.get_u8()
					for _idx in range(0, player_count):
						var new_player = Loader.RemotePlayerScene.instance()
						new_player.net = self
						new_player.game_ui = game_ui
						new_player.net_id = packet.get_u32()
						new_player.username = packet.get_string_nt()
						new_player.user_id = packet.get_u32()
						new_player.admin = packet.get_u8() == 1
						new_player.membership = packet.get_u8()
						new_player._register_nametag(nametag_manager)
						player_container.add_child(new_player)
						player_map[new_player.net_id] = new_player
					yield(get_tree(), "idle_frame")
					emit_signal("list_update")
				NetID.INCOMING_FIGURE:
					var net_id: int = packet.get_u32()
					if (player_map.has(net_id)):
						var update_player = player_map[net_id]
						var prev_score: int = update_player.score
						update_player._handle_update_packet(packet)
						# Update player list if score changed
						if (prev_score != update_player.score):
							emit_signal("list_update")
				NetID.INCOMING_REMOVE_PLAYER:
					var net_id: int = packet.get_u32()
					if (player_map.has(net_id)):
						var del_player = player_map[net_id]
						if (del_player == local_player): return
						del_player.queue_free()
						player_map.erase(net_id)
						yield(get_tree(), "idle_frame")
						emit_signal("list_update")
				NetID.INCOMING_CHAT:
					game_ui.add_message(packet.get_string_nt())
				NetID.INCOMING_SETTING:
					$SettingsHelper.parse(packet)
				NetID.INCOMING_KILL:
					var net_id: int = int(packet.get_float())
					var dead: bool = packet.get_u8() == 1
					if (player_map.has(net_id)):
						var dead_player = player_map[net_id]
						dead_player.dead = dead
				NetID.INCOMING_BRICK:
					$PartHelper.parse_brick_mod(packet)
				NetID.INCOMING_TEAM:
					var team_data: Dictionary = {
						id = packet.get_u32(),
						name = packet.get_string_nt(),
						color = Util.convert_decimal_color(packet.get_u32())
					}
					team_map[team_data.id] = team_data
					emit_signal("list_update")
				NetID.INCOMING_TOOL:
					# Add to UI
					var create: bool = packet.get_u8() == 1
					var slot: int = packet.get_u32()
					var tool_name: String = packet.get_string_nt()
					var model: int = packet.get_u32()
					if (create):
						game_ui.add_tool(slot, tool_name)
					else:
						game_ui.remove_tool(slot)
				NetID.INCOMING_BOT:
					var net_id: int = packet.get_u32()
					if (bot_map.has(net_id)):
						var bot = bot_map[net_id]
						$BotHelper.parse_update(bot, packet)
					else:
						$BotHelper.parse_create(net_id, packet)
				NetID.INCOMING_CLEAR_MAP:
					pass
				NetID.INCOMING_DELETE_BOT:
					var net_id: int = packet.get_u32()
					if (bot_map.has(net_id)):
						var bot = bot_map[net_id]
						bot.queue_free()
						bot_map.erase(net_id)
				NetID.INCOMING_DELETE_BRICK:
					var del_count: int = packet.get_u32()
					for idx in range(0, del_count):
						var del_id: int = packet.get_u32()
						brick_system.delete_instance(del_id)
				NetID.INCOMING_SEND_BRICK_BINARY:
					var instance_count: int = packet.get_u32()
					for _idx in instance_count:
						emit_signal("bricks_loading")
						$PartHelper.parse_brick(packet)
						loaded_brick_count += 1
						emit_signal("bricks_loaded")
						if (loaded_brick_count >= total_brick_count && initial_load):
							#_create_local_player()
							initial_load = false
