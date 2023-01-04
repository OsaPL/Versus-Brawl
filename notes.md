# DO THOSE THINGS:
- get rid of that stupid limitation of: `respawnTime cant be smaller than activeTime` on powerupBase
- make winner/crown logic generic (move it to the versusBase) and support multiple winners (for teams update)
- NIDHOGG gamemode!
- add checkmarks or something to race goal to show you've already hit them
- extend `powerUpBase.as` to allow more than a single particle emitter
- `poleFlagItem` will animate legs moving after hitting someone

# Maybe, Maybees, Maybies?
- for simple arrays, I should just use `int find(const T& in)`
- enable/disable hints ingame by using a key combo

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
- `vec4` cant access `w` param (`a` works tho), cant do `vec4 * float`
- Setting, then comparing global custom enums, crashes the game?