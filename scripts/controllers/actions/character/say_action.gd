## SayAction displays dialog text in the dialog layer
extends "res://scripts/controllers/actions/action_node.gd"
class_name SayAction

## The text to display
var text: String = ""

## The character speaking (optional)
var speaker = null  # Character

## Reference to the dialog UI node
var dialog_box: Control = null

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
	
	# Get or create the dialog box
	var dialog_layer = target.vn_scene.get_node_or_null("DialogLayer")
	if not dialog_layer:
		push_error("SayAction: DialogLayer not found")
		_is_complete = true
		return
	
	dialog_box = dialog_layer.get_node_or_null("DialogBox")
	if not dialog_box:
		# Create a simple dialog box
		dialog_box = create_dialog_box()
		dialog_layer.add_child(dialog_box)
	
	# Display the text
	var speaker_name = ""
	if speaker:
		speaker_name = speaker.resource_name
	
	update_dialog_box(speaker_name, text)
	
	# Setup completion behavior
	if auto_advance:
		duration = auto_advance_delay
	else:
		_waiting_for_input = true


## Creates a simple dialog box UI
func create_dialog_box() -> Control:
	var panel = Panel.new()
	panel.name = "DialogBox"
	
	# Position at bottom of screen
	panel.anchor_left = 0.1
	panel.anchor_right = 0.9
	panel.anchor_top = 0.75
	panel.anchor_bottom = 0.95
	
	# Add a VBox for layout
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 10
	vbox.offset_right = -10
	vbox.offset_top = 10
	vbox.offset_bottom = -10
	panel.add_child(vbox)
	
	# Speaker name label
	var name_label = Label.new()
	name_label.name = "SpeakerName"
	name_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(name_label)
	
	# Dialog text label
	var text_label = Label.new()
	text_label.name = "DialogText"
	text_label.add_theme_font_size_override("font_size", 20)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(text_label)
	
	# Continue indicator
	var continue_label = Label.new()
	continue_label.name = "ContinueIndicator"
	continue_label.text = "▼"
	continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(continue_label)
	
	return panel


## Updates the dialog box with new text
func update_dialog_box(speaker_name: String, dialog_text: String) -> void:
	if not dialog_box:
		return
	
	var name_label = dialog_box.get_node_or_null("VBox/SpeakerName")
	if name_label:
		name_label.text = speaker_name
		name_label.visible = speaker_name != ""
	
	var text_label = dialog_box.get_node_or_null("VBox/DialogText")
	if text_label:
		text_label.text = dialog_text
	
	dialog_box.visible = true


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

