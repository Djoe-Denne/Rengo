## CollisionHelper - Utility for creating collision shapes from meshes and textures
## Provides methods to generate Area2D/Area3D collision shapes
class_name CollisionHelper
extends RefCounted


## Creates an Area3D with collision shapes for a 3D actor (theater mode)
## Analyzes all MeshInstance3D children and creates BoxShape3D for each quad
static func create_area3d_for_actor(sprite_container: Node3D) -> Area3D:
	if not sprite_container:
		push_error("CollisionHelper: sprite_container is null")
		return null
	
	var area = Area3D.new()
	area.name = "InteractionArea3D"
	area.input_ray_pickable = true
	
	# Find all MeshInstance3D children
	for child in sprite_container.get_children():
		if child is MeshInstance3D:
			var mesh_instance = child as MeshInstance3D
			
			# Create collision shape for this mesh
			var collision_shape = _create_collision_for_mesh(mesh_instance)
			if collision_shape:
				area.add_child(collision_shape)
	
	return area


## Creates an Area2D with collision shapes for a 2D actor (movie mode)
## Uses texture alpha to create polygon collision shape
static func create_area2d_for_sprite(sprite: Sprite2D) -> Area2D:
	if not sprite:
		push_error("CollisionHelper: sprite is null")
		return null
	
	var area = Area2D.new()
	area.name = "InteractionArea2D"
	area.input_pickable = true
	
	# Create collision polygon from sprite texture
	if sprite.texture:
		var collision_polygon = _create_polygon_from_texture(sprite.texture, sprite.centered)
		if collision_polygon:
			area.add_child(collision_polygon)
	
	return area


## Creates a CollisionShape3D for a MeshInstance3D quad
static func _create_collision_for_mesh(mesh_instance: MeshInstance3D) -> CollisionShape3D:
	if not mesh_instance.mesh:
		return null
	
	var collision_shape = CollisionShape3D.new()
	collision_shape.name = "Collision_" + mesh_instance.name
	
	# Copy position from mesh instance (for layering)
	collision_shape.position = mesh_instance.position
	
	# For QuadMesh, create a BoxShape3D matching the quad size
	if mesh_instance.mesh is QuadMesh:
		var quad_mesh = mesh_instance.mesh as QuadMesh
		var box_shape = BoxShape3D.new()
		
		# QuadMesh size is 2D (x, y), set box to be very thin (0.1cm in z)
		box_shape.size = Vector3(quad_mesh.size.x, quad_mesh.size.y, 0.1)
		collision_shape.shape = box_shape
	
	# For other mesh types, try to create a box from AABB
	else:
		var aabb = mesh_instance.mesh.get_aabb()
		var box_shape = BoxShape3D.new()
		box_shape.size = aabb.size
		collision_shape.position += aabb.get_center()
		collision_shape.shape = box_shape
	
	return collision_shape


## Creates a CollisionPolygon2D from a texture's alpha channel
static func _create_polygon_from_texture(texture: Texture2D, centered: bool) -> CollisionPolygon2D:
	var image = texture.get_image()
	if not image:
		push_warning("CollisionHelper: Cannot get image from texture")
		return null
	
	# Create bitmap from image alpha channel
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(image)
	
	# Generate polygon from opaque pixels
	var polygons = bitmap.opaque_to_polygons(Rect2(Vector2.ZERO, image.get_size()))
	
	if polygons.size() == 0:
		push_warning("CollisionHelper: No polygons generated from texture")
		return null
	
	# Use the first (and typically largest) polygon
	var polygon = polygons[0]
	
	# Center the polygon if sprite is centered
	if centered:
		var size = image.get_size()
		var offset = -size / 2.0
		for i in range(polygon.size()):
			polygon[i] += offset
	
	var collision_polygon = CollisionPolygon2D.new()
	collision_polygon.polygon = polygon
	
	return collision_polygon


## Updates an existing Area3D's collision shapes (when meshes change)
static func update_area3d_collision(area: Area3D, sprite_container: Node3D) -> void:
	if not area or not sprite_container:
		return
	
	# Remove all existing collision shapes
	for child in area.get_children():
		if child is CollisionShape3D:
			child.queue_free()
	
	# Recreate collision shapes
	for child in sprite_container.get_children():
		if child is MeshInstance3D:
			var mesh_instance = child as MeshInstance3D
			var collision_shape = _create_collision_for_mesh(mesh_instance)
			if collision_shape:
				area.add_child(collision_shape)


## Updates an existing Area2D's collision polygon (when texture changes)
static func update_area2d_collision(area: Area2D, sprite: Sprite2D) -> void:
	if not area or not sprite:
		return
	
	# Remove existing collision polygon
	for child in area.get_children():
		if child is CollisionPolygon2D:
			child.queue_free()
	
	# Recreate collision polygon
	if sprite.texture:
		var collision_polygon = _create_polygon_from_texture(sprite.texture, sprite.centered)
		if collision_polygon:
			area.add_child(collision_polygon)

