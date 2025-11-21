extends CanvasLayer

# UI References
@onready var score_label: Label = $ScoreLabel
@onready var combo_label: Label = $ComboLabel
@onready var lives_label: Label = $LivesLabel
@onready var floor_label: Label = $FloorLabel
@onready var timer_label: Label = $TimerLabel
@onready var word_display: Label = $WordContainer/VBoxContainer/WordDisplay
@onready var typed_display: Label = $WordContainer/VBoxContainer/TypedDisplay

# Game over UI
@onready var game_over_panel: Panel = $GameOverPanel
@onready var final_score_label: Label = $GameOverPanel/VBoxContainer/FinalScoreLabel
@onready var restart_button: Button = $GameOverPanel/VBoxContainer/RestartButton
@onready var pause_button: Button = $PauseButton

signal pause_requested

var game_manager: Node
var word_manager: Node

func _ready():
	if game_over_panel:
		game_over_panel.visible = false
	if pause_button:
		pause_button.pressed.connect(_on_pause_pressed)

func _on_pause_pressed():
	emit_signal("pause_requested")

func setup(gm: Node, wm: Node):
	game_manager = gm
	word_manager = wm

	# Connect signals
	game_manager.score_changed.connect(_on_score_changed)
	game_manager.combo_changed.connect(_on_combo_changed)
	game_manager.lives_changed.connect(_on_lives_changed)
	game_manager.floor_changed.connect(_on_floor_changed)
	game_manager.time_changed.connect(_on_time_changed)
	game_manager.game_over.connect(_on_game_over)

	word_manager.new_word_set.connect(_on_new_word)
	word_manager.character_typed.connect(_on_character_typed)

func _on_score_changed(new_score: int):
	if score_label:
		score_label.text = "Score: %d" % new_score

func _on_combo_changed(new_combo: int):
	if combo_label:
		if new_combo > 0:
			var mult = game_manager.get_combo_multiplier()
			combo_label.text = "Combo: %d (x%.1f)" % [new_combo, mult]
			combo_label.visible = true
		else:
			combo_label.visible = false

func _on_lives_changed(new_lives: int):
	if lives_label:
		lives_label.text = "Lives: %s" % "♥".repeat(new_lives)

func _on_floor_changed(new_floor: int):
	if floor_label:
		floor_label.text = "Floor: %d" % new_floor

func _on_time_changed(new_time: float):
	if timer_label:
		timer_label.text = "Time: %.1f" % new_time

		# Color coding for urgency
		if new_time <= 5:
			timer_label.modulate = Color.RED
		elif new_time <= 15:
			timer_label.modulate = Color.YELLOW
		else:
			timer_label.modulate = Color.WHITE

func _on_new_word(word: String):
	update_word_display(word, "")

func _on_character_typed(char: String, correct: bool, position: int):
	var typed = word_manager.get_typed_progress()
	var full_word = word_manager.get_current_word()
	update_word_display(full_word, typed)

func update_word_display(word: String, typed: String):
	if word_display and typed_display:
		# Show remaining characters
		word_display.text = word

		# Show typed progress with color coding
		typed_display.text = typed
		typed_display.modulate = Color.GREEN

func _on_game_over():
	if game_over_panel:
		game_over_panel.visible = true
		final_score_label.text = "Final Score: %d\nFloor: %d\nMax Combo: %d" % [
			game_manager.score,
			game_manager.current_floor,
			game_manager.max_combo
		]

func _on_restart_pressed():
	get_tree().reload_current_scene()

func show_score_popup(points: int, pos: Vector2):
	# Create floating score text (optional polish)
	pass
