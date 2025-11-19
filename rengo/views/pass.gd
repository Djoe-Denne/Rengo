## Pass - Single node in the viewport pass chain (doubly-linked list)
class_name Pass
extends Node

var _shader: VNShader = null
var _viewport: SubViewport
var _textures: Dictionary = {}
var _padding_multiplier: float = 1.0
var _previous: Pass = null
var _next: Pass = null
var _output_texture: VNTexture = null
var _changed_texture_ids: Array[String] = []
var _is_active: bool = true
var _sprite_cache: Dictionary = {}  # Keyed by layer_id
var _cached_texture_structure: Dictionary = {}

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
	_textures[p_texture.get_layer_id()] = p_texture
	_changed_texture_ids.append(p_texture.get_layer_id())
	_compute_viewport_size()

func remove_texture(p_texture_id: String) -> void:
	_textures.erase(p_texture_id)
	_changed_texture_ids.append(p_texture_id)

func get_textures() -> Array[VNTexture]:
	var out: Array[VNTexture] = []
	for t in _textures.values():
		out.append(t as VNTexture)
	return out

func get_texture(p_index: int) -> VNTexture:
	if p_index < 0 or p_index >= _textures.size():
		return null
	return _textures.values()[p_index]

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

func set_shader(p_shader: VNShader) -> void:
	_shader = p_shader

func is_active() -> bool:
	return _is_active

func set_active(p_active: bool) -> void:
	if _is_active == p_active:
		return
	
	_is_active = p_active
	
	if _is_active:
		# Activate: add viewport back to scene tree
		if _viewport.get_parent() == null:
			add_child(_viewport)
	else:
		# Deactivate: remove viewport from scene tree to save rendering cost
		if _viewport.get_parent() != null:
			remove_child(_viewport)

func get_padding_multiplier() -> float:
	return _padding_multiplier

func set_padding_multiplier(p_padding_multiplier: float) -> void:
	if p_padding_multiplier < 1.0:
		p_padding_multiplier = 1.0
	_padding_multiplier = p_padding_multiplier

func get_output_texture() -> VNTexture:
	# If inactive, pass through previous pass's output
	if not _is_active and _previous:
		return _previous.get_output_texture()
	
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
	_sprite_cache.clear()
	_cached_texture_structure.clear()

func clear_viewport() -> void:
	while _viewport.get_child_count() != 0:
		_viewport.remove_child(_viewport.get_child(_viewport.get_child_count()-1))

func _compute_viewport_size() -> void:
	var viewport_size = Vector2.ZERO
	for texture in _textures.values():
		if viewport_size.x < texture.get_texture().get_size().x:
			viewport_size.x = texture.get_texture().get_size().x
		if viewport_size.y < texture.get_texture().get_size().y:
			viewport_size.y = texture.get_texture().get_size().y
	_viewport.size = viewport_size * _padding_multiplier

func recompose() -> void:
	if not _is_active:
		# Skip recomposition for inactive passes
		if _next:
			_next.recompose()
		return
	
	var padding = get_padding() / 2.0
	
	# Compute current texture structure
	var current_structure = {}
	for texture in _textures.values():
		current_structure[texture.get_layer_id()] = _compute_texture_structure(texture)
	
	# Check if structure changed
	var structure_changed = (current_structure.hash() != _cached_texture_structure.hash())
	
	if structure_changed:
		# Structure changed: rebuild from scratch but reuse sprites from cache
		clear_viewport()
		
		for texture in _textures.values():
			var sprite = _rebuild_sprite_hierarchy(texture, padding, null)
			if _shader:
				sprite.material = _shader.get_shader_material()
			_viewport.add_child(sprite)
		
		_cached_texture_structure = current_structure
	else:
		# Structure unchanged: just update existing sprites
		for texture in _textures.values():
			var layer_id = texture.get_layer_id()
			if layer_id in _sprite_cache:
				var sprite = _sprite_cache[layer_id]
				if sprite and sprite.get_parent() == _viewport:
					_update_sprite(sprite, texture, padding, null)
					# Update shader material if needed
					if _shader:
						sprite.material = _shader.get_shader_material()
					# Recursively update children
					_update_sprite_hierarchy_children(sprite, texture, padding)
	
	if _next:
		_next.recompose()

