## BaseScreenView - Optional base class for screen views
## Provides common functionality for observing models
## Game developers can extend this or create their own views
class_name BaseScreenView
extends Control

## Reference to the screen model
var model: ScreenModel = null

## Reference to the screen controller
var controller: ScreenController = null


## Sets up the view with a model and controller
func setup(p_model: ScreenModel, p_controller: ScreenController) -> void:
	model = p_model
	controller = p_controller
	
	if model:
		model.add_observer(_on_model_changed)
		# Initial update
		_on_model_changed(model._get_state())


## Called when the model changes
## Override this in subclasses to update the UI
func _on_model_changed(state: Dictionary) -> void:
	# Override in subclasses
	pass


## Called when the view is about to be removed
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if model:
			model.remove_observer(_on_model_changed)

