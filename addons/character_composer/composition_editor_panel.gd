@tool
extends Control

## Main editor panel for CharacterCompositionResource

var current_resource: CharacterCompositionResource = null
var selected_layer: CompositionLayer = null

# UI references
@onready var layer_tree: Tree = $HBoxContainer/LeftPanel/LayerTree
@onready var preview_container: Control = $HBoxContainer/CenterPanel/PreviewContainer
@onready var preview_display: Control = $HBoxContainer/CenterPanel/PreviewContainer/PreviewDisplay
@onready var properties_panel: VBoxContainer = $HBoxContainer/RightPanel/PropertiesScroll/PropertiesPanel
@onready var add_layer_button: Button = $HBoxContainer/LeftPanel/ToolBar/AddLayerButton
@onready var remove_layer_button: Button = $HBoxContainer/LeftPanel/ToolBar/RemoveLayerButton
@onready var validate_button: Button = $HBoxContainer/LeftPanel/ToolBar/ValidateButton
@onready var batch_convert_button: Button = $HBoxContainer/LeftPanel/ToolBar/BatchConvertButton


func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	
	# Connect signals
	if add_layer_button:
		add_layer_button.pressed.connect(_on_add_layer_pressed)
	if remove_layer_button:
		remove_layer_button.pressed.connect(_on_remove_layer_pressed)
	if validate_button:
		validate_button.pressed.connect(_on_validate_pressed)
	if batch_convert_button:
		batch_convert_button.pressed.connect(_on_batch_convert_pressed)
	
	if layer_tree:
		layer_tree.item_selected.connect(_on_layer_selected)
	
	_refresh_ui()


func edit_resource(resource: CharacterCompositionResource) -> void:
	current_resource = resource
	_refresh_ui()


func _refresh_ui() -> void:
	_rebuild_layer_tree()
	_update_properties_panel()
	_update_preview()


func _rebuild_layer_tree() -> void:
	if not layer_tree or not current_resource:
		return
	
	layer_tree.clear()
	var root = layer_tree.create_item()
	layer_tree.hide_root = true
	
	# Build tree structure
	var layer_items = {}
	
	# First pass: create all items
	for layer in current_resource.layers:
		var item = layer_tree.create_item()
		var layer_id_display = layer.id + " [" + layer.layer_id + "]"
		item.set_metadata(0, layer)
		item.set_text(0, layer_id_display)
		layer_items[layer.id] = item
	
	# Second pass: organize hierarchy
	for layer in current_resource.layers:
		var item = layer_items[layer.id]
		if layer.parent_layer_id != "" and layer.parent_layer_id in layer_items:
			var parent_item = layer_items[layer.parent_layer_id]
			item.get_parent().remove_child(item)
			parent_item.add_child(item)

func _on_layer_selected() -> void:
	if not layer_tree:
		return
	
	var selected = layer_tree.get_selected()
	if selected:
		selected_layer = selected.get_metadata(0)
		_update_properties_panel()
		_update_preview()


func _update_properties_panel() -> void:
	if not properties_panel:
		return
	
	# Clear existing properties
	for child in properties_panel.get_children():
		child.queue_free()
	
	if not selected_layer:
		var label = Label.new()
		label.text = "No layer selected"
		properties_panel.add_child(label)
		return
	
	# Add property editors
	_add_property_editor("ID", selected_layer.id, "id")
	_add_property_editor("Layer ID", selected_layer.layer_id, "layer_id")
	_add_property_editor("Template Path", selected_layer.template_path, "template_path")
	_add_property_editor("Position X", str(selected_layer.position.x), "position_x")
	_add_property_editor("Position Y", str(selected_layer.position.y), "position_y")
	_add_property_editor("Z-Index", str(selected_layer.z_index), "z_index")
	_add_property_editor("Parent Layer ID", selected_layer.parent_layer_id, "parent_layer_id")
	
	# Preview section
	var preview_separator = HSeparator.new()
	properties_panel.add_child(preview_separator)
	
	var preview_header = Label.new()
	preview_header.text = "Preview Settings"
	preview_header.add_theme_font_size_override("font_size", 14)
	properties_panel.add_child(preview_header)
	
	_add_property_editor("Preview Image Path", selected_layer.preview_image_path, "preview_image_path")
	_add_preview_checkbox()
	
	# Tags section
	var tags_separator = HSeparator.new()
	properties_panel.add_child(tags_separator)
	
	var tags_header = Label.new()
	tags_header.text = "Wardrobe Tags"
	tags_header.add_theme_font_size_override("font_size", 14)
	properties_panel.add_child(tags_header)
	
	var tags_label = Label.new()
	tags_label.text = "Tags: " + ", ".join(selected_layer.tags)
	properties_panel.add_child(tags_label)
	
	var excluding_tags_label = Label.new()
	excluding_tags_label.text = "Excluding Tags: " + ", ".join(selected_layer.excluding_tags)
	properties_panel.add_child(excluding_tags_label)


