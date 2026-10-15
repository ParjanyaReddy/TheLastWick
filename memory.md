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
  - State machine: `State { NORMAL, DASH, ATTACK, HURT, DEAD }`
  - Dash speed: 300 px/s, duration 0.16s, cooldown 0.40s, i-frames 0.12s
  - Fixed air dash distance to ~48px (no excessive drift)
  - Long jump from ground carries boosted momentum (`LONG_JUMP_SPEED = 270.0`)
  - Dash-cancel allows immediate interrupt from attack swings
- [x] **M2: Components and Combat Core**
  - `HitData`, `Health`, `Hitbox`, `Hurtbox`
  - 3-hit ground combo (15/15/25 dmg with knockback)
  - Up-slash (15 dmg)
  - Down-strike bounce ("pogo jump", 15 dmg, bounces high and resets air-dash)
  - `Juice` autoload (hit-stop 40ms, screen shake)
  - Floating damage numbers
  - Training Dummy in test level
- [x] **M3: First Enemy & Player Damage**
  - `Events` autoload signal bus
  - `EnemyData` Resource class
  - **Cinderling Enemy:** State machine (`PATROL -> TELEGRAPH -> ATTACK -> RECOVER -> DEAD`), ledge and wall detection, 0.45s telegraph flash, contact attack hitbox (8 dmg), death animation
  - **Player Damage:** Health (100 HP), Hurtbox, `HURT` state with knockback, 0.8s i-frames (blinking effect), `DEAD` state
  - **HUD CanvasLayer:** Health bar (100/100 HP), Wick flame icon, death overlay with "Press R to Restart"
- [x] **M4: Game Autoload, Mana System & Ember Bolt Spell**
  - `Stats` class with additive and multiplicative stat modifiers
  - `Game` autoload owning run state, HP, mana, Wax, and boons
  - Mana mechanics: 50 max mana, 2 mana/s out-of-combat regen, +4 mana per sword strike
  - **Ember Bolt Spell:** Cast on `K` (or RMB), costs 15 mana, launches a 320 px/s fire projectile dealing 25 damage
  - **Burn Status Effect:** `apply_status("burn", duration, dps)` implemented on enemies and training dummy (3 dmg/s over 3s)
  - HUD updated with animated blue Mana Bar (`50 / 50`)

## Next Milestones
- [ ] **M3b: Second Enemy - Ash Hurler** (ledge sniper lobbing arcing coals)
- [ ] **M5: Chunks and Procedural Level Builder** (Room template, Entry/Exit markers, wave spawner, door locks)
