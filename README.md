# Versus-Brawl
## THE Overgrowth Versus mode overhaul
I had a dream mod I wanted to make 6 yrs ago, and I didnt really try to make it. I've done a basic 4 player mod, and called it a day.

After dusting it off, and having a complete blast with my buddies, I decided now is the time.

No more wonky scripts, no more boring maps, no more rabbits (<sub>okay few rabbits can stay</sub>), no more maps that are hard to create.

I say, slash, bonk, impale and do whatever else you want to do with your friends (<sub>ew, not that, gross</sub>).

*Pro tip: I really recommend using Steams Remote Play Together.*

# Quick disclaimer:
There are things missing atm:
- Respawn system is not yet completed (still a little wonky, missing a more generic spawn code)
- No ability to team up
- No modifications to the default character scripts
- Missing elements for new gamemodes implementation

Some of the functionality will come eventually, once I have laid the foundation by developing these features.
**Anything marked by 👻 is missing atm.**

# Features
- 2/3/4 player support, with UI help and gamepad support
- Ability to change species, with each character having different stats and a unique trait
- Players should no longer get their Id swapped, resulting in gamepads being always correctly arranged
- Two maps that arent just a gm_flatgrass (👻6 planned, atleast 1 per mode)
- Only a single level script and few basic prefabs needed to create a map. You can have a map ready in matter of minutes.
- Warmup before the game start
- Easy to extend with new gamemodes (with even more options coming)
- `F8` now does a hard-reload of the map (this saved me EONS of time)
- 👻SuperEasy<sup>TM</sup> to extend with new races (mostly true, but there are still few hardcoded places)
- 👻Randomized character apperance (almost completely done, missing some variants, colors look whack sometimes)
- 👻NPC opponents support (this will rely on map maker to implement detailed paths)

# FAQ

1. **How do I swap characters?**

For each player its always `drop` and `item` key together, then press `attack` to switch to next.
The UI should start showing you different species icons, if its not the gamemode doesnt allow it. 
Some gamemodes only allow for next round change while game is in progress.
2. **How do I select amount of players**

I mean, its on the screen but ok. Player nr 1 has to hold `item` key and press corresponding buttons for players number.
`crouch` for 2 players
`jump` for 3 players
`attack` for 4 players
3. **Gamepads not working/controlling one character/other stupid controller related bugs**

Make sure your gamepads are all connected before starting the map. If problem persists, try restarting the game. If the problem still occurs, try reassigning gamepads.

4. **What does `<action here>` key correspond to?**

For an XbOne gamepad its: 

`item` A
`drop` X
`attack` right trigger
`grab` left trigger
`crouch` right bumper
`jump` left bumper

If you have other any gamepad, you're smart, I believe you'll figure it out.

# Gamemodes:

- Last Bun Standing
  
Survivor gets the point

- 👻Race (mostly done, needed maps and balancing)
  
*self explanatory* On each checkpoint, everyone but 1st place, gets a knife to throw.

- 👻Deathmatch (mostly working, weapon respawn mechanics are still needed)

Gather kills to get points

- 👻Tag

Catchers needs to catch everyone

- 👻Sacrifice
  
Each enemy body thrown to your abbys, gives a point, your body in your abbys takes back two.

- 👻Capture the fur 
  
Just CTF

** Important note: Gamemode list is a subject to change at any time. **

# Species:
*These are subject to change*

*I appreciate any feedback!*

## Rabbits:
- Att dmg:5/10 (no change) 
- Att knockback:5/10 (no change)
- Att speed:5/10 (no change)
- Damage resistance:4/10 (5/10)
- Movement speed:4/10 (5/10)
- Jump height:10/10 (no change)
- Size: 4/10 (5/10)

Trait: Rabbit binkies - Midair powerful attack

Dogs:
- Att dmg:6/10 (5/10) 
- Att knockback:6/10 (5/10)
- Att speed:4/10 (5/10)
- Damage resistance:6/10 (5/10)
- Movement speed:4/10 (5/10)
- Jump height:5/10 (no change)
- Size: 6/10 (5/10)

Trait: Whos a good swordsman? - Cant be disarmed, 👻cant block with weapon

Cats:
- Att dmg:5/10 (no change)
- Att knockback:3/10 (5/10)
- Att speed:6/10 (5/10)
- Damage resistance:3/10 (5/10)
- Movement speed:6/10 (5/10)
- 👻Jump height:7/10 (5/10)
- Size: 5/10 (no change)

Trait: Always lands on its feet- No dmg from falls

Rats:
- Att dmg:3.5/10 (5/10)
- Att knockback:7.5/10 (5/10)
- Att speed:6/10 (5/10)
- Damage resistance:4/10 (5/10)
- Movement speed:7/10 (5/10)
- 👻Jump height:6/10 (5/10)
- Size: 3.5/10 (5.10)

Trait: Cant be stomped - knockout shield (set to 1)

Wolf:
- Att dmg:8/10 (10/10) 
- Att knockback:6/10 (5/10)
- Att speed:3/10 (5/10)
- Damage resistance:6/10 (5/10)
- Movement speed:3.5/10 (5/10)
- Jump height:5/10 (no change)
- Size: 7/10 (5/10)

Trait: Pounces on you - sharp claws, cant use weapons (still can defend by grabbing incoming ones)

# Small bugs (dont report these, I know :) )
- clothing colors may look wonky, low priority
- changing anything in the script, causes ui to bug out (my fault, probably global script variables are being cleared)
- for 2 players the UI still stays the same as for 3/4 players setup
- most of the UI stuff is filled with placeholders atm
- going from warmup to game can scramble controlerIds if you didnt select 4 players (add pre warmup to select number of players?)

# Download and instalation
## WIP mod

# Thanks to:
[WolfireGames](https://github.com/WolfireGames) - for being awesome developers (source code helped me a lot)

[Surak](https://github.com/Surak) for [Timed-Execution](https://github.com/EmpSurak/Timed-Execution) simplified A LOT of my code

Jukucz, Naxer, Dante, Emperot and DemonAngel - for playtesting this shit

WhaleMan - Praise the WhaleMan

