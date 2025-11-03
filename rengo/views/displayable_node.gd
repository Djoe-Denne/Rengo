
## DisplayableNode - Base class for multi-layer displayable resources
## Extends ResourceNode with layer management and interaction routing
## Used as base class for Actor, and potentially Background, Props, etc.
class_name DisplayableNode
extends ResourceNode


## Dictionary of all layers { layer_name: DisplayableLayer }
var layers: Dictionary = {}

## Container node that holds all layers (typically Node3D)
var sprite_container: Node3D = null

## Reference to controller (for interaction callbacks)
var controller = null  # Controller reference

## Input handler for centralized mouse event coordination
var input_handler = null  # DisplayableInputHandler

## SubViewport system for rendering all layers to a single texture
var sub_viewport: SubViewport = null
var viewport_camera: Camera3D = null
var viewport_container: Node3D = null
var output_mesh: MeshInstance3D = null
var largest_layer_size: Vector2 = Vector2(10, 10)  # Default size


func _init(p_name: String = "") -> void:
	super(p_name)

func set_controller(p_controller: Controller) -> void:
	controller = p_controller

## Sets up the SubViewport rendering system
func _setup_viewport() -> void:
	if sub_viewport:
		return  # Already set up
	
	# Create SubViewport
	sub_viewport = SubViewport.new()
	sub_viewport.name = "SubViewport_" + resource_name
	sub_viewport.transparent_bg = true
	sub_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	

	sub_viewport.size = Vector2i(int(largest_layer_size.x), int(largest_layer_size.y))
	
	# Create viewport container (holds all layer nodes)
	viewport_container = Node3D.new()
	viewport_container.name = "ViewportContainer_" + resource_name
	
	#Create orthogonal camera for viewport
	viewport_camera = Camera3D.new()
	viewport_camera.name = "ViewportCamera_" + resource_name
	viewport_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	viewport_camera.size = largest_layer_size.y  # Orthogonal size
	viewport_container.add_child(viewport_camera)
	
	
	output_mesh = MeshInstance3D.new()
	output_mesh.name = "OutputMesh_" + resource_name
	output_mesh.mesh = QuadMesh.new()
	output_mesh.mesh.size = largest_layer_size
	viewport_container.add_child(output_mesh)
	# Create material with SubViewport texture
	var material = StandardMaterial3D.new()
	material.albedo_texture = sub_viewport.get_texture()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED

	output_mesh.material_override = material
	
	sprite_container.add_child(sub_viewport)
	sprite_container.add_child(viewport_container)
	# Position camera to view layers from -Z direction
	_update_camera_position()

## Creates the scene node - should be overridden by subclasses
## Subclasses should create sprite_container and call parent's method
func create_scene_node(parent: Node) -> Node:
	# Create sprite_container
	sprite_container = MeshInstance3D.new()
	sprite_container.name = "SpriteContainer_" + resource_name
	
	# Set up SubViewport rendering system
	_setup_viewport()
	
	# Create and attach input handler for centralized mouse event coordination
	_create_input_handler()
	
	parent.add_child(sprite_container)

	scene_node = parent

	# Instruct director to set up initial layers
	if controller.director and controller.model:
		controller.director.instruct(controller.model)

	return sprite_container


## Updates the camera position to frame the largest layer
func _update_camera_position() -> void:
	if not viewport_camera:
		return
	
	# Set orthogonal size to match largest layer height
	viewport_camera.size = largest_layer_size.y
	
	# Position camera on -Z axis at a distance that frames the content
	# For orthogonal projection, distance doesn't affect framing, but we need
	# to be far enough back to see layers with positive Z offsets
	var camera_distance = largest_layer_size.y + 50.0  # Extra distance for z-layering
	viewport_camera.position = Vector3(0, 0, camera_distance)
	
	# Look at origin (where layers are positioned)
	viewport_camera.look_at(Vector3.ZERO, Vector3.UP)


