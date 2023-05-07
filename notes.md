# Npc players problems:
1. Should use `.isNpc` for all Npc checks
2. Tag: will crash if more than 4 players
   - Problem: tables are hardcoded to have 4 elems
3. `isNpc` should be checked inside SpawnCharacter probably!
4. There is some logic in `pointUIBase.as` taht needs to get seperated, to some UI and Gameplay flows

DM and CTF seem to work just fine, even if over 4+ players

# Example `LevelParams` section (*put into docs*)
```json
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
```

# DO THOSE THINGS:
- `speed` on staticAnimator should also work for frames (in integer form only for > 1), 2x is "skip a frame", 0.5x is "render frame two times" etc
- big weapons that support sheathing should be seperated into Versus brawl probably, instead of overwriting the stock weapons
- all places that have paths to resources should use `FileExistsWithType`
- organise all scripts/objects better
- create a generic thing for managing and "switching" objects (gut out what is already done in `waterRiseHotspot`?)
- get rid of that stupid limitation of: `respawnTime cant be smaller than activeTime` on powerupBase

# Maybe, Maybees, Maybies?
- for simple arrays, I should just use `int find(const T& in)`
- enable/disable hints ingame by using a key combo
- extend `powerUpBase.as` to allow more than a single particle emitter

# Sheathed weapons:
Big blades:
- `DogBroadSword`: not great, rotate 90 degrees around itself and move it higher `"Data/Animations/bow/r_arrow_sheathed.anm"`
- `DogHammer`: meh, rotate 90 degrees around itself and move closer to the body, also added `<label>staff</label>`, ALSO added new attacks to make it usable `"Data/Animations/bow/r_bow_sheathed.anm"`, and moved the model slightly higher

Big sticks:
- `staffbasic`: acceptable? would be cool to rotate like 30-45 degrees `"Data/Animations/bow/r_arrow_sheathed.anm"`
- `DogGlaive`: alright, maybe move it slightly higher, so it doesnt go through you ankles `"Data/Animations/bow/r_arrow_sheathed.anm"`
- `DogSpear`: basically perfect `"Data/Animations/bow/r_arrow_sheathed.anm"`
- `RabbitCatcher`: alright `"Data/Animations/bow/r_bow_sheathed.anm"`


[h1]0.7:[/h1]
This is a big one, with focus on actually getting new content polished, and making mapping a lot better.
Some of these changes/additions were already included in 0.5.9 pre-release, they have been fixed up and polished since.
(skipped 0.6, since I didnt want to push another update without any new content)
[b]Added Nidhogg, CTF, Race gamemodes![/b]
- Some of these were already available, but were reworked/enhanced a lot
- also, they now come with actually finished maps...

[b]Added new playable maps:[/b]
- Sand Fortress, CTF
- Purple Dreams, Nidhogg
- Lava Tower, Race (WIP)

[b]Maps reworked:[/b]
- Imperial sewers, is now a finished map
- Dank cave, now a TAG map, with many visual touchups
- Gods Exile, touched up and converted into a DM map

[b]Weapons additions:[/b]
- DogHammer is now a unique two handed weapon, for smashing through a sturdy opponent.
- RabbitCatcher now acts as a spear.
- You can now also quick drop a weapon by tapping "drop" two times quickly
- Added ability to select which weapon to unsheathe by holding a key, and then pressing "item" key:
  - hold "grab" to unsheathe hip weapons (hold "item" to unsheathe both, press for a single one)
  - hold "attack" to unsheathe big sword weapon slot

[b]Dogs can now sheathe big weapons on their back. (other characters can also use the new "Can sheathe big weapons" parameter)[/b]
- Supported big sword slot weapons are: DogBroadSword, DogHammer
- Supported big stick slot weapons are: staffbasic, DogGlaive, DogSpear, RabbitCatcher

[b]KnockbackMlt is now also applied on blocked hits.[/b]

[b]Leaders are now granted a shiny crown.[/b]

[b]On screen text can now be separately colored.[/b]

