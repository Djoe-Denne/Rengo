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
	if view.displayable:
		_update_displayable_shaders(view.displayable, active_state_keys, model)
	
	# 3. Scan annotations for layer-specific states
	for annotation_name in model.annotations:
		if not annotation_name.begins_with("layer_"):
			continue
		
		var layer_name = annotation_name.substr(6)  # Remove "layer_" prefix
		var annotation = model.annotations[annotation_name]
		var layer = view.get_layer(layer_name)
		
		if not layer:
			continue
		
		# Apply shaders based on annotation notes using viewport passes
		_update_displayable_shaders(layer.displayable, annotation.get_notes(), model)


## Updates shaders for a specific displayable using viewport passes
func _update_displayable_shaders(displayable: Displayable, trigger_words: Array, model: DisplayableModel) -> void:
	if not displayable:
		return
	
	var target_key = str(displayable.get_instance_id())
	
	# Remove old shaders from this target
	if target_key in active_shaders:
		active_shaders.erase(target_key)
	
	# Collect all shader definitions from the annotation notes
	var all_shader_defs = []
	for trigger_word in trigger_words:
		if trigger_word in shader_config:
			var shader_list = shader_config[trigger_word]
			if shader_list is Array:
				all_shader_defs.append_array(shader_list)
	
	# Sort shader definitions by order
	var sorted_defs = all_shader_defs.duplicate()
	sorted_defs.sort_custom(func(a, b): return a.get("order", 0) < b.get("order", 0))
	
	# Build shader passes using PostProcessorBuilder
	var builder = PostProcessorBuilder.take(displayable)
	
	# If no shaders, clear all shader passes
	if sorted_defs.is_empty():
		builder.clear_shaders()
	else:
		# Add all shader materials in order
		for shader_def in sorted_defs:
			var shader_material = ShaderRepository.create_shader_material(shader_def, model)
			if shader_material:
				builder.add_shader_pass(shader_material)
	
	builder.build()
	
	# Store shader definitions for tracking
	active_shaders[target_key] = sorted_defs


## Applies a shader chain to a 3D mesh (MeshInstance3D) - for node-level shaders
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


## Rebuilds the complete shader chain for a 3D mesh - for node-level shaders
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


## Removes shaders for a specific layer
func remove_shaders_for_layer(layer: DisplayableLayer) -> void:
	if not layer:
		return
	
	var target_key = str(layer.get_instance_id())
	
	# Remove the target's shaders
	if target_key in active_shaders:
		active_shaders.erase(target_key)
	
	# Clear shader passes
	if layer.displayable:
		layer.displayable.clear_shader_passes()


## Clears all active shaders
func clear_all_shaders() -> void:
	# Clear internal state
	active_shaders.clear()