## Updates viewport size based on largest visible layer
func _update_viewport_size() -> void:
	if not sub_viewport:
		return
	
	# Find the largest layer dimensions
	var new_largest_size = Vector2(10, 10)  # Minimum size
	
	for layer_name in layers:
		var layer = layers[layer_name]
		if not layer.is_layer_visible:
			continue
		
		# Get layer quad size
		if layer.mesh_instance and layer.mesh_instance.mesh is QuadMesh:
			var quad_size = (layer.mesh_instance.mesh as QuadMesh).size
			if quad_size.x * quad_size.y > largest_layer_size.x * largest_layer_size.y:
				new_largest_size = quad_size
	
	# Only update if size changed significantly (avoid unnecessary updates)
	if new_largest_size.x * new_largest_size.y > largest_layer_size.x * largest_layer_size.y:
		largest_layer_size = new_largest_size
		
		# Update SubViewport size
		sub_viewport.size = Vector2i(int(largest_layer_size.x), int(largest_layer_size.y))

		# Update output mesh size
		output_mesh.mesh.size = largest_layer_size

## Updates the viewport
func _update_viewport() -> void:
	_update_viewport_size()
	_update_camera_position()

## Adds a new layer to this displayable node
## layer_def contains configuration: { "layer": name, "z": z_index, ... }
func add_layer(layer_name: String, layer_def: Dictionary = {}) -> DisplayableLayer:
	if layer_name in layers:
		push_warning("DisplayableNode: Layer '%s' already exists, returning existing" % layer_name)
		return layers[layer_name]
	
	# Create the layer
	var layer = DisplayableLayer.new(layer_name)
	layer.parent_displayable = self
	
	# Set z-index if provided
	if "z" in layer_def:
		layer.set_z_index(layer_def.z)
	
	viewport_container.add_child(layer)
	
	# Store the layer
	layers[layer_name] = layer
	
	# Connect layer signals for interaction handling
	_connect_layer_signals(layer)
	_update_viewport()
	return layer


## Gets a layer by name
func get_layer(layer_name: String) -> DisplayableLayer:
	return layers.get(layer_name, null)


## Removes a layer
func remove_layer(layer_name: String) -> void:
	if not layer_name in layers:
		return
	
	var layer = layers[layer_name]
	
	# Remove from sprite container
	if layer.get_parent():
		layer.get_parent().remove_child(layer)
	
	# Free the layer
	layer.queue_free()
	layers.erase(layer_name)
	_update_viewport()


## Gets all visible layers
func get_visible_layers() -> Array:
	var visible = []
	for layer_name in layers:
		var layer = layers[layer_name]
		if layer.is_layer_visible:
			visible.append(layer)
	return visible


## Connects layer signals to interaction system
func _connect_layer_signals(layer: DisplayableLayer) -> void:
	if not layer:
		return
	
	# Connect layer signals for potential custom handling
	# (The layer itself handles direct InteractionHandler calls in its signal handlers)
	layer.layer_hovered.connect(_on_layer_hovered)
	layer.layer_unhovered.connect(_on_layer_unhovered)
	layer.layer_clicked.connect(_on_layer_clicked)


func on_model_position_changed(new_position: Vector3) -> void:
	if sprite_container:
		sprite_container.position = new_position

func on_model_visibility_changed(new_visible: bool) -> void:
	if sprite_container:
		sprite_container.visible = new_visible

func on_model_rotation_changed(new_rotation: Vector3) -> void:
	if sprite_container:
		sprite_container.rotation_degrees = new_rotation

func on_model_scale_changed(new_scale: Vector3) -> void:
	if sprite_container:
		sprite_container.scale = new_scale

## Layer signal handlers (for potential custom logic)
func _on_layer_hovered(_layer_name: String) -> void:
	# Layer already notified InteractionHandler, this is for custom logic
	pass


func _on_layer_unhovered(_layer_name: String) -> void:
	# Layer already notified InteractionHandler, this is for custom logic
	pass


func _on_layer_clicked(_layer_name: String, _event: InputEvent) -> void:
	# Custom click handling if needed
	pass


## Called when a layer's visibility changes (kept for compatibility)
func _on_layer_visibility_changed() -> void:
	# Clear hover state if the layer that became invisible was hovered
	if input_handler:
		for layer_name in layers:
			var layer = layers[layer_name]
			if not layer.is_layer_visible:
				input_handler.clear_hover_if_layer(layer)
	_update_viewport()

## Gets the controller for this displayable node
func get_controller():
	return controller


## Creates the input handler and attaches it to sprite_container
func _create_input_handler() -> void:
	if not sprite_container:
		return
	
	# Load the input handler class
	var InputHandlerClass = load("res://rengo/views/displayable_input_handler.gd")
	input_handler = InputHandlerClass.new()
	input_handler.displayable_node = self
	input_handler.name = "InputHandler_" + resource_name
	
	# Add as child to sprite_container
	sprite_container.add_child(input_handler)