[b]Added new hotspots to use for mappers:[/b]
- charCatapultHotspot: Used to create jump pads, catapults and trampolines for players.
- teleporterHotspot: Used to create portals.
- flagHotspot and flagReturnHotspot: These two can be used to create some gameplay based on gathering/returning flag. (comes with a flag item)
- staticObjectAnimatorHotspot: allows you to animate static objects. (additionally you can use scripts for extracting animation frames from blender included here: https://github.com/OsaPL/Versus-Brawl/tree/main/Scripts/extractAnim)

[b]Big changes for mappers/modders:[/b]
- Added some test maps for experimentation with hotspots/scripts
- Hotspots now highlight when selected
- ...and also get more transparent when disabled
- Suicide now available for all gamemodes
- Not counted kills will now trigger SuicideDeath event
- Leader crown now also available for all gamemodes
- All hotspots are now available in the spawner category 'VersusBrawl'
- Points UI is now generic and you can use it in any gamemode or even extend it
- Versus-Brawl UI no longer displays while in editor mode
- More options for fps optimization added to objectFollowerEmmiter and waterRiseHotspot (see modding docs)
- objectFollowerEmmiter now also has a editor mode placeholder to help with visibility
- All hotspot placeholder texts now only show up within a distance of the camera
 
[b]Fixes:[/b]
- Hotspots should now check the paths before trying to load a file.
- Coop panic now doesnt work on "gamemode == versusBrawl" tagged maps
- Coop now uses Duplicate object to more accurately recreate coop players
- Reduced number of logs.
- Reverted the throw change on dog for the time being
- Fixed funnies not triggering
- You now cant suicide during you respawn invincibility
- Point counters not disappearing on round end
- Some hints have been removed, and some have been reworded
- Preloading should be faster, will now spawn a static dummy to preload everything on, instead of a real character

[b]Mapping and modding docs update.[/b]
Docs have been extended and a lot more things are now documented. With this update I've tried to document everything new.
Any feedback will be appreciated.

Please report any problems.

### For changelogs
`git log <hash>..HEAD --pretty=format:%s`

### To convert to stupid workshop bbcode
https://md2bb.mizle.net/

### Some balancing notes:
Wolf shouldnt be able to one hit kill dog

wolf is weak vs weapons

cat is glass cannon, good vs lower hp rabbit and rat

rat is great for pushing opponents

rabbit should be only faster than dog and wolf on horizontal spaces

### Playtesting sessions notes:

`=>` is a decided task,
`?` probably needs more testing/thinking

- session #1 (mostly blocks, 3 players) 11 Oct

wolf is in a surprisingly good place, maybe make attack or movement speed slightly higher?

rat is kinda annoying on maps with hazards, good, tis the way of the rat

cats feel weak, even with high movements and attack speeds, buff them a little?

rabbits feel now better that default, maybe even a slight dmg nerf is needed still

nobody played dog, other than to counter wolf, maybe hes too weak against other species? maybe he feels sluggish and underpowered when comparing to wolf?

- session #2 (cave, block and planks, 4 players) 23 Oct

rock a little to easy to camp on  => longer respawn, shorter active time (done)

wolf a little to hard to kill? =? decrease slightly attack speed and resistance (done)

wolf op on planks => maybe allow species to be blocked per map?

cave - swap healing with rock, and make the rock powerup place more hostile (more ways to die)?

planks - you can get on top of the tower things => lower planks (done)

- session #3 (2 and 4 players, laggy as hell (over sea remote play), a little on cave, a little of planks, lots of time on blocks) 24 Oct

People seem to enjoy blocks alot => create more simple and small arenas

cave is a little too dark => marginally lighten it up (done)

fights a little to fast? increase hp all over the board?

No instructions on how to do lots of things. => add warmup hints (important), and ingame hints (less important), start game explanation for LBS ("Be the last one standing.")

The shortnames for modes are cryptic => seperate gamemodes into folders?

- session #4 (2 players, nidhogg prototype/purple waters)

two ppl die in water == softlocked spawning => no idea why, added a `awake` check on removing the invincibility, if still dead, we try to respawn him again => was a bug in respawning logic after new round starts

wolf still awful?

suicide timer lower tiny bit => now is 0.7f

annoying that ppl spawn in front of you and kill you?

particles/billboards not visible sometimes? => hopefully fixed? (looks like it only happens sometimes, and not for all cameras) => caused by a reflection probed, and only for 2nd player

- session #5-8 (2,3,4 players, nidhogg prototype/purple waters, some DM on blocks/planks)

last part is a fun idea, but is too short to do anything in it, platforms to small => will make them much bigger, and part longer

lots of waiting for another person to jump => add more options for on ground passing, less single way gaps

blocks is still the most fun DM map :)

- session #9 (2 players, purple dreams)

garden part pretty, but not that interesting gameplay wise

teleports and branching routes are highly appreciated and apparently a fun addition

the boards under the cloudy part, equally annoying and funny? I'll keep them for time being

### Scuffed things (that are probably bugs in OG) that need to get reported:
- Level params are unusable for other values than string (float are getting converted to ints, sliders crash the game etc.)
- You can spawn an object in code with `CreateObject("object.xml", /* save object: */ false);` and still connect stuff to it in editor.
- `Input` class crashes when it tries to ask for input pressed for a player that got spawned, but not yet acquired a controllerId (probably why, didnt get much deeper into it, still, its easy to reproduce)
- Why `AssetManager` is not exposed to `as_context`?! >:(
- Death event message is called so many times on a single death, its actually clogging up the pipe for other (time sensitive) messages (probably is called each frame a character is dead?)
- `Load Item...` menu entry sometimes occupies the same place as `Load` making clicking on `Load` also click on `Load Item...`. (just include Gyrth Object Menu mod cowards)
- `DebugDrawBillboard` has wrong TEXTURE_WRAP setting, which makes the texture bleed on top sometimes (`GL_CLAMP_TO_EDGE` should help?)
- `SetEditorLabel` only works for placeholder objects
- holding a `JSONValue` as a global var sometimes just crashes games (easiest way to reproduce is just to keep reloading the level script)
- `<ModDependency>` does nothing, probably missing checks on UI part
- You cant attach an object to a bone from as script (you can but its hella complicated to do atm)
- `vec4` cant access `w` param (`a` works tho), cant do `vec4 * float`
- Setting, then comparing global custom enums, crashes the game?
- 2nd player camera (ONLY 2nd is affected. 1st, 3rd and 4th work just fine) will stop rendering billboards if there is a global reflection probe present (to fix needs a full game restart, after removal of the probe)
- `SetTranslation` is more costly to call, the more envObjects you have in the level (cause it recalculates physics everytime, apparently better on internal_testing?)