## WearAction - Changes a character's outfit using Costumier system with optional animation
class_name WearAction
extends AnimatedAction

var controller: ActorController
var clothing_id: String
var name: String
var director  # ActorDirector (for Costumier access)


func _init(p_controller: ActorController, p_clothing_id: String, p_name: String = "", p_director = null) -> void:
	super._init(p_controller)
	controller = p_controller
	clothing_id = p_clothing_id
	var model = p_controller.model if p_controller else null
	name = p_name if p_name != "" else (model.name if model else "")
	director = p_director
	parameters = {"target_layers": [p_clothing_id]}

## Get current outfit from model via controller
func _get_current_value() -> Variant:
	if controller and controller.model:
		return controller.model.panoplie.duplicate()
	return []


## Apply outfit to model via controller using Costumier
func _apply_value(value: Variant) -> void:
	if not controller or not controller.model:
		return
	
	var model = controller.model
	
	# Get the Costumier for this character
	var costumier = director.get_costumier(name) if director else null
	
	if costumier:
		# Use Costumier.select() to handle exclusions properly
		var new_panoplie = costumier.select(model.panoplie, clothing_id)
		# Update model with new outfit via controller (includes exclusions)
		if model.has_method("wear"):
			model.wear(new_panoplie)
		target_value = new_panoplie
	else:
		# Fallback - just add the clothing_id
		var new_panoplie = model.panoplie.duplicate()
		if not new_panoplie.has(clothing_id):
			new_panoplie.append(clothing_id)
		if model.has_method("wear"):
			model.wear(new_panoplie)
		target_value = new_panoplie


## Create default animation for outfit changes
func _create_default_animation() -> VNAnimationNode:
	var StateChangeAnimation = load("res://rengo/infra/animation/implementations/state_change_animation.gd")
	var anim = StateChangeAnimation.new(duration if duration > 0.0 else 0.3)
	
	# Set callback to change state at midpoint
	anim.with_state_change(func(): _apply_value(target_value))
	anim.set_target_layers(parameters.get("target_layers", []))
	
	return anim


## Override execute to handle animation or instant change
func execute() -> void:
	if duration > 0.0:
		# Animated outfit change
		super.execute()
	else:
		# Instant outfit change
		_apply_value(target_value)
		_is_complete = true
