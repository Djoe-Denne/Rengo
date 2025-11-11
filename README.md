# GENPY - 2.5D Visual Novel Framework for Godot

A programmatic visual novel framework inspired by Ren'Py and Rakugo, but with enhanced graphical capabilities and a type-safe, FSM-based approach.

## Overview

GENPY provides a two-layer rendering system for creating visual novels in Godot:

- **Acting Layer**: 2.5D orthographic space where 2D/3D assets (characters, backgrounds) are positioned
- **Dialog Layer**: 2D UI space for dialog boxes and interface elements

Unlike traditional visual novel engines, GENPY uses pure GDScript code instead of a scripting language, providing full IDE support, type safety, and debugging capabilities.

## Key Features

- **Normalized Coordinates**: All positioning uses normalized [0.0-1.0] coordinates that adapt to any screen size
- **FSM-Based Scenes**: Finite state machine approach for predictable, sequential execution
- **Type-Safe API**: Pure GDScript with full autocomplete and type checking
- **Two-Layer Rendering**: Separate layers for scene content and UI
- **Modular Architecture**: Easy to extend with new resource and action types

## Architecture

### Core Classes

#### ResourceNode (`scripts/core/resource_node.gd`)
Base class for all scene resources (characters, backgrounds, cameras, etc.)

**Key Properties:**
- `name: String` - Unique identifier
- `position: Vector3` - Normalized position (x, y in [0-1], z for depth)
- `visible: bool` - Visibility state
- `scene_node: Node` - Reference to the Godot node in scene tree

**Key Methods:**
- `show() -> ActionNode` - Returns action to show this resource
- `hide() -> ActionNode` - Returns action to hide this resource
- `create_scene_node(parent: Node) -> Node` - Creates visual representation

#### ActionNode (`scripts/core/action/action_node.gd`)
Base class for all scene actions (show, hide, say, move, etc.)

**Key Properties:**
- `target: ResourceNode` - The resource this action operates on
- `duration: float` - How long the action takes (seconds)
- `blocking: bool` - Whether to wait for completion

**Key Methods:**
- `execute()` - Called when action starts
- `process_action(delta: float) -> bool` - Called every frame, returns true when complete
- `get_progress() -> float` - Returns 0.0 to 1.0 completion progress

#### VNSceneController (`scripts/core/scene_controller.gd`)
Manages the finite state machine that executes actions

**Key Methods:**
- `add_resource(resource: ResourceNode)` - Adds a resource to the scene
- `action(action: ActionNode) -> VNSceneController` - Queues an action
- `wait(seconds: float) -> VNSceneController` - Queues a wait action
- `play()` - Starts execution
- `process(delta: float)` - Processes actions (called every frame)

#### VNScene (`scripts/core/vn_scene.gd` / `scenes/game/vn_scene.tscn`)
Main scene container with two layers

**Structure:**
```
VNScene (Node2D)
├── ActingLayer (Node2D) - Characters, backgrounds appear here
└── DialogLayer (CanvasLayer) - UI elements appear here
```

### Resource Types

#### Background (`scripts/core/render/texturebackground.gd`)
Displays background images/scenes

```gdscript
var bg = Background.new("park")
bg.texture = load("res://assets/park.png")
bg.position = Vector3(0.0, 0.0, 0.0)
```

#### Character (`scripts/core/render/texturecharacter.gd`)
Displays character sprites with expression support

```gdscript
var char = Character.new("alice")
char.texture = load("res://assets/alice_neutral.png")
char.add_expression("happy", "res://assets/alice_happy.png")
char.position = NormalizedPosition.left_bottom(0.2, 0.2)
```

#### VNCamera (`scripts/core/render/texturecamera.gd`)
Controls the camera position and zoom

```gdscript
var cam = VNCamera.new()
cam.set_zoom(1.5)
cam.position = NormalizedPosition.center()
```

### Action Types

#### ShowAction (`scripts/core/action/common/show_action.gd`)
Makes a resource visible with optional fade-in

```gdscript
resource.show()  # Default 0.3s fade
resource.show().with_fade(1.0)  # Custom fade duration
resource.show().instant()  # No fade
```

#### HideAction (`scripts/core/action/common/hide_action.gd`)
Makes a resource invisible with optional fade-out

```gdscript
resource.hide()  # Default 0.3s fade
resource.hide().with_fade(1.0)  # Custom fade duration
resource.hide().instant()  # No fade
```

