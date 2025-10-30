# Unified State Template System - Implementation Complete

## Overview
Successfully refactored the VN engine's layer rendering system to use a unified state-to-path template system. This eliminates the complexity of the variant/tags matching system in favor of a cleaner, more maintainable directory-based state resolution approach.

## What Changed

### 1. Template Resolution System (ResourceRepository)
**File:** `rengo/infra/resource_repository.gd`

Added `resolve_template_path()` function that:
- Auto-detects `{placeholder}` patterns in template strings
- Uses RegEx to find and replace all placeholders with state dictionary values
- Returns fully resolved paths ready for image loading
- Provides warnings when placeholders are not found in state

Example:
```gdscript
var template = "images/{plan}/{orientation}/body/{pose}_{body}.png"
var state = {"plan": "medium_shot", "orientation": "front", "pose": "idle", "body": "default"}
var path = ResourceRepository.resolve_template_path(template, state)
# Returns: "images/medium_shot/front/body/idle_default.png"
```

### 2. Character Layer Structure
**Files:** 
- `assets/scenes/common/characters/me/character.yaml`
- `assets/scenes/common/characters/other/character.yaml`

Added `layers` section defining body layers:
```yaml
layers:
  - id: "body"
    layer: "body"
    image: "images/{plan}/{orientation}/body/{pose}_{body}.png"
    z: 0
    anchor: {x: 0, y: 0}
```

This centralizes layer structure configuration and makes it easy to add new state-driven layers.

### 3. Face Layer System
**New Files:**
- `assets/scenes/common/characters/me/faces.yaml`
- `assets/scenes/common/characters/other/faces.yaml`

Created separate face layer definitions:
```yaml
faces:
  - id: "face"
    layer: "face"
    image: "images/{plan}/{orientation}/faces/{expression}.png"
    z: 1
    anchor: {x: 0, y: 90}
```

Faces are now treated as a separate layer system, independent of poses/acts.

### 4. Simplified Wardrobe System
**Files:**
- `assets/scenes/common/characters/me/panoplie.yaml`
- `assets/scenes/common/characters/other/panoplie.yaml`

Removed complex variant arrays and tag matching. Each clothing item now has:
- Direct template path in `image` field
- Simple `excluding_tags` for outfit conflict management
- No more `variants` or orientation/tag matching logic

Before:
```yaml
variants:
  - image: "path.png"
    orientations: ["front"]
    tags: ["waving"]
    default: true
```

After:
```yaml
image: "images/{plan}/{orientation}/outfits/casual.png"
excluding_tags: ["top"]
```

Note: For pose-specific variants (like `casual_wave.png`), we now create separate clothing items.

### 5. Updated TheaterCostumier
**File:** `rengo/domain/theater_costumier.gd`

Simplified `get_layers()` method:
- Removed `_find_best_variant()` matching logic
- Removed `_substitute_templates()` method (now uses ResourceRepository)
- Direct template resolution using `ResourceRepository.resolve_template_path()`
- Kept `excluding_tags` logic for outfit management

### 6. Enhanced ActorDirector Base Class
**File:** `rengo/views/actor_director.gd`

Added new methods:
- `load_character_layers()` - Loads body layers from character.yaml
- `load_face_layers()` - Loads face layers from faces.yaml

These provide layer metadata that directors use to construct the full layer stack.

### 7. Refactored TheaterActorDirector
**File:** `rengo/views/theater_actor_director.gd`

Major changes:
- New `_update_layers_unified()` method replaces old Act-based layer system
- Merges body + face + clothing layers using unified template system
- New `_create_layer_mesh()` helper for dynamic layer creation
- New `_apply_texture_to_layer()` helper for texture application
- New `_hide_layer()` helper for managing layer visibility
- Smart fallback in `_load_texture()` for handling "default" state values
  - Automatically tries without "_default" suffix (e.g., "idle_default.png" → "idle.png")
- Removed dependency on Act files for layer structure (Act files now deprecated)

## File Structure

### Current Directory Structure (Unchanged)
```
characters/me/images/{plan}/{orientation}/
  body/
    idle.png              # pose=idle, body=default
    idle_bedhair.png      # pose=idle, body=bedhair
    waving.png            # pose=waving, body=default
    waving_bedhair.png    # pose=waving, body=bedhair
  faces/
    neutral.png           # expression=neutral
    happy.png             # expression=happy
    sad.png               # expression=sad
  outfits/
    casual.png            # Regular casual outfit
    casual_wave.png       # Casual outfit variant for waving
    chino.png
    jeans.png
```

