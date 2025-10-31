## DisplayableNode - Base class for multi-layer displayable resources
## Extends ResourceNode with layer management and interaction routing
## Used as base class for Actor, and potentially Background, Props, etc.
class_name DisplayableNode
extends ResourceNode

## Dictionary of all layers { layer_name: DisplayableLayer }
var layers: Dictionary = {}

## Container node that holds all layers (typically Node3D)
var sprite_container: Node = null

## Reference to controller (for interaction callbacks)
var controller = null  # Controller reference

## Director that handles visual updates for this displayable
var director: Director = null

## Machinist that handles shader effects for this displayable
var machinist: Machinist = null

## Input handler for centralized mouse event coordination
var input_handler = null  # DisplayableInputHandler


func _init(p_name: String = "") -> void:
	super(p_name)


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
	
	# Add to sprite container if it exists
	if sprite_container:
		sprite_container.add_child(layer)
	
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
	
	# Remove from sprite container
	if layer.get_parent():
		layer.get_parent().remove_child(layer)
	
	# Free the layer
	layer.queue_free()
	layers.erase(layer_name)


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


## Gets the controller for this displayable node
func get_controller():
	return controller


## Creates the scene node - should be overridden by subclasses
## Subclasses should create sprite_container and call parent's method
func create_scene_node(parent: Node) -> Node:
	# Subclasses should override this and create sprite_container
	if sprite_container:
		# Create and attach input handler for centralized mouse event coordination
		_create_input_handler()
		
		parent.add_child(sprite_container)
		scene_node = sprite_container
	
	return sprite_container


## Creates the input handler and attaches it to sprite_container
func _create_input_handler() -> void:
	if not sprite_container:
		return
	
	# Load the input handler class
	var InputHandlerClass = load("res://rengo/views/displayable_input_handler.gd")
	input_handler = InputHandlerClass.new()
	input_handler.displayable_node = self
	input_handler.name = "InputHandler"
	
	# Add as child to sprite_container
	sprite_container.add_child(input_handler)
