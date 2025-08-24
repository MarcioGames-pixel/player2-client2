extends Spatial
class_name Avatar

const TEXTURE_DEFAULT_FACE: StreamTexture = preload("res://prefabs/avatar/default_face.png")
const SURFACE_TORSO: int = 0
const SURFACE_LEFT_ARM: int = 1
const SURFACE_LEFT_LEG: int = 2
const SURFACE_RIGHT_ARM: int = 3
const SURFACE_RIGHT_LEG: int = 4
onready var animation_player: AnimationPlayer = $Rig/AnimationPlayer
onready var animation_tree: AnimationTree = $Rig/AnimationTree
onready var rig: Spatial = $Rig
onready var mesh_head: MeshInstance = $Rig/FigureArmature/Skeleton/HeadMesh
onready var mesh_figure: MeshInstance = $Rig/FigureArmature/Skeleton/FigureMesh
onready var mesh_tshirt: MeshInstance = $Rig/FigureArmature/Skeleton/TShirt/TShirtMesh
onready var mesh_tool: MeshInstance = $Rig/FigureArmature/Skeleton/Tool/Offset/ToolMesh
var hats: Dictionary = {}
var arm_up: bool = false

func _ready():
	# Make materials unique
	for s in [SURFACE_TORSO, SURFACE_LEFT_ARM, SURFACE_LEFT_LEG, SURFACE_RIGHT_ARM, SURFACE_RIGHT_LEG]:
		var mat: ShaderMaterial = mesh_figure.mesh.surface_get_material(s).duplicate()
		mesh_figure.mesh.surface_set_material(s, mat)
	var head_mat: ShaderMaterial = mesh_head.mesh.surface_get_material(0).duplicate()
	mesh_head.mesh.surface_set_material(0, head_mat)

func set_animation(anim: int):
	animation_tree["parameters/current_state/current"] = anim

func get_animation():
	return animation_tree["parameters/current_state/current"]

func set_shadow_mode(mode: int):
	mesh_figure.cast_shadow = mode
	mesh_head.cast_shadow = mode

func set_head_color(value: Color):
	var mat: ShaderMaterial = mesh_head.mesh.surface_get_material(0)
	mat.set_shader_param("tint", value)

func set_figure_color(surface: int, value: Color):
	var mat: ShaderMaterial = mesh_figure.mesh.surface_get_material(surface)
	mat.set_shader_param("tint", value)

func set_tool(tool_id: int):
	mesh_tool.visible = false;
	if (tool_id == 0):
		arm_up = false
	else:
		var mat: SpatialMaterial = mesh_tool.get("material_override")
		mat.albedo_texture = null
		var mesh_fetch: GDScriptFunctionState = AssetCache.fetch(tool_id, AssetCache.TYPE_MESH)
		var loaded_mesh: ArrayMesh = yield(mesh_fetch, "completed")
		mesh_tool.mesh = loaded_mesh
		arm_up = true
		mesh_tool.visible = true;
		var tex_fetch: GDScriptFunctionState = AssetCache.fetch(tool_id, AssetCache.TYPE_TEXTURE)
		var loaded_tex: Texture = yield(tex_fetch, "completed")
		mat.albedo_texture = loaded_tex

func set_hat(slot: int, hat_id: int):
	if (hats.has(slot)):
		hats.get(slot).queue_free()
		if (hat_id <= 0):
			hats.erase(slot)
			return
	var new_hat: Spatial = Loader.Hat.instance()
	new_hat.id = hat_id
	$Rig/FigureArmature/Skeleton/Hats/Offset.add_child(new_hat)
	hats[slot] = new_hat

func set_face(face_id: int):
	var mat: ShaderMaterial = mesh_head.mesh.surface_get_material(0)
	if (face_id <= 0):
		mat.set_shader_param("face", TEXTURE_DEFAULT_FACE)
	else:
		var tex_fetch: GDScriptFunctionState = AssetCache.fetch(face_id, AssetCache.TYPE_TEXTURE)
		var loaded_tex: Texture = yield(tex_fetch, "completed")
		mat.set_shader_param("face", loaded_tex)
		mat.set_shader_param("face_enabled", true)

func set_tshirt(tshirt_id: int):
	var mat: SpatialMaterial = mesh_tshirt.mesh.surface_get_material(0)
	if (tshirt_id <= 0):
		mesh_tshirt.visible = false
	else:
		var tex_fetch: GDScriptFunctionState = AssetCache.fetch(tshirt_id, AssetCache.TYPE_TEXTURE)
		var loaded_tex: Texture = yield(tex_fetch, "completed")
		mat.albedo_texture = loaded_tex
		mesh_tshirt.visible = true

func set_shirt(shirt_id: int):
	if (shirt_id <= 0):
		for s in [SURFACE_TORSO, SURFACE_LEFT_ARM, SURFACE_RIGHT_ARM]:
			var mat: ShaderMaterial = mesh_figure.mesh.surface_get_material(s)
			mat.set_shader_param("shirt_enabled", false)
	else:
		var tex_fetch: GDScriptFunctionState = AssetCache.fetch(shirt_id, AssetCache.TYPE_TEXTURE)
		var loaded_tex: Texture = yield(tex_fetch, "completed")
		for s in [SURFACE_TORSO, SURFACE_LEFT_ARM, SURFACE_RIGHT_ARM]:
			var mat: ShaderMaterial = mesh_figure.mesh.surface_get_material(s)
			mat.set_shader_param("shirt", loaded_tex)
			mat.set_shader_param("shirt_enabled", true)

func set_pants(pants_id: int):
	if (pants_id <= 0):
		for s in [SURFACE_TORSO, SURFACE_LEFT_LEG, SURFACE_RIGHT_LEG]:
			var mat: ShaderMaterial = mesh_figure.mesh.surface_get_material(s)
			mat.set_shader_param("pants_enabled", false)
	else:
		var tex_fetch: GDScriptFunctionState = AssetCache.fetch(pants_id, AssetCache.TYPE_TEXTURE)
		var loaded_tex: Texture = yield(tex_fetch, "completed")
		for s in [SURFACE_TORSO, SURFACE_LEFT_LEG, SURFACE_RIGHT_LEG]:
			var mat: ShaderMaterial = mesh_figure.mesh.surface_get_material(s)
			mat.set_shader_param("pants", loaded_tex)
			mat.set_shader_param("pants_enabled", true)
