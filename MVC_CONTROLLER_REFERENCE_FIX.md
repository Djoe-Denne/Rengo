# MVC Controller Reference Fix

## Issue

In the original implementation, `Actor` view was searching for its controller by traversing the scene tree via `_get_controller()` method. This violated proper MVC architecture where views should have direct references to their controllers.

## Changes Made

### 1. Actor View (`rengo/views/actor.gd`)

**Added:**
- `controller` property to store direct reference to ActorController

**Modified:**
- Removed `_get_controller()` method (no longer needed)
- Updated `_on_mouse_entered()` to use direct `controller` reference
- Updated `_on_mouse_exited()` to use direct `controller` reference

**Before:**
```gdscript
func _on_mouse_entered() -> void:
    var controller = _get_controller()  # Search through scene
    if controller:
        InteractionHandler.on_hover_enter(controller)

func _get_controller():
    # Complex scene traversal to find controller
    if not vn_scene or not vn_scene.controller:
        return null
    # ... more searching logic
```

**After:**
```gdscript
## Reference to the ActorController (MVC: view knows its controller)
var controller = null  # ActorController

func _on_mouse_entered() -> void:
    if controller:  # Direct reference
        InteractionHandler.on_hover_enter(controller)
```

### 2. VNScene (`rengo/views/vn_scene.gd`)

**Modified:**
- Updated `cast()` method to set the controller reference in Actor view after creating ActorController

**Changes:**
```gdscript
# Create ActorController and link it to the view (MVC)
var actor_ctrl = ActorController.new(name, character, actor)
actor_ctrl.vn_scene = self  # For action registration
actor.controller = actor_ctrl  # View knows its controller ← NEW
```

### 3. StageView (`rengo/views/stage_view.gd`)

**Added:**
- `controller` property for future extensibility

**Note:** StageView currently doesn't have a dedicated controller since it only observes the Scene model and has no user interactions. The property is added for future extensibility if background interactions are needed.

```gdscript
## Reference to a controller (MVC: view knows its controller)
## Currently StageView doesn't have a dedicated controller, but this is here
## for future extensibility if background interactions are needed
var controller = null
```

## Benefits

### 1. **Proper MVC Architecture**
Views now correctly reference their controllers directly, following the standard MVC pattern.

### 2. **Better Performance**
No more scene tree traversal to find controllers - direct O(1) access.

### 3. **Cleaner Code**
Removed complex `_get_controller()` logic with multiple fallbacks and edge cases.

### 4. **Type Safety**
Direct references make the relationship explicit and easier to understand.

### 5. **Easier Debugging**
Clear ownership relationship - if controller is null, something went wrong during initialization.

## Architecture

The relationship between components is now:

```
ActorController (Controller)
    ├─> Character (Model) - owns and updates
    ├─> Actor (View) - owns and updates
    └─> vn_scene - for action registration

Actor (View)
    ├─> Character (Model) - observes via observer pattern
    ├─> ActorController (Controller) - direct reference
    ├─> director - for rendering instructions
    └─> vn_scene - for scene integration

Character (Model)
    └─> observers[] - notifies on changes
```

This follows the proper MVC pattern where:
- **Model** (Character) notifies observers of changes
- **View** (Actor) observes model and references its controller
- **Controller** (ActorController) coordinates between model and view

## Testing

The interaction system continues to work correctly:
1. When mouse enters actor → Actor calls `controller` reference → InteractionHandler notified
2. When mouse exits actor → Same flow
3. No scene traversal required
4. Direct, fast access to controller

## Future Improvements

### StageView Controller

If background interactions are needed in the future:

1. Create `StageController` or `BackgroundController`
2. Set `stage_view.controller` reference during initialization
3. Add interaction support to StageView similar to Actor

Example:
```gdscript
# In scene_factory.gd or vn_scene.gd
var stage_ctrl = StageController.new(stage_model, stage_view)
stage_view.controller = stage_ctrl
```

### Other ResourceNodes

Any new ResourceNode subclass that needs interactions should:
1. Add `controller` property
2. Set it during initialization
3. Use it for interaction callbacks

## Conclusion

The MVC architecture is now properly implemented with views holding direct references to their controllers, eliminating the need for scene traversal and improving code clarity, performance, and maintainability.

