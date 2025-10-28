## DialogLayerView - Manages the 2D dialog layer
## Observes DialogModel and updates UI accordingly
## Pure view component - displays what the model tells it to
class_name DialogLayerView
extends RefCounted

## Reference to the DialogLayer CanvasLayer
var layer_node: CanvasLayer = null

## Reference to the DialogBox UI control
var dialog_box: Control = null

## Reference to the DialogModel being observed
var dialog_model: DialogModel = null

## UI element references
var _speaker_label: Label = null
var _text_label: Label = null
var _continue_indicator: Label = null


func _init() -> void:
	pass


## Sets up the dialog layer
func setup_layer(p_layer_node: CanvasLayer) -> void:
	layer_node = p_layer_node
	
	# Create dialog box UI
	dialog_box = create_dialog_box()
	layer_node.add_child(dialog_box)
	
	# Initially hidden
	dialog_box.visible = false


## Observes a DialogModel
func observe(model: DialogModel) -> void:
	# Unsubscribe from previous model if any
	if dialog_model:
		dialog_model.remove_observer(_on_dialog_changed)
	
	# Subscribe to new model
	dialog_model = model
	if dialog_model:
		dialog_model.add_observer(_on_dialog_changed)
		
		# Initial update
		_update_display()


## Observer callback - called when DialogModel changes
func _on_dialog_changed(dialog_state: Dictionary) -> void:
	_update_display()


## Updates the dialog display based on current model state
func _update_display() -> void:
	if not dialog_model or not dialog_box:
		return
	
	# Update visibility
	dialog_box.visible = dialog_model.visible
	
	if not dialog_model.visible:
		return
	
	# Update speaker name
	if _speaker_label:
		_speaker_label.text = dialog_model.speaker_name
		_speaker_label.visible = dialog_model.speaker_name != ""
	
	# Update dialog text
	if _text_label:
		_text_label.text = dialog_model.text
		
		# Apply text color
		_text_label.add_theme_color_override("font_color", dialog_model.color)
	
	# Show continue indicator
	if _continue_indicator:
		_continue_indicator.visible = true


## Creates the dialog box UI
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
	_speaker_label = Label.new()
	_speaker_label.name = "SpeakerName"
	_speaker_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(_speaker_label)
	
	# Dialog text label
	_text_label = Label.new()
	_text_label.name = "DialogText"
	_text_label.add_theme_font_size_override("font_size", 20)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_text_label)
	
	# Continue indicator
	_continue_indicator = Label.new()
	_continue_indicator.name = "ContinueIndicator"
	_continue_indicator.text = "▼"
	_continue_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(_continue_indicator)
	
	return panel


## Shows the dialog
func show_dialog() -> void:
	if dialog_box:
		dialog_box.visible = true


## Hides the dialog
func hide_dialog() -> void:
	if dialog_box:
		dialog_box.visible = false


## Cleanup when view is destroyed
func cleanup() -> void:
	if dialog_model:
		dialog_model.remove_observer(_on_dialog_changed)
		dialog_model = null
	
	if dialog_box and is_instance_valid(dialog_box):
		dialog_box.queue_free()
		dialog_box = null

