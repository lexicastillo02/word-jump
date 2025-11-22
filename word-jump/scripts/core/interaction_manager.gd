extends Node

# Singleton for managing interactions across the apartment

signal interaction_available(object_name: String, prompt: String)
signal interaction_unavailable()
signal interaction_triggered(object_name: String)

var current_interaction_zone: String = ""
var interaction_prompts: Dictionary = {
	"Computer": "Use Computer",
	"Headset": "Put on Headset",
	"Bed": "Sleep",
	"Door": "Open Door",
	"Window": "Look Outside",
	"TV": "Watch TV",
	"Bookshelf": "Read"
}

# Default prompts for unknown objects
var default_prompt: String = "Interact"

func enter_zone(zone_name: String) -> void:
	current_interaction_zone = zone_name
	var prompt = interaction_prompts.get(zone_name, default_prompt)
	interaction_available.emit(zone_name, prompt)

func exit_zone(zone_name: String) -> void:
	if current_interaction_zone == zone_name:
		current_interaction_zone = ""
		interaction_unavailable.emit()

func trigger_interaction() -> String:
	if current_interaction_zone != "":
		interaction_triggered.emit(current_interaction_zone)
		return current_interaction_zone
	return ""

func is_in_zone() -> bool:
	return current_interaction_zone != ""

func get_current_zone() -> String:
	return current_interaction_zone

func set_prompt(zone_name: String, prompt: String) -> void:
	interaction_prompts[zone_name] = prompt
