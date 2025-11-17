## StageModel - Configuration data for stage/viewport behavior
## Pure data, no rendering logic
class_name StageModel
extends RefCounted

## Scaling mode for viewport ("letterbox", "fit", "stretch")
var scaling_mode: String = "letterbox"

## Default plan ID to use on scene start
var default_plan_id: String = ""

## static instance of StageModel
static var instance: StageModel = null

static func get_instance() -> StageModel:
	if not instance:
		instance = StageModel.new()
	return instance


## Creates a StageModel from a dictionary configuration
func from_dict(config: Dictionary) -> void:
	scaling_mode = config.get("scaling_mode", "letterbox")
	default_plan_id = config.get("default_plan", "")

func from_view(stage_view: StageView) -> void:
	scaling_mode = stage_view.scaling_mode
	default_plan_id = stage_view.default_plan_id
