
## DisplayableNode - Base class for multi-layer displayable resources
## Extends ResourceNode with layer management and interaction routing
## Used as base class for Actor, and potentially Background, Props, etc.
class_name DisplayableNode
extends ResourceNode


## Dictionary of all layers { layer_name: DisplayableLayer }
var layers: Dictionary = {}

## Character size in centimeters (set by director)
var character_size: Vector2 = Vector2(60, 170)

## Pixels per cm ratio (calculated from body layer)
var pixels_per_cm: Vector2 = Vector2(1.0, 1.0)

## Reference to controller (for interaction callbacks)
var controller = null  # Controller reference

## Input handler for centralized mouse event coordination
var input_handler = null  # DisplayableInputHandler

## Displayable for compositing all layers
var displayable: Displayable = null

## Output mesh showing final composite
var output_mesh: MeshInstance3D = null

## Dictionary to track sprites in compositing viewport { layer_name: Sprite2D }
var composite_sprites: Dictionary = {}


func _init(p_name: String = "") -> void:
	super(p_name)

func set_controller(p_controller: Controller) -> void:
	controller = p_controller

## Sets up the compositing system
func _setup_viewport() -> void:
	if displayable:
		return  # Already set up
	
	# Create Displayable for compositing
	displayable = Displayable.new(resource_name + "_composite")
	
	# Create output mesh
	output_mesh = MeshInstance3D.new()
	output_mesh.name = "OutputMesh_" + resource_name
	output_mesh.mesh = QuadMesh.new()
	output_mesh.mesh.size = character_size
	
	# Create material with Displayable texture
	var material = StandardMaterial3D.new()
	material.albedo_texture = displayable.get_output_viewport().get_texture()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	output_mesh.material_override = material
	
	output_mesh.add_child(displayable)


## Creates the scene node - should be overridden by subclasses
func create_scene_node(parent: Node) -> Node:
	# Set up compositing system
	_setup_viewport()
	
	# Create and attach input handler for centralized mouse event coordination
	_create_input_handler()
	
	parent.add_child(output_mesh)
	scene_node = parent

	# Instruct director to set up initial layers
	if controller.director and controller.model:
		controller.director.instruct(controller.model)

	return output_mesh


## Updates the composite viewport with all layer outputs
func _update() -> void:
	if not displayable:
		return
	
	# Find the largest layer to determine viewport size
	var max_viewport_size = character_size * pixels_per_cm * 1.25
	# Update compositing viewport size
	displayable.set_pass_size(max_viewport_size)

	_create_composition()
	
	# Update output mesh size to character size
	if output_mesh and output_mesh.mesh:
		output_mesh.mesh.size = character_size


func _create_composition() -> void:
	# Update or create sprites for each visible layer
	for layer_name in layers:
		var layer = layers[layer_name]
		
		if not layer.is_layer_visible():
			# Hide sprite if layer is invisible
			if layer_name in composite_sprites:
				composite_sprites[layer_name].visible = false
			continue
		
		# Get or create sprite for this layer
		var sprite: Sprite2D
		if layer_name in composite_sprites:
			sprite = composite_sprites[layer_name]
		else:
			sprite = Sprite2D.new()
			sprite.name = "Sprite_" + layer_name
			sprite.centered = false
			var input_viewport = displayable.get_input_viewport()
			if input_viewport:
				input_viewport.add_child(sprite)
			composite_sprites[layer_name] = sprite
		
		# Update sprite with layer's output texture
		sprite.texture = layer.displayable.get_output_viewport().get_texture()
		sprite.visible = true
		
		# Apply anchor positioning (convert from pixel coordinates)
		# Anchor is stored in layer_size metadata from theater_actor_director
		sprite.position = layer.position


## Adds a new layer to this displayable node
## layer_def contains configuration: { "layer": name, "z": z_index, "anchor": {x, y}, ... }
func add_layer(layer_name: String, layer_def: Dictionary = {}) -> DisplayableLayer:
	if layer_name in layers:
		push_warning("DisplayableNode: Layer '%s' already exists, returning existing" % layer_name)
		return layers[layer_name]
	
	# Create the layer
	var layer = DisplayableLayer.new(layer_name, layer_def)
	layer.parent_displayable = self
	
	# Add layer as direct child of DisplayableNode (not in viewport)
	output_mesh.add_child(layer)
	
	# Store the layer
	layers[layer_name] = layer
	
	# Store anchor information for compositing
	if "anchor" in layer_def:
		var anchor = layer_def.anchor
		layer.position = Vector2(anchor.get("x", 0.0), anchor.get("y", 0.0))
	
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
	
	# Disconnect signals
	_deconnect_layer_signals(layer)
	
	# Remove composite sprite if exists
	if layer_name in composite_sprites:
		var sprite = composite_sprites[layer_name]
		sprite.queue_free()
		composite_sprites.erase(layer_name)
	
	# Remove and free the layer
	if layer.get_parent():
		layer.get_parent().remove_child(layer)
	layer.queue_free()
	layers.erase(layer_name)
	
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

func _on_layer_displayable_changed(displayable: Displayable) -> void:
	_update()

## Gets the controller for this displayable node
func get_controller():
	return controller


## Creates the input handler and attaches it
func _create_input_handler() -> void:
	# Load the input handler class
	var InputHandlerClass = load("res://rengo/views/displayable_input_handler.gd")
	input_handler = InputHandlerClass.new()
	input_handler.displayable_node = self
	input_handler.name = "InputHandler_" + resource_name
	
	# Add as child
	output_mesh.add_child(input_handler)
