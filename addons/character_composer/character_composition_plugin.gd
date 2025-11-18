@tool
extends EditorPlugin

## Character Composition Editor Plugin
## Provides visual editing for CharacterCompositionResource

var editor_panel: Control = null
var editor_panel_instance: Control = null


func _enter_tree() -> void:
	# Load the editor panel scene
	var panel_scene = preload("res://addons/character_composer/composition_editor_panel.tscn")
	editor_panel = panel_scene.instantiate()
	
	# Add the panel to the bottom panel
	add_control_to_bottom_panel(editor_panel, "Character Composer")
	
	# Hide by default
	hide_bottom_panel()
	
	print("Character Composer plugin enabled")


func _exit_tree() -> void:
	# Clean up the editor panel
	if editor_panel:
		remove_control_from_bottom_panel(editor_panel)
		editor_panel.queue_free()
		editor_panel = null
	
	print("Character Composer plugin disabled")


func _handles(object: Object) -> bool:
	# Handle CharacterCompositionResource objects
	return object is CharacterCompositionResource


func _edit(object: Object) -> void:
	if object is CharacterCompositionResource:
		if editor_panel and editor_panel.has_method("edit_resource"):
			editor_panel.edit_resource(object)
			make_bottom_panel_item_visible(editor_panel)


func _make_visible(visible: bool) -> void:
	if editor_panel:
		if visible:
			make_bottom_panel_item_visible(editor_panel)
		else:
			hide_bottom_panel()

