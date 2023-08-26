# Versus-Brawl
## THE Overgrowth Versus mode overhaul
I had a dream mod I wanted to make 6 yrs ago, and I didnt really try to make it. I've done a basic [4 player mod](https://forums.wolfire.com/viewtopic.php?f=16&t=40260&p=245753&hilit=4+players#p245753), and called it a day.

After dusting it off, and having a complete blast with my buddies, I decided now is the time.

No more wonky scripts, no more boring maps, no more rabbits (<sub>okay few rabbits can stay</sub>), no more maps that are hard to create.

I say, slash, bonk, impale and do whatever else you want to do with your friends (<sub>ew, not that, gross</sub>).

This award-winning mod, got you covered.

*Pro tip: I really recommend using Steams Remote Play Together.*

# Quick disclaimer:
Some of the functionality will come eventually, once I have laid the foundation by developing these features.
**Anything marked by 👻 is missing atm.**

# Features
- 2/3/4 player support, with UI help and gamepad support
- Play Coop on any level (levels support vary, relies on map makers)
- Respawn/teleport button for coop partners.
- Ability to change species, with each character having different stats and a unique trait
- Players should no longer get their Id swapped, resulting in gamepads being always correctly arranged
- New maps that arent just a gm_flatgrass, designed for game modes
- Only a single level script and few basic prefabs needed to create a map. You can have a map ready in matter of minutes.
- Ability to modify many parameters, for characters, gamemodes and maps.
- Warmup before the game start (with preloading for smoother gameplay)
- Easy to extend with new gamemodes (with even more options coming)
- Pickup wacky powerups and be able to add your own with only few lines of code (👻need to create a better template for external use and add some documentation)
- SuperEasy<sup>TM</sup> to extend with new races (👻mostly true, but there are still few hardcoded places)
- Randomized character apperance (👻almost completely done, missing some variants, colors look whack sometimes)
- Custom weapons and ability to carry big weapons on your back
- 👻NPC opponents support (this will rely on map maker to implement detailed paths)

# FAQ

1. **How do I swap characters?**

For each player its always `drop` and `item` key together, then press `attack` to switch to next.
The UI should start showing you different species icons, if its not the gamemode doesnt allow it. 
Some gamemodes only allow for next round change while game is in progress.

2. **How do I select amount of players?**

Go to the `Settings -> Game -> Local Players`.

3. **How do I enable coop on a level?**

Just set `Local Players` to desired value.
Each coop partner can also press `skip_dialogue` button to respawn at 1st player.

Not all levels are supported. Please, dont message me if its incompatible, you should let the mapper know. If you're a mapper and want to make your level compatible, message me and I'll help (or even add in missing stuff)
[There is a helpful README for modders/mappers.](https://github.com/OsaPL/Versus-Brawl/blob/main/Adding%20maps%20and%20gamemodes%20README.md)

4. **What does `<action here>` key correspond to?**

For an XbOne gamepad its: 

`item` A
`drop` X
`attack` right trigger
`grab` left trigger
`crouch` right bumper
`jump` left bumper
`skip_dialogue` start

If you have other any gamepad, you're smart, I believe you'll figure it out.

5. **Gamepads not working/controlling one character/other stupid controller related bugs**

Make sure your gamepads are all connected before starting the map. If problem persists, try restarting the game. If the problem still occurs, try reassigning gamepads.

6. **The game sometimes crashes on spawning characters.**

Unfortunately, it looks like spawning in new characters and then setting `SetPlayer(true)` is sometimes unstable, probably correlated with input/controller_id. Can't do much about it rn.

7. **Fights are too fast!**

You can try changing the difficulty level to also slow down the game speed.

# Gamemodes:

- Last Bun Standing
  
Survivor gets the point

- Deathmatch

Gather kills to get points

- Coop

Play through campaign with friendsos.

- Race (👻mostly done, needed maps and balancing)
  
*self explanatory*

- Tag

Catchers needs to catch everyone

- Nidhogg

Fight and run to be the one who can become the best fighter/food.

- Capture the fur
  
Just CTF

** Important note: Gamemode list is a subject to change at any time. **

# Species:
*These are subject to change*

*I appreciate any balancing feedback!*

### Rabbits:
Slow on ground, but masters of vertical spaces. 
The mid air rabbit kick provides them with a dangerous, but also powerful way to engage.

**Trait**: Rabbit binkies - Midair powerful attack

### Dogs:
Sluggish but strong and sturdy. They can withstand a lot of damage, while also being always prepared with many weapons on them.

**Trait**: Good boi - Can holster long and heavy weapons on his back

### Cats:
Fast and fragile. Can move and attack really fast, but are the most vulnerable.

**Trait**: Always lands on its feet - Catches weapons automatically

### Rats:
Kings of on ground movement. Even though their hits are not heavy, they are great for players looking for ways to create guaranteed win situations.

**Trait**: Cant be stomped - knockout shield

### Wolf:
Powerful and slow. They require specific methods to kill, otherwise they can become a menace, just killing everything on its way.

**Trait**: Pounces on you - sharp claws, unblockable, cant use weapons (still can defend by grabbing incoming ones)

# Powerups

- **Ninja** (dark smoke) - Have an infinite supply of knives to throw (hands must be free)
- **Heal** (green poof) - Heals all damage
- **Rock** (blue sparks) - Gives high damage resistance
- **Yeet** (yellow dots) - Next direct hit (expires after `activeTime`) will launch enemy really hard
- **Firefists** (red flames) - hitting an enemy with fists ignites him
- **Virus** (aqua cloud) - being close to an enemy inverts his controls (movement inverted, attack and defend, grab and item, crouch and jump switched)

# Known problems
**Dont report these, I know :)**

## To be fixed 
(or atleast to try to fix)
- Rock powerup can sometimes save you from dying from `genericKillHotspot` (dont use on maps where you need to kill players using that)
- Level specific `SpeciesStats` will not be set for the first spawn
- for 2 players the UI still stays the same as for 3/4 players setup
- most of the UI stuff is filled with placeholders atm
- Some level parts with moving platforms can tank fps a little

## Not planned
(wont be fixed for the time being)
- Coop partners sometimes bug out under the ground/behind walls whenever its cramped (depends on map makers to accomodate)
- maps stutter after load (preloading is done after level load since `AssetManager` is not available in `as_context`)
- UI gets wonky on weird resolutions (standard aspects like 16:10, 16:9, 4:3 all work, to fix, migration to imgui is probably needed)
- Switching character while unsheathing a weapon, cancels the animation (and the animation event), thus locking player ability to unsheathe into that slot (OG aschar.as bug, probably fixable)

# Thanks to:
[WolfireGames](https://github.com/WolfireGames) - for being awesome developers (source code helped me a lot)

[Surak](https://github.com/Surak) - for [Timed-Execution](https://github.com/EmpSurak/Timed-Execution) simplified A LOT of my code

[Gyrth](https://github.com/Gyrth) - for showing me not documented stuff

[constance](https://steamcommunity.com/sharedfiles/filedetails/?id=1525405745) - for pumpkins (cave_map)

[yanwangken](https://steamcommunity.com/profiles/76561198307136622) - for helping me fix 2 handed back sheath positions

Jukucz, Naxer, Dante, Emperot and DemonAngel - for playtesting this shit

WhaleMan - 🐋 Praise the WhaleMan 🐋