## DisplayableLayer - Self-contained layer with mesh, texture, and raycast-based collision
## Each layer manages its own visibility, input handling, and collision detection
class_name DisplayableLayer
extends Node2D

## Custom signals for interaction events
signal layer_hovered(layer_name: String)
signal layer_unhovered(layer_name: String)
signal layer_clicked(layer_name: String, event: InputEvent)

## Signal for when the postprocess sub viewport changes
signal postprocess_sub_viewport_changed(new_viewport: SubViewport)

## Layer identifier
var layer_name: String = ""

## The visual mesh instance
var postprocess_sub_viewport: SubViewport = null

## The composed sprite instance
var composed_sprite: Sprite2D = null

## Layer visibility (separate from Node3D.visible for control)
var is_layer_visible: bool = false

## Reference to parent displayable node (for callbacks)
var parent_displayable = null  # DisplayableNode

## Alpha threshold for collision detection (configurable per layer)
var alpha_threshold: float = 0.5

## Track mouse hover state
var is_mouse_over: bool = false

## Cached alpha mask for performance
var texture_image: Image = null


func _init(p_layer_name: String = "") -> void:
	layer_name = p_layer_name
	name = "Layer_" + layer_name

	composed_sprite = Sprite2D.new()
	composed_sprite.name = "ComposedSprite_" + layer_name
	composed_sprite.centered = false

	# Create the mesh instance as a child
	postprocess_sub_viewport = SubViewport.new()
	postprocess_sub_viewport.name = "PostprocessSubViewport_" + layer_name
	postprocess_sub_viewport.transparent_bg = true
	postprocess_sub_viewport.disable_3d = true
	postprocess_sub_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	postprocess_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	add_child(postprocess_sub_viewport)

func _ready() -> void:
	# Input processing now handled by DisplayableNode parent
	pass

## Sets the texture and updates the quad mesh
func set_texture(tex: Image) -> void:
	if not tex:
		push_warning("DisplayableLayer: Attempted to set null texture on layer '%s'" % layer_name)
		return
	
	texture_image = tex


func commit_postprocess_sub_viewport() -> void:
	if not postprocess_sub_viewport:
		return
	composed_sprite.texture = postprocess_sub_viewport.get_texture()

	postprocess_sub_viewport_changed.emit(postprocess_sub_viewport)

## Gets the composed sprite
func get_composed_sprite() -> Sprite2D:
	return composed_sprite

## Controls layer visibility
func set_layer_visible(p_visible: bool) -> void:
	is_layer_visible = p_visible
	
	# Update Node3D visibility
	if p_visible and not postprocess_sub_viewport.get_parent():
		add_child(postprocess_sub_viewport)
	elif not p_visible and postprocess_sub_viewport.get_parent() and not p_visible:
		remove_child(postprocess_sub_viewport)

	# If layer becomes invisible while mouse is over, trigger exit
	if not p_visible and is_mouse_over:
		_trigger_mouse_exit()
	
	# Notify parent to rebuild root collision
	if parent_displayable and parent_displayable.has_method("_on_layer_visibility_changed"):
		parent_displayable._on_layer_visibility_changed()


## Handles input events for raycast-based collision detection
func _input(event: InputEvent) -> void:
	# Only process clicks - mouse motion is handled by DisplayableNode
	if event is InputEventMouseButton:
		if event.pressed and is_mouse_over:
			layer_clicked.emit(layer_name, event)
			get_viewport().set_input_as_handled()


## Triggers mouse enter event
func _trigger_mouse_enter() -> void:
	is_mouse_over = true
	layer_hovered.emit(layer_name)
	
	# Notify InteractionHandler
	if parent_displayable and parent_displayable.has_method("get_controller"):
		var controller = parent_displayable.get_controller()
		if controller:
			InteractionHandler.on_hover_enter(controller, layer_name)


## Triggers mouse exit event
func _trigger_mouse_exit() -> void:
	is_mouse_over = false
	layer_unhovered.emit(layer_name)
	
	# Notify InteractionHandler
	if parent_displayable and parent_displayable.has_method("get_controller"):
		var controller = parent_displayable.get_controller()
		if controller:
			InteractionHandler.on_hover_exit(controller, layer_name)


## Sets the alpha threshold for collision detection
func set_alpha_threshold(threshold: float) -> void:
	alpha_threshold = clamp(threshold, 0.0, 1.0)


## ============================================================================
## DEBUG VISUALIZATION
## ============================================================================

## Enables or disables debug visualization of collision area
func set_debug_enabled(enabled: bool) -> void:
	pass


## Creates a visual debug outline for the quad bounds
func _create_debug_outline() -> void:
	pass

## Removes debug outline visualization
func _remove_debug_outline() -> void:
	pass
