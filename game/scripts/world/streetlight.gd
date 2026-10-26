## 街灯。子に streetlight.glb（LampHead / LightAnchor）を持ち、点灯状態を光と発光に反映する。
## 下向きのスポットライトで路面を照らし（霧の中に光の円すいが浮かぶ）、灯具のまわりは小さな点光源で明るくする。
## signal_id も Flicker もなければ常時点灯。always_off なら消えたまま。
class_name Streetlight
extends SignalSource

@export var always_off := false
@export var light_color := Color(1.0, 0.8, 0.52)

var _light: SpotLight3D
var _halo: OmniLight3D
var _emit_mat: StandardMaterial3D

func _ready() -> void:
	super._ready()
	var anchor := find_child("LightAnchor", true, false) as Node3D
	_light = SpotLight3D.new()
	_light.light_color = light_color
	_light.light_energy = 9.0
	_light.spot_range = 14.0
	_light.spot_angle = 52.0
	_light.spot_angle_attenuation = 1.6
	_light.rotation_degrees.x = -90.0
	_halo = OmniLight3D.new()
	_halo.light_color = light_color
	_halo.light_energy = 1.2
	_halo.omni_range = 2.5
	_halo.light_volumetric_fog_energy = 0.6
	var parent: Node3D = anchor if anchor else self
	if anchor == null:
		_light.position = Vector3(0, 4.5, 0)
		_halo.position = Vector3(0, 4.5, 0)
	parent.add_child(_light)
	parent.add_child(_halo)
	apply_quality(GraphicsSettings.quality)
	var head := find_child("LampHead", true, false) as MeshInstance3D
	if head and head.mesh:
		var base := head.mesh.surface_get_material(0)
		_emit_mat = (base.duplicate() if base is StandardMaterial3D else StandardMaterial3D.new())
		_emit_mat.emission = light_color
		_emit_mat.emission_energy_multiplier = 6.0
		head.set_surface_override_material(0, _emit_mat)
	toggled.connect(_apply)
	var steady := cycle_length_ms() == 0
	if always_off:
		is_on = false
	elif steady:
		is_on = true
	_apply(is_on)

func apply_quality(q: StringName) -> void:
	GraphicsSettings.configure_lamp(_light, q)

func signal_point() -> Vector3:
	return _light.global_position if _light else global_position + Vector3(0, 4.5, 0)

func _apply(on: bool) -> void:
	var lit := on and not always_off
	_light.visible = lit
	_halo.visible = lit
	if _emit_mat:
		_emit_mat.emission_enabled = lit
