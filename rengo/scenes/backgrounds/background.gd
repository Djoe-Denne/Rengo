## Background scene script
## Represents a background in the visual novel
extends Sprite2D

## Background ID
@export var background_id: String = ""

## Background configuration
var config: Dictionary = {}

## Current background states (for shader activation)
var current_states: Dictionary = {}

## Shader configuration loaded from YAML { state_name: [shader_defs] }
var shader_config: Dictionary = {}

## Currently active shaders { state_name: [ShaderMaterials] }
var active_shaders: Dictionary = {}


func _ready() -> void:
	# Configure background if config is set
	if config:
		_apply_config()
	
	# Load shader configuration if background_id is set
	if background_id != "":
		_load_shader_config()


## Applies configuration to the background
func _apply_config() -> void:
	if "image" in config:
		var image_path = config.image
		if ResourceLoader.exists(image_path):
			texture = load(image_path)
	
	if "color" in config:
		var color_data = config.color
		if color_data is Array and color_data.size() >= 3:
			var color = Color(color_data[0], color_data[1], color_data[2])
			texture = _create_color_texture(color)


## Creates a colored texture
func _create_color_texture(color: Color, size: Vector2 = Vector2(800, 600)) -> Texture2D:
	var image = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


## Loads shader configuration for this background
func _load_shader_config() -> void:
	# Construct base directories for background resources
	var base_dirs = _get_background_base_dirs()
	
	if base_dirs.is_empty():
		return
	
	shader_config = ShaderRepository.load_shader_config(base_dirs)


## Gets base directories for background resources
func _get_background_base_dirs() -> Array:
	var base_dirs = []
	
	# Try scene-specific backgrounds
	if "scene_path" in config and config.scene_path != "":
		var scene_bg_path = "res://assets/scenes/" + config.scene_path + "/backgrounds/" + background_id + "/"
		if DirAccess.dir_exists_absolute(scene_bg_path):
			base_dirs.append(scene_bg_path)
	
	# Try common backgrounds
	var common_bg_path = "res://assets/scenes/common/backgrounds/" + background_id + "/"
	if DirAccess.dir_exists_absolute(common_bg_path):
		base_dirs.append(common_bg_path)
	
	return base_dirs


## Sets a background state value
func set_state(key: String, value: Variant) -> void:
	if current_states.get(key) != value:
		current_states[key] = value
		_update_shaders()


## Updates multiple states at once
func update_states(new_states: Dictionary) -> void:
	var changed = false
	for key in new_states:
		if current_states.get(key) != new_states[key]:
			current_states[key] = new_states[key]
			changed = true
	
	if changed:
		_update_shaders()


## Updates shaders based on current background states
func _update_shaders() -> void:
	if shader_config.is_empty():
		return
	
	# Track which states are currently active that have shader configurations
	var active_state_shaders: Dictionary = {}
	
	# Check each state in current_states to see if it has shader config
	for state_key in current_states:
		var state_value = current_states[state_key]
		
		# Check if this state value has a shader configuration
		if state_value in shader_config:
			active_state_shaders[state_value] = shader_config[state_value]
	
	# Apply shaders for active states
	for state_name in active_state_shaders:
		var shader_defs = active_state_shaders[state_name]
		_apply_shaders_for_state(state_name, shader_defs)
	
	# Remove shaders for inactive states
	for state_name in active_shaders.keys():
		if not state_name in active_state_shaders:
			_remove_shaders_for_state(state_name)


## Applies shaders for a specific state
func _apply_shaders_for_state(state_name: String, shader_defs: Array) -> void:
	if shader_defs.is_empty():
		return
	
	# Check if shaders for this state are already applied
	if state_name in active_shaders:
		return  # Already applied
	
	# Sort shader definitions by order
	var sorted_defs = shader_defs.duplicate()
	sorted_defs.sort_custom(func(a, b): return a.get("order", 0) < b.get("order", 0))
	
	# Create shader materials
	var shader_materials: Array = []
	for shader_def in sorted_defs:
		var shader_material = ShaderRepository.create_shader_material(shader_def, current_states)
		if shader_material:
			shader_materials.append(shader_material)
	
	if shader_materials.is_empty():
		return
	
	# Store shader materials for this state
	active_shaders[state_name] = shader_materials
	
	# Rebuild the complete material chain
	_rebuild_shader_chain()


## Rebuilds the complete shader chain
func _rebuild_shader_chain() -> void:
	# For 2D sprites, we need to create or update the material
	# Note: Sprite2D uses CanvasItemMaterial or ShaderMaterial
	
	# Collect all shader materials from all active states
	var all_shader_materials: Array = []
	
	for state_name in active_shaders:
		var state_shaders = active_shaders[state_name]
		all_shader_materials.append_array(state_shaders)
	
	# For 2D, we can only apply one shader at a time, or use next_pass
	# Apply the first shader material (they should be chained via next_pass)
	if all_shader_materials.size() > 0:
		material = all_shader_materials[0]
		
		# Chain additional shaders via next_pass
		for i in range(all_shader_materials.size() - 1):
			all_shader_materials[i].next_pass = all_shader_materials[i + 1]
		
		# Last material has no next_pass
		all_shader_materials[-1].next_pass = null
	else:
		# No shaders active, clear material
		material = null


## Removes shaders for a specific state
func _remove_shaders_for_state(state_name: String) -> void:
	if not state_name in active_shaders:
		return
	
	# Remove the state's shaders
	active_shaders.erase(state_name)
	
	# Rebuild the chain without this state's shaders
	_rebuild_shader_chain()

