extends CharacterBody2D

# Movement constants
const GRAVITY: float = 1200.0

# State
var is_jumping: bool = false
var target_platform: Node2D = null
var can_type: bool = true
var jump_horizontal_velocity: float = 0.0

# References
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

signal landed_on_platform
signal started_jumping

func _ready():
	pass

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		# Only count as landed if we were falling (not just starting a jump)
		if is_jumping and velocity.y >= 0:
			is_jumping = false
			velocity.x = 0
			emit_signal("landed_on_platform")

	move_and_slide()

	# Flip sprite based on movement direction
	if velocity.x < -10:
		sprite.flip_h = true
	elif velocity.x > 10:
		sprite.flip_h = false

func jump_to_platform(platform: Node2D):
	target_platform = platform
	is_jumping = true
	can_type = false

	# Calculate arc trajectory to reach target platform
	var target_pos = platform.global_position + Vector2(0, -32)  # Account for player offset
	var distance = target_pos - global_position

	# Calculate jump velocity needed to reach the platform
	# Using kinematic equations for projectile motion
	var height = abs(distance.y) + 50  # Extra height for nice arc
	var jump_velocity_y = -sqrt(2 * GRAVITY * height)

	# Calculate time to reach peak and then fall to target
	var time_to_peak = abs(jump_velocity_y) / GRAVITY
	var fall_height = height - abs(distance.y)
	var time_to_fall = sqrt(2 * fall_height / GRAVITY) if fall_height > 0 else 0
	var total_time = time_to_peak + time_to_fall

	# Horizontal velocity to cover horizontal distance in that time
	var jump_velocity_x = distance.x / total_time if total_time > 0 else 0

	velocity.y = jump_velocity_y
	velocity.x = jump_velocity_x

	emit_signal("started_jumping")

	# Play jump animation if available
	if animation_player and animation_player.has_animation("jump"):
		animation_player.play("jump")

func enable_typing():
	can_type = true

func set_position_on_platform(platform: Node2D):
	global_position = platform.global_position + Vector2(0, -32)
