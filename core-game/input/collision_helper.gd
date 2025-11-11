## CollisionHelper - Utility for raycast-based collision with texture alpha checking
## Provides methods for 2-step collision: raycast to quad, then alpha check
class_name CollisionHelper
extends RefCounted


## Performs a raycast from camera through mouse position to check quad intersection
## Returns a Dictionary with hit info: { "hit": bool, "position": Vector3, "uv": Vector2 }
static func raycast_to_quad(camera: Camera3D, mouse_pos: Vector2, quad_transform: Transform3D, quad_size: Vector2) -> Dictionary:
	if not camera:
		push_error("CollisionHelper: camera is null")
		return {"hit": false}
	
	# Get ray from camera through mouse position
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)
	
	# Create a plane from the quad's transform
	# The quad faces along the -Z axis in local space (standard QuadMesh orientation)
	var plane_normal = quad_transform.basis.z  # Z axis points out from quad
	var plane_point = quad_transform.origin
	var plane = Plane(plane_normal, plane_point.dot(plane_normal))
	
	# Intersect ray with plane
	var hit_position = plane.intersects_ray(ray_origin, ray_direction)
	
	if hit_position == null:
		return {"hit": false}
	
	# Convert world position to local quad space
	var local_hit = quad_transform.affine_inverse() * hit_position
	
	# Check if hit is within quad bounds
	var half_width = quad_size.x / 2.0
	var half_height = quad_size.y / 2.0
	
	if abs(local_hit.x) > half_width or abs(local_hit.y) > half_height:
		return {"hit": false}
	
	return {
		"hit": true,
		"position": hit_position
	}


static func is_hover_non_transparent(texture: Texture2D, coords: Vector2) -> bool:
	if not texture:
		push_warning("CollisionHelper: texture is null")
		return false

	var image = texture.get_image()
	return image.get_pixel(int(coords.x), int(coords.y)).a > 0.5