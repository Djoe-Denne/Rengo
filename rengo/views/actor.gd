## Actor class - Pure VIEW for character display
## Actors observe Character models and display visuals via ActorDirectors
## Extends DisplayableNode for multi-layer rendering and collision
## DO NOT use Actor directly - use ActorController for public API
class_name Actor extends DisplayableNode

## The character name this actor represents
var actor_name: String = ""

## Reference to the Character model (data/state holder)
var character: Character = null

## Reference to the director managing this actor
var director = null  # ActorDirector

## Shader manager for handling state-based shader effects
var shader_manager: ShaderManager = null


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
	
	# Update shaders when states change
	if "current_states" in state_dict and shader_manager:
		shader_manager.update_shaders(character.current_states, layers)


## Creates the scene node for this actor
func create_scene_node(parent: Node) -> Node:
	# Initialize sprite_container if not already created
	if not sprite_container:
		sprite_container = Node3D.new()
		sprite_container.name = "Actor_" + actor_name
	
	# Instruct director to set up initial layers
	if director and character:
		director.instruct(self, character.current_states)
	
	# Call parent's create_scene_node to handle collision setup
	return super.create_scene_node(parent)


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
