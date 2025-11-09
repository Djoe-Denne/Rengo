## ViewportTextureExporter - Debug utility to export all viewport textures to PNG
## Standalone class for debugging viewport rendering pipeline
## Usage: Call ViewportTextureExporter.export_all_viewports(get_tree().root, "user://viewport_debug/")
class_name ViewportTextureExporter
extends RefCounted


## Exports all SubViewport textures from a scene tree to PNG files
## @param root_node: Root node to start recursive search from
## @param output_dir: Directory to save PNG files (e.g., "user://viewport_debug/")
## @return: Number of textures exported
static func export_all_viewports(root_node: Node, output_dir: String = "user://viewport_debug/") -> int:
	if not root_node:
		push_error("ViewportTextureExporter: root_node is null")
		return 0
	
	# Ensure output directory exists
	var dir = DirAccess.open("user://")
	if not dir:
		push_error("ViewportTextureExporter: Failed to access user:// directory")
		return 0
	
	# Extract just the directory name from the path
	var dir_path = output_dir.replace("user://", "")
	if dir_path.ends_with("/"):
		dir_path = dir_path.substr(0, dir_path.length() - 1)
	
	if not dir.dir_exists(dir_path):
		var err = dir.make_dir_recursive(dir_path)
		if err != OK:
			push_error("ViewportTextureExporter: Failed to create directory: %s" % output_dir)
			return 0
	
	print("ViewportTextureExporter: Starting export to %s" % output_dir)
	
	# Collect all viewports
	var viewports: Array[SubViewport] = []
	_collect_viewports(root_node, viewports)
	
	print("ViewportTextureExporter: Found %d viewports" % viewports.size())
	
	# Export each viewport
	var export_count = 0
	for viewport in viewports:
		if _export_viewport_texture(viewport, output_dir):
			export_count += 1
	
	print("ViewportTextureExporter: Exported %d textures to %s" % [export_count, output_dir])
	return export_count


## Recursively collects all SubViewport nodes from the scene tree
static func _collect_viewports(node: Node, viewports: Array[SubViewport]) -> void:
	if node is SubViewport:
		viewports.append(node)
	
	for child in node.get_children():
		_collect_viewports(child, viewports)


## Exports a single viewport's texture to PNG
## @param viewport: The SubViewport to export
## @param output_dir: Directory to save the PNG file
## @return: true if export successful, false otherwise
static func _export_viewport_texture(viewport: SubViewport, output_dir: String) -> bool:
	if not viewport:
		return false
	
	var texture = viewport.get_texture()
	if not texture:
		push_warning("ViewportTextureExporter: Viewport '%s' has no texture" % viewport.name)
		return false
	
	# Get the image from the texture
	var image = texture.get_image()
	if not image:
		push_warning("ViewportTextureExporter: Failed to get image from viewport '%s'" % viewport.name)
		return false
	
	# Generate filename from viewport's full path
	var full_path = viewport.get_path()
	var filename = _sanitize_filename(str(full_path)) + ".png"
	
	# Construct full output path
	var output_path = output_dir
	if not output_path.ends_with("/"):
		output_path += "/"
	output_path += filename
	
	# Save the image
	var err = image.save_png(output_path)
	if err != OK:
		push_error("ViewportTextureExporter: Failed to save '%s' (error %d)" % [output_path, err])
		return false
	
	print("ViewportTextureExporter: Exported texture '%s' from viewport '%s' (%dx%d) -> %s" % [
		texture,
		viewport.name,
		image.get_width(),
		image.get_height(),
		output_path
	])
	return true


## Sanitizes a node path to be a valid filename
## Replaces special characters with underscores
static func _sanitize_filename(path: String) -> String:
	var sanitized = path
	
	# Remove leading slash
	if sanitized.begins_with("/"):
		sanitized = sanitized.substr(1)
	
	# Replace invalid filename characters
	sanitized = sanitized.replace("/", "_")
	sanitized = sanitized.replace("\\", "_")
	sanitized = sanitized.replace(":", "_")
	sanitized = sanitized.replace("*", "_")
	sanitized = sanitized.replace("?", "_")
	sanitized = sanitized.replace("\"", "_")
	sanitized = sanitized.replace("<", "_")
	sanitized = sanitized.replace(">", "_")
	sanitized = sanitized.replace("|", "_")
	
	return sanitized
