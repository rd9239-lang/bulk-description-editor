## 島の環境音：岸の波、夜風、草むらの虫、部屋の静けさ、ときどき沖から聞こえる汽笛。
class_name Ambience
extends Node3D

const AUDIO := "res://assets/audio/%s.ogg"
## 虫が鳴く草むら（道の両脇の空き地）
const INSECT_SPOTS := [Vector3(4, 0.2, 7), Vector3(18, 0.2, -9), Vector3(30, 0.2, 8), Vector3(44, 0.2, -9), Vector3(50, 0.2, 9), Vector3(62, 0.2, -8)]

var _rng := RandomNumberGenerator.new()
var _horn_timer: Timer

const INSECTS_DB := {&"night": -8.0, &"dusk": -14.0}
const WIND_DB := {&"night": -16.0, &"dusk": -12.0}

## 夕方は虫が少なく風が強め、夜は虫がよく鳴く
func set_time_of_day(tod: StringName) -> void:
	for i in INSECT_SPOTS.size():
		var p := get_node_or_null("Insects%d" % i) as AudioStreamPlayer3D
		if p:
			p.volume_db = INSECTS_DB.get(tod, -8.0)
	var w := get_node_or_null("Wind") as AudioStreamPlayer
	if w:
		w.volume_db = WIND_DB.get(tod, -16.0)

static func next_horn_delay(rng: RandomNumberGenerator) -> float:
	return rng.randf_range(35.0, 80.0)

func _ready() -> void:
	AudioMixer.ensure_buses()
	_rng.randomize()
	_spot("Waves", "amb_waves", Vector3(-3, 0, 0), -2.0, 12.0, 80.0)
	for i in INSECT_SPOTS.size():
		var p := _spot("Insects%d" % i, "amb_insects", INSECT_SPOTS[i], -8.0, 3.0, 22.0)
		p.pitch_scale = 0.94 + 0.03 * i
	var wind := AudioStreamPlayer.new()
	wind.name = "Wind"
	wind.stream = AudioMixer.load_loop(AUDIO % "amb_wind")
	wind.volume_db = -16.0
	wind.bus = AudioMixer.OUTDOOR
	wind.autoplay = true
	add_child(wind)
	var room := AudioStreamPlayer.new()
	room.name = "RoomTone"
	room.stream = AudioMixer.load_loop(AUDIO % "amb_room")
	room.volume_db = -22.0
	room.bus = AudioMixer.INDOOR
	room.autoplay = true
	add_child(room)
	var horn := AudioStreamPlayer3D.new()
	horn.name = "Horn"
	horn.stream = load(AUDIO % "ship_horn")
	horn.position = Vector3(-70, 6, 40)
	horn.unit_size = 60.0
	horn.max_distance = 400.0
	horn.volume_db = -4.0
	horn.bus = AudioMixer.OUTDOOR
	add_child(horn)
	_horn_timer = Timer.new()
	_horn_timer.one_shot = true
	_horn_timer.timeout.connect(_on_horn)
	add_child(_horn_timer)
	_horn_timer.start(next_horn_delay(_rng))

func _spot(name: String, sound: String, pos: Vector3, db: float, unit: float, max_d: float) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.name = name
	p.stream = AudioMixer.load_loop(AUDIO % sound)
	p.position = pos
	p.volume_db = db
	p.unit_size = unit
	p.max_distance = max_d
	p.bus = AudioMixer.OUTDOOR
	p.autoplay = true
	add_child(p)
	return p

func _on_horn() -> void:
	($Horn as AudioStreamPlayer3D).play()
	_horn_timer.start(next_horn_delay(_rng))
