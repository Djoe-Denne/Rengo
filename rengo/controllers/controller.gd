class_name Controller
extends SceneObject

func get_model() -> DisplayableModel:
	push_error("get_model() must be implemented by subclass")
	return null

func get_view() -> DisplayableNode:
	push_error("get_view() must be implemented by subclass")
	return null

func handle_changes() -> void:
	push_error("handle_changes() must be implemented by subclass")