#### SayAction (`scripts/core/action/common/say_action.gd`)
Displays dialog text and waits for user input

```gdscript
character.say("Hello world!")
character.say("Text").with_auto_advance(2.0)  # Auto-advance after 2s
```

#### WaitAction (`scripts/core/action/common/wait_action.gd`)
Pauses execution for a specified duration

```gdscript
scene.wait(1.5)  # Wait 1.5 seconds
```

## Coordinate System

### NormalizedPosition (`scripts/utilities/normalized_position.gd`)

All positions use normalized coordinates where (0, 0) is top-left and (1, 1) is bottom-right.

**Helper Functions:**

```gdscript
# Basic creation
NormalizedPosition.create(x, y, z)

# Anchor-based positioning
NormalizedPosition.left_bottom(x, y)    # x from left, y from bottom
NormalizedPosition.right_bottom(x, y)   # x from right, y from bottom
NormalizedPosition.left_top(x, y)       # x from left, y from top
NormalizedPosition.right_top(x, y)      # x from right, y from top
NormalizedPosition.center(x_off, y_off) # Offset from center

# Conversion
NormalizedPosition.to_pixels(normalized_pos, viewport_size)
NormalizedPosition.from_pixels(pixel_pos, viewport_size)
```

## Usage Example

```gdscript
extends Node2D

var vn_scene: VNScene = null

func _ready() -> void:
    # Load the VNScene
    var scene_packed = load("res://scenes/game/vn_scene.tscn")
    vn_scene = scene_packed.instantiate()
    add_child(vn_scene)
    
    # Create resources
    var bg = Background.new("park")
    bg.texture = load("res://assets/park.png")
    
    var alice = Character.new("alice")
    alice.texture = load("res://assets/alice.png")
    alice.position = NormalizedPosition.left_bottom(0.2, 0.2)
    
    var bob = Character.new("bob")
    bob.texture = load("res://assets/bob.png")
    bob.position = NormalizedPosition.right_bottom(0.2, 0.2)
    
    # Add resources to scene
    vn_scene.add_resource(bg)
    vn_scene.add_resource(alice)
    vn_scene.add_resource(bob)
    
    # Build action sequence
    vn_scene.controller.action(bg.show())
    vn_scene.controller.wait(0.5)
    vn_scene.controller.action(alice.show())
    vn_scene.controller.action(bob.show())
    vn_scene.controller.wait(0.5)
    vn_scene.controller.action(alice.say("Hi Bob!"))
    vn_scene.controller.action(bob.say("Hello Alice!"))
    
    # Start playing
    vn_scene.play()
```

## Extending the Framework

### Creating Custom ResourceNodes

```gdscript
class_name MyCustomResource
extends ResourceNode

func create_scene_node(parent: Node) -> Node:
    var node = Sprite2D.new()
    node.texture = my_texture
    parent.add_child(node)
    scene_node = node
    return node
```

### Creating Custom ActionNodes

```gdscript
class_name MyCustomAction
extends ActionNode

func execute() -> void:
    super.execute()
    # Setup action

func _process_action(delta: float) -> void:
    # Per-frame update
    var progress = get_progress()
    # Use progress for interpolation

func on_complete() -> void:
    # Cleanup
```

## Interaction System

GENPY provides a flexible interaction system that allows game developers to add custom input handlers to resources without creating multiple subclasses.

### Overview

The interaction system uses `InteractionArea` (extends `Area2D`) to provide collision detection based on the sprite's shape. The collision shape automatically updates when the texture changes (e.g., when a character changes pose or expression).

### Adding Interactions

Use `add_interaction()` or `add_interactions()` on any `TexturedResourceNode` (like `Character`):

```gdscript
# Create a simple click handler
class ClickHandler:
    func should_handle(resource, event):
        return event.type == "click" and event.pressed
    
    func handle(resource, event):
        print("Character clicked: ", resource.name)
        print("Position: ", event.position)

# Add to a character
var alice = Character.new("alice")
alice.add_interaction(ClickHandler.new())

# Add multiple handlers at once
alice.add_interactions([
    ClickHandler.new(),
    HoverHandler.new(),
    DragHandler.new()
])
```

### Handler Interface

All handlers must implement two methods:

