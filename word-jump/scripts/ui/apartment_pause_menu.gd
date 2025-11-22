extends CanvasLayer

@onready var overlay: ColorRect = $Overlay
@onready var panel: Panel = $Panel
@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var save_button: Button = $Panel/VBoxContainer/SaveButton
@onready var settings_button: Button = $Panel/VBoxContainer/SettingsButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton

var is_paused: bool = false

func _ready() -> void:
	overlay.visible = false
	panel.visible = false

	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	is_paused = !is_paused
	overlay.visible = is_paused
	panel.visible = is_paused
	get_tree().paused = is_paused

	if is_paused:
		resume_button.grab_focus()

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_save_pressed() -> void:
	var success := SaveManager.save_game()
	if success:
		save_button.text = "Saved!"
	else:
		save_button.text = "Save Failed!"
	await get_tree().create_timer(1.0).timeout
	save_button.text = "Save Game"

func _on_settings_pressed() -> void:
	# TODO: Implement settings menu
	pass

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
