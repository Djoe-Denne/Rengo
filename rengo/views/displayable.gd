## Displayable - Multi-pass viewport system for shader effects
## Manages a doubly-linked list of viewport passes, each feeding into the next
class_name Displayable
extends Node2D

## First pass in the chain (input)
var _input_pass: Pass = null

## Last pass in the chain (output)
var _output_pass: Pass = null

## Counter for generating unique pass names
var _pass_counter: int = 0

var postprocessor_builder: PostProcessorBuilder = null

func _init(displayable_name: String = "") -> void:
	name = "Displayable_" + displayable_name

	# Create the first pass (input = output initially)
	_create_initial_pass()


## Creates the initial pass (pass1)
func _create_initial_pass() -> void:
	_input_pass = Pass.new(self)
	_output_pass = Pass.new(self)

	_input_pass.name = "input_pass"
	_output_pass.name = "output_pass"

	_input_pass.set_next(_output_pass)
	_output_pass.set_previous(_input_pass)

func to_builder() -> PostProcessorBuilder:
	if not postprocessor_builder:
		postprocessor_builder = PostProcessorBuilder.take(self)
	return postprocessor_builder

func clear() -> void:
	clear_shader_passes()
	_pass_counter = 0

## Gets the input pass (first pass)
func get_input_pass() -> Pass:
	return _input_pass

## Gets the output pass (last pass)
func get_output_pass() -> Pass:
	return _output_pass

## Gets the number of passes in the chain
func get_pass_count() -> int:
	return _pass_counter - 2 # -2 for _input_pass and _output_pass

func get_padding_multiplier() -> float:
	return _input_pass.get_padding_multiplier()

func set_padding_multiplier(p_padding_multiplier: float) -> void:
	_input_pass.set_padding_multiplier(p_padding_multiplier)
	var textures = _input_pass.get_textures()
	for texture in textures:
		texture.set_scale(Vector2(1.0 + p_padding_multiplier / 100.0, 1.0 + p_padding_multiplier / 100.0))

func clickables_at_uv(uv: Vector2) -> Array:
	return _input_pass.clickables_at_uv(uv)

## Clears all passes except the first one
func clear_shader_passes() -> void:
	if not _input_pass:
		return
	
	# Remove all passes after the first
	var current = _input_pass	
	while current != null:
		var next_pass = current.get_next()
		current.clear()
		remove_child(current)
		current = next_pass
	
	_input_pass.set_next(_output_pass)
	_output_pass.set_previous(_input_pass)
	add_child(_input_pass)
	add_child(_output_pass)
	#displayable_changed.emit(self)

func recompose() -> void:
	_input_pass.recompose()
