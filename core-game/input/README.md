# Interaction Input System

A flexible, builder-pattern-based input handling system for visual novel ResourceNodes (characters, cameras, etc.) that integrates seamlessly with the existing MVC architecture and action queue system.

## Overview

The interaction system allows any ResourceNode with a view component to respond to user input through:
- **Hover detection** (mouse enter/exit)
- **Custom Godot actions** (keyboard, mouse, gamepad)
- **Focus management** (highlighting, selection)
- **Callback-based responses** (immediate execution)

## Architecture

### Core Components

#### 1. InputDefinition (`input_definition.gd`)
Data class representing a single input configuration.

**Properties:**
- `input_type`: "hover" or "custom"
- `action_name`: Godot action name (for custom inputs)
- `requires_focus`: Whether resource must be focused
- `in_callback`: Called on enter/press
- `out_callback`: Called on exit/release
- `on_callback`: Called on single-fire events

#### 2. InputBuilder (`input_builder.gd`)
Fluent API for building InputDefinitions.

**Static Methods:**
- `InputBuilder.hover()`: Creates hover input
- `InputBuilder.custom(action_name)`: Creates custom action input

**Methods:**
- `.on_focus(bool)`: Sets focus requirement
- `.in_callback(callable)`: Sets enter/press callback
- `.out_callback(callable)`: Sets exit/release callback
- `.callback(callable)`: Sets single-fire callback
- `.build()`: Returns InputDefinition

#### 3. InteractionDefinition (`interaction_definition.gd`)
Data class representing a complete interaction with multiple inputs.

**Properties:**
- `name`: Unique identifier
- `inputs`: Array of InputDefinitions
- `is_active`: Activation state

#### 4. InteractionBuilder (`interaction_builder.gd`)
Fluent API for building InteractionDefinitions.

**Static Methods:**
- `InteractionBuilder.builder()`: Creates builder instance

**Methods:**
- `.name(String)`: Sets interaction name
- `.add(InputDefinition)`: Adds input configuration
- `.build()`: Returns InteractionDefinition

#### 5. InteractionHandler (`interaction_handler.gd`)
Singleton autoload that manages all interactions.

**Responsibilities:**
- Maintains registry of active/registered interactions
- Routes input events to appropriate callbacks
- Tracks focus state per resource
- Processes Godot input events

**Methods:**
- `register_interaction(controller, interaction)`: Stores interaction
- `activate(controller, interaction_name)`: Activates interaction
- `deactivate(controller, interaction_name)`: Deactivates interaction
- `on_hover_enter(controller)`: Called by view on mouse enter
- `on_hover_exit(controller)`: Called by view on mouse exit

#### 6. CollisionHelper (`collision_helper.gd`)
Utility for generating collision shapes.

**Static Methods:**
- `create_area3d_for_actor(Node3D)`: Creates Area3D with BoxShape3D for each mesh
- `create_area2d_for_sprite(Sprite2D)`: Creates Area2D with polygon from texture alpha
- `update_area3d_collision(Area3D, Node3D)`: Updates existing collision shapes
- `update_area2d_collision(Area2D, Sprite2D)`: Updates existing polygon

### Model Extensions

**Transformable** (`rengo/models/interfaces/transformable.gd`)
- Added `focused: bool` property
- Added `set_focused(bool)` method with observer notification
- Includes "focused" in transform state notifications

### View Extensions

**ResourceNode** (`rengo/domain/resource_node.gd`)
- Added `interaction_area: Node` property (Area2D or Area3D)
- Added `registered_interactions: Dictionary` storage
- Added `register_interaction(InteractionDefinition)` method

**Actor** (`rengo/views/actor.gd`)
- Creates Area3D (theater mode) or Area2D (movie mode) on scene node creation
- Generates collision shapes from mesh bounds or texture alpha
- Connects area signals to InteractionHandler
- Provides controller lookup for signal routing

### Controller Extensions

**ActorController** (`rengo/controllers/actor_controller.gd`)

**New Methods:**
- `interaction(InteractionDefinition) -> ActorController`: Registers interaction
- `interact(String) -> ActionNode`: Returns InteractAction
- `stop_interact(String) -> ActionNode`: Returns StopInteractAction

### New Actions

**InteractAction** (`rengo/controllers/actions/input/interact_action.gd`)
- Activates a registered interaction
- Instant completion (duration = 0)
- Queued through action system

**StopInteractAction** (`rengo/controllers/actions/input/stop_interact_action.gd`)
- Deactivates an active interaction
- Instant completion (duration = 0)
- Queued through action system

## Input Event Flow

