extends Node

# Save file location
const SAVE_FILE_PATH := "user://wfh_save.json"

# Signals
signal save_completed(success: bool)
signal load_completed(success: bool)

# Save data structure
var save_data := {
	"version": 1,
	"day_count": 1,
	"door_interactions": 0,
	"door_opened": false,
	"work_completed_today": false,
	"high_score": 0,
	"total_work_sessions": 0,
	"purchased_decorations": [],
	"discovered_clues": [],
	"manager_visits_completed": [],
}

func _ready() -> void:
	pass

# === SAVE FUNCTIONS ===

func save_game() -> bool:
	# Gather current game state from GameSettings
	_gather_save_data()

	# Convert to JSON
	var json_string := JSON.stringify(save_data, "\t")

	# Write to file
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		var error := FileAccess.get_open_error()
		push_error("Failed to open save file for writing: " + str(error))
		emit_signal("save_completed", false)
		return false

	file.store_string(json_string)
	file.close()

	print("Game saved successfully to: ", SAVE_FILE_PATH)
	emit_signal("save_completed", true)
	return true

func _gather_save_data() -> void:
	# Pull data from GameSettings singleton
	save_data["day_count"] = GameSettings.day_count
	save_data["door_interactions"] = GameSettings.door_interactions
	save_data["door_opened"] = GameSettings.door_opened
	save_data["work_completed_today"] = GameSettings.work_completed_today
	save_data["high_score"] = GameSettings.high_score
	save_data["total_work_sessions"] = GameSettings.total_work_sessions
	save_data["purchased_decorations"] = GameSettings.purchased_decorations
	save_data["discovered_clues"] = GameSettings.discovered_clues
	save_data["manager_visits_completed"] = GameSettings.manager_visits_completed

# === LOAD FUNCTIONS ===

func load_game() -> bool:
	if not save_exists():
		push_warning("No save file found")
		emit_signal("load_completed", false)
		return false

	# Read file
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		var error := FileAccess.get_open_error()
		push_error("Failed to open save file for reading: " + str(error))
		emit_signal("load_completed", false)
		return false

	var json_string := file.get_as_text()
	file.close()

	# Parse JSON
	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		push_error("Failed to parse save file: " + json.get_error_message())
		emit_signal("load_completed", false)
		return false

	var loaded_data = json.get_data()
	if typeof(loaded_data) != TYPE_DICTIONARY:
		push_error("Save file has invalid format")
		emit_signal("load_completed", false)
		return false

	# Validate and apply data
	if not _validate_save_data(loaded_data):
		push_error("Save file validation failed")
		emit_signal("load_completed", false)
		return false

	_apply_save_data(loaded_data)

	print("Game loaded successfully from: ", SAVE_FILE_PATH)
	emit_signal("load_completed", true)
	return true

func _validate_save_data(data: Dictionary) -> bool:
	# Check for required fields
	var required_fields := ["version", "day_count", "door_interactions", "door_opened"]
	for field in required_fields:
		if not data.has(field):
			push_error("Save file missing required field: " + field)
			return false

	# Check version compatibility
	if data["version"] > save_data["version"]:
		push_error("Save file is from a newer version of the game")
		return false

	return true

func _apply_save_data(data: Dictionary) -> void:
	# Apply loaded data to GameSettings
	GameSettings.day_count = data.get("day_count", 1)
	GameSettings.door_interactions = data.get("door_interactions", 0)
	GameSettings.door_opened = data.get("door_opened", false)
	GameSettings.work_completed_today = data.get("work_completed_today", false)
	GameSettings.high_score = data.get("high_score", 0)
	GameSettings.total_work_sessions = data.get("total_work_sessions", 0)
	GameSettings.purchased_decorations = data.get("purchased_decorations", [])
	GameSettings.discovered_clues = data.get("discovered_clues", [])
	GameSettings.manager_visits_completed = data.get("manager_visits_completed", [])

# === UTILITY FUNCTIONS ===

func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

func delete_save() -> bool:
	if not save_exists():
		return true

	var error := DirAccess.remove_absolute(SAVE_FILE_PATH)
	if error != OK:
		push_error("Failed to delete save file: " + str(error))
		return false

	print("Save file deleted")
	return true

func get_save_info() -> Dictionary:
	# Returns basic info about the save file without fully loading it
	if not save_exists():
		return {}

	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		return {}

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_string) != OK:
		return {}

	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		return {}

	return {
		"day_count": data.get("day_count", 1),
		"high_score": data.get("high_score", 0),
	}
