## DisplayableLayer - Self-contained layer with mesh, texture, collision, and shader
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

## Texture-based collision area
var interaction_area: Area3D = null

## Current texture
var texture: Texture2D = null

## Applied shader material
var shader_material: ShaderMaterial = null

## Layer visibility (separate from Node3D.visible for control)
var is_layer_visible: bool = true

## Z-index for layer ordering
var z_index: float = 0.0

## Reference to parent displayable node (for callbacks)
var parent_displayable = null  # DisplayableNode


func _init(p_layer_name: String = "") -> void:
	layer_name = p_layer_name
	name = "Layer_" + layer_name
	
	# Create the mesh instance as a child
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Mesh_" + layer_name
	add_child(mesh_instance)


## Sets the texture and rebuilds collision area
func set_texture(tex: Texture2D, quad_size: Vector2 = Vector2(100, 100)) -> void:
	if not tex:
		push_warning("DisplayableLayer: Attempted to set null texture on layer '%s'" % layer_name)
		return
	
	texture = tex
	
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
	
	# If we have a shader material, preserve it
	if shader_material:
		shader_material.set_shader_parameter("albedo_texture", texture)
		mesh_instance.material_override = shader_material
	else:
		mesh_instance.material_override = material
	
	# Rebuild collision based on new texture
	rebuild_collision()


## Applies a shader with parameters
func apply_shader(shader: Shader, params: Dictionary = {}) -> void:
	if not shader:
		push_warning("DisplayableLayer: Attempted to apply null shader on layer '%s'" % layer_name)
		return
	
	# Create shader material if it doesn't exist
	if not shader_material:
		shader_material = ShaderMaterial.new()
	
	shader_material.shader = shader
	
	# Set shader parameters
	for param_name in params:
		shader_material.set_shader_parameter(param_name, params[param_name])
	
	# Ensure texture is set if we have one
	if texture:
		shader_material.set_shader_parameter("albedo_texture", texture)
	
	# Apply to mesh
	if mesh_instance:
		mesh_instance.material_override = shader_material


## Clears the shader and reverts to standard material
func clear_shader() -> void:
	shader_material = null
	
	if mesh_instance and texture:
		var material = StandardMaterial3D.new()
		material.albedo_texture = texture
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh_instance.material_override = material


## Controls layer visibility
func set_layer_visible(p_visible: bool) -> void:
	is_layer_visible = p_visible
	
	# Update Node3D visibility
	if mesh_instance:
		mesh_instance.visible = p_visible
	
	# Notify parent to rebuild root collision
	if parent_displayable and parent_displayable.has_method("_on_layer_visibility_changed"):
		parent_displayable._on_layer_visibility_changed()


## Creates collision area from texture alpha channel
func create_collision_area() -> void:
	if not texture:
		return
	
	# Remove existing collision area if any
	if interaction_area:
		interaction_area.queue_free()
		interaction_area = null
	
	# Get CollisionHelper to create polygon from texture
	var CollisionHelper = load("res://core-game/input/collision_helper.gd")
	
	# Get quad size for scaling
	var quad_size = Vector2(100, 100)
	if mesh_instance and mesh_instance.mesh is QuadMesh:
		quad_size = (mesh_instance.mesh as QuadMesh).size
	
	# Create Area3D with texture-based collision
	interaction_area = CollisionHelper.create_area3d_from_texture(texture, quad_size)
	
	if interaction_area:
		interaction_area.name = "InteractionArea_" + layer_name
		add_child(interaction_area)
		
		# Connect signals
		interaction_area.input_event.connect(_on_input_event)
		interaction_area.mouse_entered.connect(_on_mouse_entered)
		interaction_area.mouse_exited.connect(_on_mouse_exited)


## Rebuilds collision area (when texture changes)
func rebuild_collision() -> void:
	create_collision_area()


## Signal handler for input events on this layer
func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	layer_clicked.emit(layer_name, event)


## Signal handler for mouse entering this layer
func _on_mouse_entered() -> void:
	layer_hovered.emit(layer_name)
	
	# Notify InteractionHandler
	if parent_displayable and parent_displayable.has_method("get_controller"):
		var controller = parent_displayable.get_controller()
		if controller:
			InteractionHandler.on_hover_enter(controller, layer_name)


## Signal handler for mouse exiting this layer
func _on_mouse_exited() -> void:
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

