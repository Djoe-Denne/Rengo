# Interaction Input System - Layer-Based Texture Collision

## Overview

A flexible, builder-pattern-based input handling system with texture-based collision detection has been successfully implemented for DisplayableNodes (characters, backgrounds, etc.) in the visual novel engine. The system provides per-layer interaction support, allowing fine-grained input handling on specific visual layers or merged root collision areas. All callbacks receive layer information, enabling layer-specific responses to user input.

## What Was Implemented

### Core Architecture

**NEW: DisplayableNode/DisplayableLayer System**

1. **DisplayableLayer** (`rengo/views/displayable_layer.gd`) - **NEW**
   - Self-contained layer wrapper extending Node3D
   - Manages: MeshInstance3D, texture, collision area, shader, visibility
   - **Texture-based collision**: Extracts polygon from alpha channel
   - Signals: `layer_hovered`, `layer_unhovered`, `layer_clicked`
   - Automatically notifies InteractionHandler with layer information
   - Dynamically rebuilds collision when texture changes

2. **DisplayableNode** (`rengo/views/displayable_node.gd`) - **NEW**
   - Base class for multi-layer displayable resources
   - Extends ResourceNode
   - Manages dictionary of DisplayableLayer instances
   - **Root collision area**: Merged collision of all visible layers
   - Automatically rebuilds root collision when layer visibility changes
   - Routes layer signals to InteractionHandler

3. **Actor** (`rengo/views/actor.gd`) - **REFACTORED**
   - Now extends DisplayableNode (was ResourceNode)
   - Simplified: layer management delegated to base class
   - Focuses on character-specific logic and observation

### Input System Classes (in `core-game/input/`)

1. **InputDefinition** (`input_definition.gd`)
   - Data class representing a single input configuration
   - Supports "hover" and "custom" input types
   - Stores callbacks for in/out/on events
   - **Callbacks now receive (controller, layer_name) parameters**
   - Includes focus requirement flag

2. **InputBuilder** (`input_builder.gd`) - **UPDATED**
   - Fluent API for building InputDefinitions
   - Static methods: `hover()`, `custom(action_name)`
   - Chaining methods: `on_focus()`, `in_callback()`, `out_callback()`, `callback()`
   - **All callbacks have signature: func(controller, layer_name)**
   - `build()` method returns InputDefinition

3. **InteractionDefinition** (`interaction_definition.gd`) - **UPDATED**
   - Data class for complete interactions
   - Contains name, array of InputDefinitions, and activation state
   - **NEW: Layer tracking with `active_layers` dictionary**
   - Methods: `activate_on_layer()`, `deactivate_on_layer()`, `is_active_on_layer()`
   - Helper methods for querying inputs by type or action

4. **InteractionBuilder** (`interaction_builder.gd`)
   - Fluent API for building InteractionDefinitions
   - Static constructor: `builder()`
   - Methods: `name()`, `add()`, `build()`

5. **InteractionHandler** (`interaction_handler.gd`) - **UPDATED**
   - Singleton autoload managing all interactions
   - Maintains registry of active/registered interactions per controller
   - **Layer-aware routing**: Tracks activation per layer
   - Methods accept optional `layer_name` parameter (null = root)
   - **Passes layer information to all callbacks**
   - Tracks focus state per resource
   - Registered as autoload in project.godot

6. **CollisionHelper** (`collision_helper.gd`) - **UPDATED**
   - Utility for generating collision shapes
   - **NEW: `create_area3d_from_texture()`**: Texture-based 3D collision
   - **NEW: `create_collision_polygon_from_texture()`**: Alpha channel extraction
   - **NEW: `convert_2d_polygon_to_3d_collision()`**: 2D to 3D shape conversion
   - **NEW: `merge_area3d_shapes()`**: Merges multiple Area3D for root collision
   - **NEW: `update_merged_area3d()`**: Updates merged collision dynamically
   - `create_area3d_for_actor()`: DEPRECATED - use DisplayableLayer
   - `create_area2d_for_sprite()`: Creates Area2D with polygon from texture alpha

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

**DisplayableNode** (`rengo/views/displayable_node.gd`) - **NEW**
- Extends ResourceNode
- Properties:
  - `layers: Dictionary` - All DisplayableLayer instances by name
  - `root_interaction_area: Area3D` - Merged collision of visible layers
  - `interaction_areas: Dictionary` - All collision areas (root + per-layer)
  - `controller` - Reference for interaction callbacks
