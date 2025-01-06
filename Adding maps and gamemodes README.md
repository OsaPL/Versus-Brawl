Reminder: **Anything marked by 👻 is missing atm.**

### Table of contents
1. [Mapping](#mapping)
   1. [Map `.json` config file](#jsonconfig)
   2. [Gametypes specific](#gametype)
      1. [Last Bun Standing/Deathmatch](#lbsdm)
      2. [Race](#race)
      3. [CTF](#ctf)
      4. [Nidhogg](#nidhogg)
      5. [Coop](#coop)
      6. [Arena](#arena)
3. [Gamemode creation](#gamemodecreate)
   1. [Global variables](#globalvars)
   2. [UI](#ui)
   3. [Special events/messages](#events)
4. [Changes to default scripts](#scriptchanges)
   1. [`aschar.as`](#aschar)
   2. [`playercontrol.as`](#playercontrol)
   3. [`situationawareness.as`](#situationawareness)
5. [Hotspots](#hotspots)
   1. [`playerspawnhotspot`](#playerspawnhotspot)
   2. [`powerupbase`](#powerupbase)
   3. [`objectfolloweremitter`](#objectfolloweremitter)
   4. [`weaponspawnhotspot`](#weaponspawnhotspot)
   5. [`waterrisehotspot` and `waterPhaseHotspot`](#waterrisehotspot)
   6. [`flaghotspot` and `flagReturnHotspot`](#flaghotspot)
   7. [`teleporterhotspot`](#teleporterhotspot)
   8. [`charcatapulthotspot`](#charcatapulthotspot)
   9. [`staticobjectanimatorhotspot`](#staticobjectanimatorhotspot)
      1. [Importing your own animation](#animationimport)
      2. [Animating and `anim.json`](#animating)
      3. [Using `anim.json` files and hotspot itself](#hotspotitself)
   10. [`refreshPowerup`](#refreshpowerup)
   11. [`rotatoHotspot`](#rotatohotspot)
   12. [`raceWarmupHotspot`](#racewarmuphotspot)
6. [Items specific](#items)
   1. [Sheathing big weapons on the back](#sheatingonback)

# Mapping <a name="mapping"/>
These are general guidelines, tips, explanations that will make your map/gamemode more enjoyable and less janky, for this mod.
If you have any questions, suggestions or requests, feel free to DM me.

- `F10` now does a hard-reload of the map (this saved me EONS of time)
- `PreScriptReload()` will now reload the map automatically, to stay synced and reduce crashes due to a pointer fuckup or weird timing issues. Can be turned off with `noReloads=true` flag

### Navigation
1. Take into account that `jump nav point` will be used regardles of species by NPCs, so make it jumpable even for slowest ones.

### Performance
1. Keep levels light on decorations, splitscreen increase load by a lot.
2. Many effects are not even rendering for splitscreen (like fire effects), so removing them can give you a fps boost.

### General tips 
1. Try not put high or far ledges only available for rabbits, not everyone jumps that high and far.
Instead create for example, a row of columns, allowing rabbits to shine, but other species to still be viable (especially fast ones)
2. Do not to create one way battlegrounds, always give another way, holding a choke with a weapon is pretty easy
3. Weapons should be available to the all players similarly, even the playing field
4. Spawns should be pretty close, for that quick, swift action.
5. ... dont put them right next to each other tho
6. Spruce the level with some small obstacles, killzones, spikes, lava pits, whatever can be used to "accidentally" trip into (with or without help of your enemies)

### Workarounds
1. For the time being **DO NOT USE GLOBAL REFLECTION PROBES**, they are bugged atm and will make 2nd player camera not render some things.

## Map `.json` config file <a name="jsonconfig"/>

You can also add a `<map_name>.xml.json` file (see example file: `Levels\Test_map.xml.json`)

This allows you to control the parameters of both base and gamemode scripts, per map. These will overwrite the original value, use with caution.

To create a config, create an empty file, and name it correctly.
For example, we create `branches_map.xml.json`, to change params for `branches_map.xml`.
We can change checkpoints number needed to win to 7 in the race gamemode, but also force species to rabbit. We do this like this:

```json
{
  "VersusBase": {
    "ForcedSpecies": {
      "Value": 0
    }
  },
  "Race": {
    "CheckPointsNeeded": {
      "Value": 7
    }
  }
}
```

If you want to make values configurable on the menu, just set `Configurable` part accordingly (for values without range, you just need to create an empty entry):
```json
{
  "VersusBase": {
    "ForcedSpecies": {
      "Value": 0
    },
    "Configurable": {
      "Min": 0,
      "Max": 3
    },
    "InstantSpeciesChange": {
      "Value": false,
      "Configurable": {
      }
    }
  }
}
```

You can also set level params in the json itself, and make them configurable :
```json
{
  "LevelParams": {
    "TestString": {
      "Value": "Test",
      "Configurable": {}
    },
    "NonConfigurableTestString": {
      "Value": "NoConfTestString"
    },
    "IntTest": {
      "Value": 10,
      "Configurable": {
        "Min": 2,
        "Max": 100
      }
    },
    "BoolTest": {
      "Value": false,
      "Configurable": {}
    }
  }
}
```

You can also modify parameters of characters for that map by adding `SpeciesStats`:

```json
{
  "SpeciesStats": {
    "rabbit": {
      "Attack Knockback": 6.9
    }
  }
}
```
See `Scripts/versus-brawl/speciesStats.json` for available options.
You can also change them globally temporarily vby editing that file.



## Gametypes specific <a name="gametype"/>

### Last Bun Standing/Deathmatch <a name="lbsdm"/>

To implement Last Bun Standing/Deathmatch:

1. Place playerSpawnHotspots, change playerNr accordingly, -1 will be a free for all spawn
2. Setup level json parameters to your liking (like useGeneric, oneSpawnTypeOnly, blockRaceChange etc.)

### Race <a name="race"/>

To implement a race:

1. Place playerSpawnHotspots for all players, change playerNr accordingly (only specific ones will work)
2. Place checkPointsHotspots, adjust size as needed
3. Place separate spawnHotspot for all player for that checkpoint
4. Connect checkpointHotSpot to each spawnHotspot. To do that select checkpointHotSpot `double click` and then hold `alt` then click on spawnHotspot.

OR

1. Place 👻checkpointPrefab
2. Move spawnpoints to your desired position

and lastly, setup level json parameters to your liking (like checkPointsNeeded, blockRaceChange, spawnTime etc.)

Linking checkpoint to any other objects will switch the enabled flag and send in an `switch` event message, good for opening doorway, disabling walls, spawning in weapons etc.

If you wish your item to be stay disabled until checkpoint first activation, add `KeepDisabled` parameter to the object (no value needed)

You can also use `raceWarmupHotspot` and link it to anything you want to keep enabled (or disabled if has `KeepDisabled` param) during warmup.

### CTF <a name="ctf"/>

To implement CTF:

1. You just have to place `flag` hotspot (remember to set `teamId` accordingly).
2. Additionally, you can place some `flagReturn` hotspots, connect those `flagReturn` to `flag` hotspots, for a quicker way to return flags for defenders.
3. 👻 Setup level json parameters to your liking

### Nidhogg <a name="nidhogg"/>

This gamemode is a little complicated to implement, but it still only needs you to place hotspots, and connect the required things.

1. Place desired amount of `nidhoggPhase` hotspots, and set `phase` parameter accordingly (you can ignore phase `0`)
2. Add 2 spawns per phase and connect them to the hotspot (make sure there is at least one for each team, `0` and `1`)
3. Orientate the `nidhoggPhase` so the plus is directed towards phase with lower number (for example: `+[-2] +[-1] +[1] +[2]`)
4. If you want to seperate phases/stages, you can also connect more stuff to the `nidhoggPhase`, like kill hotspots or any static objects to create walls.
All connected objects will be enabled/disabled if the phase is currently open or active.
5. Setup level json parameters to your liking  

👻**Point *3.* will become optional/automatic at a later date**

### Coop <a name="coop"/>

You dont need to do anything in particular, as long as you use default `aschar.as`.

#### Custom levels support 
👻(not widely tested)

Make sure the place you spawn in players is always roomy enough for 4 players, and is atleast slightly off the ground.

If youre using anything custom, a custom implementation will be probably needed.
1. Set Level Parameter `characterActorPath` with your players desired `actor.xml` paths. 
You can set those per player:
```xml
<!-- For player two -->
<parameter name="characterActorPath1" type="string" val="Data/Objects/characters/cats/ouranian_hand_actor.xml" /> 
<!-- For player three -->
<parameter name="characterActorPath2" type="string" val="Data/Objects/IGF_Characters/IGF_WolfActor.xml" />
<!-- For player four -->
<parameter name="characterActorPath3" type="string" val="Data/Objects/rats/hooded_rat_actor.xml" />
```
2. Set any Script Parameters changes to that actor file, so the newly spawned player will also have them.
3. If you ever use players MovementObject to do something in level/hotspot script, you should change it to smth like:
```c++
for (int i = 0; i < GetNumCharacters(); i++) {
    MovementObject@ char = ReadCharacter(i);
    
    if(char.is_player){
        // This will affect all players now
        char.Execute("TakeBloodDamage(1.0f);");
    }
}
```

### Arena <a name="arena"/>
Creating arena map requires few things:
1. Place player spawn where desired.
2. Place `npcSpawners` where you want enemies to show up, setup them by changing params as needed:
   - If there is no way for enemy to notice players, enable `noticeAllOnSpawn`.
   - Keep `spawnLimit` at `1` if your spawn point is not in an open space.
   - `characterLimit` will define how many characters can be alive at once from this spawn
   - Name the spawn point if you wish to use it in the waves configuration
3. Create enemy templates
   - These will be used as the enemy definitions for the waves
   - You can just create an actor in editor, configure them as you please, and use `Save selection` option
   - Make note of the path to that saved file
```json
{
  "Arena": {
    "EnemyTemplates": {
      "NormalBunny": {
        "ActorPath": "Data/Objects/versus-brawl/levelSpecific/testArena/NormalBunny.xml"
      },
      "ArmoredBunny": {
        "ActorPath": "Data/Objects/versus-brawl/levelSpecific/testArena/ArmoredBunny.xml",
        "WeaponPath": "Data/Items/flint_knife.xml"
      },
      "NinjaDog": {
        "ActorPath": "Data/Objects/versus-brawl/levelSpecific/testArena/NinjaDog.xml",
        "WeaponPath": "Data/Items/staffbasic.xml",
        "BackWeaponPath": "Data/Items/Bastard.xml"
      }
    }
  }
}
```
4. Create wave definitions
   - These will define the enemies and their count for this wave
   - You can also set time, and whether or not killing everyone is required
   - If `KillAll` if false, the wave will require you to survive till time runs out.
   - Setting `SpawnName` will make sure they will spawn at that, named spawn point
```json
{
   "Arena": {
      "Waves": [
         {
            "Time": 20.0,
            "KillAll": true,
            "Enemies": [
               {
                  "Type":"NormalBunny",
                  "Amount": 2
               }
            ]
         },
         {
            "Time": 40.0,
            "KillAll": true,
            "Enemies": [
               {
                  "Type":"NinjaDog",
                  "Amount":1,
                  "SpawnName":"BGate"
               },
               {
                  "Type":"ArmoredBunny",
                  "Amount":1,
                  "SpawnName":"AGate"
               }
            ]
         }
      ]
   }
}
```
5. Configure mode itself, these are some additional settings that could prove useful:
(as with all params, you can also decide whether they should be configurable, from players menu)
```json
{
  "Arena": {
    "TimeBetweenWaves": {
      "Value": 5.0
    },
    "HealAfterWave": {
      "Value": true
    },
    "RespawnAfterWave": {
      "Value": true
    },
    "ScaleWithPlayers": {
      "Value": true
    },
    "FriendlyAttacks": {
      "Value": false,
      "Configurable": {
      }
    }
  }
}
```
# Gamemode creation <a name="gamemodecreate"/>
 
You can create your own gamemodes pretty easily! Start with `versusGameplayTemplate`.
 
## Global variables <a name="globalvars"/>
 `currentState` contains current game state, template already has: `warmup=0`, `error=1`, `gamestart>=2` `gameend>=100`, but you are free to implement more and use the `ChangeGameState(value)` call to switch.

**👻Document all params**

`errorMessage` can be set to notify user what is the reason for making `currentState == 1` (or basically, error state)

`constantRespawning` controls whether you should be automatically queued for a respawn.

`useGenericSpawns` decides whether to include generic (`playerNr==-1`) spawns into spawning logic.

`useSingleSpawnType` if is `true` will only use either generic or player specific spawns exclusively.

`blockSpeciesChange` will block players from changing species if `true`.

`forcedSpecies` number representing starting species for each player, at the map load.

`maxCollateralKillTime` how long does a death count as kill for the last attacker

`ScaleWithPlayers` multiply enemies amount by playuers amount

`EnemiesMultiplier` how many more enemies to spawn (this stacks multiplically with `ScaleWithPlayers`)

## UI <a name="ui"/>
You can use `versusAHGUI` class to have some basic UI.

Like setting onscreen text using :
```c++
versusAHGUI.SetText("big text","small text", /*text color:*/ vec4(1.0f,0.0f,0.0f,1.0f));
```
You can also make text multicolored, like this:
```c++
versusAHGUI.SetMainText("white @vec3(1,0,0)RED TEXT@ whiteAgain @ @vec3(0,0,1)BLUE TEXT@", vec4(1.0f,0.0f,0.0f,1.0f));
```
`vec3(R,G,B)` defines colors.

Result:
**white** 🔴<span style="color:red">RED TEXT</span> **whiteAgain** 🔵<span style="color:blue">BLUE TEXT</span>

You can also include control binding in the text:
```c++
versusAHGUI.SetMainText("Press @grab@ to block attacks!", vec4(1.0f,0.0f,0.0f,1.0f));
```
Result: **Press left trigger/left mouse button to block attacks!**

Adding an element to players bar
```c++
AHGUI::Element@ headerElement = versusAHGUI.root.findElement("header"+playerNr);
headerElement.addElement(@AHGUI::Text("Kills: "+killsCount[playerNr], "OpenSans-Regular", 50, 1, 1, 1, 1 ),DDTop);
```

## Special events/messages <a name="events"/>

### `oneKilledByTwo <victim obj ID> <attacker obj ID>`
Sent when a character is killed by another (checks `attacked_by_id` on victim and takes into account `maxCollateralKillTime`) 
### `bluntHit <victim obj ID> <attacker obj ID>`
Sent when a character is hit with a blunt weapon or hand to hand (unguarded hits, that deal dmg)
### `spawned <spawned obj ID> <first spawn bool>`
Sent when a character is being spawned or respawned (if current game state is not warmup)
### `suicideDeath <victim obj ID> <attacker obj ID>`
Sent when a death is not counted as a kill by another player (`maxCollateralKillTime < timeSinceAttackedById`)

# Changes to default scripts <a name="scriptchanges"/>
## `aschar.as` <a name="`aschar"/>

- 👻(not working yet fully) new values controlling item throws:
```c++
throwVelocityMlt = params.GetFloat("Throw - Initial Velocity Multiplier");
throwMassMlt = params.GetFloat("Throw - Mass Multiplier");
```
- Added fixes from `internal testing` branch regarding `attacker_id`
- Added jump parameters from `internal testing` branch to change jumping behaviour
- `bluntHit` message
- `weaponBlock` message, triggers on any held weapons collision
- `coopPartners.as` include, with an additional calls in `Update()`
- Moved color functions to `colorHelper.as`
- `timeSinceAttackedById` tracks time since last `attacked_by_id` change (as long as its not `-1`)
- `set_dialogue_position` now calls `InvokeCoop_set_dialogue_position` to forward the new position to coop players
- `BlockedAttack` now takes into the account `Attack Knockback`
- `HandleAnimationMiscEvent` returns quicker
- Modifications to the Unsheathe/Sheathing to allow for more weapon slots/big weapons sheathing and also more generic unsheathing (no longer you have to rely on anim events)
- You can now set `Can sheathe big weapons` param on a character to enable that.
- New animation events to use for `sheathed_left_back` and `sheathed_right_back` slots
- Zero or negative mass weapons will no longer crash/throw errors in throw functions
- Remove `situation.known_chars` entries if they disappeared

## `playercontrol.as` <a name="`playercontrol"/>
- `drunkMode` added, with new methods to invert controls
- Small modifications to Unsheathe/Sheathing, also adds ability to choose which weapon is selected
- You can now drop items by quick tapping `drop` key two times
- Characters will now make sounds based on their actions (just like npcs do)

## `situationawareness.as` <a name="`situationawareness"/>
- Small fix to `Notice()` method, to make manipulating (mostly removing) movement objects not crash sometimes
- Remove `known_chars` entries if they disappeared

# Hotspots <a name="hotspots"></a>

## `playerspawnhotspot` <a name="playerspawnhotspot"/>

Used to simply set player spawns.

Take note of the plus, it shows you the direction player will orientate themselves on spawn.

The only option you can set is `playerNr`. If its `0-3`, player with that number can spawn there, if its `-1` its a generic spawn (anyone can spawn there if `useGenericSpawns==true`)

## `powerupBase` <a name="powerupbase"></a>

Simple pickup that executes a function on the character. Disables on death or round reset.

👻TODO: write up on all parameters (most are self-explanatory still)

## `objectFollowerEmitter` <a name="objectfolloweremitter"/>

Can be used to make a particle effect emitter at its location.
Will follow the object if connected to it, or `objectIdToFollow` is filled with an object ID.

- `Min Distance To Activate` distance to nearest player after which it will turn itself off, also helps with fps

👻TODO: Document this better, its pretty useful.

## `weaponSpawnHotspot` <a name="weaponspawnhotspot"></a>

This allows you to create a dynamically spawned weapon. 

To use, fill the parameters with desired settings.

Options:

- `ItemPath` path to the item you want to spawn (paste the path in, to avoid crashes, why there is no `checkPath(path)` or smth ;_; )
- `RespawnTime` how long will it stay, if its not being held/attached to a character, before respawning
- `RespawnDistance` how far from spawn point qualifies as too far, and to start `RespawnTime` timer

## `waterRiseHotspot` and `waterPhaseHotspot` <a name="waterrisehotspot"/>

These two hotspots can be used together to create a phase based object up and down movement (see sewer_map for example)

To use, setup your desired objects and few `waterPhaseHotspot` (with `Phase` param set) and connect them to the `waterRiseHotspot`.

Objects rise/lower between `waterPhaseHotspot` phases.

If you want to set some dynamic stuff, you can connect any object to the `waterPhaseHotspot`, and it will be switched on/off accordingly, if you want to reverse the behaviour, add `KeepDisabled` param to the object (switching changes `Enabled` variable and sends `switch` event)

Options you can set for `waterRiseHotspot`:
- `Loop Phases` decides whether always go back to end/beginning if `true` or just reverse the order if `false`
- `Rise Speed` movement step per frame (higher means everything moves faster)
- `Phase Change Time` how often does phases advance
- `Bobbing Direction Inverted` inverts bobbing into opposite direction
- `Bobbing Multiplier` defines the strength of objects bobbing, lower values increase the bobbing, (default: `800`)
- `Delay Time` add delay, allows for bobbing not in sync
- `Phase Starting Direction Forward` in which direction should we consider phases at the start
- `Fast Mode - No Collision Refresh` this disables all physics calculation for movement, helps with fps in bigger levels (Note: this is ignored while in phase transition!)
- `Fast Mode - Reduce Rate Mltp` will interpolate physics only every X frame, helps with fps if you need collisions on objects to still change but not so often. `No Collision Refresh` has to be off to take effect (Note: this is ignored while in phase transition!)
- `Min Distance To Activate` distance to nearest player after which it will turn itself off, also helps with fps
- `RisingSoundPath` play this sound as loop during changing phases, use `RisingSoundVolume` to control volume
- `IdleSoundPath` play this sound as loop during idle time, again, use `IdleSoundVolume` if needed

Options you can set for `waterPhaseHotspot`:
- `Phase` decides what phase number in order it is

## `flagHotspot` and `flagReturnHotspot` <a name="flaghotspot"/>

These two can be used to create some gameplay based on gathering/returning flag.

`flaghotspot` creates a place that spawns flag and enables logic to return it back and also to capture enemy flags.
Captured flags will send a level wide event `flagCaptured <teamNr that lost the flag> <teamNr that captured that flag>`


Options you can set for `flaghotspot`:

- `red`, `green`, `blue`: controls the flag color (together with its light and all billboards)
- `returnCooldown`: for how long does it have to be dropped to return by itself back.
- `teamId`: defines what team is assigned to this flag

`flagreturn` hotspots once connected to a `flaghotspot` will work as a drop off point for the connected flag. You cant capture enemy flags using this point.

## `teleporterHotspot` <a name="teleporterhotspot"/>

Used to create portals. 

If you want to create a single way portal just connect it to an placeholder/object you wish it to teleport to.
If you want a two way portal, attach them both to each other.

Options you can set for `teleporterHotspot`:
- `red`, `green`, `blue`: controls the teleporterHotspot icon color
- `cooldown`: how long till it can be used again (dont set it to a really low or zero value for 2 way teleports)
- `teleportSound`: path to teleport sound file
- `velocityTranslator`: allows you to choose how should velocity be translated after teleport:
  - `-1`: dont translate velocity, it will be reset
  - `0`: just transfer it
  - `1` translate velocity onto direction of the portal, and reverse it if entered on the other side of the portal

## `charCatapultHotspot` <a name="charcatapulthotspot"></a>

Used to create jump pads, catapults and trampolines for players.

Options you can set for `charCatapultHotspot`:
- `velocity`: the velocity value to set
- `upwardsBoostScale`: adds percentage of the velocity to the UP direction, allows to more curved launches
- `reuseCharactersVelocity`: if true will add the `velocity` to the actual character velocity, otherwise will override it
- `trampolineMode`: Transforms it into a trampoline, can hold `jump` for a additional boost (options below will only work if true)
- `trampolineMinimalVelocityY`: what velocity is understood as to low to be bouncing off
- `trampolineBoost`: velocity boost, given to you a if `jump` is held during landing

## `staticObjectAnimatorHotspot` <a name="staticobjectanimatorhotspot"/>

This is a hotspot that allows you to create animated objects from static objects.

**If you want to animate with objects you already have, skip to [Animating and `anim.json`](#animating).**

### A. Importing your own animation <a name="animationimport"/>
If you want to export the animation from your blender model, you can use `extractAnim` scripts:
1. Configure paths to textures and everything else you will need inside `templateObj.xml` file
2. Make sure you have blender in your `PATH`, so that `blender` command is available
3. Open up powershell console in scripts location.
4. Import the needed script:
```powershell 
. ./extractAnim.ps1
```
5. Execute the script with the desired parameters (this could take a while):
```powershell 
# with interactive prompts
Export-Anims

# or you can use:
Export-Anims <.blend file> <start frame> <end frame> <mesh name> <models output dir> <objects output dir>
#EXAMPLE: Export-Anims test.blend 1 20 Parasit test out
```
6. Insert `<models output dir>` into desired `Data/Models/` folder and `<objects output dir>` into `Data/Objects/`

There should be a `anim.json` file in `<objects output dir>`

### B. Animating and `anim.json` <a name="animating"/>

You can use `anim.json` files to create your own animations. The game can be unresponsive depending on the amount of object frame needed to load.
Example file:
```json
{
  "objectPaths": [
    "Data/Objects/0.xml",
    "Data/Objects/1.xml",
    "Data/Objects/2.xml"
  ],
  "animations": [
    {
      "animName": "Default",
      "repeat": true,
      "animFrames": [
        {
          "frameTime": 0.2
          "objectIndex": 0
        },
        {
          "frameTime": 0,
          "objectIndex": 1
        },
        {
          "frameTime": 0,
          "objectIndex": 2
        },
        {
          "frameTime": 0,
          "objectIndex": 1
        }
      ]
    }
  ]
}

Cool idea to steal: you can also use this system to create animated textures.

```

Quick descriptions:
- `objectPaths`: list of available objects
- `animations`: list of available animations
  - `animName`: animation name
  - `repeat`: it will loop
  - `animFrames`: list of animation frames
    - `frameTime`: minimum time a frame needs to stay on screen (`0` means only single frame)
    - `objectIndex`: object index to use, from `objectPaths`

### C. Using `anim.json` files and hotspot itself <a name="hotspotitself"/>

Finally, you can load that `anim.json` into a hotspot and see it alive!

Options you can set for `staticObjectAnimatorHotSpot`:
- `configPath`: the path to the `anim.json` file
- `currentAnim`: animation to use from  `anim.json` file
- `paused`: will pause animation playback
- `forceRepeat`: will force looping, even if animation has `repeat` set to `false`
- `forceNoRepeat`: will disable looping, even if animation has `repeat` on animation set to `true` and `forceRepeat` is `true`
- `playNextAnim`: enables playing next animation in the list after this one finished
- `nextAnimIsRandom`: when a next animation is gonna be played, it selects a random one, `playNextAnim` must be `true`
- `speed`: controls the playback speed (👻 atm not working for single render frame animation frames)

## `refreshPowerup` <a name="refreshpowerup"/>
This is, I think the only powerup pickup that needs some explaining:

`RefreshAll` will send a refresh message to all powerups, if `true`.
If `false`, only connected powerups will get the refresh message.
Note: You cant refresh `refreshPowerup`.

## `rotatoHotspot` <a name="rotatohotspot"/>
This is used to create a simple rotating object, around a predefined axis. 

Options to set:
- `rotateDelay`: how much to delay each rotation, allows for slower, easier for fps/collisions rotations
- `rotatoSpeed`: how high is the angle for each rotation
- `useFastRotate`: use for object where there is no need to update collisions, big fps improvement
- `pauseWhenEditor`: If editor is active, stop rotation
- `rotationAxis`: axis of the rotation, a blue line will be drawn to illustrate axis (must follow `vec3(x, y, z)` format)

## `raceWarmupHotSpot` <a name="racewarmuphotspot"/>
This allows for elements to be only enabled or disabled if `InProgress` level param change.
Adding `KeepDisabled` will reverse the functionality.
Is mainly used to disable/enable elements in race mode only atm, but works by itself too.

# Items specific <a name="items"/>

## Sheathing big weapons on the back <a name="sheatingonback"/>

To make your weapon sheathe-able you need to add to your item xml:
1. Add a label describing what kind of weapon it is: 
```xml
<label>spear</label> <!--or--> <label>big_sword</label>
``` 
- `_sheathed_left_back` slot will be used for `big_sword` labeled weapons (`IsBigBlade(weapId)` check)
- `_sheathed_right_back` slot will be used for `spear` labeled weapon (`IsBigStick(weapId)` check)

👻 Step 1. will be not needed once step 3. will be a required one.

2. Add a attachment section with desired attachment animation (where the weapon will be mounted), and select a desired `ik_attach` bone (for most situation, just leave it as `torso`)
```xml
<sheathe ik_attach = "torso" anim = "Data/Animations/bow/r_arrow_sheathed.anm"/>
```

Some already available anims for weapons on your back you can try are:
```
"Data/Animations/bow/r_arrow_sheathed.anm"
"Data/Animations/bow/r_bow_sheathed.anm"
```

3. 👻 (step not needed atm, should already work, but havent tested it yet) Use these animation events, in your .anm to control sheathing:

**Sheathing**
- `sheatherighthandrightback`: right hand -> right back
- `sheatherighthandleftback`: right hand -> left back
- `sheathelefthandrightback`: left hand -> right back
- `sheathelefthandleftback`: left hand -> left back


**Unsheathing**
- `unsheatherighthandrightback`: right hand <- right back
- `unsheatherighthandleftback`: right hand <- left back
- `unsheathelefthandrightback`: left hand <- right back
- `unsheathelefthandleftback`: left hand <- left back
