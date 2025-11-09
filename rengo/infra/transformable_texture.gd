class_name TransformableTexture
extends RefCounted

var _position: Vector2 = Vector2.ZERO
var _texture: Texture2D = null

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
