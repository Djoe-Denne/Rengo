## PostProcessorBuilder - Manages viewport passes for a Displayable
## Provides fluent API for setting base textures, sizes, and adding shader passes
## Works incrementally - only updates what changes
class_name PostProcessorBuilder
extends RefCounted

## Reference to the Displayable we're building
var displayable: Displayable = null

## Base texture to set on first pass (null means don't change)
var base_textures: Array[VNTexture] = []

## Shader materials to ensure exist (in order)
var vn_shaders: Array[VNShader] = []

var is_padding_included: bool = true

## Whether to clear all shader passes before building

func _init(p_displayable: Displayable) -> void:
	displayable = p_displayable
	base_textures = p_displayable.get_input_pass().get_textures().duplicate()
	var current_pass = p_displayable.get_input_pass()
	while current_pass:
		if current_pass.get_shader():
			vn_shaders.append(current_pass.get_shader())
		current_pass = current_pass.get_next()


## Static factory method
static func take(p_displayable: Displayable) -> PostProcessorBuilder:
	return PostProcessorBuilder.new(p_displayable)


## Adds a base texture to the list
func add_base_texture(texture: VNTexture) -> PostProcessorBuilder:
	base_textures.append(texture)
	return self

## Clears all base textures
func clear_base_textures() -> PostProcessorBuilder:
	base_textures.clear()
	return self

## Adds a shader material to the list (will be applied in order)
func add_shader_pass(vn_shader: VNShader) -> PostProcessorBuilder:
	vn_shaders.append(vn_shader)
	return self


## Clears all shader passes before applying new ones
func clear_shaders() -> PostProcessorBuilder:
	vn_shaders.clear()
	return self


func dont_include_padding() -> PostProcessorBuilder:
	is_padding_included = false
	return self

## Applies all changes to the Displayable incrementally
func build() -> Displayable:
	if not displayable:
		push_error("PostProcessorBuilder: No displayable set")
		return null
	if vn_shaders.is_empty() and base_textures.is_empty():
		return displayable

	# Don't clear - we'll update incrementally
	var input_pass = displayable.get_input_pass()

	var max_padding = _find_max_padding_from_vn_shaders()

	input_pass.set_padding_multiplier(max_padding)
	# 1. Update base texture if requested
	if not base_textures.is_empty():
		# Clear existing textures in input pass
		for texture in input_pass.get_textures():
			input_pass.remove_texture(texture.get_layer_id())
		# Add new textures
		for base_texture in base_textures:
			input_pass.add_texture(base_texture)

	# 2. Update shader passes incrementally
	_build_passes()

	return displayable


func _find_max_padding_from_vn_shaders() -> float:
	if not is_padding_included:
		return 1.0
	var max_padding = 0.0
	for vn_shader in vn_shaders:
		max_padding = max(max_padding, vn_shader.get_padding())
	return 1.0 + max_padding / 100.0

## Creates a unique signature for a shader based on path and params
func _get_shader_signature(shader: VNShader) -> String:
	var sig = shader.get_shader_path()
	var params = shader.get_params()
	var keys = params.keys()
	keys.sort()
	for key in keys:
		sig += "|" + str(key) + "=" + str(params[key])
	return sig

## Compares shader parameters to detect changes
func _compare_shader_params(p_pass: Pass, shader: VNShader) -> bool:
	var pass_shader = p_pass.get_shader()
	if not pass_shader:
		return false
	
	var pass_params = pass_shader.get_params()
	var shader_params = shader.get_params()
	
	if pass_params.size() != shader_params.size():
		return false
	
	for key in pass_params:
		if not key in shader_params:
			return false
		if pass_params[key] != shader_params[key]:
			return false
	
	return true

## Updates shader passes incrementally - only adds/removes what changed
func _build_passes() -> void:
	# Build map of current passes by shader signature
	var current_passes_map = {}
	var current_pass = displayable.get_input_pass().get_next()
	while current_pass and current_pass != displayable.get_output_pass():
		var pass_shader = current_pass.get_shader()
		if pass_shader:
			var sig = _get_shader_signature(pass_shader)
			current_passes_map[sig] = current_pass
		current_pass = current_pass.get_next()
	
	# Build map of desired shaders
	var desired_shaders_map = {}
	var desired_order: Array[String] = []
	for shader in vn_shaders:
		var sig = _get_shader_signature(shader)
		desired_shaders_map[sig] = shader
		desired_order.append(sig)
	
	# Find passes to keep, update, and create
	var passes_to_use: Array[Pass] = []
	
	for sig in desired_order:
		var shader = desired_shaders_map[sig]
		
		if sig in current_passes_map:
			# Pass exists - reuse it
			var existing_pass = current_passes_map[sig]
			
			# Check if parameters changed
			if not _compare_shader_params(existing_pass, shader):
				# Parameters changed - update shader material
				existing_pass.set_shader(shader)
			
			passes_to_use.append(existing_pass)
			current_passes_map.erase(sig)  # Mark as used
		else:
			# Pass doesn't exist - get from pool or create new
			var new_pass = displayable._get_or_create_pass(shader)
			new_pass.set_shader(shader)
			passes_to_use.append(new_pass)
	
	# Deactivate and pool passes that are no longer needed
	for sig in current_passes_map:
		var unused_pass = current_passes_map[sig]
		unused_pass.set_active(false)
		if not unused_pass in displayable._pass_pool:
			displayable._pass_pool.append(unused_pass)
	
	# Rebuild the linked list with active passes
	var previous = displayable.get_input_pass()
	var pass_count = 0
	
	for pass_to_use in passes_to_use:
		pass_to_use.name = "pass_" + str(pass_count)
		pass_count += 1
		pass_to_use.set_previous(previous)
		displayable._add_active_pass(pass_to_use)
		previous = pass_to_use
	
	# Update the output pass
	var output_pass = displayable.get_output_pass()
	output_pass.name = "output_pass"
	output_pass.set_previous(previous)
