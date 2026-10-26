## 光や音で信号を発する物の共通部分。周期は timeline の合計＋休み。
class_name SignalSource
extends Node3D

signal cycle_completed(signal_id: StringName)
signal toggled(on: bool)

@export var signal_id: StringName = &""
@export var seed := 0

var is_on := false
var phase_ms := 0
var _timeline := PackedInt32Array()
var _pause_ms := 0
var _cycle_ms := 0

static var _registry := {}

static func registry() -> Dictionary:
	if _registry.is_empty():
		_registry = SignalDef.load_all("res://data/signals.json")
	return _registry

func configure(def: SignalDef) -> void:
	signal_id = def.id
	configure_raw(def.timeline(seed), def.loop_pause_ms)

func configure_raw(timeline: PackedInt32Array, pause_ms: int) -> void:
	_timeline = timeline
	_pause_ms = pause_ms
	_cycle_ms = pause_ms
	for ms in timeline:
		_cycle_ms += ms
	phase_ms = 0
	_update_state()

func _ready() -> void:
	if _timeline.is_empty() and signal_id != &"" and registry().has(signal_id):
		configure(registry()[signal_id])
	var gs := get_node_or_null("/root/GameState")
	if gs and gs.signal_phase.has(signal_id):
		advance(gs.signal_phase[signal_id])

func _process(delta: float) -> void:
	if _cycle_ms == 0:
		return
	advance(int(delta * 1000.0))
	var gs := get_node_or_null("/root/GameState")
	if gs and signal_id != &"":
		gs.signal_phase[signal_id] = phase_ms

func cycle_length_ms() -> int:
	return _cycle_ms

func advance(delta_ms: int) -> void:
	if _cycle_ms <= 0:
		return
	phase_ms += delta_ms
	while phase_ms >= _cycle_ms:
		phase_ms -= _cycle_ms
		cycle_completed.emit(signal_id)
	_update_state()

func _update_state() -> void:
	var on := false
	var t := phase_ms
	for i in _timeline.size():
		if t < _timeline[i]:
			on = i % 2 == 0
			break
		t -= _timeline[i]
	if on != is_on:
		is_on = on
		toggled.emit(on)
