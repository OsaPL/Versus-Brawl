﻿# Mappipng guidelines
These are general guidelines that will make the map more enjoyable and less janky, for this mod.
Each of them have been created from play testers feedback

## Navigation
1. Take into account that `jump nav point` will be used regardles of species by NPCs, so make it jumpable even for slowest ones.

## Performance
1. Keep levels light on decorations, splitscreen increase load by a lot.
2. Many effects are not even rendering for splitscreen (like fire effects), so removing them can give you a fps boost.

## General tips 
1. Try not put high or far ledges only available for rabbits, not everyone jumps that high and far.
Instead create for example, a row of columns, allowing rabbits to shine, but other species to still be viable (especially fast ones)
2. Do not to create one way battlegrounds, always give another way, holding a choke with a weapon is pretty easy
3. Weapons should be available to the all players similarly, even the playing field
4. Spawns should be pretty close, for that quick, swift action.
5. ... dont put them right next to each other tho
6. Spruce the level with some small obstacles, killzones, spikes, lava pits, whatever can be used to "accidently" trip into (with or without help of your enemies)

# Gametype specific

## Last Bun Standing

To implement Last Bun Standing:

1. Place separate spawnHotspot for all players, change playerNr accordingly, -1 will be a free for all spawn
2. Setup level parameters to your liking (like 👻useGeneric, 👻oneSpawnTypeOnly, blockRaceChange etc.)

## 👻Race

To implement a race:

1. Place separate spawnHotspot for all players, change playerNr accordingly (only specific ones will work)
2. Place checkPointsHotspots, adjust size as needed
3. Place separate spawnHotspot for all player for that checkpoint
4. Connect checkpointHotSpot to each spawnHotspot. To do that select checkpointHotSpot `double click` and then hold `alt` then click on spawnHotspot.

OR

1. Place 👻checkpointPrefab
2. Move spawnpoints to your desired position



5. Setup level parameters to your liking (like checkPointsNeeded, blockRaceChange, spawnTime etc.)