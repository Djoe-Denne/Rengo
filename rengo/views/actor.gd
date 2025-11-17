## Actor class - Pure VIEW for character display
## Actors observe Character models and display visuals via ActorDirectors
## Extends DisplayableNode for multi-layer rendering and collision
## DO NOT use Actor directly - use ActorController for public API
class_name Actor extends DisplayableNode

## The character name this actor represents
@export var actor_name: String = ""

## Default gizmo texture for actor editor billboard
@export var gizmo_texture: Texture2D = preload("res://assets/dev/gizmo/actor/idle.png")


func _ready() -> void:
	super._ready()
	if not actor_name:
		push_error("Actor: actor_name is not set")
		return
	
	# Create or retrieve Character model
	var character = null
	# Create new Character model
	character = Character.new(actor_name)
		
	# Create Machinist
	var machinist = Machinist.new()

	# Create ActorDirector
	var actor_director = TheaterActorDirector.new()
	# Create ActorController and link it to the view (MVC)
	var actor_ctrl = ActorController.new(actor_name, character, self, actor_director, machinist)
	actor_ctrl.plug_signals()
	actor_director.load_character(character)
	machinist.load_config("")
	
	
