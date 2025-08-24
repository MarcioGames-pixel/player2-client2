extends MeshInstance

export var id: int = 18785

func _ready():
	# Load mesh
	var mesh_fetch: GDScriptFunctionState = AssetCache.fetch(id, AssetCache.TYPE_MESH)
	var loaded_mesh: ArrayMesh = yield(mesh_fetch, "completed")
	mesh = loaded_mesh
	
	# Load texture
	var tex_fetch: GDScriptFunctionState = AssetCache.fetch(id, AssetCache.TYPE_TEXTURE)
	var loaded_tex: Texture = yield(tex_fetch, "completed")
	var mat: SpatialMaterial = SpatialMaterial.new()
	mat.params_cull_mode = SpatialMaterial.CULL_DISABLED
	mat.albedo_texture = loaded_tex
	material_override = mat

func set_shadow_mode(mode: int):
	cast_shadow = mode
