@tool
## EditorNode3DGizmo for DisplayableNode
## Displays a textured billboard in the editor that matches the node's base_size
class_name DisplayableNodeGizmo
extends EditorNode3DGizmo


func _redraw() -> void:
	clear()
	
	var node = get_node_3d()
	if not node or not node is DisplayableNode:
		return
	
	var displayable_node: DisplayableNode = node as DisplayableNode
	
	# Get properties from the DisplayableNode
	var base_size: Vector2 = displayable_node.base_size
	var texture: Texture2D = displayable_node.gizmo_texture
	
	# Skip if no texture is set
	if not texture:
		return
	
	# Create a quad mesh for the billboard
	var mesh = QuadMesh.new()
	mesh.size = base_size
	
	# Create material with the texture
	var material = StandardMaterial3D.new()
	material.albedo_texture = texture
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Double-sided
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED  # Face camera
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # No lighting
	
	# Add the mesh to the gizmo
	add_mesh(mesh, material)
