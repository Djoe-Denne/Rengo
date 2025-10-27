# Animation & Transformation System

## Overview

The VN engine uses a state-based architecture with a powerful animation system. Animations are applied to state changes and transformations through a composition-based approach where actions contain animation nodes.

## Core Concepts

### 1. State Changes vs Transformations

**State Changes**: Modify Character model properties (pose, expression, outfit, etc.)
- Changes are immediate by default
- Can be animated with `.over(duration)` and `.using(animation)`
- Examples: `actor.express("happy")`, `actor.pose("waving")`, `actor.wear("casual")`

**Transformations**: Modify Actor visual properties (position, rotation, scale)
- Always support animation
- Use fluent API for building transformations
- Examples: `actor.move().left(0.2)`, `actor.rotate().by_degrees(45)`, `actor.scale().up(1.5)`

### 2. AnimationNode Types

**TransformAnimation** - Smooth interpolation with easing
- Supports Vector2, Vector3, float, Color values
- 13 easing functions (linear, ease_in/out, elastic, bounce, back, etc.)
- Optional shake effects

**StateChangeAnimation** - Fade out → change → fade in
- Used for character state transitions
- Configurable fade duration
- Three target modes to prevent layer bleed-through:
  - `WHOLE_NODE`: Fades entire sprite container (default, prevents body showing through clothes)
  - `INDIVIDUAL_LAYERS`: Fades each layer independently
  - `SPECIFIC_LAYERS`: Fades only specified layers
- Ensures smooth visual transitions

**ShaderAnimation** - Custom shader effects (placeholder)
- Load shaders from YAML
- Animate shader parameters
- Effects: shake, wave, distortion, etc.

**VideoAnimation** - Video/GIF/sprite sheet playback
- Multiple formats supported
- Sync with action duration or play full video
- Looping support

## Usage Examples

### Basic State Changes

```gdscript
# Instant state change (default)
actor.express("happy")
actor.pose("idle")
actor.wear("casual")

# Animated state change
actor.express("sad").over(0.5)  # 0.5 second fade transition
actor.pose("waving").over(0.3)
actor.wear("jeans").over(0.6)
```

### Transformations

```gdscript
# Move actions
actor.move().to(0.5, 0.8).over(1.0)  # Move to position
actor.move().left(0.2).over(0.5)     # Move left by amount
actor.move().right(0.1).over(0.5)    # Move right
actor.move().up(0.1).over(0.5)       # Move up
actor.move().down(0.1).over(0.5)     # Move down

# Rotate actions
actor.rotate().to_degrees(45).over(0.5)      # Rotate to angle
actor.rotate().by_degrees(90).over(0.5)      # Rotate by amount
actor.rotate().clockwise(45).over(0.5)       # Clockwise rotation
actor.rotate().counter_clockwise(45).over(0.5)

# Scale actions
actor.scale().uniform(1.5).over(0.5)  # Scale uniformly
actor.scale().up(1.5).over(0.5)       # Scale up
actor.scale().down(1.5).over(0.5)     # Scale down
actor.scale().to(2.0, 1.0).over(0.5)  # Scale to specific values
```

### Using Named Animations

```gdscript
# Use animation from AnimationRepository
actor.move().left(0.2).over(1.0).using("bounce")
actor.move().right(0.1).over(0.8).using("shake")
actor.express("happy").using("fade")

# Programmatically register animations
AnimationRepository.register_animation("my_bounce", bounce_anim)
actor.move().up(0.1).using("my_bounce")
```

### Chaining Actions

```gdscript
# Actions are automatically queued
actor.move().left(0.2).over(1.0)
actor.scale().up(1.2).over(0.3)
actor.scale().down(1.2).over(0.3)
actor.pose("waving")
```

## YAML Configuration

### Animation Definitions

Create animation files in `assets/scenes/common/animations/` or character-specific folders:

**bounce.yaml**
```yaml
type: transform
duration: 0.8
easing: bounce_out
parameters:
  shake_intensity: 0.0
  shake_frequency: 20.0
```

**shake.yaml**
```yaml
type: transform
duration: 1.0
easing: ease_out
parameters:
  shake_intensity: 15.0
  shake_frequency: 30.0
```

### Default Animations per Character

Create `animation.yaml` in character folders:

**characters/me/animations/animation.yaml**
```yaml
defaults:
  move:
    type: transform
    easing: ease_out
    duration: 0.5
  
  express:
    type: state_change
    duration: 0.3
    parameters:
      fade_fraction: 0.3
      target_mode: whole_node  # Prevents body bleed-through
  
  pose:
    type: state_change
    duration: 0.4
    parameters:
      fade_fraction: 0.35
      target_mode: whole_node
  
  wear:
    type: state_change
    duration: 0.5
    parameters:
      fade_fraction: 0.4
      target_mode: whole_node
```

