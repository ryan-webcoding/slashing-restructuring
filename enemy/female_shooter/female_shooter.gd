extends CharacterBody3D

@export var speed: float = 3.0
@export var player_path: NodePath

@onready var player: Node3D = get_node_or_null(player_path)
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var running_sprite: Node3D = $Sprite3D

@onready var range_area: Area3D = $range

@onready var body_up: Sprite3D = $body_up
@onready var body_down: Sprite3D = $body_down
@onready var arm_pivot_left: Node3D = $arm_pivot_left
@onready var arm_pivot_right: Node3D = $arm_pivot_right
@onready var arm_left: Sprite3D = $arm_pivot_left/arm_left
@onready var arm_right: Sprite3D = $arm_pivot_right/arm_right

var last_direction: String = "down"
var is_shooting_position := false
var is_dead := false

func _ready():
	range_area.monitoring = true
	range_area.connect("body_entered", Callable(self, "_on_range_entered"))
	range_area.connect("body_exited", Callable(self, "_on_range_exited"))
	_reset_shooting_pose()
	add_to_group("enemies")  # ensure it's damageable

func _physics_process(delta):
	if player == null or not is_instance_valid(player) or is_dead:
		return

	if is_shooting_position:
		_update_shooting_pose()
		return

	var to_player = player.global_transform.origin - global_transform.origin
	to_player.y = 0
	var direction = to_player.normalized()

	velocity = direction * speed
	move_and_slide()

	var x = direction.x
	var z = direction.z

	if abs(x) > abs(z):
		last_direction = "right" if x > 0.0 else "left"
	else:
		last_direction = "up" if z < 0.0 else "down"

	var anim_name = "run_" + last_direction
	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name)

func _on_range_entered(body):
	if body.is_in_group("players"):
		is_shooting_position = true
		running_sprite.hide()

func _on_range_exited(body):
	if body.is_in_group("players"):
		is_shooting_position = false
		running_sprite.show()
		_reset_shooting_pose()

func _reset_shooting_pose():
	body_up.hide()
	body_down.hide()
	arm_left.hide()
	arm_right.hide()

func _update_shooting_pose():
	if player == null or not is_instance_valid(player):
		return

	var to_player = player.global_transform.origin - global_transform.origin
	to_player.y = 0

	var x = to_player.x
	var z = to_player.z

	_reset_shooting_pose()

	if z < 0:
		body_up.show()
		body_up.flip_h = x < 0
	else:
		body_down.show()
		body_down.flip_h = x >= 0

	var angle_rad = atan2(z, x)
	var angle_deg = -rad_to_deg(angle_rad)

	if x >= 0:
		arm_right.show()
		arm_pivot_right.rotation_degrees.z = angle_deg
	else:
		arm_left.show()
		arm_pivot_left.rotation_degrees.z = 180 + angle_deg

# Called when damaged by player
func take_damage():
	if is_dead:
		return
	is_dead = true

	# Show AnimationPlayer node if it's hidden
	if not running_sprite.visible:
		running_sprite.show()

	var death_anim = "death_%s_1" % last_direction
	if anim_player.has_animation(death_anim):
		anim_player.play(death_anim)
	else:
		print("Missing death animation:", death_anim)

	_reset_shooting_pose()  # hide body_up/down and arms

	var duration = anim_player.get_animation(death_anim).length
	await get_tree().create_timer(duration + 3.0).timeout
	queue_free()
