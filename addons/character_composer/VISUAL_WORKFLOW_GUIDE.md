# Visual Character Composition Workflow

Complete guide to building characters visually in the Character Composer.

## Core Concept

Characters are built layer-by-layer in the visual editor. Each layer:
- Has a unique ID
- References image assets via template paths
- Can be positioned relative to a parent
- Has a z-index for rendering order

## Step-by-Step Tutorial

### Example: Creating a Character Named "Emma"

#### 1. Setup Actor Node

In your scene:
```
StageView
  └── Actor
        actor_name: "emma"
        base_size: (80, 170)
```

#### 2. Create Blank Resource

1. Open the scene in Godot
2. Select any `.tres` file (or create a dummy one) to open Character Composer
3. Click **"Batch Convert"**
4. Console output:
```
=== Batch Create Blank Resources ===
Found 1 Actor node(s):
  - Actor (actor_name: 'emma')

Processing actor: emma
  → Created blank resource (no layers)
  → Saving resource to: res://assets/scenes/common/characters/emma/emma_composition.tres
  ✓ Successfully created
```

#### 3. Open the Resource

Navigate to: `res://assets/scenes/common/characters/emma/emma_composition.tres`

Select it - the Character Composer panel appears at the bottom.

#### 4. Configure Character Metadata

In the Inspector (top-right):
- **character_name**: `emma`
- **display_name**: `Emma`
- **dialog_color**: Choose a color
- **inner_dialog_color**: Same color with alpha
- **base_size**: `(80, 170)` (already set from Actor)
- **default_states**: 
  ```
  {
    "orientation": "front",
    "pose": "idle",
    "expression": "neutral",
    "outfit": "default",
    "body": "default"
  }
  ```

#### 5. Add Body Layer (Root)

Click **"Add"** in the toolbar:

**In Properties Panel:**
- **ID**: `body`
- **Layer Name**: `body`
- **Template Path**: `images/{plan}/{orientation}/body/{pose}_{body}.png`
- **Position X**: `0`
- **Position Y**: `0`
- **Z-Index**: `0`
- **Parent Layer ID**: *(leave empty)*
- **Layer Type**: Select `BODY`

**What this means:**
- When orientation="front", pose="idle", body="default", plan="full"
- Loads: `images/full/front/body/idle_default.png`

#### 6. Add Face Layer (Child of Body)

Click **"Add"** again:

**In Properties Panel:**
- **ID**: `face`
- **Layer Name**: `face`
- **Template Path**: `images/{plan}/{orientation}/faces/{expression}.png`
- **Position X**: `100` *(100 pixels right of body anchor)*
- **Position Y**: `500` *(500 pixels up from body anchor)*
- **Z-Index**: `1` *(renders on top of body)*
- **Parent Layer ID**: `body`
- **Layer Type**: Select `FACE`

**What this means:**
- Positioned relative to body layer
- When expression="happy"
- Loads: `images/full/front/faces/happy.png`

#### 7. Add Clothing Layer (Casual Top)

Click **"Add"**:

**In Properties Panel:**
- **ID**: `casual_top`
- **Layer Name**: `casual_top`
- **Template Path**: `images/{plan}/{orientation}/outfits/casual_{pose}.png`
- **Position X**: `0`
- **Position Y**: `0`
- **Z-Index**: `2` *(on top of face)*
- **Parent Layer ID**: `body`
- **Tags**: Click to edit, add: `casual`, `top`
- **Excluding Tags**: Add: `top`
- **Layer Type**: Select `CLOTHING`

**What this means:**
- Part of wardrobe system
- Can't wear with other items tagged "top"
- Changes based on pose

#### 8. Add More Clothing (Pants)

Click **"Add"**:

**In Properties Panel:**
- **ID**: `jeans`
- **Layer Name**: `jeans`
- **Template Path**: `images/{plan}/{orientation}/outfits/jeans.png`
- **Position X**: `0`
- **Position Y**: `0`
- **Z-Index**: `1` *(between body and top)*
- **Parent Layer ID**: `body`
- **Tags**: `casual`, `pants`, `bottom`
- **Excluding Tags**: `bottom`
- **Layer Type**: Select `CLOTHING`

#### 9. Review Layer Tree

Your layer tree should now show:
```
body (Body)
  ├── face (Face)
  ├── jeans (Clothing)
  └── casual_top (Clothing)
```

#### 10. Validate and Save

Click **"Validate"**:
```
✓ Validation passed!
✓ Resource saved successfully
```

## Understanding Positioning

### Root Layers (No Parent)
- Position is absolute in world space
- Usually `(0, 0)` for body

### Child Layers (Has Parent)
- Position is relative to parent's anchor point
- Parent's anchor is typically top-left of parent image
- Positive X = right, Positive Y = down

### Example Positioning

```
Body (root): Position (0, 0)
  ├── Face: Position (100, 500)
  │   → Final position: body_pos + (100, 500)
  │   → If face texture is 200x200, anchor is at top-left
  │
  ├── Clothing: Position (0, 0)
      → Aligned with body anchor
```

