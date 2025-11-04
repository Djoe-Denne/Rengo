class_name PostProcessorBuilder

var post_processing_viewport: SubViewport = null
var root_node: Node2D = null

var viewport_name: String = ""
var size: Vector2 = Vector2(100, 100)
var texture: Texture2D = null
var material: Material = null

static func take(viewport: SubViewport) -> PostProcessorBuilder:
	var p = PostProcessorBuilder.new()
	p.post_processing_viewport = viewport
	return p

func set_name(p_viewport_name: String) -> PostProcessorBuilder:
	viewport_name = p_viewport_name
	return self

func set_size(p_size: Vector2) -> PostProcessorBuilder:
	size = p_size
	return self

func set_texture(p_texture: Texture2D) -> PostProcessorBuilder:
	texture = p_texture
	return self

func set_material(p_material: Material) -> PostProcessorBuilder:
	material = p_material
	return self

func build() -> SubViewport:
	if post_processing_viewport.get_child_count() > 0 and post_processing_viewport.get_child(0) is Node2D:
		root_node = post_processing_viewport.get_child(0)
		#root_node.queue_free()
	else:
		root_node = Node2D.new()
		root_node.name = "RootNode_" + viewport_name
		post_processing_viewport.add_child(root_node)
	root_node = Node2D.new()
	root_node.name = "RootNode_" + viewport_name
	post_processing_viewport.add_child(root_node)
	if viewport_name:
		post_processing_viewport.name = viewport_name
	if size:
		post_processing_viewport.size = Vector2i(int(size.x), int(size.y))
	post_processing_viewport.transparent_bg = false
	post_processing_viewport.disable_3d = true
	post_processing_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	post_processing_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	var sprite = Sprite2D.new()
	if texture:
		sprite.texture = texture
		sprite.centered = false
	if size:
		sprite.scale.x = size.x / texture.get_size().x
		sprite.scale.y = size.y / texture.get_size().y
	if material:
		sprite.material_override = material

	root_node.add_child(sprite)

	return post_processing_viewport
