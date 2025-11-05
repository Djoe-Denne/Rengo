
## DisplayableNode - Base class for multi-layer displayable resources
## Extends ResourceNode with layer management and interaction routing
## Used as base class for Actor, and potentially Background, Props, etc.
class_name DisplayableNode
extends ResourceNode


## Dictionary of all layers { layer_name: DisplayableLayer }
var layers: Dictionary = {}

var sprite_container: Displayable = null

var pixels_per_cm: Vector2 = Vector2(1.0, 1.0)

## Reference to controller (for interaction callbacks)
var controller = null  # Controller reference

## Input handler for centralized mouse event coordination
var input_handler = null  # DisplayableInputHandler

## SubViewport system for rendering all layers to a single texture
var sub_viewport: SubViewport = null
var output_mesh: MeshInstance3D = null
var largest_layer_size: Vector2 = Vector2i(10, 10)  # Default size


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
	sub_viewport.disable_3d = true
	sub_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	

	sub_viewport.size = Vector2i(int(largest_layer_size.x), int(largest_layer_size.y))
	
	output_mesh = MeshInstance3D.new()
	output_mesh.name = "OutputMesh_" + resource_name
	output_mesh.mesh = QuadMesh.new()
	output_mesh.mesh.size = largest_layer_size

	
	# Create material with SubViewport texture
	var material = StandardMaterial3D.new()
	material.albedo_texture = sub_viewport.get_texture()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED

	output_mesh.material_override = material
	
	sprite_container.add_child(sub_viewport)
	sprite_container.add_child(output_mesh)


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


## Updates viewport size based on largest visible layer
func _update() -> void:
	if not sub_viewport:
		return
	
	# Find the largest layer dimensions
	var new_largest_mesh_size = Vector2i(10, 10)  # Minimum size
	var new_largest_viewport_size = Vector2i(10, 10)  # Minimum size

	for layer_name in layers:
		var layer = layers[layer_name]
		if not layer.is_layer_visible():
			continue
		
		# Get layer quad size
		var quad_size = layer.layer_size
		if quad_size.x * quad_size.y > new_largest_mesh_size.x * new_largest_mesh_size.y:
			new_largest_mesh_size = quad_size
			new_largest_viewport_size = layer.displayable.postprocess_sub_viewport.size
			
	sub_viewport.size.x = new_largest_viewport_size.x
	sub_viewport.size.y = new_largest_viewport_size.y

	# Update output mesh size
	output_mesh.mesh.size.x = new_largest_mesh_size.x
	output_mesh.mesh.size.y = new_largest_mesh_size.y

## Adds a new layer to this displayable node
## layer_def contains configuration: { "layer": name, "z": z_index, ... }
func add_layer(layer_name: String, layer_def: Dictionary = {}) -> DisplayableLayer:
	if layer_name in layers:
		push_warning("DisplayableNode: Layer '%s' already exists, returning existing" % layer_name)
		return layers[layer_name]
	
	# Create the layer
	var layer = DisplayableLayer.new(layer_name, layer_def)
	layer.parent_displayable = self
	
	sub_viewport.add_child(layer)
	
	# Store the layer
	layers[layer_name] = layer
	
	# Connect layer signals for interaction handling
	_connect_layer_signals(layer)

	return layer


## Gets a layer by name
func get_layer(layer_name: String) -> DisplayableLayer:
	return layers.get(layer_name, null)


## Removes a layer
func remove_layer(layer_name: String) -> void:
	if not layer_name in layers:
		return
	
	var layer = layers[layer_name]
	
	# Free the layer
	sub_viewport.remove_child(layer)
	_deconnect_layer_signals(layer)
	if layer.get_parent():
		layer.get_parent().remove_child(layer)
	layer.queue_free()
	layers.erase(layer_name)

	#sub_viewport.remove_child(TextureRect) #TODO: Remove this when we have a way to remove the TextureRect
	_update()


## Gets all visible layers
func get_visible_layers() -> Array:
	var visible = []
	for layer_name in layers:
		var layer = layers[layer_name]
		if layer.is_layer_visible():
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
	layer.layer_displayable_changed.connect(_on_layer_displayable_changed)


func _deconnect_layer_signals(layer: DisplayableLayer) -> void:
	if not layer:
		return
	layer.layer_hovered.disconnect(_on_layer_hovered)
	layer.layer_unhovered.disconnect(_on_layer_unhovered)
	layer.layer_clicked.disconnect(_on_layer_clicked)
	layer.layer_displayable_changed.disconnect(_on_layer_displayable_changed)

func on_model_position_changed(new_position: Vector3) -> void:
	if output_mesh:
		output_mesh.position = new_position

func on_model_visibility_changed(new_visible: bool) -> void:
	if output_mesh:
		output_mesh.visible = new_visible

func on_model_rotation_changed(new_rotation: Vector3) -> void:
	if output_mesh:
		output_mesh.rotation_degrees = new_rotation

func on_model_scale_changed(new_scale: Vector3) -> void:
	if output_mesh:
		output_mesh.scale = new_scale

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
			if not layer.is_layer_visible():
				input_handler.clear_hover_if_layer(layer)
	_update()

func _on_layer_displayable_changed(new_viewport: SubViewport) -> void:
	_update()

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
