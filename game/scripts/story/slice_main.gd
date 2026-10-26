## 縦切り試作のメイン：島の通りを組み立て、会話・手帳・目標・演出・UI をつなぐ。
class_name SliceMain
extends Node3D

const STREETLIGHT := preload("res://assets/models/streetlight.glb")
const POLE := preload("res://assets/models/pole.glb")
const HOUSE_KIT := preload("res://assets/models/house_kit.glb")
const PLAYER := preload("res://scenes/parts/player.tscn")
# Poly Haven（CC0）の小物
const TABLE := preload("res://assets/models/props/wooden_table_02.glb")
const LAPTOP := preload("res://assets/models/props/classic_laptop.glb")
const DRAWER := preload("res://assets/models/props/vintage_wooden_drawer_01.glb")
const CRATE := preload("res://assets/models/props/plastic_crate_02.glb")
const FOOD := preload("res://assets/models/props/long_life_food.glb")
## 床の上面の高さ
const FLOOR_Y := 0.05

## 街灯の配置：位置 → 種類
const LAMPS := {
	Vector3(4, 0, -2.6): "flicker", Vector3(12, 0, -2.6): "flicker", Vector3(20, 0, -2.6): "steady",
	Vector3(28, 0, -2.6): "flicker", Vector3(36, 0, -2.6): "flicker", Vector3(44, 0, -2.6): "dead",
	Vector3(52, 0, -2.6): "flicker",
	# 自宅の窓の正面、路地の突き当たりに一本だけ立つ街灯
	Vector3(55, 0, -9): "sos",
}
## 家の配置：名前 → [原点, 正面の部品（左から）, 奥行きのマス数]
const HOUSES := {
	"House_Jikka": [Vector3(8, 0, 4), ["Wall_2m", "Door_Frame", "Wall_Window_2m"], 2],
	"House_Museum": [Vector3(20, 0, 4), ["Wall_Window_2m", "Door_Frame", "Wall_Window_2m", "Wall_2m"], 3],
	"House_Neighbor": [Vector3(32, 0, 4), ["Door_Frame", "Wall_Window_2m", "Wall_2m"], 2],
	"House_Home": [Vector3(54, 0, 4), ["Wall_Window_2m", "Door_Frame", "Wall_2m"], 2],
	"House_Back1": [Vector3(14, 0, -6), ["Wall_2m", "Wall_Window_2m", "Wall_2m"], 2],
	"House_Back2": [Vector3(40, 0, -6), ["Wall_Window_2m", "Wall_2m", "Wall_Window_2m"], 2],
}

var _kit := {}
var player: Player
var notebook: Notebook
var dialogue: DialogueBox
var flow: ChapterFlow
var scares: ScareDirector
var radio: Radio
var knock: Knock

var _hud_goal: Label
var _hud_prompt: Label
var _card: Label
var _overlay: ColorRect
var _menu: VBoxContainer
var _pending: Interactable
var _pending_ending: StringName = &""

func _ready() -> void:
	_load_kit()
	_build_environment()
	_build_ground()
	_build_street()
	for name in HOUSES:
		var h: Array = HOUSES[name]
		_build_house(name, h[0], h[1], h[2])
	_build_interiors()
	MaterialLibrary.apply(self)
	_build_ui()
	_show_menu()

# ---------- 組み立て ----------

func _load_kit() -> void:
	var kit := HOUSE_KIT.instantiate()
	for c in kit.get_children():
		if c is MeshInstance3D:
			_kit[String(c.name)] = (c as MeshInstance3D).mesh
	kit.free()

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.025, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.25, 0.3, 0.45)
	env.ambient_light_energy = 0.25
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.06, 0.09)
	env.fog_density = 0.03
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.55, 0.65, 0.9)
	moon.light_energy = 0.12
	moon.rotation_degrees = Vector3(-35, 30, 0)
	add_child(moon)

## 箱の地形。look は質感一覧の名前（data/materials.json）
func _box_body(name: String, size: Vector3, pos: Vector3, look: String, parent: Node = self) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name
	body.position = pos
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = MaterialLibrary.material(look)
	mi.mesh = bm
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	parent.add_child(body)
	return body

func _build_ground() -> void:
	_box_body("Ground", Vector3(90, 1, 40), Vector3(30, -0.5, 0), "gravel")
	_box_body("Road", Vector3(74, 0.02, 4), Vector3(31, 0.01, 0), "asphalt")
	_box_body("Pier", Vector3(14, 0.3, 3), Vector3(-9, 0.15, 0), "wood_floor")
	var sea := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 80)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.01, 0.02, 0.04)
	m.roughness = 0.1
	pm.material = m
	sea.mesh = pm
	sea.position = Vector3(-31, -0.4, 0)
	add_child(sea)
	# 桟橋から上がると「到着」
	_area("PierExit", Vector3(3, 3, 6), Vector3(-1, 1.5, 0), func(): flow.complete(&"arrive_pier"))

