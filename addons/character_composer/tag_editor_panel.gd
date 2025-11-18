@tool
extends VBoxContainer

## Tag Editor Panel
## Allows editing tags and excluding_tags for wardrobe layers

signal tags_changed(new_tags: Array[String])
signal excluding_tags_changed(new_excluding_tags: Array[String])

var current_layer: CompositionLayer = null

@onready var tags_container: VBoxContainer = $TagsGroup/TagsList
@onready var excluding_tags_container: VBoxContainer = $ExcludingTagsGroup/ExcludingTagsList
@onready var add_tag_button: Button = $TagsGroup/AddTagButton
@onready var add_excluding_tag_button: Button = $ExcludingTagsGroup/AddExcludingTagButton


func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	
	if add_tag_button:
		add_tag_button.pressed.connect(_on_add_tag_pressed)
	if add_excluding_tag_button:
		add_excluding_tag_button.pressed.connect(_on_add_excluding_tag_pressed)


func set_layer(layer: CompositionLayer) -> void:
	current_layer = layer
	_refresh_ui()


func _refresh_ui() -> void:
	_rebuild_tags_list()
	_rebuild_excluding_tags_list()


func _rebuild_tags_list() -> void:
	if not tags_container or not current_layer:
		return
	
	# Clear existing items
	for child in tags_container.get_children():
		child.queue_free()
	
	# Add tag items
	for tag in current_layer.tags:
		_add_tag_item(tag, tags_container, true)


func _rebuild_excluding_tags_list() -> void:
	if not excluding_tags_container or not current_layer:
		return
	
	# Clear existing items
	for child in excluding_tags_container.get_children():
		child.queue_free()
	
	# Add excluding tag items
	for tag in current_layer.excluding_tags:
		_add_tag_item(tag, excluding_tags_container, false)


func _add_tag_item(tag: String, container: Control, is_regular_tag: bool) -> void:
	var hbox = HBoxContainer.new()
	
	var line_edit = LineEdit.new()
	line_edit.text = tag
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.text_changed.connect(_on_tag_text_changed.bind(tag, is_regular_tag))
	hbox.add_child(line_edit)
	
	var remove_button = Button.new()
	remove_button.text = "X"
	remove_button.pressed.connect(_on_remove_tag_pressed.bind(tag, is_regular_tag))
	hbox.add_child(remove_button)
	
	container.add_child(hbox)


func _on_tag_text_changed(new_text: String, old_tag: String, is_regular_tag: bool) -> void:
	if not current_layer:
		return
	
	if is_regular_tag:
		var index = current_layer.tags.find(old_tag)
		if index >= 0:
			current_layer.tags[index] = new_text
			tags_changed.emit(current_layer.tags)
	else:
		var index = current_layer.excluding_tags.find(old_tag)
		if index >= 0:
			current_layer.excluding_tags[index] = new_text
			excluding_tags_changed.emit(current_layer.excluding_tags)


func _on_remove_tag_pressed(tag: String, is_regular_tag: bool) -> void:
	if not current_layer:
		return
	
	if is_regular_tag:
		current_layer.tags.erase(tag)
		tags_changed.emit(current_layer.tags)
	else:
		current_layer.excluding_tags.erase(tag)
		excluding_tags_changed.emit(current_layer.excluding_tags)
	
	_refresh_ui()


func _on_add_tag_pressed() -> void:
	if not current_layer:
		return
	
	current_layer.tags.append("new_tag")
	tags_changed.emit(current_layer.tags)
	_refresh_ui()


func _on_add_excluding_tag_pressed() -> void:
	if not current_layer:
		return
	
	current_layer.excluding_tags.append("new_excluding_tag")
	excluding_tags_changed.emit(current_layer.excluding_tags)
	_refresh_ui()

