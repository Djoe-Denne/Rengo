
## DisplayableNode - Base class for multi-layer displayable resources
## Extends ResourceNode with layer management and interaction routing
## Used as base class for Actor, and potentially Background, Props, etc.
class_name DisplayableNode
extends ResourceNode


## Dictionary of all layers { layer_name: DisplayableLayer }
var layers: Dictionary[String, DisplayableLayer] = {}

var root_layers: Array[DisplayableLayer] = []

## Base size in centimeters (set by director)
var base_size: Vector2 = Vector2(100, 100)

var pixels_per_cm: Vector2 = Vector2(1.0, 1.0)

## Reference to controller (for interaction callbacks)
var controller = null  # Controller reference

## Input handler for centralized mouse event coordination
var input_handler: ViewportInput = null

## Displayable for compositing all layers
var displayable: Displayable = null

## Output mesh showing final composite
var output_mesh: MeshInstance3D = null

var collision_shape: CollisionShape3D = null

var max_padding: float = 0.0

## Dictionary to track sprites in compositing viewport { layer_name: Sprite2D }
var composite_sprites: Dictionary = {}

func _init(p_name: String = "") -> void:
	super(p_name)
	# Create Displayable for compositing
	displayable = Displayable.new(name + "_composite")
	
	# Connect to padding changes
	#displayable.padding_changed.connect(_on_node_padding_changed)
	
	# Create output mesh
	_create_output_mesh()

	add_child(displayable)

	activate_input_handler()

func activate_input_handler() -> void:
	if input_handler:
		input_handler.set_active(true)
	else:
		_create_input_handler()

func deactivate_input_handler() -> void:
	if input_handler:
		input_handler.set_active(false)

func set_controller(p_controller: Controller) -> void:
	controller = p_controller

## Creates the scene node - should be overridden by subclasses
func create_scene_node(parent: Node) -> Node:
	
	parent.add_child(self)
	scene_node = parent

	# Instruct director to set up initial layers
	if controller.director and controller.model:
		controller.director.instruct(controller.model)

	return self


## Adds a new layer to this displayable node
## layer_def contains configuration: { "layer": name, "z": z_index, "anchor": {x, y}, "parent": parent_name, ... }
func add_layer(layer_name: String, layer_def: Dictionary = {}) -> DisplayableLayer:
	if layer_name in layers:
		push_warning("DisplayableNode: Layer '%s' already exists, returning existing" % layer_name)
		return layers[layer_name]
	
	# Create the layer
	var layer = DisplayableLayer.new(layer_name, layer_def)
	
	# Store the layer in flat dictionary for easy lookup
	layers[layer_name] = layer
	
	# Store anchor information for compositing (relative to parent if any)
	if "anchor" in layer_def:
		var anchor = layer_def.anchor
		layer.position = Vector2(anchor.get("x", 0.0), anchor.get("y", 0.0))
	
	# Handle parent-child relationship
	if "parent" in layer_def:
		var parent_name = layer_def.parent
		var parent_layer = get_layer(parent_name)
		if parent_layer:
			# Add layer as child of parent in scene tree
			parent_layer.add_child(layer)
			# Add to parent's child list
			parent_layer.add_child_layer(layer)
		else:
			push_warning("DisplayableNode: Parent layer '%s' not found for layer '%s', adding as root" % [parent_name, layer_name])
			# Add as direct child if parent not found
			add_child(layer)
			root_layers.append(layer)
	else:
		# Add layer as direct child of DisplayableNode (root layer)
		add_child(layer)
		root_layers.append(layer)
	# Connect layer signals for interaction handling
	_connect_layer_signals(layer)

	#displayable.add_input_sprite(layer.get_output_sprite())
	return layer


## Gets a layer by name
func get_layer(layer_name: String) -> DisplayableLayer:
	return layers.get(layer_name, null)
	
func get_layers() -> Array[DisplayableLayer]:
	return layers.values()

## Gets only root layers (layers without parent)
func get_root_layers() -> Array[DisplayableLayer]:
	var root_layers: Array[DisplayableLayer] = []
	for layer in layers.values():
		if layer.parent_layer == null:
			root_layers.append(layer)
	return root_layers

## Gets all visible layers
func get_visible_layers() -> Array:
	var visible = []
	for layer_name in layers:
		var layer = layers[layer_name]
		if layer.is_layer_visible():
			visible.append(layer)
	return visible
## Gets the controller for this displayable node
func get_controller():
	return controller


func recompose(recompose_all: bool = true) -> void:
	var padding_multiplier = displayable.get_padding_multiplier()
	for layer in layers.values():
		if recompose_all:
			layer.recompose()
		if layer in root_layers:
			padding_multiplier = max(padding_multiplier, layer.displayable.get_padding_multiplier())
	displayable.recompose()

	output_mesh.mesh.size = base_size * padding_multiplier
	collision_shape.shape = output_mesh.mesh.create_convex_shape()

func _create_output_mesh() -> void:
	output_mesh = MeshInstance3D.new()
	output_mesh.name = "OutputMesh_" + name
	output_mesh.mesh = QuadMesh.new()
	
	# Create material with Displayable texture
	var material = StandardMaterial3D.new()
	material.albedo_texture = displayable.get_output_pass().get_output_texture().get_texture()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	output_mesh.material_override = material

	# Create Area3D and CollisionShape3D
	var area = Area3D.new()
	area.name = "Area3D_" + name
	collision_shape = CollisionShape3D.new()
	collision_shape.debug_color = Color.TRANSPARENT
	collision_shape.shape = ConvexPolygonShape3D.new()

	area.add_child(collision_shape)

	output_mesh.add_child(area)
	add_child(output_mesh)

## Creates the input handler and attaches it
func _create_input_handler() -> void:
	# Load the input handler class
	var area = output_mesh.get_node("Area3D_" + name)
	var viewport = displayable.get_input_pass().get_sub_viewport()
	input_handler = ViewportInput.new(self, viewport, output_mesh, area)
	input_handler.name = "InputHandler_" + name
	input_handler.set_active(true)
	add_child(input_handler)


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
	layer.layer_visibility_changed.connect(_on_layer_visibility_changed)
	layer.layer_changed.connect(_on_layer_changed)

func _deconnect_layer_signals(layer: DisplayableLayer) -> void:
	if not layer:
		return
	
	print("DisplayableNode: deconnecting layer signals for layer '%s'" % layer.layer_name)
	layer.layer_hovered.disconnect(_on_layer_hovered)
	layer.layer_unhovered.disconnect(_on_layer_unhovered)
	layer.layer_clicked.disconnect(_on_layer_clicked)
	layer.layer_visibility_changed.disconnect(_on_layer_visibility_changed)
	layer.layer_changed.disconnect(_on_layer_changed)

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
func _on_layer_hovered(layer: DisplayableLayer) -> void:
	InteractionHandler.on_hover_enter(controller, layer.layer_name)

func _on_layer_unhovered(layer: DisplayableLayer) -> void:
	InteractionHandler.on_hover_exit(controller, layer.layer_name)

func _on_layer_clicked(layer: DisplayableLayer, event: InputEvent) -> void:
	pass


## Called when a layer's visibility changes (kept for compatibility)
func _on_layer_visibility_changed(layer: DisplayableLayer) -> void:
	pass

func _on_layer_changed(layer: DisplayableLayer) -> void:
	recompose(false)
