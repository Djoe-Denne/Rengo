## WaitAction pauses scene execution for a specified duration
extends "res://rengo/controllers/actions/action_node.gd"
class_name WaitAction


func _init(p_duration: float = 1.0) -> void:
	super._init(null, p_duration)
	blocking = true


## Execute the wait
func execute() -> void:
	super.execute()
	# Nothing to do, just wait for the duration


## No per-frame processing needed
func _process_action(_delta: float) -> void:
	pass

