## TitleScreenController - Controller for title screen
## Provides public API for title screen actions
class_name TitleScreenController
extends ScreenController

## Callback when "New Game" is selected
var on_new_game: Callable = func(): pass

## Callback when "Continue" is selected
var on_continue: Callable = func(): pass

## Callback when "Options" is selected
var on_options: Callable = func(): pass

## Callback when "Quit" is selected
var on_quit: Callable = func(): pass


func _init(p_model: TitleScreenModel = null) -> void:
	if p_model == null:
		p_model = TitleScreenModel.new()
	super._init(p_model)


## Gets the title screen model (typed accessor)
func get_title_model() -> TitleScreenModel:
	return model as TitleScreenModel


## Called when entering the title screen
func on_enter() -> void:
	super.on_enter()
	
	# Check if any save exists and update model
	var SaveSystem = load("res://core-game/domain/save_system.gd")
	var has_save = SaveSystem.has_any_save()
	get_title_model().set_has_save_game(has_save)


## Starts a new game
func start_new_game() -> void:
	if on_new_game.is_valid():
		on_new_game.call()


## Continues from the most recent save
func continue_game() -> void:
	var title_model = get_title_model()
	
	if not title_model.has_save_game:
		push_warning("TitleScreenController: No save game available to continue")
		return
	
	if on_continue.is_valid():
		on_continue.call()


## Opens the options screen
func open_options() -> void:
	if on_options.is_valid():
		on_options.call()
	elif screen_manager:
		screen_manager.transition("options")


## Quits the game
func quit_game() -> void:
	if on_quit.is_valid():
		on_quit.call()


## Selects a menu option by index
func select_option(index: int) -> void:
	get_title_model().set_selected_option(index)


## Executes the currently selected menu option
func execute_selected_option() -> void:
	var title_model = get_title_model()
	var option = title_model.selected_option
	
	match option:
		0: start_new_game()
		1: continue_game()
		2: open_options()
		3: quit_game()


## Moves selection up
func select_previous() -> void:
	var title_model = get_title_model()
	var new_index = title_model.selected_option - 1
	if new_index < 0:
		new_index = title_model.menu_options.size() - 1
	select_option(new_index)


## Moves selection down
func select_next() -> void:
	var title_model = get_title_model()
	var new_index = (title_model.selected_option + 1) % title_model.menu_options.size()
	select_option(new_index)
