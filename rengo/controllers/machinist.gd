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

const SHADER_CONFIG_PATH = "res://assets/shaders/"
const LOG_PREFIX := "[Machinist]"


## Loads shader configuration from base directories
## @param base_dirs: Array of base directories to search for shaders.yaml
func load_config(path: String) -> void:
	var sanitized_path = SHADER_CONFIG_PATH + path 
	shader_config = ShaderRepository.load_shader_config([sanitized_path])

func handle_displayable(displayable: Displayable) -> void:
	if not displayable:
		return
	
	if displayable.get_parent() and displayable.get_parent() is DisplayableLayer:
		var layer = displayable.get_parent()
		var active_shaders = get_active_shaders_on_layers(layer)
		update_displayable_shaders(displayable, active_shaders)
	else:
		var active_shaders = get_active_shaders_on_node()
		update_displayable_shaders(displayable, active_shaders)

## Updates shaders based on current states
func get_active_shaders_on_node() -> Array[VNShader]:
	if shader_config.is_empty() or not controller:
		return []
	
	var model = controller.get_model()
	if not model:
		return []
	
	# Track which shader keys are currently active
	var active_shaders: Array[VNShader] = []
	
	# 1. Scan current_states for matching shader configs
	for state_key in model.current_states:
		var state_value = model.current_states[state_key]
		# Convert state value to string for matching
		var state_value_str = str(state_value)
		if state_value_str in shader_config:
			var shader_list = shader_config[state_value_str]
			if shader_list is Array:
				for vn_shader in shader_list:
					active_shaders.append(vn_shader.duplicate())
	
	return active_shaders


## Updates shaders based on current states
## @param model: DisplayableModel with current states and annotations
func get_active_shaders_on_layers(layer: DisplayableLayer) -> Array[VNShader]:
	if shader_config.is_empty() or not controller or not layer:
		return []
	
	var model = controller.get_model()
	if not model:
		return []
	
	# Track which shader keys are currently active
	var active_shaders: Array[VNShader] = []

	# 3. Scan annotations for layer-specific states
	for annotation_name in model.annotations:
		if annotation_name != "layer_" + layer.layer_name:
			continue
		
		var annotation = model.annotations[annotation_name]
		var notes = annotation.get_notes()
		for note in notes:
			if note in shader_config:
				var shader_list = shader_config[note]
				if shader_list is Array:
					for vn_shader in shader_list:
						active_shaders.append(vn_shader.duplicate())

	return active_shaders

## Updates shaders for a specific displayable using viewport passes
func update_displayable_shaders(displayable: Displayable, active_shaders: Array[VNShader]) -> void:
	if not displayable:
		push_warning("Skipping shader update: displayable is null")
		return
	
	# Sort VNShader objects by order
	var sorted_shaders = active_shaders.duplicate()
	sorted_shaders.sort_custom(func(a: VNShader, b: VNShader): return a.get_order() < b.get_order())
	
	var builder = displayable.to_builder()
	if not builder:
		push_warning("Displayable '%s' has no builder; skipping shader update" % displayable.name)
		return
	
	# Don't clear shaders - builder will handle incremental updates
	builder.clear_shaders()  # Clear the builder's list, not the displayable's passes
	
	var base_texture = _get_base_texture(displayable)

	# Add all VNShader objects in order
	# The builder will reuse existing passes when possible
	for vn_shader in sorted_shaders:
		# Load shader material (cached by ShaderRepository)
		var shader_material = ShaderRepository.load_shader_material(vn_shader, controller.get_model(), displayable.name)
		vn_shader.set_shader_material(shader_material)
		
		# Only set BASE_TEXTURE parameter if the shader supports it
		if base_texture and _shader_supports_base_texture(vn_shader):
			shader_material.set_shader_parameter("BASE_TEXTURE", base_texture)
		
		builder.add_shader_pass(vn_shader)


func _get_base_texture(displayable: Displayable) -> Texture2D:
	if not displayable:
		push_warning("Cannot resolve base texture: displayable is null")
		return null
	var input_pass = displayable.get_input_pass()
	if not input_pass:
		push_warning("Displayable '%s' has no input pass" % displayable.name)
		return null

	var output_texture = input_pass.get_output_texture()
	if output_texture and output_texture is VNTexture:
		var viewport_texture = output_texture.get_texture()
		if viewport_texture:
			return viewport_texture

	return null


func _shader_supports_base_texture(vn_shader: VNShader) -> bool:
	if vn_shader and vn_shader.get_params().has("BASE_TEXTURE"):
		return true
	if not vn_shader.get_shader_material() or not vn_shader.get_shader_material().shader:
		return false
	var param_list = vn_shader.get_shader_material().shader.get_shader_uniform_list()
	for param_dict in param_list:
		if typeof(param_dict) == TYPE_DICTIONARY and param_dict.has("name"):
			if str(param_dict["name"]) == "BASE_TEXTURE":
				return true
	return false
