extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var how_to_play_button: Button = $VBoxContainer/HowToPlayButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var how_to_play_panel: Panel = $HowToPlayPanel
@onready var back_button: Button = $HowToPlayPanel/VBoxContainer/BackButton

# Difficulty buttons
@onready var easy_button: Button = $DifficultyContainer/EasyButton
@onready var medium_button: Button = $DifficultyContainer/MediumButton
@onready var hard_button: Button = $DifficultyContainer/HardButton

var selected_difficulty: int = 1  # 0=Easy, 1=Medium, 2=Hard

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	how_to_play_button.pressed.connect(_on_how_to_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	back_button.pressed.connect(_on_back_pressed)

	easy_button.pressed.connect(_on_easy_pressed)
	medium_button.pressed.connect(_on_medium_pressed)
	hard_button.pressed.connect(_on_hard_pressed)

	how_to_play_panel.visible = false
	update_difficulty_buttons()

func _on_easy_pressed():
	selected_difficulty = 0
	GameSettings.selected_difficulty = GameSettings.Difficulty.EASY
	update_difficulty_buttons()

func _on_medium_pressed():
	selected_difficulty = 1
	GameSettings.selected_difficulty = GameSettings.Difficulty.MEDIUM
	update_difficulty_buttons()

func _on_hard_pressed():
	selected_difficulty = 2
	GameSettings.selected_difficulty = GameSettings.Difficulty.HARD
	update_difficulty_buttons()

func update_difficulty_buttons():
	easy_button.disabled = (selected_difficulty == 0)
	medium_button.disabled = (selected_difficulty == 1)
	hard_button.disabled = (selected_difficulty == 2)

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_how_to_play_pressed():
	how_to_play_panel.visible = true

func _on_back_pressed():
	how_to_play_panel.visible = false

func _on_quit_pressed():
	get_tree().quit()