- Methods:
  - `add_layer()` - Creates and registers a DisplayableLayer
  - `get_layer()` - Retrieves layer by name
  - `remove_layer()` - Removes and frees a layer
  - `get_visible_layers()` - Returns array of visible layers
  - `rebuild_root_collision()` - Merges all visible layer collisions
  - `_on_layer_visibility_changed()` - Triggered when layer visibility changes
  - `_connect_layer_signals()` - Connects layer signals to interaction system
- Signal handlers for root area hover events

**DisplayableLayer** (`rengo/views/displayable_layer.gd`) - **NEW**
- Extends Node3D (wraps mesh, texture, collision, shader)
- Properties:
  - `layer_name: String` - Layer identifier
  - `mesh_instance: MeshInstance3D` - Visual mesh
  - `interaction_area: Area3D` - Texture-based collision
  - `texture: Texture2D` - Current texture
  - `shader_material: ShaderMaterial` - Applied shader
  - `is_visible: bool` - Visibility state
  - `z_index: float` - Layer ordering
- Methods:
  - `set_texture()` - Updates texture and rebuilds collision
  - `apply_shader()` - Applies shader with parameters
  - `clear_shader()` - Removes shader
  - `set_layer_visible()` - Controls visibility (triggers root rebuild)
  - `create_collision_area()` - Generates Area3D from texture alpha
  - `rebuild_collision()` - Regenerates collision
- Automatically notifies InteractionHandler on hover with layer name

**Actor** (`rengo/views/actor.gd`) - **REFACTORED**
- Now extends DisplayableNode (was ResourceNode)
- Removed: `sprite_container`, `layers` dictionary (inherited from DisplayableNode)
- Simplified `create_scene_node()` - delegates collision to parent
- Removed direct mesh/collision management
- Focuses on character observation and state management

### Controller Extensions

**ActorController** (`rengo/controllers/actor_controller.gd`)
- Added `interaction(InteractionDefinition)` method
  - Registers interaction to view and InteractionHandler
  - Returns self for chaining
- Added `interact(String)` method - **UPDATED**
  - Creates and registers InteractAction
  - Returns ActionNode with `.on()` chaining support
- Added `stop_interact(String)` method - **UPDATED**
  - Creates and registers StopInteractAction
  - Returns ActionNode with `.on()` chaining support

### New Actions

**InteractAction** (`rengo/controllers/actions/input/interact_action.gd`) - **UPDATED**
- Activates a registered interaction
- Instant completion (duration = 0)
- **NEW: `target_layer` property** - Specifies layer (null = root only)
- **NEW: `on(layer_name)` method** - Fluent API for layer targeting
- Calls `InteractionHandler.activate(controller, interaction_name, target_layer)`
- **Example**: `actor_ctrl.interact("poke").on("face")`

**StopInteractAction** (`rengo/controllers/actions/input/stop_interact_action.gd`) - **UPDATED**
- Deactivates an active interaction
- Instant completion (duration = 0)
- **NEW: `target_layer` property** - Specifies layer (null = all layers)
- **NEW: `on(layer_name)` method** - Fluent API for layer targeting
- Calls `InteractionHandler.deactivate(controller, interaction_name, target_layer)`
- **Example**: `actor_ctrl.stop_interact("poke").on("face")`

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
# NOTE: All callbacks now receive (controller, layer_name) parameters
var poke_interaction = InteractionBuilder.builder() \
    .name("poke") \
    .add(InputBuilder.hover() \
        .in_callback(func(ctrl, layer): 
            print("Hovering ", layer if layer else "root")
            ctrl.model.set_state("status", "focused")) \
        .out_callback(func(ctrl, layer): 
            ctrl.model.set_state("status", "")) \
        .build()) \
    .add(InputBuilder.custom("ok_confirm") \
        .on_focus(true) \
        .callback(func(ctrl, layer): 
            var msg = "Ow on " + (layer if layer else "character")
            ctrl.express("surprised").say(msg)) \
        .build()) \
    .build()

# Register interaction (stores but inactive)
actor_ctrl.interaction(poke_interaction)

# Activate on root (merged collision of all visible layers)
actor_ctrl.interact("poke")

# Activate on specific layer only (e.g., face layer)
actor_ctrl.interact("poke").on("face")

# Deactivate all layers
actor_ctrl.stop_interact("poke")

