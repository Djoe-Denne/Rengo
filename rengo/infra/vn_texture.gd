class_name VNTexture
extends RefCounted

var _position: Vector2 = Vector2.ZERO
var _texture: Texture2D = null
var _source = null
var _scale: Vector2 = Vector2.ONE
var _children: Array[VNTexture] = []
var _padding: Vector2 = Vector2.ZERO
var _layer_id: String = ""

func _init(p_texture: Texture2D, p_position: Vector2 = Vector2.ZERO) -> void:
	_texture = p_texture
	_position = p_position

func get_position() -> Vector2:
	return _position

func set_position(p_position: Vector2) -> void:
	_position = p_position

func get_texture() -> Texture2D:
	return _texture

func set_texture(p_texture: Texture2D) -> void:
	_texture = p_texture

func get_source() -> Node:
	return _source

func set_source(p_source: Node) -> void:
	_source = p_source

func get_scale() -> Vector2:
	return _scale

func set_scale(p_scale: Vector2) -> void:
	_scale = p_scale

func add_child_texture(child: VNTexture) -> void:
	if child and not child in _children:
		_children.append(child)

func get_children() -> Array[VNTexture]:
	return _children

func has_children() -> bool:
	return _children.size() > 0

func get_padding() -> Vector2:
	return _padding

func set_padding(p_padding: Vector2) -> void:
	_padding = p_padding

func get_layer_id() -> String:
	return _layer_id

func set_layer_id(p_layer_id: String) -> void:
	_layer_id = p_layer_id
