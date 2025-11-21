extends Control

@onready var climb_icon: Button = $DesktopIcons/ClimbIcon
@onready var selection_highlight: ColorRect = $DesktopIcons/ClimbIcon/SelectionHighlight
@onready var boot_overlay: ColorRect = $BootOverlay
@onready var boot_text: Label = $BootOverlay/BootText
@onready var start_button: Button = $Taskbar/StartButton

var is_icon_selected: bool = false
var click_count: int = 0
var click_timer: float = 0.0
const DOUBLE_CLICK_TIME: float = 0.4

func _ready() -> void:
	climb_icon.pressed.connect(_on_climb_icon_pressed)
	climb_icon.mouse_entered.connect(_on_icon_mouse_entered)
	climb_icon.mouse_exited.connect(_on_icon_mouse_exited)
	start_button.pressed.connect(_on_start_pressed)

	# Fade in from black
	var fade_in := ColorRect.new()
	fade_in.color = Color(0, 0, 0, 1)
	fade_in.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_in.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade_in)

	var tween := create_tween()
	tween.tween_property(fade_in, "color:a", 0.0, 0.5)
	tween.tween_callback(fade_in.queue_free)

func _process(delta: float) -> void:
	# Handle double-click timing
	if click_timer > 0:
		click_timer -= delta
		if click_timer <= 0:
			click_count = 0

func _on_climb_icon_pressed() -> void:
	click_count += 1
	click_timer = DOUBLE_CLICK_TIME

	if click_count == 1:
		# Single click - select icon
		_select_icon()
	elif click_count >= 2:
		# Double click - launch game
		_launch_climb()
		click_count = 0

func _select_icon() -> void:
	is_icon_selected = true
	selection_highlight.visible = true

func _on_icon_mouse_entered() -> void:
	if not is_icon_selected:
		selection_highlight.visible = true
		selection_highlight.color = Color(0, 0, 0.5, 0.3)

func _on_icon_mouse_exited() -> void:
	if not is_icon_selected:
		selection_highlight.visible = false
	else:
		selection_highlight.color = Color(0, 0, 0.5, 0.5)

func _input(event: InputEvent) -> void:
	# Allow Enter/Space to launch if icon is selected
	if is_icon_selected and event.is_action_pressed("ui_accept"):
		_launch_climb()

	# Click elsewhere to deselect
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var click_pos: Vector2 = event.position
			var icon_rect := climb_icon.get_global_rect()
			if not icon_rect.has_point(click_pos):
				_deselect_icon()

func _deselect_icon() -> void:
	is_icon_selected = false
	selection_highlight.visible = false

func _on_start_pressed() -> void:
	# Return to overworld (like shutting down)
	_return_to_overworld()

func _launch_climb() -> void:
	# Show boot sequence
	boot_overlay.visible = true

	var tween := create_tween()

	# Boot text sequence
	tween.tween_property(boot_text, "text", "Loading CLIMB.exe...", 0.0)
	tween.tween_interval(0.5)
	tween.tween_property(boot_text, "text", "Initializing word database...", 0.0)
	tween.tween_interval(0.4)
	tween.tween_property(boot_text, "text", "Starting game...", 0.0)
	tween.tween_interval(0.3)
	tween.tween_callback(_change_to_game)

func _change_to_game() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _return_to_overworld() -> void:
	var tween := create_tween()

	# Create fade overlay
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)

	tween.tween_property(fade, "color:a", 1.0, 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/overworld.tscn"))
