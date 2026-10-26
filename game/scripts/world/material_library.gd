## 質感の一覧（data/materials.json）。モデルの材質名を、質感画像つきの材質に置き換える。
## 画像は空間に投影して貼る（トリプラナー）ので、モデル側の UV 設定は不要。
class_name MaterialLibrary
extends RefCounted

const DATA := "res://data/materials.json"
const TEXTURES := "res://assets/textures/%s/%s.jpg"

static var _specs := {}
static var _aliases := {}
static var _cache := {}

static func _load() -> void:
	if not _specs.is_empty():
		return
	var raw = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	if typeof(raw) != TYPE_DICTIONARY:
		push_warning("MaterialLibrary: cannot parse %s" % DATA)
		return
	_specs = raw
	for name in _specs:
		for a in _specs[name].get("aliases", []):
			_aliases[a] = name

## 一覧の名前から材質を返す（同じ名前には同じ材質を返す）。なければ null
static func material(name: String) -> StandardMaterial3D:
	_load()
	if _cache.has(name):
		return _cache[name]
	if not _specs.has(name):
		return null
	var spec: Dictionary = _specs[name]
	var m := StandardMaterial3D.new()
	m.resource_name = "lib_" + name
	if not spec.has("texture"):
		# 画像を使わない材質（ガラスなど）
		var c: Array = spec.get("color", [1.0, 1.0, 1.0, 1.0])
		m.albedo_color = Color(c[0], c[1], c[2], c[3] if c.size() > 3 else 1.0)
		m.roughness = spec.get("roughness", 1.0)
		m.metallic = spec.get("metallic", 0.0)
		m.metallic_specular = spec.get("specular", 0.5)
		if m.albedo_color.a < 1.0:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_cache[name] = m
		return m
	var tex: String = spec["texture"]
	m.albedo_texture = load(TEXTURES % [tex, "albedo"])
	var tint: Array = spec.get("tint", [1.0, 1.0, 1.0])
	m.albedo_color = Color(tint[0], tint[1], tint[2])
	m.normal_enabled = true
	m.normal_texture = load(TEXTURES % [tex, "normal"])
	m.normal_scale = spec.get("normal_scale", 1.0)
	m.roughness_texture = load(TEXTURES % [tex, "roughness"])
	m.roughness = spec.get("roughness", 1.0)
	m.metallic = spec.get("metallic", 0.0)
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 4.0
	m.uv1_scale = Vector3.ONE / float(spec.get("meters", 1.0))
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_cache[name] = m
	return m

## モデルの材質名（Blender で付けた名前）から一覧の材質を返す。なければ null
static func for_source(source_name: String) -> StandardMaterial3D:
	_load()
	return material(_aliases[source_name]) if _aliases.has(source_name) else null

## node 以下のメッシュの材質を置き換える。置き換えた面の数を返す
static func apply(node: Node) -> int:
	var count := 0
	for mi in node.find_children("*", "MeshInstance3D", true, false) + ([node] if node is MeshInstance3D else []):
		var mesh: Mesh = (mi as MeshInstance3D).mesh
		if mesh == null:
			continue
		for i in mesh.get_surface_count():
			var src := mesh.surface_get_material(i)
			if src == null:
				continue
			var lib := for_source(src.resource_name)
			if lib:
				(mi as MeshInstance3D).set_surface_override_material(i, lib)
				count += 1
	return count
