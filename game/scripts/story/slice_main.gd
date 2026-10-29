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
var ch2: Chapter2
var ui_layer: CanvasLayer

var _hud_goal: Label
var _observe_box: VBoxContainer
var _observe_bar: ProgressBar
var _toast: Label
var _toast_tween: Tween
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
	StreetDressing.build(self)
	_build_utilities()
	_build_interiors()
	EastDistrict.build(self)
	MaterialLibrary.apply(self)
	var amb := Ambience.new()
	amb.name = "Ambience"
	add_child(amb)
	_build_ui()
	ch2 = Chapter2.new()
	ch2.setup(self)
	_show_menu()

# ---------- 組み立て ----------

func _load_kit() -> void:
	var kit := HOUSE_KIT.instantiate()
	for c in kit.get_children():
		if c is MeshInstance3D:
			_kit[String(c.name)] = (c as MeshInstance3D).mesh
	kit.free()

func _build_environment() -> void:
	var we := WorldEnvironment.new()
	we.name = "WorldEnv"
	add_child(we)
	var moon := DirectionalLight3D.new()
	moon.name = "Moon"
	moon.light_color = Color(0.55, 0.65, 0.9)
	moon.light_energy = 0.3
	moon.rotation_degrees = Vector3(-35, 30, 0)
	add_child(moon)
	apply_quality(GraphicsSettings.quality)

## 画質の切り替え（環境・月の影・街灯と室内灯の影）
func apply_quality(q: StringName) -> void:
	GraphicsSettings.quality = q
	($WorldEnv as WorldEnvironment).environment = GraphicsSettings.build_environment(q, TimeOfDay.current)
	($Moon as DirectionalLight3D).shadow_enabled = q == &"high"
	for lamp in find_children("*", "Streetlight", true, false):
		(lamp as Streetlight).apply_quality(q)
	for light in get_tree().get_nodes_in_group("room_lights") if is_inside_tree() else []:
		GraphicsSettings.configure_lamp(light, q)

## 箱の地形。look は質感一覧の名前（data/materials.json）
func _box_body(name: String, size: Vector3, pos: Vector3, look: String, parent: Node = self) -> StaticBody3D:
	return BuildUtil.box_body(parent, name, size, pos, look)

func _build_ground() -> void:
	# 陸地は x=-1 の岸まで。その先は海で、桟橋は杭の上に立つ
	_box_body("Ground", Vector3(76, 1, 40), Vector3(37, -0.5, 0), "gravel").set_meta("surface", "gravel")
	_box_body("Road", Vector3(69, 0.02, 4), Vector3(33.5, 0.01, 0), "asphalt").set_meta("surface", "asphalt")
	_box_body("Pier", Vector3(15, 0.3, 3), Vector3(-8.5, 0.15, 0), "wood_floor").set_meta("surface", "wood")
	_build_shore()
	var sea := MeshInstance3D.new()
	sea.name = "Sea"
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 80)
	pm.material = MaterialLibrary.material("sea")
	sea.mesh = pm
	sea.position = Vector3(-31, -0.4, 0)
	add_child(sea)
	# 桟橋から上がると「到着」
	_area("PierExit", Vector3(3, 3, 6), Vector3(-1, 1.5, 0), func(): flow.complete(&"arrive_pier"))

