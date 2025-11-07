## Displayable - Multi-pass viewport system for shader effects
## Manages a doubly-linked list of viewport passes, each feeding into the next
class_name Displayable
extends Node2D

## Signal for when the displayable changes
signal displayable_changed(displayable: Displayable)

## Signal for when padding changes
signal padding_changed(displayable: Displayable, new_padding: float)

## First pass in the chain (input)
var _input_pass: Pass = null

## Last pass in the chain (output)
var _output_pass: Pass = null

## Counter for generating unique pass names
var _pass_counter: int = 0

## Maximum padding percentage from all active shaders
var _max_padding: float = 0.0

var output_sprite: Sprite2D = null


func _init(displayable_name: String = "") -> void:
	name = "Displayable_" + displayable_name
	
	# Create the first pass (input = output initially)
	_create_initial_pass(displayable_name)


## Creates the initial pass (pass1)
func _create_initial_pass(_displayable_name: String) -> void:
	_input_pass = add_pass()
	_output_pass = add_pass()


## Adds a new pass at the end of the chain
## @param shader_material: Optional shader material to apply to the sprite
## @return: The newly created Pass
func add_pass(shader_material: Material = null) -> Pass:
	var previous_pass = _output_pass.get_previous() if _output_pass else _input_pass
	var new_pass = _create_pass(previous_pass, shader_material)
	
	if previous_pass:
		var next_pass = previous_pass.get_next()
		previous_pass.set_next(new_pass)
		new_pass.set_previous(previous_pass)
		new_pass.set_next(next_pass)
		if next_pass:
			next_pass.get_sprite(0).texture = new_pass.get_viewport().get_texture()
	displayable_changed.emit(self)
	return new_pass


func _create_pass(after_pass: Pass, shader_material: Material = null) -> Pass:
	_pass_counter += 1
	var pass_name = "pass" + str(_pass_counter)
	
	# Create new viewport
	var viewport = SubViewport.new()
	viewport.name = pass_name
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	if after_pass:
		viewport.size = after_pass.get_viewport().size
	
	# Create sprite that shows the pass we're inserting after
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.centered = false
	if after_pass:
		sprite.texture = after_pass.get_viewport().get_texture()
	
	# Apply material if provided
	if shader_material:
		sprite.material = shader_material
	
	viewport.add_child(sprite)
	add_child(viewport)
	
	# Create new pass
	return Pass.new(viewport, sprite)


## Inserts a new pass after the specified pass
## @param after_pass: The pass after which to insert the new pass
## @param shader_material: Optional shader material to apply to the sprite
## @return: The newly created Pass
func insert_pass_after(after_pass: Pass, shader_material: Material = null) -> Pass:
	if not after_pass:
		push_error("Displayable: Cannot insert pass after null")
		return null

	var new_pass = _create_pass(after_pass, shader_material)
	
	# Insert into linked list
	new_pass.set_previous(after_pass)
	new_pass.set_next(after_pass.get_next())
	
	if after_pass.get_next():
		# Update the next pass to show the new pass output
		after_pass.get_next().get_sprite(0).texture = new_pass.get_viewport().get_texture()
		after_pass.get_next().set_previous(new_pass)
	else:
		# We're adding at the end
		_output_pass = new_pass
	
	after_pass.set_next(new_pass)
	displayable_changed.emit(self)
	return new_pass


## Removes a pass from the chain
## @param pass_to_remove: The pass to remove (cannot be the first pass)
func remove_pass(pass_to_remove: Pass) -> void:
	if not pass_to_remove:
		push_error("Displayable: Cannot remove null pass")
		return
	
	if pass_to_remove == _input_pass:
		push_error("Displayable: Cannot remove the first pass")
		return
	
	# Update linked list
	if pass_to_remove.get_previous():
		pass_to_remove.get_previous().set_next(pass_to_remove.get_next())
	
	if pass_to_remove.get_next():
		# Update next pass to show previous pass output
		pass_to_remove.get_next().get_sprite(0).texture = pass_to_remove.get_previous().get_viewport().get_texture()
		pass_to_remove.get_next().set_previous(pass_to_remove.get_previous())
	else:
		# We're removing the last pass
		_output_pass = pass_to_remove.get_previous()
	
	# Free the viewport
	pass_to_remove.get_viewport().queue_free()
	
	displayable_changed.emit(self)


