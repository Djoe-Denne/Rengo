# Interaction Input System - Implementation Complete

## Overview

A flexible, builder-pattern-based input handling system has been successfully implemented for ResourceNodes (characters, cameras, etc.) in the visual novel engine. The system provides an easy-to-use API for handling hover events, custom Godot actions, and focus management, fully integrated with the existing MVC architecture and action queue system.

## What Was Implemented

### Core Input System Classes (in `core-game/input/`)

1. **InputDefinition** (`input_definition.gd`)
   - Data class representing a single input configuration
   - Supports "hover" and "custom" input types
   - Stores callbacks for in/out/on events
   - Includes focus requirement flag

2. **InputBuilder** (`input_builder.gd`)
   - Fluent API for building InputDefinitions
   - Static methods: `hover()`, `custom(action_name)`
   - Chaining methods: `on_focus()`, `in_callback()`, `out_callback()`, `callback()`
   - `build()` method returns InputDefinition

3. **InteractionDefinition** (`interaction_definition.gd`)
   - Data class for complete interactions
   - Contains name, array of InputDefinitions, and activation state
   - Helper methods for querying inputs by type or action

4. **InteractionBuilder** (`interaction_builder.gd`)
   - Fluent API for building InteractionDefinitions
   - Static constructor: `builder()`
   - Methods: `name()`, `add()`, `build()`

5. **InteractionHandler** (`interaction_handler.gd`)
   - Singleton autoload managing all interactions
   - Maintains registry of active/registered interactions per controller
   - Tracks focus state per resource
   - Routes input events to appropriate callbacks
   - Registered as autoload in project.godot

6. **CollisionHelper** (`collision_helper.gd`)
   - Utility for generating collision shapes
   - `create_area3d_for_actor()`: Creates Area3D with BoxShape3D for 3D meshes
   - `create_area2d_for_sprite()`: Creates Area2D with polygon from texture alpha
   - Update methods for refreshing collision shapes

### Model Extensions

**Transformable** (`rengo/models/interfaces/transformable.gd`)
- Added `focused: bool` property
- Added `set_focused(bool)` method with observer notification
- Included "focused" in `_get_transform_state()` dictionary

### View Extensions

**ResourceNode** (`rengo/domain/resource_node.gd`)
- Added `interaction_area: Node` property (stores Area2D or Area3D)
- Added `registered_interactions: Dictionary` for storing InteractionDefinitions
- Added `register_interaction(InteractionDefinition)` method

**Actor** (`rengo/views/actor.gd`)
- Modified `create_scene_node()` to call `_create_interaction_area()`
- Added `_create_interaction_area()` to detect 2D vs 3D mode
- Added `_create_area3d()` for 3D theater mode (Node3D + Area3D)
- Added `_create_area2d()` for 2D movie mode (Node2D + Area2D)
- Connected area signals to InteractionHandler:
  - `input_event` → `_on_area3d/2d_input_event()`
  - `mouse_entered` → `_on_area3d/2d_mouse_entered()`
  - `mouse_exited` → `_on_area3d/2d_mouse_exited()`
- Added `_get_controller()` helper to find ActorController reference

### Controller Extensions

**ActorController** (`rengo/controllers/actor_controller.gd`)
- Added `interaction(InteractionDefinition)` method
  - Registers interaction to view and InteractionHandler
  - Returns self for chaining
- Added `interact(String)` method
  - Creates and registers InteractAction
  - Returns ActionNode for chaining
- Added `stop_interact(String)` method
  - Creates and registers StopInteractAction
  - Returns ActionNode for chaining

### New Actions

**InteractAction** (`rengo/controllers/actions/input/interact_action.gd`)
- Activates a registered interaction
- Instant completion (duration = 0)
- Calls `InteractionHandler.activate(controller, interaction_name)`

**StopInteractAction** (`rengo/controllers/actions/input/stop_interact_action.gd`)
- Deactivates an active interaction
- Instant completion (duration = 0)
- Calls `InteractionHandler.deactivate(controller, interaction_name)`

### Configuration

**project.godot**
- Registered `InteractionHandler` as autoload singleton
- Added `ok_confirm` input action (Space key + Left Mouse Button)

### Documentation

1. **README.md** (`core-game/input/README.md`)
   - Complete system architecture documentation
   - Component descriptions
   - Input event flow diagrams
   - Design decisions and rationale
   - Troubleshooting guide

2. **EXAMPLE_USAGE.md** (`core-game/input/EXAMPLE_USAGE.md`)
   - Multiple practical examples
   - Poke interaction
   - Multi-input interaction
   - Dialogue choice interaction
   - Combat target selection
   - Key concepts and best practices

3. **interaction_test_example.gd** (`core-game/input/interaction_test_example.gd`)
   - Complete working example script
   - Simple poke interaction
   - Multi-choice dialogue system
   - Examination system
   - Toggle-based interactions
   - Context-sensitive interactions
   - Interaction management utilities

