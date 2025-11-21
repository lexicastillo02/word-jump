# Word Jump

A typing platformer game built with Godot 4.x where you climb a cyberpunk skyscraper by typing words to jump between platforms.

## Gameplay

- Type the word displayed on the next platform to jump to it
- Keep up with the auto-scrolling camera or lose a life
- Build combos by successfully typing words without mistakes
- Reach combo milestones to recover lives

## Features

- **Single-path progression** - One platform at a time, no confusion
- **Widescreen layout** (1280x720) - Clear visibility of upcoming platforms
- **Three difficulty levels**:
  - Easy: 10 lives, no word challenges
  - Medium: 5 lives, word challenges after floor 10
  - Hard: 3 lives, word challenges after floor 5
- **Word challenges** (Medium/Hard):
  - Backwards (pink) - Word displayed reversed
  - Missing Vowels (light blue) - Vowels replaced with underscores
- **Combo rewards**:
  - 5 combo streak: +1 life
  - 20 combo streak: +2 lives
- **Risk/reward scoring** - Longer words and faster typing = more points

## Controls

- **Letter keys** - Type the displayed word
- **ESC** - Pause game

## Running the Game

1. Open the project in Godot 4.x
2. Press F5 to run

## Project Structure

```
word-jump/
├── assets/           # Game assets (background, etc.)
├── scenes/           # Godot scene files
│   ├── main.tscn
│   ├── main_menu.tscn
│   ├── player.tscn
│   ├── platform.tscn
│   ├── hud.tscn
│   └── pause_menu.tscn
├── scripts/          # GDScript files
│   ├── main.gd
│   ├── game_manager.gd
│   ├── word_manager.gd
│   ├── platform_spawner.gd
│   ├── player.gd
│   └── ...
└── project.godot
```

## Credits

Built with Godot Engine 4.x
