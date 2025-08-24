extends Node
class_name PacketUtil

static func encode_string_nt(val: String):
	var encoded = val.to_ascii()
	encoded.append(0x00)
	return encoded

static func decode_string_nt(raw: StreamPeerBuffer):
	var string_bytes: PoolByteArray = PoolByteArray()
	while (true):
		var byte = raw.get_u8()
		if (byte == 0x00):
			break
		string_bytes.append(byte)
	return {
		value = string_bytes.get_string_from_ascii(),
		size = string_bytes.size()
	}

static func get_size_value(buffer: PoolByteArray):
	var size: int = buffer.size()
	var size_buf: StreamPeerBuffer = StreamPeerBuffer.new()
	if (size < 0x80):
		size_buf.put_u8((size << 1) + 1)
		return size_buf.data_array
	elif (size < 0x4080):
		size_buf.put_u16(((size - 0x80) << 2) + 2)
	elif (size < 0x204080):
		var write_value: int = ((size - 0x4080) << 3) + 4
		size_buf.put_u8((write_value & 0xFF))
		size_buf.put_u16(write_value >> 8)
	else:
		size_buf.put_u32((size - 0x204080) * 8)
	return size_buf.data_array


static func decode_uintv(raw: PoolByteArray):
	var buffer: StreamPeerBuffer = StreamPeerBuffer.new()
	buffer.data_array = raw
	if (buffer.data_array[0] & 1):
		return {
			value = buffer.data_array[0] >> 1,
			size = 1
		}
	elif (buffer.data_array[0] & 2):
		return {
			value = (buffer.get_u16() >> 2) + 0x80,
			size = 2
		}
	elif (buffer.data_array[0] & 4):
		return {
			value = (buffer.data_array[2] << 13) + (buffer.data_array[1] << 5) + (buffer.data_array[0] >> 3) + 0x4080,
			size = 3
		}
	else:
		return {
			value = (buffer.get_u32() / 8) + 0x204080,
			size = 4
		}
