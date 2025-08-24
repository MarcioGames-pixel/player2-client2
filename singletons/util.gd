extends Node

const CHAT_COLOR_CODES: PoolColorArray = PoolColorArray([
	Color("#FFFFFF"), Color("#AAAAAA"), Color("#555555"), Color("#000000"),
	Color("#0000FF"), Color("#00FF00"), Color("#FF0000"), Color("#00FFFF"),
	Color("#FFFF00"), Color("#FF00FF")
])

static func parse_chat_str(message: String):
	# Escape by prefixing opening tags with zero width space
	message = message.replace("[", "[​")
	
	# Classic colors
	var CLASSIC_COLOR: RegEx = RegEx.new()
	var _cc = CLASSIC_COLOR.compile("\\\\c([0-9])")
	var classic_matches: Array = CLASSIC_COLOR.search_all(message)
	
	# Hex colors
	var HEX_COLOR: RegEx = RegEx.new()
	var _hc = HEX_COLOR.compile("<color:([a-fA-F0-9]{6})>")
	var hex_matches: Array = HEX_COLOR.search_all(message)
	
	# Apply classic colors
	for m in classic_matches:
		var r_str: String = m.get_string()
		var hex: String = CHAT_COLOR_CODES[int(r_str[2])].to_html()
		message = message.replace(r_str, "[color=#%s]" % hex)
		message += "[/color]"
	
	# Apply hex colors
	for m in hex_matches:
		var r_str: String = m.get_string()
		var hex: String = r_str.substr(7, 6)
		message = message.replace(r_str, "[color=#%s]" % Util.unjank_hex(hex))
		message += "[/color]"
	
	return message

static func convert_decimal_color(from: int):
	var r: int = (from >> 16) & 0xff
	var g: int = (from >> 8) & 0xff
	var b: int = from & 0xff
	return Color(float(b) / 255, float(g) / 255, float(r) / 255)

static func unjank_hex(from: String):
	var has_pound: bool = false
	if (from[0] == '#'):
		has_pound = true
		from = from.substr(1)
	var fixed: String = "%s%s%s" % [from.substr(4, 2), from.substr(2, 2), from.substr(0, 2)]
	if (has_pound):
		return "#%s" % fixed
	return fixed
