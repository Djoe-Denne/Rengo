# Core Game Library

An extendable MVC-based library for common game screens (title, options, save/load) built alongside the `rengo/` visual novel engine.

## Overview

The `core-game/` library provides models and controllers for common game screens, allowing developers to focus on creating custom views and UI while the library handles state management, persistence, and business logic.

## Architecture

Follows the same MVC pattern as `rengo/`:

- **Models**: Pure data with observer pattern for state management
- **Controllers**: Public API and business logic
- **Views**: Developer-created (examples provided)
- **Domain**: Shared utilities (screen manager, save system)

## Directory Structure

```
core-game/
├── models/              # Pure data models with observer pattern
│   ├── screen_model.gd
│   ├── title_screen_model.gd
│   ├── options_screen_model.gd
│   ├── save_load_screen_model.gd
│   └── save_data.gd
├── controllers/         # Controllers with public API
│   ├── screen_controller.gd
│   ├── title_screen_controller.gd
│   ├── options_screen_controller.gd
│   └── save_load_screen_controller.gd
├── domain/              # Shared utilities
│   ├── screen_manager.gd
│   └── save_system.gd
├── views/               # Base view helper
│   └── base_screen_view.gd
└── examples/            # Example implementations
    ├── example_save_data.gd
    ├── example_title_screen.gd
    ├── example_options_screen.gd
    └── example_save_load_screen.gd
```

## Quick Start

### 1. Define Your Save Data

Extend `SaveData` to define what gets saved:

```gdscript
class_name GameSaveData extends SaveData

var player_name: String = ""
var level: int = 1

func serialize() -> Dictionary:
    return {
        "player_name": player_name,
        "level": level
    }

static func deserialize(data: Dictionary) -> SaveData:
    var save = GameSaveData.new()
    save.player_name = data.get("player_name", "")
    save.level = data.get("level", 1)
    return save

func get_preview_data() -> Dictionary:
    return {
        "player": player_name,
        "level": level
    }
```

### 2. Create Your Views

Extend `BaseScreenView` or create custom Control nodes:

```gdscript
extends BaseScreenView

@onready var new_game_button: Button = $NewGameButton
@onready var continue_button: Button = $ContinueButton

func _ready() -> void:
    # Create model and controller
    var title_model = TitleScreenModel.new()
    var title_controller = TitleScreenController.new(title_model)
    
    # Setup callbacks
    title_controller.on_new_game = func(): print("New game!")
    
    # Setup view
    setup(title_model, title_controller)
    
    # Connect buttons
    new_game_button.pressed.connect(title_controller.start_new_game)
    continue_button.pressed.connect(title_controller.continue_game)

func _on_model_changed(state: Dictionary) -> void:
    # Update UI based on model state
    continue_button.disabled = not state.get("has_save_game", false)
```

### 3. Use Screen Manager for Navigation

```gdscript
# Setup screen manager
var screen_manager = ScreenManager.new()
add_child(screen_manager)

# Create controllers
var title_controller = TitleScreenController.new()
var options_controller = OptionsScreenController.new()

# Register screens
screen_manager.register_screen("title", "res://ui/title_screen.tscn", title_controller)
screen_manager.register_screen("options", "res://ui/options_screen.tscn", options_controller)

# Transition between screens
screen_manager.transition("title", "fade")
screen_manager.push_screen("options", "slide_left")  # Stack-based navigation
screen_manager.pop_screen("slide_right")             # Go back
```

## Features

### Title Screen

**Model** (`TitleScreenModel`):
- `has_save_game: bool` - Whether save exists
- `selected_option: int` - Selected menu index
- `menu_options: Array[String]` - Menu items

**Controller** (`TitleScreenController`):
- `start_new_game()` - Start new game
- `continue_game()` - Load most recent save
- `open_options()` - Open options screen
- `quit_game()` - Quit application
- `select_option(index)` - Select menu item

### Options Screen

**Model** (`OptionsScreenModel`):
- Audio: `master_volume`, `music_volume`, `sfx_volume` (0.0 to 1.0)
- Display: `is_fullscreen`, `resolution`, `vsync_enabled`
- Automatically applies settings to engine
- Persists to `user://settings.cfg`

