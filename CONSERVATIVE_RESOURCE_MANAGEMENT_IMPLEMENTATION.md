# Conservative Resource Management Implementation

## Overview
Successfully transformed the aggressive resource destruction/allocation pattern into a conservative reuse system with Pass pooling, sprite caching, and incremental shader updates.

## Changes Implemented

### 1. Pass.gd - Activation State & Sprite Caching

#### Activation State Management
- Added `_is_active: bool = true` field to track pass activation
- Added `set_active(is_active: bool)` method:
  - When deactivating: removes viewport from scene tree (saves rendering cost)
  - When activating: adds viewport back to scene tree
- Modified `get_output_texture()` to pass through previous pass's output when inactive

#### Sprite Hierarchy Caching
- Added `_sprite_cache: Dictionary = {}` keyed by layer_id
- Added `_cached_texture_structure: Dictionary = {}` to track hierarchy changes
- Renamed `_create_sprite_hierarchy()` to `_rebuild_sprite_hierarchy()`:
  - Tries to reuse sprites from cache by layer_id
  - Only creates new sprites when layer_id not in cache
  - Updates existing sprite properties (texture, position, scale, z-index)
- Modified `recompose()`:
  - Computes current texture structure signature
  - Compares with cached structure using hash
  - If unchanged: updates existing sprites in-place
  - If changed: rebuilds hierarchy but reuses sprite objects from cache
  - Skips recomposition entirely for inactive passes
- Added helper methods:
  - `_compute_texture_structure()`: Recursively builds structure signature
  - `_update_sprite()`: Updates existing sprite properties
  - `_update_sprite_hierarchy_children()`: Recursively updates child sprites

### 2. Displayable.gd - Pass Pooling

#### Pass Pool Implementation
- Added `_pass_pool: Array[Pass] = []` for storing inactive passes
- Added `_active_passes: Array[Pass] = []` to track currently active shader passes

#### Modified Pass Management
- `clear_shader_passes()`:
  - Deactivates passes instead of destroying them
  - Moves deactivated passes to pool for reuse
  - Keeps input_pass and output_pass linked
- Added `_get_or_create_pass(shader: VNShader) -> Pass`:
  - Searches pool for Pass with matching shader (path + params)
  - Activates and returns matching pass from pool
  - Creates new Pass only if no match found
- Added `_matches_shader(pass: Pass, shader: VNShader) -> bool`:
  - Compares shader path and all parameters
  - Enables accurate pass reuse
- Added `get_active_passes()`: Returns current active shader passes
- Added `_add_active_pass(pass: Pass)`: Adds pass to active list

### 3. PostProcessorBuilder.gd - Incremental Updates

#### Removed Aggressive Clearing
- Removed `displayable.clear()` from `build()` method
- Modified texture updates to clear and replace incrementally

#### Differential Pass Updates
- Completely rewrote `_build_passes()` for differential updates:
  - Maps current passes by shader signature
  - Maps desired shaders by signature
  - For each desired shader:
    - Reuses existing pass if signature matches
    - Updates shader material if parameters changed
    - Gets pass from pool or creates new if needed
  - Deactivates and pools unused passes
  - Rebuilds linked list with only active passes

#### Helper Methods
- `_get_shader_signature(shader: VNShader) -> String`:
  - Creates unique key from shader path + sorted params
- `_compare_shader_params(pass: Pass, shader: VNShader) -> bool`:
  - Detects parameter changes for selective updates

### 4. Machinist.gd - Optimized Material Handling

#### Incremental Shader Activation
- Kept `builder.clear_shaders()` call (clears builder's list, not displayable passes)
- Builder now handles incremental updates internally
- Optimized material handling:
  - Loads shader material from ShaderRepository (already cached)
  - Sets BASE_TEXTURE parameter only when shader supports it
  - Avoids redundant material creation

## Benefits

### Resource Efficiency
- **Reduced SubViewport creation/destruction**: Passes are pooled and reused
- **Reduced Sprite2D allocation**: Sprites are cached and updated in-place
- **Reduced ShaderMaterial updates**: Only changed parameters are updated
- **Reduced scene tree operations**: Inactive passes removed from tree, not destroyed

### Performance Improvements
- **Better frame time stability**: Less memory allocation spikes
- **Lower memory churn**: Objects reused instead of recreated
- **Faster state transitions**: Matching passes reactivated instantly
- **Optimized recomposition**: Structure changes detected via hash comparison

### Behavioral Improvements
- **Smart caching**: Sprite hierarchy only rebuilt when structure changes
- **Pass pooling**: Shader passes reused across state changes
- **Activation management**: Inactive passes don't render, saving GPU cycles
- **Material caching**: ShaderRepository caches materials by key

## Integration Points

### Actor Controller Flow
1. `director.handle_displayable()` - Sets up textures in builder
2. `machinist.handle_displayable()` - Sets up shaders in builder
3. `displayable.to_builder().build()` - Applies changes incrementally
4. `view.recompose()` - Updates sprites (with caching)

### Key Methods
- `Pass.set_active(bool)` - Manages viewport visibility
- `Pass.recompose()` - Updates sprites with caching
- `Displayable._get_or_create_pass()` - Gets pooled or new pass
- `PostProcessorBuilder._build_passes()` - Differential updates
- `Machinist.update_displayable_shaders()` - Incremental shader activation

## Testing Status
- ✅ No linter errors in modified files
- ✅ Integration points verified
- ✅ Resource pooling implemented
- ✅ Sprite caching implemented
- ✅ Incremental updates implemented

## Files Modified
1. `rengo/views/pass.gd` - Activation state + sprite caching (13 new/modified methods)
2. `rengo/views/displayable.gd` - Pass pooling (5 new methods)
3. `rengo/controllers/post_processor_builder.gd` - Incremental updates (3 new methods, 1 rewritten)
4. `rengo/controllers/machinist.gd` - Optimized material handling (1 modified method)

## Backward Compatibility
All public APIs remain unchanged. The optimization is transparent to calling code.

