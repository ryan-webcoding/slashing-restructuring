extends CharacterBody3D

@onready var anim_lower = $animation_lower
@onready var anim_upper = $animation_upper
@onready var upper_body = $upper_body

const SPEED = 5.0
var last_input_vector := Vector2(0, 1)
var is_slashing := false

func _ready():
	anim_lower.play("idle_down")
	anim_upper.stop()
	upper_body.hide()

func _physics_process(delta):
	if is_dead:
		# Stop movement, skip all animation updates
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var input_vector := Input.get_vector("run_left", "run_right", "run_up", "run_down")

	if is_slashing:
		move_and_slide()
		return

	if input_vector != Vector2.ZERO:
		last_input_vector = input_vector
		velocity.x = input_vector.x * SPEED
		velocity.z = input_vector.y * SPEED
		move_and_slide()

		if not upper_body.visible:
			upper_body.show()

		play_run_animation(input_vector)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		move_and_slide()

		if upper_body.visible:
			upper_body.hide()

		play_idle_animation(last_input_vector)

	if Input.is_action_just_pressed("slash") and not is_slashing:
		start_slash()


# ---- Slash Logic ----

func start_slash() -> void:
	is_slashing = true
	var dir_name = get_direction_name(last_input_vector)
	var variation = randi() % 2 + 1

	if velocity.length() > 0.1:
		# Running → play run_slash in animation_upper
		var anim_name = "run_slash_%s_var%d" % [dir_name, variation]
		anim_upper.play(anim_name)
		if anim_upper.is_connected("animation_finished", Callable(self, "_on_slash_finished")):
			anim_upper.disconnect("animation_finished", Callable(self, "_on_slash_finished"))
		anim_upper.connect("animation_finished", Callable(self, "_on_slash_finished"))
	else:
		# Idle → play idle_slash in animation_lower
		var anim_name = "idle_slash_%s_var%d" % [dir_name, variation]
		anim_lower.play(anim_name)
		if anim_lower.is_connected("animation_finished", Callable(self, "_on_slash_finished")):
			anim_lower.disconnect("animation_finished", Callable(self, "_on_slash_finished"))
		anim_lower.connect("animation_finished", Callable(self, "_on_slash_finished"))

func _on_slash_finished(anim_name: StringName) -> void:
	is_slashing = false

	if anim_upper.is_connected("animation_finished", Callable(self, "_on_slash_finished")):
		anim_upper.disconnect("animation_finished", Callable(self, "_on_slash_finished"))
	if anim_lower.is_connected("animation_finished", Callable(self, "_on_slash_finished")):
		anim_lower.disconnect("animation_finished", Callable(self, "_on_slash_finished"))

	if velocity.length() > 0.1:
		play_run_animation(last_input_vector)
	else:
		play_idle_animation(last_input_vector)

# ---- Animation Helpers ----

func play_run_animation(dir: Vector2) -> void:
	var anim_name = get_run_anim_name(dir)
	if anim_lower.current_animation != anim_name:
		anim_lower.play(anim_name)
	if anim_upper.current_animation != anim_name:
		anim_upper.play(anim_name)

func play_idle_animation(dir: Vector2) -> void:
	var anim_name = get_idle_anim_name(dir)
	if anim_lower.current_animation != anim_name:
		anim_lower.play(anim_name)
	if anim_upper.is_playing():
		anim_upper.stop()

# ---- Direction Name Builders ----

func get_run_anim_name(dir: Vector2) -> String:
	return "run_" + get_direction_name(dir)

func get_idle_anim_name(dir: Vector2) -> String:
	return "idle_" + get_direction_name(dir)

func get_direction_name(dir: Vector2) -> String:
	if abs(dir.x) > abs(dir.y):
		return "right" if dir.x > 0 else "left"
	else:
		return "down" if dir.y > 0 else "up"
		
		
		
# ---- death animation handler----

var is_dead := false

func take_damage():
	if is_dead:
		return
	is_dead = true

	var dir_name = get_direction_name(last_input_vector)
	var death_anim = "stab_death_" + dir_name

	if anim_lower.has_animation(death_anim):
		anim_lower.play(death_anim)
	else:
		print("Missing death animation:", death_anim)

	# Stop upper animation if any
	if anim_upper.is_playing():
		anim_upper.stop()
	upper_body.hide()
