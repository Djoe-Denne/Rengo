## Pass - Single node in the viewport pass chain (doubly-linked list)
class_name Pass
extends RefCounted

var viewport: SubViewport
var sprite: Sprite2D
var previous: Pass = null
var next: Pass = null

func _init(p_viewport: SubViewport, p_sprite: Sprite2D):
	viewport = p_viewport
	sprite = p_sprite
