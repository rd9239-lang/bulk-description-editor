## 第2章「前の移住者」の進行役。人物と調べる物を置き、目標の切り替わり・時間帯・つきまとい・
## 一斉停電・窓の写真をつなぐ。会話や演出は、ほかの会話が開いている間は閉じるまで待ってから出す。
class_name Chapter2
extends Node

const CH2 := "res://data/dialogue/ch2.json"
const HOME_POS := Vector3(56.5, 0.1, 6.5)
const DORM_DOOR := Vector3(78, 0, 4.2)
const UNDER_PLANT_LAMP := Vector3(118, 0, -5.2)
const EARPHONE_POS := Vector3(124, 1.0, -16.5)
## 写真を撮る位置（路地の SOS の街灯の下）と、向ける先（自宅の窓）
const PHOTO_CAM := Vector3(55, 1.6, -8.6)
const PHOTO_TARGET := Vector3(55, 1.4, 4.12)
const FOLLOW_LINES := 4
const TABLE_TOP := 0.85
const VIBRATE := "res://assets/audio/phone_vibrate.ogg"

var main: SliceMain
var follower: Follower
var popup: PhonePopup
var feed: PhoneFeed
var grid: PowerGrid
## 停電の静けさと、再点灯の間隔（秒）。テストでは短くする
var blackout_hold := 3.0
var blackout_interval := 0.35

var _entered := false
var _calling := false
var _photo: Texture2D
var _vibrate: AudioStreamPlayer3D
var _vibrate_timer: Timer

func setup(m: SliceMain) -> void:
	main = m
	name = "Ch2"
	m.add_child(self)
	feed = PhoneFeed.new()
	add_child(feed)
	grid = PowerGrid.new()
	add_child(grid)
	popup = PhonePopup.new()
	m.ui_layer.add_child(popup)
	_build_items()
	follower = Follower.new()
	follower.name = "Follower"
	m.add_child(follower)
	follower.deactivate()
	follower.body.interacted.connect(_on_follower_talk)
	MaterialLibrary.apply(self)
	feed.delivered.connect(_on_delivered)
	m.flow.goal_changed.connect(on_goal_changed)
	m.flow.goal_completed.connect(_on_goal_completed)
	m.flow.time_of_day_changed.connect(_on_time_changed)
	m.scares.custom_scare.connect(_on_custom_scare)

# ---------- 置く物 ----------

func _build_items() -> void:
	var phone := _item("Phone", EastDistrict.mesh("Phone"), Vector3(55.0, TABLE_TOP, 6.32), Vector3(0.2, 0.05, 0.25), "phone_1", &"ch2_phone", &"ch2_phone")
	phone.interacted.connect(func(_t): if main.flow.current_goal() == &"ch2_phone": feed.deliver(&"bank_address"))
	_vibrate = AudioStreamPlayer3D.new()
	_vibrate.bus = AudioMixer.INDOOR
	if ResourceLoader.exists(VIBRATE):
		_vibrate.stream = load(VIBRATE)
	phone.add_child(_vibrate)
	_vibrate_timer = Timer.new()
	_vibrate_timer.wait_time = 3.0
	_vibrate_timer.timeout.connect(func(): if _vibrate.stream: _vibrate.play())
	add_child(_vibrate_timer)
	_item("Memo", EastDistrict.mesh("Memo"), Vector3(55.95, TABLE_TOP, 6.3), Vector3(0.2, 0.05, 0.15), "memo")
	EastDistrict.prop(main, "Stove", "Stove", Vector3(57.2, SliceMain.FLOOR_Y, 7.55), 180, Vector3(0.6, 0.86, 0.45))
	MaterialLibrary.apply(main.get_node("Stove"))
	_item("Kettle", EastDistrict.mesh("Kettle"), Vector3(57.3, SliceMain.FLOOR_Y + 0.89, 7.5), Vector3(0.3, 0.25, 0.3), "coffee_1", &"ch2_coffee", &"ch2_coffee")
	var glint := BoxMesh.new()
	glint.size = Vector3(0.05, 0.012, 0.04)
	glint.material = MaterialLibrary.material("steel")
	_item("DeadLampRelic", glint, Vector3(44.2, 0.02, -2.1), Vector3(0.5, 0.3, 0.5), "relic_watch", &"ch2_dead_lamp", &"ch2_dead_lamp", &"watch")
	_person("OldMan", Vector3(1.2, 0, -3.5), 0, Color(0.33, 0.3, 0.25), "old_man_1", &"ch2_old_man", &"ch2_old_man", "")
	_person("Returnee", Vector3(78.6, 0.05, 8.6), 180, Color(0.3, 0.3, 0.33), "returnee_1", &"ch2_dorm", &"ch2_dorm", "ship")
	_item("NoticeBoard", null, Vector3(95, 0.85, -5.35), Vector3(1.4, 0.9, 0.25), "board", &"ch2_ruins")
	var paper := BoxMesh.new()
	paper.size = Vector3(0.22, 0.008, 0.12)
	paper.material = MaterialLibrary.material("paper")
	_item("Letter", paper, Vector3(100.2, 0.81, -11.0), Vector3(0.3, 0.1, 0.2), "relic_letter", &"ch2_ruins", &"", &"letter")
	_item("Switchboard", null, Vector3(121, 0.3, -17.35), Vector3(2.4, 1.6, 0.2), "switchboard", &"ch2_power_plant", &"ch2_power_plant")
	_item("Locker", null, Vector3(114.85, 0.1, -12), Vector3(0.2, 1.6, 0.9), "relic_nametag", &"", &"", &"nametag")
	for n in ["Memo", "OldMan", "Returnee", "Locker"]:
		_set_present(get_node(n), false)

