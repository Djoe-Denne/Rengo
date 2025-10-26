## InteractionArea - Flexible input handling for TexturedResourceNodes
## Extends Area2D to provide collision detection based on sprite shape
## 
## Handler Interface:
## Handlers should implement two methods:
## - should_handle(resource: TexturedResourceNode, event: Dictionary) -> bool
## - handle(resource: TexturedResourceNode, event: Dictionary) -> void
##
## Event dictionary structure:
## {
##   "type": String,  # "click", "hover_enter", "hover_exit", "drag_start", "drag_move", "drag_end"
##   "position": Vector2,  # Local position of the event
##   "button_index": int,  # Mouse button (for click/drag)
##   "pressed": bool,  # Button state (for click)
##   ... additional event-specific data
## }
class_name InteractionArea
extends Area2D

## Reference to the parent TexturedResourceNode
var resource_node = null  # TexturedResourceNode

## List of interaction handlers
var handlers: Array = []

## Current collision shape node
var collision_shape_node: CollisionPolygon2D = null

## Drag tracking
var is_dragging: bool = false
var drag_button: int = -1
var last_mouse_position: Vector2 = Vector2.ZERO


func _init(p_resource_node) -> void:
	resource_node = p_resource_node
	
	# Enable input processing
	input_pickable = true

	print("interaction area initialized")
	print("resource node: ", resource_node)
	print("resource name: ", resource_node.resource_name)
	print("resource position: ", resource_node.position)
	
	# Connect signals
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Create initial collision shape node
	collision_shape_node = CollisionPolygon2D.new()
	add_child(collision_shape_node)


func _ready() -> void:
	print("InteractionArea ready")
	# Update collision shape if resource already has a texture
	if resource_node and resource_node.scene_node:
		if "texture" in resource_node.scene_node and resource_node.scene_node.texture:
			update_collision_shape(resource_node.scene_node.texture)


func _process(_delta: float) -> void:
	# Handle drag tracking
	if is_dragging:
		var current_mouse_position = get_viewport().get_mouse_position()
		if current_mouse_position != last_mouse_position:
			_dispatch_event({
				"type": "drag_move",
				"position": to_local(current_mouse_position),
				"global_position": current_mouse_position,
				"button_index": drag_button,
				"delta": current_mouse_position - last_mouse_position
			})
			last_mouse_position = current_mouse_position


## Adds a handler to the interaction system
func add_handler(handler) -> void:
	if handler:
		handlers.append(handler)


## Updates the collision shape based on the sprite texture
func update_collision_shape(texture: Texture2D) -> void:
	if not texture or not collision_shape_node:
		return
	
	print("getting image from texture")
	var image = texture.get_image()
	if not image:
		push_warning("InteractionArea: Cannot get image from texture")
		return
	
	print("creating bitmap from image alpha channel")
	# Create bitmap from image alpha channel
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(image)
	
	print("generating polygon from opaque pixels")
	# Generate polygon from opaque pixels
	var polygons = bitmap.opaque_to_polygons(Rect2(Vector2.ZERO, image.get_size()))
	
	print("polygons: ", polygons)
	if polygons.size() == 0:
		push_warning("InteractionArea: No polygons generated from texture")
		return
	
	# Use the first (and typically largest) polygon
	var polygon = polygons[0]
	
	# Center the polygon based on sprite centering
	if resource_node and resource_node.scene_node:
		if "centered" in resource_node.scene_node and resource_node.scene_node.centered:
			var size = image.get_size()
			var offset = -size / 2.0
			for i in range(polygon.size()):
				polygon[i] += offset
	
	collision_shape_node.polygon = polygon


## Handles input events from Area2D
func _on_input_event(viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		
		if mouse_event.pressed:
			# Mouse button pressed - could be click or drag start
			if mouse_event.button_index == MOUSE_BUTTON_LEFT:
				is_dragging = true
				drag_button = mouse_event.button_index
				last_mouse_position = viewport.get_mouse_position()
				
				_dispatch_event({
					"type": "drag_start",
					"position": to_local(mouse_event.position),
					"global_position": mouse_event.position,
					"button_index": mouse_event.button_index
				})
			
			# Always dispatch click event for pressed
			_dispatch_event({
				"type": "click",
				"position": to_local(mouse_event.position),
				"global_position": mouse_event.position,
				"button_index": mouse_event.button_index,
				"pressed": true
			})
		else:
			# Mouse button released
			if is_dragging and mouse_event.button_index == drag_button:
				_dispatch_event({
					"type": "drag_end",
					"position": to_local(mouse_event.position),
					"global_position": mouse_event.position,
					"button_index": mouse_event.button_index
				})
				is_dragging = false
				drag_button = -1
			
			# Dispatch click event for released
			_dispatch_event({
				"type": "click",
				"position": to_local(mouse_event.position),
				"global_position": mouse_event.position,
				"button_index": mouse_event.button_index,
				"pressed": false
			})


## Handles mouse entering the area
func _on_mouse_entered() -> void:
	_dispatch_event({
		"type": "hover_enter",
		"position": to_local(get_viewport().get_mouse_position()),
		"global_position": get_viewport().get_mouse_position()
	})


## Handles mouse exiting the area
func _on_mouse_exited() -> void:
	_dispatch_event({
		"type": "hover_exit",
		"position": to_local(get_viewport().get_mouse_position()),
		"global_position": get_viewport().get_mouse_position()
	})
	
	# Cancel drag if mouse leaves area
	if is_dragging:
		_dispatch_event({
			"type": "drag_end",
			"position": to_local(get_viewport().get_mouse_position()),
			"global_position": get_viewport().get_mouse_position(),
			"button_index": drag_button,
			"cancelled": true
		})
		is_dragging = false
		drag_button = -1


## Dispatches an event to all handlers
func _dispatch_event(event: Dictionary) -> void:
	print("dispatching event: ", event)
	for handler in handlers:
		# Check if handler implements the required methods
		if not handler.has_method("should_handle") or not handler.has_method("handle"):
			push_warning("InteractionArea: Handler missing required methods (should_handle/handle)")
			continue
		
		# Check if handler wants to handle this event
		if handler.should_handle(resource_node, event):
			handler.handle(resource_node, event)


