extends Camera2D

@export var target: Node2D

# Auto-scroll settings (vertical ascending)
var base_scroll_speed: float = 30.0  # Pixels per second
var current_scroll_speed: float = 30.0
var scroll_speed_increase: float = 0.10  # 10% increase per 10 floors
var is_scrolling: bool = false
var start_delay: float = 3.0  # Seconds before scrolling starts
var delay_timer: float = 0.0

# Game manager reference for floor tracking
var game_manager: Node = null

func _ready():
	# Start at bottom of screen
	position = Vector2(640, 400)  # Center of 1280x720 viewport

func _process(delta):
	if not is_scrolling:
		# Wait for start delay
		delay_timer += delta
		if delay_timer >= start_delay:
			is_scrolling = true
		return

	# Calculate scroll speed based on current floor
	if game_manager:
		var floor_tier = int(game_manager.current_floor / 10)
		current_scroll_speed = base_scroll_speed * (1.0 + floor_tier * scroll_speed_increase)

	# Auto-scroll upward (negative Y)
	position.y -= current_scroll_speed * delta

	# If player is ahead of auto-scroll, follow them instead
	if target:
		var player_camera_y = target.global_position.y - 100  # Look ahead (above)
		if player_camera_y < position.y:
			position.y = player_camera_y

func set_target(new_target: Node2D):
	target = new_target

func set_game_manager(gm: Node):
	game_manager = gm

func reset_position():
	position = Vector2(640, 400)
	is_scrolling = false
	delay_timer = 0.0

func get_scroll_speed() -> float:
	return current_scroll_speed
