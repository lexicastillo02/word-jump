# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**WFH (Work From Home)** is a surreal work-from-home life sim with hidden simulation narrative, built with Godot 4.5.

The player lives in a cramped studio apartment and "goes to work" via a VR headset. The twist: the apartment itself is a simulation—they never actually took the headset off. This reveals itself through environmental clues, glitches, and narrative progression.

**Word Jump** (typing platformer) is one of several work minigames within this larger experience.

## Running the Game

Open project in Godot 4.5 and press F5, or run from command line:
```bash
godot --path word-jump
```

Current flow: overworld (bedroom) → desktop → Word Jump

## Project Structure

```
climb/
├── word-jump/              # Main Godot project
│   ├── scenes/
│   ├── scripts/
│   ├── assets/
│   └── project.godot
├── planning-docs/          # Design documents
│   ├── concept/            # Game concept and implementation plans
│   └── *.md                # Feature plans
└── Learning/               # Personal learning notes (gitignored)
```

## Architecture

### Entry Flow
```
overworld.tscn → desktop.tscn → main_menu.tscn → main.tscn (Word Jump)
```

Future flow will include work hub with multiple minigames.

### Script Organization (word-jump/scripts/)

- **core/** - Singletons and game-wide systems
  - `game_settings.gd` - Autoload singleton for persistent settings
  - `game_manager.gd` - Game state, scoring, lives, floor progression
  - `word_manager.gd` - Word database, challenges, word selection logic

- **gameplay/** - Word Jump mechanics
  - `main.gd` - Central coordinator connecting all systems
  - `player.gd` - CharacterBody2D with jump physics
  - `platform.gd` - Platform types (static, shaky, timed, moving)
  - `platform_spawner.gd` - Dynamic platform generation
  - `camera_controller.gd` - Auto-scroll with speed scaling

- **ui/** - User interface
  - `hud.gd`, `main_menu.gd`, `pause_menu.gd`

- **overworld/** - Apartment/meta-game
  - `overworld.gd` - Apartment scene controller
  - `overworld_player.gd` - 8-directional movement, interaction zones
  - `desktop.gd` - Windows 95-style fake OS

### Key Patterns

**Signal-based Communication**: Components emit signals that others connect to:
- `game_manager`: score_changed, lives_changed, floor_changed, game_over
- `word_manager`: new_word_set, character_typed
- `player`: landed_on_platform, started_jumping

**Coordinator Pattern**: `main.gd` acts as central hub connecting player input, word validation, platform updates, and game state.

**Autoload Singleton**: `GameSettings` persists state between scenes.

### Scene Dependencies

- `main.tscn` instantiates: player.tscn, platform.tscn (via spawner), hud.tscn
- `overworld.tscn` instantiates: overworld_player.tscn

## Game Concept Summary

### The Apartment (Current: overworld)
- Cozy but restrictive single room
- Interactables: bed, TV, computer, window, door
- Player cannot leave—door eventually reveals brick wall

### Work Simulation (Current: Word Jump)
- Abstract "white room" environment
- Multiple minigames representing work tasks
- Layering effects hint at simulation nature

### Narrative Progression
- Day/night cycle with daily loop
- Glitches increase over time
- Environmental clues reveal the truth
- Multiple ending options

See `planning-docs/concept/wfh-implementation-plan-11-21-2025.md` for full implementation roadmap.

## Development Notes

- Resolution: 1280x720 with viewport stretch mode
- Collision: Platform shapes are 32px tall to prevent tunneling
- Player max fall velocity: 800 px/s
- Godot creates .uid files alongside scripts—move both when reorganizing
- Planning docs in `planning-docs/`, learning notes in `Learning/` (gitignored)
