## Fade animation - interpolates alpha (modulate.a) from start to end
## LEGACY: This is kept for backward compatibility
## New code should use StateChangeAnimation or TransformAnimation
class_name FadeAnimation
extends VNAnimationNode


func _init(p_duration: float = 0.0) -> void:
	super._init(p_duration)


## Applies the fade animation to target
func apply_to(target: Variant, progress: float, _delta: float) -> void:
	if not target or not target.scene_node:
		return
	
	# Setup from_value on first frame
	if from_value == null:
		from_value = _get_alpha_from_node(target.scene_node)
		to_value = 1.0 - from_value
	
	# Interpolate alpha
	var alpha = lerp(float(from_value), float(to_value), progress)
	_set_alpha_on_node(target.scene_node, alpha)


## Helper to get alpha from both 2D and 3D nodes
func _get_alpha_from_node(node: Node) -> float:
	if node is Node2D:
		return node.modulate.a if "modulate" in node else 1.0
	elif node is MeshInstance3D:
		if node.material_override:
			return node.material_override.albedo_color.a
		return 1.0
	elif node is Node3D:
		# For Node3D containers, check first child MeshInstance3D
		for child in node.get_children():
			if child is MeshInstance3D and child.material_override:
				return child.material_override.albedo_color.a
		return 1.0
	return 1.0


## Helper to set alpha on both 2D and 3D nodes
func _set_alpha_on_node(node: Node, alpha: float) -> void:
	if node is Node2D:
		# 2D node - use modulate
		if "modulate" in node:
			node.modulate.a = alpha
	elif node is MeshInstance3D:
		# 3D mesh - set material alpha
		if node.material_override:
			node.material_override.albedo_color.a = alpha
	elif node is Node3D:
		# 3D container - set alpha on all MeshInstance3D children
		for child in node.get_children():
			if child is MeshInstance3D and child.material_override:
				child.material_override.albedo_color.a = alpha
