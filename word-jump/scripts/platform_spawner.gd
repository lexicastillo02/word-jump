extends Node2D

const PLATFORM_SCENE_PATH = "res://scenes/platform.tscn"
var platform_scene: PackedScene

# Spawning parameters (vertical ascending, widescreen)
const VERTICAL_SPACING: float = 120.0
const VIEWPORT_WIDTH: float = 1280.0
const VIEWPORT_HEIGHT: float = 720.0

# Platform positions spread across wide screen (4-5 platforms per level)
const MIN_X: float = 100.0
const MAX_X: float = 1180.0

var platforms: Array = []
var highest_platform_y: float = 0.0
var platform_count: int = 0

# Reference to word manager for generating words
var word_manager: Node
var current_difficulty: int = 1  # 0=Easy, 1=Medium, 2=Hard

signal platform_spawned(platform: Node2D)

func set_word_manager(wm: Node):
	word_manager = wm

func set_difficulty(difficulty: int):
	current_difficulty = difficulty

func _ready():
	platform_scene = load(PLATFORM_SCENE_PATH)
	# Don't spawn here - wait for main to set word_manager first

func initialize():
	# Called by main after word_manager is set
	spawn_initial_platforms()

func spawn_initial_platforms():
	# Spawn starting platform at bottom center
	spawn_platform(Vector2(VIEWPORT_WIDTH / 2, 600), 0)

	# Spawn single path - one platform per level (spawn more ahead)
	for i in range(1, 12):  # 11 levels above start
		var y_pos = 600 - (i * VERTICAL_SPACING)
		var x_pos = randf_range(MIN_X, MAX_X)
		spawn_platform(Vector2(x_pos, y_pos), i)

func spawn_platform(pos: Vector2, floor_num: int) -> Node2D:
	var platform = platform_scene.instantiate()
	platform.position = pos

	# Determine platform type based on floor
	platform.platform_type = get_platform_type_for_floor(floor_num)

	add_child(platform)
	platforms.append(platform)

	if pos.y < highest_platform_y:
		highest_platform_y = pos.y

	platform_count = floor_num

	# Assign a word to the platform (skip first platform - player starts there)
	if floor_num > 0 and word_manager:
		var word = word_manager.get_word_for_floor(floor_num)

		# Apply challenge based on difficulty
		var challenge = word_manager.get_random_challenge(current_difficulty, floor_num)
		if challenge != word_manager.ChallengeType.NORMAL:
			var displayed = word_manager.apply_challenge(word, challenge)
			platform.set_word_with_challenge(word, displayed, challenge)
		else:
			platform.set_word(word)

	emit_signal("platform_spawned", platform)

	return platform

func get_platform_type_for_floor(floor_num: int) -> int:
	# Platform type distribution based on difficulty
	if floor_num <= 10:
		return 0  # All static in tutorial
	elif floor_num <= 25:
		# 80% static, 20% timed
		return 0 if randf() < 0.8 else 2
	elif floor_num <= 50:
		# 60% static, 20% timed, 20% shaky
		var roll = randf()
		if roll < 0.6:
			return 0
		elif roll < 0.8:
			return 2
		else:
			return 1
	else:
		# 40% static, 30% timed, 20% shaky, 10% moving
		var roll = randf()
		if roll < 0.4:
			return 0
		elif roll < 0.7:
			return 2
		elif roll < 0.9:
			return 1
		else:
			return 3

func spawn_next_platforms(current_floor: int):
	# Spawn single platform at the next level
	var y_pos = highest_platform_y - VERTICAL_SPACING
	var x_pos = randf_range(MIN_X, MAX_X)
	spawn_platform(Vector2(x_pos, y_pos), current_floor)

func get_platform_at_floor(floor_num: int) -> Node2D:
	# Get any platform at the given floor
	for platform in platforms:
		if is_instance_valid(platform):
			var platform_floor = int((600 - platform.position.y) / VERTICAL_SPACING)
			if platform_floor == floor_num:
				return platform
	return null

func get_next_platform(current_floor: int) -> Node2D:
	return get_platform_at_floor(current_floor + 1)

func cleanup_platforms_below(y_threshold: float):
	for platform in platforms:
		if is_instance_valid(platform) and platform.position.y > y_threshold:
			# Release the word back to the pool
			if word_manager and platform.current_word != "":
				word_manager.release_word(platform.current_word)
			platform.queue_free()

	platforms = platforms.filter(func(p): return is_instance_valid(p))

func get_reachable_platforms(from_y: float, max_levels: int = 3) -> Array:
	# Get platforms within jump range (above the player, within max_levels)
	var reachable: Array = []
	var sorted_platforms = platforms.filter(func(p):
		return is_instance_valid(p) and p.position.y < from_y
	)

	# Sort by Y position (nearest first = highest Y value among those above)
	sorted_platforms.sort_custom(func(a, b): return a.position.y > b.position.y)

	# Take platforms within max_levels vertical distance
	var max_y_distance = max_levels * VERTICAL_SPACING
	for platform in sorted_platforms:
		if from_y - platform.position.y <= max_y_distance:
			reachable.append(platform)

	return reachable

func get_platform_by_word(word: String) -> Node2D:
	for platform in platforms:
		if is_instance_valid(platform) and platform.current_word == word:
			return platform
	return null
