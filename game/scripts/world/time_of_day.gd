## 時間帯の切り替え（夜／曇りの夕方）。環境と空、月（夕方は低い西日）、環境音をまとめて変える。
class_name TimeOfDay
extends RefCounted

static var current: StringName = &"night"

static func apply(main: Node, tod: StringName) -> void:
	current = tod
	var we := main.get_node_or_null("WorldEnv") as WorldEnvironment
	if we:
		we.environment = GraphicsSettings.build_environment(GraphicsSettings.quality, tod)
	var moon := main.get_node_or_null("Moon") as DirectionalLight3D
	if moon:
		if tod == &"dusk":
			moon.light_color = Color(1.0, 0.62, 0.38)
			moon.light_energy = 0.55
			moon.rotation_degrees = Vector3(-8, -80, 0)
		else:
			moon.light_color = Color(0.55, 0.65, 0.9)
			moon.light_energy = 0.3
			moon.rotation_degrees = Vector3(-35, 30, 0)
	var amb := main.get_node_or_null("Ambience")
	if amb and amb.has_method("set_time_of_day"):
		amb.set_time_of_day(tod)
