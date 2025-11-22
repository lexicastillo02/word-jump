extends Node2D

@onready var start_work_button: Button = $UI/InteractionPanel/VBoxContainer/StartWorkButton
@onready var log_off_button: Button = $UI/InteractionPanel/VBoxContainer/LogOffButton
@onready var day_label: Label = $UI/DayLabel
@onready var status_label: Label = $UI/StatusLabel
@onready var dialogue_box: Panel = $UI/DialogueBox
@onready var dialogue_text: Label = $UI/DialogueBox/DialogueText
@onready var screen_text: Label = $Terminal/Screen/ScreenText

var is_dialogue_active: bool = false
var is_transitioning: bool = false

# Manager dialogue by day
var manager_visits := {
	3: {
		"dialogue": "Welcome to the team. I'm sure you'll fit right in here. Just focus on your work and everything will be fine.",
		"visited": false
	},
	5: {
		"dialogue": "Your metrics are looking good. Keep it up. The system appreciates consistency.",
		"visited": false
	},
	8: {
		"dialogue": "You've been here a while now. Do you ever wonder about... No, never mind. Back to work.",
		"visited": false
	},
	10: {
		"dialogue": "Have you been sleeping well? You look... different. Remember, productivity is self-care.",
		"visited": false
	},
	12: {
		"dialogue": "Some employees ask too many questions. Not you though. That's what we like about you.",
		"visited": false
	},
	15: {
		"dialogue": "The work never stops. It can't stop. You understand that now, don't you?",
		"visited": false
	}
}

func _ready() -> void:
	start_work_button.pressed.connect(_on_start_work_pressed)
	log_off_button.pressed.connect(_on_log_off_pressed)

	_update_ui()
	_check_manager_visit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and is_dialogue_active:
		_close_dialogue()

func _update_ui() -> void:
	day_label.text = "Day " + str(GameSettings.day_count) + " - Workspace"

	if GameSettings.work_completed_today:
		status_label.text = "Work: Complete"
		status_label.modulate = Color(0.3, 0.8, 0.3, 1)
		screen_text.text = "DONE"
		start_work_button.text = "Work Again"
	else:
		status_label.text = "Work: Incomplete"
		status_label.modulate = Color(0.8, 0.3, 0.3, 1)
		screen_text.text = "READY"
		start_work_button.text = "Start Work"

func _check_manager_visit() -> void:
	var day = GameSettings.day_count

	if day in manager_visits and not manager_visits[day]["visited"]:
		manager_visits[day]["visited"] = true
		# Delay the dialogue slightly
		await get_tree().create_timer(0.5).timeout
		_show_manager_dialogue(manager_visits[day]["dialogue"])

func _show_manager_dialogue(text: String) -> void:
	dialogue_text.text = text
	dialogue_box.visible = true
	is_dialogue_active = true
	start_work_button.disabled = true
	log_off_button.disabled = true

func _close_dialogue() -> void:
	dialogue_box.visible = false
	is_dialogue_active = false
	start_work_button.disabled = false
	log_off_button.disabled = false

func _on_start_work_pressed() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	start_work_button.disabled = true
	log_off_button.disabled = true

	# Transition to Word Jump
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(fade)

	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.3)
	tween.tween_callback(_launch_work)

func _launch_work() -> void:
	# Go to work desktop
	GameSettings.returning_from_game = false
	get_tree().change_scene_to_file("res://scenes/work_desktop.tscn")

func _on_log_off_pressed() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	start_work_button.disabled = true
	log_off_button.disabled = true

	# Fade to white then to apartment
	var fade := ColorRect.new()
	fade.color = Color(1, 1, 1, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(fade)

	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.5)
	tween.tween_callback(_return_to_apartment)

func _return_to_apartment() -> void:
	GameSettings.returning_from_game = true
	get_tree().change_scene_to_file("res://scenes/apartment.tscn")
