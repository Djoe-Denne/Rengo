class_name TransformableTexture
extends RefCounted

var _position: Vector2 = Vector2.ZERO
var _texture: Texture2D = null
var _source = null
var _scale: Vector2 = Vector2.ONE

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
