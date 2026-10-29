## 見るのではなく、近くで聞いて記録する信号（ラジオ、老人の指、イヤホン）。
## 聞こえる状態（audible）で、聞こえる距離（hearing_range）にいる間だけ観察が進む。
class_name AudibleSource
extends SignalSource

@export var hearing_range := 3.0

func audible() -> bool:
	return true

func heard_from(pos: Vector3) -> bool:
	return audible() and pos.distance_to(global_position) <= hearing_range
