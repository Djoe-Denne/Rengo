## Helper class for normalized coordinate system
## Converts normalized [0.0-1.0] coordinates to screen pixels
class_name NormalizedPosition
extends RefCounted

## Creates a Vector3 with normalized coordinates
static func create(x: float, y: float, z: float = 0.0) -> Vector3:
	return Vector3(
		clamp(x, 0.0, 1.0),
		clamp(y, 0.0, 1.0),
		z
	)


## Creates a position anchored to the left-bottom
## x: distance from left edge (0.0-1.0)
## y: distance from bottom edge (0.0-1.0)
static func left_bottom(x: float, y: float, z: float = 0.0) -> Vector3:
	return create(x, 1.0 - y, z)


## Creates a position anchored to the right-bottom
## x: distance from right edge (0.0-1.0)
## y: distance from bottom edge (0.0-1.0)
static func right_bottom(x: float, y: float, z: float = 0.0) -> Vector3:
	return create(1.0 - x, 1.0 - y, z)


## Creates a position anchored to the left-top
## x: distance from left edge (0.0-1.0)
## y: distance from top edge (0.0-1.0)
static func left_top(x: float, y: float, z: float = 0.0) -> Vector3:
	return create(x, y, z)


## Creates a position anchored to the right-top
## x: distance from right edge (0.0-1.0)
## y: distance from top edge (0.0-1.0)
static func right_top(x: float, y: float, z: float = 0.0) -> Vector3:
	return create(1.0 - x, y, z)


## Creates a centered position
## x_offset: offset from center horizontally (-0.5 to 0.5, typically)
## y_offset: offset from center vertically (-0.5 to 0.5, typically)
static func center(x_offset: float = 0.0, y_offset: float = 0.0, z: float = 0.0) -> Vector3:
	return create(0.5 + x_offset, 0.5 + y_offset, z)


## Converts a normalized Vector3 to pixel coordinates
## viewport_size: the size of the viewport in pixels
static func to_pixels(normalized_pos: Vector3, viewport_size: Vector2) -> Vector2:
	return Vector2(
		normalized_pos.x * viewport_size.x,
		normalized_pos.y * viewport_size.y
	)


## Converts pixel coordinates to normalized Vector3
## pixel_pos: position in pixels
## viewport_size: the size of the viewport in pixels
static func from_pixels(pixel_pos: Vector2, viewport_size: Vector2, z: float = 0.0) -> Vector3:
	return Vector3(
		pixel_pos.x / viewport_size.x if viewport_size.x > 0 else 0.0,
		pixel_pos.y / viewport_size.y if viewport_size.y > 0 else 0.0,
		z
	)

