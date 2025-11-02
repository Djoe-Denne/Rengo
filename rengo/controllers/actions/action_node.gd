## Base class for all visual novel scene actions
## ActionNodes represent things that happen in the scene (show, hide, say, etc.)
class_name ActionNode
extends RefCounted

## The resource this action operates on (can be null for some actions)
var target = null  # ResourceNode

## How long this action takes to complete (in seconds)
var duration: float = 0.0

var feed_back_wait: bool = false

## Whether scene execution should wait for this action to complete
var blocking: bool = true

## Internal state tracking
var _elapsed_time: float = 0.0
var _is_complete: bool = false
var _is_started: bool = false


func _init(p_target = null, p_duration: float = 0.0, p_feed_back_wait: bool = false) -> void:
	target = p_target
	duration = p_duration
	feed_back_wait = p_feed_back_wait


## Called once when the action starts
## Should be overridden by subclasses
func execute() -> void:
	_is_started = true
	if !feed_back_wait and duration <= 0.0:
		_is_complete = true


## Called every frame while the action is running
## Should be overridden by subclasses for animated actions
## Returns true when the action is complete
func process_action(delta: float) -> bool:
	if not _is_started:
		execute()
	
	if _is_complete:
		return true
	
	if !feed_back_wait:
		_elapsed_time += delta
		
		if _elapsed_time >= duration:
			_is_complete = true
			on_complete()
			return true
	
	# Call subclass implementation
	_process_action(delta)
	return false


## Override this for custom per-frame processing
func _process_action(_delta: float) -> void:
	pass


## Called when the action completes
func on_complete() -> void:
	pass


## Check if the action is complete
func is_complete() -> bool:
	return _is_complete


## Get the progress of the action (0.0 to 1.0)
func get_progress() -> float:
	if duration <= 0.0:
		return 1.0
	return clamp(_elapsed_time / duration, 0.0, 1.0)
