## DisplayableLayer - Self-contained layer with mesh, texture, and raycast-based collision
## Each layer manages its own visibility, input handling, and collision detection
class_name DisplayableLayer
extends Node2D

## Custom signals for interaction events
signal layer_hovered(layer_name: String)
signal layer_unhovered(layer_name: String)
signal layer_clicked(layer_name: String, event: InputEvent)
signal layer_displayable_changed(layer_name: String)

## Layer identifier
var layer_name: String = ""

var layer_size: Vector2 = Vector2(0, 0)

## Reference to parent displayable node (for callbacks)
var parent_displayable = null  # DisplayableNode

## Alpha threshold for collision detection (configurable per layer)
var alpha_threshold: float = 0.5

## Track mouse hover state
var is_mouse_over: bool = false

## Cached alpha mask for performance
var texture_image: Image = null

var displayable: Displayable = null


func _init(p_layer_name: String = "", p_layer_def: Dictionary = {}) -> void:
	layer_name = p_layer_name
	name = "Layer_" + layer_name

	displayable = Displayable.new(layer_name)
	
	# Set the anchor if it exists in the layer definition
	if "anchor" in p_layer_def:
		displayable.position.x = p_layer_def.anchor.get("x", 0.0)
		displayable.position.y = p_layer_def.anchor.get("y", 0.0)
	if "z" in p_layer_def:
		displayable.z_index = p_layer_def.z

	displayable.displayable_changed.connect(_on_displayable_changed)

	add_child(displayable)

func _ready() -> void:
	# Input processing now handled by DisplayableNode parent
	pass

func _on_displayable_changed(displayable: Displayable) -> void:
	layer_displayable_changed.emit(layer_name)


func set_size(p_size: Vector2) -> void:
	print("===============", "set_size on layer: ", layer_name, " with size: ", p_size, "===============")
	layer_size = p_size
	var final_render_size = displayable.postprocess_sub_viewport.size
	var ratio = Vector2(p_size.x / final_render_size.x, p_size.y / final_render_size.y)
	print("final_render_size: ", final_render_size)
	print("ratio: ", ratio)
	self.scale = ratio

## Sets the texture and updates the quad mesh
func set_texture(tex: Image) -> void:
	if not tex:
		push_warning("DisplayableLayer: Attempted to set null texture on layer '%s'" % layer_name)
		return
	
	texture_image = tex

## Controls layer visibility
func set_layer_visible(p_visible: bool) -> void:
	displayable.set_visible(p_visible)

	# Notify parent to rebuild root collision
	if parent_displayable and parent_displayable.has_method("_on_layer_visibility_changed"):
		parent_displayable._on_layer_visibility_changed()

func is_layer_visible() -> bool:
	return displayable.is_visible()

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
