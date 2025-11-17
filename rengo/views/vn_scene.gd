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


## Character models registry
var characters: Dictionary = {}

@onready var scene_model: Scene = Scene.get_instance()

@onready var dialog_model: DialogModel = DialogModel.get_instance()

## Acting layer (where characters, backgrounds appear in 3D)
@onready var acting_layer: ActingLayerView = $ActingLayer

## VNCamera3D for the 3D acting layer (handles camera model observation and mouse control)
@onready var camera_3d: VNCamera3D = $ActingLayer/VNCamera3D

## Dialog layer (where dialog UI appears in 2D)
@onready var dialog_layer: DialogLayerView = $DialogLayer

## The stage view (renders backgrounds)
@onready var stage_view: StageView = $ActingLayer/StageView

@export var scene_name: String = ""

#func _init() -> void:
func _ready() -> void:	
	# Initialize the controller
	var VNSceneController = load("res://rengo/controllers/vn_scene_controller.gd")
	controller = VNSceneController.new(self)
	controller.dialog_model = dialog_model  # Pass dialog model to controller
	
		
	# Subscribe to scene model changes to handle plan changes
	if scene_model:
		scene_model.plan_changed.connect(_on_scene_changed)
	
	# Setup camera to observe the camera model
	var camera = scene_model.get_current_camera() if scene_model else null
	
	camera_3d.observe_camera(camera)

	SceneFactory.populate(self)


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

## Observer callback for scene model changes
func _on_scene_changed(plan_id: String) -> void:
	# Update camera observation when plan changes
	if camera_3d:
		var camera = scene_model.get_current_camera() if scene_model else null
		if camera:
			camera_3d.observe_camera(camera)
	stage_view.on_scene_changed(plan_id)
