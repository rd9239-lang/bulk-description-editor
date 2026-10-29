## 島じゅうの灯りの一斉停電と再点灯。街灯はグループ "streetlights"、部屋の灯りは "room_lights"。
## 再点灯は遠い街灯からこちらへ向かって順に「カチッ」と点き、最後に指定の街灯が点く。
class_name PowerGrid
extends Node

signal restored

const DOWN := "res://assets/audio/power_down.ogg"
const CLICK := "res://assets/audio/lamp_click.ogg"

var _down: AudioStreamPlayer

func _ready() -> void:
	_down = AudioStreamPlayer.new()
	_down.bus = AudioMixer.SFX
	if ResourceLoader.exists(DOWN):
		_down.stream = load(DOWN)
	add_child(_down)

func cut() -> void:
	for l in get_tree().get_nodes_in_group("streetlights"):
		(l as Streetlight).set_power(false)
	for r in get_tree().get_nodes_in_group("room_lights"):
		(r as Node3D).visible = false
	if _down.stream:
		_down.play()

## 点け直す順番：last 以外を origin から遠い順、最後に last
static func restore_order(lights: Array, origin: Vector3, last: Node3D) -> Array:
	var rest := lights.filter(func(l): return is_instance_valid(l) and l != last)
	rest.sort_custom(func(a, b): return a.global_position.distance_to(origin) > b.global_position.distance_to(origin))
	rest.append(last)
	return rest

func restore(origin: Vector3, last: Streetlight, interval := 0.35, hold := 3.0) -> void:
	await get_tree().create_timer(hold).timeout
	for l in restore_order(get_tree().get_nodes_in_group("streetlights"), origin, last):
		if not is_instance_valid(l) or l == last:
			continue
		_power_on(l)
		await get_tree().create_timer(interval).timeout
	for r in get_tree().get_nodes_in_group("room_lights"):
		(r as Node3D).visible = true
	if is_instance_valid(last):
		_power_on(last)
	restored.emit()

func _power_on(l: Streetlight) -> void:
	l.set_power(true)
	if not ResourceLoader.exists(CLICK):
		return
	var p := AudioStreamPlayer3D.new()
	p.stream = load(CLICK)
	p.bus = AudioMixer.OUTDOOR
	p.unit_size = 3.0
	p.max_distance = 40.0
	l.add_child(p)
	p.global_position = l.signal_point()
	p.finished.connect(p.queue_free)
	p.play()
