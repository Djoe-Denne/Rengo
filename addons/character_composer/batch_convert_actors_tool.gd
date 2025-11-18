@tool
extends EditorScript

## Batch Character Composition Creator
## Scans the current scene for Actor nodes and creates blank CharacterCompositionResource files
## NO YAML dependency - creates empty resources that you build visually in the editor
## Will NOT overwrite existing .tres files.
## Usage: Open this script in Godot editor and select File > Run

func _run() -> void:
	print("=== Batch Actor Resource Creator ===")
	
	# Get the current scene
	var editor_interface = get_editor_interface()
	var edited_scene = editor_interface.get_edited_scene_root()
	
	if not edited_scene:
		push_error("No scene is currently open. Please open a scene with Actor nodes.")
		return
	
	print("Scanning scene: %s" % edited_scene.name)
	
	# Find all Actor nodes in the scene
	var actors = _find_all_actors(edited_scene)
	
	if actors.is_empty():
		print("No Actor nodes found in the current scene.")
		return
	
	print("Found %d Actor node(s):" % actors.size())
	for actor in actors:
		var actor_name_value = ""
		if "actor_name" in actor:
			actor_name_value = actor.get("actor_name")
		print("  - %s (actor_name: '%s')" % [actor.name, actor_name_value])
	
	# Create blank resource for each actor
	var created_count = 0
	var skipped_count = 0
	var failed_count = 0
	
	for actor in actors:
		var result = _create_blank_resource(actor)
		if result == CreationResult.SUCCESS:
			created_count += 1
		elif result == CreationResult.SKIPPED:
			skipped_count += 1
		else:
			failed_count += 1
	
	print("\n=== Creation Complete ===")
	print("✓ Created: %d" % created_count)
	print("⊘ Skipped (already exists): %d" % skipped_count)
	print("✗ Failed: %d" % failed_count)


enum CreationResult {
	SUCCESS,
	SKIPPED,
	FAILED
}


## Finds all Actor nodes recursively in the scene tree
func _find_all_actors(node: Node) -> Array:
	var actors = []
	
	# Check if this node is an Actor
	if node.get_script() and node.get_script().get_global_name() == "Actor":
		actors.append(node)
	
	# Recursively check children
	for child in node.get_children():
		actors.append_array(_find_all_actors(child))
	
	return actors


## Creates a blank CharacterCompositionResource for an Actor node
func _create_blank_resource(actor: Node) -> CreationResult:
	# Get actor_name
	var character_name = ""
	if "actor_name" in actor:
		character_name = actor.get("actor_name")
	
	if not character_name or character_name == "":
		push_error("Actor '%s' has no actor_name set. Skipping." % actor.name)
		return CreationResult.FAILED
	
	print("\nProcessing actor: %s" % character_name)
	
	# Check if resource already exists
	var resource_path = _get_resource_path(character_name)
	if ResourceLoader.exists(resource_path):
		print("  ⊘ Resource already exists: %s" % resource_path)
		return CreationResult.SKIPPED
	
	# Ensure character directory exists
	var character_dir = _get_character_directory(character_name)
	if not DirAccess.dir_exists_absolute(character_dir):
		print("  → Creating directory: %s" % character_dir)
		DirAccess.make_dir_recursive_absolute(character_dir)
	
	# Create blank CharacterCompositionResource
	var composition_resource = CharacterCompositionResource.new()
	composition_resource.character_name = character_name
	
	# Set basic defaults
	composition_resource.display_name = character_name.capitalize()
	composition_resource.dialog_color = Color.WHITE
	composition_resource.inner_dialog_color = Color(1.0, 1.0, 1.0, 0.5)
	
	# Get base_size from actor if available, otherwise use default
	if "base_size" in actor and actor.get("base_size") != Vector2(100, 100):
		composition_resource.base_size = actor.get("base_size")
		print("  → Using base_size from Actor: %s" % composition_resource.base_size)
	else:
		composition_resource.base_size = Vector2(80, 170)
		print("  → Using default base_size: %s" % composition_resource.base_size)
	
	# Set default states
	composition_resource.default_states = {
		"orientation": "front",
		"pose": "idle",
		"expression": "neutral",
		"outfit": "default",
		"body": "default"
	}
	
	# NO layers created - completely blank for manual setup
	print("  → Created blank resource (no layers)")
	
	# Save the resource
	print("  → Saving resource to: %s" % resource_path)
	var save_error = ResourceSaver.save(composition_resource, resource_path)
	
	if save_error == OK:
		print("  ✓ Successfully created blank CharacterCompositionResource")
		print("    - Display Name: %s" % composition_resource.display_name)
		print("    - Base Size: %s" % composition_resource.base_size)
		print("    - Layers: 0 (add them manually in the editor)")
		return CreationResult.SUCCESS
	else:
		push_error("  ✗ Failed to save resource: Error code " + str(save_error))
		return CreationResult.FAILED