```gdscript
func should_handle(resource: TexturedResourceNode, event: Dictionary) -> bool:
    # Return true if this handler wants to handle the event
    return event.type == "click"

func handle(resource: TexturedResourceNode, event: Dictionary) -> void:
    # Process the event
    print("Handling event")
```

### Event Types

The interaction system supports multiple event types:

- **click**: Mouse button press or release
- **hover_enter**: Mouse enters the resource area
- **hover_exit**: Mouse leaves the resource area
- **drag_start**: Mouse button pressed (beginning of potential drag)
- **drag_move**: Mouse moved while button held down
- **drag_end**: Mouse button released (end of drag)

### Event Dictionary Structure

```gdscript
{
    "type": String,           # Event type (see above)
    "position": Vector2,      # Local position relative to sprite
    "global_position": Vector2, # Global screen position
    "button_index": int,      # Mouse button (MOUSE_BUTTON_LEFT, etc.)
    "pressed": bool,          # For click events, whether pressed or released
    "delta": Vector2,         # For drag_move, movement delta
    "cancelled": bool         # For drag_end, if drag was cancelled
}
```

### Example Handlers

#### Hover Effect Handler

```gdscript
class HoverEffectHandler:
    var original_modulate: Color
    
    func should_handle(resource, event):
        return event.type in ["hover_enter", "hover_exit"]
    
    func handle(resource, event):
        if event.type == "hover_enter":
            original_modulate = resource.scene_node.modulate
            resource.scene_node.modulate = Color(1.2, 1.2, 1.2)
        elif event.type == "hover_exit":
            resource.scene_node.modulate = original_modulate
```

#### State Change on Click

```gdscript
class StateToggleHandler:
    func should_handle(resource, event):
        return event.type == "click" and event.pressed
    
    func handle(resource, event):
        # Toggle between states
        var current_emotion = resource.get_states().get("emotion", "neutral")
        var new_emotion = "smile" if current_emotion == "neutral" else "neutral"
        resource.set_states({"emotion": new_emotion})
```

#### Drag Handler

```gdscript
class DragHandler:
    func should_handle(resource, event):
        return event.type in ["drag_start", "drag_move", "drag_end"]
    
    func handle(resource, event):
        if event.type == "drag_move":
            # Move the resource
            resource.scene_node.position += event.delta
        elif event.type == "drag_end":
            print("Dragged to: ", resource.scene_node.position)
```

### Automatic Collision Shape

The `InteractionArea` automatically generates a collision polygon from the sprite's alpha channel using `BitMap.create_from_image_alpha()` and `BitMap.opaque_to_polygons()`. This means:

- Collision detection follows the exact shape of your sprite
- Transparent areas are not clickable
- Collision shape updates automatically when texture changes

### Benefits

- **No subclassing required**: Add different behaviors without extending classes
- **Composable**: Mix and match handlers for different behaviors
- **Reusable**: Write handlers once, use on any resource
- **Context-aware**: Handlers receive resource reference, can access states and trigger actions
- **Flexible filtering**: Use `should_handle()` to control when handlers respond

## Current Limitations

This is a minimal prototype focused on core functionality:

- **Limited Actions**: Only Show, Hide, Say, and Wait implemented
- **No Animation**: Move, Rotate, Scale actions not yet implemented
- **No Transitions**: No scene transitions or effects
- **Basic Dialog**: Simple dialog box with no rich text features
- **2D Only**: Acting layer uses 2D (3D support planned)

## Roadmap

Future features to consider:
- Move, Rotate, Scale, and other transform actions
- Rich text and dialog effects (typewriter, shake, etc.)
- Scene transitions and visual effects
- Character expressions and poses
- Audio support (music, sound effects, voice)
- Save/Load system
- Choice menus and branching
- True 3D support in acting layer
- Visual editor for scene creation

## License

MIT License - feel free to use in your projects!

## Comparison with Ren'Py/Rakugo

| Feature | GENPY | Ren'Py/Rakugo |
|---------|-------|---------------|
| Scripting | Pure GDScript (programmatic) | Custom script language |
| Type Safety | Full (GDScript types) | Limited |
| IDE Support | Full autocomplete, debugging | Text editor only |
| Graphics | 2.5D with 3D potential | 2D only |
| Learning Curve | Steeper (need GDScript) | Easier (simple syntax) |
| Flexibility | High (access to full engine) | Limited to script commands |
| Performance | Native speed | Interpreted |

GENPY trades the simplicity of a scripting language for the power and flexibility of direct engine access.