## 岩の護岸、桟橋の杭、海に落ちないための見えない柵
func _build_shore() -> void:
	var shore := Node3D.new()
	shore.name = "Shore"
	add_child(shore)
	var slope := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(3.2, 0.6, 40)
	bm.material = MaterialLibrary.material("rock")
	slope.mesh = bm
	slope.position = Vector3(-1.9, -0.95, 0)
	slope.rotation.z = deg_to_rad(38)
	shore.add_child(slope)
	for x in [-15.0, -11.0, -7.0, -3.0]:
		for z in [-1.3, 1.3]:
			var pile := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.12
			cm.bottom_radius = 0.14
			cm.height = 2.4
			cm.material = MaterialLibrary.material("plank_dark")
			pile.mesh = cm
			pile.position = Vector3(x, -1.2, z)
			pile.add_to_group("pier_piles")
			shore.add_child(pile)
	# 桟橋の先の港の灯り（常に点いている）
	var harbor := Streetlight.new()
	harbor.name = "HarborLight"
	harbor.position = Vector3(-5.0, 0.3, -1.4)
	harbor.rotation_degrees.y = -90
	harbor.add_child(STREETLIGHT.instantiate())
	shore.add_child(harbor)
	var fence := StaticBody3D.new()
	fence.name = "SeaBarrier"
	shore.add_child(fence)
	for b in [[Vector3(0.2, 3, 18.4), Vector3(-1.1, 1.5, 10.8)], [Vector3(0.2, 3, 18.4), Vector3(-1.1, 1.5, -10.8)],
			[Vector3(15, 3, 0.2), Vector3(-8.5, 1.5, 1.6)], [Vector3(15, 3, 0.2), Vector3(-8.5, 1.5, -1.6)],
			[Vector3(0.2, 3, 3.4), Vector3(-16.1, 1.5, 0)]]:
		_col(fence, b[0], b[1])

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
				# 古い蛍光灯の青白い光。ほかのオレンジ色の街灯と見分けられるように
				lamp.light_color = Color(0.78, 0.9, 1.0)
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
				StreetDressing.wire(street, prev.position + (prev.find_child(side) as Node3D).position,
					pole.position + (pole.find_child(side) as Node3D).position, 0.55)
		prev = pole
	# 電柱から家への引き込み線
	StreetDressing.wire(street, Vector3(8.7, 8.3, -4.4), Vector3(9.0, 2.75, 3.6), 0.35)
	StreetDressing.wire(street, Vector3(56.7, 8.3, -4.4), Vector3(59.0, 2.75, 3.6), 0.35)

func _add_pole_collision(parent: Node3D, radius: float, height: float) -> void:
	BuildUtil.pole_collision(parent, radius, height)

## 正面（道路側、ローカル z=0）を部品で、奥と側面を壁で囲う。屋根などは HouseDetail。
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
	for j in depth:
		_piece(house, "Wall_2m", Vector3(0, 0, 1 + j * 2), 90)
		_piece(house, "Wall_2m", Vector3(w * 2, 0, 1 + j * 2), 90)
	HouseDetail.add(house, w * 2.0, depth * 2.0, front)
	# 屋内の範囲：入ると屋外の音がこもる
	var inside := Area3D.new()
	inside.name = "Interior"
	var ics := CollisionShape3D.new()
	var ibox := BoxShape3D.new()
	ibox.size = Vector3(w * 2.0 - 0.2, 2.4, depth * 2.0 - 0.2)
	ics.shape = ibox
	ics.position = Vector3(w, 1.2, depth)
	inside.add_child(ics)
	inside.body_entered.connect(func(b): if b is Player: set_player_indoor(true))
	inside.body_exited.connect(func(b): if b is Player: set_player_indoor(false))
	house.add_child(inside)
	var lamp := OmniLight3D.new()
	lamp.add_to_group("room_lights")
	GraphicsSettings.configure_lamp(lamp, GraphicsSettings.quality)
	lamp.light_color = Color(1.0, 0.72, 0.42)
	lamp.light_energy = 1.6
	lamp.omni_range = 7.0
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
			body.set_meta("surface", "tatami")
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
	BuildUtil.col(body, size, pos)

func _npc(name: String, pos: Vector3, color: Color, file: String, node: String, goal: StringName, completes: StringName, knock_kind := "") -> Interactable:
	var npc := Interactable.new()
	npc.name = name
	npc.position = pos
	npc.dialogue_file = file
	npc.dialogue_node = node
	npc.active_goal = goal
	npc.completes_goal = completes
	npc.knock = knock_kind
	# 仮の人型（服の色だけ人物ごとに変える）。モデルは +Z を向くので道路側（-Z）へ回す
	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = StreetDressing.mesh("Mannequin_F")
	body.rotation_degrees.y = 180
	for i in body.mesh.get_surface_count():
		var src := body.mesh.surface_get_material(i)
		if src and src.resource_name == "npc_cloth":
			var m := StandardMaterial3D.new()
			m.albedo_color = color
			m.roughness = 0.85
			body.set_surface_override_material(i, m)
	npc.add_child(body)
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