## Recursively updates child sprites in the hierarchy
func _update_sprite_hierarchy_children(sprite: VNSprite, texture: VNTexture, padding: Vector2) -> void:
	if not texture.has_children():
		return
	
	for child_texture in texture.get_children():
		var child_layer_id = child_texture.get_layer_id()
		if child_layer_id in _sprite_cache:
			var child_sprite = _sprite_cache[child_layer_id]
			if child_sprite:
				_update_sprite(child_sprite, child_texture, padding, sprite)
				_update_sprite_hierarchy_children(child_sprite, child_texture, padding)

func get_padding() -> Vector2:
	return (_viewport.size - Vector2i(_viewport.size / _padding_multiplier))

func _create_sprite(texture: VNTexture, padding: Vector2) -> Sprite2D:
	var sprite = VNSprite.new(texture, texture.get_position() + padding)
	sprite.centered = false
	return sprite

## Computes a structure signature for texture hierarchy (for change detection)
func _compute_texture_structure(texture: VNTexture) -> Dictionary:
	var structure = {
		"layer_id": texture.get_layer_id(),
		"has_children": texture.has_children(),
		"children": []
	}
	
	if texture.has_children():
		for child_texture in texture.get_children():
			structure["children"].append(_compute_texture_structure(child_texture))
	
	return structure

## Updates an existing sprite with new texture data
func _update_sprite(sprite: VNSprite, texture: VNTexture, padding: Vector2, parent_sprite: Node2D) -> void:
	# Update texture
	sprite.texture = texture.get_texture()
	sprite._texture = texture
	
	# Update position
	if parent_sprite == null:
		sprite.position = texture.get_position() + padding
	else:
		sprite.position = parent_sprite.to_centered_position(texture)
	
	# Update scale
	sprite.scale = texture.get_scale()
	
	# Update z-index
	var source = texture.get_source()
	if source and source is DisplayableLayer:
		var layer = source as DisplayableLayer
		if parent_sprite != null and layer.parent_layer:
			sprite.z_index = layer.parent_layer.z_index + layer.z_index
		else:
			sprite.z_index = layer.z_index

## Rebuilds hierarchical sprite structure recursively with caching
## @param texture: The VNTexture to create/update sprite for
## @param padding: The padding to apply to root sprites
## @param parent_sprite: The parent sprite node (null for root)
## @return The created/updated sprite with all children attached
func _rebuild_sprite_hierarchy(texture: VNTexture, padding: Vector2, parent_sprite: Node2D) -> Sprite2D:
	var layer_id = texture.get_layer_id()
	var sprite: Sprite2D = null
	
	# Try to reuse existing sprite from cache
	if layer_id in _sprite_cache and _sprite_cache[layer_id] != null:
		sprite = _sprite_cache[layer_id]
		# Update existing sprite with new texture data
		_update_sprite(sprite, texture, padding, parent_sprite)
	else:
		# Create new sprite
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
		
		# Cache the new sprite
		_sprite_cache[layer_id] = sprite
	
	# Recursively rebuild child sprites
	if texture.has_children():
		# Build a set of expected child layer IDs
		var expected_children = {}
		for child_texture in texture.get_children():
			expected_children[child_texture.get_layer_id()] = child_texture
		
		# Remove children that are no longer needed
		for i in range(sprite.get_child_count() - 1, -1, -1):
			var child = sprite.get_child(i)
			if child is VNSprite:
				var child_layer_id = child._texture.get_layer_id() if child._texture else ""
				if not child_layer_id in expected_children:
					sprite.remove_child(child)
		
		# Rebuild or update children
		for child_texture in texture.get_children():
			var child_sprite = _rebuild_sprite_hierarchy(child_texture, padding, sprite)
			# Only add if not already a child
			if child_sprite.get_parent() != sprite:
				sprite.add_child(child_sprite)
	else:
		# No children expected, remove all children
		while sprite.get_child_count() > 0:
			sprite.remove_child(sprite.get_child(sprite.get_child_count() - 1))
	
	return sprite
