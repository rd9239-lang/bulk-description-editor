## 一人称操作。歩き 2.2m/s、しゃがみ 1.0m/s（目線 1.6m→1.0m）、手持ちの灯り。走りはなし。
class_name Player
extends CharacterBody3D

const WALK := 2.2
const CROUCH := 1.0
const EYE_STAND := 1.6
const EYE_CROUCH := 1.0
const MOUSE_SENS := 0.0025

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var hand_light: SpotLight3D = $Head/HandLight

var input_enabled := true
var _bob_t := 0.0
var _last_step := -1
var _footsteps: Footsteps

## 歩くときの視点の揺れ（x: 左右、y: 上下、メートル）。止まっていれば 0
static func bob_offset(t: float, speed: float) -> Vector2:
	if speed < 0.1:
		return Vector2.ZERO
	var k := clampf(speed / WALK, 0.0, 1.0)
	var ph := t * TAU * 1.8
	return Vector2(sin(ph * 0.5) * 0.02 * k, (absf(sin(ph)) - 0.5) * 0.035 * k)

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hand_light.visible = false
	_footsteps = Footsteps.new()
	_footsteps.name = "Footsteps"
	add_child(_footsteps)

func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENS)
		head.rotate_x(-event.relative.y * MOUSE_SENS)
		head.rotation.x = clampf(head.rotation.x, -1.4, 1.4)
	elif event.is_action_pressed("toggle_light"):
		hand_light.visible = not hand_light.visible

func _physics_process(delta: float) -> void:
	var crouching := input_enabled and Input.is_action_pressed("crouch")
	head.position.y = move_toward(head.position.y, EYE_CROUCH if crouching else EYE_STAND, delta * 3.0)
	var dir := Vector3.ZERO
	if input_enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		dir = (transform.basis * Vector3(v.x, 0, v.y)).normalized()
	var speed := CROUCH if crouching else WALK
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	move_and_slide()
	var flat := Vector2(velocity.x, velocity.z).length()
	_bob_t = _bob_t + delta if flat > 0.1 else 0.0
	if flat > 0.1 and is_on_floor():
		var si := Footsteps.step_index(_bob_t)
		if si != _last_step:
			_last_step = si
			_footsteps.play_step(_surface_below(), crouching)
	else:
		_last_step = -1
	var o := bob_offset(_bob_t, flat)
	camera.position = camera.position.lerp(Vector3(o.x, o.y, 0), 0.25)

func _surface_below() -> String:
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.3, global_position + Vector3.DOWN * 0.4)
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return Footsteps.surface_for(hit.get("collider"))
