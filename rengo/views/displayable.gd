## Displayable - Multi-pass viewport system for shader effects
## Manages a doubly-linked list of viewport passes, each feeding into the next
class_name Displayable
extends Node2D

## Signal for when the displayable changes
signal displayable_changed(displayable: Displayable)

## First pass in the chain (input)
var input_pass: Pass = null

## Last pass in the chain (output)
var output_pass: Pass = null

## Counter for generating unique pass names
var _pass_counter: int = 1


func _init(displayable_name: String = "") -> void:
	name = "Displayable_" + displayable_name
	
	# Create the first pass (input = output initially)
	_create_initial_pass(displayable_name)


## Creates the initial pass (pass1)
func _create_initial_pass(displayable_name: String) -> void:
	var viewport = SubViewport.new()
	viewport.name = "pass1"
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.centered = false
	
	viewport.add_child(sprite)
	add_child(viewport)
	
	# Create the first pass
	var main_pass = Pass.new(viewport, sprite)
	input_pass = main_pass
	output_pass = main_pass


## Adds a new pass at the end of the chain
## @param material: Optional shader material to apply to the sprite
## @return: The newly created Pass
func add_pass(material: Material = null) -> Pass:
	_pass_counter += 1
	var pass_name = "pass" + str(_pass_counter)
	
	# Create new viewport
	var viewport = SubViewport.new()
	viewport.name = pass_name
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.size = output_pass.viewport.size  # Match size of previous pass
	
	# Create sprite that shows previous pass
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.centered = false
	sprite.texture = output_pass.viewport.get_texture()
	
	# Apply material if provided
	if material:
		sprite.material = material
	
	viewport.add_child(sprite)
	add_child(viewport)
	
	# Create new pass and link it
	var new_pass = Pass.new(viewport, sprite)
	new_pass.previous = output_pass
	output_pass.next = new_pass
	output_pass = new_pass
	
	return new_pass


## Inserts a new pass after the specified pass
## @param after_pass: The pass after which to insert the new pass
## @param material: Optional shader material to apply to the sprite
## @return: The newly created Pass
func insert_pass_after(after_pass: Pass, material: Material = null) -> Pass:
	if not after_pass:
		push_error("Displayable: Cannot insert pass after null")
		return null
	
	_pass_counter += 1
	var pass_name = "pass" + str(_pass_counter)
	
	# Create new viewport
	var viewport = SubViewport.new()
	viewport.name = pass_name
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.size = after_pass.viewport.size
	
	# Create sprite that shows the pass we're inserting after
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.centered = false
	sprite.texture = after_pass.viewport.get_texture()
	
	# Apply material if provided
	if material:
		sprite.material = material
	
	viewport.add_child(sprite)
	add_child(viewport)
	
	# Create new pass
	var new_pass = Pass.new(viewport, sprite)
	
	# Insert into linked list
	new_pass.previous = after_pass
	new_pass.next = after_pass.next
	
	if after_pass.next:
		# Update the next pass to show the new pass output
		after_pass.next.sprite.texture = new_pass.viewport.get_texture()
		after_pass.next.previous = new_pass
	else:
		# We're adding at the end
		output_pass = new_pass
	
	after_pass.next = new_pass
	
	return new_pass


## Removes a pass from the chain
## @param pass_to_remove: The pass to remove (cannot be the first pass)
func remove_pass(pass_to_remove: Pass) -> void:
	if not pass_to_remove:
		push_error("Displayable: Cannot remove null pass")
		return
	
	if pass_to_remove == input_pass:
		push_error("Displayable: Cannot remove the first pass")
		return
	
	# Update linked list
	if pass_to_remove.previous:
		pass_to_remove.previous.next = pass_to_remove.next
	
	if pass_to_remove.next:
		# Update next pass to show previous pass output
		pass_to_remove.next.sprite.texture = pass_to_remove.previous.viewport.get_texture()
		pass_to_remove.next.previous = pass_to_remove.previous
	else:
		# We're removing the last pass
		output_pass = pass_to_remove.previous
	
	# Free the viewport
	pass_to_remove.viewport.queue_free()
	
	displayable_changed.emit(self)


## Gets the output texture (from the last pass)
func get_output_texture() -> ViewportTexture:
	if output_pass:
		return output_pass.viewport.get_texture()
	return null


## Gets the input sprite (first pass sprite for setting base texture)
func get_input_sprite() -> Sprite2D:
	if input_pass:
		return input_pass.sprite
	return null


## Gets the input viewport (first pass viewport)
func get_input_viewport() -> SubViewport:
	if input_pass:
		return input_pass.viewport
	return null


## Gets the output viewport (last pass viewport)
func get_output_viewport() -> SubViewport:
	if output_pass:
		return output_pass.viewport
	return null


## Sets the size for all viewport passes
## @param size: The base size (typically texture size + 25% padding)
func set_pass_size(size: Vector2i) -> void:
	var current = input_pass
	while current:
		current.viewport.size = size
		current = current.next


## Gets the number of passes in the chain
func get_pass_count() -> int:
	var count = 0
	var current = input_pass
	while current:
		count += 1
		current = current.next
	return count


## Clears all passes except the first one
func clear_shader_passes() -> void:
	if not input_pass:
		return
	
	# Remove all passes after the first
	var current = input_pass.next
	while current:
		var next_pass = current.next
		current.viewport.queue_free()
		current = next_pass
	
	# Reset chain to just first pass
	input_pass.next = null
	output_pass = input_pass
	_pass_counter = 1
	
	displayable_changed.emit(self)
