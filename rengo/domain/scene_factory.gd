## Factory for creating VNScenes from YAML configuration
## 
## DEPRECATED: This factory is being phased out in favor of editor-based scene setup.
## 
## Migration Guide:
## Instead of using YAML files and SceneFactory.populate(), you should now:
## 1. Add VNCamera3D nodes directly to ActingLayer in the Godot editor
## 2. Set plan_id and camera properties via @export inspector variables
## 3. Configure backgrounds via @export variables (background_image or background_color)
## 4. VNScene will auto-discover cameras and build Scene model at runtime
## 5. Optionally use preset camera scenes (standard_camera.tscn, cinemascope_camera.tscn)
## 
## The populate() method still works for backward compatibility with existing YAML-based scenes.
class_name SceneFactory
extends RefCounted


## Creates a VNScene from a scene configuration
## DEPRECATED: Use editor-based camera setup instead. See class documentation for migration guide.
static func populate(vn_scene: VNScene) -> void:

	# Create Scene model from configuration
	Scene.get_instance().from_view(vn_scene)
	
	# Process camera references - load camera definitions and merge with plan data
	_discover_plans(vn_scene)

	Scene.get_instance().set_plan(Scene.get_instance().stage.default_plan_id)
	

## Discovers all VNCamera3D nodes in ActingLayer and creates Plans from them
static func _discover_plans(vn_scene: VNScene) -> void:
	
	var acting_layer = vn_scene.acting_layer
	# Find all VNCamera3D children in ActingLayer
	var cameras = []
	for camera_node in acting_layer.get_children():
		if camera_node is VNCamera3D:
			cameras.append(camera_node)
	
	if cameras.is_empty():
		push_error("VNScene: No VNCamera3D nodes found in ActingLayer")
		return
	
	# Create Plans from camera nodes
	for camera_node in cameras:
		if camera_node.plan_id == "":
			push_error("VNScene: VNCamera3D node has no plan_id set, skipping")
			continue
		
		# Create Plan from camera node
		var plan = Plan.from_vn_camera(camera_node)
		Scene.get_instance().add_plan(plan)
		vn_scene.camera_nodes[camera_node.plan_id] = camera_node
		
