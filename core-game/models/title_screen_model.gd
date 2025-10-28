## TitleScreenModel - Model for title screen state
## Extends ScreenModel with title screen specific properties
class_name TitleScreenModel
extends ScreenModel

## Whether a saved game exists and "Continue" option should be available
var has_save_game: bool = false

## Selected menu option index
var selected_option: int = 0

## Available menu options
var menu_options: Array[String] = ["New Game", "Continue", "Options", "Quit"]


func _init() -> void:
	super._init("title")


## Sets the selected menu option and notifies observers
func set_selected_option(index: int) -> void:
	if index >= 0 and index < menu_options.size() and selected_option != index:
		selected_option = index
		_notify_observers()


## Sets whether a save game exists and notifies observers
func set_has_save_game(has_save: bool) -> void:
	if has_save_game != has_save:
		has_save_game = has_save
		_notify_observers()


## Override to include title screen specific state
func _get_state() -> Dictionary:
	var state = super._get_state()
	state["has_save_game"] = has_save_game
	state["selected_option"] = selected_option
	state["menu_options"] = menu_options
	return state

