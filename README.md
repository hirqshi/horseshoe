# Horseshoe

First-person atmospheric speedrun parkour game about momentum, traversal and flow.

## Core pillars

- Momentum must be preserved whenever possible.
- Movement should reward speed, creativity and route knowledge.
- Stopping or moving slowly drains inverse stamina.
- The player should feel continuous forward flow through colossal megastructures.

## Tech

- Godot 4.x
- GDScript
- GitHub Desktop

## Repository structure

```text
res://
├── player/       # player scene, movement and camera
├── world/        # levels, checkpoints, kill zones and traversal geometry
├── ui/           # hud and menus
├── data/         # gameplay config resources
└── test/         # isolated mechanic test scenes
```

## Git conventions

Commit format:

```text
type(scope): short description
```

Examples:

```text
chore: initialize project
feat(player): add initial movement motor
feat(slide): add slope-aware slide action
fix(wallrun): preserve velocity on entry
```