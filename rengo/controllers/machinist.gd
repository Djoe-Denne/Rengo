## Machinist - Manages shader application for displayable resources
## Named after theatrical machinists who handle lights and stage effects
## Can be composed into any visual resource (Actors, Backgrounds, etc.)
## Handles state-based shader activation/deactivation with Material.next_pass chaining
class_name Machinist
extends RefCounted

var VNShader = preload("res://rengo/infra/vn_shader.gd")

## The controller (pure display)
var controller: Controller = null


## Sets the controller reference
func set_controller(p_controller: Controller) -> void:
	controller = p_controller

## Shader configuration loaded from YAML { state_name: Array[VNShader] }
var shader_config: Dictionary = {}

## Currently active shaders per target { target_key: Array[VNShader] }
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
func _update_displayable_shaders(displayable: Displayable, trigger_words: Array, _model: DisplayableModel) -> void:
	if not displayable:
		return
	
	var target_key = str(displayable.get_instance_id())
	
	# Remove old shaders from this target
	if target_key in active_shaders:
		active_shaders.erase(target_key)
	
	# Collect all VNShader objects from the annotation notes
	var all_vn_shaders: Array[VNShader] = []
	for trigger_word in trigger_words:
		if trigger_word in shader_config:
			var shader_list = shader_config[trigger_word]
			if shader_list is Array:
				for vn_shader in shader_list:
					if vn_shader is VNShader:
						all_vn_shaders.append(vn_shader)
	
	# Sort VNShader objects by order
	var sorted_shaders = all_vn_shaders.duplicate()
	sorted_shaders.sort_custom(func(a: VNShader, b: VNShader): return a.get_order() < b.get_order())
	
	# Build shader passes using PostProcessorBuilder
	var builder = PostProcessorBuilder.take(displayable)
	
	# If no shaders, clear all shader passes
	if sorted_shaders.is_empty():
		builder.clear_shaders()
	else:
		# Add all VNShader objects in order
		for vn_shader in sorted_shaders:
			var shader_material = vn_shader.get_shader_material()
			if not shader_material:
				shader_material = ShaderRepository.create_shader_material(vn_shader, _model)
				vn_shader.set_shader_material(shader_material)
			builder.add_shader_pass(vn_shader)
	
	builder.build()
	
	# Store VNShader objects for tracking
	active_shaders[target_key] = sorted_shaders


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
