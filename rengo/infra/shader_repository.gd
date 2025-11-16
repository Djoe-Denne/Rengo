## ShaderRepository - Singleton for centralized shader loading and management
## Handles shader loading, caching, and ShaderMaterial creation with parameter binding
extends Node

## Cache of loaded shader materials { <hash of: shader_path + key>: ShaderMaterial }
var _material_cache: Dictionary = {}


## Loads a shader from the given path and caches it
## @param shader_path: Path to the .gdshader file
## @return: Loaded Shader or null on error
func load_shader(shader_path: String) -> Shader:
	if shader_path == "":
		return null
	
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
		return shader
	else:
		push_error("Failed to load shader: %s" % full_path)
		return null


## Creates a ShaderMaterial from a VNShader with parameter resolution
## @param vn_shader: VNShader with shader config (shader path, params, etc.)
## @param model: DisplayableModel for resolving template parameters
## @return: Configured ShaderMaterial or null on error
func load_shader_material(vn_shader: VNShader, model: DisplayableModel, key: String = "") -> ShaderMaterial:
	if not vn_shader:
		push_warning("VNShader is null")
		return null
	
	var shader_path = vn_shader.get_shader_path()
	if shader_path == "":
		push_warning("Shader definition missing 'shader' path")
		return null

	var material = null
	var cache_key = "%s|%s" % [shader_path, key]
	if not cache_key in _material_cache:
		
		var shader = load_shader(shader_path)
		
		if not shader:
			return null
		
		# Create ShaderMaterial
		material = ShaderMaterial.new()
		material.shader = shader
		
		_material_cache[cache_key] = material
	else:
		material = _material_cache[cache_key]

	set_shader_parameters(material, vn_shader, model)
	return material


func set_shader_parameters(material: ShaderMaterial, vn_shader: VNShader, model: DisplayableModel) -> void:
	# Apply parameters if provided
	var params = vn_shader.get_params()
	for param_name in params:
		var param_value = params[param_name]
		
		# Resolve template parameters from state
		if param_value is String:
			param_value = _resolve_parameter_value(param_value, model)
		
		# Set shader parameter (convert types as needed)
		_set_shader_param(material, param_name, param_value)
	

## Loads shader configuration from YAML files in base directories
## @param base_dirs: Array of base directories to search
## @return: Dictionary with shader configurations { state_name: Array[VNShader] }
func load_shader_config(base_dirs: Array) -> Dictionary:
	if base_dirs.is_empty():
		return {}
	
	# Load shaders.yaml using ResourceRepository
	var shader_data = ResourceRepository.load_yaml(base_dirs, "shaders", false)
	
	if shader_data.is_empty():
		return {}
	
	# Extract shaders dictionary
	var raw_shaders = {}
	if "shaders" in shader_data:
		raw_shaders = shader_data.shaders
	else:
		raw_shaders = shader_data
	
	# Convert shader definitions to VNShader objects
	var converted_shaders = {}
	for state_name in raw_shaders:
		var shader_list = raw_shaders[state_name]
		if shader_list is Array:
			var vn_shader_array: Array[VNShader] = []
			for shader_def in shader_list:
				if shader_def is Dictionary:
					var vn_shader = VNShader.from_dict(shader_def)
					vn_shader_array.append(vn_shader)
			converted_shaders[state_name] = vn_shader_array
	
	return converted_shaders


## Resolves a parameter value from state (supports template syntax)
## @param value: Parameter value (may contain {placeholder} templates)
## @param state: State dictionary for resolution
## @return: Resolved value
func _resolve_parameter_value(value: String, model: DisplayableModel) -> Variant:
	# Use ResourceRepository's template resolution for consistency
	var resolved = ResourceRepository.resolve_template_path(value, model.get_states())
	
	# If still contains placeholders or is empty, return the original value
	if resolved == "" or resolved.contains("{"):
		return _resolve_parameter_value_by_model_property(value, model)
	
	# Try to parse as color if it looks like a color
	if resolved.begins_with("#") or resolved.begins_with("("):
		var color = _parse_color(resolved)
		if color != null:
			return color
	
	# Try to parse as number
	if resolved.is_valid_float():
		return float(resolved)
	
	return resolved


## Resolves a parameter value from model properties
## @param value: Parameter value (may contain @property_name syntax)
## @param model: Model to resolve parameter value from
## @return: Resolved value
func _resolve_parameter_value_by_model_property(value: String, model: DisplayableModel) -> Variant:
	# Check for @property_name syntax
	var regex = RegEx.new()
	regex.compile("@(\\w+)")
	var match_result = regex.search(value)
	
	if not match_result:
		return value  # No property reference
	
	var property_name = match_result.get_string(1)
	
	# Use reflection to get property value
	if property_name in model:
		var property_value = model.get(property_name)
		
		# If the entire value is just @property_name, return the property directly
		if value == "@" + property_name:
			return property_value
		
		# Otherwise, replace @property_name with the stringified value
		return value.replace("@" + property_name, str(property_value))
	
	# Property not found, return original value
	push_warning("Property '%s' not found in model" % property_name)
	return value


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
	_material_cache.clear()
