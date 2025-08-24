extends Node

onready var net: Net = get_parent()

func parse_brick(packet: AdaptedPacket):
	var net_id: int = packet.get_u32()
	
	var pos_x: float = -packet.get_float()
	var pos_z: float = -packet.get_float()
	var pos_y: float = packet.get_float()
	var position: Vector3 = Vector3(pos_x, pos_y, pos_z)
	
	var size_x: float = -packet.get_float()
	var size_z: float = -packet.get_float()
	var size_y: float = packet.get_float()
	var size: Vector3 = Vector3(size_x, size_y, size_z)
	
	var color: Color = Util.convert_decimal_color(packet.get_u32())
	var alpha: float = packet.get_float()
	
	var angle: float = 0
	var shape: String = "brick"
	var _model: int = 0
	var _light_color: Color = Color.black
	var _light_range: int = 0
	var collision: bool = true
	var _click_distance: int = 0
	var _real_angle = 0
	
	var attributes: String = packet.get_string_nt()
	for c in attributes:
		match c:
			"A":
				angle = packet.get_32()
				angle = 0
			"B":
				shape = packet.get_string_nt()
			"C":
				_model = packet.get_u32()
			"D":
				_light_color = Util.convert_decimal_color(packet.get_u32())
				_light_range = packet.get_u32()
			"F":
				collision = false
			"G":
				if (packet.get_u8() == 1):
					_click_distance = packet.get_u32()
				else:
					var _yeet = packet.get_u32() # discard
	
	net.brick_system.add_instance(net_id, position, size, color, alpha, angle, collision, shape)

func parse_brick_mod(packet: AdaptedPacket):
	var target_id: int = packet.get_u32()
	if (net.brick_system.has_instance(target_id)):
		var mod: String = packet.get_string_nt()
		
		match(mod):
			"pos":
				var new_x: float = -packet.get_float()
				var new_z: float = -packet.get_float()
				var new_y: float = packet.get_float()
				var new_pos = Vector3(new_x, new_y, new_z)
				net.brick_system.update_instance_position(target_id, new_pos)
			"rot":
				var new_rot: float = deg2rad(packet.get_u32())
				net.brick_system.update_instance_rotation(target_id, new_rot)
			"scale":
				var new_x: float = packet.get_float()
				var new_z: float = packet.get_float()
				var new_y: float = packet.get_float()
				var new_scale = Vector3(new_x, new_y, new_z)
				net.brick_system.update_instance_scale(target_id, new_scale)
			"kill", "destroy":
				net.brick_system.delete_instance(target_id)
			"col":
				var new_color = Util.convert_decimal_color(packet.get_u32())
				net.brick_system.update_instance_color(target_id, new_color)
			"model":
				pass
			"alpha":
				var new_alpha = packet.get_float()
			"collide":
				var new_collision = (packet.get_u8() == 1)
			"lightcol":
				pass
			"lightrange":
				pass
			"clickable":
				var toggle: bool = (packet.get_u8() == 1)
				var distance: float = float(packet.get_u32())
				if (!toggle):
					distance = 0

func parse_brick_string(packet: AdaptedPacket):
	var data_string: String = packet.get_string_nt()
	if (!data_string.begins_with("\t")):
		var properties: PoolRealArray = data_string.split_floats(" ")
		var position: Vector3 = Vector3(-properties[0], properties[2], -properties[1])
		var size: Vector3 = Vector3(properties[3], properties[5], properties[4])
		var tint: Color = Color(properties[6], properties[7], properties[8])
		var alpha: float = properties[9]
		
		# Create
	else:
		var split: PoolStringArray = data_string.strip_edges().split(" ", false, 1)
		var modifier: String = ""
		var data: String = ""
		if (split.size() > 1):
			modifier = split[0]
			data = split[1]
		else:
			modifier = data_string.strip_edges()
		match(modifier):
			"+NAME":
				#var part_id = int(data)
				#last_part.custom_name = data
				#last_part.net_id = part_id
				#net.part_id_map[part_id] = last_part
				pass
			"+ROT":
				#last_part.rotation.y = deg2rad(float(data))
				pass
			"+CLICKABLE":
				#last_part.click_distance = float(data)
				pass
			"+SHAPE":
				pass # lol
			"+MODEL":
				pass # lol
			"+NOCOLLISION":
				#last_part.set_collision(false)
				pass
