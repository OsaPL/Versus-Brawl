Reminder: **Anything marked by 👻 is missing atm.**
# Mapping
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

### `.json` config file

You can also add a `<map_name>.xml.json` file (see example file: `Levels\Test_map.xml.json`)

This allows you to control the parameters of both base and gamemode scripts, per map. These will overwrite the original value, use with caution.

To create a config, create an empty file, and name it correctly.
For example, we create `branches_map.xml.json`, to change params for `branches_map.xml`.
We can change checkpoints number needed to win to 7 in the race gamemode, but also force species to rabbit. We do this like this:

```json
{
  "VersusBase": {
    "ForcedSpecies": 0
  },
  "Race": {
    "CheckPointsNeeded": 7
  }
}
```

You can also modify paremeters of characters for that map by adding `SpeciesStats`:

```json
{
  "VersusBase": {
    "ForcedSpecies": 0
  },
  "Race": {
    "CheckPointsNeeded": 7
  },
  "SpeciesStats": {
    "rabbit": {
      "Attack Knockback": 6.9
    }
  }
}
```
See `Scripts/versus-brawl/speciesStats.json` for available options.
You can also change them globally temporarily vby editing that file.



## Gametype specific

### Last Bun Standing/Deathmatch

To implement Last Bun Standing/Deathmatch:

1. Place playerSpawnHotspots, change playerNr accordingly, -1 will be a free for all spawn
2. Setup level json parameters to your liking (like useGeneric, oneSpawnTypeOnly, blockRaceChange etc.)

### Race

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

### CTF

To implement CTF:

1. You just have to place `flag` hotspot (remember to set `teamId` accordingly).
2. Additionally, you can place some `flagReturn` hotspots, connect those `flagReturn` to `flag` hotspots, for a quicker way to return flags for defenders.
3. 👻 Setup level json parameters to your liking

### Coop

You dont need to do anything in particular, as long as you use default `aschar.as`.

#### Custom levels support 
👻(not tested)

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

#### Custom `aschar.as` support
👻(not tested)

You probably just need to include `coopPartners.as` script and do the same thing I've done in my `aschar.as`. 

Just correctly call `CoopPartnersCheck()` and `CoopPanic()`.

# Gamemode creation
 
You can create your own gamemodes pretty easily! Start with `versusGameplayTemplate`.

### Global variables available
 `currentState` contains current game state, template already has: `warmup=0`, `map unsupported/missing components=1`, `gamestart>=2` `gameend>=100`, but you are free to implement more and use the `ChangeGameState(value)` call to switch.

**👻Document all params**

`constantRespawning` controls whether you should be automatically queued for a respawn.

`useGenericSpawns` decides whether to include generic (`playerNr==-1`) spawns into spawning logic.

`useSingleSpawnType` if is `true` will only use either generic or player specific spawns exclusively.

`blockSpeciesChange` will block players from changing species if `true`.

`forcedSpecies` number representing starting species for each player, at the map load.

`maxCollateralKillTime` how long does a death count as kill for the last attacker

## UI 
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
**white** <span style="color:red">RED TEXT</span> **whiteAgain** <span style="color:blue">BLUE TEXT</span>

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

## Special events/messages

### `oneKilledByTwo <victim obj ID> <attacker obj ID>`
Sent when a character is killed by another (checks `attacked_by_id` on victim and takes into account `maxCollateralKillTime`) 
### `bluntHit <victim obj ID> <attacker obj ID>`
Sent when a character is hit with a blunt weapon or hand to hand (unguarded hits, that deal dmg)
### `spawned <spawned obj ID> <first spawn bool>`
Sent when a character is being spawned or respawned (if current game state is not warmup)
### `suicideDeath <victim obj ID> <attacker obj ID>`
Sent when a death is not counted as a kill by another player (`maxCollateralKillTime < timeSinceAttackedById`)

# Changes to default scripts 
## `aschar.as`

- 👻(not working yet fully) new values controlling item throws:
```c++
throwVelocityMlt = params.GetFloat("Throw - Initial Velocity Multiplier");
throwMassMlt = params.GetFloat("Throw - Mass Multiplier");
```
- Added fixes from `internal testing` branch regarding `attacker_id`
- Added jump parameters from `internal testing` branch to change jumping behaviour
- `bluntHit` message
- `coopPartners.as` include, with an additional calls in `Update()`
- Moved color functions to `colorHelper.as`
- `timeSinceAttackedById` tracks time since last `attacked_by_id` change (as long as its not `-1`)
- `set_dialogue_position` now calls `InvokeCoop_set_dialogue_position` to forward the new position to coop players
- `BlockedAttack` now takes into the account `Attack Knockback`
- `HandleAnimationMiscEvent` returns quicker
- Modifications to the Unsheathe/Sheathing to allow for more weapon slots/big weapons sheathing and also more generic unsheathing (no longer you have to rely on anim events)
.You can now set `Can sheathe big weapons` param on a character to enable that.
- Zero or negative mass weapons will no longer crash/throw errors in throw functions

