# Harvest Hero: Farm Defender

A beginner-friendly Godot 4.x 2D combat platformer where a farmer protects the harvest from pest monsters.

## Controls

- Move: `A/D` or arrow keys
- Jump / double jump: `W`, `Space`, or up arrow
- Attack: `J` or left mouse button
- Restart after game over: `R`

## Included Systems

- Cleaner TileMap challenge route with warm-up jumps, hazard pits, a raised key path, enemy lane, and boss arena
- Player movement, double jumping, sword attack hitbox, knockback, health, hurt, and death
- Checkpoints that respawn the player after death or falling
- Player HP label plus a red HP bar
- Enemy and boss health bars
- Moving wooden platforms
- Crop shop stall that trades coins for healing
- Level timer shown in the HUD and on completion
- Supplied illustrated farm panorama used as the repeating level background
- Multi-tier TileMap layout based on the supplied reference: cliffs, bridges, tunnels, hazards, and boss yard
- Imported cartoon sprite frames for the farmer, beetle bugs, crows, worms, and Pest King boss
- Slime/mushroom slots use the beetle bug sprite set, with worm, crow, and boss using their own sheets
- Collectible crops, coins, and golden crop key
- Locked barn gate that opens only after collecting the key and defeating the boss
- HP and score UI
- Game over and level complete messages
- Camera follow
- No music or sound effects

Open `project.godot` in Godot 4.x and run the main scene.

## Editing the TileMap

1. Open `scenes/Main.tscn`.
2. Select the `TileMapLayer` child in the Scene dock.
3. Switch to the `2D` workspace.
4. Use the TileMap palette at the bottom to select grass, dirt, wood, fence, mud, spikes, water, or decoration tiles.
5. Paint with the pencil tool, erase with the eraser tool, then save the scene.

Solid tiles, spikes, and water automatically rebuild their gameplay collision when the level starts.

## Scene Structure

- `scenes/Main.tscn` - the canonical editable and playable level
- `Scenes/player.tscn` - player scene entry used by the main level
- `scenes/level_base.tscn` - base structure inherited by the main level
- `scenes/world/FarmBackground.tscn` - illustrated scrolling farm background
- Edit the `TileMapLayer` shown inside `scenes/Main.tscn`; both F5 and F6 now use those saved edits
- `scenes/characters/Player.tscn` - farmer player
- `scenes/enemies/Beetle.tscn` - beetle enemy
- `scenes/enemies/Worm.tscn` - worm enemy
- `scenes/enemies/Crow.tscn` - crow enemy
- `scenes/enemies/MushroomBeetle.tscn` - stronger beetle enemy
- `scenes/enemies/PestKing.tscn` - boss enemy
- `scenes/objects/` - checkpoint, moving platform, crop shop, and gate scenes
