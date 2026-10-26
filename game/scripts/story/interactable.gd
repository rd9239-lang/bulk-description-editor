## 調べられる物・人。調べると interacted を出し、SliceMain が会話や目標の処理をする。
class_name Interactable
extends StaticBody3D

signal interacted(target: Interactable)

@export var dialogue_file := ""
@export var dialogue_node := ""
## この目標の間だけ反応する（空なら常に反応）
@export var active_goal: StringName = &""
## 会話が終わったら完了する目標
@export var completes_goal: StringName = &""
## 調べる前に鳴らすノック（"island" / "normal" / ""）
@export var knock := ""

func _ready() -> void:
	add_to_group("interactable")

func interact(_player: Node) -> void:
	interacted.emit(self)
