## Transformable - Interface for entities with transform and visibility properties
## Provides position, rotation, scale, visible with observer pattern
## Can be used by Character, Camera, and other transformable entities
class_name Transformable
extends RefCounted

## Position in 3D space (in centimeters for this engine)
var position: Vector3 = Vector3.ZERO

## Rotation (in degrees for storage, converted to radians for rendering)
var rotation: Vector3 = Vector3.ZERO

## Scale (uniform or non-uniform scaling)
var scale: Vector3 = Vector3.ONE

## Whether this entity is visible
var visible: bool = false

## Whether this entity is currently focused (for input handling)
var focused: bool = false

## List of observers (Callables) watching this transformable entity
var _observers: Array = []


func _init(p_position: Vector3 = Vector3.ZERO, p_visible: bool = false) -> void:
	position = p_position
	visible = p_visible


## Sets position and notifies observers
func set_position(new_position: Vector3) -> void:
	if position != new_position:
		position = new_position
		_notify_observers()


## Sets rotation and notifies observers
func set_rotation(new_rotation: Vector3) -> void:
	if rotation != new_rotation:
		rotation = new_rotation
		_notify_observers()


## Sets scale and notifies observers
func set_scale(new_scale: Vector3) -> void:
	if scale != new_scale:
		scale = new_scale
		_notify_observers()


## Sets visibility and notifies observers
func set_visible(new_visible: bool) -> void:
	if visible != new_visible:
		visible = new_visible
		_notify_observers()


## Sets focused state and notifies observers
func set_focused(new_focused: bool) -> void:
	if focused != new_focused:
		focused = new_focused
		_notify_observers()


## Adds an observer to be notified of transform changes
func add_observer(observer: Callable) -> void:
	if not _observers.has(observer):
		_observers.append(observer)


## Removes an observer
func remove_observer(observer: Callable) -> void:
	var idx = _observers.find(observer)
	if idx >= 0:
		_observers.remove_at(idx)


## Notifies all observers of transform changes
## Subclasses should override this to include additional state in the notification
func _notify_observers() -> void:
	var transform_state = _get_transform_state()
	
	for observer in _observers:
		if observer.is_valid():
			observer.call(transform_state)


## Gets the current transform state as a dictionary
## Subclasses can override this to include additional properties
func _get_transform_state() -> Dictionary:
	return {
		"position": position,
		"rotation": rotation,
		"scale": scale,
		"visible": visible,
		"focused": focused
	}

