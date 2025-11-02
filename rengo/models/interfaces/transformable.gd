## Transformable - Interface for entities with transform and visibility properties
## Provides position, rotation, scale, visible with observer pattern
## Can be used by Character, Camera, and other transformable entities
class_name Transformable
extends RefCounted

##Signals for transform changes
signal position_changed(new_position: Vector3)
signal rotation_changed(new_rotation: Vector3)
signal scale_changed(new_scale: Vector3)
signal visible_changed(new_visible: bool)
signal focused_changed(new_focused: bool)

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


func _init(p_position: Vector3 = Vector3.ZERO, p_visible: bool = false) -> void:
	position = p_position
	visible = p_visible


## Sets position and notifies observers
func set_position(new_position: Vector3) -> void:
	if position != new_position:
		position = new_position
		position_changed.emit(new_position)

## Sets rotation and notifies observers
func set_rotation(new_rotation: Vector3) -> void:
	if rotation != new_rotation:
		rotation = new_rotation
		rotation_changed.emit(new_rotation)


## Sets scale and notifies observers
func set_scale(new_scale: Vector3) -> void:
	if scale != new_scale:
		scale = new_scale
		scale_changed.emit(new_scale)


## Sets visibility and notifies observers
func set_visible(new_visible: bool) -> void:
	if visible != new_visible:
		visible = new_visible
		visible_changed.emit(new_visible)


## Sets focused state and notifies observers
func set_focused(new_focused: bool) -> void:
	if focused != new_focused:
		focused = new_focused
		focused_changed.emit(new_focused)

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
