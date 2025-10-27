extends Node2D

## Simple demo story: Two friends meet and chat

var vn_scene: VNScene = null
var me_actor: Actor = null
var other_actor: Actor = null


func _ready() -> void:
	# Create VNScene using SceneFactory
	vn_scene = SceneFactory.create("demo_scene")
	if not vn_scene:
		push_error("Failed to create demo scene")
		return
	
	# Add scene to tree
	add_child(vn_scene)
	
	# Cast characters
	me_actor = vn_scene.cast("me")
	other_actor = vn_scene.cast("other")
	
	# Position actors in 3D space (x, y, z in centimeters)
	# y=0 is ground level, x=0 is center, z=0 is at camera origin (positive z goes toward camera)
	me_actor.position = Vector3(-80, 0, -500)   # 80cm to the left, on ground
	other_actor.position = Vector3(80, 0, -500)  # 80cm to the right, on ground
	
	# Build the story action queue
	_play_story()
	
	# Start playing the scene
	vn_scene.play()


func _play_story() -> void:
	# Scene 1: Me wakes up with bed hair
	me_actor.show()
	me_actor.act({"body": "bedhair"})
	me_actor.express("sad")
	me_actor.say("Ugh, I just woke up...")
	
	# Scene 2: Other arrives and greets - with animated entrance
	other_actor.show()
	other_actor.move().right(0.1).over(0.8).using("bounce")  # Bounce in from left
	other_actor.pose("waving")
	other_actor.express("happy")
	other_actor.say("Good morning!")
	
	# Scene 3: Me cheers up - with animated expression change
	me_actor.express("neutral").over(0.3)  # Smooth expression transition
	me_actor.say("Oh, hey there!")
	
	# Scene 4: Other notices the hair - moves closer with shake
	other_actor.move().left(0.05).over(0.6).using("bounce")
	other_actor.pose("idle")
	other_actor.express("neutral")
	other_actor.say("Nice hair!")
	
	# Scene 5: Me fixes hair and feels better
	me_actor.act({"body": "default"})
	me_actor.express("happy").over(0.4)  # Animated expression change
	me_actor.say("Thanks! Let me fix it...")
	
	# Scene 6: Me puts on casual outfit - with animated outfit change
	me_actor.wear("casual").over(0.5)  # Fade out, change, fade in
	me_actor.say("Much better!")
	
	# Scene 7: Other changes to jeans - animated
	other_actor.wear("jeans").over(0.5)
	other_actor.express("happy")
	other_actor.say("I like those jeans too!")
	
	# Scene 8: Me tries chino pants - animated
	me_actor.wear("chino").over(0.5)
	me_actor.say("What about these chinos?")
	
	# Scene 9: Other approves and jumps excitedly
	other_actor.scale().up(1.2).over(0.3)  # Scale up
	other_actor.pose("waving")
	other_actor.scale().down(1.2).over(0.3)  # Scale back down
	other_actor.say("Looking good!")
	
	# Scene 10: Switch to close-up plan (cinematic ratio)
	vn_scene.change_plan("close_up")
	me_actor.say("Wait, let me show you something...")
	
	# Scene 11: Both wave happily
	me_actor.pose("waving").over(0.3)
	me_actor.express("happy")
	me_actor.say("Thanks for stopping by!")
	
	other_actor.say("See you later!")
	
	# Scene 12: Switch back to medium shot
	vn_scene.change_plan("medium_shot")
	
	# Scene 13: Other leaves with smooth animation
	other_actor.move().right(0.3).over(1.0).using("smooth")
	
	# Scene 14: Return to idle
	me_actor.pose("idle")
	me_actor.express("neutral")