## 調べられる物。当たりは底面から立つ箱（size）。mesh があれば見た目も置く
func _item(item_name: String, mesh: Mesh, pos: Vector3, size: Vector3, node: String, goal: StringName = &"", completes: StringName = &"", relic: StringName = &"") -> Interactable:
	var it := Interactable.new()
	it.name = item_name
	it.dialogue_file = CH2
	it.dialogue_node = node
	it.active_goal = goal
	it.completes_goal = completes
	it.relic_id = relic
	if mesh:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		it.add_child(mi)
	BuildUtil.col(it, size, Vector3(0, size.y / 2, 0))
	add_child(it)
	it.global_position = pos
	it.interacted.connect(main._on_interacted)
	return it

## 人物（仮の人型を服の色で区別する）。モデルは +Z を向く
func _person(person_name: String, pos: Vector3, rot_y: float, color: Color, node: String, goal: StringName, completes: StringName, knock_kind: String) -> Interactable:
	var it := _item(person_name, null, pos, Vector3(0.5, 1.8, 0.5), node, goal, completes)
	it.knock = knock_kind
	it.rotation_degrees.y = rot_y
	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = StreetDressing.mesh("Mannequin_F")
	if body.mesh:
		for i in body.mesh.get_surface_count():
			var src := body.mesh.surface_get_material(i)
			if src and src.resource_name == "npc_cloth":
				var m := StandardMaterial3D.new()
				m.albedo_color = color
				m.roughness = 0.9
				body.set_surface_override_material(i, m)
	it.add_child(body)
	return it

func _set_present(n: Node3D, on: bool) -> void:
	n.visible = on
	if n is CollisionObject3D:
		(n as CollisionObject3D).collision_layer = 1 if on else 0

# ---------- 章の流れ ----------

## 第2章に入ったときの準備（妻は留守、老人と書き置きが現れる）。何度呼んでもよい
func enter_chapter2() -> void:
	if _entered:
		return
	_entered = true
	var wife := main.get_node_or_null("Wife") as Node3D
	if wife:
		_set_present(wife, false)
	for n in ["Memo", "OldMan", "Locker"]:
		_set_present(get_node(n), true)
	if not ChapterFlow.GOALS.find(main.flow.current_goal()) > ChapterFlow.GOALS.find(&"ch2_dorm"):
		_set_present(get_node("Returnee"), true)
	var taps := FingerTaps.new()
	taps.name = "FingerTaps"
	taps.signal_id = &"oldman_nigero"
	add_child(taps)
	taps.global_position = Vector3(1.9, 0.47, -3.3)

func on_goal_changed(goal: StringName) -> void:
	var idx := ChapterFlow.GOALS.find(goal)
	if idx < ChapterFlow.CHAPTER2_START:
		return
	enter_chapter2()
	if goal == &"ch2_phone":
		_vibrate_timer.start()
	else:
		_vibrate_timer.stop()
	if idx >= ChapterFlow.GOALS.find(&"ch2_earphone"):
		_ensure_earphone()
	if goal == &"ch2_window":
		var w := main.get_node("Window") as Interactable
		w.dialogue_file = CH2
		w.dialogue_node = "window_ch2"
		w.active_goal = &"ch2_window"
		w.completes_goal = &"ch2_window"

