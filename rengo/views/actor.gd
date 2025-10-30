## Actor class - Pure VIEW for character display
## Actors observe Character models and display visuals via ActorDirectors
## DO NOT use Actor directly - use ActorController for public API
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

## Reference to the ActorController (MVC: view knows its controller)
var controller = null  # ActorController

## Shader configuration loaded from YAML { state_name: [shader_defs] }
var shader_config: Dictionary = {}

## Currently active shaders per layer { layer_name: { state_name: [ShaderMaterials] } }
var active_shaders: Dictionary = {}


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
	if "current_states" in state_dict:
		_update_shaders()


## Creates the scene node for this actor
func create_scene_node(parent: Node) -> Node:
	if director and character:
		director.instruct(self, character.current_states)
	
	if sprite_container:
		parent.add_child(sprite_container)
		scene_node = sprite_container
		
		# Create interaction area for input handling
		_create_interaction_area()
	
	return sprite_container


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


## Creates the interaction area for input detection
func _create_interaction_area() -> void:
	if not sprite_container:
		return
	
	var CollisionHelper = load("res://core-game/input/collision_helper.gd")
	interaction_area = CollisionHelper.create_area3d_for_actor(sprite_container)
	
	if interaction_area:
		sprite_container.add_child(interaction_area)
		
		# Connect signals to InteractionHandler
		interaction_area.input_event.connect(_on_input_event)
		interaction_area.mouse_entered.connect(_on_mouse_entered)
		interaction_area.mouse_exited.connect(_on_mouse_exited)


## Signal handlers for Area3D
func _on_input_event(_camera: Node, _event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	# Input events are handled by InteractionHandler via custom actions
	pass


func _on_mouse_entered() -> void:
	# Notify InteractionHandler that this actor is hovered
	if controller:
		InteractionHandler.on_hover_enter(controller)


func _on_mouse_exited() -> void:
	# Notify InteractionHandler that this actor is no longer hovered
	if controller:
		InteractionHandler.on_hover_exit(controller)


## Updates shaders based on current character states
func _update_shaders() -> void:
	if not character or shader_config.is_empty():
		return
	
	# Get current states
	var current_states = character.current_states
	
	# Track which states are currently active that have shader configurations
	var active_state_shaders: Dictionary = {}
	
	# Check each state in current_states to see if it has shader config
	for state_key in current_states:
		var state_value = current_states[state_key]
		
		# Check if this state value has a shader configuration
		if state_value in shader_config:
			active_state_shaders[state_value] = shader_config[state_value]
	
	# Apply shaders for active states
	for state_name in active_state_shaders:
		var shader_defs = active_state_shaders[state_name]
		_apply_shaders_for_state(state_name, shader_defs, current_states)
	
	# Remove shaders for inactive states
	for layer_name in active_shaders.keys():
		var layer_shaders = active_shaders[layer_name]
		for state_name in layer_shaders.keys():
			if not state_name in active_state_shaders:
				_remove_shaders_for_state(layer_name, state_name)


## Applies shaders for a specific state to appropriate layers
func _apply_shaders_for_state(state_name: String, shader_defs: Array, current_states: Dictionary) -> void:
	if shader_defs.is_empty():
		return
	
	# Group shader definitions by layer (or apply to all if no layer specified)
	for shader_def in shader_defs:
		var target_layer = shader_def.get("layer", "")
		
		# If no specific layer, apply to all layers
		if target_layer == "":
			for layer_name in layers.keys():
				_apply_shader_chain(layer_name, state_name, [shader_def], current_states)
		else:
			# Apply to specific layer
			if target_layer in layers:
				_apply_shader_chain(target_layer, state_name, [shader_def], current_states)


## Applies a chain of shaders to a specific layer
## Shaders are chained using Material.next_pass in order
func _apply_shader_chain(layer_name: String, state_name: String, shader_defs: Array, current_states: Dictionary) -> void:
	if not layer_name in layers:
		return
	
	var mesh_instance = layers[layer_name]
	if not mesh_instance is MeshInstance3D:
		return
	
	# Initialize active_shaders structure for this layer
	if not layer_name in active_shaders:
		active_shaders[layer_name] = {}
	
	# Check if shaders for this state are already applied
	if state_name in active_shaders[layer_name]:
		return  # Already applied
	
	# Sort shader definitions by order
	var sorted_defs = shader_defs.duplicate()
	sorted_defs.sort_custom(func(a, b): return a.get("order", 0) < b.get("order", 0))
	
	# Create shader materials
	var shader_materials: Array = []
	for shader_def in sorted_defs:
		var shader_material = ShaderRepository.create_shader_material(shader_def, current_states)
		if shader_material:
			shader_materials.append(shader_material)
	
	if shader_materials.is_empty():
		return
	
	# Store shader materials for this state
	active_shaders[layer_name][state_name] = shader_materials
	
	# Rebuild the complete next_pass chain
	_rebuild_shader_chain(layer_name)


## Rebuilds the complete shader chain for a layer
## Combines all active state shaders in the correct order
func _rebuild_shader_chain(layer_name: String) -> void:
	if not layer_name in layers:
		return
	
	var mesh_instance = layers[layer_name]
	if not mesh_instance is MeshInstance3D or not mesh_instance.material_override:
		return
	
	# Get base material (the material with the texture)
	var base_material = mesh_instance.material_override
	
	# Collect all shader materials from all active states
	var all_shader_materials: Array = []
	
	if layer_name in active_shaders:
		for state_name in active_shaders[layer_name]:
			var state_shaders = active_shaders[layer_name][state_name]
			all_shader_materials.append_array(state_shaders)
	
	# Clear existing next_pass chain
	base_material.next_pass = null
	
	# Rebuild chain: base_material -> shader1 -> shader2 -> ...
	if all_shader_materials.size() > 0:
		base_material.next_pass = all_shader_materials[0]
		
		for i in range(all_shader_materials.size() - 1):
			all_shader_materials[i].next_pass = all_shader_materials[i + 1]
		
		# Last material has no next_pass
		all_shader_materials[-1].next_pass = null


## Removes shaders for a specific state from a layer
func _remove_shaders_for_state(layer_name: String, state_name: String) -> void:
	if not layer_name in active_shaders:
		return
	
	if not state_name in active_shaders[layer_name]:
		return
	
	# Remove the state's shaders
	active_shaders[layer_name].erase(state_name)
	
	# If no more shaders for this layer, clean up
	if active_shaders[layer_name].is_empty():
		active_shaders.erase(layer_name)
	
	# Rebuild the chain without this state's shaders
	_rebuild_shader_chain(layer_name)
