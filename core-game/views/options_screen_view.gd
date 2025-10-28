## OptionsScreenView - Complete view implementation for options screen
## Extends BaseScreenView and handles all options screen logic
## Game developers only need to create .tscn with UI layout
class_name OptionsScreenView
extends BaseScreenView

## Exported node paths for UI elements (set in editor)
@export var master_volume_slider_path: NodePath = ^"VBoxContainer/MasterVolumeSlider"
@export var music_volume_slider_path: NodePath = ^"VBoxContainer/MusicVolumeSlider"
@export var sfx_volume_slider_path: NodePath = ^"VBoxContainer/SFXVolumeSlider"
@export var fullscreen_checkbox_path: NodePath = ^"VBoxContainer/FullscreenCheckBox"
@export var resolution_label_path: NodePath = ^"VBoxContainer/ResolutionContainer/ResolutionLabel"
@export var resolution_prev_button_path: NodePath = ^"VBoxContainer/ResolutionContainer/ResolutionPrevButton"
@export var resolution_next_button_path: NodePath = ^"VBoxContainer/ResolutionContainer/ResolutionNextButton"
@export var vsync_checkbox_path: NodePath = ^"VBoxContainer/VSyncCheckBox"
@export var back_button_path: NodePath = ^"VBoxContainer/BackButton"

## UI element references
var master_volume_slider: HSlider
var music_volume_slider: HSlider
var sfx_volume_slider: HSlider
var fullscreen_checkbox: CheckBox
var resolution_label: Label
var resolution_prev_button: Button
var resolution_next_button: Button
var vsync_checkbox: CheckBox
var back_button: Button


func _ready() -> void:
	# Create model and controller
	var options_model = OptionsScreenModel.new()
	var options_controller = OptionsScreenController.new(options_model)
	
	# Get UI nodes FIRST (before setup, so initial model state can update them)
	_setup_ui_nodes()
	
	# Setup with BaseScreenView (triggers initial _on_model_changed with model's loaded values)
	setup(options_model, options_controller)
	
	# Find and set screen_manager reference on controller
	_find_and_set_screen_manager()
	
	# Wire up controller callbacks
	_setup_controller_callbacks(options_controller)
	
	# Connect UI signals
	_connect_ui_elements(options_controller)


## Gets UI node references from the scene tree
func _setup_ui_nodes() -> void:
	if has_node(master_volume_slider_path):
		master_volume_slider = get_node(master_volume_slider_path)
	
	if has_node(music_volume_slider_path):
		music_volume_slider = get_node(music_volume_slider_path)
	
	if has_node(sfx_volume_slider_path):
		sfx_volume_slider = get_node(sfx_volume_slider_path)
	
	if has_node(fullscreen_checkbox_path):
		fullscreen_checkbox = get_node(fullscreen_checkbox_path)
	
	if has_node(resolution_label_path):
		resolution_label = get_node(resolution_label_path)
	
	if has_node(resolution_prev_button_path):
		resolution_prev_button = get_node(resolution_prev_button_path)
	
	if has_node(resolution_next_button_path):
		resolution_next_button = get_node(resolution_next_button_path)
	
	if has_node(vsync_checkbox_path):
		vsync_checkbox = get_node(vsync_checkbox_path)
	
	if has_node(back_button_path):
		back_button = get_node(back_button_path)


## Sets up controller callbacks
func _setup_controller_callbacks(options_controller: OptionsScreenController) -> void:
	# Back callback - returns to previous screen
	options_controller.on_back = func():
		if controller.screen_manager:
			controller.screen_manager.pop_screen("fade")


## Connects UI element signals to controller methods
func _connect_ui_elements(options_controller: OptionsScreenController) -> void:
	# Volume sliders
	if master_volume_slider:
		master_volume_slider.value_changed.connect(options_controller.set_master_volume)
	
	if music_volume_slider:
		music_volume_slider.value_changed.connect(options_controller.set_music_volume)
	
	if sfx_volume_slider:
		sfx_volume_slider.value_changed.connect(options_controller.set_sfx_volume)
	
	# Fullscreen checkbox
	if fullscreen_checkbox:
		fullscreen_checkbox.toggled.connect(options_controller.set_fullscreen)
	
	# Resolution buttons
	if resolution_prev_button:
		resolution_prev_button.pressed.connect(options_controller.cycle_resolution_previous)
	
	if resolution_next_button:
		resolution_next_button.pressed.connect(options_controller.cycle_resolution_next)
	
	# VSync checkbox
	if vsync_checkbox:
		vsync_checkbox.toggled.connect(func(enabled): options_controller.toggle_vsync())
	
	# Back button
	if back_button:
		back_button.pressed.connect(options_controller.back)


## Finds ScreenManager in parent tree and sets it on controller
func _find_and_set_screen_manager() -> void:
	var current = get_parent()
	while current:
		if current is ScreenManager:
			if controller:
				controller.set_screen_manager(current)
			return
		current = current.get_parent()


## Called when the model changes
func _on_model_changed(state: Dictionary) -> void:
	# Update sliders (prevent triggering change signals)
	if master_volume_slider:
		master_volume_slider.set_value_no_signal(state.get("master_volume", 1.0))
	
	if music_volume_slider:
		music_volume_slider.set_value_no_signal(state.get("music_volume", 1.0))
	
	if sfx_volume_slider:
		sfx_volume_slider.set_value_no_signal(state.get("sfx_volume", 1.0))
	
	# Update checkboxes
	if fullscreen_checkbox:
		fullscreen_checkbox.set_pressed_no_signal(state.get("is_fullscreen", false))
	
	if vsync_checkbox:
		vsync_checkbox.set_pressed_no_signal(state.get("vsync_enabled", true))
	
	# Update resolution label
	if resolution_label:
		var res = state.get("resolution", Vector2i(1920, 1080))
		resolution_label.text = "%dx%d" % [res.x, res.y]

