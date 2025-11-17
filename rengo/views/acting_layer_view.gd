## ActingLayerView - Manages the 3D acting layer
## Coordinates actors, backgrounds, and other visual elements in 3D space
## Pure view component - no business logic
class_name ActingLayerView
extends Node3D

## Dictionary of actors in the layer { actor_name: Actor }
var actors: Dictionary = {}

## Reference to the StageView (background rendering)
@onready var stage_view: StageView = $StageView

static var instance: ActingLayerView = null

static func get_instance() -> ActingLayerView:
	if not instance:
		instance = ActingLayerView.new()
	return instance

func _init() -> void:
	instance = self

## Adds an actor to the layer
func add_actor(actor: Actor) -> void:
	
	if actor.actor_name in actors:
		push_warning("ActingLayerView: Actor '%s' already exists, replacing" % actor.actor_name)
	
	actors[actor.actor_name] = actor
	add_child(actor)

## Removes an actor from the layer
func remove_actor(actor_name: String) -> void:
	if actor_name in actors:
		var actor = actors[actor_name]
		actor.queue_free()
		actors.erase(actor_name)
		remove_child(actor)
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
