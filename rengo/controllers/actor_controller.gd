## ActorController - Controller for actor entities
## Provides the public API for controlling an actor (character + view)
## Follows MVC: holds Model (Character) and View (Actor), provides Commands
class_name ActorController
extends SceneObject

## The Character model (pure data)
var model: Character = null

## The Actor view (pure display)
var view: Actor = null

## Actor name (for convenience)
var name: String = ""


func _init(p_name: String, p_model: Character, p_view: Actor) -> void:
	name = p_name
	model = p_model
	view = p_view


## Creates and auto-registers a ShowAction to make this actor visible
## Returns the ActionNode for optional chaining
func show():
	var ShowAction = load("res://rengo/controllers/actions/common/show_action.gd")
	var action = ShowAction.new(self)  # Action receives the controller
	return register_action(action)


## Creates and auto-registers a HideAction to make this actor invisible
## Returns the ActionNode for optional chaining
func hide():
	var HideAction = load("res://rengo/controllers/actions/common/hide_action.gd")
	var action = HideAction.new(self)  # Action receives the controller
	return register_action(action)


## Changes the actor's state (pose, expression, etc.)
## Auto-registers the action and returns it for optional chaining
func act(new_states: Dictionary):
	var ActAction = load("res://rengo/controllers/actions/character/act_action.gd")
	var action = ActAction.new(self, new_states)  # Action receives the controller
	return register_action(action)


## Convenience method: Changes expression
## Auto-registers the action and returns it for optional chaining
func express(emotion: String):
	var ExpressAction = load("res://rengo/controllers/actions/character/express_action.gd")
	var action = ExpressAction.new(self, emotion)  # Action receives the controller
	return register_action(action)


## Convenience method: Changes pose
## Auto-registers the action and returns it for optional chaining
func pose(pose_name: String):
	var PoseAction = load("res://rengo/controllers/actions/character/pose_action.gd")
	var action = PoseAction.new(self, pose_name)  # Action receives the controller
	return register_action(action)


## Convenience method: Changes orientation
## Auto-registers the action and returns it for optional chaining
func look(orientation: String):
	var LookAction = load("res://rengo/controllers/actions/character/look_action.gd")
	var action = LookAction.new(self, orientation)  # Action receives the controller
	return register_action(action)


## Convenience method: Changes outfit
## Auto-registers the action and returns it for optional chaining
func wear(clothing_id: String):
	var WearAction = load("res://rengo/controllers/actions/character/wear_action.gd")
	var director = view.director if view else null  # Get director from view
	var action = WearAction.new(self, clothing_id, name, director)  # Action receives the controller
	return register_action(action)


## Makes the actor speak
## Auto-registers the action and returns it for optional chaining
func say(text: String):
	var SayAction = load("res://rengo/controllers/actions/character/say_action.gd")
	var action = SayAction.new(self).with_text(text)  # SayAction needs the controller for speaker info
	return register_action(action)


## Creates a MoveAction for position transformation
## Auto-registers the action and returns it for chaining
func move():
	var MoveAction = load("res://rengo/controllers/actions/transform/move_action.gd")
	var action = MoveAction.new(self)  # Action receives the controller
	return register_action(action)


## Creates a RotateAction for rotation transformation
## Auto-registers the action and returns it for chaining
func rotate():
	var RotateAction = load("res://rengo/controllers/actions/transform/rotate_action.gd")
	var action = RotateAction.new(self)  # Action receives the controller
	return register_action(action)


## Creates a ScaleAction for scale transformation
## Auto-registers the action and returns it for chaining
func scale():
	var ScaleAction = load("res://rengo/controllers/actions/transform/scale_action.gd")
	var action = ScaleAction.new(self)  # Action receives the controller
	return register_action(action)


## ============================================================================
## ANIMATION API - Used by animations to update Model and View
## ============================================================================

## Updates the model's position (triggers observer notifications)
func update_model_position(pos: Vector3) -> void:
	if model:
		model.set_position(pos)


## Updates the model's rotation (triggers observer notifications)
func update_model_rotation(rot: Vector3) -> void:
	if model:
		model.set_rotation(rot)


## Updates the model's scale (triggers observer notifications)
func update_model_scale(scl: Vector3) -> void:
	if model:
		model.set_scale(scl)


## Updates the model's visibility (triggers observer notifications)
func update_model_visible(is_visible: bool) -> void:
	if model:
		model.set_visible(is_visible)


## Updates a single state in the model (triggers observer notifications)
func update_model_state(key: String, value: Variant) -> void:
	if model:
		model.set_state(key, value)


## Updates multiple states in the model (triggers observer notifications)
func update_model_states(states: Dictionary) -> void:
	if model:
		model.update_states(states)


## Applies a pure view effect (no model changes)
## The callback receives the view as context
func apply_view_effect(effect_callback: Callable) -> void:
	if view and effect_callback.is_valid():
		effect_callback.call(view)