func _add_property_editor(label_text: String, value: String, property: String) -> void:
	var hbox = HBoxContainer.new()
	
	var label = Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size.x = 120
	hbox.add_child(label)
	
	var line_edit = LineEdit.new()
	line_edit.text = value
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.text_changed.connect(_on_property_changed.bind(property, line_edit))
	hbox.add_child(line_edit)
	
	properties_panel.add_child(hbox)


func _add_preview_checkbox() -> void:
	var hbox = HBoxContainer.new()
	
	var label = Label.new()
	label.text = "Preview Active:"
	label.custom_minimum_size.x = 120
	hbox.add_child(label)
	
	var checkbox = CheckBox.new()
	checkbox.button_pressed = selected_layer.preview_active
	checkbox.toggled.connect(_on_preview_checkbox_toggled)
	hbox.add_child(checkbox)
	
	properties_panel.add_child(hbox)


func _on_preview_checkbox_toggled(toggled_on: bool) -> void:
	if not selected_layer or not current_resource:
		return
	
	selected_layer.preview_active = toggled_on
	current_resource.emit_changed()
	_update_preview()


func _on_property_changed(new_value: String, property: String, line_edit: LineEdit) -> void:
	if not selected_layer or not current_resource:
		return
	
	match property:
		"id":
			selected_layer.id = new_value
		"layer_id":
			selected_layer.layer_id = new_value
		"template_path":
			selected_layer.template_path = new_value
		"position_x":
			selected_layer.position.x = float(new_value)
			_update_preview()
		"position_y":
			selected_layer.position.y = float(new_value)
			_update_preview()
		"z_index":
			selected_layer.z_index = int(new_value)
			_update_preview()
		"parent_layer_id":
			selected_layer.parent_layer_id = new_value
			_update_preview()
		"preview_image_path":
			selected_layer.preview_image_path = new_value
			_update_preview()
	
	current_resource.emit_changed()
	_rebuild_layer_tree()


func _update_preview() -> void:
	if not preview_display or not current_resource:
		return
	
	# Clear existing preview
	for child in preview_display.get_children():
		child.queue_free()
	
	# Get all layers with active preview, sorted by z-index
	var preview_layers = []
	for layer in current_resource.layers:
		if layer.preview_active and layer.preview_image_path != "":
			preview_layers.append(layer)
	
	# Sort by z-index (lowest first)
	preview_layers.sort_custom(func(a, b): return a.z_index < b.z_index)
	
	if preview_layers.is_empty():
		var label = Label.new()
		label.text = "No preview layers active\n\nTo preview:\n1. Select a layer\n2. Set Preview Image Path\n3. Enable Preview Active checkbox"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.anchors_preset = Control.PRESET_FULL_RECT
		preview_display.add_child(label)
		return
	
	# Calculate base size and scale
	var base_size = current_resource.base_size if current_resource else Vector2(80, 170)
	var display_height = preview_display.size.y
	
	# Calculate scale to fit character height in display
	var scale_ratio =  1.0
	
	# Build position map for parent-child relationships
	var layer_positions = {}
	
	# First pass: calculate positions for all layers
	
	var current_parent = preview_display
	# Display each preview layer
	for layer in preview_layers:
		var texture = _load_preview_texture(layer)
		if texture:
			if layer.parent_layer_id == "":
				var sprite = VNSprite.new(texture, texture.get_position())
				sprite.centered = false
				sprite.scale = Vector2(scale_ratio, scale_ratio)
				current_parent = sprite
				preview_display.add_child(sprite)
			else:
				var sprite = VNSprite.new(texture, current_parent.to_centered_position(texture) )
				sprite.centered = false
				current_parent.add_child(sprite)
	
	# Add layer info overlay
	var info_label = Label.new()
	info_label.text = "Preview: %d layer(s) | Scale: %.2fx" % [preview_layers.size(), scale_ratio]
	info_label.position = Vector2(10, 10)
	info_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	info_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	info_label.add_theme_constant_override("outline_size", 2)
	preview_display.add_child(info_label)


