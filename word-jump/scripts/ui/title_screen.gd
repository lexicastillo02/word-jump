extends Control

@onready var new_game_button: Button = $TitleContainer/MenuContainer/NewGameButton
@onready var load_game_button: Button = $TitleContainer/MenuContainer/LoadGameButton
@onready var quit_button: Button = $TitleContainer/MenuContainer/QuitButton

func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	load_game_button.pressed.connect(_on_load_game_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Check if save exists
	_update_load_button_state()

	# Focus on new game button
	new_game_button.grab_focus()

func _update_load_button_state() -> void:
	var save_exists := SaveManager.save_exists()
	load_game_button.disabled = not save_exists
	if save_exists:
		var save_info := SaveManager.get_save_info()
		load_game_button.text = "Load Game (Day %d)" % save_info.get("day_count", 1)
	else:
		load_game_button.text = "Load Game"

func _on_new_game_pressed() -> void:
	# Reset game state for new game
	if GameSettings.has_method("reset_game"):
		GameSettings.reset_game()

	# Fade transition to apartment
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)

	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.5)
	tween.tween_callback(_start_new_game)

func _start_new_game() -> void:
	get_tree().change_scene_to_file("res://scenes/apartment.tscn")

func _on_load_game_pressed() -> void:
	if not SaveManager.save_exists():
		return

	var success := SaveManager.load_game()
	if not success:
		load_game_button.text = "Load Failed!"
		await get_tree().create_timer(1.0).timeout
		_update_load_button_state()
		return

	# Fade transition to apartment
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)

	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.5)
	tween.tween_callback(_load_apartment)

func _load_apartment() -> void:
	get_tree().change_scene_to_file("res://scenes/apartment.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