## Gets the input pass (first pass)
func get_input_pass() -> Pass:
	return _input_pass

## Gets the input sprite (first pass sprite for setting base texture)
func get_input_sprite(p_index: int = 0) -> Sprite2D:
	if _input_pass:
		return _input_pass.get_sprite(p_index)
	return null

func set_input_sprite_texture(texture: Texture2D, p_index: int = 0) -> void:
	if _input_pass:
		_input_pass.get_sprite(p_index).texture = texture
	_update_input_region()

func add_input_sprite(p_sprite: Sprite2D) -> void:
	if _input_pass:
		_input_pass.add_sprite(p_sprite)
	_update_input_region()

## Gets the input viewport (first pass viewport)
func get_input_viewport() -> SubViewport:
	if _input_pass:
		return _input_pass.get_viewport()
	return null


## Gets the output pass (last pass)
func get_output_pass() -> Pass:
	return _output_pass

## Gets the output viewport (last pass viewport)
func get_output_viewport() -> SubViewport:
	if _output_pass:
		return _output_pass.get_viewport()
	return null

func get_output_sprite() -> Sprite2D:
	if not output_sprite:
		output_sprite = Sprite2D.new()
		output_sprite.name = "Sprite2D"
		output_sprite.centered = false
		output_sprite.texture = get_output_viewport().get_texture()
		output_sprite.visible = true
	return output_sprite

## Sets the size for all viewport passes
## @param size: The base size (typically texture size + 25% padding)
func _set_viewport_size(size: Vector2i) -> void:
	var current = _input_pass
	while current:
		current.get_viewport().size = size
		current = current.get_next()


## Gets the number of passes in the chain
func get_pass_count() -> int:
	return _pass_counter - 2 # -2 for _input_pass and _output_pass


## Clears all passes except the first one
func clear_shader_passes() -> void:
	if not _input_pass:
		return
	
	# Remove all passes after the first
	var current = _input_pass.get_next()	
	while current != _output_pass:
		var next_pass = current.get_next()
		current.get_viewport().queue_free()
		current = next_pass
	
	# Reset chain to just first pass
	_input_pass.set_next(_output_pass)
	_output_pass.set_previous(_input_pass)
	_pass_counter = 2
	
	displayable_changed.emit(self)


## Sets the maximum padding percentage
func set_max_padding(padding: float) -> void:
	if _max_padding != padding:
		_max_padding = padding
		_update_input_region()
		padding_changed.emit(self, _max_padding)
		displayable_changed.emit(self)

## Gets the maximum padding percentage
func get_max_padding() -> float:
	return _max_padding


## Updates the input pass sprite region based on current padding and texture
func _update_input_region() -> void:
	if not _input_pass or not _input_pass.get_sprites().size() > 0:
		return
	
	## Find biggest sprite
	var sprite = null

	for current_sprite in _input_pass.get_sprites():
		if not current_sprite.texture:
			continue
		if not sprite or current_sprite.texture.get_size().x > sprite.texture.get_size().x:
			sprite = current_sprite
		if not sprite or current_sprite.texture.get_size().y > sprite.texture.get_size().y:
			sprite = current_sprite

	var texture = sprite.texture
	
	if not texture:
		sprite.region_enabled = false
		return
	
	# Get base texture size
	var tex_size = texture.get_size()
	
	# Calculate padding offset (centered)
	var padding_multiplier = _max_padding / 100.0
	var offset_x = -tex_size.x * padding_multiplier / 2.0
	var offset_y = -tex_size.y * padding_multiplier / 2.0
	
	# Calculate padded region size
	var region_width = tex_size.x * (1.0 + padding_multiplier)
	var region_height = tex_size.y * (1.0 + padding_multiplier)
	
	# Apply region settings to input sprite
	sprite.region_enabled = true
	sprite.region_rect = Rect2(offset_x, offset_y, region_width, region_height)
	_set_viewport_size(Vector2i(region_width, region_height))
	displayable_changed.emit(self)

func force_update() -> void:
	_update_input_region()
