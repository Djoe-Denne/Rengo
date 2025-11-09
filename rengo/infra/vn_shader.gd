## VNShader - Data structure for shader configuration
## Replaces dictionary-based shader definitions with proper typing
class_name VNShader
extends RefCounted

## Path to the shader file
var shader_path: String = ""

## Shader parameters dictionary
var params: Dictionary = {}

## Order in the shader chain (lower = earlier)
var order: int = 0

## Padding percentage (0-100+)
var padding: float = 25.0

## Shader material (cached)
var shader_material: ShaderMaterial = null


## Constructor
func _init(p_shader_path: String = "", p_params: Dictionary = {}, p_order: int = 0, p_padding: float = 25.0) -> void:
	shader_path = p_shader_path
	params = p_params
	order = p_order
	padding = p_padding


## Factory method to create from YAML dictionary
static func from_dict(shader_def: Dictionary) -> VNShader:
	var shader = VNShader.new()
	
	# Extract shader path
	if "shader" in shader_def:
		shader.shader_path = shader_def.shader
	
	# Extract parameters
	if "params" in shader_def:
		shader.params = shader_def.params
	
	# Extract order
	if "order" in shader_def:
		shader.order = shader_def.order
	
	# Extract padding (default to 25% if not specified)
	if "padding" in shader_def:
		shader.padding = float(shader_def.padding)
	
	return shader


## Getters
func get_shader_path() -> String:
	return shader_path

func get_params() -> Dictionary:
	return params

func get_order() -> int:
	return order

func get_padding() -> float:
	return padding


## Setters
func set_shader_path(p_path: String) -> void:
	shader_path = p_path

func set_params(p_params: Dictionary) -> void:
	params = p_params

func set_order(p_order: int) -> void:
	order = p_order

func set_padding(p_padding: float) -> void:
	padding = p_padding

func set_shader_material(p_shader_material: ShaderMaterial) -> void:
	shader_material = p_shader_material

func get_shader_material() -> ShaderMaterial:
	return shader_material


## Converts back to dictionary format (for compatibility if needed)
func to_dict() -> Dictionary:
	return {
		"shader": shader_path,
		"params": params,
		"order": order,
		"padding": padding
	}
