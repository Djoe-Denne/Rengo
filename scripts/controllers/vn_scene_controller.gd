## Finite State Machine manager for visual novel scenes
## Executes actions sequentially and manages scene resources
class_name VNSceneController
extends RefCounted

## Dictionary of all resources in this scene (name -> ResourceNode)
var resources: Dictionary = {}

## Queue of actions to execute
var action_queue: Array = []

## Current action being executed
var current_action = null  # ActionNode

## Whether the scene is currently playing
var is_playing: bool = false

## Reference to the actual VNScene node
var scene_node: Node = null

## Reference to the Scene model (owns the model)
var scene_model: Scene = null


func _init(p_scene_node: Node = null) -> void:
	scene_node = p_scene_node


## Sets the scene model
func set_scene_model(p_scene_model: Scene) -> void:
	scene_model = p_scene_model


## Adds a resource to the scene
func add_resource(resource) -> void:  # ResourceNode
	if resource.resource_name in resources:
		push_warning("Resource '%s' already exists, replacing it" % resource.resource_name)
	resources[resource.resource_name] = resource
	resource.vn_scene = scene_node


## Gets a resource by name
func get_resource(res_name: String):  # -> ResourceNode
	return resources.get(res_name, null)


## Adds an action to the execution queue
func action(p_action) -> VNSceneController:  # ActionNode
	action_queue.append(p_action)
	return self


## Adds a wait action to the queue
func wait(seconds: float) -> VNSceneController:
	var WaitAction = load("res://scripts/controllers/actions/common/wait_action.gd")
	action_queue.append(WaitAction.new(seconds))
	return self


## Starts playing the scene
func play() -> void:
	is_playing = true


## Stops playing the scene
func stop() -> void:
	is_playing = false
	current_action = null


## Resets the scene to the beginning
func reset() -> void:
	stop()
	current_action = null


## Processes the scene (should be called every frame)
func process(delta: float) -> void:
	# Process all resource animations (even if scene isn't playing)
	for resource in resources.values():
		if resource.has_method("process_animations"):
			resource.process_animations(delta)
	
	if not is_playing:
		return
	
	# If no current action, get the next one from the queue
	if current_action == null:
		if action_queue.is_empty():
			# Scene is complete
			is_playing = false
			return
		current_action = action_queue.pop_front()
	
	# Process the current action
	var is_complete = current_action.process_action(delta)
	
	if is_complete:
		current_action = null


## Checks if the scene has finished playing
func is_finished() -> bool:
	return not is_playing and action_queue.is_empty() and current_action == null

