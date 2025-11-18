# Visual Character Composition System - Pure Visual Workflow

## Overview

The Character Composer is now a completely standalone visual system with **NO YAML dependencies**. All characters are built from scratch in the Godot editor using the visual composition tools.

## What Changed

### Removed
- ❌ YAML import functionality
- ❌ YAML conversion tools
- ❌ Import button from UI
- ❌ All YAML file dependencies
- ❌ Migration guides

### Kept
- ✅ Visual layer editor
- ✅ Property inspector
- ✅ Tag management
- ✅ Validation system
- ✅ Batch resource creation
- ✅ YAML fallback loading (for backwards compatibility only)

## Pure Visual Workflow

### 1. Create Blank Resources
```
Scene with Actor nodes → Batch Convert → Blank .tres files created
```

No YAML files needed. Resources are created with:
- character_name from Actor
- base_size from Actor or default (80, 170)
- Default states
- **Zero layers** (build manually)

### 2. Build Characters Visually
```
Open .tres → Add layers → Configure properties → Validate → Done
```

Every aspect configured in the editor:
- Layer hierarchy
- Template paths
- Positions and z-indices
- Tags and exclusions
- No external files required

## System Architecture

### Resources
```
CharacterCompositionResource (@tool)
├── character_name: String
├── display_name: String  
├── dialog_color: Color
├── inner_dialog_color: Color
├── base_size: Vector2
├── default_states: Dictionary
└── layers: Array[CompositionLayer]
    └── CompositionLayer (@tool)
        ├── id: String
        ├── layer_name: String
        ├── template_path: String
        ├── position: Vector2
        ├── z_index: int
        ├── parent_layer_id: String
        ├── tags: Array[String]
        ├── excluding_tags: Array[String]
        └── layer_type: LayerType enum
```

### Editor Plugin
```
CharacterCompositionPlugin
└── CompositionEditorPanel
    ├── Layer Tree (add/remove/validate)
    ├── Preview (placeholder)
    └── Properties Panel (edit selected layer)
```

### Batch Tool
```
batch_convert_actors_tool.gd
├── Scans scene for Actor nodes
├── Creates blank CharacterCompositionResource
├── No YAML file checking
└── Skips existing .tres files
```

### Runtime
```
ActorDirector.load_character()
├── Check for .tres file
├── Load from CharacterCompositionResource
├── Fallback to YAML (legacy support)
└── Create displayable layers
```

## File Structure

```
addons/character_composer/
├── plugin.cfg
├── icon.svg
├── character_composition_plugin.gd
├── composition_editor_panel.gd
├── composition_editor_panel.tscn
├── tag_editor_panel.gd
├── tag_editor_panel.tscn
├── batch_convert_actors_tool.gd
├── README.md
└── VISUAL_WORKFLOW_GUIDE.md

rengo/resources/
├── character_composition_resource.gd (@tool)
└── composition_layer.gd (@tool)

rengo/controllers/
├── actor_director.gd (loads .tres, falls back to YAML)
└── theater_actor_director.gd (wardrobe from .tres)

assets/scenes/common/characters/{character_name}/
├── {character_name}_composition.tres (NEW - visual system)
├── character.yaml (LEGACY - fallback only)
├── faces.yaml (LEGACY)
├── panoplie.yaml (LEGACY)
└── images/ (actual image assets)
```

## Complete Workflow Example

### Step 1: Scene Setup
```gdscript
# demo.tscn
StageView
├── Actor
│   actor_name: "emma"
│   base_size: Vector2(80, 170)
└── Actor2
    actor_name: "noah"
    base_size: Vector2(90, 185)
```

### Step 2: Batch Create
1. Open demo.tscn
2. Select any .tres file to open Character Composer
3. Click "Batch Convert"

Output:
```
=== Batch Create Blank Resources ===
Found 2 Actor nodes
✓ Created: 2
  - emma_composition.tres
  - noah_composition.tres
```

### Step 3: Build Emma
Open `emma_composition.tres`:

**Add Body:**
- ID: `body`
- Template: `images/{plan}/{orientation}/body/{pose}_{body}.png`
- Position: `(0, 0)`
- Z-Index: `0`
- Parent: *(empty)*
- Type: BODY

**Add Face:**
- ID: `face`
- Template: `images/{plan}/{orientation}/faces/{expression}.png`
- Position: `(100, 500)`
- Z-Index: `1`
- Parent: `body`
- Type: FACE

**Add Casual Top:**
- ID: `casual_top`
- Template: `images/{plan}/{orientation}/outfits/casual_{pose}.png`
- Position: `(0, 0)`
- Z-Index: `2`
- Parent: `body`
- Tags: `["casual", "top"]`
- Excluding: `["top"]`
- Type: CLOTHING

