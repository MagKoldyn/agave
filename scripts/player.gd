extends CharacterBody2D

signal footstep(at: Vector2)

const WALK_SPEED := 145.0
const RUN_SPEED := 225.0
const ACCELERATION := 920.0
const DECELERATION := 1150.0
const DISPLAY_SCALE := 0.29
const FRAME_RATE_WALK := 7.5
const FRAME_RATE_RUN := 11.0
const MODEL_TEXTURES := {
	"sage": "res://assets/art/player_walk_sage.png",
	"ochre": "res://assets/art/player_walk_ochre.png",
	"desert": "res://assets/art/player_walk_desert.png"
}

var can_move := true
var facing := Vector2.DOWN
var action_lock := false
var footstep_clock := 0.0
var animation_clock := 0.0
var current_direction := "down"
var sprite: Sprite2D

func _ready() -> void:
	z_index = 8
	var collision := CollisionShape2D.new()
	var body_shape := CapsuleShape2D.new()
	body_shape.radius = 8.0
	body_shape.height = 22.0
	collision.shape = body_shape
	collision.position = Vector2(0, 10)
	add_child(collision)
	sprite = Sprite2D.new()
	sprite.texture = _load_model_texture()
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.frame = 1
	sprite.scale = Vector2.ONE * DISPLAY_SCALE
	sprite.position = Vector2(0, -34)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	queue_redraw()

func _load_model_texture() -> Texture2D:
	var path := str(MODEL_TEXTURES.get(GameState.character_model, MODEL_TEXTURES.sage))
	if ResourceLoader.exists(path):
		return load(path)
	push_warning("Атлас героя не найден: " + path)
	return load("res://assets/art/player_idle.png")

func _physics_process(delta: float) -> void:
	var input_direction := Vector2.ZERO
	if can_move and not action_lock:
		input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	var running := Input.is_action_pressed("run") and input_direction.length_squared() > 0.01
	var target_speed := RUN_SPEED if running else WALK_SPEED
	var target_velocity := input_direction * target_speed
	var rate := ACCELERATION if input_direction.length_squared() > 0.01 else DECELERATION
	velocity = velocity.move_toward(target_velocity, rate * delta)

	if input_direction.length_squared() > 0.01:
		facing = input_direction.normalized()
		current_direction = _direction_name(facing)
		animation_clock += delta * (FRAME_RATE_RUN if running else FRAME_RATE_WALK)
		var phase := int(floor(animation_clock)) % 4
		sprite.frame = _direction_row(current_direction) * 4 + phase
		footstep_clock += delta
		var footstep_interval := 0.19 if running else 0.29
		if footstep_clock >= footstep_interval:
			footstep_clock = 0.0
			footstep.emit(position + Vector2(0, 18))
	else:
		footstep_clock = 0.0
		animation_clock = 1.0
		sprite.frame = _direction_row(current_direction) * 4 + 1

	if not action_lock:
		var speed_ratio := clampf(velocity.length() / RUN_SPEED, 0.0, 1.0)
		var step_wave := sin(animation_clock * TAU * 0.5) if input_direction.length_squared() > 0.01 else sin(Time.get_ticks_msec() * 0.0024) * 0.25
		sprite.position.y = -34.0 - abs(step_wave) * (1.7 + speed_ratio)
		sprite.rotation = step_wave * 0.008 * speed_ratio

	move_and_slide()
	position.x = clampf(position.x, 40.0, 1112.0)
	position.y = clampf(position.y, 195.0, 608.0)
	queue_redraw()

func _direction_name(direction: Vector2) -> String:
	if absf(direction.x) > absf(direction.y):
		return "right" if direction.x > 0.0 else "left"
	return "down" if direction.y > 0.0 else "up"

func _direction_row(direction: String) -> int:
	return {"down": 0, "left": 1, "right": 2, "up": 3}.get(direction, 0)

func face_toward(world_position: Vector2) -> void:
	var direction := global_position.direction_to(world_position)
	if direction.length_squared() > 0.01:
		facing = direction
		current_direction = _direction_name(direction)
		sprite.frame = _direction_row(current_direction) * 4 + 1

func play_action(_kind: String) -> void:
	action_lock = true
	can_move = false
	velocity = Vector2.ZERO
	var resting_frame := _direction_row(current_direction) * 4 + 1
	sprite.frame = resting_frame
	var start_position := Vector2(0, -34)
	var windup := create_tween().set_parallel(true)
	var lean := -0.09 if facing.x >= 0.0 else 0.09
	windup.tween_property(sprite, "rotation", lean, 0.14).set_trans(Tween.TRANS_BACK)
	windup.tween_property(sprite, "position", start_position + Vector2(-3 if facing.x >= 0.0 else 3, -4), 0.14)
	windup.tween_property(sprite, "scale", Vector2(DISPLAY_SCALE * 0.97, DISPLAY_SCALE * 1.04), 0.14)
	await windup.finished
	var strike := create_tween().set_parallel(true)
	strike.tween_property(sprite, "rotation", -lean * 0.55, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	strike.tween_property(sprite, "position", start_position + Vector2(3 if facing.x >= 0.0 else -3, 3), 0.12)
	strike.tween_property(sprite, "scale", Vector2(DISPLAY_SCALE * 1.04, DISPLAY_SCALE * 0.96), 0.12)
	await strike.finished
	var settle := create_tween().set_parallel(true)
	settle.tween_property(sprite, "rotation", 0.0, 0.2).set_trans(Tween.TRANS_ELASTIC)
	settle.tween_property(sprite, "position", start_position, 0.2)
	settle.tween_property(sprite, "scale", Vector2.ONE * DISPLAY_SCALE, 0.2)
	await settle.finished
	action_lock = false
	can_move = true

func celebrate() -> void:
	action_lock = true
	var tween := create_tween()
	tween.tween_property(sprite, "position:y", -49.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "position:y", -34.0, 0.28).set_trans(Tween.TRANS_BOUNCE)
	await tween.finished
	action_lock = false

func _draw() -> void:
	fill_ellipse(Vector2(0, 18), Vector2(19, 7), Color(0.08, 0.11, 0.08, 0.34))

func fill_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 24:
		var angle := TAU * i / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