## 室外機とガスメーター
func _build_utilities() -> void:
	StreetDressing.place(self, "AC_Home", "ACUnit", Vector3(60.35, 0, 6.0), 90.0, Vector3(0.3, 0.6, 0.8))
	StreetDressing.place(self, "Gas_Home", "GasMeter", Vector3(56.0, 0, 3.92), 180.0)
	StreetDressing.place(self, "AC_Jikka", "ACUnit", Vector3(7.65, 0, 6.0), -90.0, Vector3(0.3, 0.6, 0.8))
	StreetDressing.place(self, "Gas_Jikka", "GasMeter", Vector3(12.0, 0, 3.92), 180.0)
	StreetDressing.place(self, "AC_Neighbor", "ACUnit", Vector3(38.35, 0, 6.5), 90.0, Vector3(0.3, 0.6, 0.8))

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

var _indoor_count := 0

## 屋内の範囲への出入り（家どうしが重ならないので、数で管理しておけば十分）
func set_player_indoor(entered: bool) -> void:
	_indoor_count = maxi(0, _indoor_count + (1 if entered else -1))
	AudioMixer.set_indoor(_indoor_count > 0)

func _enter_home() -> void:
	flow.on_location_entered(&"home")
	flow.complete(&"go_home")
	ch2.on_home_entered()

# ---------- UI ----------

func _build_ui() -> void:
	# 画面効果（周辺減光・粒子・色ずれ）。UI より下、3D より上に重ねる
	var fx_layer := CanvasLayer.new()
	fx_layer.name = "PostFX"
	fx_layer.layer = 0
	var fx := ColorRect.new()
	fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fx_mat := ShaderMaterial.new()
	fx_mat.shader = preload("res://shaders/post_fx.gdshader")
	fx.material = fx_mat
	fx_layer.add_child(fx)
	add_child(fx_layer)
	var ui := CanvasLayer.new()
	ui_layer = ui
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
	# 信号を見ているときの「観察中」と記録の進み具合
	_observe_box = VBoxContainer.new()
	_observe_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_observe_box.offset_top = -150
	_observe_box.offset_bottom = -110
	_observe_box.offset_left = -110
	_observe_box.offset_right = 110
	_observe_box.visible = false
	var ol := Label.new()
	ol.text = tr("ui_observing")
	ol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ol.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	_observe_box.add_child(ol)
	_observe_bar = ProgressBar.new()
	_observe_bar.max_value = 1.0
	_observe_bar.show_percentage = false
	_observe_bar.custom_minimum_size = Vector2(220, 6)
	_observe_box.add_child(_observe_bar)
	ui.add_child(_observe_box)
	_toast = Label.new()
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.offset_top = -200
	_toast.offset_bottom = -170
	_toast.offset_left = -200
	_toast.offset_right = 200
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 22)
	_toast.visible = false
	ui.add_child(_toast)
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
	notebook.recorded.connect(func(_id): _show_toast(tr("ui_recorded")))
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
	var b_q := Button.new()
	b_q.text = tr("ui_quality_high" if GraphicsSettings.quality == &"high" else "ui_quality_low")
	b_q.pressed.connect(_toggle_quality)
	_menu.add_child(b_q)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _toggle_quality() -> void:
	apply_quality(&"low" if GraphicsSettings.quality == &"high" else &"high")
	_show_menu()

func _toggle_language() -> void:
	TranslationServer.set_locale("en" if TranslationServer.get_locale().begins_with("ja") else "ja")
	_show_menu()