**Validate → Save → Done**

### Step 4: Runtime
```gdscript
# Automatically loads from emma_composition.tres
var character = Character.new("emma")
var actor_controller = ActorController.new(character)

# Works immediately - no setup needed
character.express("happy")
character.pose("walking")
character.wear(["casual_top"])
```

## Key Features

### ✅ Zero External Dependencies
- No YAML files required
- Everything in .tres resource
- Self-contained system

### ✅ Visual First
- Build in editor
- See hierarchy visually
- Point-and-click configuration

### ✅ Type Safe
- Godot enforces types
- Validation at edit time
- No syntax errors

### ✅ Fast Iteration
- Change and test immediately
- Real-time validation
- Auto-save on validate

### ✅ Version Control Friendly
- Binary .tres diffs better than YAML
- No merge conflicts in text
- Smaller file sizes

## Benefits Over YAML System

| Aspect | YAML System | Visual System |
|--------|-------------|---------------|
| **Learning Curve** | Learn YAML syntax | Use Godot Inspector |
| **Error Prevention** | Manual syntax checking | Type enforcement |
| **Iteration Speed** | Edit → Save → Test | Edit → Validate → Test |
| **Visualization** | Imagine hierarchy | See tree structure |
| **Migration** | Complex scripts needed | Not needed - start fresh |
| **Documentation** | External docs required | Self-documenting in UI |
| **Validation** | Runtime errors | Edit-time validation |

## Migration Path (Optional)

If you have existing YAML characters:

### Option A: Keep YAML (Recommended)
- YAML files still work as fallback
- No migration needed
- Build new characters visually
- Old characters keep working

### Option B: Build Fresh
- Create blank resources
- Rebuild characters visually
- Test thoroughly
- Remove YAML when confident

**Note**: There's no automated YAML→Resource conversion. The old conversion tools were removed. If you want to migrate, rebuild manually in the visual editor.

## Technical Details

### Resource Loading Priority
1. Check for `{character_name}_composition.tres`
2. If found, load from resource
3. If not found, fall back to YAML (legacy)
4. If neither, error

### Layer Rendering Order
1. Sort layers by z-index
2. Render parent before children
3. Apply parent transformations
4. Composite final image

### Template Resolution
```gdscript
Template: "images/{plan}/{orientation}/body/{pose}_{body}.png"
State: { plan: "full", orientation: "front", pose: "idle", body: "default" }
Result: "images/full/front/body/idle_default.png"
```

### Wardrobe System
```gdscript
Current: ["top_A"]
Wear: "top_B" (excluding_tags: ["top"])
Result: ["top_B"]  # top_A removed due to tag conflict
```

## Best Practices

1. **Start Simple**: Body + face first, add clothing later
2. **Consistent Naming**: Use clear, descriptive IDs
3. **Z-Index Gaps**: Use 0, 10, 20 for easy insertion
4. **Validate Often**: Catch errors early
5. **Test States**: Ensure all combinations have images
6. **Document Templates**: Note custom placeholders
7. **Use Hierarchy**: Parent-child for proper positioning
8. **Tag Consistently**: Same tags across all characters

## Common Patterns

### Basic Character
```
body (root, z=0)
├── face (z=1)
└── clothing (z=2)
```

### Complex Character
```
body (root, z=0)
├── pants (z=1)
├── shoes (z=2)
├── face (z=10)
├── top (z=20)
└── accessories (z=30)
```

### Multi-Body Character
```
body_normal (root, z=0)
├── face_normal (z=1)
└── outfit_normal (z=2)

body_athletic (root, z=0)
├── face_athletic (z=1)
└── outfit_athletic (z=2)
```

## Troubleshooting

### "Actor not loading"
- Check .tres file exists
- Verify character_name matches
- Look for console errors
- Try YAML fallback (if you have old files)

### "Batch Convert does nothing"
- Ensure Actor has actor_name set
- Check console for errors
- Verify resource doesn't already exist

### "Validation fails"
- Check duplicate IDs
- Verify parent_layer_id references exist
- Look for circular dependencies

### "Template not resolving"
- Check placeholder names match state keys
- Verify image exists at resolved path
- Test with static path first

## Future Enhancements

- 2D preview with visual positioning
- Drag-drop layer reordering
- Asset browser for template paths
- Animation preview
- Duplicate layer functionality
- Export to shareable format

## Summary

The Character Composer is now a pure visual system:
- **No YAML dependencies** for new characters
- **Build everything in the editor** visually
- **Type-safe and validated** at edit time
- **Fast iteration** with immediate feedback
- **Backwards compatible** with YAML fallback
- **Production ready** for new projects

Start building characters visually today!

