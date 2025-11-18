class_name VNSprite
extends Sprite2D

var _texture: VNTexture = null
var _time_before_taking_input: float = 0.0

func _init(p_texture: VNTexture, p_position: Vector2 = Vector2.ZERO) -> void:
	_texture = p_texture
	position = p_position
	texture = p_texture.get_texture()
	if _texture.get_source() and _texture.get_source() is DisplayableLayer:
		name = "Sprite_" + _texture.get_source().name

func _ready() -> void:
	set_time_before_taking_input(100)

func set_time_before_taking_input(p_time: float) -> void:
	_time_before_taking_input = p_time + Time.get_ticks_msec()

func get_transformable_texture() -> VNTexture:
	return _texture

func to_centered_position(p_texture: VNTexture) -> Vector2:
	var centered_position = texture.get_size() / 2 - p_texture.get_position() - (p_texture.get_padding() / 2.0)
	return centered_position

func _input(event: InputEvent) -> void:
	if Time.get_ticks_msec() < _time_before_taking_input:
		return

	if event is InputEventMouse:
		var mouse_event = event as InputEventMouse
		var local_position = to_local(mouse_event.position)
		var texture_size = texture.get_size()
		var texture_position = position
		var texture_rect = Rect2(Vector2.ZERO, texture_size)
		var source = _texture.get_source()
		if source and source is DisplayableLayer:
			print("input event: ", event, "source: ", source)
			set_time_before_taking_input(100)
			if source.is_visible():
				if texture_rect.has_point(local_position):
					if CollisionHelper.is_hover_non_transparent(texture, local_position):
						source.set_hovered(true)
						return;
					
			source.set_hovered(false)

					
