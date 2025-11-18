## ChangePlanAction - Changes the cinematic plan (camera, backgrounds)
## Queued action that changes plan when executed in the scene timeline
extends ActionNode
class_name ChangePlanAction

## The new plan ID to switch to
var plan_id: String = ""

## Reference to the Scene model



func _init(p_plan_id: String) -> void:
	super._init(null, 0.0)  # No target, instant by default
	plan_id = p_plan_id
	blocking = true  # Wait for plan change to complete


## Execute the plan change
func execute() -> void:
	super.execute()
	
	if plan_id == "":
		push_error("ChangePlanAction: no plan ID specified")
		_is_complete = true
		return
	
	# Change the plan on the scene model
	# This will notify all observers (StageView, ActorDirector)
	Scene.get_instance().set_plan(plan_id)
	
	# Complete immediately
	_is_complete = true
