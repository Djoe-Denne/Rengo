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
var shader_materials: Array[ShaderMaterial] = []

## Whether to clear all shader passes before building
var _clear_shaders: bool = false


func _init(p_displayable: Displayable) -> void:
	displayable = p_displayable


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
func add_shader_pass(material: ShaderMaterial) -> PostProcessorBuilder:
	shader_materials.append(material)
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
		var input_sprite = displayable.get_input_sprite()
		if input_sprite:
			input_sprite.texture = base_texture
	
	# 2. Update viewport size if requested
	if _update_size:
		var padded_size = viewport_size
		if viewport_size.x > 0 and viewport_size.y > 0:
			padded_size = Vector2i(
				int(viewport_size.x * 1.25),
				int(viewport_size.y * 1.25)
			)
		elif _update_texture and base_texture:
			# If no size specified but texture updated, use texture size + padding
			var tex_size = base_texture.get_size()
			padded_size = Vector2i(
				int(tex_size.x * 1.25),
				int(tex_size.y * 1.25)
			)
		
		if padded_size.x > 0 and padded_size.y > 0:
			displayable.set_pass_size(padded_size)
	
	# 3. Clear shader passes if requested
	if _clear_shaders:
		displayable.clear_shader_passes()
	
	# 4. Update shader passes incrementally
	_update_shader_passes()
	
	return displayable


## Updates shader passes incrementally - only adds/removes what changed
func _update_shader_passes() -> void:
	if shader_materials.is_empty():
		return
	
	# Count existing shader passes (excluding first pass which is the base)
	var existing_count = displayable.get_pass_count() - 1
	var needed_count = shader_materials.size()
	
	# Get the first pass (base texture pass)
	var current_pass = displayable.input_pass
	
	# Update existing passes or add new ones
	for i in range(shader_materials.size()):
		if i < existing_count:
			# Update existing pass material
			current_pass = current_pass.next
			if current_pass and current_pass.sprite:
				current_pass.sprite.material = shader_materials[i]
		else:
			# Add new pass
			current_pass = displayable.add_pass(shader_materials[i])
	
	# Remove excess passes
	if existing_count > needed_count:
		# Find the last pass we want to keep
		current_pass = displayable.input_pass
		for i in range(needed_count):
			current_pass = current_pass.next
		
		# Remove all passes after this one
		while current_pass and current_pass.next:
			var to_remove = current_pass.next
			displayable.remove_pass(to_remove)
