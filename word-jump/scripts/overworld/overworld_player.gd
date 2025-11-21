extends CharacterBody2D

signal entered_interaction_zone(zone_name: String)
signal exited_interaction_zone(zone_name: String)

@export var move_speed: float = 120.0

var current_interaction_zone: String = ""
var can_move: bool = true

@onready var interaction_area: Area2D = $InteractionArea

func _ready() -> void:
	interaction_area.area_entered.connect(_on_area_entered)
	interaction_area.area_exited.connect(_on_area_exited)

func _physics_process(_delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		return

	var input_direction := Vector2.ZERO

	# Get input
	if Input.is_action_pressed("ui_left"):
		input_direction.x -= 1
	if Input.is_action_pressed("ui_right"):
		input_direction.x += 1
	if Input.is_action_pressed("ui_up"):
		input_direction.y -= 1
	if Input.is_action_pressed("ui_down"):
		input_direction.y += 1

	# Normalize for diagonal movement
	if input_direction.length() > 0:
		input_direction = input_direction.normalized()

	# Apply velocity
	velocity = input_direction * move_speed

	move_and_slide()

func _on_area_entered(area: Area2D) -> void:
	var zone_name := area.name.replace("Zone", "")
	current_interaction_zone = zone_name
	entered_interaction_zone.emit(zone_name)

func _on_area_exited(area: Area2D) -> void:
	var zone_name := area.name.replace("Zone", "")
	if current_interaction_zone == zone_name:
		current_interaction_zone = ""
	exited_interaction_zone.emit(zone_name)

func is_in_interaction_zone() -> bool:
	return current_interaction_zone != ""

func get_current_zone() -> String:
	return current_interaction_zone

func set_can_move(value: bool) -> void:
	can_move = value
	if not can_move:
		velocity = Vector2.ZERO
