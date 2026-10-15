# THE LAST WICK - Project Memory & State Tracker

## Project Overview
- **Game Title:** The Last Wick
- **Genre:** 2D Side-scrolling Action-Platformer Roguelite (Swordigo-style platforming + Hades-style run loop/boons)
- **Engine:** Godot 4.7.2 (Windows, Compatibility renderer)
- **Project Location:** `C:\Godot\TheLastWick`
- **Resolution:** 320x180 viewport, 1280x720 window override, nearest-neighbor filtering

## Core Mechanics & Design
- **Protagonist:** Ilu, apprentice lamplighter carrying the Wick (spark of dormant sun)
- **Hub:** Lamp Hearth in Vasara (restored with 12 Lost Lanterns)
- **Areas:** 3 Depths (Soot Streets, Drowned Cisterns, The Hush)
- **Controls:**
  - `move_left`, `move_right`, `move_up`, `move_down` (WASD / Arrows)
  - `jump` (Space)
  - `attack` (J)
  - `spell` (K)
  - `dash` (Shift)
  - `interact` (E)
  - `pause` (Escape)
- **Physics Layers (2D):**
  1. `world`
  2. `player`
  3. `enemy`
  4. `player_hitbox`
  5. `enemy_hitbox`
  6. `pickup`
  7. `interactable`

## Completed Milestones
- [x] **M0: Setup & Safety Net**
  - Project created in `C:\Godot\TheLastWick`
  - Viewport & window settings configured
  - 2D Physics layers named
  - Full Input Map registered
  - Git repository initialized and initial commit made
  - Folders established (`autoload/`, `scenes/`, `scripts/`, `data/`, `assets/`)
  - `CREDITS.md` and `later.md` created
- [x] **M1a: Run and Jump**
  - `res://scripts/player.gd` created with run speed (120), variable jump (-300), coyote time (0.12s), jump buffer (0.15s)
  - `res://scenes/player/player.tscn` created (CharacterBody2D, Camera2D, 10x20 shape)
  - `res://scenes/test/test_level.tscn` created with floor and 3 platforms
- [x] **M1b: Dash & Dash-Jump (Long Jump)**
  - State machine: `State { NORMAL, DASH }`
  - Dash speed: 300 px/s, duration 0.16s, cooldown 0.40s, i-frames 0.12s
  - Ground dash can be cancelled into a boosted long jump (`LONG_JUMP_SPEED = 270.0`) anytime during the dash
  - Air glide physics preserves horizontal momentum in the air instead of aggressively braking to base speed

## Next Milestones
- [ ] **M1c: Tilemap and Camera** (TileMapLayer, collision, camera limits)
- [ ] **M2: Components and Combat Core** (Health, Hitbox, Hurtbox, HitData, 3-hit sword combo, up/down strike, bounce, Juice hit-stop/shake)
