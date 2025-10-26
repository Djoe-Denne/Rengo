## VNScene - Main container for visual novel scenes
## Manages the two-layer rendering system (Acting + Dialog)
class_name VNScene
extends Node2D

var Actor = load("res://scripts/views/actor.gd")
var Character = load("res://scripts/models/character.gd")

## The scene controller (FSM)
var controller = null  # VNSceneController

## The actor director (Theater or Movie mode)
var director = null  # ActorDirector

## The stage (manages backgrounds)
var stage = null  # Stage

## Character models registry
var characters: Dictionary = {}

## Acting layer (where characters, backgrounds appear)
@onready var acting_layer: Node2D = $ActingLayer

## Dialog layer (where dialog UI appears)
@onready var dialog_layer: CanvasLayer = $DialogLayer


func _ready() -> void:
	# Initialize the controller
	var VNSceneController = load("res://scripts/controllers/vn_scene_controller.gd")
	controller = VNSceneController.new(self)
	
	# Setup viewport resizing
	get_viewport().size_changed.connect(_on_viewport_resized)
	
	# Scale background now that we're in the tree
	if stage:
		stage.scale_background_to_viewport()


func _process(delta: float) -> void:
	if controller:
		controller.process(delta)


## Called when the viewport is resized
func _on_viewport_resized() -> void:
	# Update all resource positions
	if controller:
		for resource in controller.resources.values():
			resource.update_position()


## Adds a resource to the scene
func add_resource(resource) -> void:  # ResourceNode
	controller.add_resource(resource)


## Gets a resource by name
func get_resource(res_name: String):  # -> ResourceNode
	return controller.get_resource(res_name)


## Starts playing the scene
func play() -> void:
	controller.play()


## Stops the scene
func stop() -> void:
	controller.stop()


## Checks if the scene is finished
func is_finished() -> bool:
	return controller.is_finished()


## Sets the director for this scene (called by SceneFactory)
func set_director(p_director) -> void:
	director = p_director


## Sets the stage for this scene (called by SceneFactory)
func set_stage(p_stage) -> void:
	stage = p_stage
	if stage:
		stage.vn_scene = self


## Casts a character as an actor in this scene
## Creates/retrieves Character model and links it to a new Actor view
func cast(character_name: String) -> Actor:
	# Create or retrieve Character model
	var character = null
	if character_name in characters:
		character = characters[character_name]
	else:
		# Create new Character model
		character = Character.new(character_name)
		characters[character_name] = character
		
		# Load character metadata from director
		if director:
			director.load_character_metadata(character)
	
	# Load character acts if not already loaded
	if director and not character_name in director.character_acts:
		director.load_character(character_name)
	
	# Load character wardrobe if not already loaded
	if director and not character_name in director.costumiers:
		director.load_wardrobe(character_name)
	
	# Create Actor view instance
	var actor = Actor.new(character_name, director)
	actor.vn_scene = self
	
	# Link Actor to Character model (observer pattern)
	actor.observe(character)
	
	# Add to controller as a resource
	add_resource(actor)
	
	return actor


## Changes the background
func set_background(bg_id: String) -> void:
	if stage:
		stage.set_background(bg_id)
