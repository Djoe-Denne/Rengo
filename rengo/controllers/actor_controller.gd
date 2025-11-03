## ActorController - Controller for actor entities
## Provides the public API for controlling an actor (character + view)
## Follows MVC: holds Model (Character) and View (Actor), provides Commands
class_name ActorController
extends Controller

## The Scene model (pure data)
var scene: Scene = null

## The Character model (pure data)
var model: Character = null

## The Actor view (pure display)
var view: Actor = null

## Actor name (for convenience)
var name: String = ""

## Director that handles visual updates for this displayable
var director: Director = null

## Machinist that handles shader effects for this displayable
var machinist: Machinist = null ## TODO: Implement this

func _init(p_name: String, p_model: Character, p_view: Actor, p_director: Director, p_machinist: Machinist, p_scene: Scene) -> void:
	scene = p_scene
	name = p_name
	model = p_model
	view = p_view
	model.set_controller(self)
	view.set_controller(self)
	director = p_director
	director.set_controller(self)
	machinist = p_machinist
	machinist.set_controller(self)

func plug_signals() -> void:
	model.position_changed.connect(view.on_model_position_changed)
	model.visible_changed.connect(view.on_model_visibility_changed)
	model.rotation_changed.connect(view.on_model_rotation_changed)
	model.scale_changed.connect(view.on_model_scale_changed)
	model.state_changed.connect(director.instruct)
	model.state_changed.connect(machinist.update_shaders)
	model.outfit_changed.connect(director.instruct)
	scene.plan_changed.connect(director.on_scene_changed)


func get_model() -> Character:
	return model

func get_view() -> Actor:
	return view

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
## INTERACTION API - Used for input handling
## ============================================================================

## Registers an interaction definition to this actor
## The interaction is stored but not activated until interact() is called
func interaction(interaction_def) -> ActorController:  # InteractionDefinition
	if not interaction_def:
		push_error("ActorController.interaction: interaction_def is null")
		return self
	
	# Register to view (for collision detection)
	if view:
		view.register_interaction(interaction_def)
	
	# Register to InteractionHandler
	InteractionHandler.register_interaction(self, interaction_def)
	
	return self


## Creates and auto-registers an InteractAction to activate an interaction
## Returns the ActionNode for optional chaining
func interact(interaction_name: String):
	var InteractAction = load("res://rengo/controllers/actions/input/interact_action.gd")
	var action = InteractAction.new(self, interaction_name)
	return register_action(action)


## Creates and auto-registers a StopInteractAction to deactivate an interaction
## Returns the ActionNode for optional chaining
func stop_interact(interaction_name: String):
	var StopInteractAction = load("res://rengo/controllers/actions/input/stop_interact_action.gd")
	var action = StopInteractAction.new(self, interaction_name)
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
		var current_states = model.get_states()
		for key in states:
			current_states[key] = states[key]
		model.update_states(current_states)


## Applies a pure view effect (no model changes)
## The callback receives the view as context
func apply_view_effect(effect_callback: Callable) -> void:
	if view and effect_callback.is_valid():
		effect_callback.call(view)
