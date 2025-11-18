# Character Composer Plugin

Visual character composition editor for Godot. Create layered 2D characters entirely through the visual editor with no external file dependencies.

## Features

- **Pure Visual Workflow**: Build characters from scratch in the editor
- **Layer Hierarchy**: Define parent-child relationships for layered sprites
- **Property Inspector**: Edit template paths, positions, z-index, and more
- **Tag Management**: Configure wardrobe system with tags and exclusions
- **Validation**: Built-in hierarchy validation
- **Batch Creation**: Scan scenes for Actor nodes and create blank resources automatically

## Installation

1. Ensure the plugin is in `addons/character_composer/`
2. Enable it in **Project Settings > Plugins**

## Quick Start

### Creating Characters from Scratch

#### Step 1: Create Blank Resources
1. Open your game scene containing Actor nodes
2. Create or select any CharacterCompositionResource (to open the panel)
3. Click **"Batch Convert"** in the Character Composer panel
4. Blank resources are created for each Actor node in `res://assets/scenes/common/characters/{actor_name}/`

#### Step 2: Add Layers Visually
1. Select the `.tres` file in the FileSystem
2. The Character Composer panel appears at the bottom
3. Click **"Add"** to create a new layer
4. Configure the layer in the properties panel:
   - **ID**: Unique identifier (e.g., "body", "face", "casual_top")
   - **Layer Name**: Display name
   - **Template Path**: Path with placeholders (e.g., `images/{plan}/{orientation}/body/{pose}_{body}.png`)
   - **Position X/Y**: Offset position (for child layers relative to parent)
   - **Z-Index**: Rendering order (higher = on top)
   - **Parent Layer ID**: Leave empty for root, or set to parent layer's ID
   - **Layer Type**: BODY, FACE, or CLOTHING

#### Step 3: Build Layer Hierarchy
1. Add root layer (usually body): Leave **Parent Layer ID** empty
2. Add child layers (face, clothing): Set **Parent Layer ID** to "body"
3. Layers with parents are positioned relative to their parent

#### Step 4: Configure Wardrobe (Optional)
For clothing layers:
1. Set **Layer Type** to CLOTHING
2. Add **Tags**: Categories this item belongs to (e.g., "casual", "top")
3. Add **Excluding Tags**: Categories that conflict (e.g., "top" means no other tops)

#### Step 5: Validate and Test
1. Click **"Validate"** to check for errors
2. Resource is automatically saved
3. Test your character in-game

## Editor Interface

### Character Composer Panel (Bottom)

The panel appears when you select a CharacterCompositionResource file.

#### Left Panel: Layer Tree
- Shows all layers in hierarchical structure
- Select a layer to edit its properties
- **Add**: Create a new layer
- **Remove**: Delete selected layer
- **Validate**: Check hierarchy and save
- **Batch Convert**: Scan scene for Actor nodes and create blank resources

#### Center Panel: Preview
- Placeholder for future visual preview

#### Right Panel: Properties
- **Character Info**: character_name, display_name, colors, base_size, default_states
- **Layer Properties** (when layer selected):
  - ID, Layer Name, Template Path
  - Position X/Y, Z-Index
  - Parent Layer ID
  - Tags, Excluding Tags
  - Layer Type

## Template Path System

Template paths use placeholder syntax resolved at runtime based on character state:

```
images/{plan}/{orientation}/body/{pose}_{body}.png
```

### Available Placeholders
- `{plan}`: Camera plan ("full", "medium", "closeup")
- `{orientation}`: Facing direction ("front", "left", "right")
- `{pose}`: Character pose ("idle", "walking", "sitting")
- `{expression}`: Facial expression ("neutral", "happy", "sad")
- `{body}`: Body variant ("default", "athletic")
- `{outfit}`: Custom state variable

### Example Paths

**Body Layer (root):**
```
images/{plan}/{orientation}/body/{pose}_{body}.png
→ images/full/front/body/idle_default.png
```

**Face Layer (child of body):**
```
images/{plan}/{orientation}/faces/{expression}.png
→ images/full/front/faces/happy.png
```

**Clothing Layer (child of body):**
```
images/{plan}/{orientation}/outfits/casual_{pose}.png
→ images/full/front/outfits/casual_idle.png
```

## Layer Types

### BODY
- Base character sprite
- Usually the root layer
- Defines character size

### FACE
- Facial expressions
- Typically child of body layer
- Changes based on expression state

### CLOTHING
- Wardrobe items
- Child of body layer
- Uses tags for conflict management

## Wardrobe System

Clothing layers use tags to manage what can be worn together:

```
Layer: "casual_top"
  - Tags: ["casual", "top"]
  - Excluding Tags: ["top"]
```

