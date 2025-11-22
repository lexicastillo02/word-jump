extends Node

# Global game settings (autoload singleton)

# Word Jump settings
enum Difficulty { EASY, MEDIUM, HARD }
var selected_difficulty: Difficulty = Difficulty.MEDIUM

# WFH game state
var day_count: int = 1
var door_interactions: int = 0
var door_opened: bool = false

# Flags for narrative progression
var has_slept: bool = false
var work_completed_today: bool = false

# Return context from minigames
var last_score: int = 0
var last_floor: int = 0
var returning_from_game: bool = false

# Track where player launched desktop/game from
var desktop_source: String = "apartment"  # "apartment" or "work"

# Persistent stats (saved to file)
var high_score: int = 0
var total_work_sessions: int = 0

# Progression tracking (saved to file)
var purchased_decorations: Array = []
var discovered_clues: Array = []
var manager_visits_completed: Array = []

func reset_game() -> void:
	# Reset all game state for new game
	day_count = 1
	door_interactions = 0
	door_opened = false
	has_slept = false
	work_completed_today = false
	last_score = 0
	last_floor = 0
	returning_from_game = false
	selected_difficulty = Difficulty.MEDIUM
	high_score = 0
	total_work_sessions = 0
	purchased_decorations = []
	discovered_clues = []
	manager_visits_completed = []

func advance_day() -> void:
	day_count += 1
	has_slept = true
	work_completed_today = false

func increment_door_interaction() -> int:
	door_interactions += 1
	return door_interactions
