extends CharacterBody3D

@onready var anim_lower = $animation_lower
@onready var anim_upper = $animation_upper
@onready var upper_body = $upper_body
@onready var endurance_bar = $endurance_bar

@export var endurancebar_color_high: Color = Color(0.0, 1.0, 0.0)  # Green
@export var endurancebar_color_mid: Color = Color(1.0, 1.0, 0.0)   # Yellow
@export var endurancebar_color_low: Color = Color(1.0, 0.0, 0.0)   # Red


@onready var hit_areas := {
	"up": $hit_area_up,
	"down": $hit_area_down,
	"left": $hit_area_left,
	"right": $hit_area_right
}

const SPEED := 5.0
var last_input_vector := Vector2(0, 1)
var is_slashing := false
var is_dead := false

# ---- Endurance System ----
var endurance := 80.0
const MAX_ENDURANCE := 80.0
const SLASH_COST := 10.0
const REGEN_RATE := 80.0  # per second
const REGEN_DELAY := 0.5  # seconds
var time_since_last_slash := 0.0
var time_since_last_endurance_change := 0.0

func _ready():
	add_to_group("players")
	anim_lower.play("idle_down")
	anim_upper.stop()
	upper_body.hide()
	endurance_bar.visible = true
	update_endurance_bar()  # Initialize appearance

func _physics_process(delta):
	if is_dead:
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

	if Input.is_action_just_pressed("slash") and not is_slashing and endurance >= SLASH_COST:
		start_slash()

	# Regeneration logic
	if time_since_last_slash >= REGEN_DELAY and endurance < MAX_ENDURANCE:
		var previous_endurance = endurance
		endurance = min(MAX_ENDURANCE, endurance + REGEN_RATE * delta)
		if endurance != previous_endurance:
			time_since_last_endurance_change = 0.0
			update_endurance_bar()
	else:
		time_since_last_slash += delta

	time_since_last_endurance_change += delta
	if endurance >= MAX_ENDURANCE and time_since_last_endurance_change >= 1.0:
		endurance_bar.visible = false

# ---- Slash Logic ----

func start_slash() -> void:
	is_slashing = true
	endurance -= SLASH_COST
	time_since_last_slash = 0.0
	time_since_last_endurance_change = 0.0
	update_endurance_bar()

	var dir_name = get_direction_name(last_input_vector)
	var variation = randi() % 2 + 1

	if velocity.length() > 0.1:
		var anim_name = "run_slash_%s_var%d" % [dir_name, variation]
		anim_upper.play(anim_name)
		_disconnect_all_slash_signals()
		anim_upper.connect("animation_finished", Callable(self, "_on_slash_finished"))
	else:
		var anim_name = "idle_slash_%s_var%d" % [dir_name, variation]
		anim_lower.play(anim_name)
		_disconnect_all_slash_signals()
		anim_lower.connect("animation_finished", Callable(self, "_on_slash_finished"))

func _on_slash_finished(anim_name: StringName) -> void:
	is_slashing = false
	_disconnect_all_slash_signals()

	if velocity.length() > 0.1:
		play_run_animation(last_input_vector)
	else:
		play_idle_animation(last_input_vector)

func _disconnect_all_slash_signals():
	if anim_upper.is_connected("animation_finished", Callable(self, "_on_slash_finished")):
		anim_upper.disconnect("animation_finished", Callable(self, "_on_slash_finished"))
	if anim_lower.is_connected("animation_finished", Callable(self, "_on_slash_finished")):
		anim_lower.disconnect("animation_finished", Callable(self, "_on_slash_finished"))


# ---- Damage Output ----

func deal_damage():
	var dir_name = get_direction_name(last_input_vector)
	var area_to_check: Area3D = hit_areas.get(dir_name)
	if area_to_check:
		for body in area_to_check.get_overlapping_bodies():
			if body != self and body.is_in_group("enemies") and body.has_method("take_damage"):
				body.take_damage()


# ---- Animation Helpers ----

func play_run_animation(dir: Vector2) -> void:
	var anim_name = "run_" + get_direction_name(dir)
	if anim_lower.current_animation != anim_name:
		anim_lower.play(anim_name)
	if anim_upper.current_animation != anim_name:
		anim_upper.play(anim_name)

func play_idle_animation(dir: Vector2) -> void:
	var anim_name = "idle_" + get_direction_name(dir)
	if anim_lower.current_animation != anim_name:
		anim_lower.play(anim_name)
	if anim_upper.is_playing():
		anim_upper.stop()


# ---- Direction ----

func get_direction_name(dir: Vector2) -> String:
	if abs(dir.x) > abs(dir.y):
		return "right" if dir.x > 0 else "left"
	else:
		return "down" if dir.y > 0 else "up"


# ---- Death ----

func take_damage():
	if is_dead:
		return
	is_dead = true

	# Play death animation based on direction
	var dir_name = get_direction_name(last_input_vector)
	var death_anim = "stab_death_" + dir_name

	if anim_lower.has_animation(death_anim):
		anim_lower.play(death_anim)
	else:
		print("Missing death animation:", death_anim)

	if anim_upper.is_playing():
		anim_upper.stop()
	upper_body.hide()

	# Trigger camera shake
	var camera = get_tree().get_root().get_node("game/Camera3D")
	if camera and camera.has_method("start_shake"):
		camera.start_shake()



# ---- Endurance Bar Visual ----

func update_endurance_bar():
	endurance_bar.scale.x = endurance
	endurance_bar.visible = true

	if endurance >= 40:
		endurance_bar.modulate = endurancebar_color_high
	elif endurance >= 24:
		endurance_bar.modulate = endurancebar_color_mid
	else:
		endurance_bar.modulate = endurancebar_color_low