This means:
- Item is tagged as "casual" and "top"
- When worn, removes any other items tagged "top"
- Prevents wearing multiple tops at once

### Common Tag Patterns

**Tops:**
- Tags: `["casual", "top"]`
- Excluding: `["top"]`

**Bottoms:**
- Tags: `["pants", "bottom"]`
- Excluding: `["bottom"]`

**Accessories:**
- Tags: `["accessory", "head"]`
- Excluding: `[]` (can wear with anything)

## Complete Workflow Example

### 1. Scene Setup
```
StageView
  ├── Actor (actor_name: "alice")
  └── Actor2 (actor_name: "bob")
```

### 2. Batch Create Resources
- Click "Batch Convert"
- Creates: `alice_composition.tres` and `bob_composition.tres`

### 3. Build Alice Character
Select `alice_composition.tres`:

**Add Body Layer:**
- ID: `body`
- Layer Name: `body`
- Template Path: `images/{plan}/{orientation}/body/{pose}_{body}.png`
- Position: `(0, 0)`
- Z-Index: `0`
- Parent Layer ID: *(empty - root layer)*
- Layer Type: `BODY`

**Add Face Layer:**
- ID: `face`
- Layer Name: `face`
- Template Path: `images/{plan}/{orientation}/faces/{expression}.png`
- Position: `(100, 500)` *(offset from body)*
- Z-Index: `1`
- Parent Layer ID: `body`
- Layer Type: `FACE`

**Add Casual Top:**
- ID: `casual_top`
- Layer Name: `casual_top`
- Template Path: `images/{plan}/{orientation}/outfits/casual_{pose}.png`
- Position: `(0, 0)`
- Z-Index: `2`
- Parent Layer ID: `body`
- Tags: `["casual", "top"]`
- Excluding Tags: `["top"]`
- Layer Type: `CLOTHING`

**Add Jeans:**
- ID: `jeans`
- Layer Name: `jeans`
- Template Path: `images/{plan}/{orientation}/outfits/jeans.png`
- Position: `(0, 0)`
- Z-Index: `1`
- Parent Layer ID: `body`
- Tags: `["casual", "pants", "bottom"]`
- Excluding Tags: `["bottom"]`
- Layer Type: `CLOTHING`

### 4. Validate
Click "Validate" - resource is checked and saved

### 5. Runtime Usage
```gdscript
# Character automatically loads from alice_composition.tres
var character = Character.new("alice")
var actor_controller = ActorController.new(character)
```

## Runtime Behavior

At runtime:
1. Checks for `{character_name}_composition.tres`
2. Loads character data from resource
3. Creates displayable layers based on composition
4. Resolves template paths using character state
5. Renders layers in z-index order with hierarchy

## Best Practices

1. **Consistent Naming**: Use descriptive IDs ("body", "face_happy", "casual_top")
2. **Hierarchy Depth**: Keep shallow (2-3 levels max)
3. **Z-Index Spacing**: Use increments of 10 for easy insertion
4. **Template Testing**: Test paths resolve for all state combinations
5. **Validation**: Run validation frequently
6. **Tags**: Use consistent tag names across characters
7. **Root Layers**: Usually just body; face and clothing are children

## Troubleshooting

### Character doesn't load
- Verify .tres file exists in correct location
- Check character_name matches directory name
- Look for console errors

### Layers not showing
- Check template paths resolve to existing images
- Verify z-index values
- Check parent_layer_id is valid
- Run validation

### Wardrobe conflicts
- Review tags and excluding_tags
- Ensure tag names are consistent
- Check that excluding_tags match actual tags

### Validation errors
- Check for duplicate layer IDs
- Verify parent layers exist
- Fix any circular references

## Migration from YAML (Legacy)

If you have existing YAML-based characters, the YAML loading system still works as a fallback. The game will try to load `.tres` first, then fall back to YAML if not found.

To fully migrate:
1. Build your characters visually (steps above)
2. Test thoroughly
3. Remove old YAML files once confident

## Architecture

### Resources
- **CharacterCompositionResource**: Main character data
- **CompositionLayer**: Individual layer definition

### Runtime
- **ActorDirector**: Loads resources at runtime
- **DisplayableNode**: Renders layered characters
- **TheaterActorDirector**: Handles layer updates

### Editor
- **CharacterCompositionPlugin**: Editor integration
- **CompositionEditorPanel**: Main editing UI
- **BatchConvertActorsTool**: Bulk resource creation

## Tips

- Start with just body and face, add clothing later
- Use consistent state variable names across characters
- Test template paths with different states
- Group similar items with shared tags
- Keep position offsets relative to parent
- Document your custom template variables
- Use validation before committing changes