## Template Path Patterns

### Dynamic (State-Based)

**Changes with pose:**
```
images/{plan}/{orientation}/body/{pose}_{body}.png
```

**Changes with expression:**
```
images/{plan}/{orientation}/faces/{expression}.png
```

**Changes with both:**
```
images/{plan}/{orientation}/outfits/{outfit}_{pose}.png
```

### Static (Fixed)

**Always same image:**
```
images/{plan}/{orientation}/accessories/hat.png
```

## Z-Index Strategy

Use gaps for flexibility:

```
0   - Body (base layer)
1   - Pants (over body)
2   - Face (over clothing)
10  - Tops (over face)
20  - Accessories (on top)
```

This allows inserting layers later:
- Add shoes at z=0.5
- Add jewelry at z=15

## Layer Type Guidelines

### When to use BODY
- Base character sprite
- Main body definition
- Usually only one per character
- Root layer

### When to use FACE
- Facial expressions
- Eye variations
- Mouth animations
- Changes frequently during gameplay

### When to use CLOTHING
- Any wardrobe item
- Items that can be swapped
- Items with tag conflicts
- Part of outfit system

## Wardrobe Tag Strategy

### Mutually Exclusive Items

**Only one top at a time:**
```
Tank Top:
  - Tags: ["summer", "top"]
  - Excluding: ["top"]

T-Shirt:
  - Tags: ["casual", "top"]
  - Excluding: ["top"]
```

**Only one bottom at a time:**
```
Jeans:
  - Tags: ["casual", "pants", "bottom"]
  - Excluding: ["bottom"]

Skirt:
  - Tags: ["feminine", "bottom"]
  - Excluding: ["bottom"]
```

### Compatible Items

**Accessories don't conflict:**
```
Hat:
  - Tags: ["accessory", "head"]
  - Excluding: [] (empty - can wear with anything)

Necklace:
  - Tags: ["accessory", "jewelry"]
  - Excluding: []
```

### Set Items

**Complete outfits:**
```
Suit Jacket:
  - Tags: ["formal", "suit", "top"]
  - Excluding: ["top", "bottom"] (includes pants)

Suit Pants:
  - Tags: ["formal", "suit", "bottom"]
  - Excluding: [] (worn with jacket)
```

## Advanced Techniques

### Multiple Body Types

```
Body Layer ID: "body"
Template: images/{plan}/{orientation}/body/{body_type}_{pose}.png

States:
  - body_type: "default" → default body
  - body_type: "athletic" → muscular variant
  - body_type: "slim" → thinner variant
```

### Seasonal Variations

```
Outfit Layer: "seasonal_top"
Template: images/{plan}/{orientation}/outfits/{season}_{outfit}.png

States:
  - season: "summer" → lighter colors
  - season: "winter" → warmer clothes
```

### Expression Combinations

```
Eyes Layer:
  Template: images/{plan}/{orientation}/faces/eyes_{expression}.png

Mouth Layer:
  Template: images/{plan}/{orientation}/faces/mouth_{expression}.png
  Parent: "body"
  Position: (100, 600)

Allows: happy_eyes + sad_mouth = mixed expression
```

## Common Workflows

### Adding a New Outfit

1. Open character resource
2. Click "Add"
3. Set as CLOTHING type
4. Set parent_layer_id to "body"
5. Choose appropriate z-index
6. Add tags for category
7. Add excluding_tags for conflicts
8. Set template path
9. Validate

### Reordering Layers

1. Select layer to move
2. Change z-index value
3. Gaps of 10 give room for insertion
4. Higher z = rendered on top
5. Validate

### Creating Layer Hierarchy

1. Add parent layer first (e.g., body)
2. Add child layers
3. Set child's parent_layer_id to parent's ID
4. Set child's position relative to parent
5. Validate hierarchy

### Testing Character

1. Validate resource
2. Run game scene with Actor node
3. Character loads automatically from .tres
4. Test state changes:
   ```gdscript
   character.express("happy")
   character.pose("walking")
   character.wear(["casual_top", "jeans"])
   ```

## Checklist

Before considering character complete:

- [ ] Body layer created (root)
- [ ] Face layer added (child of body)
- [ ] At least one clothing layer
- [ ] Template paths tested
- [ ] Z-indices logical
- [ ] Wardrobe tags configured
- [ ] Validation passes
- [ ] Tested in-game
- [ ] All states have images

## Troubleshooting

### "Layer not showing"
- Check template path resolves to existing file
- Verify z-index isn't hidden behind another layer
- Check layer isn't invisible (validation should catch this)

### "Wrong position"
- For root layers: position is absolute
- For child layers: position is relative to parent
- Check parent_layer_id is correct

### "Wardrobe conflicts not working"
- Verify tags are strings
- Check excluding_tags match actual tags
- Ensure layer_type is CLOTHING

### "Template not resolving"
- Check placeholder names match state variables
- Verify file exists at resolved path
- Test with simple static path first

## Next Steps

- Build more characters
- Create outfit variations
- Add expressions
- Test runtime character switching
- Document your template conventions

