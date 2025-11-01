## Machinist - Manages shader application for displayable resources
## Named after theatrical machinists who handle lights and stage effects
## Can be composed into any visual resource (Actors, Backgrounds, etc.)
## Handles state-based shader activation/deactivation with Material.next_pass chaining
class_name Machinist
extends RefCounted

## Shader configuration loaded from YAML { state_name: [shader_defs] }
var shader_config: Dictionary = {}

## Currently active shaders per target { target_key: { state_name: [ShaderMaterials] } }
var active_shaders: Dictionary = {}


## Loads shader configuration from base directories
## @param base_dirs: Array of base directories to search for shaders.yaml
func load_config(base_dirs: Array) -> void:
	if base_dirs.is_empty():
		return
	
	shader_config = ShaderRepository.load_shader_config(base_dirs)


## Updates shaders based on current states
## @param current_states: Dictionary of current state values
## @param target_nodes: Dictionary of { target_key: Node } to apply shaders to
func update_shaders(current_states: Dictionary, target_nodes: Dictionary) -> void:
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
		_apply_shaders_for_state(state_name, shader_defs, current_states, target_nodes)
	
	# Remove shaders for inactive states
	for target_key in active_shaders.keys():
		var target_shaders = active_shaders[target_key]
		for state_name in target_shaders.keys():
			if not state_name in active_state_shaders:
				remove_shaders_for_state(target_key, state_name, target_nodes)


## Applies shaders for a specific state to appropriate targets
func _apply_shaders_for_state(state_name: String, shader_defs: Array, current_states: Dictionary, target_nodes: Dictionary) -> void:
	if shader_defs.is_empty():
		return
	
	# Group shader definitions by target layer (or apply to all if no layer specified)
	for shader_def in shader_defs:
		var target_layer = shader_def.get("layer", "")
		
		# If no specific layer, apply to all targets
		if target_layer == "":
			for target_key in target_nodes.keys():
				var node = target_nodes[target_key]
				_apply_shader_to_node(target_key, state_name, node, [shader_def], current_states)
		else:
			# Apply to specific layer/target
			if target_layer in target_nodes:
				var node = target_nodes[target_layer]
				_apply_shader_to_node(target_layer, state_name, node, [shader_def], current_states)


## Applies shader chain to a specific node
func _apply_shader_to_node(target_key: String, state_name: String, node: Node, shader_defs: Array, current_states: Dictionary) -> void:
	if not node:
		return
	
	# Determine node type and apply accordingly
	if node is MeshInstance3D:
		_apply_shader_chain_3d(target_key, state_name, node, shader_defs, current_states)
	elif node is Sprite2D:
		_apply_shader_chain_2d(target_key, state_name, node, shader_defs, current_states)
	else:
		push_warning("Machinist: Unsupported node type: %s" % node.get_class())


## Applies a shader chain to a 3D mesh (MeshInstance3D)
func _apply_shader_chain_3d(target_key: String, state_name: String, mesh_instance: MeshInstance3D, shader_defs: Array, current_states: Dictionary) -> void:
	if not mesh_instance or not mesh_instance.material_override:
		return
	
	# Initialize active_shaders structure for this target
	if not target_key in active_shaders:
		active_shaders[target_key] = {}
	
	# Check if shaders for this state are already applied
	if state_name in active_shaders[target_key]:
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
	active_shaders[target_key][state_name] = shader_materials
	
	# Rebuild the complete next_pass chain for this target
	_rebuild_shader_chain_3d(target_key, mesh_instance)


## Applies a shader chain to a 2D sprite (Sprite2D)
func _apply_shader_chain_2d(target_key: String, state_name: String, sprite: Sprite2D, shader_defs: Array, current_states: Dictionary) -> void:
	if not sprite:
		return
	
	# Initialize active_shaders structure for this target
	if not target_key in active_shaders:
		active_shaders[target_key] = {}
	
	# Check if shaders for this state are already applied
	if state_name in active_shaders[target_key]:
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
	active_shaders[target_key][state_name] = shader_materials
	
	# Rebuild the complete material chain for this sprite
	_rebuild_shader_chain_2d(target_key, sprite)


## Rebuilds the complete shader chain for a 3D mesh
func _rebuild_shader_chain_3d(target_key: String, mesh_instance: MeshInstance3D) -> void:
	if not mesh_instance or not mesh_instance.material_override:
		return
	
	# Get base material (the material with the texture)
	var base_material = mesh_instance.material_override
	
	# Collect all shader materials from all active states
	var all_shader_materials: Array = []
	
	if target_key in active_shaders:
		for state_name in active_shaders[target_key]:
			var state_shaders = active_shaders[target_key][state_name]
			all_shader_materials.append_array(state_shaders)
	
	# Clear existing next_pass chain
	base_material.next_pass = null
	
	# Rebuild chain: base_material -> shader1 -> shader2 -> ...
	if all_shader_materials.size() > 0:
		base_material.next_pass = all_shader_materials[0]
		
		for i in range(all_shader_materials.size() - 1):
			all_shader_materials[i].next_pass = all_shader_materials[i + 1]
		
		# Last material has no next_pass
		all_shader_materials[-1].next_pass = null


## Rebuilds the complete shader chain for a 2D sprite
func _rebuild_shader_chain_2d(target_key: String, sprite: Sprite2D) -> void:
	if not sprite:
		return
	
	# Collect all shader materials from all active states
	var all_shader_materials: Array = []
	
	if target_key in active_shaders:
		for state_name in active_shaders[target_key]:
			var state_shaders = active_shaders[target_key][state_name]
			all_shader_materials.append_array(state_shaders)
	
	# For 2D, apply the first shader material (they chain via next_pass)
	if all_shader_materials.size() > 0:
		sprite.material = all_shader_materials[0]
		
		# Chain additional shaders via next_pass
		for i in range(all_shader_materials.size() - 1):
			all_shader_materials[i].next_pass = all_shader_materials[i + 1]
		
		# Last material has no next_pass
		all_shader_materials[-1].next_pass = null
	else:
		# No shaders active, clear material
		sprite.material = null


## Removes shaders for a specific state from a target
func remove_shaders_for_state(target_key: String, state_name: String, target_nodes: Dictionary) -> void:
	if not target_key in active_shaders:
		return
	
	if not state_name in active_shaders[target_key]:
		return
	
	# Remove the state's shaders
	active_shaders[target_key].erase(state_name)
	
	# If no more shaders for this target, clean up
	if active_shaders[target_key].is_empty():
		active_shaders.erase(target_key)
	
	# Rebuild the chain without this state's shaders
	if target_key in target_nodes:
		var node = target_nodes[target_key]
		if node is MeshInstance3D:
			_rebuild_shader_chain_3d(target_key, node)
		elif node is Sprite2D:
			_rebuild_shader_chain_2d(target_key, node)


## Clears all active shaders from all targets
func clear_all_shaders(target_nodes: Dictionary) -> void:
	# Clear shader chains from all nodes
	for target_key in target_nodes:
		var node = target_nodes[target_key]
		if node is MeshInstance3D and node.material_override:
			node.material_override.next_pass = null
		elif node is Sprite2D:
			node.material = null
	
	# Clear internal state
	active_shaders.clear()
