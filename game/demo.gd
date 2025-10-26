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
	
	# Position actors
	var NormalizedPosition = load("res://scripts/utilities/normalized_position.gd")
	me_actor.position = NormalizedPosition.left_bottom(0.3, 0.2, 0.0)
	other_actor.position = NormalizedPosition.right_bottom(0.2, 0.2, 0.0)
	
	# Play the story
	_play_story()
	vn_scene.play()


func _play_story() -> void:
	var ctrl = vn_scene.controller
	
	# Scene 1: Me wakes up with bed hair
	ctrl.action(me_actor.show())
	ctrl.action(me_actor.act({"body": "bedhair"}))
	ctrl.action(me_actor.express("sad"))
	ctrl.action(me_actor.say("Ugh, I just woke up..."))
	
	# Scene 2: Other arrives and greets
	ctrl.action(other_actor.show())
	ctrl.action(other_actor.pose("waving"))
	ctrl.action(other_actor.express("happy"))
	ctrl.action(other_actor.say("Good morning!"))
	
	# Scene 3: Me cheers up
	ctrl.action(me_actor.express("neutral"))
	ctrl.action(me_actor.say("Oh, hey there!"))
	
	# Scene 4: Other notices the hair
	ctrl.action(other_actor.pose("idle"))
	ctrl.action(other_actor.express("neutral"))
	ctrl.action(other_actor.say("Nice hair!"))
	
	# Scene 5: Me fixes hair and feels better
	ctrl.action(me_actor.act({"body": "default"}))
	ctrl.action(me_actor.express("happy"))
	ctrl.action(me_actor.say("Thanks! Let me fix it..."))
	
	# Scene 6: Me puts on casual outfit
	ctrl.action(me_actor.wear("casual"))
	ctrl.action(me_actor.say("Much better!"))
	
	# Scene 7: Other changes to jeans
	ctrl.action(other_actor.wear("jeans"))
	ctrl.action(other_actor.express("happy"))
	ctrl.action(other_actor.say("I like those jeans too!"))
	
	# Scene 8: Me tries chino pants
	ctrl.action(me_actor.wear("chino"))
	ctrl.action(me_actor.say("What about these chinos?"))
	
	# Scene 9: Other approves
	ctrl.action(other_actor.pose("waving"))
	ctrl.action(other_actor.say("Looking good!"))
	
	# Scene 10: Both wave happily
	ctrl.action(me_actor.pose("waving"))
	ctrl.action(me_actor.express("happy"))
	ctrl.action(me_actor.say("Thanks for stopping by!"))
	
	ctrl.action(other_actor.say("See you later!"))
	
	# Scene 11: Return to idle
	ctrl.action(me_actor.pose("idle"))
	ctrl.action(other_actor.pose("idle"))
	ctrl.action(me_actor.express("neutral"))
	ctrl.action(other_actor.express("neutral"))