# Deactivate specific layer only
actor_ctrl.stop_interact("poke").on("face")
```

## Key Features

### 1. Builder Pattern API
Clean, fluent API for defining complex interactions with multiple inputs and callbacks.

### 2. Texture-Based Collision Detection
- **Alpha channel extraction**: Precise collision polygons from texture transparency
- **Per-layer collision**: Each DisplayableLayer has its own interaction area
- **Root collision**: Dynamically merged collision of all visible layers
- **Automatic rebuild**: Root collision updates when layer visibility changes

### 3. Per-Layer Interactions
- **Layer targeting**: Activate interactions on specific layers with `.on(layer_name)`
- **Layer callbacks**: All callbacks receive layer information
- **Mixed activation**: Same interaction can be active on multiple layers simultaneously
- **Fine-grained control**: Deactivate per layer or all at once

### 4. MVC Integration
- **Model**: Focus state stored in Transformable with observer pattern
- **View**: DisplayableNode/DisplayableLayer architecture for self-managing layers
- **Controller**: Public API for interaction management with layer support

### 5. Action Queue Integration
Activation/deactivation queued as actions for synchronization with scene flow.

### 6. Immediate Callback Execution
Callbacks execute immediately for responsive input, but can enqueue actions for choreographed responses.

### 7. Automatic Collision Management
- **3D**: ConvexPolygonShape3D from texture alpha channel
- **2D**: Polygon2D from texture alpha channel
- **Dynamic**: Collision rebuilds when texture changes
- **Merged**: Root area combines all visible layer collisions

### 8. Focus Management
- Stored in model for observer reactivity
- Automatically managed by hover callbacks
- Enforceable requirement for custom actions

### 9. Flexible Input Types
- **Hover**: Mouse enter/exit events (per layer or root)
- **Custom**: Any Godot input action (keyboard, mouse, gamepad)

### 10. Scalable Architecture
- **DisplayableNode**: Base class for any multi-layer displayable resource
- **DisplayableLayer**: Self-contained layer with texture, collision, shader
- **Extensible**: Easy to add support for Backgrounds, Props, UI elements

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
rengo/views/
├── displayable_layer.gd         # NEW: Self-contained layer wrapper
└── displayable_node.gd          # NEW: Multi-layer displayable base class

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
rengo/views/actor.gd                           # REFACTORED: Extends DisplayableNode
rengo/views/theater_actor_director.gd          # UPDATED: Works with DisplayableLayer
rengo/controllers/actor_controller.gd          # Added interaction methods
core-game/input/collision_helper.gd            # UPDATED: Texture polygon extraction
core-game/input/interaction_definition.gd      # UPDATED: Layer activation tracking
core-game/input/interaction_handler.gd         # UPDATED: Layer-aware routing
core-game/input/input_builder.gd               # UPDATED: Callback signature docs
rengo/controllers/actions/input/interact_action.gd       # UPDATED: .on() chaining
rengo/controllers/actions/input/stop_interact_action.gd  # UPDATED: .on() chaining
rengo/models/interfaces/transformable.gd       # Added focused property
rengo/domain/resource_node.gd                  # Added interaction support
project.godot                                  # Registered autoload + ok_confirm action
```

## Architecture Benefits

### Encapsulation
Each DisplayableLayer manages its own texture, collision, shader, and visibility. No external code needs to manage these concerns.

### Scalability
The DisplayableNode/DisplayableLayer pattern can be extended to:
- Backgrounds with multi-layer parallax
- Interactive UI elements with layer-specific hotspots
- Props and environmental objects
- Any resource that needs layered rendering and interaction

### Maintainability
Clear separation of concerns:
- **DisplayableLayer**: Single layer management
- **DisplayableNode**: Multi-layer coordination and root collision
- **Actor**: Character-specific observation and behavior
- **Director**: Layer creation and texture application
- **InteractionHandler**: Global interaction routing

### Performance
- Collision shapes generated once per texture
- Root collision rebuilds only when layer visibility changes
- No per-frame overhead for inactive interactions
- Dictionary lookups for O(1) interaction queries

## Conclusion

The interaction input system with layer-based texture collision is fully implemented and ready for use. It provides:

1. **Texture-based collision**: Precise interaction areas from alpha channels
2. **Per-layer targeting**: Fine-grained control over which layers respond to input
3. **Dynamic root collision**: Automatically merged collision of visible layers
4. **Clean architecture**: DisplayableNode/DisplayableLayer pattern for scalability
5. **Fluent API**: `.on()` chaining for layer-specific activation
6. **Layer-aware callbacks**: All callbacks receive layer information

All planned features have been implemented, documented, and tested. The system is extensible and follows established patterns in the codebase.

