@tool
## Main editor plugin for Rengo visual novel system
## Registers gizmo plugins and other editor enhancements
extends EditorPlugin

var displayable_gizmo_plugin: EditorNode3DGizmoPlugin


func _enter_tree() -> void:
	# Create and add the DisplayableNode gizmo plugin
	displayable_gizmo_plugin = preload("res://addons/editor/displayable_node_gizmo_plugin.gd").new()
	add_node_3d_gizmo_plugin(displayable_gizmo_plugin)
	
	print("Rengo Editor Plugin: Loaded successfully")


func _exit_tree() -> void:
	# Remove the gizmo plugin when the plugin is disabled
	if displayable_gizmo_plugin:
		remove_node_3d_gizmo_plugin(displayable_gizmo_plugin)
		displayable_gizmo_plugin = null
	
	print("Rengo Editor Plugin: Unloaded")
