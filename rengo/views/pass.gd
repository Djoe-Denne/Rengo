## Pass - Single node in the viewport pass chain (doubly-linked list)
class_name Pass
extends Node

var _shader: VNShader = null
var _viewport: SubViewport
var _textures: Array[VNTexture] = []
var _padding_multiplier: float = 1.0
var _previous: Pass = null
var _next: Pass = null
var _output_texture: VNTexture = null

func _init(displayable: Displayable, p_shader: VNShader = null) -> void:
	_shader = p_shader
	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.disable_3d = true
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	displayable.add_child(self)

func add_texture(p_texture: VNTexture) -> void:
	_textures.append(p_texture)
	_compute_viewport_size()

func get_textures() -> Array[VNTexture]:
	return _textures

func get_texture(p_index: int) -> VNTexture:
	if p_index < 0 or p_index >= _textures.size():
		return null
	return _textures[p_index]

func get_sub_viewport() -> SubViewport:
	return _viewport

func get_previous() -> Pass:
	return _previous

func get_next() -> Pass:
	return _next

func set_previous(p_previous: Pass) -> void:
	_previous = p_previous
	if p_previous and p_previous.get_next() != self:
		p_previous.set_next(self)
	_textures.clear()
	add_texture(p_previous.get_output_texture())

func set_next(p_next: Pass) -> void:
	_next = p_next
	if p_next and p_next.get_previous() != self:
		p_next.set_previous(self)

func get_shader() -> VNShader:
	return _shader

func get_padding_multiplier() -> float:
	return _padding_multiplier

func set_padding_multiplier(p_padding_multiplier: float) -> void:
	if p_padding_multiplier < 1.0:
		p_padding_multiplier = 1.0
	_padding_multiplier = p_padding_multiplier

func get_output_texture() -> VNTexture:
	_output_texture = VNTexture.new(_viewport.get_texture(), Vector2.ZERO)
	_output_texture.set_padding(get_padding())
	return _output_texture

func clear() -> void:
	_textures.clear()
	clear_viewport()
	_shader = null
	_padding_multiplier = 1.0
	_previous = null
	_next = null

func clear_viewport() -> void:
	while _viewport.get_child_count() != 0:
		_viewport.remove_child(_viewport.get_child(_viewport.get_child_count()-1))

func _compute_viewport_size() -> void:
	var viewport_size = Vector2.ZERO
	for texture in _textures:
		if viewport_size.x < texture.get_texture().get_size().x:
			viewport_size.x = texture.get_texture().get_size().x
		if viewport_size.y < texture.get_texture().get_size().y:
			viewport_size.y = texture.get_texture().get_size().y
	_viewport.size = viewport_size * _padding_multiplier

func recompose() -> void:
	# clear viewport
	clear_viewport()
	var padding = get_padding() / 2.0
	# add textures to viewport with hierarchical structure
	for texture in _textures:
		var sprite = _create_sprite_hierarchy(texture, padding, null)
		if _shader:
			sprite.material = _shader.get_shader_material()
		_viewport.add_child(sprite)
	
	if _next:
		_next.recompose()

func get_padding() -> Vector2:
	return (_viewport.size - Vector2i(_viewport.size / _padding_multiplier))

func _create_sprite(texture: VNTexture, padding: Vector2) -> Sprite2D:
	var sprite = VNSprite.new(texture, texture.get_position() + padding)
	sprite.centered = false
	return sprite

## Creates hierarchical sprite structure recursively
## @param texture: The VNTexture to create sprite for
## @param padding: The padding to apply to root sprites
## @param parent_sprite: The parent sprite node (null for root)
## @return The created sprite with all children attached
func _create_sprite_hierarchy(texture: VNTexture, padding: Vector2, parent_sprite: Node2D) -> Sprite2D:
	# Create sprite for current texture
	var sprite: Sprite2D
	
	if parent_sprite == null:
		# Root sprite: apply padding
		sprite = _create_sprite(texture, padding)
	else:
		# Child sprite: position relative to parent
		sprite = VNSprite.new(texture, parent_sprite.to_centered_position(texture))
		sprite.scale = texture.get_scale()
		sprite.centered = false
	
	# Get source layer for z-index calculation
	var source = texture.get_source()
	if source and source is DisplayableLayer:
		var layer = source as DisplayableLayer
		if parent_sprite != null and layer.parent_layer:
			# Apply relative z-index: parent.z + child.z
			sprite.z_index = layer.parent_layer.z_index + layer.z_index
		else:
			sprite.z_index = layer.z_index
	
	# Recursively create child sprites
	if texture.has_children():
		for child_texture in texture.get_children():
			var child_sprite = _create_sprite_hierarchy(child_texture, padding, sprite)
			sprite.add_child(child_sprite)
	
	return sprite
