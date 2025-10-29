## ScreenController - Base controller for all screen controllers
## Provides common functionality and holds reference to screen model
class_name ScreenController
extends RefCounted

## Reference to the screen model
var model: ScreenModel = null

## Reference to the screen manager (for navigation)
var screen_manager = null  # ScreenManager


func _init(p_model: ScreenModel = null) -> void:
	model = p_model


## Sets the screen manager reference
func set_screen_manager(p_screen_manager) -> void:
	screen_manager = p_screen_manager


## Activates the screen (called when screen becomes active)
func activate() -> void:
	if model:
		model.activate()


## Deactivates the screen (called when screen becomes inactive)
func deactivate() -> void:
	if model:
		model.deactivate()


## Called when the screen is entered (navigation)
func on_enter() -> void:
	activate()


## Called when the screen is exited (navigation)
func on_exit() -> void:
	deactivate()

