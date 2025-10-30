# State-Driven Shader System - Usage Guide

## Overview

The state-driven shader system allows you to activate/deactivate shaders based on resource states (Characters, Backgrounds, etc.). Shaders are configured via YAML files and automatically apply when states change.

## Features

- **State-based activation**: Shaders activate when specific states are set
- **Shader chaining**: Multiple shaders can be chained using Material.next_pass
- **Parameter binding**: Shader parameters can reference state values
- **Works with Actors and Backgrounds**: Supports both 3D (MeshInstance3D) and 2D (Sprite2D) rendering

## How It Works

### 1. Create a Shader File

Example: `assets/shaders/glow.gdshader`

```gdscript
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_opaque, cull_disabled;

uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 0.5, 1.0);
uniform float intensity : hint_range(0.0, 2.0) = 0.8;
uniform sampler2D screen_texture : hint_screen_texture;

void fragment() {
    vec4 input_color = texture(screen_texture, SCREEN_UV);
    vec3 glow = glow_color.rgb * intensity * input_color.a;
    ALBEDO = glow;
    ALPHA = input_color.a * intensity;
}
```

### 2. Create a Shader Configuration File

Place `shaders.yaml` in your character or background asset folder.

Example: `assets/scenes/common/characters/me/shaders.yaml`

```yaml
shaders:
  # State name that activates this shader
  focused:
    - shader: "assets/shaders/glow.gdshader"
      order: 0  # Chain order (lower = earlier in next_pass)
      params:
        glow_color: "(1.0, 1.0, 0.5, 1.0)"  # Yellow glow
        intensity: 0.8
  
  # Multiple shaders can be chained
  highlighted:
    - shader: "assets/shaders/glow.gdshader"
      order: 0
      params:
        glow_color: "(0.5, 0.5, 1.0, 1.0)"  # Blue glow
        intensity: 1.0
    - shader: "assets/shaders/outline.gdshader"
      order: 1
      params:
        outline_color: "(1.0, 1.0, 1.0, 1.0)"
        outline_width: 3.0
```

### 3. Activate Shaders via State Changes

**For Characters (Actors):**

```gdscript
# Hover interaction that activates glow shader
var poke_interaction = InteractionBuilder.builder() \
    .name("poke") \
    .add(InputBuilder.hover() \
        .in_callback(func(ctrl): ctrl.model.set_state("status", "focused")) \
        .out_callback(func(ctrl): ctrl.model.set_state("status", "")) \
        .build()) \
    .build()

me_actor_ctrl.interaction(poke_interaction)
```

**For Backgrounds:**

```gdscript
# Get background reference
var background = $Background

# Activate shader by setting state
background.set_state("status", "focused")

# Deactivate shader
background.set_state("status", "")
```

## Configuration Options

### Shader Definition Fields

- **shader**: Path to the .gdshader file (required)
- **order**: Chain order for next_pass (default: 0, lower values render first)
- **layer**: Specific layer to apply shader to (optional, omit to apply to all layers)
- **params**: Dictionary of shader parameters

### Parameter Types

Parameters support:
- **Numbers**: `intensity: 0.8`
- **Colors**: `glow_color: "(1.0, 0.5, 0.2, 1.0)"` or `"#FF8833"`
- **State references**: `"{glow_color}"` - resolves from current state values

### Layer-Specific Shaders

Apply shaders to specific layers only:

```yaml
shaders:
  focused:
    - shader: "assets/shaders/glow.gdshader"
      layer: "body"  # Only apply to body layer
      order: 0
      params:
        glow_color: "(1.0, 1.0, 0.5, 1.0)"
```

## Shader Chaining with next_pass

Multiple shaders are automatically chained using Material.next_pass:

```
Base Material (texture) 
  → Shader 1 (order: 0)
    → Shader 2 (order: 1)
      → Shader 3 (order: 2)
```

Each shader receives the output of the previous pass as input via `screen_texture`.

## Testing

The demo scene (`game/demo.gd`) includes a hover interaction that sets the "status" state to "focused":

1. Run the demo scene
2. Hover over the "me" actor
3. The glow shader should activate (yellow glow)
4. Move mouse away to deactivate

## Architecture

- **ShaderRepository**: Singleton that loads and caches shaders
- **Actor.shader_config**: Loaded from character's shaders.yaml
- **Actor._update_shaders()**: Called when states change, manages shader activation
- **Material.next_pass**: Used to chain multiple shader effects

## File Structure

```
assets/
  shaders/
    glow.gdshader           # Reusable shader files
    outline.gdshader
  scenes/
    common/
      characters/
        me/
          shaders.yaml      # Character-specific shader config
      backgrounds/
        sunset/
          shaders.yaml      # Background-specific shader config
```

## Troubleshooting

**Shader not activating:**
- Check that shaders.yaml exists in the correct character/background folder
- Verify the state name matches (e.g., "focused" in YAML and code)
- Check console for shader loading warnings

**Shader rendering incorrectly:**
- Ensure shader_type matches (spatial for 3D, canvas_item for 2D)
- Verify render_mode settings for your use case
- Check that screen_texture sampler is defined correctly

**Multiple shaders not chaining:**
- Verify order values are different (0, 1, 2, etc.)
- Check that next_pass chaining is working via material inspection

