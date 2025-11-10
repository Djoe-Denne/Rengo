## Pass - Single node in the viewport pass chain (doubly-linked list)
class_name Pass
extends Node

var _shader: VNShader = null
var _viewport: SubViewport
var _textures: Array[TransformableTexture] = []
var _padding_multiplier: float = 1.0
var _previous: Pass = null
var _next: Pass = null
var _output_texture: TransformableTexture = null
var _scale: Vector2 = Vector2.ONE

func _init(displayable: Displayable, p_shader: VNShader = null) -> void:
	_shader = p_shader
	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.disable_3d = true
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	displayable.add_child(self)

func add_texture(p_texture: TransformableTexture) -> void:
	_textures.append(p_texture)
	_compute_viewport_size()

func get_textures() -> Array[TransformableTexture]:
	return _textures

func get_texture(p_index: int) -> TransformableTexture:
	if p_index < 0 or p_index >= _textures.size():
		return null
	return _textures[p_index]

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

func get_output_texture() -> TransformableTexture:
	_output_texture = TransformableTexture.new(_viewport.get_texture(), Vector2.ZERO)
	_output_texture.set_scale(_scale)
	return _output_texture

func get_scale() -> Vector2:
	return _scale

func set_scale(p_scale: Vector2) -> void:
	_scale = p_scale

func clear() -> void:
	_textures.clear()
	clear_viewport()
	_shader = null
	_padding_multiplier = 1.0
	_previous = null
	_next = null
	_scale = Vector2.ONE

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

func clickables_at_uv(uv: Vector2) -> Array:
	var result: Array = []
	var children: Array = _viewport.get_children().filter(func(child): return child is Sprite2D).map(func(child): return child as Sprite2D)
	for child in children:
		if CollisionHelper.is_hover_non_transparent(_viewport.size, _get_padding(), child, uv):
			var sprite: Sprite2D = child
			if sprite.has_meta("source"):
				result.append(child.get_meta("source"))
			else:
				result.append(true)
	return result

func recompose() -> void:
	# clear viewport
	clear_viewport()
	var padding = _get_padding() / 2.0
	# add textures to viewport
	for texture in _textures:
		var sprite = _create_sprite(texture, padding)
		if _shader:
			sprite.material = _shader.get_shader_material()
		_viewport.add_child(sprite)
	
	if _next:
		_next.recompose()

func _get_padding() -> Vector2:
	return (_viewport.size - Vector2i(_viewport.size / _padding_multiplier))

func _create_sprite(texture: TransformableTexture, padding: Vector2) -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.texture = texture.get_texture()
	sprite.position = texture.get_position() + padding
	sprite.scale = texture.get_scale()
	sprite.centered = false
	if texture.get_source() and texture.get_source() is DisplayableLayer:
		sprite.set_meta("source", texture.get_source().get_path())
	return sprite
