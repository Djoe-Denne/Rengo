# Cinematic Plan System - Image Structure

## Overview

The cinematic plan system introduces plan-based image organization for characters. Each plan (e.g., "medium_shot", "close_up") can have its own set of character images, allowing for different levels of detail and composition.

## New Image Path Structure

Character images are now organized with an additional plan level:

```
assets/scenes/common/characters/<character>/
  images/
    <plan-name>/
      <orientation>/
        body/
          idle.png
          waving.png
          ...
        faces/
          neutral.png
          happy.png
          sad.png
          ...
        outfits/
          casual.png
          chino.png
          jeans.png
          ...
```

### Example Structure

```
assets/scenes/common/characters/me/
  images/
    medium_shot/          # 16:9 ratio, medium distance
      front/
        body/
          idle.png
          waving.png
          idle_bedhair.png
          waving_bedhair.png
        faces/
          neutral.png
          happy.png
          sad.png
        outfits/
          casual.png
          casual_wave.png
          chino.png
          jeans.png
    close_up/             # 2.35:1 ratio, close distance
      front/
        body/
          idle.png
          waving.png
          idle_bedhair.png
          waving_bedhair.png
        faces/
          neutral.png
          happy.png
          sad.png
        outfits/
          casual.png
          casual_wave.png
          chino.png
          jeans.png
```

## Migration Guide

### Old Path Format
```
images/front/body/idle.png
images/front/faces/neutral.png
images/{orientation}/outfits/casual.png
```

### New Path Format
```
images/{plan}/front/body/idle.png
images/{plan}/front/faces/neutral.png
images/{plan}/{orientation}/outfits/casual.png
```

### Steps to Migrate

1. **Create plan directories**: For each character, create subdirectories under `images/` for each plan (e.g., `medium_shot/`, `close_up/`)

2. **Copy/Move images**: Duplicate or move existing images into each plan directory. You may want to:
   - Use the same images for all plans initially
   - Create plan-specific variations later (e.g., more detailed faces for close-ups)

3. **Verify YAML files**: All character YAML files have been updated to use the `{plan}` placeholder. No further changes needed.

## Configuration Files Updated

### Character Configuration (character.yaml)
- Added `size_cm` with `height` and `width` fields
- Example:
  ```yaml
  character:
    display_name: "Me"
    size_cm:
      height: 170
      width: 60
  ```

### Act Files (acts/*.yaml)
- All image paths now include `{plan}` placeholder
- Example:
  ```yaml
  variants:
    front:
      layers:
        body:
          images:
            default: "images/{plan}/front/body/idle.png"
  ```

### Wardrobe Files (panoplie.yaml)
- All image paths now include `{plan}` placeholder
- Example:
  ```yaml
  wardrobe:
    - id: "casual"
      variants:
        - image: "images/{plan}/{orientation}/outfits/casual.png"
  ```

### Scene Configuration (scene.yaml)
- Backgrounds moved into plans
- Added camera configurations per plan
- Example:
  ```yaml
  stage:
    default_plan: "medium_shot"
    scaling_mode: "letterbox"
  
  plans:
    - id: "medium_shot"
      camera:
        ratio: 1.777  # 16:9
        focal:
          min: 24
          max: 200
          default: 50
        aperture: 2.8
        shutter_speed: 50
        sensor_size: "fullframe"
      backgrounds:
        - id: "default"
          color: [0.2, 0.2, 0.3]
  ```

## Using Plans in Code

### Switch Plans
```gdscript
# Switch to close-up plan
vn_scene.set_plan("close_up")

# Switch back to medium shot
vn_scene.set_plan("medium_shot")
```

### Camera Configuration
Camera attributes are stored but not yet actively used. They're ready for future implementation:
- `ratio`: Aspect ratio (used for viewport scaling)
- `focal.min/max/default`: Focal length range in mm
- `aperture`: F-stop value
- `shutter_speed`: Shutter speed
- `sensor_size`: Sensor format (fullframe, micro43, apsc, etc.)

### Scaling Modes
Set in scene.yaml under `stage.scaling_mode`:
- `letterbox`: Maintain aspect ratio, add bars if needed (default)
- `fit`: Stretch to viewport while maintaining plan ratio
- `stretch`: Ignore ratio, fill entire viewport

## Technical Details

### Template Substitution
The system performs template substitution at runtime:
- `{plan}` → Current plan ID (e.g., "medium_shot")
- `{orientation}` → Character orientation (e.g., "front")
- `{color}` → Color variant
- `{variant}` → Style variant

### Placeholder Images
If an image is not found, the system displays a magenta placeholder and logs a warning with the character name and plan ID.

## Next Steps

1. **Reorganize existing images** into the new plan-based structure
2. **Create plan-specific variations** if desired (e.g., more detailed close-up images)
3. **Test plan switching** in the demo scene
4. **Add more plans** as needed (e.g., "wide_shot", "extreme_close_up")
5. **Implement camera effects** using the stored camera attributes (future enhancement)

