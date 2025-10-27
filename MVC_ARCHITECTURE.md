# MVC Architecture Documentation

## Overview

The VN engine now follows a strict MVC (Model-View-Controller) architecture with proper separation of concerns and the observer pattern for state management.

## Architecture Layers

### Models (scripts/models/)

Pure data classes with no rendering logic. Implement observer pattern to notify views of changes.

#### Scene Model
- **File**: `scripts/models/scene.gd`
- **Purpose**: Holds all scene state (current plan, available plans, stage config)
- **Key Properties**:
  - `scene_name: String` - Scene identifier
  - `scene_type: String` - "theater" or "movie"
  - `current_plan_id: String` - Active plan
  - `plans: Dictionary` - All available plans
  - `stage: StageModel` - Stage configuration
- **Key Methods**:
  - `set_plan(plan_id: String)` - Changes plan and notifies observers
  - `get_current_plan() -> Plan`
  - `get_current_camera() -> Camera`
  - `add_observer(callback: Callable)` - Subscribe to changes

#### Plan Model
- **File**: `scripts/models/plan.gd`
- **Purpose**: Configuration for a specific cinematic plan/shot
- **Key Properties**:
  - `plan_id: String` - Plan identifier
  - `camera: Camera` - Camera configuration
  - `backgrounds: Dictionary` - Background configs for this plan

#### Camera Model
- **File**: `scripts/models/camera.gd`
- **Purpose**: Camera configuration data
- **Key Properties**:
  - `ratio: float` - Aspect ratio (e.g., 1.777 for 16:9)
  - `focal_min/max/default: float` - Focal length range
  - `aperture, shutter_speed, sensor_size` - Camera parameters

#### StageModel
- **File**: `scripts/models/stage_model.gd`
- **Purpose**: Stage/viewport configuration
- **Key Properties**:
  - `scaling_mode: String` - "letterbox", "fit", or "stretch"
  - `default_plan_id: String` - Initial plan to use

#### Character Model (Existing)
- **File**: `scripts/models/character.gd`
- **Purpose**: Character state and attributes
- Follows same observer pattern as Scene

### Views (scripts/views/)

Handle rendering and user interface. Observe models and update display when notified.

#### VNScene View
- **File**: `scripts/views/vn_scene.gd`
- **Purpose**: Main scene container, pure view component
- **Key Properties**:
  - `scene_model: Scene` - Reference to scene model
  - `stage_view: StageView` - Background rendering component
  - `director: ActorDirector` - Actor rendering strategy
- **API**: Exposes `scene` property for direct model access
  ```gdscript
  vn_scene.scene.set_plan("close_up")
  var camera = vn_scene.scene.get_current_camera()
  ```

#### StageView
- **File**: `scripts/views/stage_view.gd`
- **Purpose**: Renders backgrounds, observes Scene model
- **Responsibilities**:
  - Creates and manages background Sprite2D
  - Scales backgrounds based on camera ratio and scaling mode
  - Updates when plan changes (observer callback)

#### ActorDirector (Existing, Refactored)
- **File**: `scripts/views/actor_director.gd`
- **Purpose**: Base class for actor rendering strategies
- **Changes**: Now observes Scene model instead of storing current_plan
- **Subclasses**:
  - `TheaterActorDirector` - Multi-layer sprite rendering
  - `MovieActorDirector` - Single sprite rendering

#### Actor View (Existing)
- **File**: `scripts/views/actor.gd`
- **Purpose**: Actor view, observes Character model
- No changes needed

### Controllers (scripts/controllers/)

Manage application flow and coordinate between models and views.

#### VNSceneController
- **File**: `scripts/controllers/vn_scene_controller.gd`
- **Purpose**: FSM for scene execution
- **Key Properties**:
  - `scene_model: Scene` - Reference to scene model
  - `resources: Dictionary` - Actor/resource registry
  - `action_queue: Array` - Queued actions
- **Responsibilities**:
  - Executes action queue
  - Manages scene resources
  - Provides access to scene model

### Domain (scripts/domain/)

Business logic and factories.

#### SceneFactory
- **File**: `scripts/domain/scene_factory.gd`
- **Purpose**: Creates VNScene with proper model hierarchy
- **Process**:
  1. Loads scene YAML
  2. Creates Scene model with Plans, Camera, Stage
  3. Creates Director and StageView
  4. Wires up observers (Director → Scene, StageView → Scene)
  5. Returns configured VNScene

## Data Flow

### Scene Creation
```
YAML Config
    ↓
SceneFactory
    ↓
Scene Model ← Plan Models ← Camera Models
    ↓           ↓
StageModel  StageView (observer)
    ↓
ActorDirector (observer)
    ↓
VNScene (view)
```

### Plan Change
```
User calls: vn_scene.scene.set_plan("close_up")
    ↓
Scene Model updates current_plan_id
    ↓
Scene Model notifies all observers
    ↓           ↓
StageView   ActorDirector
    ↓           ↓
Updates     Reloads textures
background  with new plan
& scaling
```

## Observer Pattern

### How It Works

1. **Models** maintain a list of observer callbacks
2. **Views** subscribe by calling `model.add_observer(callback)`
3. **Models** notify observers when state changes via `_notify_observers()`
4. **Observers** receive state dictionary and update display

