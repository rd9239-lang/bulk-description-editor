## 画面中心から 2.0m のレイで interactable グループのノードを探し、E キーで interact(player) を呼ぶ。
class_name Interactor
extends RayCast3D

signal focus_changed(target: Node)

var _focus: Node

func _ready() -> void:
	target_position = Vector3(0, 0, -2.0)
	# レイヤー1（物）とレイヤー4（窓など、視線を遮らない調べる対象）
	collision_mask = 1 | 4
	enabled = true

func _physics_process(_delta: float) -> void:
	var t: Node = null
	if is_colliding():
		var n := get_collider() as Node
		while n and not n.is_in_group("interactable"):
			n = n.get_parent()
		t = n
	if t != _focus:
		_focus = t
		focus_changed.emit(t)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and _focus and _focus.has_method("interact"):
		_focus.interact(owner)
		get_viewport().set_input_as_handled()
