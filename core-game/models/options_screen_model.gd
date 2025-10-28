## OptionsScreenModel - Model for options/settings screen state
## Extends ScreenModel with game settings properties
class_name OptionsScreenModel
extends ScreenModel

## Audio settings (0.0 to 1.0)
var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0

## Display settings
var is_fullscreen: bool = false
var resolution: Vector2i = Vector2i(1920, 1080)
var vsync_enabled: bool = true

## Available resolution options
var available_resolutions: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160)
]

## Selected menu option index (for navigation)
var selected_option: int = 0


func _init() -> void:
	super._init("options")
	_load_settings()


## Sets master volume and notifies observers
func set_master_volume(volume: float) -> void:
	volume = clampf(volume, 0.0, 1.0)
	if master_volume != volume:
		master_volume = volume
		_apply_audio_settings()
		_notify_observers()


## Sets music volume and notifies observers
func set_music_volume(volume: float) -> void:
	volume = clampf(volume, 0.0, 1.0)
	if music_volume != volume:
		music_volume = volume
		_apply_audio_settings()
		_notify_observers()


## Sets SFX volume and notifies observers
func set_sfx_volume(volume: float) -> void:
	volume = clampf(volume, 0.0, 1.0)
	if sfx_volume != volume:
		sfx_volume = volume
		_apply_audio_settings()
		_notify_observers()


## Sets fullscreen mode and notifies observers
func set_fullscreen(fullscreen: bool) -> void:
	if is_fullscreen != fullscreen:
		is_fullscreen = fullscreen
		_apply_display_settings()
		_notify_observers()


## Sets resolution and notifies observers
func set_resolution(new_resolution: Vector2i) -> void:
	if resolution != new_resolution:
		resolution = new_resolution
		_apply_display_settings()
		_notify_observers()


## Sets VSync enabled state and notifies observers
func set_vsync_enabled(enabled: bool) -> void:
	if vsync_enabled != enabled:
		vsync_enabled = enabled
		_apply_display_settings()
		_notify_observers()


## Sets the selected menu option and notifies observers
func set_selected_option(index: int) -> void:
	if selected_option != index:
		selected_option = index
		_notify_observers()


## Saves settings to disk
func save_settings() -> void:
	var config = ConfigFile.new()
	
	# Audio settings
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	
	# Display settings
	config.set_value("display", "fullscreen", is_fullscreen)
	config.set_value("display", "resolution", resolution)
	config.set_value("display", "vsync", vsync_enabled)
	
	config.save("user://settings.cfg")


## Loads settings from disk
func _load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err != OK:
		# Use defaults if file doesn't exist
		return
	
	# Load audio settings
	master_volume = config.get_value("audio", "master_volume", 1.0)
	music_volume = config.get_value("audio", "music_volume", 1.0)
	sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
	
	# Load display settings
	is_fullscreen = config.get_value("display", "fullscreen", false)
	resolution = config.get_value("display", "resolution", Vector2i(1920, 1080))
	vsync_enabled = config.get_value("display", "vsync", true)
	
	# Apply loaded settings
	_apply_audio_settings()
	_apply_display_settings()


## Applies audio settings to the engine
func _apply_audio_settings() -> void:
	# Set audio bus volumes
	var master_bus = AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(master_volume))
	
	var music_bus = AudioServer.get_bus_index("Music")
	if music_bus >= 0:
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(music_volume))
	
	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus >= 0:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx_volume))


## Applies display settings to the engine
func _apply_display_settings() -> void:
	# Set fullscreen mode
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	# Set resolution
	if not is_fullscreen:
		DisplayServer.window_set_size(resolution)
	
	# Set VSync
	if vsync_enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


## Override to include options screen specific state
func _get_state() -> Dictionary:
	var state = super._get_state()
	state["master_volume"] = master_volume
	state["music_volume"] = music_volume
	state["sfx_volume"] = sfx_volume
	state["is_fullscreen"] = is_fullscreen
	state["resolution"] = resolution
	state["vsync_enabled"] = vsync_enabled
	state["available_resolutions"] = available_resolutions
	state["selected_option"] = selected_option
	return state

