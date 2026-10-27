## 音の通り道（バス）。屋外の音は Outdoor、屋内の音は Indoor、足音や演出は SFX に流す。
## 屋内に入ると屋外の音をこもらせて小さくし、屋内の音（部屋の静けさ・ラジオ）を上げる。
class_name AudioMixer
extends RefCounted

const OUTDOOR := "Outdoor"
const INDOOR := "Indoor"
const SFX := "SFX"
const INDOOR_OUTDOOR_DB := -9.0
const OUTDOOR_INDOOR_DB := -30.0
const MUFFLE_HZ := 900.0

static func ensure_buses() -> void:
	for name in [OUTDOOR, INDOOR, SFX]:
		if AudioServer.get_bus_index(name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, name)
			AudioServer.set_bus_send(idx, "Master")
			if name == OUTDOOR:
				var lp := AudioEffectLowPassFilter.new()
				lp.cutoff_hz = MUFFLE_HZ
				AudioServer.add_bus_effect(idx, lp, 0)
				AudioServer.set_bus_effect_enabled(idx, 0, false)
	set_indoor(false)

static func set_indoor(indoor: bool) -> void:
	var out := AudioServer.get_bus_index(OUTDOOR)
	var ind := AudioServer.get_bus_index(INDOOR)
	if out == -1 or ind == -1:
		return
	AudioServer.set_bus_volume_db(out, INDOOR_OUTDOOR_DB if indoor else 0.0)
	AudioServer.set_bus_effect_enabled(out, 0, indoor)
	AudioServer.set_bus_volume_db(ind, 0.0 if indoor else OUTDOOR_INDOOR_DB)

## OGG をループ再生できる状態で読み込む
static func load_loop(path: String) -> AudioStream:
	var s: AudioStream = load(path)
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true
	return s
