## Actor class - Pure VIEW for character display
## Actors observe Character models and display visuals via ActorDirectors
## Extends DisplayableNode for multi-layer rendering and collision
## DO NOT use Actor directly - use ActorController for public API
class_name Actor extends DisplayableNode

## The character name this actor represents
var actor_name: String = ""


func _init(p_actor_name: String = "", p_director = null) -> void:
	super(p_actor_name)
	actor_name = p_actor_name
	director = p_director
