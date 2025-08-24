extends Node

enum {
	TYPE_TEXTURE = 0,
	TYPE_MESH = 1
}
const ObjParser: Script = preload("res://addons/obj_parser/obj_parser.gd")
const CACHE_DIR: String = "user://cache/"
const RETRIEVE_API: String = "https://api.brick-hill.com/v1/games/retrieveAsset"
var cache: Dictionary = {
	textures = {},
	meshes = {}
}
var loaded

signal fetched

func _ready():
	var check_path: Directory = Directory.new()
	if (!check_path.dir_exists(CACHE_DIR)):
		check_path.make_dir(CACHE_DIR)

func _get_extension(type: int):
	return ["png", "obj"][type]

func fetch(id: int, type: int):
	var extension: String = _get_extension(type)
	var cache_dictionary = [cache.textures, cache.meshes][type]
	var path: String = "%s%s.%s" % [CACHE_DIR, str(id), extension]
	
	# Check memory cache
	if cache_dictionary.has(id):
		yield(get_tree(), "idle_frame")
		return cache_dictionary.get(id)
	
	# Download if not in file cache
	var cache: File = File.new()
	if (!cache.file_exists(path)):
		# Start request
		var dl_url: String = "%s?id=%s&type=%s" % [RETRIEVE_API, str(id), extension]
		var dl: HTTPRequest = HTTPRequest.new()
		dl.use_threads = true
		add_child(dl)
		dl.download_file = path
		dl.request(dl_url, ["user-agent: player2"])
		yield(dl, "request_completed")
		
		# Remove request
		dl.queue_free()
	else:
		yield(get_tree(), "idle_frame")
	
	# Load
	match(type):
		TYPE_TEXTURE:
			loaded = ImageTexture.new()
			var img = Image.new()
			img.load(path)
			loaded.create_from_image(img, 7)
		TYPE_MESH:
			loaded = ObjParser.parse_obj(path)
	cache_dictionary[id] = loaded
	
	emit_signal("fetched")
	return loaded