func _load_preview_texture(layer: CompositionLayer) -> VNTexture:
	if layer.preview_image_path.is_empty():
		return null
		
	# Try to load as resource path
	if ResourceLoader.exists(layer.preview_image_path):
		var texture = load(layer.preview_image_path)
		if texture is Texture2D:
			return VNTexture.new(texture, layer.position)
	
	# Try relative to project
	var full_path = "res://" + layer.preview_image_path
	if ResourceLoader.exists(full_path):
		var texture = load(full_path)
		if texture is Texture2D:
			return VNTexture.new(texture, layer.position)
	
	return null


func _on_add_layer_pressed() -> void:
	if not current_resource:
		return
	
	var new_layer = CompositionLayer.new()
	new_layer.id = "new_layer_" + str(current_resource.layers.size())
	new_layer.layer_name = "New Layer"
	new_layer.layer_type = CompositionLayer.LayerType.BODY
	
	current_resource.add_layer(new_layer)
	_refresh_ui()
	_update_preview()


func _on_remove_layer_pressed() -> void:
	if not current_resource or not selected_layer:
		return
	
	current_resource.remove_layer(selected_layer)
	selected_layer = null
	_refresh_ui()
	_update_preview()


func _on_validate_pressed() -> void:
	if not current_resource:
		return
	
	var validation = current_resource.validate_hierarchy()
	
	if validation.valid:
		print("✓ Validation passed!")
		if validation.warnings.size() > 0:
			print("Warnings:")
			for warning in validation.warnings:
				print("  - ", warning)
		
		# Save the resource after successful validation
		if current_resource.resource_path != "":
			var save_result = ResourceSaver.save(current_resource, current_resource.resource_path)
			if save_result == OK:
				print("✓ Resource saved successfully")
			else:
				push_error("Failed to save resource: Error code %d" % save_result)
	else:
		print("✗ Validation failed!")
		print("Errors:")
		for error in validation.errors:
			print("  - ", error)
		if validation.warnings.size() > 0:
			print("Warnings:")
			for warning in validation.warnings:
				print("  - ", warning)


func _on_batch_convert_pressed() -> void:
	print("=== Batch Create Blank Resources ===")
	
	# Get the current scene root
	var editor_interface = Engine.get_singleton("EditorInterface")
	if not editor_interface:
		push_error("Could not get EditorInterface")
		return
	
	var scene_root = editor_interface.get_edited_scene_root()
	if not scene_root:
		push_error("No scene is currently open")
		return
	
	print("Scanning scene: %s" % scene_root.name)
	
	# Use the batch creator
	var BatchCreator = load("res://addons/character_composer/batch_convert_actors_tool.gd")
	if not BatchCreator:
		push_error("Failed to load batch creator")
		return
	
	var results = BatchCreator.create_blank_resources_for_scene(scene_root, true)
	
	if not results or not results is Dictionary:
		push_error("Invalid results from batch creator")
		return
	
	# Print results
	print("\n✓ Created: %d" % results.get("created", []).size())
	for item in results.get("created", []):
		print("  - %s (%s) → %s" % [item.actor, item.character, item.path])
	
	print("\n⊘ Skipped (already exists): %d" % results.get("skipped", []).size())
	for item in results.get("skipped", []):
		print("  - %s (%s)" % [item.actor, item.character])
	
	var failed = results.get("failed", [])
	if failed.size() > 0:
		print("\n✗ Failed: %d" % failed.size())
		for item in failed:
			print("  - %s (%s): %s" % [item.actor, item.character, item.reason])
	
	print("\n=== Batch Creation Complete ===")
