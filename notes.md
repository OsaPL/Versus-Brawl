# DO THOSE THINGS FIRST:
- add checkmarks or something to race goal to show you've already hit them
- extend `powerUpBase.as` to allow more than a single particle emitter
- enable/disable hints ingame by using a key combo
- for simple arrays, I should just use `int find(const T& in)`

[h1]0.5 update notes:[/h1]
[b]New gamemodes: [/b]
- Tag - catch or kill, doesnt matter that much
- Race - first to get to all checkpoints wins

[b]Coop is now much more stable, also added a `panic` button to increase compatibility.[/b]
- Pressing `skip_dialogue` button will return you to the player 1, and revive if needed.

[b]Cooler map names [/b]
[b]Added new fully playable maps: [/b]
- Gods Exile (tag only for now)
- Imperial Sewers (dm)

[b]Reworked Dank Cave:[/b]
- More routes for lower jumping characters
- The back part (around spear spawn) changed, to give an incentive for routes/fights there

[b]New powerups: [/b]
- Toxic cloud - inverts all controls for those affected
- Power slap - increases power of your next blunt hit
- Fire fists - your fists now ignite

[b]All old powerups have received touchups to feedback and effects:[/b]
- All of them now emit colored auras!
- Rock powerup now has a tiny sparkling particles, and when hit, will give rock hit sounds
- Ninja powerup now has a feedback sound on each dagger hit

[b]A new hints system that helps to understand some more cryptic mechanisms and controls[/b]
- Enabling `Tutorials` in `Game` Settings will give you more hints that could be helpful.
- All hints will now show keyboard/mouse bindings if they’re being used

[b]Fixed TONS OF BUGS:[/b]
- Im adding this sub point only to emphasize how many bugs were removed.
- Like holy hell, it was alot.

[b]Made editor experience for mappers much smoother
Few new tools for mappers to use:[/b]
- waterRise/Phase hotspots, for phase based platforms or just to animate bobbing/floating objects
- Added a whole new configuration system for mappers (or basically anyone) to be able to modify gameplay as they please

[h1]0.5.2:[/h1]
[b]Blocks map changes:[/b]
- Swapped ninja powerup to power slap.
- Small layout changes (planks are less obstructing, powerup is now in a more fun/risky spot)
 
[b]Heal powerup now uses a better particle, to make understanding the effect easier.[/b]

[b]Camera now reorients itself on respawn.[/b]

[b]Player spawns will now show the direction while in Editor.[/b]

[b]Changing "Local Players" will now automatically reload level if needed.[/b]

[b]Deathmatch:[/b]
- Leaders have their scores now highlighted.
- Anyone who is missing only a single point, will have its score also animated

[b]Fixed some bugs:[/b]
- Runners in TAG now should respawn more than once
- Hints in TAG should now correctly display (less flickering)
- Coop partners sometimes spawn under ground
- Wolves using wrong color layers
- Sewers having buggy spawns, that sometimes spawn you under water
- Reworked how WaterRise/Phase hotspots handle resets
- Spawn orientations on some maps fixed
- Coop now supports `set_dialogue_position`, making so all characters are teleported on dialogue event

### For changelogs
`git log <hash>..HEAD --pretty=format:%s`

### To convert to stupid workshop bbcode
https://md2bb.mizle.net/

### Some balancing notes:
Wolf shouldnt be able to one hit kill dog

wolf is weak vs weapons

cat is glass cannon, good vs lower hp rabbit and rat

rat is great for pushing opponents

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

### Scuffed things (that are probably bugs in OG) that need to get reported:
- Level params are unusable for other values than string (float are getting converted to ints, sliders crash the game etc.)
- You can spawn an object in code with `CreateObject("object.xml", /* save object: */ false);` and still connect stuff to it in editor.
- `Input` class crashes when it tries to ask for input pressed for a player that got spawned, but not yet acquired a controllerId (probably why, didnt get much deeper into it, still, its easy to reproduce)
- Why `AssetManager` is not exposed to `as_context`?! >:(
- Death event message is called so many times on a single death, its actually clogging up the pipe for other (time sensitive) messages (probably is called each frame a character is dead?)
- `Load Item...` menu entry sometimes occupies the same place as `Load` making clicking on `Load` also click on `Load Item...`. (just include Gyrth Object Menu mod cowards)
- `DebugDrawBillboard` has wrong TEXTURE_WRAP setting, which makes the texture bleed on top sometimes (`GL_CLAMP_TO_EDGE` should help?)
- `SetEditorLabel` only works for placeholder objects
- using `JSONValue` sometimes just crashes games (easiest way to reproduce is just to keep reloading the level script)
- `<ModDependency>` does nothing, probably missing checks on UI part
- You cant attach an object to a bone from as script 