## ScreenModel - Base class for all screen models
## Pure data model with observer pattern
## Follows same architecture as Character and Scene models in rengo/
class_name ScreenModel
extends RefCounted

## Screen identifier (e.g., "title", "options", "save_load")
var screen_name: String = ""

## Whether this screen is currently active
var is_active: bool = false

## List of observers (Callables) watching this screen
var _observers: Array = []


func _init(p_screen_name: String = "") -> void:
	screen_name = p_screen_name


## Activates the screen and notifies observers
func activate() -> void:
	if not is_active:
		is_active = true
		_notify_observers()


## Deactivates the screen and notifies observers
func deactivate() -> void:
	if is_active:
		is_active = false
		_notify_observers()


## Adds an observer to be notified of state changes
func add_observer(observer: Callable) -> void:
	if not _observers.has(observer):
		_observers.append(observer)


## Removes an observer
func remove_observer(observer: Callable) -> void:
	var idx = _observers.find(observer)
	if idx >= 0:
		_observers.remove_at(idx)


## Notifies all observers of state changes
## Override this in subclasses to provide specific state data
func _notify_observers() -> void:
	var state = _get_state()
	
	for observer in _observers:
		if observer.is_valid():
			observer.call(state)


## Gets the current state as a dictionary
## Override this in subclasses to include specific state data
func _get_state() -> Dictionary:
	return {
		"screen_name": screen_name,
		"is_active": is_active
	}

