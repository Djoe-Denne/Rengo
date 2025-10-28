## ScreenManager - Manages screen navigation and transitions
## Handles switching between different screens (title, options, save/load, etc.)
## Extendable through virtual methods for custom transitions
class_name ScreenManager
extends Node

## Container where screen views are displayed
@export var screen_container: Node = null

## Currently active screen node
var current_screen: Node = null

## Previously active screen node
var previous_screen: Node = null

## Screen navigation stack for push/pop navigation
var screen_stack: Array[String] = []

## Registry of available screens { screen_name: scene_path }
var registered_screens: Dictionary = {}

## Registry of screen controllers { screen_name: ScreenController }
var screen_controllers: Dictionary = {}

## Default transition type
@export var default_transition: String = "fade"

## Transition duration in seconds
@export var transition_duration: float = 0.3

## Signal emitted when screen transition starts
signal screen_transition_started(from_screen: String, to_screen: String)

## Signal emitted when screen transition completes
signal screen_transition_completed(screen_name: String)


func _ready() -> void:
	if screen_container == null:
		screen_container = self


## Registers a screen with the manager
func register_screen(screen_name: String, scene_path: String, controller: ScreenController = null) -> void:
	registered_screens[screen_name] = scene_path
	
	if controller:
		screen_controllers[screen_name] = controller
		controller.set_screen_manager(self)


## Transitions to a screen by name
func transition(to_screen_name: String, transition_type: String = "") -> void:
	if transition_type == "":
		transition_type = default_transition
	
	if not to_screen_name in registered_screens:
		push_error("ScreenManager: Screen '%s' not registered" % to_screen_name)
		return
	
	var from_screen_name = _get_current_screen_name()
	
	# Emit signal
	screen_transition_started.emit(from_screen_name, to_screen_name)
	
	# Call on_exit for current controller
	if from_screen_name in screen_controllers:
		screen_controllers[from_screen_name].on_exit()
	
	# Load the new screen
	var scene_path = registered_screens[to_screen_name]
	var new_screen = _load_screen(scene_path)
	
	if new_screen == null:
		push_error("ScreenManager: Failed to load screen '%s' from '%s'" % [to_screen_name, scene_path])
		return
	
	# Perform transition
	await _perform_transition(current_screen, new_screen, transition_type)
	
	# Update current screen
	previous_screen = current_screen
	current_screen = new_screen
	
	# Call on_enter for new controller
	if to_screen_name in screen_controllers:
		screen_controllers[to_screen_name].on_enter()
	
	# Custom callback
	_on_screen_changed(to_screen_name)
	
	# Emit completion signal
	screen_transition_completed.emit(to_screen_name)


## Pushes a screen onto the navigation stack
func push_screen(screen_name: String, transition_type: String = "") -> void:
	var current_name = _get_current_screen_name()
	if current_name != "":
		screen_stack.append(current_name)
	
	transition(screen_name, transition_type)


## Pops back to the previous screen in the stack
func pop_screen(transition_type: String = "") -> void:
	if screen_stack.is_empty():
		push_warning("ScreenManager: No screens in stack to pop")
		return
	
	var previous_screen_name = screen_stack.pop_back()
	transition(previous_screen_name, transition_type)


## Clears the navigation stack
func clear_stack() -> void:
	screen_stack.clear()


## Gets the name of the currently active screen
func _get_current_screen_name() -> String:
	if current_screen == null:
		return ""
	
	# Find the screen name by searching registered screens
	for screen_name in registered_screens:
		if registered_screens[screen_name] == current_screen.scene_file_path:
			return screen_name
	
	return ""


## Loads a screen from a scene path
func _load_screen(scene_path: String) -> Node:
	if not ResourceLoader.exists(scene_path):
		push_error("ScreenManager: Scene does not exist: %s" % scene_path)
		return null
	
	var packed_scene = load(scene_path)
	if packed_scene == null:
		push_error("ScreenManager: Failed to load scene: %s" % scene_path)
		return null
	
	return packed_scene.instantiate()


## Performs the transition between screens
## Override this method in subclasses for custom transitions
func _perform_transition(from: Node, to: Node, transition_type: String) -> void:
	match transition_type:
		"instant":
			_transition_instant(from, to)
		"fade":
			await _transition_fade(from, to)
		"slide_left":
			await _transition_slide(from, to, Vector2(-1, 0))
		"slide_right":
			await _transition_slide(from, to, Vector2(1, 0))
		"slide_up":
			await _transition_slide(from, to, Vector2(0, -1))
		"slide_down":
			await _transition_slide(from, to, Vector2(0, 1))
		_:
			# Custom transition - call virtual method
			await _custom_transition(from, to, transition_type)


## Instant transition (no animation)
func _transition_instant(from: Node, to: Node) -> void:
	if from:
		screen_container.remove_child(from)
		from.queue_free()
	
	if to:
		screen_container.add_child(to)


## Fade transition
func _transition_fade(from: Node, to: Node) -> void:
	if to:
		screen_container.add_child(to)
		to.modulate.a = 0.0
	
	# Fade out old screen
	if from:
		var tween = create_tween()
		tween.tween_property(from, "modulate:a", 0.0, transition_duration / 2)
		await tween.finished
		screen_container.remove_child(from)
		from.queue_free()
	
	# Fade in new screen
	if to:
		var tween = create_tween()
		tween.tween_property(to, "modulate:a", 1.0, transition_duration / 2)
		await tween.finished


## Slide transition
func _transition_slide(from: Node, to: Node, direction: Vector2) -> void:
	if not to or not screen_container is Control:
		_transition_instant(from, to)
		return
	
	var container_size = screen_container.size if screen_container is Control else get_viewport().get_visible_rect().size
	var offset = direction * container_size
	
	# Add new screen off-screen
	if to:
		screen_container.add_child(to)
		if to is Control:
			to.position = offset
	
	# Slide both screens
	var tween = create_tween().set_parallel(true)
	
	if from and from is Control:
		tween.tween_property(from, "position", -offset, transition_duration)
	
	if to and to is Control:
		tween.tween_property(to, "position", Vector2.ZERO, transition_duration)
	
	await tween.finished
	
	# Remove old screen
	if from:
		screen_container.remove_child(from)
		from.queue_free()


## Virtual method for custom transitions
## Override this in subclasses to add custom transition types
func _custom_transition(from: Node, to: Node, transition_type: String) -> void:
	push_warning("ScreenManager: Unknown transition type '%s', using instant transition" % transition_type)
	_transition_instant(from, to)


## Virtual method called when screen changes
## Override this in subclasses for custom behavior
func _on_screen_changed(screen_name: String) -> void:
	pass  # Override in subclasses

