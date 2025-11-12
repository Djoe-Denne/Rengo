## DisplayableLayer - Self-contained layer with mesh, texture, and raycast-based collision
## Each layer manages its own visibility, input handling, and collision detection
class_name DisplayableLayer
extends Node2D

## Custom signals for interaction events
signal layer_hovered(layer: DisplayableLayer)
signal layer_unhovered(layer: DisplayableLayer)
signal layer_clicked(layer: DisplayableLayer, event: InputEvent)
signal layer_visibility_changed(layer: DisplayableLayer)
signal layer_changed(layer: DisplayableLayer)

var hovered: bool = false

## Layer identifier
var layer_name: String = ""

var layer_size: Vector2 = Vector2(0, 0)

## Parent layer (null if root layer)
var parent_layer: DisplayableLayer = null

## Child layers
var child_layers: Array[DisplayableLayer] = []

## Cached alpha mask for performance
var texture_image: Image = null

## texture path for comparison
var texture_path: String = ""

var displayable: Displayable = null

var layer_definition: Dictionary = {}


func _init(p_layer_name: String = "", p_layer_definition: Dictionary = {}) -> void:
	layer_name = p_layer_name
	name = "Layer_" + layer_name
	layer_definition = p_layer_definition

	displayable = Displayable.new(layer_name)
	
	# Displayable stays at origin, scaling/positioning handled elsewhere
	displayable.position = Vector2.ZERO
	displayable.scale = Vector2.ONE
	
	if "z" in layer_definition:
		z_index = layer_definition.z

	#displayable.displayable_changed.connect(_on_displayable_changed)
	#displayable.padding_changed.connect(_on_padding_changed)

	add_child(displayable)

func _ready() -> void:
	# Input processing now handled by DisplayableNode parent
	pass


func set_size(p_size: Vector2) -> void:
	layer_size = p_size

## Sets the texture and updates the input sprite
func set_texture(tex: Texture2D) -> void:
	if not tex:
		push_warning("DisplayableLayer: Attempted to set null texture on layer '%s'" % layer_name)
		return
	
	# Store image for collision detection
	texture_image = tex.get_image()
	

## Controls layer visibility
func set_layer_visible(p_visible: bool) -> void:
	displayable.set_visible(p_visible)
	layer_visibility_changed.emit(self)

func is_layer_visible() -> bool:
	return displayable.is_visible()

func is_hovered() -> bool:
	return hovered

func set_hovered(p_hovered: bool) -> void:
	if hovered == p_hovered:
		return
	hovered = p_hovered
	if p_hovered:
		layer_hovered.emit(self)
	else:
		layer_unhovered.emit(self)

func set_parent_layer(parent: DisplayableLayer) -> void:
	parent_layer = parent

func add_child_layer(child: DisplayableLayer) -> void:
	if child and not child in child_layers:
		child_layers.append(child)
		child.set_parent_layer(self)

func get_child_layers() -> Array[DisplayableLayer]:
	return child_layers

func get_output_texture() -> VNTexture:
	var texture = displayable.get_output_pass().get_output_texture()
	texture.set_position(position)
	texture.set_source(self)
	
	# Add child textures to create hierarchy
	for child_layer in child_layers:
		if child_layer.is_layer_visible():
			var child_texture = child_layer.get_output_texture()
			texture.add_child_texture(child_texture)
	
	return texture

func recompose() -> void:
	displayable.recompose()
	layer_changed.emit(self)