func _start(continue_game: bool) -> void:
	var gs: GameStateData = get_node("/root/GameState")
	gs.reset()
	if continue_game:
		get_node("/root/SaveSystem").load_slot(0)
	var idx := int(gs.flags.get("goal_index", 0))
	# v3 のセーブ（第1章を終えたところ）は、第2章の始めとして読む
	if idx >= ChapterFlow.CHAPTER2_START and gs.chapter < 2:
		gs.chapter = 2
		gs.flags["time_of_day"] = "dusk"
	TimeOfDay.apply(self, StringName(gs.flags.get("time_of_day", ChapterFlow.time_of_day_for(idx))))
	ch2.restore(idx)
	_menu.visible = false
	_overlay.visible = false
	add_child(flow)
	flow.goal_changed.connect(_on_goal_changed)
	flow.goal_completed.connect(func(id): scares.on_goal_completed(id))
	flow.chapter_changed.connect(func(c): _show_card(tr("ui_chapter%d" % c)))
	flow.ending_triggered.connect(func(id): _pending_ending = id)
	player = PLAYER.instantiate()
	if idx >= 3:
		player.position = Vector3(56.5, 0.1, 6.5)
	elif idx == 2:
		player.position = Vector3(22, 0.1, 1.5)
	else:
		player.position = Vector3(-14, 0.4, 0)
		player.rotation_degrees.y = -90
	add_child(player)
	var obs := player.get_node("SignalObserver") as SignalObserver
	obs.notebook = notebook
	obs.observed.connect(_on_signal_observed)
	(player.get_node("Head/Camera3D/Interactor") as Interactor).focus_changed.connect(_on_focus)
	_on_goal_changed(flow.current_goal())
	_show_card(tr("ui_chapter%d" % gs.chapter))

func _process(_delta: float) -> void:
	_update_observe_hud()

## 信号を見ている間だけ「観察中」と進み具合を出す（記録済みの信号では出さない）
func _update_observe_hud() -> void:
	if player == null or _observe_box == null:
		return
	var obs := player.get_node("SignalObserver") as SignalObserver
	var target := obs.current_target()
	var show := target != &"" and not notebook.has_entry(target) and not dialogue.visible and not (ch2 and ch2.popup.is_post_open())
	_observe_box.visible = show
	if show:
		_observe_bar.value = obs.progress(target)

func _show_toast(text: String) -> void:
	_toast.text = text
	_toast.visible = true
	_toast.modulate.a = 1.0
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.0)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.8)
	_toast_tween.tween_callback(func(): _toast.visible = false)

## 窓の外の SOS を初めて1周期見たとき、主人公が気づく（1回だけ）
func _on_signal_observed(id: StringName) -> void:
	var gs: GameStateData = get_node("/root/GameState")
	if id != &"sos_a" or gs.flags.get("noticed_sos", false) or dialogue.visible:
		return
	gs.flags["noticed_sos"] = true
	player.input_enabled = false
	dialogue.open("res://data/dialogue/ch0.json", "notice_sos")

func _on_goal_changed(goal: StringName) -> void:
	_hud_goal.text = tr("goal_%s" % goal)

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
	# 遺品は調べた時点で拾う（一覧は手帳の「遺品」）
	if target.relic_id != &"" and Relics.pick(get_node("/root/GameState"), target.relic_id):
		_show_toast(tr("ui_relic_found") % tr(Relics.defs()[target.relic_id]["name_key"]))
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
	var done := _pending
	_pending = null
	if done and done.completes_goal != &"":
		flow.complete(done.completes_goal)
	# 拾った遺品はその場から消える
	if done and done.relic_id != &"" and done.relic_id in get_node("/root/GameState").relics_found:
		done.queue_free()

func _tune_radio() -> void:
	if dialogue.visible:
		return
	if not radio.powered:
		# 1回目は電源を入れるだけ（勝手に雑音が鳴らないように）
		radio.power_on()
		_show_toast(tr("ui_radio_on"))
		if not get_node("/root/GameState").flags.get("radio_hint_seen", false):
			get_node("/root/GameState").flags["radio_hint_seen"] = true
			player.input_enabled = false
			dialogue.open("res://data/dialogue/ch1.json", "radio_hint")
		return
	radio.tuned_freq = 76.0 if radio.tuned_freq >= 95.0 else radio.tuned_freq + 0.5
	_show_card(tr("ui_radio_freq") % ("%.1f" % radio.tuned_freq), 0.6)
	if not get_node("/root/GameState").flags.get("radio_hint_seen", false):
		get_node("/root/GameState").flags["radio_hint_seen"] = true
		player.input_enabled = false
		dialogue.open("res://data/dialogue/ch1.json", "radio_hint")

func _play_ending(id: StringName) -> void:
	player.input_enabled = false
	_overlay.color = Color.BLACK
	_overlay.visible = true
	_show_card(tr("end_%s" % id), 4.0)
	await get_tree().create_timer(6.5).timeout
	get_node("/root/GameState").reset()
	get_tree().reload_current_scene()
