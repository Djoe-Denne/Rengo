## OptionsScreenController - Controller for options/settings screen
## Provides public API for managing game settings
class_name OptionsScreenController
extends ScreenController

## Callback when "Back" is selected
var on_back: Callable = func(): pass


func _init(p_model: OptionsScreenModel = null) -> void:
	if p_model == null:
		p_model = OptionsScreenModel.new()
	super._init(p_model)


## Gets the options screen model (typed accessor)
func get_options_model() -> OptionsScreenModel:
	return model as OptionsScreenModel


## Sets master volume (0.0 to 1.0)
func set_master_volume(volume: float) -> void:
	get_options_model().set_master_volume(volume)


## Sets music volume (0.0 to 1.0)
func set_music_volume(volume: float) -> void:
	get_options_model().set_music_volume(volume)


## Sets SFX volume (0.0 to 1.0)
func set_sfx_volume(volume: float) -> void:
	get_options_model().set_sfx_volume(volume)


## Toggles fullscreen mode
func toggle_fullscreen() -> void:
	var options_model = get_options_model()
	options_model.set_fullscreen(not options_model.is_fullscreen)


## Sets fullscreen mode
func set_fullscreen(enabled: bool) -> void:
	get_options_model().set_fullscreen(enabled)


## Sets the resolution
func set_resolution(resolution: Vector2i) -> void:
	get_options_model().set_resolution(resolution)


## Cycles to the next available resolution
func cycle_resolution_next() -> void:
	var options_model = get_options_model()
	var resolutions = options_model.available_resolutions
	var current_res = options_model.resolution
	
	var current_index = resolutions.find(current_res)
	if current_index == -1:
		current_index = 0
	
	var next_index = (current_index + 1) % resolutions.size()
	set_resolution(resolutions[next_index])


## Cycles to the previous available resolution
func cycle_resolution_previous() -> void:
	var options_model = get_options_model()
	var resolutions = options_model.available_resolutions
	var current_res = options_model.resolution
	
	var current_index = resolutions.find(current_res)
	if current_index == -1:
		current_index = 0
	
	var next_index = current_index - 1
	if next_index < 0:
		next_index = resolutions.size() - 1
	
	set_resolution(resolutions[next_index])


## Toggles VSync
func toggle_vsync() -> void:
	var options_model = get_options_model()
	options_model.set_vsync_enabled(not options_model.vsync_enabled)


## Saves settings to disk
func save_settings() -> void:
	get_options_model().save_settings()


## Closes the options screen and returns to previous screen
func back() -> void:
	# Save settings before going back
	save_settings()
	
	if on_back.is_valid():
		on_back.call()
	elif screen_manager:
		screen_manager.pop_screen()


## Selects a menu option by index
func select_option(index: int) -> void:
	get_options_model().set_selected_option(index)


## Moves selection up
func select_previous() -> void:
	var options_model = get_options_model()
	var new_index = options_model.selected_option - 1
	if new_index < 0:
		new_index = 0
	select_option(new_index)


## Moves selection down
func select_next() -> void:
	var options_model = get_options_model()
	var new_index = options_model.selected_option + 1
	select_option(new_index)

