extends StaticBody2D

enum PlatformType { STATIC, SHAKY, TIMED, MOVING }

@export var platform_type: PlatformType = PlatformType.STATIC
@export var platform_width: float = 200.0

# Timed platform settings
var time_until_collapse: float = 3.0
var collapse_timer: float = 0.0
var is_collapsing: bool = false

# Moving platform settings
var move_speed: float = 50.0
var move_range: float = 100.0
var start_x: float = 0.0
var move_direction: int = 1

# Shaky platform settings
var shake_intensity: float = 2.0
var original_position: Vector2

# Visual references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var word_label: Label = $WordLabel

signal platform_collapsed

var current_word: String = ""  # The actual word to type
var display_word: String = ""  # The displayed word (may be challenged)
var challenge_type: int = 0  # 0 = normal
var is_reachable: bool = false
var is_blocked: bool = false
var is_on_cooldown: bool = false
var base_color: Color = Color(0.2, 0.6, 0.9, 1)
var highlight_color: Color = Color(0.4, 1.0, 0.4, 1)  # Green for reachable
var blocked_color: Color = Color(0.5, 0.2, 0.2, 1)  # Dark red for blocked
var cooldown_color: Color = Color(0.4, 0.4, 0.4, 1)  # Gray for cooldown
@onready var color_rect: ColorRect = $ColorRect

func _ready():
	original_position = position
	start_x = position.x

	# Set up collision shape size (32px height prevents tunneling at high speeds)
	if collision and collision.shape is RectangleShape2D:
		collision.shape.size = Vector2(platform_width, 32)

func _process(delta):
	match platform_type:
		PlatformType.SHAKY:
			process_shaky(delta)
		PlatformType.TIMED:
			process_timed(delta)
		PlatformType.MOVING:
			process_moving(delta)

func process_shaky(delta):
	if is_collapsing:
		# Shake effect - only horizontal to prevent player falling through
		position.x = original_position.x + randf_range(-shake_intensity, shake_intensity)
		# Keep Y stable so player doesn't lose floor contact
		position.y = original_position.y

func process_timed(delta):
	if is_collapsing:
		collapse_timer -= delta

		# Visual warning - flash red
		if sprite:
			sprite.modulate = Color.RED if fmod(collapse_timer, 0.3) < 0.15 else Color.WHITE

		if collapse_timer <= 0:
			emit_signal("platform_collapsed")
			queue_free()

func process_moving(delta):
	position.x += move_speed * move_direction * delta

	if abs(position.x - start_x) >= move_range:
		move_direction *= -1

func start_collapse_sequence():
	is_collapsing = true
	collapse_timer = time_until_collapse

func player_landed():
	# Called when player lands on this platform
	clear_word()
	match platform_type:
		PlatformType.TIMED:
			start_collapse_sequence()
		PlatformType.SHAKY:
			is_collapsing = true
			# Shaky platforms also collapse after some time
			await get_tree().create_timer(time_until_collapse).timeout
			emit_signal("platform_collapsed")
			queue_free()

func set_word(word: String):
	current_word = word
	display_word = word
	if word_label:
		word_label.text = word
		word_label.visible = true

func set_word_with_challenge(word: String, displayed: String, challenge: int):
	current_word = word
	display_word = displayed
	challenge_type = challenge
	if word_label:
		word_label.text = displayed
		word_label.visible = true
		# Color code by challenge type
		match challenge:
			1:  # SCRAMBLED
				word_label.modulate = Color(1.0, 0.8, 0.3, 1)  # Yellow/orange
			2:  # BACKWARDS
				word_label.modulate = Color(1.0, 0.5, 0.8, 1)  # Pink
			3:  # MISSING_VOWELS
				word_label.modulate = Color(0.5, 0.8, 1.0, 1)  # Light blue
			_:
				word_label.modulate = Color.WHITE

func clear_word():
	current_word = ""
	if word_label:
		word_label.text = ""
		word_label.visible = false

func update_typed_progress(typed: String):
	if word_label and current_word.length() > 0:
		# Show typed characters in green, remaining in white
		var remaining = current_word.substr(typed.length())
		word_label.text = remaining

func set_reachable(reachable: bool):
	is_reachable = reachable
	update_platform_color()

func set_blocked(blocked: bool):
	is_blocked = blocked
	update_platform_color()
	if word_label:
		word_label.modulate = Color(0.5, 0.5, 0.5, 0.5) if blocked else Color.WHITE

func update_platform_color():
	if color_rect:
		if is_blocked:
			color_rect.color = blocked_color
		elif is_on_cooldown:
			color_rect.color = cooldown_color
		elif is_reachable:
			color_rect.color = highlight_color
		else:
			color_rect.color = base_color

func start_cooldown(duration: float = 5.0):
	is_on_cooldown = true

	# Flash red briefly
	if color_rect:
		color_rect.color = Color.RED

	# Fade the word
	if word_label:
		word_label.modulate = Color(0.5, 0.5, 0.5, 0.5)

	# After brief flash, go to gray cooldown state
	await get_tree().create_timer(0.2).timeout
	update_platform_color()

	# Wait for cooldown to end
	await get_tree().create_timer(duration - 0.2).timeout

	# Restore platform
	is_on_cooldown = false
	if word_label:
		word_label.modulate = Color.WHITE
	# Restore word display
	set_word(current_word)
	update_platform_color()

func get_jump_distance(from_y: float) -> int:
	# Calculate how many "levels" away this platform is (vertical)
	var distance = from_y - position.y
	return int(distance / 120.0)  # VERTICAL_SPACING is 120
