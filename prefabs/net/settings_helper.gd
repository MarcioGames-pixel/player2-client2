extends Node

onready var net: Net = get_parent()

var baseplate_color: Color = Color("#248233")
var baseplate_size: Vector3 = Vector3(100, 0.1, 100)
var baseplate_position: Vector3 = Vector3(50, 0, 50)

func _update_baseplate():
	net.brick_system.add_instance(-1, baseplate_position - (baseplate_size), baseplate_size, baseplate_color, 1.0, 0.0, true, "plate")

func parse(packet: AdaptedPacket):
	var _sky: BrickSky = net.sky
	var type: String = packet.get_string_nt()
	match type:
		"topPrint":
			var game_ui: GameUI = net.game_ui
			var message: String = packet.get_string_nt()
			var time: float = float(packet.get_u32())
			game_ui.print_top.display(message, time)
		"centerPrint":
			var game_ui: GameUI = net.game_ui
			var message: String = packet.get_string_nt()
			var time: float = float(packet.get_u32())
			game_ui.print_center.display(message, time)
		"bottomPrint":
			var game_ui: GameUI = net.game_ui
			var message: String = packet.get_string_nt()
			var time: float = float(packet.get_u32())
			game_ui.print_bottom.display(message, time)
		"Ambient":
			var sky: BrickSky = net.sky
			sky.set_ambient(Util.convert_decimal_color(packet.get_u32()))
		"Sky":
			var sky: BrickSky = net.sky
			sky.set_color(Util.convert_decimal_color(packet.get_u32()))
		"BaseCol":
			baseplate_color = Util.convert_decimal_color(packet.get_u32())
			if (baseplate_size.x != 0): _update_baseplate()
		"BaseSize":
			var set_size: int = packet.get_u32()
			baseplate_size = Vector3(set_size, 0.1, set_size)
			baseplate_position = Vector3(set_size / 2.0, -0.1, set_size / 2.0)
			if (set_size == 0):
				net.brick_system.delete_instance(-1)
			else:
				_update_baseplate()
		"Sun":
			var sky: BrickSky = net.sky
			sky.set_sun(packet.get_u32())
		"kick":
			var game_ui: GameUI = net.game_ui
			net.kicked = true
			game_ui.notice("Kicked", packet.get_string_nt())
			net.close_connection()
		"prompt":
			var game_ui: GameUI = net.game_ui
			game_ui.add_message("[Prompt] " + packet.get_string_nt())
		_:
			#print("SETTING: ", type)
			pass
