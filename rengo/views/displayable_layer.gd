## DisplayableLayer - Self-contained layer with mesh, texture, and raycast-based collision
## Each layer manages its own visibility, input handling, and collision detection
class_name DisplayableLayer
extends Node3D

## Custom signals for interaction events
signal layer_hovered(layer_name: String)
signal layer_unhovered(layer_name: String)
signal layer_clicked(layer_name: String, event: InputEvent)

## Layer identifier
var layer_name: String = ""

## The visual mesh instance
var mesh_instance: MeshInstance3D = null

## Current texture
var texture: Texture2D = null

## Layer visibility (separate from Node3D.visible for control)
var is_layer_visible: bool = true

## Z-index for layer ordering
var z_index: float = 0.0

## Reference to parent displayable node (for callbacks)
var parent_displayable = null  # DisplayableNode

## Alpha threshold for collision detection (configurable per layer)
var alpha_threshold: float = 0.5

## Track mouse hover state
var is_mouse_over: bool = false

## Cached alpha mask for performance
var alpha_mask: Image = null

## Debug visualization
var debug_outline: MeshInstance3D = null
var debug_enabled: bool = false


func _init(p_layer_name: String = "") -> void:
	layer_name = p_layer_name
	name = "Layer_" + layer_name
	
	# Create the mesh instance as a child
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Mesh_" + layer_name
	add_child(mesh_instance)


func _ready() -> void:
	# Input processing now handled by DisplayableNode parent
	pass


## Sets the texture and updates the quad mesh
func set_texture(tex: Texture2D, quad_size: Vector2 = Vector2(100, 100)) -> void:
	if not tex:
		push_warning("DisplayableLayer: Attempted to set null texture on layer '%s'" % layer_name)
		return
	
	texture = tex
	
	# Cache the alpha mask for efficient collision detection
	alpha_mask = tex.get_image()
	
	# Create or update the quad mesh
	if not mesh_instance.mesh or not mesh_instance.mesh is QuadMesh:
		var quad_mesh = QuadMesh.new()
		quad_mesh.size = quad_size
		mesh_instance.mesh = quad_mesh
	
	# Update the quad mesh size if needed
	if mesh_instance.mesh is QuadMesh:
		var quad_mesh = mesh_instance.mesh as QuadMesh
		quad_mesh.size = quad_size
	
	# Apply texture to material
	var material = StandardMaterial3D.new()
	material.albedo_texture = texture
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	mesh_instance.material_override = material
	
	# Refresh debug visualization if enabled
	if debug_enabled:
		_create_debug_outline()


## Controls layer visibility
func set_layer_visible(p_visible: bool) -> void:
	is_layer_visible = p_visible
	
	# Update Node3D visibility
	if mesh_instance:
		mesh_instance.visible = p_visible
	
	# If layer becomes invisible while mouse is over, trigger exit
	if not p_visible and is_mouse_over:
		_trigger_mouse_exit()
	
	# Notify parent to rebuild root collision
	if parent_displayable and parent_displayable.has_method("_on_layer_visibility_changed"):
		parent_displayable._on_layer_visibility_changed()


## Handles input events for raycast-based collision detection
func _input(event: InputEvent) -> void:
	# Only process clicks - mouse motion is handled by DisplayableNode
	if event is InputEventMouseButton:
		if event.pressed and is_mouse_over:
			layer_clicked.emit(layer_name, event)
			get_viewport().set_input_as_handled()



## Performs 2-step collision check: raycast to quad, then alpha check
## Returns true if mouse hits quad AND texture alpha exceeds threshold
func check_mouse_intersection(camera: Camera3D, mouse_pos: Vector2) -> bool:
	if not texture or not mesh_instance or not mesh_instance.mesh:
		return false

	# Check alpha at UV coordinate using cached mask
	return CollisionHelper.check_texture_alpha_at_uv(alpha_mask, mouse_pos, alpha_threshold)

## Triggers mouse enter event
func _trigger_mouse_enter() -> void:
	is_mouse_over = true
	layer_hovered.emit(layer_name)
	
	# Notify InteractionHandler
	if parent_displayable and parent_displayable.has_method("get_controller"):
		var controller = parent_displayable.get_controller()
		if controller:
			InteractionHandler.on_hover_enter(controller, layer_name)


## Triggers mouse exit event
func _trigger_mouse_exit() -> void:
	is_mouse_over = false
	layer_unhovered.emit(layer_name)
	
	# Notify InteractionHandler
	if parent_displayable and parent_displayable.has_method("get_controller"):
		var controller = parent_displayable.get_controller()
		if controller:
			InteractionHandler.on_hover_exit(controller, layer_name)


## Sets the z-index for layer ordering
func set_z_index(z: float) -> void:
	z_index = z
	position.z = z / 100.0  # Convert to actual position (assuming 1cm per z-unit)


## Sets the alpha threshold for collision detection
func set_alpha_threshold(threshold: float) -> void:
	alpha_threshold = clamp(threshold, 0.0, 1.0)


## ============================================================================
## DEBUG VISUALIZATION
## ============================================================================

## Enables or disables debug visualization of collision area
func set_debug_enabled(enabled: bool) -> void:
	debug_enabled = enabled
	
	if debug_enabled:
		_create_debug_outline()
	else:
		_remove_debug_outline()


## Creates a visual debug outline for the quad bounds
func _create_debug_outline() -> void:
	# Remove existing outline if any
	_remove_debug_outline()
	
	if not mesh_instance or not mesh_instance.mesh:
		return
	
	# Get quad size
	var quad_size = Vector2(100, 100)
	if mesh_instance.mesh is QuadMesh:
		quad_size = (mesh_instance.mesh as QuadMesh).size
	
	# Create outline mesh
	debug_outline = MeshInstance3D.new()
	debug_outline.name = "DebugOutline_" + layer_name
	add_child(debug_outline)
	
	# Create rectangle outline points
	var half_width = quad_size.x / 2.0
	var half_height = quad_size.y / 2.0
	
	var corners = PackedVector3Array([
		Vector3(-half_width, -half_height, 0),
		Vector3(half_width, -half_height, 0),
		Vector3(half_width, half_height, 0),
		Vector3(-half_width, half_height, 0)
	])
	
	# Create line mesh from corners
	var immediate_mesh = ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	# Draw the outline
	for corner in corners:
		immediate_mesh.surface_add_vertex(corner)
	# Close the loop
	immediate_mesh.surface_add_vertex(corners[0])
	
	immediate_mesh.surface_end()
	
	debug_outline.mesh = immediate_mesh
	
	# Create red material for the outline
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.0, 0.0, 1.0)  # Red
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	material.no_depth_test = true  # Always visible
	material.render_priority = 10  # Render on top
	
	debug_outline.material_override = material
	
	# Offset slightly toward camera so it's visible over the texture
	debug_outline.position.z = 0.15


## Removes debug outline visualization
func _remove_debug_outline() -> void:
	if debug_outline:
		debug_outline.queue_free()
		debug_outline = null
