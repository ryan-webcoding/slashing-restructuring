extends CharacterBody3D

@export var speed: float = 3.0
@export var player_path: NodePath

@onready var player: Node3D = get_node_or_null(player_path)
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var main_collision: CollisionShape3D = $CollisionShape3D

var last_horizontal := true
var last_direction := "left"
var is_attacking := false

func _ready():
	pass  # No signal needed anymore

func _physics_process(delta):
	if player == null or not is_instance_valid(player) or is_attacking:
		return

	var to_player = player.global_transform.origin - global_transform.origin
	to_player.y = 0
	var direction = to_player.normalized()

	velocity = direction * speed
	move_and_slide()

	if global_transform.origin.distance_to(player.global_transform.origin) < 0.5:
		_start_attack()
		return

	var x = direction.x
	var z = direction.z

	if abs(x) > abs(z):
		last_horizontal = true
		if x > 0.0:
			last_direction = "right"
		else:
			last_direction = "left"
	else:
		last_horizontal = false
		if z > 0.0:
			last_direction = "down"
		else:
			last_direction = "up"


	var anim = "run_" + last_direction
	if anim_player.current_animation != anim:
		anim_player.play(anim)

func _start_attack():
	is_attacking = true

	var anim_name = "attack_" + last_direction
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
	else:
		print("Missing animation:", anim_name)

	var anim_length = anim_player.get_animation(anim_name).length
	await get_tree().create_timer(anim_length).timeout

	is_attacking = false

# 👇 This method is called *only* at the attack frame
func deal_damage():
	if player != null and is_instance_valid(player):
		var dist = global_transform.origin.distance_to(player.global_transform.origin)
		if dist < 1.5:
			print("you dead")