## Gets the expected resource path for a character
func _get_resource_path(character_name: String) -> String:
	var character_dir = _get_character_directory(character_name)
	return character_dir + character_name + "_composition.tres"


## Gets the character directory path
func _get_character_directory(character_name: String) -> String:
	# Try scene-specific path first
	var editor_interface = get_editor_interface()
	var edited_scene = editor_interface.get_edited_scene_root()
	
	if edited_scene and edited_scene.scene_file_path:
		var scene_path = edited_scene.scene_file_path.get_base_dir()
		var scene_char_path = scene_path + "/characters/" + character_name + "/"
		# Use scene-specific path if you want, but for now just use common
	
	# Use common path
	return "res://assets/scenes/common/characters/" + character_name + "/"


## Static method for programmatic creation of blank resources for all actors in a scene
static func create_blank_resources_for_scene(scene_root: Node, skip_existing: bool = true) -> Dictionary:
	var results = {
		"created": [],
		"skipped": [],
		"failed": []
	}
	
	if not scene_root:
		return results
	
	var actors = _find_all_actors_static(scene_root)
	
	for actor in actors:
		var character_name = ""
		if "actor_name" in actor:
			character_name = actor.get("actor_name")
		
		if not character_name or character_name == "":
			results.failed.append({"actor": actor.name, "reason": "No actor_name set"})
			continue
		
		var character_dir = "res://assets/scenes/common/characters/" + character_name + "/"
		var resource_path = character_dir + character_name + "_composition.tres"
		
		# Skip if exists
		if skip_existing and ResourceLoader.exists(resource_path):
			results.skipped.append({"actor": actor.name, "character": character_name})
			continue
		
		# Ensure directory exists
		if not DirAccess.dir_exists_absolute(character_dir):
			DirAccess.make_dir_recursive_absolute(character_dir)
		
		# Create blank resource
		var composition_resource = CharacterCompositionResource.new()
		composition_resource.character_name = character_name
		composition_resource.display_name = character_name.capitalize()
		composition_resource.dialog_color = Color.WHITE
		composition_resource.inner_dialog_color = Color(1.0, 1.0, 1.0, 0.5)
		
		# Get base_size from actor
		if "base_size" in actor and actor.get("base_size") != Vector2(100, 100):
			composition_resource.base_size = actor.get("base_size")
		else:
			composition_resource.base_size = Vector2(80, 170)
		
		composition_resource.default_states = {
			"orientation": "front",
			"pose": "idle",
			"expression": "neutral",
			"outfit": "default",
			"body": "default"
		}
		
		# Save
		var save_error = ResourceSaver.save(composition_resource, resource_path)
		if save_error == OK:
			results.created.append({"actor": actor.name, "character": character_name, "path": resource_path})
		else:
			results.failed.append({"actor": actor.name, "character": character_name, "reason": "Save failed"})
	
	return results


static func _find_all_actors_static(node: Node) -> Array:
	var actors = []
	
	if node.get_script() and node.get_script().get_global_name() == "Actor":
		actors.append(node)
	
	for child in node.get_children():
		actors.append_array(_find_all_actors_static(child))
	
	return actors
