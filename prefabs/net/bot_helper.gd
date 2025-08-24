extends Node

const BOT_SCENE: PackedScene = preload("res://prefabs/bot/bot.tscn")
onready var net: Net = get_parent()

func parse_update(bot: Bot, packet: AdaptedPacket):
	var sub_id: String = packet.get_string_nt()
	for c in sub_id:
		match(c):
			"B":
				bot.global_transform.origin.x = -packet.get_float()
			"C":
				bot.global_transform.origin.z = -packet.get_float()
			"D":
				bot.global_transform.origin.y = packet.get_float()
			"E":
				bot.rotation.x = -deg2rad(packet.get_float())
			"F":
				bot.rotation.z = -deg2rad(packet.get_float())
			"G":
				bot.rotation.y = deg2rad(packet.get_float())
			"H":
				bot.scale.x = -packet.get_float()
			"I":
				bot.scale.y = packet.get_float()
			"J":
				bot.scale.z = -packet.get_float()
			"K":
				bot.avatar.set_head_color(Util.convert_decimal_color(packet.get_u32()))
			"L":
				bot.avatar.set_figure_color(bot.avatar.SURFACE_TORSO, Util.convert_decimal_color(packet.get_u32()))
			"M":
				bot.avatar.set_figure_color(bot.avatar.SURFACE_LEFT_ARM, Util.convert_decimal_color(packet.get_u32()))
			"N":
				bot.avatar.set_figure_color(bot.avatar.SURFACE_RIGHT_ARM, Util.convert_decimal_color(packet.get_u32()))
			"O":
				bot.avatar.set_figure_color(bot.avatar.SURFACE_LEFT_LEG, Util.convert_decimal_color(packet.get_u32()))
			"P":
				bot.avatar.set_figure_color(bot.avatar.SURFACE_RIGHT_LEG, Util.convert_decimal_color(packet.get_u32()))
			"Q":
				bot.avatar.set_face(packet.get_u32())
			"R":
				bot.avatar.set_shirt(packet.get_u32())
			"S":
				bot.avatar.set_pants(packet.get_u32())
			"T":
				bot.avatar.set_tshirt(packet.get_u32())
			"U":
				bot.avatar.set_hat(0, packet.get_u32())
			"V":
				bot.avatar.set_hat(1, packet.get_u32())
			"W":
				bot.avatar.set_hat(2, packet.get_u32())
			"X":
				bot.speech = packet.get_string_nt()

func parse_create(net_id: int, packet: AdaptedPacket):
	# Base data
	print("NET_ID ", net_id)
	var sub_id: String = packet.get_string_nt()
	print("SUB_ID ", sub_id)
	var display_name: String = packet.get_string_nt()
	
	# Instance
	var new_bot: Bot = BOT_SCENE.instance()
	new_bot.net_id = net_id
	new_bot.display_name = display_name
	net.bot_container.add_child(new_bot)
	net.bot_map[net_id] = new_bot
	
	for c in sub_id:
		match(c):
			"B":
				new_bot.global_transform.origin.x = -packet.get_float()
				print("X ", new_bot.global_transform.origin.x)
			"C":
				new_bot.global_transform.origin.z = -packet.get_float()
				print("Y ", new_bot.global_transform.origin.x)
			"D":
				new_bot.global_transform.origin.y = packet.get_float()
				print("Z ", new_bot.global_transform.origin.x)
			"E":
				new_bot.rotation.x = -deg2rad(packet.get_float())
			"F":
				new_bot.rotation.z = -deg2rad(packet.get_float())
			"G":
				new_bot.rotation.y = deg2rad(packet.get_float())
			"H":
				new_bot.scale.x = -packet.get_float()
			"I":
				new_bot.scale.y = packet.get_float()
			"J":
				new_bot.scale.z = -packet.get_float()
			"K":
				new_bot.avatar.set_head_color(Util.convert_decimal_color(packet.get_u32()))
			"L":
				new_bot.avatar.set_figure_color(new_bot.avatar.SURFACE_TORSO, Util.convert_decimal_color(packet.get_u32()))
			"M":
				new_bot.avatar.set_figure_color(new_bot.avatar.SURFACE_LEFT_ARM, Util.convert_decimal_color(packet.get_u32()))
			"N":
				new_bot.avatar.set_figure_color(new_bot.avatar.SURFACE_RIGHT_ARM, Util.convert_decimal_color(packet.get_u32()))
			"O":
				new_bot.avatar.set_figure_color(new_bot.avatar.SURFACE_LEFT_LEG, Util.convert_decimal_color(packet.get_u32()))
			"P":
				new_bot.avatar.set_figure_color(new_bot.avatar.SURFACE_RIGHT_LEG, Util.convert_decimal_color(packet.get_u32()))
			"Q":
				new_bot.avatar.set_face(packet.get_u32())
			"R":
				new_bot.avatar.set_shirt(packet.get_u32())
			"S":
				new_bot.avatar.set_pants(packet.get_u32())
			"T":
				new_bot.avatar.set_tshirt(packet.get_u32())
			"U":
				new_bot.avatar.set_hat(0, packet.get_u32())
			"V":
				new_bot.avatar.set_hat(1, packet.get_u32())
			"W":
				new_bot.avatar.set_hat(2, packet.get_u32())
			"X":
				new_bot.speech = packet.get_string_nt()
