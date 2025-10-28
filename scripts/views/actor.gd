## Actor class - represents a character in the scene (VIEW layer)
## Actors observe Character models and display visuals via ActorDirectors
class_name Actor extends ResourceNode

## The character name this actor represents
var actor_name: String = ""

## Reference to the Character model (data/state holder)
var character: Character = null

## The container node that holds all mesh layers (3D)
var sprite_container: Node3D = null

## Dictionary of mesh layers { layer_name: MeshInstance3D }
var layers: Dictionary = {}

## Reference to the director managing this actor
var director = null  # ActorDirector


func _init(p_actor_name: String = "", p_director = null) -> void:
	super(p_actor_name)
	actor_name = p_actor_name
	director = p_director


## Observes a Character model for state changes
func observe(p_character: Character) -> void:
	character = p_character
	
	# Register as observer for ALL changes (states + transforms)
	character.add_observer(_on_character_changed)
	
	# Initial visual update
	if director and character.current_states:
		director.instruct(self, character.current_states)
	
	# Initial transform update
	update_position()
	update_visibility()


## Called when the observed Character changes (states or transforms)
func _on_character_changed(state_dict: Dictionary) -> void:
	# Update visual states (pose, expression, etc.)
	if "current_states" in state_dict and director:
		director.instruct(self, state_dict.current_states)
	
	# Update transform properties (position, rotation, scale, visible)
	if "position" in state_dict:
		update_position()
	
	if "visible" in state_dict:
		update_visibility()
	
	if "rotation" in state_dict:
		update_rotation()
	
	if "scale" in state_dict:
		update_scale()


## Creates the scene node for this actor
func create_scene_node(parent: Node) -> Node:
	if director and character:
		director.instruct(self, character.current_states)
	
	if sprite_container:
		parent.add_child(sprite_container)
		scene_node = sprite_container
	
	return sprite_container


## Changes the actor's state (pose, expression, etc.)
## Updates the underlying Character model
## Auto-registers the action and returns it for optional chaining
func act(new_states: Dictionary):
	var ActAction = load("res://scripts/controllers/actions/character/act_action.gd")
	var action = ActAction.new(self, new_states)
	return register_action(action)


## Convenience method: Changes expression
## Auto-registers the action and returns it for optional chaining
func express(emotion: String):
	var ExpressAction = load("res://scripts/controllers/actions/character/express_action.gd")
	var action = ExpressAction.new(self, emotion)
	return register_action(action)


## Convenience method: Changes pose
## Auto-registers the action and returns it for optional chaining
func pose(pose_name: String):
	var PoseAction = load("res://scripts/controllers/actions/character/pose_action.gd")
	var action = PoseAction.new(self, pose_name)
	return register_action(action)


## Convenience method: Changes orientation
## Auto-registers the action and returns it for optional chaining
func look(orientation: String):
	var LookAction = load("res://scripts/controllers/actions/character/look_action.gd")
	var action = LookAction.new(self, orientation)
	return register_action(action)


## Convenience method: Changes outfit
## Auto-registers the action and returns it for optional chaining
func wear(clothing_id: String):
	var WearAction = load("res://scripts/controllers/actions/character/wear_action.gd")
	var action = WearAction.new(self, clothing_id)
	return register_action(action)


## Makes the actor speak (placeholder for dialog system)
## Auto-registers the action and returns it for optional chaining
func say(text: String):
	var SayAction = load("res://scripts/controllers/actions/character/say_action.gd")
	var action = SayAction.new(self).with_text(text)
	return register_action(action)


## Moves the actor to a new position
func move_to(x: float, y: float, duration: float = 0.0):
	# TODO: Implement move action
	push_warning("Actor.move_to not yet implemented")
	return null


## Creates a MoveAction for position transformation
## Auto-registers the action and returns it for chaining
func move():
	var MoveAction = load("res://scripts/controllers/actions/transform/move_action.gd")
	var action = MoveAction.new(self)
	return register_action(action)


## Creates a RotateAction for rotation transformation
## Auto-registers the action and returns it for chaining
func rotate():
	var RotateAction = load("res://scripts/controllers/actions/transform/rotate_action.gd")
	var action = RotateAction.new(self)
	return register_action(action)


## Creates a ScaleAction for scale transformation
## Auto-registers the action and returns it for chaining
func scale():
	var ScaleAction = load("res://scripts/controllers/actions/transform/scale_action.gd")
	var action = ScaleAction.new(self)
	return register_action(action)


## Updates the visibility of the actor from Character model
func update_visibility() -> void:
	if sprite_container and character:
		sprite_container.visible = character.visible


## Updates the position of the actor from Character model
func update_position() -> void:
	if sprite_container and character:
		# Position is in centimeters, apply directly to Node3D
		sprite_container.position = character.position


## Updates the rotation of the actor from Character model
func update_rotation() -> void:
	if sprite_container and character:
		# Rotation in Character is in degrees, convert to radians for Godot
		sprite_container.rotation_degrees = character.rotation


## Updates the scale of the actor from Character model
func update_scale() -> void:
	if sprite_container and character:
		sprite_container.scale = character.scale
