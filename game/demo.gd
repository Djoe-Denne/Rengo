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
	var NormalizedPosition = load("res://scripts/infra/normalized_position.gd")
	me_actor.position = NormalizedPosition.left_bottom(0.3, 0.2, 0.0)
	other_actor.position = NormalizedPosition.right_bottom(0.2, 0.2, 0.0)
	
	# Play the story
	_play_story()
	vn_scene.play()


func _play_story() -> void:
	# Scene 1: Me wakes up with bed hair
	me_actor.show()
	me_actor.act({"body": "bedhair"})
	me_actor.express("sad")
	me_actor.say("Ugh, I just woke up...")
	
	# Scene 2: Other arrives and greets
	other_actor.show()
	other_actor.pose("waving")
	other_actor.express("happy")
	other_actor.say("Good morning!")
	
	# Scene 3: Me cheers up
	me_actor.express("neutral")
	me_actor.say("Oh, hey there!")
	
	# Scene 4: Other notices the hair
	other_actor.pose("idle")
	other_actor.express("neutral")
	other_actor.say("Nice hair!")
	
	# Scene 5: Me fixes hair and feels better
	me_actor.act({"body": "default"})
	me_actor.express("happy")
	me_actor.say("Thanks! Let me fix it...")
	
	# Scene 6: Me puts on casual outfit
	me_actor.wear("casual")
	me_actor.say("Much better!")
	
	# Scene 7: Other changes to jeans
	other_actor.wear("jeans")
	other_actor.express("happy")
	other_actor.say("I like those jeans too!")
	
	# Scene 8: Me tries chino pants
	me_actor.wear("chino")
	me_actor.say("What about these chinos?")
	
	# Scene 9: Other approves
	other_actor.pose("waving")
	other_actor.say("Looking good!")
	
	# Scene 10: Both wave happily
	me_actor.pose("waving")
	me_actor.express("happy")
	me_actor.say("Thanks for stopping by!")
	
	other_actor.say("See you later!")
	
	# Scene 11: Return to idle
	me_actor.pose("idle")
	other_actor.pose("idle")
	me_actor.express("neutral")
	other_actor.express("neutral")
