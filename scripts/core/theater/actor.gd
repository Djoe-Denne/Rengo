## Actor class - represents a character in the scene (VIEW layer)
## Actors observe Character models and display visuals via ActorDirectors
class_name Actor extends ResourceNode

## The character name this actor represents
var actor_name: String = ""

## Reference to the Character model (data/state holder)
var character: Character = null

## The container node that holds all sprite layers
var sprite_container: Node2D = null

## Dictionary of sprite layers { layer_name: Sprite2D }
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
	
	# Register as observer
	character.add_observer(_on_character_state_changed)
	
	# Initial visual update
	if director:
		director.instruct(self, character.current_states)


## Called when the observed Character's state changes
func _on_character_state_changed(state_dict: Dictionary) -> void:
	if director:
		director.instruct(self, state_dict)


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
func act(new_states: Dictionary):
	var ActAction = load("res://scripts/core/action/character/act_action.gd")
	return ActAction.new(self, new_states)


## Convenience method: Changes expression
func express(emotion: String):
	var ExpressAction = load("res://scripts/core/action/character/express_action.gd")
	return ExpressAction.new(self, emotion)


## Convenience method: Changes pose
func pose(pose_name: String):
	var PoseAction = load("res://scripts/core/action/character/pose_action.gd")
	return PoseAction.new(self, pose_name)


## Convenience method: Changes orientation
func look(orientation: String):
	var LookAction = load("res://scripts/core/action/character/look_action.gd")
	return LookAction.new(self, orientation)


## Convenience method: Changes outfit
func wear(clothing_id: String):
	var WearAction = load("res://scripts/core/action/character/wear_action.gd")
	return WearAction.new(self, clothing_id)


## Makes the actor speak (placeholder for dialog system)
func say(text: String):
	var SayAction = load("res://scripts/core/action/character/say_action.gd")
	return SayAction.new(self).with_text(text)


## Moves the actor to a new position
func move_to(x: float, y: float, duration: float = 0.0):
	# TODO: Implement move action
	push_warning("Actor.move_to not yet implemented")
	return null


## Updates the visibility of the actor
func update_visibility() -> void:
	if sprite_container:
		sprite_container.visible = visible