## `playercontrol.as`
- `drunkMode` added, with new methods to invert controls
- Small modifications to Unsheathe/Sheathing, also adds ability to choose which weapon is selected
- You can now drop items by quick tapping `drop` key two times

## Generic available Hotspots

### `playerSpawn` 

Used to simply set player spawns.

Take note of the plus, it shows you the direction player will orientate themselves on spawn.

The only option you can set is `playerNr`. If its `0-3`, player with that number can spawn there, if its `-1` its a generic spawn (anyone can spawn there if `useGenericSpawns==true`)

### `powerupBase`

Simple pickup that executes a function on the character. Disables on death or round reset.

👻TODO: write up on all parameters (most are self-explanatory still)

### `objectFollowerEmitter`

Can be used to make a particle effect emitter at its location.
Will follow the object if connected to it, or `objectIdToFollow` is filled with an object ID.

👻TODO: Document this better, its pretty useful.

### `weaponSpawnHotspot`

This allows you to create a dynamically spawned weapon. 

To use, fill the parameters with desired settings.

Options:

- `ItemPath` path to the item you want to spawn (paste the path in, to avoid crashes, why there is no `checkPath(path)` or smth ;_; )
- `RespawnTime` how long will it stay, if its not being held/attached to a character, before respawning
- `RespawnDistance` how far from spawn point qualifies as too far, and to start `RespawnTime` timer

### `waterRiseHotspot` and `waterPhaseHotspot`

These two hotspots can be used together to create a phase based object up and down movement (see sewer_map for example)

To use, setup your desired objects and few `waterPhaseHotspot` (with `Phase` param set) and connect them to the `waterRiseHotspot`.

Objects rise/lower between `waterPhaseHotspot` phases.

If you want to set some dynamic stuff, you can connect any object to the `waterPhaseHotspot`, and it will be switched on/off accordingly, if you want to reverse the behaviour, add `KeepDisabled` param to the object (switching changes `Enabled` variable and sends `switch` event)

Options you can set for `waterRiseHotspot`:
- `Loop Phases` decides whether always start from end/beginning if `true` or just reverse the order if `false`
- `Rise Speed` movement step per frame (higher means everything moves faster)
- `Phase Change Time` how often does phases advance
- `Bobbing Multiplier` defines the strength of objects bobbing, lower values increase the bobbing, (default: `800`)
- `Delay Time` add delay, allows for bobbing not in sync
- `Phase Starting Direction Forward` in which direction should be consider phases at the start

Options you can set for `waterPhaseHotspot`:
- `Phase` decides what phase number in order it is

### `flag` and `flagreturn` hotspots

These two can be used to create some gameplay based on gathering/returning flag.

`flaghotspot` creates a place that spawns flag and enables logic to return it back and also to capture enemy flags.
Captured flags will send a level wide event `flagCaptured <teamNr that lost the flag> <teamNr that captured that flag>`


Options you can set for `flaghotspot`:

- `red`, `green`, `blue`: controls the flag color (together with its light and all billboards)
- `returnCooldown`: for how long does it have to be dropped to return by itself back.
- `teamId`: defines what team is assigned to this flag

`flagreturn` hotspots once connected to a `flaghotspot` will work as a drop off point for the connected flag. You cant capture enemy flags using this point.

### `teleporterHotspot`

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

### `charCatapultHotspot`

Used to create jump pads, catapults and trampolines for players.

Options you can set for `charCatapultHotspot`:
- `velocity`: the velocity value to set
- `upwardsBoostScale`: adds percentage of the velocity to the UP direction, allows to more curved launches
- `reuseCharactersVelocity`: if true will add the `velocity` to the actual character velocity, otherwise will override it
- `trampolineMode`: Transforms it into a trampoline, can hold `jump` for a additional boost (options below will only work if true)
- `trampolineMinimalVelocityY`: what velocity is understood as to low to be bouncing off
- `trampolineBoost`: velocity boost, given to you a if `jump` is held during landing