**Controller** (`OptionsScreenController`):
- `set_master_volume(volume)` - Set master volume
- `set_music_volume(volume)` - Set music volume
- `set_sfx_volume(volume)` - Set SFX volume
- `toggle_fullscreen()` - Toggle fullscreen
- `set_resolution(resolution)` - Set resolution
- `toggle_vsync()` - Toggle VSync
- `save_settings()` - Save to disk
- `back()` - Return to previous screen

### Save/Load Screen

**Model** (`SaveLoadScreenModel`):
- `mode: String` - "save" or "load"
- `save_slots: Array[Dictionary]` - Slot metadata
- `max_slots: int` - Maximum slots
- `selected_slot: int` - Selected slot

**Controller** (`SaveLoadScreenController`):
- `set_mode(mode)` - Set save/load mode
- `select_slot(index)` - Select slot
- `save_to_selected_slot(save_data)` - Save game
- `load_from_selected_slot()` - Load game
- `delete_selected_slot()` - Delete save
- `refresh_slots()` - Refresh from disk

### Save System

Static utility class for file operations:

```gdscript
# Save game
var save_data = GameSaveData.new()
SaveSystem.save_game(0, save_data)

# Load game
var loaded = SaveSystem.load_game(0, GameSaveData)

# List slots
var slots = SaveSystem.list_save_slots(10)

# Check for saves
var has_save = SaveSystem.has_any_save()
var recent_slot = SaveSystem.get_most_recent_save_slot()

# Delete save
SaveSystem.delete_save(0)
```

## Screen Manager

Handles navigation and transitions:

### Built-in Transitions
- `instant` - No animation
- `fade` - Fade in/out
- `slide_left`, `slide_right`, `slide_up`, `slide_down` - Slide transitions

### Custom Transitions

Override `_custom_transition()` for custom effects:

```gdscript
class_name MyScreenManager extends ScreenManager

func _custom_transition(from: Node, to: Node, type: String) -> void:
    if type == "zoom":
        # Custom zoom transition
        pass
    else:
        super._custom_transition(from, to, type)
```

### Callbacks

Override `_on_screen_changed()` for custom behavior:

```gdscript
func _on_screen_changed(screen_name: String) -> void:
    print("Now on screen: ", screen_name)
    # Custom logic here
```

## Extendability

### 1. Extend Models

Add game-specific properties:

```gdscript
class_name MyOptionsModel extends OptionsScreenModel

var custom_setting: bool = false

func set_custom_setting(value: bool) -> void:
    if custom_setting != value:
        custom_setting = value
        _notify_observers()

func _get_state() -> Dictionary:
    var state = super._get_state()
    state["custom_setting"] = custom_setting
    return state
```

### 2. Extend Controllers

Add custom methods:

```gdscript
class_name MyTitleController extends TitleScreenController

func show_credits() -> void:
    screen_manager.transition("credits")
```

### 3. Create New Screens

Follow the same pattern:

```gdscript
# 1. Create model
class_name CreditsScreenModel extends ScreenModel

# 2. Create controller
class_name CreditsScreenController extends ScreenController

# 3. Create view
extends BaseScreenView
```

## Integration with rengo/

Both libraries follow the same MVC architecture:

- **Consistent Patterns**: Same observer pattern, MVC separation
- **Save Integration**: Save VN scene state in your SaveData
- **Navigation**: Screen manager can transition to/from VN scenes
- **Parallel Usage**: Use both libraries in the same project

Example - Save VN state:

```gdscript
class_name GameSaveData extends SaveData

var vn_scene: String = ""
var vn_plan: String = ""
var character_states: Dictionary = {}

func serialize() -> Dictionary:
    return {
        "vn_scene": vn_scene,
        "vn_plan": vn_plan,
        "character_states": character_states
        # ... other data
    }
```

## Best Practices

1. **Extend, Don't Modify**: Inherit from base classes rather than modifying library code
2. **Use Observer Pattern**: Models notify observers, views update automatically
3. **Separate Concerns**: Keep game logic in controllers, UI in views, data in models
4. **Custom SaveData**: Always extend SaveData for your specific needs
5. **Screen Manager**: Use for consistent navigation and transitions

## Examples

See the `examples/` directory for complete implementations:
- `example_save_data.gd` - SaveData implementation
- `example_title_screen.gd` - Title screen view
- `example_options_screen.gd` - Options screen view
- `example_save_load_screen.gd` - Save/load screen view

## License

Same license as the parent project.

