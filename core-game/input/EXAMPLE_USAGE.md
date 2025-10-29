# Interaction System Usage Examples

## Basic Setup

The interaction system allows ResourceNodes (like actors) to respond to user input through a flexible builder pattern.

## Example 1: Simple Poke Interaction

```gdscript
# Create an interaction that responds to hover and custom input
var poke_interaction = InteractionBuilder.builder() \
    .name("poke") \
    .add(InputBuilder.hover() \
        .in_callback(func(ctrl): ctrl.model.set_focused(true)) \
        .out_callback(func(ctrl): ctrl.model.set_focused(false)) \
        .build()) \
    .add(InputBuilder.custom("ui_accept") \
        .on_focus(true) \
        .callback(func(ctrl): ctrl.express("surprised").say("Ow!")) \
        .build()) \
    .build()

# Register the interaction (stores but doesn't activate)
actor_ctrl.interaction(poke_interaction)

# Queue action to activate the interaction
actor_ctrl.interact("poke")

# Later, queue action to deactivate
actor_ctrl.stop_interact("poke")
```

## Example 2: Multi-Input Interaction

```gdscript
# Create an interaction with multiple custom inputs
var examine_interaction = InteractionBuilder.builder() \
    .name("examine") \
    .add(InputBuilder.hover() \
        .in_callback(func(ctrl): 
            ctrl.model.set_focused(true)
            # Could also trigger a visual effect here
        ) \
        .out_callback(func(ctrl): ctrl.model.set_focused(false)) \
        .build()) \
    .add(InputBuilder.custom("ui_accept") \
        .on_focus(true) \
        .callback(func(ctrl): 
            ctrl.say("Let me take a closer look...")
        ) \
        .build()) \
    .add(InputBuilder.custom("ui_cancel") \
        .on_focus(true) \
        .callback(func(ctrl): 
            ctrl.say("Never mind.")
        ) \
        .build()) \
    .build()

actor_ctrl.interaction(examine_interaction).interact("examine")
```

## Example 3: Dialogue Choice Interaction

```gdscript
# Create an interaction for dialogue choices
var choice_interaction = InteractionBuilder.builder() \
    .name("dialogue_choice") \
    .add(InputBuilder.hover() \
        .in_callback(func(ctrl): 
            ctrl.model.set_focused(true)
            # Highlight this choice
        ) \
        .out_callback(func(ctrl): 
            ctrl.model.set_focused(false)
            # Un-highlight
        ) \
        .build()) \
    .add(InputBuilder.custom("ui_accept") \
        .on_focus(true) \
        .callback(func(ctrl): 
            # Select this choice and trigger dialogue progression
            ctrl.say("I choose this option!")
            # Could emit a signal or call a callback here
        ) \
        .build()) \
    .build()

choice_actor.interaction(choice_interaction)
```

## Example 4: Combat Target Selection

```gdscript
# Create an interaction for selecting combat targets
var target_interaction = InteractionBuilder.builder() \
    .name("combat_target") \
    .add(InputBuilder.hover() \
        .in_callback(func(ctrl): 
            ctrl.model.set_focused(true)
            # Show targeting reticle
            ctrl.apply_view_effect(func(view): 
                # Add visual feedback for targeting
                pass
            )
        ) \
        .out_callback(func(ctrl): 
            ctrl.model.set_focused(false)
            # Hide targeting reticle
        ) \
        .build()) \
    .add(InputBuilder.custom("attack_action") \
        .on_focus(true) \
        .callback(func(ctrl): 
            # Execute attack on this target
            ctrl.express("hurt").say("Oof!")
        ) \
        .build()) \
    .build()

enemy_ctrl.interaction(target_interaction)
# Activate during combat
enemy_ctrl.interact("combat_target")
# Deactivate when combat ends
enemy_ctrl.stop_interact("combat_target")
```

## Key Concepts

### Input Types

- **hover**: Mouse enter/exit events
  - `in_callback`: Called when mouse enters
  - `out_callback`: Called when mouse exits

- **custom**: Godot input actions (defined in Project Settings > Input Map)
  - `callback`: Single-fire callback (on action pressed)
  - `in_callback`: Called when action is pressed
  - `out_callback`: Called when action is released

### Focus

- Use `.on_focus(true)` to require the resource to be focused before the input fires
- Focus is automatically managed by hover callbacks calling `ctrl.model.set_focused(true/false)`
- Multiple resources can be interacted with, but only one can be focused at a time per user

### Activation

- `ctrl.interaction(definition)`: Registers the interaction (stored but inactive)
- `ctrl.interact(name)`: Queues an action to activate the interaction
- `ctrl.stop_interact(name)`: Queues an action to deactivate the interaction

### Callbacks

- Callbacks receive the controller as their parameter
- Callbacks execute immediately (not through the action queue)
- Callbacks can enqueue actions using controller methods (e.g., `ctrl.say()`, `ctrl.express()`)
- Use lambda functions for inline callbacks or named functions for reusable logic

## Custom Input Actions

To use custom input actions, define them in `project.godot`:

```ini
[input]

attack_action={
"events": [Object(InputEventKey, "keycode": 65)]  # 'A' key
}

examine_action={
"events": [Object(InputEventKey, "keycode": 69)]  # 'E' key
}
```

## Integration with MVC Architecture

The interaction system follows the MVC pattern:

- **Model** (Character/Transformable): Stores `focused` state
- **View** (Actor): Detects input via Area3D/Area2D collision shapes
- **Controller** (ActorController): Provides public API for interaction management

Input callbacks operate on controllers, which can update models (triggering observer updates) or apply view effects.

