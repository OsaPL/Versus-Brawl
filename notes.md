# Npc players problems:
2. There is some logic in `pointUIBase.as` that needs to get seperated, to UI and Gameplay flows (see: `playersUI` variables)
3. Try adding `params.SetInt("Stick To Nav Mesh", 1);` on spawn, maybe it will help? If so make it configurable per map.
4. Maybe add this^ as a toggleable `Baby mode` to guard ppl from dropping?

# Arena mode:
0. RETHINK SPAWNING?
   - We need rules in place to define how spawning should work
     - We probably want to spawn all enemies from same Enemy entry at the same point
     - to split them, just create new entry (maybe a new entry "forceSplit" to if you want to split an enemy entry?)
     - if we want a named spawn, we do the same as above, but available spawns pool is always filtered by name
     - ? What do we do if all spawns left are not named as we want to? Do we just reset all, or just find all the named ones and re-add them?
1. Document `npcSpawner` and `sliding` hotspots
2. Finish rainy arena
3. Finish the lava tower map, create that space race map.

# DO THOSE THINGS:
- `speed` on staticAnimator should also work for frames (in integer form only for > 1), 2x is "skip a frame", 0.5x is "render frame two times" etc
- big weapons that support sheathing should be seperated into Versus brawl probably, instead of overwriting the stock weapons
- organise all scripts/objects better
- create a generic thing for managing and "switching" objects (gut out what is already done in `waterRiseHotspot`?)
- get rid of that stupid limitation of: `respawnTime cant be smaller than activeTime` on powerupBase

# Maybe, Maybees, Maybies?
- for simple arrays, I should just use `int find(const T& in)`
- enable/disable hints ingame by using a key combo
- extend `powerUpBase.as` to allow more than a single particle emitter

# Sheathed weapons:
Big blades:
- `DogBroadSword`
- `DogHammer`
- `Bastard`

Big sticks:
- `staffbasic`
- `DogGlaive`
- `DogSpear`
- `RabbitCatcher`


[h1]0.8:[/h1]
You can now play without friends! This only sounds slightly sad. Now anyone can try this mayhem.
With this update also comes ability to customize the games to the way you like it.
Also, Arena mode... What? Are you not entertained? Ok, here are the rest of the changes:

[b]Added npc support![/b]
- The support vary on a per map basis, since some layouts are more friendly for them to navigate
- In next (smaller) update I'll fix up older maps, and tweak some values for smoother experience

[b]Games can now be customized![/b]
- You can now change tons of parameters for the levels
- All these, can be made custom, have limits etc. for ease of map making

[b]Added Arena gamemode![/b]
- Your objective is to kill everyone, or to just survive
- Lots of customisable parameters for map makers, regarding waves, enemies, spawnpoints and more

[b]Added new playable maps:[/b]
- Ominous Call, Race
- Return to Stucco, Arena
- Bloody Mist, Arena
- (WIP) Lava Tower, Race

[b]Map fixes/balance changes[b]
- Reworked collisions on older maps, should be much smoother to move around
- Gods Exile, now has giant chains, to make traversing it for more "grounded" characters easier
- Sewers now have some environment ambience

[b]2 handed weapons are now smoother and less janky:[/b]
- Sheathing, unsheathing animations and placement on the back fixed
- Thanks to [b]yanwangken[b] for helping with sheathe points anims!
- More weapons now supported!

[b]Powerups can now be marked as one use only[/b]
- They can be refreshed by sending a "RefreshPowerup" event message to hotspot by a map maker
- or by sending a level wide "RefreshAllPowerups" event message
- Also added a new powerup that can be setup to do both of these things

[b]New quick and easy to use Rotation Hotspot[/b]

[b]WaterRise hotspots now can have both idle and rising sound loops[/b]

[b]Added RaceWarmupHotspot to enable/disable elements depending if players are in warmup or not[/b]

[b]Player controlled characters are no longer almost mute[/b]
- TODO! Is controlled by "Player voices" option in Audio menu

[b]Completely new sliding hotspot, for sliding in style[/b]
- Can be used in any direction, surf maps incoming?d

[b]Fixes:[/b]
- <fill me>

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