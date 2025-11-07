## PostProcessorBuilder - Manages viewport passes for a Displayable
## Provides fluent API for setting base textures, sizes, and adding shader passes
## Works incrementally - only updates what changes
class_name PostProcessorBuilder
extends RefCounted

## Reference to the Displayable we're building
var displayable: Displayable = null

## Base texture to set on first pass (null means don't change)
var base_texture: Texture2D = null
var _update_texture: bool = false

## Viewport size (will be padded by 25%, null means don't change)
var viewport_size: Vector2i = Vector2i(0, 0)
var _update_size: bool = false

## Shader materials to ensure exist (in order)
var vn_shaders: Array[VNShader] = []

## Whether to clear all shader passes before building
var _clear_shaders: bool = false


func _init(p_displayable: Displayable) -> void:
	displayable = p_displayable
	base_texture = p_displayable.get_input_sprite().texture


## Static factory method
static func take(p_displayable: Displayable) -> PostProcessorBuilder:
	return PostProcessorBuilder.new(p_displayable)


## Sets the base texture on the first pass sprite
func set_base_texture(texture: Texture2D) -> PostProcessorBuilder:
	base_texture = texture
	_update_texture = true
	return self


## Sets the viewport size (will add 25% padding)
func set_size(size: Vector2i) -> PostProcessorBuilder:
	viewport_size = size
	_update_size = true
	return self


## Adds a shader material to the list (will be applied in order)
func add_shader_pass(vn_shader: VNShader) -> PostProcessorBuilder:
	vn_shaders.append(vn_shader)
	return self


## Clears all shader passes before applying new ones
func clear_shaders() -> PostProcessorBuilder:
	_clear_shaders = true
	return self


## Applies all changes to the Displayable incrementally
func build() -> Displayable:
	if not displayable:
		push_error("PostProcessorBuilder: No displayable set")
		return null
	
	# 1. Update base texture if requested
	if _update_texture and base_texture:
		displayable.set_input_sprite_texture(base_texture)
	
	var base_size = viewport_size if _update_size else (base_texture.get_size() if base_texture else Vector2i(0, 0))
	# 2. Update viewport size if requested
	displayable.set_max_padding(_find_max_padding_from_vn_shaders())
	
	# 3. Clear shader passes if requested
	if _clear_shaders:
		displayable.clear_shader_passes()
	
	# 4. Update shader passes incrementally
	_update_shader_passes()
	
	return displayable


func _find_max_padding_from_vn_shaders() -> float:
	var max_padding = displayable.get_max_padding()
	for vn_shader in vn_shaders:
		max_padding = max(max_padding, vn_shader.get_padding())
	return max_padding

## Updates shader passes incrementally - only adds/removes what changed
func _update_shader_passes() -> void:
	if vn_shaders.is_empty():
		return
	
	# Count existing shader passes (excluding first pass which is the base)
	var existing_count = displayable.get_pass_count()
	var needed_count = vn_shaders.size()
	
	# Get the first pass (base texture pass)
	var current_pass = displayable.get_input_pass()
	
	# Update existing passes or add new ones
	for i in range(vn_shaders.size()):
		# Skip the base pass. usefull for multi sprite displayables like @displayable_node
		if i < existing_count:
			# Update existing pass material
			current_pass = current_pass.get_next()
			if current_pass and current_pass.get_sprites().size() > 0:
				current_pass.get_sprite(0).material = vn_shaders[i].get_shader_material()
		else:
			# Add new pass
			current_pass = displayable.add_pass(vn_shaders[i].get_shader_material())
	
	# Remove excess passes
	if existing_count > needed_count:
		# Find the last pass we want to keep
		current_pass = displayable.get_input_pass()
		for i in range(needed_count):
			current_pass = current_pass.get_next()
		
		# Remove all passes after this one
		while current_pass and current_pass.get_next():
			var to_remove = current_pass.get_next()
			displayable.remove_pass(to_remove)
