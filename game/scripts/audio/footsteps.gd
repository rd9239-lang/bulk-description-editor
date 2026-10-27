## 足音。足もとの地面（"surface" のメタ情報）に合わせて音を変え、視点の揺れと同じ間隔で鳴らす。
class_name Footsteps
extends AudioStreamPlayer

const SURFACES := ["asphalt", "gravel", "wood", "tatami"]
const VARIATIONS := 4
const STEPS_PER_SEC := 3.6   # Player.bob_offset の揺れ（1.8Hz の半周期ごと）に合わせる
const DEFAULT_SURFACE := "gravel"

static var _streams := {}
var _last := -1

static func step_index(t: float) -> int:
	return int(floor(t * STEPS_PER_SEC + 1e-6))

## 当たった物（またはその親）に付いた "surface" を探す。なければ砂利
static func surface_for(node: Object) -> String:
	var n := node as Node
	while n:
		if n.has_meta("surface"):
			return n.get_meta("surface")
		n = n.get_parent()
	return DEFAULT_SURFACE

static func stream_for(surface: String, i: int) -> AudioStream:
	var key := "%s_%d" % [surface, i]
	if not _streams.has(key):
		_streams[key] = load("res://assets/audio/step_%s.ogg" % key)
	return _streams[key]

func _ready() -> void:
	bus = AudioMixer.SFX

func play_step(surface: String, quiet: bool) -> void:
	var i := randi() % VARIATIONS
	if i == _last:
		i = (i + 1) % VARIATIONS
	_last = i
	stream = stream_for(surface if surface in SURFACES else DEFAULT_SURFACE, i)
	pitch_scale = randf_range(0.92, 1.08)
	volume_db = -10.0 if quiet else -3.0
	play()
