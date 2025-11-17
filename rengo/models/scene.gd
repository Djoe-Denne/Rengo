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
func from_dict(p_scene_name: String, config: Dictionary) -> void:
	
	scene_name = p_scene_name

	# Parse scene metadata
	if "scene" in config:
		scene_type = config.scene.get("type", "theater")
	
	# Parse stage configuration
	if "stage" in config:
		stage.from_dict(config.stage)
	
	# Parse plans
	if "plans" in config:
		for plan_config in config.plans:
			var plan = Plan.from_dict(plan_config)
			add_plan(plan)
	
	# Set initial plan
	if stage.default_plan_id != "" and stage.default_plan_id in plans:
		set_plan(stage.default_plan_id)
	elif not plans.is_empty():
		# Use first available plan if no default specified
		set_plan(plans.keys()[0])
	
	# Parse cast
	if "cast" in config and "available" in config.cast:
		available_characters = config.cast.available
	