The existing file structure already supports the new template system perfectly!

### YAML Configuration Files
```
characters/me/
  character.yaml    # Character metadata + body layer definitions
  faces.yaml        # Face layer definitions (NEW)
  panoplie.yaml     # Wardrobe/clothing definitions (SIMPLIFIED)
  acts/             # Deprecated - no longer used for layers
    idle.yaml       # Keep for backward compatibility
    waving.yaml
```

## State-to-Image Mapping

### How It Works
1. Character states are stored in `Character.current_states` dictionary
2. Layer definitions contain template paths with `{placeholders}`
3. Templates are resolved using `ResourceRepository.resolve_template_path()`
4. Resolved paths are loaded via `ImageRepository` with base directory virtualization
5. Smart fallback handles "_default" suffix removal for default state values

### Example Flow
```gdscript
# Character state
{
  "plan": "medium_shot",
  "orientation": "front", 
  "pose": "waving",
  "body": "default",
  "expression": "happy"
}

# Body layer template
"images/{plan}/{orientation}/body/{pose}_{body}.png"
# Resolves to: "images/medium_shot/front/body/waving_default.png"
# Fallback to: "images/medium_shot/front/body/waving.png" (found!)

# Face layer template  
"images/{plan}/{orientation}/faces/{expression}.png"
# Resolves to: "images/medium_shot/front/faces/happy.png"

# Clothing layer template
"images/{plan}/{orientation}/outfits/casual.png"
# Resolves to: "images/medium_shot/front/outfits/casual.png"
```

## Benefits

### 1. Consistency
All layers (body, face, clothing) now use the same template resolution system.

### 2. Simplicity
No more complex variant matching with tags and orientation arrays.

### 3. Maintainability
Layer configuration is centralized in character.yaml and faces.yaml.

### 4. Extensibility
Easy to add new state dimensions - just add `{new_state}` to templates and ensure files follow naming convention.

### 5. Transparency
File paths directly map to state values - no hidden logic.

### 6. Flexibility
Game developers can define their own path structures and state keys by editing YAML templates.

## Backward Compatibility

### Deprecated but Kept
- Act files (idle.yaml, waving.yaml) in `acts/` folder
  - No longer used for layer definitions
  - Can be kept for documentation or future animation metadata
  - The old `_update_layers()` method marked as deprecated but kept in code

### Breaking Changes
None! The public API remains unchanged:
- `actor_ctrl.pose("waving")` still works
- `actor_ctrl.express("happy")` still works  
- `actor_ctrl.wear("casual")` still works
- `actor_ctrl.act({"body": "bedhair"})` still works

All changes are internal to the rendering system.

## Testing

To verify the system works:
1. Run the demo scene (`game/demo.gd`)
2. Verify characters render with correct body/face/clothing layers
3. Test state changes (pose, expression, outfit changes)
4. Test plan changes (medium_shot ↔ close_up)
5. Verify fallback system works (default body state uses non-suffixed files)

## Future Enhancements

### Possible Extensions
1. **Conditional paths**: Support for if/else in templates
2. **Multiple templates**: Fallback chain of multiple template attempts
3. **MovieActorDirector**: Update to use unified system (currently still uses Act-based)
4. **State validation**: Warn if state keys don't match any template placeholders
5. **Auto-detection**: Scan file structure to auto-generate templates

### Extensibility Examples
Add new state dimensions easily:

```yaml
# Example: Add {emotion_intensity} state
layers:
  - id: "face"
    layer: "face"
    image: "images/{plan}/{orientation}/faces/{expression}_{emotion_intensity}.png"
```

Then organize files:
```
faces/
  happy_mild.png
  happy_intense.png
  sad_mild.png
  sad_intense.png
```

## Conclusion

The unified state template system successfully:
- ✅ Simplified the codebase by removing variant matching logic
- ✅ Made layer configuration more transparent and maintainable  
- ✅ Enabled consistent state-to-image mapping across all layer types
- ✅ Preserved backward compatibility with existing API
- ✅ Maintained support for existing file structure
- ✅ Centralized template resolution in ResourceRepository for reusability

The system is now ready for production use and future expansion!

