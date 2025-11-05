class_name PostProcessorBuilder
extends RefCounted

## Signal for when the postprocess sub viewport changes
signal postprocess_sub_viewport_changed(new_viewport: SubViewport)

var post_processing_viewport: SubViewport = null
var root_node: Node2D = null

var viewport_name: String = ""
var size: Vector2 = Vector2(0, 0)
var textures: Dictionary = {}
var material: Material = null

func _init(displayable: Displayable) -> void:
	post_processing_viewport = displayable.postprocess_sub_viewport
	postprocess_sub_viewport_changed.connect(displayable.commit_postprocess_sub_viewport)
	if displayable.postprocess_sub_viewport.get_child_count() > 0 and displayable.postprocess_sub_viewport.get_child(0) is Node2D:
		root_node = displayable.postprocess_sub_viewport.get_child(0)
	else:
		root_node = Node2D.new()
		root_node.name = "RootNode_" + displayable.name
		displayable.postprocess_sub_viewport.add_child(root_node)
	

static func take(displayable: Displayable) -> PostProcessorBuilder:
	var p = PostProcessorBuilder.new(displayable)
	p._sync_sprites_from_root_node()
	return p

func set_name(p_viewport_name: String) -> PostProcessorBuilder:
	viewport_name = p_viewport_name
	return self

func set_size(p_size: Vector2) -> PostProcessorBuilder:
	size = p_size
	return self

func add_texture(layer_name: String, p_texture: Texture2D) -> PostProcessorBuilder:
	var sprite_name = "Sprite_" + layer_name
	if not sprite_name in textures:
		textures[sprite_name] = Sprite2D.new()
		textures[sprite_name].name = sprite_name
		textures[sprite_name].centered = false
	textures[sprite_name].texture = p_texture
	return self

func set_material(p_material: Material) -> PostProcessorBuilder:
	material = p_material
	return self

func build() -> SubViewport:

	_sync_sprites_to_root_node()

	if viewport_name:
		post_processing_viewport.name = viewport_name
	if size.x > 0 and size.y > 0 and not textures.size() > 0:
		post_processing_viewport.size.x = size.x
		post_processing_viewport.size.y = size.y
	elif size.x == 0 and size.y == 0 and textures.size() > 0:
		var max_size = Vector2(0, 0)
		for texture in textures.values():
			max_size.x = max(max_size.x, texture.texture.get_size().x)
			max_size.y = max(max_size.y, texture.texture.get_size().y)
		post_processing_viewport.size.x = max_size.x
		post_processing_viewport.size.y = max_size.y
	else:
		push_error("PostProcessorBuilder: Either textures or size must be set")
		return null

	if material:
		root_node.material_override = material

	postprocess_sub_viewport_changed.emit()

	return post_processing_viewport

func _sync_sprites_from_root_node() -> void:
	for root_child in root_node.get_children():
		if root_child is Sprite2D:
			textures[root_child.name] = root_child

func _sync_sprites_to_root_node() -> void:
	for texture in textures.values():
		if not texture.get_parent():
			root_node.add_child(texture)
