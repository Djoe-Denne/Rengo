## Scene - Pure data model for VN scene state
## Holds scene configuration and notifies observers when state changes
## Follows the same observer pattern as Character model
class_name Scene
extends RefCounted

## Signals for scene changes
signal plan_changed(new_plan_id: String)

var scene_name: String = ""
var scene_type: String = "theater"

## Current active plan ID
var current_plan_id: String = ""

## Dictionary of plans { plan_id: Plan }
var plans: Dictionary = {}

## Stage configuration
var stage: StageModel = null

## List of available character names
var available_characters: Array = []

## static instance of Scene
static var instance: Scene = null

static func get_instance() -> Scene:
	if not instance:
		Scene.new()
	return instance

func _init() -> void:
	instance = self
	stage = StageModel.new()


## Changes the current plan and notifies observers
func set_plan(plan_id: String) -> void:
	if not plan_id in plans:
		push_warning("Plan '%s' not found in scene" % [plan_id])
		return
	
	if current_plan_id != plan_id:
		current_plan_id = plan_id
		plan_changed.emit(plan_id)


## Gets the current Plan object
func get_current_plan() -> Plan:
	if current_plan_id in plans:
		return plans[current_plan_id]
	return null


## Gets the current Camera object
func get_current_camera() -> Camera:
	var plan = get_current_plan()
	if plan:
		return plan.camera
	return null


## Adds a plan to the scene
func add_plan(plan: Plan) -> void:
	plans[plan.plan_id] = plan


## Creates a Scene from a dictionary configuration
func from_view(vn_scene: VNScene) -> void:
	
	scene_name = vn_scene.scene_name
	scene_type = vn_scene.scene_type
	
	stage.from_view(vn_scene.stage_view)
	
