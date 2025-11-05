## DisplayableLayer - Self-contained layer with mesh, texture, and raycast-based collision
## Each layer manages its own visibility, input handling, and collision detection
class_name Displayable
extends Node2D

	## Signal for when the postprocess sub viewport changes
signal displayable_changed(displayable: Displayable)

## The visual mesh instance
var postprocess_sub_viewport: SubViewport = null

## The composed sprite instance
var composed_sprite: Sprite2D = null


func _init(displayable_name: String = "") -> void:
	name = "Displayable_" + displayable_name

	composed_sprite = Sprite2D.new()
	composed_sprite.name = "ComposedSprite_" + displayable_name
	composed_sprite.centered = false
		
	# Create the mesh instance as a child
	postprocess_sub_viewport = SubViewport.new()
	postprocess_sub_viewport.name = "PostprocessSubViewport_" + displayable_name
	postprocess_sub_viewport.transparent_bg = true
	postprocess_sub_viewport.disable_3d = true
	postprocess_sub_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	postprocess_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	add_child(postprocess_sub_viewport)
	add_child(composed_sprite)

func commit_postprocess_sub_viewport() -> void:
	if not postprocess_sub_viewport:
		return
	composed_sprite.texture = postprocess_sub_viewport.get_texture()

	displayable_changed.emit(self)

## Gets the composed sprite
func get_composed_sprite() -> Sprite2D:
	return composed_sprite
