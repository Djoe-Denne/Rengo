## StageModel - Configuration data for stage/viewport behavior
## Pure data, no rendering logic
class_name StageModel
extends RefCounted

## Scaling mode for viewport ("letterbox", "fit", "stretch")
var scaling_mode: String = "letterbox"

## Default plan ID to use on scene start
var default_plan_id: String = ""


func _init(p_scaling_mode: String = "letterbox", p_default_plan_id: String = "") -> void:
	scaling_mode = p_scaling_mode
	default_plan_id = p_default_plan_id


## Creates a StageModel from a dictionary configuration
static func from_dict(config: Dictionary) -> StageModel:
	var stage = StageModel.new()
	stage.scaling_mode = config.get("scaling_mode", "letterbox")
	stage.default_plan_id = config.get("default_plan", "")
	return stage

