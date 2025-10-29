## Actor class - Pure VIEW for character display
## Actors observe Character models and display visuals via ActorDirectors
## DO NOT use Actor directly - use ActorController for public API
class_name Actor extends ResourceNode

## The character name this actor represents
var actor_name: String = ""

## Reference to the Character model (data/state holder)
var character: Character = null

## The container node that holds all mesh layers (3D)
var sprite_container: Node3D = null

## Dictionary of mesh layers { layer_name: MeshInstance3D }
var layers: Dictionary = {}

## Reference to the director managing this actor
var director = null  # ActorDirector


func _init(p_actor_name: String = "", p_director = null) -> void:
	super(p_actor_name)
	actor_name = p_actor_name
	director = p_director


## Observes a Character model for state changes
func observe(p_character: Character) -> void:
	character = p_character
	
	# Register as observer for ALL changes (states + transforms)
	character.add_observer(_on_character_changed)
	
	# Initial visual update
	if director and character.current_states:
		director.instruct(self, character.current_states)
	
	# Initial transform update
	update_position()
	update_visibility()


## Called when the observed Character changes (states or transforms)
func _on_character_changed(state_dict: Dictionary) -> void:
	# Update visual states (pose, expression, etc.)
	if "current_states" in state_dict and director:
		director.instruct(self, state_dict.current_states)
	
	# Update transform properties (position, rotation, scale, visible)
	if "position" in state_dict:
		update_position()
	
	if "visible" in state_dict:
		update_visibility()
	
	if "rotation" in state_dict:
		update_rotation()
	
	if "scale" in state_dict:
		update_scale()


## Creates the scene node for this actor
func create_scene_node(parent: Node) -> Node:
	if director and character:
		director.instruct(self, character.current_states)
	
	if sprite_container:
		parent.add_child(sprite_container)
		scene_node = sprite_container
		
		# Create interaction area for input handling
		_create_interaction_area()
	
	return sprite_container


## Updates the visibility of the actor from Character model
func update_visibility() -> void:
	if sprite_container and character:
		sprite_container.visible = character.visible


## Updates the position of the actor from Character model
func update_position() -> void:
	if sprite_container and character:
		# Position is in centimeters, apply directly to Node3D
		sprite_container.position = character.position


## Updates the rotation of the actor from Character model
func update_rotation() -> void:
	if sprite_container and character:
		# Rotation in Character is in degrees, convert to radians for Godot
		sprite_container.rotation_degrees = character.rotation


## Updates the scale of the actor from Character model
func update_scale() -> void:
	if sprite_container and character:
		sprite_container.scale = character.scale


## Creates the interaction area for input detection
func _create_interaction_area() -> void:
	if not sprite_container:
		return
	
	# Determine if this is 3D or 2D based on sprite_container type
	if sprite_container is Node3D:
		_create_area3d()
	elif sprite_container is Node2D:
		_create_area2d()


## Creates Area3D for 3D actors (theater mode)
func _create_area3d() -> void:
	var CollisionHelper = load("res://core-game/input/collision_helper.gd")
	interaction_area = CollisionHelper.create_area3d_for_actor(sprite_container)
	
	if interaction_area:
		sprite_container.add_child(interaction_area)
		
		# Connect signals to InteractionHandler
		interaction_area.input_event.connect(_on_area3d_input_event)
		interaction_area.mouse_entered.connect(_on_area3d_mouse_entered)
		interaction_area.mouse_exited.connect(_on_area3d_mouse_exited)


## Creates Area2D for 2D actors (movie mode)
func _create_area2d() -> void:
	# For 2D mode, we need a Sprite2D child
	var sprite: Sprite2D = null
	for child in sprite_container.get_children():
		if child is Sprite2D:
			sprite = child
			break
	
	if not sprite:
		return
	
	var CollisionHelper = load("res://core-game/input/collision_helper.gd")
	interaction_area = CollisionHelper.create_area2d_for_sprite(sprite)
	
	if interaction_area:
		sprite_container.add_child(interaction_area)
		
		# Connect signals to InteractionHandler
		interaction_area.input_event.connect(_on_area2d_input_event)
		interaction_area.mouse_entered.connect(_on_area2d_mouse_entered)
		interaction_area.mouse_exited.connect(_on_area2d_mouse_exited)


## Signal handlers for Area3D
func _on_area3d_input_event(_camera: Node, _event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	# Input events are handled by InteractionHandler via custom actions
	pass


func _on_area3d_mouse_entered() -> void:
	# Notify InteractionHandler that this actor is hovered
	var controller = _get_controller()
	if controller:
		InteractionHandler.on_hover_enter(controller)


func _on_area3d_mouse_exited() -> void:
	# Notify InteractionHandler that this actor is no longer hovered
	var controller = _get_controller()
	if controller:
		InteractionHandler.on_hover_exit(controller)


## Signal handlers for Area2D
func _on_area2d_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	# Input events are handled by InteractionHandler via custom actions
	pass


func _on_area2d_mouse_entered() -> void:
	# Notify InteractionHandler that this actor is hovered
	var controller = _get_controller()
	if controller:
		InteractionHandler.on_hover_enter(controller)


func _on_area2d_mouse_exited() -> void:
	# Notify InteractionHandler that this actor is no longer hovered
	var controller = _get_controller()
	if controller:
		InteractionHandler.on_hover_exit(controller)


## Gets the ActorController for this actor
## Searches for controller in the scene
func _get_controller():
	# The controller should be accessible through vn_scene
	if not vn_scene or not vn_scene.controller:
		return null
	
	# Find the controller that references this actor
	var scene_controller = vn_scene.controller
	for resource_name in scene_controller.resources:
		var resource = scene_controller.resources[resource_name]
		# Check if this resource is an ActorController with this view
		if resource.has_method("get") and resource.get("view") == self:
			return resource
		# Or if it's the ResourceNode itself (for backward compatibility)
		if resource == self:
			# Try to find the controller by actor_name
			# This is a fallback - ideally controllers should be registered
			pass
	
	return null
