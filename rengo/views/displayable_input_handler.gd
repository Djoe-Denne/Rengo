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
		var main_camera = get_viewport().get_camera_3d()
		if not main_camera:
			return
		
		# Transform mouse position to viewport space and check layers
		var topmost_hit_layer = _check_layer_intersections_viewport(main_camera, mouse_pos)
		
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


## Checks all visible layers for mouse intersection using viewport-aware raycasting
## Returns topmost hit layer
func _check_layer_intersections_viewport(main_camera: Camera3D, mouse_pos: Vector2) -> DisplayableLayer:
	if not displayable_node or not displayable_node.output_mesh or not displayable_node.viewport_camera:
		return null
	
	# Step 1: Raycast from main camera to output_mesh to get UV coordinates
	var output_mesh = displayable_node.output_mesh
	var quad_size = Vector2(100, 100)
	if output_mesh.mesh is QuadMesh:
		quad_size = (output_mesh.mesh as QuadMesh).size
	
	var quad_transform = output_mesh.global_transform
	var hit_info = CollisionHelper.raycast_to_quad(main_camera, mouse_pos, quad_transform, quad_size)
	
	if not hit_info.hit:
		return null
	
	# Step 2: Convert UV to viewport pixel coordinates
	var viewport_size = displayable_node.sub_viewport.size
	var viewport_pos = Vector2(
		hit_info.uv.x * viewport_size.x,
		hit_info.uv.y * viewport_size.y
	)
	
	# Step 3: Check layers using viewport camera and viewport coordinates
	return _check_layers_in_viewport(viewport_pos)


## Checks layers within the SubViewport using viewport-local coordinates
func _check_layers_in_viewport(viewport_pos: Vector2) -> DisplayableLayer:
	if not displayable_node or not displayable_node.viewport_camera:
		return null
	
	# Get all visible layers and sort by z-index descending (highest first for occlusion)
	var visible_layers = displayable_node.get_visible_layers()
	visible_layers.sort_custom(func(a, b): return a.z_index > b.z_index)
	
	# Check each layer until we find a hit (front-to-back occlusion)
	for layer in visible_layers:
		if layer.check_mouse_intersection(displayable_node.viewport_camera, viewport_pos):
			return layer
	
	return null


## DEPRECATED: Old method for backward compatibility
func _check_layer_intersections(camera: Camera3D, mouse_pos: Vector2) -> DisplayableLayer:
	# Fallback to viewport-aware method
	return _check_layer_intersections_viewport(camera, mouse_pos)


## Clear hover state (called when layer visibility changes)
func clear_hover_if_layer(layer: DisplayableLayer) -> void:
	if _currently_hovered_layer == layer:
		_currently_hovered_layer._trigger_mouse_exit()
		_currently_hovered_layer = null
