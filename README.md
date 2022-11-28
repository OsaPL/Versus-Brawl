# Versus-Brawl
## THE Overgrowth Versus mode overhaul
I had a dream mod I wanted to make 6 yrs ago, and I didnt really try to make it. I've done a basic [4 player mod](https://forums.wolfire.com/viewtopic.php?f=16&t=40260&p=245753&hilit=4+players#p245753), and called it a day.

After dusting it off, and having a complete blast with my buddies, I decided now is the time.

No more wonky scripts, no more boring maps, no more rabbits (<sub>okay few rabbits can stay</sub>), no more maps that are hard to create.

I say, slash, bonk, impale and do whatever else you want to do with your friends (<sub>ew, not that, gross</sub>).

This award-winning mod, got you covered.

*Pro tip: I really recommend using Steams Remote Play Together.*

# Quick disclaimer:
There are things missing atm:
- No ability to team up
- No big modifications to the default character scripts
- Missing elements for new gamemodes implementation

Some of the functionality will come eventually, once I have laid the foundation by developing these features.
**Anything marked by 👻 is missing atm.**

# Features
- 2/3/4 player support, with UI help and gamepad support
- Play Coop on any level (levels support vary, relies on map makers)
- Respawn/teleport button for coop partners.
- Ability to change species, with each character having different stats and a unique trait
- Players should no longer get their Id swapped, resulting in gamepads being always correctly arranged
- New maps that arent just a gm_flatgrass, designed for game modes (👻6 planned, atleast 1 per mode)
- Only a single level script and few basic prefabs needed to create a map. You can have a map ready in matter of minutes.
- Ability to modify many parameters, for characters, gamemodes and maps.
- Warmup before the game start (with preloading for smoother gameplay)
- Easy to extend with new gamemodes (with even more options coming)
- Pickup wacky powerups and be able to add your own with only few lines of code (👻need to create a better template for external use and add some documentation)
- SuperEasy<sup>TM</sup> to extend with new races (👻mostly true, but there are still few hardcoded places)
- Randomized character apperance (👻almost completely done, missing some variants, colors look whack sometimes)
- 👻NPC opponents support (this will rely on map maker to implement detailed paths)

# FAQ

1. **How do I swap characters?**

For each player its always `drop` and `item` key together, then press `attack` to switch to next.
The UI should start showing you different species icons, if its not the gamemode doesnt allow it. 
Some gamemodes only allow for next round change while game is in progress.

2. **How do I select amount of players?**

Go to the `Settings -> Game -> Local Players`.

4. **How do I enable coop on a level?**

Just set `Local Players` to desired value.
Each coop partner can also press `skip_dialogue` button to respawn at 1st player.

Not all levels are supported. Please, dont message me if its incompatible, you should let the mapper know. 
[There is a helpful README for modders/mappers.](https://github.com/OsaPL/Versus-Brawl/blob/main/Adding%20maps%20and%20gamemodes%20README.md)

3. **What does `<action here>` key correspond to?**

For an XbOne gamepad its: 

`item` A
`drop` X
`attack` right trigger
`grab` left trigger
`crouch` right bumper
`jump` left bumper
`skip_dialogue` start

If you have other any gamepad, you're smart, I believe you'll figure it out.

4. **Gamepads not working/controlling one character/other stupid controller related bugs**

Make sure your gamepads are all connected before starting the map. If problem persists, try restarting the game. If the problem still occurs, try reassigning gamepads.

5. **The game sometimes crashes on spawning characters.**

Unfortunately, it looks like spawning in new characters and then setting `SetPlayer(true)` is sometimes unstable, probably correlated with input/controller_id. Can't do much about it rn.

6. **Fights are too fast!**

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

- Tag (👻done, needs maps)

Catchers needs to catch everyone

- 👻Sacrifice
  
Each enemy body thrown to your abbys, gives a point, your body in your abbys takes back two.

- 👻Capture the fur 
  
Just CTF

** Important note: Gamemode list is a subject to change at any time. **

# Species:
*These are subject to change*

*I appreciate any balancing feedback!*

### Rabbits:
- Att dmg:5/10 (no change) 
- Att knockback:5/10 (no change)
- Att speed:5/10 (no change)
- Damage resistance:3.5/10 (5/10)
- Movement speed:4/10 (5/10)
- Jumps: Even higher and far, but not that fast
- Size: 4.5/10 (5/10)

**Trait**: Rabbit binkies - Midair powerful attack

### Dogs:
- Att dmg:6/10 (5/10) 
- Att knockback:6/10 (5/10)
- Att speed:4/10 (5/10)
- Damage resistance:6/10 (5/10)
- Movement speed:4/10 (5/10)
- Jumps: Pretty high, but not far
- Size: 5/10 (no change)

**Trait**: Now you catch! - throws weapons much harder

### Cats:
- Att dmg:5/10 (no change)
- Att knockback:3/10 (5/10)
- Att speed:6/10 (5/10)
- Damage resistance:2.5/10 (5/10)
- Movement speed:6/10 (5/10)
- Jumps: Pretty low, but far and fast
- Size: 5/10 (no change)

**Trait**: Always lands on its feet - No dmg from falls, catches weapons automatically

### Rats:
- Att dmg:3.5/10 (5/10)
- Att knockback:7.5/10 (5/10)
- Att speed:6/10 (5/10)
- Damage resistance:4/10 (5/10)
- Movement speed:7/10 (5/10)
- Jumps: Really low but really fast
- Size: 4.5/10 (5.10)

**Trait**: Cant be stomped - knockout shield

### Wolf:
- Att dmg: 1.5/10 (10/10) 
- Att knockback:3.5/10 (5/10)
- Att speed:2/10 (5/10)
- Damage resistance:5/10 (no change)
- Movement speed:2.5/10 (5/10)
- Jumps: Slightly higher that dog, but slower and shorter
- Size: 5/10 (no change)

**Trait**: Pounces on you - sharp claws, cant use weapons (still can defend by grabbing incoming ones)

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

## Not planned
(wont be fixed for the time being)
- Coop partners sometimes bug out under the ground/behind walls whenever its cramped (depends on map makers to accomodate)
- maps stutter after load (preloading is done after level load since `AssetManager` is not available in `as_context`)
- clothing colors may look wonky, low priority
- UI gets wonky on weird resolutions (standard aspects like 16:10, 16:9, 4:3 all work, to fix, migration to imgui is probably needed)
- Holding a global JsonVALUE just crashes the game during script load sometimes (maybe just load the file when needed?)
# Thanks to:
[WolfireGames](https://github.com/WolfireGames) - for being awesome developers (source code helped me a lot)

[Surak](https://github.com/Surak) - for [Timed-Execution](https://github.com/EmpSurak/Timed-Execution) simplified A LOT of my code

[constance](https://steamcommunity.com/sharedfiles/filedetails/?id=1525405745) - for pumpkins (cave_map)

[Gyrth](https://github.com/Gyrth) - for showing me not documented stuff

Jukucz, Naxer, Dante, Emperot and DemonAngel - for playtesting this shit

WhaleMan - 🐋 Praise the WhaleMan 🐋