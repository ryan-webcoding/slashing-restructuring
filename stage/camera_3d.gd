extends Camera3D

@export var target: Node3D
@export var smoothing_speed: float = 5.0
@export var height: float = 10.0

func _process(delta):
	if not target:
		return

	var target_pos = target.global_transform.origin
	target_pos.y = height  # force fixed top-down height

	global_transform.origin = global_transform.origin.lerp(target_pos, delta * smoothing_speed)
