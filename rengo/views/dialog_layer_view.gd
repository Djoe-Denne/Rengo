## DialogLayerView - Manages the 2D dialog layer
## Observes DialogModel and updates UI accordingly
## Pure view component - displays what the model tells it to
class_name DialogLayerView
extends CanvasLayer

## Reference to the DialogBox UI control
@onready var dialog_box: Control = $DialogBox

## Reference to the DialogModel being observed
@onready var dialog_model: DialogModel = DialogModel.get_instance()

@onready var _speaker_label: Label = $DialogBox/VBox/SpeakerName
@onready var _text_label: Label = $DialogBox/VBox/DialogText
@onready var _continue_indicator: Label = $DialogBox/VBox/ContinueIndicator

static var instance: DialogLayerView = null
static func get_instance() -> DialogLayerView:
	if not instance:
		DialogLayerView.new()
	return instance

func _init() -> void:
	instance = self

## Observes a DialogModel
func _ready() -> void:
	if not dialog_box:
		dialog_box = create_dialog_box()
		add_child(dialog_box)
		dialog_box.visible = false

	dialog_model.add_observer(_on_dialog_changed)
	_update_display()

## Observer callback - called when DialogModel changes
func _on_dialog_changed(dialog_state: Dictionary) -> void:
	_update_display()


## Updates the dialog display based on current model state
func _update_display() -> void:
	dialog_box.visible = dialog_model.visible
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
