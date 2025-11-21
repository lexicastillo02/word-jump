extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var interaction_prompt: Label = $UI/InteractionPrompt
@onready var dialogue_box: Panel = $UI/DialogueBox
@onready var dialogue_text: Label = $UI/DialogueBox/DialogueText

var is_dialogue_active: bool = false

# Dialogue content for each interactable
var dialogues := {
	"Computer": "Boot up the computer and play Word Jump?",
	"Bed": "Not tired yet... Maybe after one more game.",
	"Bookshelf": "A collection of typing guides and game manuals.",
	"Window": "The city lights twinkle in the evening sky."
}

func _ready() -> void:
	player.entered_interaction_zone.connect(_on_player_entered_zone)
	player.exited_interaction_zone.connect(_on_player_exited_zone)

	# Check if returning from game
	if GameSettings.has_method("get") and GameSettings.get("returning_from_game"):
		_show_return_dialogue()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if is_dialogue_active:
			_close_dialogue()
		elif player.is_in_interaction_zone():
			_interact_with_zone(player.get_current_zone())

func _on_player_entered_zone(zone_name: String) -> void:
	if not is_dialogue_active:
		interaction_prompt.visible = true
		_update_prompt_for_zone(zone_name)

func _on_player_exited_zone(_zone_name: String) -> void:
	if not player.is_in_interaction_zone():
		interaction_prompt.visible = false

func _update_prompt_for_zone(zone_name: String) -> void:
	if zone_name == "Computer":
		interaction_prompt.text = "Press SPACE to play"
	else:
		interaction_prompt.text = "Press SPACE to interact"

func _interact_with_zone(zone_name: String) -> void:
	match zone_name:
		"Computer":
			_launch_word_jump()
		_:
			_show_dialogue(zone_name)

func _show_dialogue(zone_name: String) -> void:
	if zone_name in dialogues:
		dialogue_text.text = dialogues[zone_name]
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

func _launch_word_jump() -> void:
	# Disable player movement
	player.set_can_move(false)
	interaction_prompt.visible = false

	# Simple fade transition
	var tween := create_tween()

	# Create fade overlay
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	$UI.add_child(fade)

	# Fade to black
	tween.tween_property(fade, "color:a", 1.0, 0.5)
	tween.tween_callback(_change_to_game_scene)

func _change_to_game_scene() -> void:
	get_tree().change_scene_to_file("res://scenes/desktop.tscn")

func _show_return_dialogue() -> void:
	# This will be expanded in Phase 4
	pass
