# Factory Pattern Refactor - Animation System

## Overview

The AnimationRepository has been refactored to follow the Factory Pattern, achieving better separation of concerns and improved extensibility.

## Problem with Previous Design

The AnimationRepository contained multiple `_create_*` methods that violated the Single Responsibility Principle:

```gdscript
# OLD - Repository doing too much
func _create_from_definition(definition: Dictionary) -> VNAnimationNode:
    match anim_type:
        "transform":
            return _create_transform_animation(duration, params)
        "state_change":
            return _create_state_change_animation(duration, params)
        # ... many more create methods
```

**Issues:**
- Repository responsible for both loading AND creating
- Hard to extend with new animation types
- Each new type required modifying repository
- Violates Open/Closed Principle

## New Architecture

### 1. AnimationFactoryBase

Base class defining the factory interface:

```gdscript
class_name AnimationFactoryBase
extends RefCounted

func can_create(anim_type: String) -> bool:
    # Returns true if this factory handles this type
    
func create(definition: Dictionary) -> VNAnimationNode:
    # Creates and returns animation instance
```

### 2. Specific Factories

Each animation type has its own factory:

- **TransformAnimationFactory** - Creates TransformAnimation instances
- **StateChangeAnimationFactory** - Creates StateChangeAnimation instances  
- **ShaderAnimationFactory** - Creates ShaderAnimation instances
- **VideoAnimationFactory** - Creates VideoAnimation instances
- **InstantAnimationFactory** - Creates InstantAnimation instances

Example factory:

```gdscript
class_name TransformAnimationFactory
extends AnimationFactoryBase

func can_create(anim_type: String) -> bool:
    return anim_type == "transform"

func create(definition: Dictionary) -> VNAnimationNode:
    var duration = _get_duration(definition)
    var params = _get_parameters(definition)
    
    var easing = _parse_easing(params.get("easing", "linear"))
    var anim = TransformAnimation.new(duration, easing)
    
    # Configure animation from params...
    return anim
```

### 3. AnimationFactoryRegistry

Central registry that manages all factories:

```gdscript
class_name AnimationFactoryRegistry

var _factories: Dictionary = {}  # type -> factory

func register_factory(anim_type: String, factory: AnimationFactoryBase) -> void:
    _factories[anim_type] = factory

func create_animation(definition: Dictionary) -> VNAnimationNode:
    var anim_type = definition.get("type", "instant")
    var factory = _factories.get(anim_type, _fallback_factory)
    return factory.create(definition)
```

### 4. Updated AnimationRepository

Now focuses solely on loading and caching:

```gdscript
extends Node

var _factory_registry: AnimationFactoryRegistry = null

func _init() -> void:
    _factory_registry = AnimationFactoryRegistry.new()

func load_animation(name: String, context: Dictionary = {}) -> VNAnimationNode:
    # Load definition from YAML
    var definition = _load_animation_yaml(...)
    
    # Delegate creation to factory registry
    return _factory_registry.create_animation(definition)
```

## File Structure

```
scripts/infra/animation/
├── animation_repository.gd              # Repository - loading & caching
├── animation_factory_registry.gd        # Registry - factory management
└── factory/                             # Factory folder
    ├── animation_factory_base.gd        # Base factory interface
    ├── transform_animation_factory.gd   # Transform factory
    ├── state_change_animation_factory.gd # State change factory
    ├── shader_animation_factory.gd      # Shader factory
    ├── video_animation_factory.gd       # Video factory
    └── instant_animation_factory.gd     # Instant factory
```

## Benefits

### 1. Single Responsibility Principle
- **Repository**: Load definitions, manage cache
- **Registry**: Manage factories, delegate creation
- **Factories**: Create specific animation types

### 2. Open/Closed Principle
Add new animation types without modifying existing code:

```gdscript
# Create custom factory
class_name ParticleAnimationFactory
extends AnimationFactoryBase

func can_create(anim_type: String) -> bool:
    return anim_type == "particle"

func create(definition: Dictionary) -> VNAnimationNode:
    return ParticleAnimation.new(...)

# Register it
AnimationRepository.register_factory("particle", ParticleAnimationFactory.new())
```

### 3. Dependency Inversion
High-level repository depends on abstract factory interface, not concrete implementations.

### 4. Testability
Each factory can be tested independently:

```gdscript
func test_transform_factory():
    var factory = TransformAnimationFactory.new()
    assert(factory.can_create("transform"))
    
    var definition = {"type": "transform", "duration": 1.0}
    var anim = factory.create(definition)
    assert(anim is TransformAnimation)
```

### 5. Runtime Extensibility
Factories can be registered at runtime:

```gdscript
# In game initialization
var custom_factory = MyGameSpecificAnimationFactory.new()
AnimationRepository.register_factory("my_game_anim", custom_factory)
```

## Migration

### Before
```gdscript
# Repository handled everything
AnimationRepository._create_transform_animation(duration, params)
AnimationRepository._create_state_change_animation(duration, params)
```

### After
```gdscript
# Repository delegates to factory registry
var definition = {"type": "transform", "duration": 1.0, ...}
var anim = AnimationRepository.load_animation("bounce", context)
# Internally: registry.create_animation(definition)
```

## Usage Examples

### Loading Animations (No Change)
```gdscript
# Usage stays the same from outside
var bounce_anim = AnimationRepository.load_animation("bounce", context)
actor.move().left(0.2).using("bounce")
```

### Registering Custom Factory
```gdscript
# Create your custom factory
class_name TwistAnimationFactory extends AnimationFactoryBase:
    func can_create(anim_type: String) -> bool:
        return anim_type == "twist"
    
    func create(definition: Dictionary) -> VNAnimationNode:
        return TwistAnimation.new(...)

# Register at startup
func _ready():
    AnimationRepository.register_factory("twist", TwistAnimationFactory.new())
```

### Using Custom Animation
```yaml
# animations/twist.yaml
type: twist
duration: 0.8
parameters:
  twist_speed: 2.0
```

```gdscript
actor.rotate().by_degrees(360).using("twist")
```

## Performance Considerations

- Factory registry is created once at AnimationRepository initialization
- Factory lookup is O(1) dictionary access
- No performance regression from previous implementation
- Slight memory increase for factory instances (negligible)

## Design Patterns Used

1. **Factory Pattern**: Factory classes create animation instances
2. **Registry Pattern**: Central registry manages factories
3. **Strategy Pattern**: Different factories for different animation types
4. **Dependency Injection**: Registry injected into repository

## Future Enhancements

### Auto-Discovery
Scan factory folder and auto-register factories:

```gdscript
func _init() -> void:
    _factory_registry = AnimationFactoryRegistry.new()
    _factory_registry.scan_and_register_factories("res://scripts/infra/animation/factory/")
```

### Factory Priorities
Multiple factories for same type with priority levels:

```gdscript
registry.register_factory("transform", factory, priority: 10)
```

### Factory Composition
Factories that compose other factories:

```gdscript
class_name CompositeAnimationFactory:
    func create(definition) -> VNAnimationNode:
        var base = transform_factory.create(definition)
        var overlay = shader_factory.create(definition)
        return CompositeAnimation.new([base, overlay])
```

## Summary

The factory pattern refactor achieves:

✅ **Better separation of concerns**
✅ **Improved extensibility** 
✅ **Cleaner architecture**
✅ **No API changes for users**
✅ **Runtime factory registration**
✅ **Easier testing**
✅ **Follows SOLID principles**

The AnimationRepository is now focused on its core responsibility (loading definitions), while factories handle the complexity of instance creation.

