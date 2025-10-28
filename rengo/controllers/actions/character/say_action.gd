## SayAction displays dialog text using DialogModel
## Updates the model, DialogLayerView observes and updates UI
extends "res://rengo/controllers/actions/action_node.gd"
class_name SayAction

## The text to display
var text: String = ""

## The character speaking (ActorController with Character model and Actor view)
var speaker = null  # ActorController

## Reference to the DialogModel
var dialog_model: DialogModel = null

## Whether to auto-advance after display
var auto_advance: bool = false

## Auto-advance delay (in seconds)
var auto_advance_delay: float = 2.0

## Internal flag for waiting for user input
var _waiting_for_input: bool = false


func _init(p_speaker = null) -> void:
	super._init(p_speaker, 0.0, true)
	speaker = p_speaker
	blocking = true


## Start displaying the dialog
func execute() -> void:
	super.execute()
	
	if not target or not target.vn_scene:
		push_error("SayAction: no target or VNScene")
		_is_complete = true
		return
	
	# Get the DialogModel from VNScene
	if "dialog_model" not in target.vn_scene:
		push_error("SayAction: VNScene does not have dialog_model")
		_is_complete = true
		return
	
	dialog_model = target.vn_scene.dialog_model
	if not dialog_model:
		push_error("SayAction: dialog_model is null")
		_is_complete = true
		return
	
	# Prepare speaker info
	var speaker_name = ""
	var speaker_color = Color.WHITE
	
	if speaker:
		# Speaker is an ActorController with model and view
		if "model" in speaker and speaker.model:
			var character = speaker.model
			speaker_name = character.display_name if character.display_name != "" else character.character_name
			speaker_color = character.dialog_color
		elif "name" in speaker:
			speaker_name = speaker.name
	
	# Update the DialogModel - this will notify DialogLayerView
	dialog_model.show_dialog(speaker_name, text, speaker_color)
	
	# Setup completion behavior
	if auto_advance:
		duration = auto_advance_delay
	else:
		_waiting_for_input = true




## Process the action (check for input)
func _process_action(_delta: float) -> void:
	if _waiting_for_input:
		# Check for input to advance
		if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE):
			_is_complete = true
			_waiting_for_input = false


## Builder method to enable auto-advance
func with_auto_advance(delay: float = 2.0) -> SayAction:
	auto_advance = true
	auto_advance_delay = delay
	duration = delay
	return self


## Builder method to set the text
func with_text(p_text: String) -> SayAction:
	text = p_text
	return self