1. **Hover Enter**
   - Area3D/Area2D detects mouse → Signals to Actor view
   - Actor calls `InteractionHandler.on_hover_enter(controller)`
   - Handler finds active interactions with hover inputs
   - Executes `in_callback` for each hover input
   - Typically sets `ctrl.model.set_focused(true)`

2. **Custom Action**
   - User presses key/button → Godot sends input event
   - `InteractionHandler._input(event)` processes event
   - Handler checks all active interactions for matching action
   - Checks focus requirement if specified
   - Executes `on_callback` or `in_callback` immediately

3. **Hover Exit**
   - Mouse leaves area → Actor calls `InteractionHandler.on_hover_exit(controller)`
   - Executes `out_callback` for hover inputs
   - Typically sets `ctrl.model.set_focused(false)`

## Usage Pattern

### 1. Define the Interaction

```gdscript
var my_interaction = InteractionBuilder.builder() \
    .name("my_interaction") \
    .add(InputBuilder.hover() \
        .in_callback(func(ctrl): ctrl.model.set_focused(true)) \
        .out_callback(func(ctrl): ctrl.model.set_focused(false)) \
        .build()) \
    .add(InputBuilder.custom("ui_accept") \
        .on_focus(true) \
        .callback(func(ctrl): ctrl.say("Hello!")) \
        .build()) \
    .build()
```

### 2. Register the Interaction

```gdscript
# Stores but doesn't activate
actor_ctrl.interaction(my_interaction)
```

### 3. Activate the Interaction

```gdscript
# Queues action to activate when it reaches front of queue
actor_ctrl.interact("my_interaction")
```

### 4. Deactivate the Interaction

```gdscript
# Queues action to deactivate
actor_ctrl.stop_interact("my_interaction")
```

## Key Design Decisions

### Why Action Queue for Activation?

Interactions are activated/deactivated through the action queue to maintain synchronization with scene flow. This ensures interactions only become active at the right moment in your visual novel script.

### Why Immediate Callback Execution?

Callbacks execute immediately (not queued) because they represent user input responses that should feel instant. However, callbacks can enqueue actions, allowing choreographed responses.

### Why Focus in Model?

Focus state lives in the model (Transformable) so view observers can react to it. This allows you to implement visual feedback (highlighting, scaling, etc.) through the observer pattern.

### Collision Shape Generation

- **3D Theater Mode**: BoxShape3D for each mesh layer (fast, simple)
- **2D Movie Mode**: Polygon from texture alpha (precise, supports transparency)
- Collision shapes are automatically generated when the actor is added to the scene

## Extending the System

### Adding New Input Types

1. Add new input type to InputBuilder (e.g., `InputBuilder.drag()`)
2. Handle new type in InteractionHandler's input processing
3. Connect appropriate signals in Actor view

### Supporting Other ResourceNodes

Any ResourceNode subclass can support interactions by:
1. Creating an interaction area in `create_scene_node()`
2. Connecting signals to InteractionHandler
3. Providing controller lookup mechanism

### Custom Focus Behavior

Override `Transformable.set_focused()` in your model to implement custom focus behavior:

```gdscript
func set_focused(new_focused: bool) -> void:
    super.set_focused(new_focused)
    # Custom logic here
```

## Best Practices

1. **Keep callbacks simple**: Use lambdas for quick responses
2. **Enqueue complex logic**: Use callbacks to trigger actions, not perform heavy work
3. **Use focus wisely**: Only require focus when preventing accidental input is important
4. **Name interactions clearly**: Use descriptive names like "examine", "talk", "select"
5. **Clean up**: Deactivate interactions when scenes end or contexts change

## Troubleshooting

### Interaction not responding

1. Verify interaction is registered: `actor_ctrl.interaction(definition)`
2. Verify interaction is activated: `actor_ctrl.interact(name)`
3. Check interaction name matches exactly
4. For custom actions, verify input is defined in project.godot
5. For focus-required inputs, check resource is focused

### Collision detection not working

1. Verify Area3D/Area2D was created (check scene tree)
2. Check collision shapes exist (should auto-generate)
3. Verify `input_ray_pickable` (3D) or `input_pickable` (2D) is true
4. For 3D, ensure camera has Camera3D node
5. For 2D, verify viewport settings

### Callbacks not firing

1. Check callback is valid: `callback.is_valid()`
2. Verify correct callback type (in/out/on)
3. For custom actions, test with `Input.is_action_pressed()`
4. Add debug prints in InteractionHandler to trace event flow

## Future Enhancements

Possible extensions to consider:

- Drag and drop support
- Multi-touch gestures
- Customizable collision shape generation
- Visual debugging tools
- Interaction groups/tags
- Priority system for overlapping areas
- State machine integration

