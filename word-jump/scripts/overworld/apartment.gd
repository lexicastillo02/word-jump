extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var interaction_prompt: Label = $UI/InteractionPrompt
@onready var dialogue_box: Panel = $UI/DialogueBox
@onready var dialogue_text: Label = $UI/DialogueBox/DialogueText
@onready var day_label: Label = $UI/DayLabel

var is_dialogue_active: bool = false
var is_transitioning: bool = false

# Door dialogue progression
var door_dialogues := [
	"I don't need to go outside.",
	"There's nothing out there for me.",
	"Why do I keep trying?",
	"...",
	"Fine. I'll open it."
]

var door_opened_dialogue := "There's nowhere to go."
var brick_wall_revealed := false

# Standard dialogues
var dialogues := {
	"Window": "The city looks the same as always...",
	"Bookshelf": "A collection of typing guides and game manuals.",
	"TV": "The TV is off.",
	"Headset": "Time to get to work."
}

func _ready() -> void:
	player.entered_interaction_zone.connect(_on_player_entered_zone)
	player.exited_interaction_zone.connect(_on_player_exited_zone)

	# Update day display
	_update_day_display()

	# Reset returning flag (dialogue removed for now)
	if GameSettings.returning_from_game:
		GameSettings.returning_from_game = false

func _input(event: InputEvent) -> void:
	if is_transitioning:
		return

	if event.is_action_pressed("ui_accept"):
		if is_dialogue_active:
			_close_dialogue()
		elif player.is_in_interaction_zone():
			_interact_with_zone(player.get_current_zone())

func _on_player_entered_zone(zone_name: String) -> void:
	if not is_dialogue_active and not is_transitioning:
		interaction_prompt.visible = true
		_update_prompt_for_zone(zone_name)

func _on_player_exited_zone(_zone_name: String) -> void:
	if not player.is_in_interaction_zone():
		interaction_prompt.visible = false

func _update_prompt_for_zone(zone_name: String) -> void:
	var prompts := {
		"Computer": "Use Computer",
		"Headset": "Put on Headset",
		"Bed": "Sleep",
		"Door": "Open Door",
		"Window": "Look Outside",
		"TV": "Watch TV",
		"Bookshelf": "Read"
	}
	var prompt = prompts.get(zone_name, "Interact")
	interaction_prompt.text = "SPACE - " + prompt

func _interact_with_zone(zone_name: String) -> void:
	match zone_name:
		"Computer":
			_use_computer()
		"Headset":
			_use_headset()
		"Bed":
			_sleep()
		"Door":
			_interact_door()
		_:
			_show_dialogue(zone_name)

func _show_dialogue(zone_name: String) -> void:
	var text = dialogues.get(zone_name, "...")
	_display_dialogue(text)

func _display_dialogue(text: String) -> void:
	dialogue_text.text = text
	dialogue_box.visible = true
	interaction_prompt.visible = false
	is_dialogue_active = true
	player.set_can_move(false)

func _close_dialogue() -> void:
	dialogue_box.visible = false
	is_dialogue_active = false
	player.set_can_move(true)

	if player.is_in_interaction_zone():
		interaction_prompt.visible = true

func _update_day_display() -> void:
	if day_label:
		day_label.text = "Day " + str(GameSettings.day_count)

# === BED MECHANICS ===
func _sleep() -> void:
	is_transitioning = true
	player.set_can_move(false)
	interaction_prompt.visible = false

	# Fade to black
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(fade)

	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 1.0)
	tween.tween_interval(1.0)
	tween.tween_callback(_advance_day)
	tween.tween_property(fade, "color:a", 0.0, 1.0)
	tween.tween_callback(func():
		fade.queue_free()
		is_transitioning = false
		player.set_can_move(true)
	)

func _advance_day() -> void:
	GameSettings.advance_day()
	_update_day_display()
	# Autosave when sleeping
	SaveManager.save_game()

# === DOOR MECHANICS ===
func _interact_door() -> void:
	if GameSettings.door_opened:
		# Already revealed the brick wall
		_display_dialogue(door_opened_dialogue)
		return

	var interaction_count = GameSettings.increment_door_interaction()

	if interaction_count <= door_dialogues.size():
		var dialogue = door_dialogues[interaction_count - 1]
		_display_dialogue(dialogue)

		# On the last dialogue, reveal the brick wall
		if interaction_count == door_dialogues.size():
			GameSettings.door_opened = true
			# TODO: Animate door opening to reveal brick wall
	else:
		_display_dialogue(door_opened_dialogue)

# === COMPUTER MECHANICS ===
func _use_computer() -> void:
	is_transitioning = true
	player.set_can_move(false)
	interaction_prompt.visible = false

	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(fade)

	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.5)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/desktop.tscn")
	)

# === HEADSET MECHANICS ===
func _use_headset() -> void:
	is_transitioning = true
	player.set_can_move(false)
	interaction_prompt.visible = false

	# Fade to white (work is the "white room")
	var fade := ColorRect.new()
	fade.color = Color(1, 1, 1, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(fade)

	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.5)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/work_hub.tscn")
	)

