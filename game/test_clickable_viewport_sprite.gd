extends Sprite2D

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			print("Sprite: " + name + " clicked at position: ", mouse_event.position)
			# print clicked sprite pixel coordinates
			print("Sprite pixel coordinates: ",  to_local(mouse_event.position))
