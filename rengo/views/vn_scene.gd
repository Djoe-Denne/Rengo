## VNScene - Main container for visual novel scenes
## Pure view component - exposes models and manages rendering
class_name VNScene
extends Node

var Actor = load("res://rengo/views/actor.gd")
var Character = load("res://rengo/models/character.gd")

## Create ActorController (the public API)
var ActorController = load("res://rengo/controllers/actor_controller.gd")

## The scene controller (FSM)
var controller: VNSceneController = null  # VNSceneController

## The scene model (contains all scene state)
var scene_model: Scene = null

## The dialog model (holds dialog state)
var dialog_model: DialogModel = null

## The stage view (renders backgrounds)
var stage_view: StageView = null

## The acting layer view (manages 3D actors and objects)
var acting_layer_view: ActingLayerView = null

## The dialog layer view (manages 2D dialog UI)
var dialog_layer_view: DialogLayerView = null

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
	# Initialize the dialog model
	var DialogModel = load("res://rengo/models/dialog_model.gd")
	dialog_model = DialogModel.new()
	
	# Initialize the controller
	var VNSceneController = load("res://rengo/controllers/vn_scene_controller.gd")
	controller = VNSceneController.new(self)
	controller.dialog_model = dialog_model  # Pass dialog model to controller
	
	# Pass scene model to controller
	if scene_model:
		controller.set_scene_model(scene_model)
	
	# Initialize ActingLayerView
	var ActingLayerView = load("res://rengo/views/acting_layer_view.gd")
	acting_layer_view = ActingLayerView.new()
	acting_layer_view.setup_layer(acting_layer, self)
	
	# Initialize DialogLayerView
	var DialogLayerView = load("res://rengo/views/dialog_layer_view.gd")
	dialog_layer_view = DialogLayerView.new()
	dialog_layer_view.setup_layer(dialog_layer)
	
	# Wire DialogLayerView to observe DialogModel
	dialog_layer_view.observe(dialog_model)
	
	# Setup viewport resizing
	get_viewport().size_changed.connect(_on_viewport_resized)
	
	# Subscribe to scene model changes to handle plan changes
	if scene_model:
		scene_model.plan_changed.connect(_on_scene_changed)
	
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
	var ChangePlanAction = load("res://rengo/controllers/actions/common/change_plan_action.gd")
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


## Sets the stage view for this scene (called by SceneFactory)
func set_stage_view(p_stage_view: StageView) -> void:
	stage_view = p_stage_view


## Casts a character as an actor in this scene
## Creates Character model, Actor view, and ActorController
## Returns ActorController for public API
func cast(name: String) -> ActorController:
	# Create or retrieve Character model
	var character = null
	if name in characters:
		character = characters[name]
	else:
		# Create new Character model
		character = Character.new(name)
		characters[name] = character
		
	# Create Actor view instance
	var actor = Actor.new(name)
	actor.vn_scene = self
	
	# Create Machinist
	var machinist = Machinist.new()

	# Create ActorDirector
	var actor_director = TheaterActorDirector.new()
	actor_director.set_scene_model(scene_model)
	# Create ActorController and link it to the view (MVC)
	var actor_ctrl = ActorController.new(name, character, actor, actor_director, machinist, scene_model)
	actor_ctrl.vn_scene = self  # For action registration
	actor_ctrl.plug_signals()
	actor_director.load_character(character)
	machinist.load_config("")
	
	# Create the actor's scene node immediately (eager creation)
	# Actors are visual elements, so they should always have their scene representation ready
	if acting_layer:
		actor.create_scene_node(acting_layer)
	
	# Add actor to controller as a resource (still needed for legacy scene tracking)
	add_resource(actor)
	
	return actor_ctrl


## Observer callback for scene model changes
func _on_scene_changed() -> void:
	if not scene_model:
		return
	
	# Update camera observation when plan changes
	if camera_3d:
		var camera = scene_model.get_current_camera() if scene_model else null
		if camera:
			camera_3d.observe_camera(camera)
