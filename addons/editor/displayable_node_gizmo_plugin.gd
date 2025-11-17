@tool
## EditorNode3DGizmoPlugin for DisplayableNode
## Creates and manages gizmo instances for all DisplayableNode nodes in the editor
extends EditorNode3DGizmoPlugin


func _init() -> void:
	# Create a default material for the gizmo
	create_material("displayable_billboard", Color(1, 1, 1, 1))


func _has_gizmo(node: Node3D) -> bool:
	# Return true for any DisplayableNode instance
	return node is DisplayableNode


func _create_gizmo(node: Node3D) -> EditorNode3DGizmo:
	# Create and return a new DisplayableNodeGizmo for this node
	var gizmo = DisplayableNodeGizmo.new()
	return gizmo


func _get_gizmo_name() -> String:
	return "DisplayableNode"
