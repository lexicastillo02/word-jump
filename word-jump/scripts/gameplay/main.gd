extends Node2D

# Scene references
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var platform_spawner: Node2D = $PlatformSpawner
@onready var hud: CanvasLayer = $HUD
@onready var game_manager: Node = $GameManager
@onready var word_manager: Node = $WordManager
@onready var background: ParallaxBackground = $ParallaxBackground
@onready var pause_menu: CanvasLayer = $PauseMenu

var current_platform_index: int = 0
var current_platform: Node2D
var target_platform: Node2D
var reachable_platforms: Array = []
var typed_buffer: String = ""
const MAX_JUMP_RANGE: int = 1  # Only show the next platform

# Auto-scroll death detection
const DEATH_BUFFER: float = 100.0  # How far below camera before death

# Screen shake
var shake_timer: float = 0.0
var shake_intensity: float = 0.0
var original_camera_offset: Vector2 = Vector2.ZERO

func _ready():
	# Set up camera target and game manager
	camera.set_target(player)
	camera.set_game_manager(game_manager)

	# Set up platform spawner with word manager BEFORE spawning
	platform_spawner.set_word_manager(word_manager)
	platform_spawner.initialize()

	# Connect HUD to managers
	hud.setup(game_manager, word_manager)

	# Connect signals
	player.landed_on_platform.connect(_on_player_landed)
	game_manager.game_over.connect(_on_game_over)
	game_manager.game_started.connect(_on_game_started)

	# Connect restart button
	var restart_btn = hud.get_node_or_null("GameOverPanel/VBoxContainer/RestartButton")
	if restart_btn:
		restart_btn.pressed.connect(_on_restart_pressed)

	# Connect main menu button
	var menu_btn = hud.get_node_or_null("GameOverPanel/VBoxContainer/MainMenuButton")
	if menu_btn:
		menu_btn.pressed.connect(_on_main_menu_pressed)

	# Connect pause button from HUD
	hud.pause_requested.connect(_on_pause_requested)

	# Start the game
	start_game()

func _on_pause_requested():
	if pause_menu:
		pause_menu.toggle_pause()

func start_game():
	# Apply difficulty setting from menu
	game_manager.set_difficulty(GameSettings.selected_difficulty)
	game_manager.start_game()

	# Pass difficulty to platform spawner for word challenges
	platform_spawner.set_difficulty(GameSettings.selected_difficulty)

	# Position player on first platform
	current_platform = platform_spawner.get_platform_at_floor(0)
	if current_platform:
		player.set_position_on_platform(current_platform)
		player.enable_typing()

	# Set up reachable platforms
	update_reachable_platforms()

func update_reachable_platforms():
	# Clear old highlights
	for platform in reachable_platforms:
		if is_instance_valid(platform):
			platform.set_reachable(false)

	# Get new reachable platforms (above player)
	reachable_platforms = platform_spawner.get_reachable_platforms(
		player.global_position.y, MAX_JUMP_RANGE
	)

	# Highlight them
	for platform in reachable_platforms:
		platform.set_reachable(true)

	# Reset typed buffer
	typed_buffer = ""

func find_matching_platform(typed: String) -> Node2D:
	# Find a reachable platform whose word matches what was typed (excluding blocked/cooldown)
	for platform in reachable_platforms:
		if is_instance_valid(platform) and not platform.is_blocked and not platform.is_on_cooldown:
			if platform.current_word.to_lower() == typed.to_lower():
				return platform
	return null

func find_partial_matches(typed: String) -> Array:
	# Find platforms whose words start with the typed characters (excluding blocked/cooldown)
	var matches: Array = []
	for platform in reachable_platforms:
		if is_instance_valid(platform) and not platform.is_blocked and not platform.is_on_cooldown:
			if platform.current_word.to_lower().begins_with(typed.to_lower()):
				matches.append(platform)
	return matches

func _process(delta):
	# Handle screen shake
	if shake_timer > 0:
		shake_timer -= delta
		camera.offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		if shake_timer <= 0:
			camera.offset = original_camera_offset

	# Check if player fell below camera (caught by auto-scroll)
	if game_manager.current_state == game_manager.GameState.PLAYING:
		var camera_bottom = camera.global_position.y + 360  # Half viewport height
		if player.global_position.y > camera_bottom + DEATH_BUFFER:
			# Player fell off screen
			game_manager.lose_life()
			# Respawn on current platform if possible
			if current_platform and is_instance_valid(current_platform):
				player.set_position_on_platform(current_platform)
				player.velocity = Vector2.ZERO
			typed_buffer = ""

func shake_screen(duration: float, intensity: float):
	shake_timer = duration
	shake_intensity = intensity
	original_camera_offset = camera.offset

func _input(event):
	if game_manager.current_state != game_manager.GameState.PLAYING:
		return

	if event is InputEventKey and event.pressed and player.can_type:
		var typed_char = char(event.unicode).to_lower()

		# Ignore non-letter characters
		if typed_char == "" or not typed_char.is_valid_identifier():
			return

		# Add to buffer
		typed_buffer += typed_char

		# Check for matches
		var partial_matches = find_partial_matches(typed_buffer)

		if partial_matches.size() == 0:
			# No matches - wrong character, lose life and shake screen
			game_manager.lose_life()

			# Screen shake feedback
			shake_screen(0.3, 8.0)

			typed_buffer = ""
			# Reset word displays on all platforms
			for platform in reachable_platforms:
				if is_instance_valid(platform):
					platform.set_word(platform.current_word)
		else:
			# Update display on matching platforms
			for platform in partial_matches:
				platform.update_typed_progress(typed_buffer)

			# Check for complete match
			var complete_match = find_matching_platform(typed_buffer)
			if complete_match:
				# Word completed - jump to this platform!
				target_platform = complete_match
				var time_taken = 1.0  # TODO: track actual time
				_on_word_completed(complete_match.current_word, time_taken, true)

func _on_word_completed(word: String, time_taken: float, perfect: bool):
	# Calculate jump distance for risk/reward bonus
	var jump_distance = 1
	if target_platform:
		jump_distance = target_platform.get_jump_distance(player.global_position.y)
		jump_distance = max(1, jump_distance)

	# Calculate and add score with distance multiplier
	var distance_multiplier = 1.0 + (jump_distance - 1) * 0.5  # 1x, 1.5x, 2x for 1, 2, 3 levels
	var points = game_manager.add_score(word.length(), time_taken, perfect, distance_multiplier)
	game_manager.increment_combo()

	# Bonus time for risky jumps
	if jump_distance >= 2:
		game_manager.add_time(jump_distance * 1.0)  # +2s for 2 levels, +3s for 3 levels

	# Jump to the target platform
	if target_platform:
		# Release the word back to the pool
		word_manager.release_word(target_platform.current_word)

		player.jump_to_platform(target_platform)
		current_platform_index += 1
		current_platform = target_platform

		# Spawn next platforms ahead
		platform_spawner.spawn_next_platforms(current_platform_index + 5)

		# Advance floor
		game_manager.advance_floor()

func _on_player_landed():
	# Enable typing again
	player.enable_typing()

	# Notify platform that player landed
	if current_platform and current_platform.has_method("player_landed"):
		current_platform.player_landed()

	# Update reachable platforms from new position
	update_reachable_platforms()

	# Clean up platforms below
	platform_spawner.cleanup_platforms_below(player.global_position.y + 500)

func _on_game_over():
	player.can_type = false

func _on_game_started():
	pass

func _on_restart_pressed():
	get_tree().reload_current_scene()

func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
