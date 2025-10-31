## DisplayableInputHandler - Centralized input handler for DisplayableNode layers
## Attaches to sprite_container to coordinate mouse events across layers
class_name DisplayableInputHandler
extends Node3D

## Reference to the DisplayableNode this handler manages
var displayable_node = null  # DisplayableNode

## Currently hovered layer (for mouse event coordination)
var _currently_hovered_layer: DisplayableLayer = null


func _ready() -> void:
	set_process_input(true)


func _input(event: InputEvent) -> void:
	if not displayable_node:
		return
	
	if event is InputEventMouseMotion:
		var mouse_pos = event.position
		var camera = get_viewport().get_camera_3d()
		if not camera:
			return
		
		# Check all visible layers in z-order (highest first)
		var topmost_hit_layer = _check_layer_intersections(camera, mouse_pos)
		
		# If topmost hit changed from previous
		if topmost_hit_layer != _currently_hovered_layer:
			# Trigger exit on old layer
			if _currently_hovered_layer:
				_currently_hovered_layer._trigger_mouse_exit()
			
			# Trigger enter on new layer
			if topmost_hit_layer:
				topmost_hit_layer._trigger_mouse_enter()
			
			_currently_hovered_layer = topmost_hit_layer
			
			# Consume event if we hit a layer
			if topmost_hit_layer:
				get_viewport().set_input_as_handled()


## Checks all visible layers for mouse intersection, returns topmost hit
func _check_layer_intersections(camera: Camera3D, mouse_pos: Vector2) -> DisplayableLayer:
	if not displayable_node:
		return null
	
	# Get all visible layers and sort by z-index descending
	var visible_layers = displayable_node.get_visible_layers()
	visible_layers.sort_custom(func(a, b): return a.z_index > b.z_index)
	
	# Check each layer until we find a hit (occlusion)
	for layer in visible_layers:
		if layer.check_mouse_intersection(camera, mouse_pos):
			return layer
	
	return null


## Clear hover state (called when layer visibility changes)
func clear_hover_if_layer(layer: DisplayableLayer) -> void:
	if _currently_hovered_layer == layer:
		_currently_hovered_layer._trigger_mouse_exit()
		_currently_hovered_layer = null