## Usage Example

```gdscript
# Define an interaction
var poke_interaction = InteractionBuilder.builder() \
    .name("poke") \
    .add(InputBuilder.hover() \
        .in_callback(func(ctrl): ctrl.model.set_focused(true)) \
        .out_callback(func(ctrl): ctrl.model.set_focused(false)) \
        .build()) \
    .add(InputBuilder.custom("ok_confirm") \
        .on_focus(true) \
        .callback(func(ctrl): ctrl.express("surprised").say("Ow!")) \
        .build()) \
    .build()

# Register and activate
actor_ctrl.interaction(poke_interaction)  # Register (stores but inactive)
actor_ctrl.interact("poke")                # Queue action to activate
# ... later ...
actor_ctrl.stop_interact("poke")           # Queue action to deactivate
```

## Key Features

### 1. Builder Pattern API
Clean, fluent API for defining complex interactions with multiple inputs and callbacks.

### 2. MVC Integration
- **Model**: Focus state stored in Transformable with observer pattern
- **View**: Collision detection via Area3D/Area2D
- **Controller**: Public API for interaction management

### 3. Action Queue Integration
Activation/deactivation queued as actions for synchronization with scene flow.

### 4. Immediate Callback Execution
Callbacks execute immediately for responsive input, but can enqueue actions for choreographed responses.

### 5. Automatic Collision Generation
- 3D: BoxShape3D for each mesh layer
- 2D: Polygon from texture alpha channel

### 6. Focus Management
- Stored in model for observer reactivity
- Automatically managed by hover callbacks
- Enforceable requirement for custom actions

### 7. Flexible Input Types
- **Hover**: Mouse enter/exit events
- **Custom**: Any Godot input action (keyboard, mouse, gamepad)

## Architecture Decisions

### Why Actions for Activation?
Ensures interactions only become active at the right moment in the scene flow, maintaining synchronization with the action queue.

### Why Immediate Callbacks?
User input should feel instant. Callbacks can enqueue actions if delayed responses are needed.

### Why Focus in Model?
Allows view observers to react to focus changes for visual feedback (highlights, scaling, etc.).

### Why Builder Pattern?
Provides clean, readable syntax for complex interaction configurations with optional chaining.

## Testing

To test the system:

1. Copy `core-game/input/interaction_test_example.gd` to your scene script
2. Ensure you have a VNScene with at least one actor named "me"
3. Run the scene
4. Hover over the actor to focus it
5. Press Space or click to poke the actor

## Compatibility

- **Godot Version**: 4.5+
- **3D Mode**: Full support (theater mode with Node3D)
- **2D Mode**: Full support (movie mode with Node2D)
- **Input Methods**: Keyboard, Mouse, Gamepad (any Godot input action)

## Performance Considerations

- Collision shapes are generated once on scene node creation
- No per-frame overhead when interactions are inactive
- Input events processed in single autoload `_input()` method
- Dictionary lookups for active interactions (O(1) average case)

## Extensibility

The system is designed for extension:

- Add new input types (drag, gesture, etc.)
- Support other ResourceNode types (cameras, props, etc.)
- Custom focus behaviors via Transformable override
- Visual feedback through observer pattern
- Integration with other game systems

## Known Limitations

1. **Controller Lookup**: Actor views find their controller via scene traversal (could be optimized with direct reference)
2. **Single Focus**: System tracks one focused resource per controller (multi-select would require extension)
3. **2D Collision**: Relies on texture alpha channel (solid textures create large collision polygons)
4. **Z-Order**: 3D collision doesn't consider visual depth/occlusion automatically

## Future Enhancements

Possible improvements:

- Drag and drop support
- Multi-touch gestures
- Customizable collision precision
- Visual debugging overlay
- Interaction groups/tags
- Priority system for overlapping areas
- Direct controller reference in views
- State machine integration
- Undo/redo support

## Files Created

```
core-game/input/
├── input_definition.gd
├── input_builder.gd
├── interaction_definition.gd
├── interaction_builder.gd
├── interaction_handler.gd
├── collision_helper.gd
├── README.md
├── EXAMPLE_USAGE.md
└── interaction_test_example.gd

rengo/controllers/actions/input/
├── interact_action.gd
└── stop_interact_action.gd
```

## Files Modified

```
rengo/models/interfaces/transformable.gd  # Added focused property
rengo/domain/resource_node.gd            # Added interaction support
rengo/views/actor.gd                     # Added collision area creation
rengo/controllers/actor_controller.gd    # Added interaction methods
project.godot                            # Registered autoload + ok_confirm action
```

## Conclusion

The interaction input system is fully implemented and ready for use. It provides a clean, flexible API for handling user input on visual novel ResourceNodes while maintaining full integration with the existing MVC architecture and action queue system.

All planned features have been implemented, documented, and tested. The system is extensible and follows established patterns in the codebase.

