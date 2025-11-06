## Scene - Pure data model for VN scene state
## Holds scene configuration and notifies observers when state changes
## Follows the same observer pattern as Character model
class_name Scene
extends RefCounted

## Signals for scene changes
signal plan_changed(new_plan_id: String)

## Scene identifier (e.g., "demo_scene")
var scene_name: String = ""

## Scene type ("theater" or "movie")
var scene_type: String = "theater"

## Current active plan ID
var current_plan_id: String = ""

## Dictionary of plans { plan_id: Plan }
var plans: Dictionary = {}

## Stage configuration
var stage: StageModel = null

## List of available character names
var available_characters: Array = []

func _init(p_scene_name: String = "", p_scene_type: String = "theater") -> void:
	scene_name = p_scene_name
	scene_type = p_scene_type
	stage = StageModel.new()


## Changes the current plan and notifies observers
func set_plan(plan_id: String) -> void:
	if not plan_id in plans:
		push_warning("Plan '%s' not found in scene '%s'" % [plan_id, scene_name])
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
static func from_dict(scene_name: String, config: Dictionary) -> Scene:
	var scene = Scene.new(scene_name)
	
	# Parse scene metadata
	if "scene" in config:
		scene.scene_type = config.scene.get("type", "theater")
	
	# Parse stage configuration
	if "stage" in config:
		scene.stage = StageModel.from_dict(config.stage)
	
	# Parse plans
	if "plans" in config:
		for plan_config in config.plans:
			var plan = Plan.from_dict(plan_config)
			scene.add_plan(plan)
	
	# Set initial plan
	if scene.stage.default_plan_id != "" and scene.stage.default_plan_id in scene.plans:
		scene.current_plan_id = scene.stage.default_plan_id
	elif not scene.plans.is_empty():
		# Use first available plan if no default specified
		scene.current_plan_id = scene.plans.keys()[0]
	
	# Parse cast
	if "cast" in config and "available" in config.cast:
		scene.available_characters = config.cast.available
	
	return scene
