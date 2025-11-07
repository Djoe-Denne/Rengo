## Pass - Single node in the viewport pass chain (doubly-linked list)
class_name Pass
extends RefCounted

var _viewport: SubViewport
var _sprites: Array[Sprite2D] = []
var _previous: Pass = null
var _next: Pass = null

func _init(p_viewport: SubViewport, p_sprite: Sprite2D):
	_viewport = p_viewport
	_sprites.append(p_sprite)

func add_sprite(p_sprite: Sprite2D) -> void:
	_sprites.append(p_sprite)
	_viewport.add_child(p_sprite)

func get_viewport() -> SubViewport:
	return _viewport

func get_sprites() -> Array[Sprite2D]:
	return _sprites

func get_sprite(p_index: int) -> Sprite2D:
	if p_index < 0 or p_index >= _sprites.size():
		return null
	return _sprites[p_index]

func get_previous() -> Pass:
	return _previous

func get_next() -> Pass:
	return _next

func set_previous(p_previous: Pass) -> void:
	_previous = p_previous

func set_next(p_next: Pass) -> void:
	_next = p_next
