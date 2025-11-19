# Layer ID System Implementation Summary

## Overview
Implemented a `layer_id` property system to support multiple clothing variants sharing the same logical layer. This allows items like "chinos" and "jeans" to be different variants of the same "cloth_bottom" layer.

## Changes Made

### 1. Core Resources and Views

#### `rengo/resources/composition_layer.gd`
- Added `@export var layer_id: String = ""` property
- Updated `to_layer_definition()` to include `layer_id` (defaults to `id` if empty)
- Updated `from_layer_definition()` to parse `layer_id` from dictionary

#### `rengo/views/displayable_layer.gd`
- Added `var layer_id: String = ""` property
- Updated `_init()` to extract `layer_id` from layer definition
- Updated `get_output_texture()` to set `layer_id` on VNTexture

#### `rengo/infra/vn_texture.gd`
- Added `var _layer_id: String = ""` property
- Added `get_layer_id()` and `set_layer_id()` methods

### 2. Theater System

#### `rengo/controllers/theater_costumier.gd`
- Modified `select()` method to enforce one item per `layer_id`
- Before adding new clothing, removes any existing items with the same `layer_id`
- This ensures only one variant (e.g., chinos OR jeans) is active per layer

#### `rengo/controllers/theater_actor_director.gd`
- Added `clothing_to_layer_map` dictionary to map clothing_id → layer_id
- Added `composition_layers_by_layer_id` dictionary to group variants by layer_id
- Overrode `_load_wardrobe_from_resource()` to build these mappings
- Overrode `_create_displayable_layers()` to create ONE DisplayableLayer per unique layer_id
- Updated `_update_layers_unified()` to select active variant based on panoplie
- Added `_get_active_variant_for_layer()` to determine which variant to display
- Updated `_build_texture_hierarchy()` and `_apply_texture_to_displayable_layer()` to set layer_id on VNTextures

#### `rengo/resources/character_composition_resource.gd`
- Added `get_unique_layer_ids()` to return array of unique layer_id values
- Added `get_layers_by_layer_id()` to return all variants for a given layer_id

### 3. Editor Plugin

#### `addons/character_composer/composition_editor_panel.gd`
- Added "Layer ID" property editor in properties panel
- Updated `_on_property_changed()` to handle layer_id changes
- Updated layer tree display to show layer_id alongside id (e.g., "chinos [cloth_bottom] (Clothing)")

### 4. Test Resource

#### `assets/scenes/common/characters/me/me_composition.tres`
- Set `layer_id = "cloth_top"` for "casual" layer
- Set `layer_id = "cloth_bottom"` for both "chino" and "jeans" layers

## How It Works

1. **Layer Creation**: When a character is loaded, TheaterActorDirector creates DisplayableLayers based on unique `layer_id` values, not individual CompositionLayers. For example, only ONE "cloth_bottom" layer is created, not separate layers for chinos and jeans.

2. **Variant Selection**: When rendering, `_get_active_variant_for_layer()` checks the character's panoplie to determine which clothing item (variant) is active for each layer_id.

3. **Automatic Exclusion**: When `wear()` is called with a new clothing item, TheaterCostumier automatically removes any other items with the same layer_id before adding the new one.

## Testing

To verify the implementation:

1. **Load Character**: Load a character with the updated composition resource
   - Expected: Should create 4 DisplayableLayers: body, face, cloth_top, cloth_bottom (not 6)

2. **Wear Chinos**: Call `character.wear(["casual", "chino"])`
   - Expected: Character displays with casual top and chino pants

3. **Switch to Jeans**: Call `character.wear(["casual", "jeans"])`
   - Expected: Chinos are automatically removed, jeans are displayed
   - Casual top remains unchanged

4. **Editor Preview**: Open me_composition.tres in the composition editor
   - Expected: Layer tree shows "chino [cloth_bottom] (Clothing)" and "jeans [cloth_bottom] (Clothing)"

## Benefits

- **Simplified Management**: Multiple variants of the same layer type (e.g., different pants) are now properly grouped
- **Automatic Exclusion**: No need to manage complex tag-based exclusion rules for variants
- **Cleaner Layer Structure**: Fewer DisplayableLayer nodes in the scene tree
- **Better Performance**: Reduced node count and simpler update logic
- **Future-Proof**: Easy to add more variants without changing the actor structure