### Example: Scene Model

```gdscript
# Scene Model (scripts/models/scene.gd)
func set_plan(plan_id: String) -> void:
    if current_plan_id != plan_id:
        current_plan_id = plan_id
        _notify_observers()  # Notify all observers

func _notify_observers() -> void:
    var scene_state = {
        "current_plan_id": current_plan_id,
        "scene_name": scene_name,
        "scene_type": scene_type
    }
    for observer in _observers:
        if observer.is_valid():
            observer.call(scene_state)
```

### Example: StageView Observer

```gdscript
# StageView (scripts/views/stage_view.gd)
func set_scene_model(p_scene_model: Scene, p_vn_scene: Node) -> void:
    scene_model = p_scene_model
    if scene_model:
        # Subscribe to scene changes
        scene_model.add_observer(_on_scene_changed)

func _on_scene_changed(scene_state: Dictionary) -> void:
    # Plan changed - update background
    var plan = scene_model.get_current_plan()
    if plan:
        var bg_config = plan.get_default_background()
        update_background(bg_config)
```

## API Usage

### Action-Based Plan Changes (Queued)

```gdscript
# Change plan as a queued action (respects scene timeline)
vn_scene.change_plan("close_up")
me_actor.say("Now we're in close-up!")
vn_scene.change_plan("medium_shot")

# Actions are queued and execute in order during scene playback
```

### Direct Model Access (For Queries)

```gdscript
# Read scene state directly (not queued)
var current_plan = vn_scene.scene.current_plan_id
var camera = vn_scene.scene.get_current_camera()
var ratio = camera.ratio

# Access stage configuration
var scaling_mode = vn_scene.scene.stage.scaling_mode

# Get plan details
var plan = vn_scene.scene.get_current_plan()
var backgrounds = plan.backgrounds
```

### Important: Actions vs Direct Access

- **Use `vn_scene.change_plan()`** - Queues action, executes in scene timeline
- **Use `vn_scene.scene.current_plan_id`** - Direct read access (queries only)
- **DON'T use `vn_scene.scene.set_plan()` in stories** - Executes immediately, bypasses queue

### Old API (REMOVED)

```gdscript
# These no longer exist:
vn_scene.set_plan()  # REMOVED
vn_scene.current_plan_id  # REMOVED
stage.set_plan()  # Stage class removed
```

## Key Benefits

1. **Single Source of Truth**: Scene model owns all scene state
2. **No Duplication**: State lives in one place only
3. **Clean Separation**: Models/Views/Controllers clearly defined
4. **Observer Pattern**: Views automatically update when models change
5. **Testability**: Models can be tested independently
6. **Explicit API**: Direct model access, no hidden facades
7. **Type Safety**: Proper class hierarchy with typed references

## Migration Guide

### Before (Old Code)
```gdscript
vn_scene.set_plan("close_up")
```

### After (New Code - Action-Based)
```gdscript
# In story functions (_play_story):
vn_scene.change_plan("close_up")  # Queued action

# For queries (reading state):
var current = vn_scene.scene.current_plan_id
```

### Benefits of Change
- **Respects Scene Timeline**: Plan changes happen in order with other actions
- **No Race Conditions**: Changes occur when intended, not immediately
- **Consistent with Other Actions**: Same pattern as actor.pose(), actor.say(), etc.
- **Explicit Model Access**: Read state directly via `vn_scene.scene`
- **Clean MVC**: Actions (Controller) modify Models, Views observe

## File Organization

```
scripts/
├── models/              # Pure data models
│   ├── character.gd
│   ├── scene.gd
│   ├── plan.gd
│   ├── camera.gd
│   └── stage_model.gd
│
├── views/               # Rendering components
│   ├── vn_scene.gd
│   ├── stage_view.gd
│   ├── actor.gd
│   ├── actor_director.gd
│   ├── theater_actor_director.gd
│   └── movie_actor_director.gd
│
├── controllers/         # Application flow
│   ├── vn_scene_controller.gd
│   └── actions/
│       ├── action_node.gd
│       └── common/
│           ├── show_action.gd
│           ├── hide_action.gd
│           ├── change_plan_action.gd  # NEW - Plan change action
│           └── ...
│
└── domain/              # Business logic
    ├── scene_factory.gd
    ├── act.gd
    ├── costumier.gd
    └── ...
```

## Testing Implications

With proper MVC separation, each layer can be tested independently:

### Model Tests
```gdscript
# Test Scene model
var scene = Scene.new("test_scene")
scene.add_plan(Plan.new("plan1"))
scene.set_plan("plan1")
assert(scene.current_plan_id == "plan1")
```

### View Tests
```gdscript
# Test StageView with mock model
var mock_scene = Scene.new("mock")
var stage_view = StageView.new()
stage_view.set_scene_model(mock_scene, mock_vn_scene)
# Verify observer subscription
```

### Controller Tests
```gdscript
# Test controller independently
var controller = VNSceneController.new()
var scene = Scene.new("test")
controller.set_scene_model(scene)
# Test action queue processing
```

## Conclusion

This architecture provides a solid foundation for a scalable VN engine with clear separation of concerns, proper state management, and maintainable code structure.

