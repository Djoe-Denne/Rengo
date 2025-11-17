## DialogModel - Pure data model for dialog state
## Holds dialog text, speaker, and visibility
## Notifies observers (DialogLayerView) when dialog changes
class_name DialogModel
extends RefCounted

## Display name of the speaker
var speaker_name: String = ""

## Reference to the speaking character (optional)
var character: Character = null

## Dialog text to display
var text: String = ""

## Text color (from character or custom)
var color: Color = Color.WHITE

## Whether dialog box is visible
var visible: bool = false

## Dialog choices for branching (future feature)
var choices: Array = []

## Dialog history for backlog (future feature)
var history: Array = []

## List of observers (DialogLayerView) watching this dialog
var _observers: Array = []

## static instance of DialogModel
static var instance: DialogModel = null

static func get_instance() -> DialogModel:
	if not instance:
		instance = DialogModel.new()
	return instance

func _init() -> void:
	pass


## Shows dialog with specified parameters
func show_dialog(p_speaker_name: String, p_text: String, p_color: Color = Color.WHITE) -> void:
	speaker_name = p_speaker_name
	text = p_text
	color = p_color
	visible = true
	
	# Add to history
	add_to_history(p_speaker_name, p_text)
	
	_notify_observers()


## Hides the dialog box
func hide_dialog() -> void:
	visible = false
	_notify_observers()


## Clears the dialog text
func clear_dialog() -> void:
	speaker_name = ""
	text = ""
	visible = false
	_notify_observers()


## Updates dialog text without changing visibility
func set_text(p_text: String) -> void:
	if text != p_text:
		text = p_text
		_notify_observers()


## Updates speaker without changing visibility
func set_speaker(p_speaker_name: String, p_color: Color = Color.WHITE) -> void:
	if speaker_name != p_speaker_name or color != p_color:
		speaker_name = p_speaker_name
		color = p_color
		_notify_observers()


## Sets the speaking character reference
func set_character(p_character: Character) -> void:
	character = p_character
	if character:
		# Use character's display name and dialog color
		speaker_name = character.display_name if character.display_name != "" else character.name
		color = character.dialog_color


## Adds dialog to history
func add_to_history(p_speaker: String, p_text: String) -> void:
	history.append({
		"speaker": p_speaker,
		"text": p_text,
		"timestamp": Time.get_ticks_msec()
	})


## Adds an observer to be notified of dialog changes
func add_observer(observer: Callable) -> void:
	if not _observers.has(observer):
		_observers.append(observer)


## Removes an observer
func remove_observer(observer: Callable) -> void:
	var idx = _observers.find(observer)
	if idx >= 0:
		_observers.remove_at(idx)


## Notifies all observers of dialog changes
func _notify_observers() -> void:
	var dialog_state = {
		"speaker_name": speaker_name,
		"text": text,
		"color": color,
		"visible": visible,
		"choices": choices
	}
	
	for observer in _observers:
		if observer.is_valid():
			observer.call(dialog_state)
