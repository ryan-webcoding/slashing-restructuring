extends Camera3D

@export var target: Node3D
@export var smoothing_speed: float = 5.0
@export var height: float = 10.0

@export var shake_intensity: float = 1.2
@export var shake_duration: float = 0.2

var shake_timer: float = 0.0
var original_offset: Vector3 = Vector3.ZERO

func _ready():
	original_offset = Vector3.ZERO

func _process(delta):
	if not target:
		return

	var target_pos = target.global_transform.origin
	target_pos.y = height  # Fixed height

	var desired_pos = target_pos

	if shake_timer > 0:
		shake_timer -= delta
		var shake_offset = Vector3(
			randf_range(-shake_intensity, shake_intensity),
			0,
			randf_range(-shake_intensity, shake_intensity)
		)
		desired_pos += shake_offset

	global_transform.origin = global_transform.origin.lerp(desired_pos, delta * smoothing_speed)

func start_shake():
	shake_timer = shake_duration
