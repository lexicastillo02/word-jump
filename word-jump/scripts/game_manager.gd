extends Node

# Game state
enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }
enum Difficulty { EASY, MEDIUM, HARD }
var current_state: GameState = GameState.MENU
var current_difficulty: Difficulty = Difficulty.MEDIUM

# Difficulty settings
const DIFFICULTY_LIVES = {
	Difficulty.EASY: 10,
	Difficulty.MEDIUM: 5,
	Difficulty.HARD: 3
}

# Player stats
var score: int = 0
var combo: int = 0
var max_combo: int = 0
var lives: int = 5
var current_floor: int = 1
var time_remaining: float = 60.0

# Scoring constants
const BASE_POINTS_PER_CHAR: int = 10
const SPEED_BONUS_MULTIPLIER: float = 2.0
const ACCURACY_BONUS: float = 1.5
const COMBO_MILESTONES: Array = [5, 10, 15, 20]

# Signals
signal score_changed(new_score: int)
signal combo_changed(new_combo: int)
signal lives_changed(new_lives: int)
signal floor_changed(new_floor: int)
signal time_changed(new_time: float)
signal game_over
signal game_started

func _ready():
	pass

func set_difficulty(difficulty: Difficulty):
	current_difficulty = difficulty

func start_game():
	score = 0
	combo = 0
	max_combo = 0
	lives = DIFFICULTY_LIVES[current_difficulty]
	current_floor = 1
	time_remaining = 60.0
	current_state = GameState.PLAYING
	emit_signal("game_started")
	emit_signal("score_changed", score)
	emit_signal("combo_changed", combo)
	emit_signal("lives_changed", lives)
	emit_signal("floor_changed", current_floor)
	emit_signal("time_changed", time_remaining)

func _process(delta):
	if current_state == GameState.PLAYING:
		time_remaining -= delta
		emit_signal("time_changed", time_remaining)
		if time_remaining <= 0:
			trigger_game_over()

func add_score(word_length: int, time_taken: float, perfect: bool, distance_mult: float = 1.0):
	var base_score = word_length * BASE_POINTS_PER_CHAR

	# Speed bonus (faster = more points)
	var speed_bonus = max(0, (5.0 - time_taken) * SPEED_BONUS_MULTIPLIER)

	# Accuracy bonus
	var accuracy_mult = ACCURACY_BONUS if perfect else 1.0

	# Combo multiplier
	var combo_mult = get_combo_multiplier()

	# Distance multiplier (risk/reward for farther jumps)
	var total = int(base_score * accuracy_mult * combo_mult * distance_mult + speed_bonus)
	score += total
	emit_signal("score_changed", score)
	return total

func get_combo_multiplier() -> float:
	if combo >= 20:
		return 5.0
	elif combo >= 15:
		return 4.0
	elif combo >= 10:
		return 3.0
	elif combo >= 5:
		return 2.0
	else:
		return 1.0

func increment_combo():
	combo += 1
	if combo > max_combo:
		max_combo = combo
	emit_signal("combo_changed", combo)

func reset_combo():
	combo = 0
	emit_signal("combo_changed", combo)

func lose_life():
	lives -= 1
	emit_signal("lives_changed", lives)
	reset_combo()
	if lives <= 0:
		trigger_game_over()

func add_time(seconds: float):
	time_remaining += seconds
	emit_signal("time_changed", time_remaining)

func advance_floor():
	current_floor += 1
	emit_signal("floor_changed", current_floor)
	# Bonus time for reaching new floor
	add_time(2.0)

func trigger_game_over():
	current_state = GameState.GAME_OVER
	emit_signal("game_over")

func get_difficulty_tier() -> int:
	if current_floor <= 10:
		return 0  # Tutorial
	elif current_floor <= 25:
		return 1  # Easy
	elif current_floor <= 50:
		return 2  # Medium
	elif current_floor <= 75:
		return 3  # Hard
	else:
		return 4  # Extreme