func _area(name: String, size: Vector3, pos: Vector3, on_enter: Callable) -> void:
	var a := Area3D.new()
	a.name = name
	a.position = pos
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	a.add_child(cs)
	a.body_entered.connect(func(b): if b is Player and flow.is_inside_tree(): on_enter.call())
	add_child(a)

func _build_street() -> void:
	var street := Node3D.new()
	street.name = "Street"
	add_child(street)
	for pos in LAMPS:
		var kind: String = LAMPS[pos]
		var lamp := Streetlight.new()
		lamp.name = "LampSOS" if kind == "sos" else "Lamp%d" % int(pos.x)
		lamp.position = pos
		lamp.rotation_degrees.y = -90
		lamp.add_child(STREETLIGHT.instantiate())
		match kind:
			"sos":
				lamp.signal_id = &"sos_a"
			"dead":
				lamp.always_off = true
			"flicker":
				var f := Flicker.new()
				f.seed = int(pos.x)
				lamp.add_child(f)
		_add_pole_collision(lamp, 0.15, 5.4)
		street.add_child(lamp)
	# 電柱と電線
	var prev: Node3D = null
	for x in range(0, 66, 16):
		var pole := POLE.instantiate() as Node3D
		pole.position = Vector3(x + 8, 0, -4.4)
		street.add_child(pole)
		if prev:
			for side in ["WireAnchor_L", "WireAnchor_R"]:
				_wire(street, prev.position + (prev.find_child(side) as Node3D).position,
					pole.position + (pole.find_child(side) as Node3D).position)
		prev = pole

func _add_pole_collision(parent: Node3D, radius: float, height: float) -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	cs.shape = shape
	cs.position.y = height / 2
	body.add_child(cs)
	parent.add_child(body)

func _wire(parent: Node3D, a: Vector3, b: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.01
	cm.bottom_radius = 0.01
	cm.height = a.distance_to(b)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.03, 0.03, 0.03)
	cm.material = m
	mi.mesh = cm
	parent.add_child(mi)
	mi.global_transform = Transform3D(Basis(), (a + b) / 2)
	mi.look_at((a + b) / 2 + (b - a), Vector3.UP)
	mi.rotate_object_local(Vector3.RIGHT, PI / 2)

## 正面（道路側、ローカル z=0）を部品で、奥と側面を壁で囲う。屋根は波板。
func _build_house(name: String, origin: Vector3, front: Array, depth: int) -> void:
	var house := Node3D.new()
	house.name = name
	house.position = origin
	if origin.z < 0:
		house.rotation_degrees.y = 180
	add_child(house)
	var w := front.size()
	for i in w:
		_piece(house, front[i], Vector3(1 + i * 2, 0, 0), 0)
		_piece(house, "Wall_2m", Vector3(1 + i * 2, 0, depth * 2), 0)
		for j in depth:
			_piece(house, "Floor_2m", Vector3(1 + i * 2, 0.0, 1 + j * 2), 0)
			_piece(house, "Roof_Tile_2m", Vector3(1 + i * 2, 2.6, 1 + j * 2), 0)
	for j in depth:
		_piece(house, "Wall_2m", Vector3(0, 0, 1 + j * 2), 90)
		_piece(house, "Wall_2m", Vector3(w * 2, 0, 1 + j * 2), 90)
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.75, 0.45)
	lamp.light_energy = 0.6
	lamp.omni_range = 6.0
	lamp.position = Vector3(w, 2.2, depth)
	house.add_child(lamp)

