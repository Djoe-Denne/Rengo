## Factory for creating VideoAnimation instances
class_name VideoAnimationFactory
extends AnimationFactoryBase

const VideoAnimation = preload("res://rengo/infra/animation/implementations/video_animation.gd")


## Check if this factory handles the animation type
func can_create(anim_type: String) -> bool:
	return anim_type == "video"


## Create a VideoAnimation from definition
func create(definition: Dictionary) -> VNAnimationNode:
	var duration = _get_duration(definition)
	var params = _get_parameters(definition)
	
	# Parse video type
	var video_type_str = params.get("video_type", "animated_texture")
	var video_type = _parse_video_type(video_type_str)
	
	var anim = VideoAnimation.new(duration, video_type)
	
	# Set resource path if provided
	if params.has("resource_path"):
		anim.with_resource(params.resource_path)
	
	# Set loop if provided
	if params.has("loop"):
		anim.with_loop(params.loop)
	
	return anim


## Parse video type string to VideoType enum
func _parse_video_type(video_type_str: String) -> int:
	match video_type_str.to_lower():
		"video_stream":
			return VideoAnimation.VideoType.VIDEO_STREAM
		"animated_texture":
			return VideoAnimation.VideoType.ANIMATED_TEXTURE
		"sprite_frames":
			return VideoAnimation.VideoType.SPRITE_FRAMES
		"image_sequence":
			return VideoAnimation.VideoType.IMAGE_SEQUENCE
		_:
			return VideoAnimation.VideoType.ANIMATED_TEXTURE

