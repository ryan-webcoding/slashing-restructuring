extends CharacterBody3D

@onready var anim_tree = $animation_lower_tree
@onready var state_machine = anim_tree["parameters/playback"]
@onready var anim_player = $animation_lower

const SPEED = 4.0
var last_input_vector := Vector2(0, 1)
var current_slash := ""
var is_slashing := false

func _ready():
	anim_tree.active = true
	anim_tree.set("parameters/conditions/is_idle", true)
	anim_tree.set("parameters/conditions/is_running", false)
	anim_tree.set("parameters/conditions/is_slashing1", false)
	anim_tree.set("parameters/conditions/is_slashing2", false)

func _physics_process(delta):
	var input_vector = Vector2(
		Input.get_action_strength("run_right") - Input.get_action_strength("run_left"),
		Input.get_action_strength("run_down") - Input.get_action_strength("run_up")
	)

	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		last_input_vector = input_vector

		var direction = Vector3(input_vector.x, 0, input_vector.y)
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

		# Only allow movement transitions if not slashing
		if !is_slashing:
			anim_tree.set("parameters/conditions/is_running", true)
			anim_tree.set("parameters/conditions/is_idle", false)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

		if !is_slashing:
			anim_tree.set("parameters/conditions/is_running", false)
			anim_tree.set("parameters/conditions/is_idle", true)

	# Update blend positions
	anim_tree.set("parameters/idle/blend_position", last_input_vector)
	anim_tree.set("parameters/running/blend_position", last_input_vector)
	anim_tree.set("parameters/idle_slash1/blend_position", last_input_vector)
	anim_tree.set("parameters/idle_slash2/blend_position", last_input_vector)

	move_and_slide()

# 🔥 Slash input
func _input(event):
	if event.is_action_pressed("slash") and !is_slashing and velocity.length() == 0:
		is_slashing = true
		anim_tree.active = false  # Temporarily stop tree to prevent conflict

		# Pick slash anim
		var suffix = "_var1" if randi() % 2 == 0 else "_var2"
		var dir = last_input_vector
		var slash_anim := ""

		if abs(dir.x) > abs(dir.y):
			slash_anim = "idle_slash_right%s" % suffix if dir.x > 0 else "idle_slash_left%s" % suffix
		else:
			slash_anim = "idle_slash_down%s" % suffix if dir.y > 0 else "idle_slash_up%s" % suffix

		current_slash = slash_anim
		anim_player.play(current_slash)


func _process(delta):
	if is_slashing and !anim_player.is_playing():
		is_slashing = false
		current_slash = ""
		anim_tree.active = true  # Reactivate tree when done


func get_current_slash_anim_name(slash_node: String) -> String:
	var suffix = "_1" if slash_node == "idle_slash1" else "_2"
	var dir = last_input_vector
	if abs(dir.x) > abs(dir.y):
		return "slash_right%s" % suffix if dir.x > 0 else "slash_left%s" % suffix
	else:
		return "slash_down%s" % suffix if dir.y > 0 else "slash_up%s" % suffix