func _piece(parent: Node3D, kind: String, pos: Vector3, rot_y: float) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = _kit[kind]
	mi.position = pos
	mi.rotation_degrees.y = rot_y
	parent.add_child(mi)
	var body := StaticBody3D.new()
	mi.add_child(body)
	match kind:
		"Door_Frame":
			_col(body, Vector3(0.55, 2.6, 0.12), Vector3(-0.725, 1.3, 0))
			_col(body, Vector3(0.55, 2.6, 0.12), Vector3(0.725, 1.3, 0))
			_col(body, Vector3(0.9, 0.7, 0.12), Vector3(0, 2.25, 0))
		"Floor_2m":
			_col(body, Vector3(2, 0.05, 2), Vector3(0, 0.025, 0))
		"Roof_Tile_2m":
			_col(body, Vector3(2, 0.05, 2), Vector3(0, 0.025, 0))
		"Wall_Window_2m":
			_col(body, Vector3(2, 0.8, 0.12), Vector3(0, 0.4, 0))
			_col(body, Vector3(2, 0.6, 0.12), Vector3(0, 2.3, 0))
			_col(body, Vector3(0.55, 1.2, 0.12), Vector3(-0.725, 1.4, 0))
			_col(body, Vector3(0.55, 1.2, 0.12), Vector3(0.725, 1.4, 0))
			# ガラス：プレイヤーは通れないが、視線（レイ）は通す（レイヤー2）
			var glass := StaticBody3D.new()
			glass.collision_layer = 2
			glass.collision_mask = 0
			mi.add_child(glass)
			_col(glass, Vector3(0.9, 1.2, 0.12), Vector3(0, 1.4, 0))
		_:
			_col(body, Vector3(2, 2.6, 0.12), Vector3(0, 1.3, 0))

