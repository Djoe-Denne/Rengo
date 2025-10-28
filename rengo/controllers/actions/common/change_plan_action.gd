## ChangePlanAction - Changes the cinematic plan (camera, backgrounds)
## Queued action that changes plan when executed in the scene timeline
extends ActionNode
class_name ChangePlanAction

## The new plan ID to switch to
var plan_id: String = ""

## Reference to the Scene model
var scene_model: Scene = null


func _init(p_scene_model: Scene, p_plan_id: String) -> void:
	super._init(null, 0.0)  # No target, instant by default
	scene_model = p_scene_model
	plan_id = p_plan_id
	blocking = true  # Wait for plan change to complete


## Execute the plan change
func execute() -> void:
	super.execute()
	
	if not scene_model:
		push_error("ChangePlanAction: no scene model")
		_is_complete = true
		return
	
	if plan_id == "":
		push_error("ChangePlanAction: no plan ID specified")
		_is_complete = true
		return
	
	# Change the plan on the scene model
	# This will notify all observers (StageView, ActorDirector)
	scene_model.set_plan(plan_id)
	
	# Complete immediately
	_is_complete = true
