## VNScene - Main container for visual novel scenes
## Pure view component - exposes models and manages rendering
class_name VNScene
extends Node

var Actor = load("res://scripts/views/actor.gd")
var Character = load("res://scripts/models/character.gd")

## The scene controller (FSM)
var controller = null  # VNSceneController

## The actor director (Theater or Movie mode)
var director = null  # ActorDirector

## The scene model (contains all scene state)
var scene_model: Scene = null

## The stage view (renders backgrounds)
var stage_view: StageView = null

## Character models registry
var characters: Dictionary = {}

## Acting layer (where characters, backgrounds appear in 3D)
@onready var acting_layer: Node3D = $ActingLayer

## VNCamera3D for the 3D acting layer (handles camera model observation and mouse control)
@onready var camera_3d: VNCamera3D = $ActingLayer/Camera3D

## Dialog layer (where dialog UI appears in 2D)
@onready var dialog_layer: CanvasLayer = $DialogLayer

## Expose scene model as 'scene' property for direct access
var scene: Scene:
	get: return scene_model


func _ready() -> void:
	# Initialize the controller
	var VNSceneController = load("res://scripts/controllers/vn_scene_controller.gd")
	controller = VNSceneController.new(self)
	
	# Pass scene model to controller
	if scene_model:
		controller.set_scene_model(scene_model)
	
	# Setup viewport resizing
	get_viewport().size_changed.connect(_on_viewport_resized)
	
	# Subscribe to scene model changes to handle plan changes
	if scene_model:
		scene_model.add_observer(_on_scene_changed)
	
	# Setup camera to observe the camera model
	var camera = scene_model.get_current_camera() if scene_model else null
	if camera and camera_3d:
		camera_3d.observe_camera(camera)
	
	# Create background sprite now that we're in the tree
	if stage_view:
		stage_view.create_background_node(acting_layer)
	
	# Scale background to viewport (for 2D, 3D doesn't need this)
	if stage_view and scene_model and scene_model.scene_type != "theater":
		stage_view.scale_to_viewport()


func _process(delta: float) -> void:
	if controller:
		controller.process(delta)


## Called when the viewport is resized
func _on_viewport_resized() -> void:
	# In 3D mode, we don't need to update positions on resize
	# The camera handles the projection automatically
	pass


## Adds a resource to the scene
func add_resource(resource) -> void:  # ResourceNode
	controller.add_resource(resource)


## Gets a resource by name
func get_resource(res_name: String):  # -> ResourceNode
	return controller.get_resource(res_name)


## Changes the cinematic plan (queues as action)
## Returns the action for optional chaining
func change_plan(plan_id: String):
	var ChangePlanAction = load("res://scripts/controllers/actions/common/change_plan_action.gd")
	var action = ChangePlanAction.new(scene_model, plan_id)
	controller.action(action)
	return action


## Starts playing the scene
func play() -> void:
	controller.play()


## Stops the scene
func stop() -> void:
	controller.stop()


## Checks if the scene is finished
func is_finished() -> bool:
	return controller.is_finished()


## Enables or disables mouse camera control
func set_mouse_camera_enabled(enabled: bool) -> void:
	if camera_3d:
		camera_3d.set_mouse_camera_enabled(enabled)


## Sets the scene model (called by SceneFactory)
func set_scene_model(p_scene_model: Scene) -> void:
	scene_model = p_scene_model


## Sets the director for this scene (called by SceneFactory)
func set_director(p_director) -> void:
	director = p_director


## Sets the stage view for this scene (called by SceneFactory)
func set_stage_view(p_stage_view: StageView) -> void:
	stage_view = p_stage_view


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


## Observer callback for scene model changes
func _on_scene_changed(scene_state: Dictionary) -> void:
	# Update camera observation when plan changes
	if "current_plan_id" in scene_state and camera_3d:
		var camera = scene_model.get_current_camera() if scene_model else null
		if camera:
			camera_3d.observe_camera(camera)


