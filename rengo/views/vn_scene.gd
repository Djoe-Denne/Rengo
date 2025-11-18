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

## Dialog layer (where dialog UI appears in 2D)
@onready var dialog_layer: DialogLayerView = $DialogLayer

## The stage view (renders backgrounds)
@onready var stage_view: StageView = $ActingLayer/StageView

## Dictionary mapping plan_id to VNCamera3D nodes { plan_id: VNCamera3D }
var camera_nodes: Dictionary = {}

@export var scene_name: String = ""
@export var scene_type: String = "theater"

static var instance: VNScene = null

static func get_instance() -> VNScene:
	if not instance:
		VNScene.new()
	return instance

func _init() -> void:
	instance = self

#func _init() -> void:
func _ready() -> void:	
	# Initialize the controller
	var VNSceneController = load("res://rengo/controllers/vn_scene_controller.gd")
	controller = VNSceneController.new(self)
	controller.dialog_model = dialog_model  # Pass dialog model to controller
	
	# Subscribe to scene model changes to handle plan changes
	if scene_model:
		scene_model.plan_changed.connect(_on_scene_changed)
	
	SceneFactory.populate(self)

	# Activate initial camera (first plan or default)
	if not scene_model.plans.is_empty():
		var initial_plan_id = scene_model.current_plan_id
		if initial_plan_id != "" and initial_plan_id in camera_nodes:
			camera_nodes[initial_plan_id].current = true


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
	var action = ChangePlanAction.new(plan_id)
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

## Sets the scene model (called by SceneFactory)
func set_scene_model(p_scene_model: Scene) -> void:
	scene_model = p_scene_model


## Sets the stage view for this scene (called by SceneFactory)
func set_stage_view(p_stage_view: StageView) -> void:
	stage_view = p_stage_view

## Observer callback for scene model changes
func _on_scene_changed(plan_id: String) -> void:
	# Switch active camera
	if plan_id in camera_nodes:
		# Deactivate all cameras
		for cam_id in camera_nodes:
			camera_nodes[cam_id].current = false
		
		# Activate the camera for this plan
		camera_nodes[plan_id].current = true
	else:
		push_warning("VNScene: No camera found for plan '%s'" % plan_id)
	
	# Update stage view with new background
	if stage_view:
		stage_view.on_scene_changed(plan_id)
