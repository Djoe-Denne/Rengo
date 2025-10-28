# Game UI Screens

Simple UI implementations using core-game view library.

## Available Screens

### Title Screen (`title_screen.tscn`)
- Uses: `TitleScreenView` from `core-game/views/`
- Buttons: New Game, Continue, Options, Quit
- Centered vertical menu layout
- Automatically handles:
  - Continue button enable/disable based on save existence
  - Keyboard navigation (up/down/enter)
  - Callbacks to start game, open options, quit

### Options Screen (`options_screen.tscn`)
- Uses: `OptionsScreenView` from `core-game/views/`
- Controls:
  - Master Volume slider (0-1)
  - Music Volume slider (0-1)
  - SFX Volume slider (0-1)
  - Fullscreen checkbox
  - Resolution selector (< label >)
  - VSync checkbox
  - Back button
- Automatically handles:
  - Syncing sliders with actual audio levels
  - Applying display settings to engine
  - Saving/loading settings from disk
  - Navigation back to previous screen

### Save Screen (`save_screen.tscn`)
- Uses: `SaveLoadScreenView` from `core-game/views/`
- Mode: Save
- Controls:
  - Mode label ("SAVE GAME")
  - Scrollable slots container (auto-populated)
  - Save button
  - Delete button (shown only for filled slots)
  - Back button
- Automatically handles:
  - Creating slot buttons dynamically
  - Loading slot metadata from disk
  - Keyboard navigation
  - Confirmation/deletion logic

### Load Screen (`load_screen.tscn`)
- Uses: `SaveLoadScreenView` from `core-game/views/`
- Mode: Load
- Controls:
  - Mode label ("LOAD GAME")
  - Scrollable slots container (auto-populated)
  - Load button
  - Delete button (shown only for filled slots)
  - Back button
- Automatically handles:
  - Creating slot buttons dynamically
  - Loading slot metadata from disk
  - Keyboard navigation
  - Load/deletion logic

## How It Works

### 1. Views from core-game/
Each .tscn file attaches a view script from `core-game/views/`:
- `TitleScreenView`
- `OptionsScreenView`
- `SaveLoadScreenView`

These views are **complete implementations** that:
- Create their own model and controller
- Wire up all UI elements automatically
- Handle all business logic
- Provide callbacks for customization

### 2. Node Paths
Views export node paths with default values that match the UI structure:
```gdscript
@export var start_button_path: NodePath = ^"VBoxContainer/StartButton"
```

As long as your UI matches these paths, everything works automatically!

### 3. Customization
To customize node paths:
1. Open .tscn in Godot editor
2. Select the root node
3. Modify exported variables in Inspector
4. Or rename your UI nodes to match default paths

## Navigation Flow

```
Title Screen
    ├─> New Game → (configured in main.gd)
    ├─> Continue → Loads most recent save
    ├─> Options → Options Screen
    │       └─> Back → Title Screen
    ├─> Quit → Exits game
    └─> Save/Load Screens (when implemented in game flow)
```

## Adding to Your Game

Screens are registered in `game/main.gd`:
```gdscript
screen_manager.register_screen("title", "res://game/ui/title_screen.tscn")
screen_manager.register_screen("options", "res://game/ui/options_screen.tscn")
screen_manager.register_screen("save", "res://game/ui/save_screen.tscn")
screen_manager.register_screen("load", "res://game/ui/load_screen.tscn")
```

Navigate between screens:
```gdscript
screen_manager.transition("options")         # Direct transition
screen_manager.push_screen("save", "fade")   # Stack-based (can go back)
screen_manager.pop_screen("fade")            # Return to previous
```

## Styling

All screens use basic Godot controls. To style:
1. Create a theme resource in Godot
2. Apply to root Control node of each screen
3. Or apply globally in project settings

## Simple and Functional

These UIs are intentionally simple - they demonstrate the architecture without complex styling. Game developers can:
- Use these as-is for rapid prototyping
- Redesign completely in Godot editor
- Keep the same view scripts (they adapt to your layout)
- Focus on making it beautiful while logic is handled