func _on_goal_completed(goal: StringName) -> void:
	match goal:
		&"ch2_old_man":
			open_east()
			main._show_toast(tr("ui_east_open"))
		&"ch2_dorm":
			start_following(DORM_DOOR)

func open_east() -> void:
	main.get_node("/root/GameState").flags["east_open"] = true
	EastDistrict.set_east_open(main, true)

func start_following(at: Vector3) -> void:
	_set_present(get_node("Returnee"), false)
	follower.activate(at)

func _ensure_earphone() -> void:
	if has_node("Earphone"):
		return
	var e := EarphoneSignal.new()
	e.name = "Earphone"
	e.signal_id = &"sos_a_earphone"
	add_child(e)
	e.global_position = EARPHONE_POS

## 夕方の始まり（自宅で目を覚ます）と「その夜」：暗転して時間帯を切り替える
func _on_time_changed(tod: StringName) -> void:
	await _wait_dialogue_closed()
	main.player.input_enabled = false
	await _fade(1.0, 0.6)
	if tod == &"dusk":
		main.player.global_position = HOME_POS
		main.player.velocity = Vector3.ZERO
	TimeOfDay.apply(main, tod)
	if tod == &"night":
		main._show_card(tr("ui_that_night"))
	await get_tree().create_timer(0.4).timeout
	await _fade(0.0, 0.8)
	main.player.input_enabled = true

func _fade(alpha: float, sec: float) -> void:
	var o := main._overlay
	if alpha > 0.0 and not o.visible:
		o.color = Color.BLACK
		o.modulate.a = 0.0
		o.visible = true
	var tw := create_tween()
	tw.tween_property(o, "modulate:a", alpha, sec)
	await tw.finished
	if alpha == 0.0:
		o.visible = false
		o.modulate.a = 1.0

## 自宅に入ったとき：夜の目標が「母に電話」なら電話をかける
func on_home_entered() -> void:
	if main.flow.current_goal() != &"ch2_call_mother" or _calling:
		return
	_calling = true
	await say("call_mother_1", &"ch2_call_mother")
	_calling = false

## 会話を出す（ほかの会話が開いていれば閉じるまで待つ）。終わったら completes の目標を完了する
func say(node: String, completes: StringName = &"") -> void:
	await _wait_dialogue_closed()
	main.player.input_enabled = false
	main.dialogue.open(CH2, node)
	await _wait_dialogue_closed()
	main.player.input_enabled = true
	if completes != &"":
		main.flow.complete(completes)

func _wait_dialogue_closed() -> void:
	while main.dialogue.visible or main._pending != null:
		await get_tree().process_frame

## つきまとう男に話しかけると、断片的なひとことを順に返す
func _on_follower_talk(_t: Interactable) -> void:
	if main.dialogue.visible:
		return
	var gs: GameStateData = main.get_node("/root/GameState")
	var n := int(gs.flags.get("follow_line", 0)) + 1
	gs.flags["follow_line"] = n
	say("returnee_follow_%d" % ((n - 1) % FOLLOW_LINES + 1))

func _on_delivered(note: Dictionary) -> void:
	popup.show_note(note, _photo if note.get("photo", false) else null)

# ---------- 驚かせる演出 ----------

func _on_custom_scare(s: Dictionary) -> void:
	match s["kind"]:
		"blackout":
			_blackout(s)
		"window_photo":
			_window_photo()

## 一斉停電：島じゅうの灯りが消え、遠くから順に点き直る。最後に発電所の入口の灯りの下に男が立っている
func _blackout(s: Dictionary) -> void:
	grid.cut()
	var lamp := main.get_node(s.get("lamp_path", "East/PlantLamp")) as Streetlight
	await grid.restore(main.player.global_position, lamp, blackout_interval, blackout_hold)
	if follower.active:
		follower.place(UNDER_PLANT_LAMP)
	else:
		start_following(UNDER_PLANT_LAMP)
	main.scares.play_sound(s.get("sound", ""))
	await say("returnee_back")

## 自分の窓の写真：路地から、いま窓辺に立つ自分を撮った写真が投稿される
func _window_photo() -> void:
	await _wait_dialogue_closed()
	main.player.input_enabled = false
	var p := main.player.global_position
	var img: Image = await PhotoCapture.capture(main, PHOTO_CAM, PHOTO_TARGET, Vector3(p.x, SliceMain.FLOOR_Y, p.z))
	_photo = ImageTexture.create_from_image(img)
	feed.deliver(&"sns_like")
	await popup.closed
	await say("me_photo")
	main._show_card(tr("ui_ch2_end"), 6.0)
