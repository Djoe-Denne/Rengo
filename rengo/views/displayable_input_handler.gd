## DisplayableInputHandler - Centralized input handler for DisplayableNode layers
## Attaches to DisplayableNode to coordinate mouse events across layers
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
		var topmost_hit_layer = _get_topmost_layer(main_camera, mouse_pos)
		
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
func _check_layer_intersections_viewport(main_camera: Camera3D, mouse_pos: Vector2) -> Array[DisplayableLayer]:
	if not displayable_node or not displayable_node.output_mesh:
		return []
	
	# Step 1: Raycast from main camera to output_mesh to get UV coordinates
	var output_mesh = displayable_node.output_mesh
	var quad_size = displayable_node.base_size

	var quad_transform = output_mesh.global_transform
	var hit_info = CollisionHelper.raycast_to_quad(main_camera, mouse_pos, quad_transform, quad_size)
	
	if not hit_info.hit:
		return []

	var uv = CollisionHelper.get_uv_from_world_hit(hit_info.position, quad_transform, quad_size)
	return displayable_node.get_layers_at_uv(uv)

func _get_topmost_layer(main_camera: Camera3D, mouse_pos: Vector2) -> DisplayableLayer:
	var intersected_layers = _check_layer_intersections_viewport(main_camera, mouse_pos)
	if intersected_layers.is_empty():
		return null
	intersected_layers.sort_custom(func(a: DisplayableLayer, b: DisplayableLayer): return a.z_index > b.z_index)
	return intersected_layers[0]
