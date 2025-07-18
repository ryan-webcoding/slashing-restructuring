extends CharacterBody3D

@export var speed: float = 3.0
@export var player_path: NodePath

@onready var player: Node3D = get_node_or_null(player_path)
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var main_collision: CollisionShape3D = $CollisionShape3D

@onready var hit_areas := {
	"up": $hit_area_up,
	"down": $hit_area_down,
	"left": $hit_area_left,
	"right": $hit_area_right
}

var last_horizontal := true
var last_direction := "left"
var is_attacking := false
var is_dead := false

func _ready():
	add_to_group("enemies")  # 👈 Add assassin to "enemies" group

	for area in hit_areas.values():
		area.monitoring = true
		area.monitorable = true

func _physics_process(delta):
	if player == null or not is_instance_valid(player) or is_attacking or is_dead:
		return

	var to_player = player.global_transform.origin - global_transform.origin
	to_player.y = 0
	var direction = to_player.normalized()

	velocity = direction * speed
	move_and_slide()

	if global_transform.origin.distance_to(player.global_transform.origin) < 0.8:
		_start_attack()
		return

	var x = direction.x
	var z = direction.z

	if abs(x) > abs(z):
		last_horizontal = true
		last_direction = "right" if x > 0.0 else "left"
	else:
		last_horizontal = false
		last_direction = "down" if z > 0.0 else "up"

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

# Called by AnimationPlayer
func deal_damage():
	var area_to_check: Area3D = hit_areas.get(last_direction)
	if area_to_check:
		for body in area_to_check.get_overlapping_bodies():
			if body != self and body.is_in_group("players") and body.has_method("take_damage"):
				body.take_damage()

# Called when damaged by player
func take_damage():
	if is_dead:
		return
	is_dead = true

	var anim_name = "death_%s_1" % last_direction
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
	else:
		print("Missing death animation:", anim_name)

	# Optional: delete after animation
	var duration = anim_player.get_animation(anim_name).length
	await get_tree().create_timer(duration + 3).timeout
	queue_free()
