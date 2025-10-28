## ActingLayerView - Manages the 3D acting layer
## Coordinates actors, backgrounds, and other visual elements in 3D space
## Pure view component - no business logic
class_name ActingLayerView
extends RefCounted

## Reference to the ActingLayer Node3D
var layer_node: Node3D = null

## Dictionary of actors in the layer { actor_name: Actor }
var actors: Dictionary = {}

## Reference to the StageView (background rendering)
var stage_view: StageView = null

## Reference to the parent VNScene
var vn_scene: Node = null


func _init() -> void:
	pass


## Sets up the acting layer
func setup_layer(p_layer_node: Node3D, p_vn_scene: Node) -> void:
	layer_node = p_layer_node
	vn_scene = p_vn_scene
	
	# Initialize stage view if Scene model is available
	if vn_scene and "scene_model" in vn_scene and vn_scene.scene_model:
		stage_view = StageView.new()
		stage_view.set_scene_model(vn_scene.scene_model, vn_scene)
		stage_view.create_background_node(layer_node)


## Adds an actor to the layer
func add_actor(actor: Actor) -> void:
	if not layer_node:
		push_error("ActingLayerView: layer_node not initialized")
		return
	
	if actor.actor_name in actors:
		push_warning("ActingLayerView: Actor '%s' already exists, replacing" % actor.actor_name)
	
	actors[actor.actor_name] = actor
	
	# Create the actor's scene node if it doesn't exist
	if not actor.scene_node:
		actor.create_scene_node(layer_node)


## Removes an actor from the layer
func remove_actor(actor_name: String) -> void:
	if actor_name in actors:
		var actor = actors[actor_name]
		
		# Remove the actor's scene node
		if actor.scene_node:
			actor.scene_node.queue_free()
			actor.scene_node = null
		
		actors.erase(actor_name)
	else:
		push_warning("ActingLayerView: Actor '%s' not found" % actor_name)


## Gets an actor by name
func get_actor(actor_name: String) -> Actor:
	return actors.get(actor_name, null)


## Gets all actors
func get_all_actors() -> Array:
	return actors.values()


## Clears all actors from the layer
func clear_actors() -> void:
	for actor_name in actors.keys():
		remove_actor(actor_name)


## Updates the stage view (background)
func update_stage() -> void:
	if stage_view:
		# Stage view observes Scene model and updates automatically
		pass

