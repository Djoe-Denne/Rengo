## ShaderRepository - Singleton for centralized shader loading and management
## Handles shader loading, caching, and ShaderMaterial creation with parameter binding
extends Node

## Cache of loaded shaders { shader_path: Shader }
var _shader_cache: Dictionary = {}


## Loads a shader from the given path and caches it
## @param shader_path: Path to the .gdshader file
## @return: Loaded Shader or null on error
func load_shader(shader_path: String) -> Shader:
	if shader_path == "":
		return null
	
	# Check cache first
	if shader_path in _shader_cache:
		return _shader_cache[shader_path]
	
	# Resolve path (support both absolute and relative paths)
	var full_path = shader_path
	if not shader_path.begins_with("res://"):
		full_path = "res://" + shader_path
	
	# Load shader
	if not ResourceLoader.exists(full_path):
		push_warning("Shader file not found: %s" % full_path)
		return null
	
	var shader = load(full_path)
	if shader is Shader:
		_shader_cache[shader_path] = shader
		return shader
	else:
		push_error("Failed to load shader: %s" % full_path)
		return null


## Creates a ShaderMaterial from a shader definition with parameter resolution
## @param shader_def: Dictionary with shader config (shader path, params, etc.)
## @param state: State dictionary for resolving template parameters
## @return: Configured ShaderMaterial or null on error
func create_shader_material(shader_def: Dictionary, state: Dictionary) -> ShaderMaterial:
	if not "shader" in shader_def:
		push_warning("Shader definition missing 'shader' path")
		return null
	
	var shader_path = shader_def.shader
	var shader = load_shader(shader_path)
	
	if not shader:
		return null
	
	# Create ShaderMaterial
	var material = ShaderMaterial.new()
	material.shader = shader
	
	# Apply parameters if provided
	if "params" in shader_def:
		var params = shader_def.params
		for param_name in params:
			var param_value = params[param_name]
			
			# Resolve template parameters from state
			if param_value is String:
				param_value = _resolve_parameter_value(param_value, state)
			
			# Set shader parameter (convert types as needed)
			_set_shader_param(material, param_name, param_value)
	
	return material


## Loads shader configuration from YAML files in base directories
## @param base_dirs: Array of base directories to search
## @return: Dictionary with shader configurations { state_name: [shader_defs] }
func load_shader_config(base_dirs: Array) -> Dictionary:
	if base_dirs.is_empty():
		return {}
	
	# Load shaders.yaml using ResourceRepository
	var shader_data = ResourceRepository.load_yaml(base_dirs, "shaders", false)
	
	if shader_data.is_empty():
		return {}
	
	# Extract shaders dictionary
	if "shaders" in shader_data:
		return shader_data.shaders
	
	return shader_data


## Resolves a parameter value from state (supports template syntax)
## @param value: Parameter value (may contain {placeholder} templates)
## @param state: State dictionary for resolution
## @return: Resolved value
func _resolve_parameter_value(value: String, state: Dictionary) -> Variant:
	# Use ResourceRepository's template resolution for consistency
	var resolved = ResourceRepository.resolve_template_path(value, state)
	
	# If still contains placeholders or is empty, return the original value
	if resolved == "" or resolved.contains("{"):
		return value
	
	# Try to parse as color if it looks like a color
	if resolved.begins_with("#") or resolved.begins_with("("):
		var color = _parse_color(resolved)
		if color != null:
			return color
	
	# Try to parse as number
	if resolved.is_valid_float():
		return float(resolved)
	
	return resolved


## Parses a color from various string formats
## @param color_str: Color string (hex, rgb, rgba, named)
## @return: Color or null if parsing fails
func _parse_color(color_str: String) -> Variant:
	# Hex format: #RRGGBB or #RRGGBBAA
	if color_str.begins_with("#"):
		return Color(color_str)
	
	# RGB/RGBA format: (r, g, b) or (r, g, b, a)
	if color_str.begins_with("(") and color_str.ends_with(")"):
		var components = color_str.substr(1, color_str.length() - 2).split(",")
		if components.size() >= 3:
			var r = float(components[0].strip_edges())
			var g = float(components[1].strip_edges())
			var b = float(components[2].strip_edges())
			var a = 1.0
			if components.size() >= 4:
				a = float(components[3].strip_edges())
			return Color(r, g, b, a)
	
	# Named colors (Godot built-in)
	match color_str.to_lower():
		"white": return Color.WHITE
		"black": return Color.BLACK
		"red": return Color.RED
		"green": return Color.GREEN
		"blue": return Color.BLUE
		"yellow": return Color.YELLOW
		"cyan": return Color.CYAN
		"magenta": return Color.MAGENTA
	
	return null


## Sets a shader parameter with automatic type conversion
## @param material: ShaderMaterial to set parameter on
## @param param_name: Name of the shader parameter
## @param value: Value to set (will be converted to appropriate type)
func _set_shader_param(material: ShaderMaterial, param_name: String, value: Variant) -> void:
	if not material or not material.shader:
		return
	
	# Set the parameter directly - Godot handles type conversion
	material.set_shader_parameter(param_name, value)


## Clears the shader cache (useful for hot-reloading during development)
func clear_cache() -> void:
	_shader_cache.clear()

