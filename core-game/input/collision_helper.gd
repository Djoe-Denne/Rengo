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


## Checks if the texture alpha at given UV coordinate exceeds the threshold
## uv: Vector2 in 0-1 range
## threshold: Alpha value threshold (0.0-1.0)
## Returns true if alpha > threshold
static func check_texture_alpha_at_uv(texture: Image, viewport_mouse_pos: Vector2, threshold: float = 0.5) -> bool:
	if not texture:
		push_warning("CollisionHelper: texture is null")
		return false
	
	# Convert viewport mouse position to UV
	var uv = viewport_mouse_pos
	# Clamp UV to valid range
	uv.x = clamp(uv.x, 0.0, 1.0)
	uv.y = clamp(uv.y, 0.0, 1.0)
	
	# Convert UV to pixel coordinates
	var texture_size = texture.get_size()
	var pixel_x = int(uv.x * texture_size.x)
	var pixel_y = int(uv.y * texture_size.y)
	
	# Clamp to valid pixel range (prevent edge case overflow)
	pixel_x = clamp(pixel_x, 0, texture_size.x - 1)
	pixel_y = clamp(pixel_y, 0, texture_size.y - 1)
	
	# Get pixel color and check alpha
	var pixel_color = texture.get_pixel(pixel_x, pixel_y)
	
	return pixel_color.a > threshold


## Converts a 3D world hit position to UV coordinates in quad space
## This is a utility function if you already have the hit position from another raycast
static func get_uv_from_local_hit(hit_position: Vector3, quad_transform: Transform3D, quad_size: Vector2) -> Vector2:
	# Convert world position to local quad space
	var local_hit = quad_transform.affine_inverse() * hit_position
	
	# Convert local position to UV coordinates (0-1 range)
	var uv = Vector2(
		(local_hit.x / quad_size.x) + 0.5,
		(-local_hit.y / quad_size.y) + 0.5
	)
	
	return uv
