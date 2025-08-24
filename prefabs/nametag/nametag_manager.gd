extends Control
class_name NametagManager

var mapping: Dictionary = {}
var font: Font = preload("res://prefabs/nametag/nametag_font.tres")
var space_state: PhysicsDirectSpaceState

func _ready():
	space_state = $WorldGetter.get_world().get_direct_space_state()
	$WorldGetter.queue_free()

func create_nametag(parent: NametagInstance, text: String):
	mapping[parent] = text

func _process(delta):
	update()

func _draw():
	var cam: Camera = get_viewport().get_camera()
	for parent in mapping.keys():
		if (!parent.visible): continue
		var new_pos: Vector2 = cam.unproject_position(parent.global_transform.origin)
		var hit = space_state.intersect_ray(parent.global_transform.origin, cam.global_transform.origin)
		if (!hit):
			var text: String = mapping[parent]
			var offset: Vector2 = font.get_string_size(text) / 2.0
			draw_string(font, new_pos - offset, text, parent.color)
