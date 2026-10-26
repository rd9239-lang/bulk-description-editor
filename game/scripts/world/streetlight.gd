## 街灯。子に streetlight.glb（LampHead / LightAnchor）を持ち、点灯状態を光と発光に反映する。
## signal_id も Flicker もなければ常時点灯。always_off なら消えたまま。
class_name Streetlight
extends SignalSource

@export var always_off := false
@export var light_color := Color(1.0, 0.82, 0.55)

var _light: OmniLight3D
var _emit_mat: StandardMaterial3D

func _ready() -> void:
	super._ready()
	var anchor := find_child("LightAnchor", true, false) as Node3D
	_light = OmniLight3D.new()
	_light.light_color = light_color
	_light.light_energy = 2.0
	_light.omni_range = 12.0
	_light.shadow_enabled = true
	if anchor:
		anchor.add_child(_light)
	else:
		_light.position = Vector3(0, 4.5, 0)
		add_child(_light)
	var head := find_child("LampHead", true, false) as MeshInstance3D
	if head and head.mesh:
		var base := head.mesh.surface_get_material(0)
		_emit_mat = (base.duplicate() if base is StandardMaterial3D else StandardMaterial3D.new())
		_emit_mat.emission = light_color
		head.set_surface_override_material(0, _emit_mat)
	toggled.connect(_apply)
	var steady := cycle_length_ms() == 0
	if always_off:
		is_on = false
	elif steady:
		is_on = true
	_apply(is_on)

func _apply(on: bool) -> void:
	_light.visible = on and not always_off
	if _emit_mat:
		_emit_mat.emission_enabled = on and not always_off
