## TitleScreenView - Complete view implementation for title screen
## Extends BaseScreenView and handles all title screen logic
## Game developers only need to create .tscn with UI layout
class_name TitleScreenView
extends BaseScreenView

## Exported node paths for UI elements (set in editor)
@export var start_button_path: NodePath = ^"VBoxContainer/StartButton"
@export var continue_button_path: NodePath = ^"VBoxContainer/ContinueButton"
@export var options_button_path: NodePath = ^"VBoxContainer/OptionsButton"
@export var quit_button_path: NodePath = ^"VBoxContainer/QuitButton"

## UI element references
var start_button: Button
var continue_button: Button
var options_button: Button
var quit_button: Button

## Callback for starting new game (set by main.gd or game-specific code)
var on_start_game: Callable = func(): pass


func _ready() -> void:
	# Create model and controller
	var title_model = TitleScreenModel.new()
	var title_controller = TitleScreenController.new(title_model)
	
	# Get UI nodes FIRST (before setup, so initial model state can update them)
	_setup_ui_nodes()
	
	# Setup with BaseScreenView (triggers initial _on_model_changed with model's loaded values)
	setup(title_model, title_controller)
	
	# Find and set screen_manager reference on controller
	_find_and_set_screen_manager()
	
	# Wire up controller callbacks
	_setup_controller_callbacks(title_controller)
	
	# Wire up button signals
	_connect_buttons(title_controller)


## Gets UI node references from the scene tree
func _setup_ui_nodes() -> void:
	if has_node(start_button_path):
		start_button = get_node(start_button_path)
	
	if has_node(continue_button_path):
		continue_button = get_node(continue_button_path)
	
	if has_node(options_button_path):
		options_button = get_node(options_button_path)
	
	if has_node(quit_button_path):
		quit_button = get_node(quit_button_path)


## Sets up controller callbacks
func _setup_controller_callbacks(title_controller: TitleScreenController) -> void:
	# New game callback - delegates to configurable callback
	title_controller.on_new_game = func():
		if on_start_game.is_valid():
			on_start_game.call()
	
	# Continue callback - loads most recent save
	title_controller.on_continue = func():
		var SaveSystem = load("res://core-game/domain/save_system.gd")
		var slot = SaveSystem.get_most_recent_save_slot()
		if slot >= 0:
			_on_continue_from_slot(slot)
	
	# Options callback - opens options screen via screen manager
	title_controller.on_options = func():
		if controller.screen_manager:
			controller.screen_manager.push_screen("options", "fade")
	
	# Quit callback - quits the game
	title_controller.on_quit = func():
		get_tree().quit()


## Connects button signals to controller methods
func _connect_buttons(title_controller: TitleScreenController) -> void:
	if start_button:
		start_button.pressed.connect(title_controller.start_new_game)
	
	if continue_button:
		continue_button.pressed.connect(title_controller.continue_game)
	
	if options_button:
		options_button.pressed.connect(title_controller.open_options)
	
	if quit_button:
		quit_button.pressed.connect(title_controller.quit_game)


## Called when the model changes
func _on_model_changed(state: Dictionary) -> void:
	# Update continue button based on save game availability
	if continue_button:
		var has_save = state.get("has_save_game", false)
		continue_button.disabled = not has_save
	
	# Update visual feedback for selected option (for keyboard navigation)
	var selected = state.get("selected_option", 0)
	_update_selection_visual(selected)


## Updates visual feedback for the selected menu option
func _update_selection_visual(selected_index: int) -> void:
	var buttons = [start_button, continue_button, options_button, quit_button]
	
	for i in range(buttons.size()):
		if buttons[i] and i == selected_index:
			buttons[i].grab_focus()


## Virtual method - override in game-specific code to handle continue
func _on_continue_from_slot(slot: int) -> void:
	# Default: just load the save data
	# Game developers should override this or set a callback
	print("Loading from slot ", slot)


## Finds ScreenManager in parent tree and sets it on controller
func _find_and_set_screen_manager() -> void:
	var current = get_parent()
	while current:
		if current is ScreenManager:
			if controller:
				controller.set_screen_manager(current)
			return
		current = current.get_parent()


## Handles keyboard navigation
func _input(event: InputEvent) -> void:
	if not model or not model.is_active:
		return
	
	var title_controller = controller as TitleScreenController
	if not title_controller:
		return
	
	if event.is_action_pressed("ui_up"):
		title_controller.select_previous()
		accept_event()
	elif event.is_action_pressed("ui_down"):
		title_controller.select_next()
		accept_event()
	elif event.is_action_pressed("ui_accept"):
		title_controller.execute_selected_option()
		accept_event()