### Layer Targeting Modes

For layered characters (body + clothing sprites), control how fade animations apply:

**Whole Node (Default)** - Recommended for state changes
```yaml
type: state_change
parameters:
  target_mode: whole_node  # Fades entire sprite_container as one unit
```
This prevents the body from becoming visible through semi-transparent clothing during fade transitions.

**Individual Layers** - Each layer fades independently
```yaml
type: state_change
parameters:
  target_mode: individual_layers  # Each sprite layer fades separately
```
⚠️ Warning: This will cause body bleed-through if character has clothing layers.

**Specific Layers** - Only fade certain layers
```yaml
type: state_change
parameters:
  target_mode: specific_layers
  target_layers: ["body", "face"]  # Only fade these layers
```
Useful for effects like fading only the character's face expression while keeping the body solid.

### Priority Order

Animation resolution follows this priority:
1. **Code**: `.using(animation)` in the action call
2. **Character**: `characters/{name}/animations/`
3. **Scene**: `scenes/{scene_name}/animations/`
4. **Common**: `scenes/common/animations/`

## Easing Functions

Available easing types for TransformAnimation:

- `linear` - Constant speed
- `ease_in` - Slow start, fast end
- `ease_out` - Fast start, slow end
- `ease_in_out` - Smooth acceleration and deceleration
- `elastic_in` / `elastic_out` / `elastic_in_out` - Spring-like motion
- `bounce_in` / `bounce_out` / `bounce_in_out` - Bouncing effect
- `back_in` / `back_out` / `back_in_out` - Slight overshoot

## Architecture Details

### AnimatedAction (Base Class)

All actions that support animation extend `AnimatedAction`:
- Composes an `AnimationNode`
- Handles animation setup and processing
- Provides fluent API methods: `.over()`, `.using()`

### AnimationRepository (Singleton)

Centralized animation management:
- Loads animations from YAML files
- Supports programmatic registration
- Handles animation caching
- Resolves animations by priority (scene → character → common)
- Delegates instance creation to AnimationFactoryRegistry

### AnimationFactoryRegistry

Factory pattern for creating animation instances:
- Scans and registers animation factories
- Each factory handles a specific animation type
- Extensible: custom factories can be registered at runtime
- Clean separation: Repository loads definitions, Factories create instances

### Animation Processing Flow

1. Action is created and registered to scene controller
2. When action executes, it initializes its animation node
3. Each frame, action processes animation and applies to target
4. Animation node calculates progress and applies easing
5. Action applies interpolated value to target property
6. When complete, action ensures final value is set

## Migration from Legacy System

The old animation system used these patterns:

```gdscript
# OLD - Direct animation on resources
actor.show().with_fade(0.5)

# NEW - Animation composition in actions
actor.show().over(0.5).using("fade")
```

Legacy animations (FadeAnimation, DissolveAnimation) are still available but marked as deprecated. Use the new system for all new code.

## Creating Custom Animation Factories

You can extend the system with custom animation types:

### 1. Create Your Factory

```gdscript
# scripts/infra/animation/factory/my_custom_animation_factory.gd
class_name MyCustomAnimationFactory
extends AnimationFactoryBase

func can_create(anim_type: String) -> bool:
    return anim_type == "my_custom"

func create(definition: Dictionary) -> VNAnimationNode:
    var duration = _get_duration(definition)
    var params = _get_parameters(definition)
    
    # Create your custom animation node
    var anim = MyCustomAnimation.new(duration)
    # Configure from params...
    return anim
```

### 2. Register Your Factory

```gdscript
# In your initialization code
var my_factory = MyCustomAnimationFactory.new()
AnimationRepository.register_factory("my_custom", my_factory)
```

### 3. Use in YAML

```yaml
# animations/my_effect.yaml
type: my_custom
duration: 1.0
parameters:
  custom_param: value
```

## Best Practices

1. **Use `.over()` for duration**: More readable than `.in_duration()`
2. **Name animations descriptively**: "bounce", "shake", "smooth" rather than "anim1", "anim2"
3. **Set defaults in YAML**: Configure character-specific animation preferences
4. **Chain actions thoughtfully**: Remember they execute sequentially
5. **Test easing functions**: Different easings create very different feels
6. **Keep animations short**: VN pacing is important; 0.3-1.0s for most animations
7. **Use factories for custom animations**: Don't pollute repository with create methods

## Future Enhancements

- **2D Mesh manipulation**: Facial animation, character deformation
- **Shader effects**: Full implementation of ShaderAnimation
- **Animation blending**: Combine multiple animations
- **Animation curves**: Custom bezier curves for easing
- **Timeline system**: Complex choreographed sequences

