## Example script showing how to use the Interaction Input System
## This can be copied into a scene script to test interactions
extends Node

# Reference to scene controller
var ctrl: VNSceneController

# Actor controllers
var actor_me: ActorController


func _ready():
	# This example assumes you have a VNScene set up
	# with at least one actor named "me"
	
	# Get the scene controller
	ctrl = $VNScene.controller if has_node("VNScene") else null
	
	if not ctrl:
		push_error("No VNScene controller found!")
		return
	
	# Setup the scene
	_setup_scene()


func _setup_scene():
	# Example 1: Simple poke interaction
	# Hover to focus, click/space to poke
	var poke_interaction = InteractionBuilder.builder() \
		.name("poke") \
		.add(InputBuilder.hover() \
			.in_callback(_on_actor_focus_in) \
			.out_callback(_on_actor_focus_out) \
			.build()) \
		.add(InputBuilder.custom("ok_confirm") \
			.on_focus(true) \
			.callback(_on_actor_poked) \
			.build()) \
		.build()
	
	# Get actor controller
	actor_me = ctrl.get_resource("me")
	if actor_me:
		# Register and activate the interaction
		actor_me.interaction(poke_interaction)
		actor_me.interact("poke")
		
		# Position and show the actor
		actor_me.model.set_position(Vector3(0, 0, 0))
		actor_me.show()


## Callback when mouse enters actor
func _on_actor_focus_in(actor_ctrl: ActorController):
	print("Actor focused: ", actor_ctrl.name)
	actor_ctrl.model.set_focused(true)
	
	# Optional: Add visual feedback
	# actor_ctrl.apply_view_effect(func(view): 
	#     view.sprite_container.modulate = Color(1.2, 1.2, 1.2)
	# )


## Callback when mouse exits actor
func _on_actor_focus_out(actor_ctrl: ActorController):
	print("Actor unfocused: ", actor_ctrl.name)
	actor_ctrl.model.set_focused(false)
	
	# Optional: Remove visual feedback
	# actor_ctrl.apply_view_effect(func(view): 
	#     view.sprite_container.modulate = Color(1.0, 1.0, 1.0)
	# )


## Callback when actor is poked (clicked/space pressed while focused)
func _on_actor_poked(actor_ctrl: ActorController):
	print("Actor poked: ", actor_ctrl.name)
	
	# Trigger actions in response to the poke
	actor_ctrl.express("surprised").say("Ow! Why did you poke me?")


# ============================================================================
# Advanced Examples
# ============================================================================

## Example 2: Multi-choice interaction
func _setup_dialogue_choice_interaction(choice_actor: ActorController, choice_text: String):
	var choice_interaction = InteractionBuilder.builder() \
		.name("dialogue_choice") \
		.add(InputBuilder.hover() \
			.in_callback(func(ctrl): 
				ctrl.model.set_focused(true)
				print("Choice highlighted: ", choice_text)
			) \
			.out_callback(func(ctrl): 
				ctrl.model.set_focused(false)
			) \
			.build()) \
		.add(InputBuilder.custom("ok_confirm") \
			.on_focus(true) \
			.callback(func(ctrl): 
				print("Choice selected: ", choice_text)
				_on_choice_selected(choice_text)
			) \
			.build()) \
		.build()
	
	choice_actor.interaction(choice_interaction)
	choice_actor.interact("dialogue_choice")


func _on_choice_selected(choice_text: String):
	print("Player chose: ", choice_text)
	# Process the choice and continue the scene


## Example 3: Examination interaction
func _setup_examine_interaction(examinable_actor: ActorController):
	var examine_interaction = InteractionBuilder.builder() \
		.name("examine") \
		.add(InputBuilder.hover() \
			.in_callback(func(ctrl): 
				ctrl.model.set_focused(true)
				# Show "Examine" prompt
			) \
			.out_callback(func(ctrl): 
				ctrl.model.set_focused(false)
				# Hide prompt
			) \
			.build()) \
		.add(InputBuilder.custom("ui_accept") \
			.on_focus(true) \
			.callback(func(ctrl): 
				ctrl.say("This is an interesting object...")
				# Show detailed examination UI
			) \
			.build()) \
		.build()
	
	examinable_actor.interaction(examine_interaction)
	examinable_actor.interact("examine")


## Example 4: Toggle-based interaction (for minigames, etc.)
func _setup_toggle_interaction(interactive_actor: ActorController):
	var is_active = false
	
	var toggle_interaction = InteractionBuilder.builder() \
		.name("toggle") \
		.add(InputBuilder.hover() \
			.in_callback(func(ctrl): ctrl.model.set_focused(true)) \
			.out_callback(func(ctrl): ctrl.model.set_focused(false)) \
			.build()) \
		.add(InputBuilder.custom("ok_confirm") \
			.on_focus(true) \
			.callback(func(ctrl): 
				is_active = !is_active
				if is_active:
					ctrl.express("happy").say("Activated!")
				else:
					ctrl.express("neutral").say("Deactivated.")
			) \
			.build()) \
		.build()
	
	interactive_actor.interaction(toggle_interaction)
	interactive_actor.interact("toggle")


## Example 5: Context-sensitive interaction
func _setup_context_sensitive_interaction(actor: ActorController, context: String):
	var interaction_name = "interact_" + context
	
	var interaction = InteractionBuilder.builder() \
		.name(interaction_name) \
		.add(InputBuilder.hover() \
			.in_callback(func(ctrl): 
				ctrl.model.set_focused(true)
				# Show context-appropriate cursor/prompt
			) \
			.out_callback(func(ctrl): 
				ctrl.model.set_focused(false)
			) \
			.build()) \
		.add(InputBuilder.custom("ok_confirm") \
			.on_focus(true) \
			.callback(func(ctrl): 
				# Execute context-specific action
				match context:
					"combat":
						print("Attack!")
					"dialogue":
						print("Talk")
					"examine":
						print("Look at")
					_:
						print("Interact")
			) \
			.build()) \
		.build()
	
	actor.interaction(interaction)
	actor.interact(interaction_name)


# ============================================================================
# Interaction Management
# ============================================================================

## Deactivate all interactions for an actor
func deactivate_all_interactions(actor: ActorController):
	if not actor or not actor.view:
		return
	
	for interaction_name in actor.view.registered_interactions:
		actor.stop_interact(interaction_name)


## Switch between interaction contexts (e.g., exploration -> combat)
func switch_interaction_context(actor: ActorController, old_context: String, new_context: String):
	# Deactivate old context interactions
	actor.stop_interact("interact_" + old_context)
	
	# Activate new context interactions
	actor.interact("interact_" + new_context)

