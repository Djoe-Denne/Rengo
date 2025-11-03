## Machinist - Manages shader application for displayable resources
## Named after theatrical machinists who handle lights and stage effects
## Can be composed into any visual resource (Actors, Backgrounds, etc.)
## Handles state-based shader activation/deactivation with Material.next_pass chaining
class_name Machinist
extends RefCounted

## The controller (pure display)
var controller: Controller = null


## Sets the controller reference
func set_controller(p_controller: Controller) -> void:
	controller = p_controller

## Shader configuration loaded from YAML { state_name: [shader_defs] }
var shader_config: Dictionary = {}

## Currently active shaders per target { target_key: [ShaderMaterials]  }
var active_shaders: Dictionary = {}

const SHADER_CONFIG_PATH = "res://assets/shaders/"


## Loads shader configuration from base directories
## @param base_dirs: Array of base directories to search for shaders.yaml
func load_config(path: String) -> void:
	var sanitized_path = SHADER_CONFIG_PATH + path 
	shader_config = ShaderRepository.load_shader_config([sanitized_path])


## Updates shaders based on current states
## @param model: DisplayableModel with current states and annotations
func update_shaders(model: DisplayableModel) -> void:
	if shader_config.is_empty() or not controller:
		return
	
	var view = controller.get_view()
	if not view:
		return
	
	# Track which shader keys are currently active
	var active_state_keys: Array[String] = []
	
	# 1. Scan current_states for matching shader configs
	for state_key in model.current_states:
		var state_value = model.current_states[state_key]
		# Convert state value to string for matching
		var state_value_str = str(state_value)
		if state_value_str in shader_config:
			active_state_keys.append(state_value_str)
	
	# 2. Apply shaders to output_mesh (node-level)
	if view.output_mesh:
		_update_node_shaders(view.output_mesh, active_state_keys, model)
	
	# 3. Scan annotations for layer-specific states
	for annotation_name in model.annotations:
		if not annotation_name.begins_with("layer_"):
			continue
		
		var layer_name = annotation_name.substr(6)  # Remove "layer_" prefix
		var annotation = model.annotations[annotation_name]
		var layer = view.get_layer(layer_name)
		
		if not layer or not layer.mesh_instance:
			continue
		
		# Apply shaders based on annotation notes
		_update_layer_shaders(layer.mesh_instance, annotation.get_notes(), model)


## Updates shaders for the output mesh (node-level)
func _update_node_shaders(mesh: MeshInstance3D, shader_keys: Array, model: DisplayableModel) -> void:
	if not mesh:
		return
	
	var target_key = "output_mesh"
	
	# Remove old shaders from this target
	if target_key in active_shaders:
		active_shaders.erase(target_key)
	
	# Collect all shader definitions from the active keys
	var all_shader_defs = []
	for key in shader_keys:
		if key in shader_config:
			var shader_list = shader_config[key]
			if shader_list is Array:
				all_shader_defs.append_array(shader_list)
	
	# If no shaders to apply, clear the chain
	if all_shader_defs.is_empty():
		_clear_shader_chain(mesh)
		return
	
	# Apply shader chain with all collected shaders
	_apply_shader_chain_3d(target_key, shader_keys, mesh, all_shader_defs, model)


## Updates shaders for a specific layer mesh
func _update_layer_shaders(mesh: MeshInstance3D, notes: Array, model: DisplayableModel) -> void:
	if not mesh:
		return
	
	var target_key = str(mesh.get_instance_id())
	
	# Remove old shaders from this target
	if target_key in active_shaders:
		active_shaders.erase(target_key)
	
	# Collect all shader definitions from the annotation notes
	var all_shader_defs = []
	for note in notes:
		if note in shader_config:
			var shader_list = shader_config[note]
			if shader_list is Array:
				all_shader_defs.append_array(shader_list)
	
	# If no shaders to apply, clear the chain
	if all_shader_defs.is_empty():
		_clear_shader_chain(mesh)
		return
	
	# Apply shader chain with all collected shaders
	_apply_shader_chain_3d(target_key, notes, mesh, all_shader_defs, model)


## Applies a shader chain to a 3D mesh (MeshInstance3D)
func _apply_shader_chain_3d(target_key: String, _state_name: Variant, mesh_instance: MeshInstance3D, shader_defs: Array, model: DisplayableModel) -> void:
	if not mesh_instance or not mesh_instance.material_override:
		return
	
	# Sort shader definitions by order
	var sorted_defs = shader_defs.duplicate()
	sorted_defs.sort_custom(func(a, b): return a.get("order", 0) < b.get("order", 0))
	
	# Create shader materials
	var shader_materials: Array = []
	for shader_def in sorted_defs:
		var shader_material = ShaderRepository.create_shader_material(shader_def, model)
		if shader_material:
			shader_materials.append(shader_material)
	
	if shader_materials.is_empty():
		return
	
	# Store shader materials for this target
	active_shaders[target_key] = shader_materials
	
	# Rebuild the complete next_pass chain for this target
	_rebuild_shader_chain_3d(target_key, mesh_instance)


## Rebuilds the complete shader chain for a 3D mesh
func _rebuild_shader_chain_3d(target_key: String, mesh_instance: MeshInstance3D) -> void:
	if not mesh_instance or not mesh_instance.material_override:
		return
	
	# Get base material (the material with the texture)
	var base_material = mesh_instance.material_override
	
	# Collect all shader materials from active shaders
	var all_shader_materials: Array = []
	
	if target_key in active_shaders:
		all_shader_materials = active_shaders[target_key]
	
	# Clear existing next_pass chain
	base_material.next_pass = null
	
	# Rebuild chain: base_material -> shader1 -> shader2 -> ...
	if all_shader_materials.size() > 0:
		base_material.next_pass = all_shader_materials[0]
		
		for i in range(all_shader_materials.size() - 1):
			all_shader_materials[i].next_pass = all_shader_materials[i + 1]
		
		# Last material has no next_pass
		all_shader_materials[-1].next_pass = null


## Removes shaders for a specific target
func remove_shaders_for_target(target_key: String, mesh: MeshInstance3D) -> void:
	if not target_key in active_shaders:
		return
	
	# Remove the target's shaders
	active_shaders.erase(target_key)
	
	# Clear the shader chain
	_clear_shader_chain(mesh)



## Clears shader chain from a specific mesh
func _clear_shader_chain(mesh: MeshInstance3D) -> void:
	if not mesh or not mesh.material_override:
		return
	
	# Clear the next_pass chain
	mesh.material_override.next_pass = null


## Clears all active shaders from all targets
func clear_all_shaders(target_nodes: Dictionary) -> void:
	# Clear shader chains from all nodes
	for target_key in target_nodes:
		var node = target_nodes[target_key]
		if node is MeshInstance3D and node.material_override:
			node.material_override.next_pass = null
		elif node is Sprite2D:
			node.material = null
	
	# Clear internal state
	active_shaders.clear()
