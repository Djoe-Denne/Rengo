## VideoAnimationNode - Video/GIF/sprite sheet playback on sprites
## Supports playing video files, animated textures, or sprite sequences
class_name VideoAnimation
extends VNAnimationNode

## Type of video animation
enum VideoType {
	VIDEO_STREAM,      # VideoStreamPlayer for .ogv files
	ANIMATED_TEXTURE,  # AnimatedTexture for GIFs
	SPRITE_FRAMES,     # SpriteFrames for sprite sheets
	IMAGE_SEQUENCE     # Sequence of images
}

## Video type
var video_type: VideoType = VideoType.ANIMATED_TEXTURE

## Path to video/animation resource
var resource_path: String = ""

## Video stream or animated texture
var video_resource: Resource = null

## Whether to loop the video
var loop_video: bool = false

## Video player node (created if needed)
var video_player: Node = null


func _init(p_duration: float = 0.0, p_type: VideoType = VideoType.ANIMATED_TEXTURE) -> void:
	super._init(p_duration)
	video_type = p_type


## Applies the video animation to controller
## Uses controller.apply_view_effect() for video player manipulation
func apply_to(target: Variant, progress: float, delta: float) -> void:
	if not target:
		return
	
	# Target should be a controller
	if not ("view" in target and "apply_view_effect" in target):
		push_warning("VideoAnimation: target is not a controller with view")
		return
	
	var view = target.view
	if not view:
		return
	
	# Ensure video is loaded and playing (use controller for setup)
	if not video_player and resource_path != "":
		_setup_video_player_via_controller(target)
	
	# Update video player if it exists
	if video_player:
		_update_video_playback(progress, delta)


## Setup video player via controller
func _setup_video_player_via_controller(controller: Variant) -> void:
	var view = controller.view if "view" in controller else null
	if not view:
		return
	
	match video_type:
		VideoType.VIDEO_STREAM:
			_setup_video_stream_player(view)
		
		VideoType.ANIMATED_TEXTURE:
			_setup_animated_texture(view)
		
		VideoType.SPRITE_FRAMES:
			_setup_sprite_frames(view)
		
		VideoType.IMAGE_SEQUENCE:
			_setup_image_sequence(view)


## Setup video player based on type (legacy - kept for internal use)
func _setup_video_player(target: Variant) -> void:
	match video_type:
		VideoType.VIDEO_STREAM:
			_setup_video_stream_player(target)
		
		VideoType.ANIMATED_TEXTURE:
			_setup_animated_texture(target)
		
		VideoType.SPRITE_FRAMES:
			_setup_sprite_frames(target)
		
		VideoType.IMAGE_SEQUENCE:
			_setup_image_sequence(target)


## Setup VideoStreamPlayer
func _setup_video_stream_player(target: Variant) -> void:
	if not ResourceLoader.exists(resource_path):
		push_error("VideoAnimation: Video file not found: %s" % resource_path)
		return
	
	# Create VideoStreamPlayer
	video_player = VideoStreamPlayer.new()
	video_player.stream = load(resource_path)
	video_player.loop = loop_video
	
	# Add to target
	if target.scene_node:
		target.scene_node.add_child(video_player)
		video_player.play()


## Setup animated texture on Sprite2D
func _setup_animated_texture(target: Variant) -> void:
	if not target.scene_node or not target.scene_node is Sprite2D:
		push_warning("VideoAnimation: Target is not a Sprite2D")
		return
	
	if not ResourceLoader.exists(resource_path):
		push_error("VideoAnimation: Animated texture not found: %s" % resource_path)
		return
	
	# Load and apply animated texture
	video_resource = load(resource_path)
	if video_resource is AnimatedTexture:
		target.scene_node.texture = video_resource
		video_player = target.scene_node  # Track for later


## Setup SpriteFrames on AnimatedSprite2D
func _setup_sprite_frames(target: Variant) -> void:
	# Create AnimatedSprite2D if target doesn't have one
	if not target.scene_node.has_node("AnimatedSprite2D"):
		var anim_sprite = AnimatedSprite2D.new()
		anim_sprite.name = "AnimatedSprite2D"
		target.scene_node.add_child(anim_sprite)
		video_player = anim_sprite
	else:
		video_player = target.scene_node.get_node("AnimatedSprite2D")
	
	if not ResourceLoader.exists(resource_path):
		push_error("VideoAnimation: SpriteFrames not found: %s" % resource_path)
		return
	
	# Load and apply sprite frames
	video_resource = load(resource_path)
	if video_resource is SpriteFrames:
		video_player.sprite_frames = video_resource
		video_player.play()


## Setup image sequence (manual frame switching)
func _setup_image_sequence(target: Variant) -> void:
	# TODO: Implement image sequence playback
	push_warning("VideoAnimation: Image sequence not yet implemented")


## Update video playback
func _update_video_playback(progress: float, delta: float) -> void:
	# Sync video with animation progress if duration is set
	if duration > 0.0 and video_player:
		if video_player is VideoStreamPlayer:
			# Seek to position based on progress
			var stream_length = video_player.stream.get_length()
			video_player.stream_position = progress * stream_length
		
		elif video_player is AnimatedSprite2D:
			# Update frame based on progress
			var total_frames = video_player.sprite_frames.get_frame_count(video_player.animation)
			var target_frame = int(progress * total_frames)
			video_player.frame = clamp(target_frame, 0, total_frames - 1)


## Builder method to set resource path
func with_resource(path: String) -> VideoAnimation:
	resource_path = path
	return self


## Builder method to set loop
func with_loop(should_loop: bool) -> VideoAnimation:
	loop_video = should_loop
	loop = should_loop
	return self


## Cleanup when animation finishes
func _finish_animation() -> void:
	super._finish_animation()
	
	# Clean up video player if needed
	if video_player and video_type == VideoType.VIDEO_STREAM:
		if video_player.get_parent():
			video_player.get_parent().remove_child(video_player)
		video_player.queue_free()
		video_player = null

