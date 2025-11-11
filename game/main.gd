extends Node

## Main entry point for the game
## Sets up ScreenManager and registers all screens

var screen_manager: ScreenManager


func _ready() -> void:
	# Create and add screen manager
	screen_manager = ScreenManager.new()
	add_child(screen_manager)
	
	# Register all available screens
	_register_screens()
	
	# Setup screen-specific configurations
	_configure_screens()
	
	# Start with title screen
	screen_manager.transition("title", "instant")


## Registers all screens with the screen manager
func _register_screens() -> void:
	# Title screen
	screen_manager.register_screen("title", "res://game/ui/title_screen.tscn")
	
	# Options screen
	screen_manager.register_screen("options", "res://game/ui/options_screen.tscn")
	
	# Save/Load screens
	screen_manager.register_screen("save", "res://game/ui/save_screen.tscn")
	screen_manager.register_screen("load", "res://game/ui/load_screen.tscn")


## Configures screens after they're loaded
func _configure_screens() -> void:
	# Listen for screen transitions to configure them
	screen_manager.screen_transition_completed.connect(_on_screen_loaded)


## Called when a screen finishes loading
func _on_screen_loaded(screen_name: String) -> void:
	match screen_name:
		"title":
			_configure_title_screen()
		"options":
			_configure_options_screen()
		"save", "load":
			_configure_save_load_screen()


## Configures the title screen
func _configure_title_screen() -> void:
	var title_view = screen_manager.current_screen as TitleScreenView
	if not title_view:
		return
	
	# Set callback for starting new game
	title_view.on_start_game = func():
		# Transition to demo/game scene
		get_tree().change_scene_to_file("res://game/demo.tscn")


## Configures the options screen
func _configure_options_screen() -> void:
	var options_view = screen_manager.current_screen as OptionsScreenView
	if not options_view:
		return
	
	# Options screen is fully self-contained
	# Additional configuration can be added here if needed


## Configures the save/load screen
func _configure_save_load_screen() -> void:
	var save_load_view = screen_manager.current_screen as SaveLoadScreenView
	if not save_load_view:
		return
	
	# Set the SaveData class to use (game-specific)
	# save_load_view.save_data_class = GameSaveData
	
	# Set callback for when save/load completes
	save_load_view.on_complete = func():
		# Handle completion (e.g., return to game)
		print("Save/load completed")
