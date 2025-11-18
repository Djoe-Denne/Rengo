extends Node

## Scene script for test_scene - mimics demo.gd behavior with editor-based setup
## This script is attached to the SceneScript node in test_scene.tscn

var vn_scene = null  # VNScene
var me_actor_ctrl = null  # ActorController
var other_actor_ctrl = null  # ActorController


func _ready() -> void:
	# Get parent VNScene reference (SceneScript is a child of VNScene)
	vn_scene = get_parent()
	if not vn_scene:
		push_error("Failed to get VNScene parent")
		return
	
	# Wait for scene to be fully initialized
	await get_tree().process_frame
	
	# Get StageView reference
	var stage_view = vn_scene.stage_view
	if not stage_view:
		push_error("Failed to get StageView")
		return
	
	# Get actor controllers using the new helper method
	me_actor_ctrl = stage_view.get_actor_controller("me")
	other_actor_ctrl = stage_view.get_actor_controller("other")
	
	if not me_actor_ctrl:
		push_error("Failed to get 'me' actor controller")
		return
	if not other_actor_ctrl:
		push_error("Failed to get 'other' actor controller")
		return
	
	var poke_interaction = InteractionBuilder.builder() \
									.name("poke") \
									.add(InputBuilder.hover() \
										.in_callback(func(ctrl, layer): ctrl.get_model().add_layer_state(layer, "focused")) \
										.out_callback(func(ctrl, layer): ctrl.get_model().remove_layer_state(layer, "focused")) \
										.build()) \
									.add(InputBuilder.custom("ok_confirm") \
										.on_focus(true) \
										.callback(func(ctrl, layer): ctrl.say("Ow!")) \
										.build()) \
									.build()

	me_actor_ctrl.interaction(poke_interaction)  # Register interaction

	# Build the story action queue
	_play_story()
	
	# Start playing the scene
	vn_scene.play()


func _input(event: InputEvent) -> void:
	# Debug: Export all viewport textures on Ctrl+P
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_P and event.ctrl_pressed:
			print("=== Exporting Viewport Textures (Ctrl+P) ===")
			var count = ViewportTextureExporter.export_all_viewports(get_tree().root, "user://viewport_debug/")
			print("=== Export Complete: %d textures saved to user://viewport_debug/ ===" % count)
			get_viewport().set_input_as_handled()


func _play_story() -> void:
	# Scene 1: Me wakes up with bed hair
	me_actor_ctrl.act({"body": "bedhair"})
	me_actor_ctrl.interact("poke").on("body").on("face")
	me_actor_ctrl.express("sad")
	me_actor_ctrl.say("Ugh, I just woke up...")
	
	# Scene 2: Other arrives and greets - with animated entrance
	other_actor_ctrl.move().right(0.1).over(0.8).using("bounce")  # Bounce in from left
	other_actor_ctrl.pose("waving")
	other_actor_ctrl.express("happy")
	other_actor_ctrl.say("Good morning!")
	
	# Scene 3: Me cheers up - with animated expression change
	me_actor_ctrl.express("neutral").over(0.3)  # Smooth expression transition
	me_actor_ctrl.say("Oh, hey there!")
	
	# Scene 4: Other notices the hair - moves closer with shake
	other_actor_ctrl.move().left(0.05).over(0.6).using("bounce")
	other_actor_ctrl.pose("idle")
	other_actor_ctrl.express("neutral")
	other_actor_ctrl.say("Nice hair!")
	
	# Scene 5: Me fixes hair and feels better
	me_actor_ctrl.act({"body": "default"})
	me_actor_ctrl.express("happy").over(0.4)  # Animated expression change
	me_actor_ctrl.say("Thanks! Let me fix it...")
	
	# Scene 6: Me puts on casual outfit - with animated outfit change
	me_actor_ctrl.wear("casual").over(0.5)  # Fade out, change, fade in
	me_actor_ctrl.say("Much better!")
	
	# Scene 7: Other changes to jeans - animated
	other_actor_ctrl.wear("jeans").over(0.5)
	other_actor_ctrl.express("happy")
	other_actor_ctrl.say("I like those jeans too!")
	
	# Scene 8: Me tries chino pants - animated
	me_actor_ctrl.wear("chino").over(0.5)
	me_actor_ctrl.say("What about these chinos?")
	
	# Scene 9: Other approves and jumps excitedly
	other_actor_ctrl.scaling().up(1.2).over(0.3)  # Scale up
	other_actor_ctrl.pose("waving")
	other_actor_ctrl.scaling().down(1.2).over(0.3)  # Scale back down
	other_actor_ctrl.say("Looking good!")
	
	# Scene 10: Switch to close-up plan (cinematic ratio)
	vn_scene.change_plan("close_up")
	me_actor_ctrl.say("Wait, let me show you something...")
	
	# Scene 11: Both wave happily
	me_actor_ctrl.pose("waving").over(0.3)
	me_actor_ctrl.express("happy")
	me_actor_ctrl.say("Thanks for stopping by!")
	
	other_actor_ctrl.say("See you later!")
	me_actor_ctrl.stop_interact("poke")           # Deactivate (queued as action)
	# Scene 12: Switch back to medium shot
	vn_scene.change_plan("medium_shot")
	
	# Scene 13: Other leaves with smooth animation
	other_actor_ctrl.move().right(0.3).over(1.0).using("smooth")
	
	# Scene 14: Return to idle
	me_actor_ctrl.pose("idle")
	me_actor_ctrl.express("neutral")
