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

## Pass pool for reusing inactive passes
var _pass_pool: Array[Pass] = []

## Currently active shader passes (between input and output)
var _active_passes: Array[Pass] = []

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

## Clears all passes except the first one (but pools them for reuse)
func clear_shader_passes() -> void:
	if not _input_pass:
		return
	
	# Deactivate and pool all shader passes between input and output
	var current = _input_pass.get_next()
	while current != null and current != _output_pass:
		var next_pass = current.get_next()
		
		# Deactivate the pass
		current.set_active(false)
		
		# Move to pool for reuse
		_pass_pool.append(current)
		
		current = next_pass
	
	# Clear active passes list
	_active_passes.clear()
	
	# Link input directly to output
	_input_pass.set_next(_output_pass)
	_output_pass.set_previous(_input_pass)
	#displayable_changed.emit(self)

func recompose() -> void:
	_input_pass.recompose()

## Gets a Pass from the pool that matches the shader, or creates a new one
## @param shader: VNShader to match
## @return: Pass object (reused from pool or newly created)
func _get_or_create_pass(shader: VNShader) -> Pass:
	# Search pool for matching Pass
	for i in range(_pass_pool.size() - 1, -1, -1):
		var pooled_pass = _pass_pool[i]
		if _matches_shader(pooled_pass, shader):
			# Found a match - remove from pool and reuse
			_pass_pool.remove_at(i)
			pooled_pass.set_active(true)
			return pooled_pass
	
	# No match found - create new Pass
	var new_pass = Pass.new(self, shader)
	return new_pass

## Checks if a Pass matches a shader (by path and params)
## @param pass: Pass to check
## @param shader: VNShader to match against
## @return: True if they match
func _matches_shader(p_pass: Pass, shader: VNShader) -> bool:
	var pass_shader = p_pass.get_shader()
	if not pass_shader or not shader:
		return false
	
	# Compare shader path
	if pass_shader.get_shader_path() != shader.get_shader_path():
		return false
	
	# Compare shader parameters (keys and values)
	var pass_params = pass_shader.get_params()
	var shader_params = shader.get_params()
	
	if pass_params.size() != shader_params.size():
		return false
	
	for key in pass_params:
		if not key in shader_params:
			return false
		if pass_params[key] != shader_params[key]:
			return false
	
	return true

## Gets all currently active shader passes
func get_active_passes() -> Array[Pass]:
	return _active_passes.duplicate()

## Adds a pass to the active passes list
func _add_active_pass(p_pass: Pass) -> void:
	if not p_pass in _active_passes:
		_active_passes.append(p_pass)