func _col(body: StaticBody3D, size: Vector3, pos: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.position = pos
	body.add_child(cs)

func _npc(name: String, pos: Vector3, color: Color, file: String, node: String, goal: StringName, completes: StringName, knock_kind := "") -> Interactable:
	var npc := Interactable.new()
	npc.name = name
	npc.position = pos
	npc.dialogue_file = file
	npc.dialogue_node = node
	npc.active_goal = goal
	npc.completes_goal = completes
	npc.knock = knock_kind
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.25
	cap.height = 1.5
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	cap.material = m
	body.mesh = cap
	body.position.y = 0.75
	npc.add_child(body)
	var head := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.13
	sm.height = 0.26
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color(0.85, 0.75, 0.65)
	sm.material = hm
	head.mesh = sm
	head.position.y = 1.62
	npc.add_child(head)
	_col(npc, Vector3(0.5, 1.8, 0.5), Vector3(0, 0.9, 0))
	npc.interacted.connect(_on_interacted)
	add_child(npc)
	return npc

func _prop(name: String, pos: Vector3, size: Vector3, color: Color, file: String, node: String, goal: StringName = &"", completes: StringName = &"") -> Interactable:
	var p := Interactable.new()
	p.name = name
	p.position = pos
	p.dialogue_file = file
	p.dialogue_node = node
	p.active_goal = goal
	p.completes_goal = completes
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	bm.material = m
	mi.mesh = bm
	p.add_child(mi)
	_col(p, size + Vector3(0.1, 0.1, 0.1), Vector3.ZERO)
	p.interacted.connect(_on_interacted)
	add_child(p)
	return p

## 3Dモデルの小物。会話があれば調べられる。col_size は当たり判定（床から立つ箱）
func _model_prop(name: String, model: PackedScene, pos: Vector3, rot_y: float, col_size: Vector3, file := "", node := "") -> StaticBody3D:
	var p: StaticBody3D
	if file != "":
		var it := Interactable.new()
		it.dialogue_file = file
		it.dialogue_node = node
		it.interacted.connect(_on_interacted)
		p = it
	else:
		p = StaticBody3D.new()
	p.name = name
	p.position = pos
	p.rotation_degrees.y = rot_y
	p.add_child(model.instantiate())
	_col(p, col_size, Vector3(0, col_size.y / 2, 0))
	add_child(p)
	return p

func _build_interiors() -> void:
	const CH0 := "res://data/dialogue/ch0.json"
	const CH1 := "res://data/dialogue/ch1.json"
	# 妻の実家の前に母
	_npc("Mother", Vector3(11, 0, 3.0), Color(0.35, 0.3, 0.38), CH0, "mother_1", &"greet_mother", &"greet_mother", "island")
	# 資料館：展示の灯りと説明板
	var exhibit := Streetlight.new()
	exhibit.name = "Exhibit"
	exhibit.signal_id = &"museum_hi"
	exhibit.position = Vector3(26, 0, 8.5)
	exhibit.scale = Vector3.ONE * 0.4
	exhibit.add_child(STREETLIGHT.instantiate())
	add_child(exhibit)
	_prop("MuseumSign", Vector3(24, 1.2, 9.2), Vector3(1.2, 0.8, 0.05), Color(0.5, 0.42, 0.3), CH0, "museum_sign")
	_area("MuseumEntry", Vector3(7, 2.5, 5), Vector3(24, 1.2, 7), func(): flow.on_location_entered(&"museum"))
	# 近所の老婆
	_npc("Neighbor", Vector3(33, 0, 3.0), Color(0.3, 0.32, 0.28), CH1, "neighbor_1", &"ask_neighbor", &"ask_neighbor", "island")
	# 自宅：妻、パンフ、整髪料、ラジオ、窓
	_npc("Wife", Vector3(58.3, 0, 6.2), Color(0.55, 0.32, 0.32), CH1, "wife_ask", &"talk_wife", &"talk_wife", "normal")
	# 机（天板 0.8m）の上：ラジオ、パンフ、ノートパソコン
	_model_prop("PropTable", TABLE, Vector3(55.5, FLOOR_Y, 6.5), 0, Vector3(1.13, 0.8, 0.71))
	var top := FLOOR_Y + 0.8
	_model_prop("PropLaptop", LAPTOP, Vector3(55.8, top, 6.68), 180, Vector3(0.4, 0.3, 0.3), CH0, "laptop")
	_prop("Pamphlet", Vector3(55.45, top + 0.01, 6.3), Vector3(0.3, 0.02, 0.21), Color(0.85, 0.82, 0.7), CH0, "pamphlet")
	# 奥の壁際の古い箪笥。上に前の住人の整髪料
	_model_prop("PropDrawer", DRAWER, Vector3(59.0, FLOOR_Y, 7.44), 180, Vector3(1.7, 1.09, 1.0), CH0, "drawer")
	_prop("Pomade", Vector3(59.4, FLOOR_Y + 1.09 + 0.05, 7.5), Vector3(0.08, 0.1, 0.08), Color(0.2, 0.35, 0.3), CH0, "pomade")
	# 入口脇の箱と保存食
	_model_prop("PropCrate", CRATE, Vector3(54.6, FLOOR_Y, 7.4), 90, Vector3(0.41, 0.25, 0.51))
	_model_prop("PropFood", FOOD, Vector3(54.6, FLOOR_Y + 0.25, 7.4), 90, Vector3(0.11, 0.24, 0.52), CH0, "food")
	# 妻の実家の玄関脇にも箱
	_model_prop("PropCrateJikka", CRATE, Vector3(9.6, 0, 3.4), 15, Vector3(0.51, 0.25, 0.41))
	# 窓を調べるための見えない箱。レイヤー4：調べるレイだけが当たり、視線と体は通す
	var window := _prop("Window", Vector3(55, 1.4, 4.12), Vector3(0.9, 1.2, 0.05), Color(0, 0, 0, 0), CH0, "window_night", &"first_night", &"first_night")
	window.get_child(0).visible = false
	window.collision_layer = 4
	radio = Radio.new()
	radio.name = "Radio"
	radio.signal_id = &"sos_a_radio"
	radio.position = Vector3(55.15, FLOOR_Y + 0.9, 6.55)
	add_child(radio)
	var radio_prop := _prop("RadioBox", Vector3(55.15, FLOOR_Y + 0.9, 6.55), Vector3(0.35, 0.2, 0.15), Color(0.4, 0.3, 0.2), "", "")
	radio_prop.interacted.disconnect(_on_interacted)
	radio_prop.interacted.connect(func(_t): _tune_radio())
	_area("HomeEntry", Vector3(5, 2.5, 3), Vector3(57, 1.2, 6.5), _enter_home)
	knock = Knock.new()
	add_child(knock)

func _enter_home() -> void:
	flow.on_location_entered(&"home")
	flow.complete(&"go_home")

# ---------- UI ----------

func _build_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	_hud_goal = Label.new()
	_hud_goal.position = Vector2(32, 24)
	_hud_goal.add_theme_font_size_override("font_size", 20)
	_hud_goal.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	ui.add_child(_hud_goal)
	_hud_prompt = Label.new()
	_hud_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_hud_prompt.position = Vector2(-60, 40)
	ui.add_child(_hud_prompt)
	notebook = Notebook.new()
	ui.add_child(notebook)
	dialogue = DialogueBox.new()
	ui.add_child(dialogue)
	_overlay = ColorRect.new()
	_overlay.color = Color.BLACK
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	ui.add_child(_overlay)
	_card = Label.new()
	_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_card.add_theme_font_size_override("font_size", 44)
	_card.modulate.a = 0
	ui.add_child(_card)
	_menu = VBoxContainer.new()
	_menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	ui.add_child(_menu)

	flow = ChapterFlow.new()
	scares = ScareDirector.new()
	add_child(scares)
	notebook.recorded.connect(func(id): flow.on_signal_recorded(id))
	dialogue.runner.ended.connect(_on_dialogue_ended)

func _show_menu() -> void:
	_overlay.visible = true
	_overlay.color = Color(0, 0, 0, 0.85)
	for c in _menu.get_children():
		c.queue_free()
	var title := Label.new()
	title.text = tr("ui_title")
	title.add_theme_font_size_override("font_size", 56)
	_menu.add_child(title)
	var b_new := Button.new()
	b_new.text = tr("ui_new_game")
	b_new.pressed.connect(_start.bind(false))
	_menu.add_child(b_new)
	if get_node("/root/SaveSystem").has_save(0):
		var b_cont := Button.new()
		b_cont.text = tr("ui_continue")
		b_cont.pressed.connect(_start.bind(true))
		_menu.add_child(b_cont)
	var b_lang := Button.new()
	b_lang.text = tr("ui_lang")
	b_lang.pressed.connect(_toggle_language)
	_menu.add_child(b_lang)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _toggle_language() -> void:
	TranslationServer.set_locale("en" if TranslationServer.get_locale().begins_with("ja") else "ja")
	_show_menu()

func _start(continue_game: bool) -> void:
	var gs: GameStateData = get_node("/root/GameState")
	gs.reset()
	if continue_game:
		get_node("/root/SaveSystem").load_slot(0)
	_menu.visible = false
	_overlay.visible = false
	add_child(flow)
	flow.goal_changed.connect(_on_goal_changed)
	flow.goal_completed.connect(func(id): scares.on_goal_completed(id))
	flow.chapter_changed.connect(func(_c): _show_card(tr("ui_chapter1")))
	flow.ending_triggered.connect(func(id): _pending_ending = id)
	player = PLAYER.instantiate()
	var idx := int(gs.flags.get("goal_index", 0))
	if idx >= 3:
		player.position = Vector3(56.5, 0.1, 6.5)
	elif idx == 2:
		player.position = Vector3(22, 0.1, 1.5)
	else:
		player.position = Vector3(-14, 0.4, 0)
		player.rotation_degrees.y = -90
	add_child(player)
	(player.get_node("SignalObserver") as SignalObserver).notebook = notebook
	(player.get_node("Head/Camera3D/Interactor") as Interactor).focus_changed.connect(_on_focus)
	_on_goal_changed(flow.current_goal())
	_show_card(tr("ui_chapter0") if gs.chapter == 0 else tr("ui_chapter1"))

func _on_goal_changed(goal: StringName) -> void:
	_hud_goal.text = tr("goal_%s" % goal)
	if goal == &"slice_end":
		_show_card(tr("ui_slice_end"), 6.0)

func _on_focus(target: Node) -> void:
	_hud_prompt.text = tr("ui_interact") if target and _is_active(target) else ""

func _is_active(target: Node) -> bool:
	var it := target as Interactable
	return it == null or it.active_goal == &"" or it.active_goal == flow.current_goal()

func _show_card(text: String, hold := 2.5) -> void:
	_card.text = text
	var tw := create_tween()
	tw.tween_property(_card, "modulate:a", 1.0, 0.8)
	tw.tween_interval(hold)
	tw.tween_property(_card, "modulate:a", 0.0, 1.2)

# ---------- 調べる・会話 ----------

func _on_interacted(target: Interactable) -> void:
	if dialogue.visible or _pending != null or not _is_active(target) or target.dialogue_file == "":
		return
	_pending = target
	if target.knock != "":
		knock.global_position = target.global_position
		knock.play_rhythm(target.knock)
		await get_tree().create_timer(1.4).timeout
	player.input_enabled = false
	dialogue.open(target.dialogue_file, target.dialogue_node)

func _on_dialogue_ended(_last: String) -> void:
	player.input_enabled = true
	if _pending_ending != &"":
		_play_ending(_pending_ending)
		return
	if _pending and _pending.completes_goal != &"":
		flow.complete(_pending.completes_goal)
	_pending = null

func _tune_radio() -> void:
	radio.tuned_freq = 76.0 if radio.tuned_freq >= 95.0 else radio.tuned_freq + 0.5
	_show_card(tr("ui_radio_freq") % ("%.1f" % radio.tuned_freq), 0.6)
	if not get_node("/root/GameState").flags.get("radio_hint_seen", false):
		get_node("/root/GameState").flags["radio_hint_seen"] = true
		dialogue.open("res://data/dialogue/ch1.json", "radio_hint")

func _play_ending(id: StringName) -> void:
	player.input_enabled = false
	_overlay.color = Color.BLACK
	_overlay.visible = true
	_show_card(tr("end_%s" % id), 4.0)
	await get_tree().create_timer(6.5).timeout
	get_node("/root/GameState").reset()
	get_tree().reload_current_scene()
