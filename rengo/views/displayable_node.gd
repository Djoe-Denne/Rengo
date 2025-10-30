## DisplayableNode - Base class for multi-layer displayable resources
## Extends ResourceNode with layer management, collision handling, and interaction routing
## Used as base class for Actor, and potentially Background, Props, etc.
class_name DisplayableNode
extends ResourceNode

## Dictionary of all layers { layer_name: DisplayableLayer }
var layers: Dictionary = {}

## Root interaction area (merged collision of all visible layers)
var root_interaction_area: Area3D = null

## Dictionary tracking all interaction areas { "root": Area3D, layer_name: Area3D }
var interaction_areas: Dictionary = {}

## Container node that holds all layers (typically Node3D)
var sprite_container: Node = null

## Reference to controller (for interaction callbacks)
var controller = null  # Controller reference


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
	
	# Store layer's interaction area
	if layer.interaction_area:
		interaction_areas[layer_name] = layer.interaction_area
	
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
	
	# Clean up interaction area reference
	interaction_areas.erase(layer_name)
	
	# Free the layer
	layer.queue_free()
	layers.erase(layer_name)
	
	# Rebuild root collision since a layer was removed
	rebuild_root_collision()


## Gets all visible layers
func get_visible_layers() -> Array:
	var visible = []
	for layer_name in layers:
		var layer = layers[layer_name]
		if layer.is_layer_visible:
			visible.append(layer)
	return visible


## Rebuilds the root collision area from all visible layers
func rebuild_root_collision() -> void:
	# Remove old root collision area
	if root_interaction_area:
		if root_interaction_area.get_parent():
			root_interaction_area.get_parent().remove_child(root_interaction_area)
		root_interaction_area.queue_free()
		root_interaction_area = null
	
	# Get all visible layer areas
	var visible_layer_areas = []
	for layer_name in layers:
		var layer = layers[layer_name]
		if layer.is_layer_visible and layer.interaction_area:
			visible_layer_areas.append(layer.interaction_area)
	
	# Merge into root area
	var CollisionHelper = load("res://core-game/input/collision_helper.gd")
	root_interaction_area = CollisionHelper.merge_area3d_shapes(visible_layer_areas)
	
	if root_interaction_area and sprite_container:
		sprite_container.add_child(root_interaction_area)
		
		# Connect root area signals
		root_interaction_area.input_event.connect(_on_root_input_event)
		root_interaction_area.mouse_entered.connect(_on_root_mouse_entered)
		root_interaction_area.mouse_exited.connect(_on_root_mouse_exited)
		
		# Store in interaction_areas
		interaction_areas["root"] = root_interaction_area


## Called when a layer's visibility changes
func _on_layer_visibility_changed() -> void:
	rebuild_root_collision()


## Connects layer signals to interaction system
func _connect_layer_signals(layer: DisplayableLayer) -> void:
	if not layer:
		return
	
	# Connect layer signals for potential custom handling
	# (The layer itself handles direct InteractionHandler calls in its signal handlers)
	layer.layer_hovered.connect(_on_layer_hovered)
	layer.layer_unhovered.connect(_on_layer_unhovered)
	layer.layer_clicked.connect(_on_layer_clicked)


## Root area signal handlers
func _on_root_input_event(_camera: Node, _event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	# Root input events handled by InteractionHandler via custom actions
	pass


func _on_root_mouse_entered() -> void:
	# Notify InteractionHandler for root area (layer_name = null)
	if controller:
		InteractionHandler.on_hover_enter(controller, null)


func _on_root_mouse_exited() -> void:
	# Notify InteractionHandler for root area (layer_name = null)
	if controller:
		InteractionHandler.on_hover_exit(controller, null)


## Layer signal handlers (for potential custom logic)
func _on_layer_hovered(layer_name: String) -> void:
	# Layer already notified InteractionHandler, this is for custom logic
	pass


func _on_layer_unhovered(layer_name: String) -> void:
	# Layer already notified InteractionHandler, this is for custom logic
	pass


func _on_layer_clicked(layer_name: String, event: InputEvent) -> void:
	# Custom click handling if needed
	pass


## Gets the controller for this displayable node
func get_controller():
	return controller


## Creates the scene node - should be overridden by subclasses
## Subclasses should create sprite_container and call parent's method
func create_scene_node(parent: Node) -> Node:
	# Subclasses should override this and create sprite_container
	# Then build initial root collision
	if sprite_container:
		parent.add_child(sprite_container)
		scene_node = sprite_container
		rebuild_root_collision()
	
	return sprite_container

