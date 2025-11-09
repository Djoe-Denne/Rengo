
## DisplayableNode - Base class for multi-layer displayable resources
## Extends ResourceNode with layer management and interaction routing
## Used as base class for Actor, and potentially Background, Props, etc.
class_name DisplayableNode
extends ResourceNode


## Dictionary of all layers { layer_name: DisplayableLayer }
var layers: Dictionary[String, DisplayableLayer] = {}

## Base size in centimeters (set by director)
var base_size: Vector2 = Vector2(100, 100)

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

var max_padding: float = 0.0

## Dictionary to track sprites in compositing viewport { layer_name: Sprite2D }
var composite_sprites: Dictionary = {}

func _init(p_name: String = "") -> void:
	super(p_name)
	# Create Displayable for compositing
	displayable = Displayable.new(resource_name + "_composite")
	
	# Connect to padding changes
	#displayable.padding_changed.connect(_on_node_padding_changed)
	
	# Create output mesh
	output_mesh = MeshInstance3D.new()
	output_mesh.name = "OutputMesh_" + resource_name
	output_mesh.mesh = QuadMesh.new()
	
	# Create material with Displayable texture
	var material = StandardMaterial3D.new()
	material.albedo_texture = displayable.get_output_pass().get_output_texture().get_texture()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	output_mesh.material_override = material

	add_child(output_mesh)
	add_child(displayable)
	
func set_controller(p_controller: Controller) -> void:
	controller = p_controller

## Creates the scene node - should be overridden by subclasses
func create_scene_node(parent: Node) -> Node:
	
	# Create and attach input handler for centralized mouse event coordination
	_create_input_handler()
	
	parent.add_child(self)
	scene_node = parent

	# Instruct director to set up initial layers
	if controller.director and controller.model:
		controller.director.instruct(controller.model)

	return self


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
	add_child(layer)
	
	# Store the layer
	layers[layer_name] = layer
	
	# Store anchor information for compositing
	if "anchor" in layer_def:
		var anchor = layer_def.anchor
		layer.position = Vector2(anchor.get("x", 0.0), anchor.get("y", 0.0))
	
	# Connect layer signals for interaction handling
	_connect_layer_signals(layer)

	#displayable.add_input_sprite(layer.get_output_sprite())
	return layer


## Gets a layer by name
func get_layer(layer_name: String) -> DisplayableLayer:
	return layers.get(layer_name, null)
	
func get_layers() -> Array[DisplayableLayer]:
	return layers.values()

func get_layers_at_uv(uv: Vector2) -> Array[DisplayableLayer]:
	var layers_at_uv: Array[DisplayableLayer] = []

	var clickables = displayable.clickables_at_uv(uv)
	for clickable in clickables:
		if clickable is NodePath:
			var layer = get_node(clickable) as DisplayableLayer
			print("DisplayableNode: layer at uv: ", layer.layer_name)
			layers_at_uv.append(layer)

	return layers_at_uv


func recompose() -> void:
	for layer in layers.values():
		layer.recompose()
	displayable.recompose()

	output_mesh.mesh.size = base_size * displayable.get_padding_multiplier()

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

	print("DisplayableNode: connecting layer signals for layer '%s'" % layer.layer_name)
	
	# Connect layer signals for potential custom handling
	# (The layer itself handles direct InteractionHandler calls in its signal handlers)
	layer.layer_hovered.connect(_on_layer_hovered)
	layer.layer_unhovered.connect(_on_layer_unhovered)
	layer.layer_clicked.connect(_on_layer_clicked)


func _deconnect_layer_signals(layer: DisplayableLayer) -> void:
	if not layer:
		return
	
	print("DisplayableNode: deconnecting layer signals for layer '%s'" % layer.layer_name)
	layer.layer_hovered.disconnect(_on_layer_hovered)
	layer.layer_unhovered.disconnect(_on_layer_unhovered)
	layer.layer_clicked.disconnect(_on_layer_clicked)

	
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
