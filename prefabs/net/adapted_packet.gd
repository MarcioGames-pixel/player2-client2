extends StreamPeerBuffer
class_name AdaptedPacket

var net_id: int = 0
var self_ref: Script

func _init(id: int):
	net_id = id

static func _from_incoming(existing: PoolByteArray):
	var temp_buffer: StreamPeerBuffer = StreamPeerBuffer.new()
	temp_buffer.data_array = existing
	var compression_check = temp_buffer.get_u8()
	if (compression_check == 0x78):
		temp_buffer.data_array = Miniz.zlib_decompress(existing)
	temp_buffer.seek(0)
	var incoming_id = temp_buffer.get_u8()
	var incoming_packet = Loader.AdaptedPacket.new(incoming_id)
	incoming_packet.data_array = temp_buffer.data_array.subarray(1, temp_buffer.data_array.size() - 1)
	return incoming_packet

func put_string_nt(val: String):
	var _put = put_data(PacketUtil.encode_string_nt(val))

func get_string_nt():
	return PacketUtil.decode_string_nt(self).value

func put_uintv(val: int, sized: bool = true):
	var _put = put_data(PacketUtil.encode_uintv(val, sized))

func get_uintv():
	return PacketUtil.decode_uintv(data_array).value

func print_out():
	var original_pos: int = get_position()
	var byte_str: String = ""
	seek(0)
	for byte in data_array:
		byte_str += str(byte) + " "
	seek(original_pos)
	print("(AdaptedPacket %s) %s" % [net_id, byte_str])

func send_to(connection: StreamPeerTCP, compression: bool = false):
	var final_buffer = StreamPeerBuffer.new()
	final_buffer.put_u8(net_id)
	final_buffer.put_data(data_array)
	if (compression):
		final_buffer.data_array = Miniz.zlib_compress(final_buffer.data_array, 5)
	var encoded_size: PoolByteArray = PacketUtil.get_size_value(final_buffer.data_array)
	var _put_data = connection.put_data(encoded_size + final_buffer.data_array)
