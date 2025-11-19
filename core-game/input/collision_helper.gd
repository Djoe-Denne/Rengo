## CollisionHelper - Utility for raycast-based collision with texture alpha checking
## Provides methods for 2-step collision: raycast to quad, then alpha check
class_name CollisionHelper
extends RefCounted


static func is_hover_non_transparent(texture: Texture2D, coords: Vector2) -> bool:
	if not texture:
		push_warning("CollisionHelper: texture is null")
		return false

	var image = texture.get_image()
	return image.get_pixel(int(coords.x), int(coords.y)).a > 0.5