## WearAction - Changes a character's outfit using Costumier system with optional animation
class_name WearAction
extends AnimatedAction

var actor: Actor
var clothing_id: String


func _init(p_actor: Actor, p_clothing_id: String) -> void:
	super._init(p_actor)
	actor = p_actor
	clothing_id = p_clothing_id
	parameters = {"target_layers": [p_clothing_id]}

## Get current outfit
func _get_current_value() -> Variant:
	if actor and actor.character:
		return actor.character.panoplie.duplicate()
	return []


## Apply outfit to character using Costumier
func _apply_value(value: Variant) -> void:
	if not actor or not actor.character:
		return
	
	# Get the Costumier for this character
	var costumier = actor.director.get_costumier(actor.actor_name) if actor.director else null
	
	if costumier:
		# Use Costumier.select() to handle exclusions properly
		var new_panoplie = costumier.select(actor.character.panoplie, clothing_id)
		# Update character with new outfit (includes exclusions)
		actor.character.wear(new_panoplie)
		target_value = new_panoplie
	else:
		# Fallback - just add the clothing_id
		var new_panoplie = actor.character.panoplie.duplicate()
		if not new_panoplie.has(clothing_id):
			new_panoplie.append(clothing_id)
		actor.character.wear(new_panoplie)
		target_value = new_panoplie


## Create default animation for outfit changes
func _create_default_animation() -> VNAnimationNode:
	var StateChangeAnimation = load("res://scripts/infra/animation/implementations/state_change_animation.gd")
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
