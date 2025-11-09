## PostProcessorBuilder - Manages viewport passes for a Displayable
## Provides fluent API for setting base textures, sizes, and adding shader passes
## Works incrementally - only updates what changes
class_name PostProcessorBuilder
extends RefCounted

## Reference to the Displayable we're building
var displayable: Displayable = null

## Base texture to set on first pass (null means don't change)
var base_textures: Array[TransformableTexture] = []

## Shader materials to ensure exist (in order)
var vn_shaders: Array[VNShader] = []

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
func add_base_texture(texture: TransformableTexture) -> PostProcessorBuilder:
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


## Applies all changes to the Displayable incrementally
func build() -> Displayable:
	if not displayable:
		push_error("PostProcessorBuilder: No displayable set")
		return null
	if vn_shaders.is_empty() and base_textures.is_empty():
		return displayable

	print("PostProcessorBuilder: ======================================")
	print("PostProcessorBuilder: building displayable: ", displayable.name)

	print("PostProcessorBuilder: ======================================")
	displayable.clear()
	var input_pass = displayable.get_input_pass()

	var max_padding = _find_max_padding_from_vn_shaders()

	input_pass.set_padding_multiplier(max_padding)
	# 1. Update base texture if requested
	if not base_textures.is_empty():
		for base_texture in base_textures:
			print("PostProcessorBuilder: adding base texture: ", base_texture.get_texture().get_size())
			input_pass.add_texture(base_texture)

	print("PostProcessorBuilder: -------------------------------------")
	# 4. Update shader passes incrementally
	_build_passes()
	print("PostProcessorBuilder: -------------------------------------")

	print("PostProcessorBuilder: displayable viewport size: ", displayable.get_output_pass().get_output_texture().get_texture().get_size())

	print("PostProcessorBuilder: ======================================")

	return displayable


func _find_max_padding_from_vn_shaders() -> float:
	var max_padding = 0.0
	for vn_shader in vn_shaders:
		max_padding = max(max_padding, vn_shader.get_padding())
	return 1.0 + max_padding / 100.0

## Updates shader passes incrementally - only adds/removes what changed
func _build_passes() -> void:	
	# Get the first pass (base texture pass)
	var current_pass = displayable.get_input_pass()
	var pass_count = 0
	# Update existing passes or add new ones
	for shader in vn_shaders:
		# Add new pass
		var new_pass = Pass.new(displayable, shader)
		new_pass.name = "pass_" + str(pass_count)
		
		print("PostProcessorBuilder: added shader ", new_pass.name,": ", shader.shader_path)
		pass_count += 1
		new_pass.set_previous(current_pass)
		current_pass = new_pass

	
	# Update the output pass
	var output_pass = displayable.get_output_pass()
	output_pass.name = "output_pass"
	output_pass.set_previous(current_pass)
