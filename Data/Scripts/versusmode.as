#include "ui_effects.as"
#include "music_load.as"
#include "ui_tools.as"

#include "speciesStats.as"
#include "colorHelpers.as"

#include "versus-brawl/save_load.as"

#include "timed_execution/timed_execution.as"
#include "timed_execution/char_death_job.as"
#include "timed_execution/level_event_job.as"

array<string> insults = {
    "For sure not thanks to always hogging all the weapons...",
    "ez, gg no re",
    "Maybe you should try Tai Chi instead.",
    "You should try turning on `Baby Mode`.",
    "vidja gams are hart",
    "Are you guys still playing?",
    "Oooh! That's gonna leave a mark!",
    "You play like my frickin grandma, y'know that?",
    "Quick! Blame the controls!"
};

// This is my fun corner
array<string> funnies = {
    "Do you ever dream about @vec3(1,0.5,0)cheese?@",
    "There are no bunkers, but still its frickin great.",
    "Have you heard of the high cats?",
    "@vec3(1,0,0)HELP!@ They took me hostage to keep me writing these!",
    "I liked the part where you just fell down.",
    "@vec3(0,0.5,1)This is a test hint, no need to panic.@",
    "Play @vec3(1,0.8,0)Skatebird@, the most wholesome game.",
    "This is more fun than picking up bullets from ground.",
    "I like my hints, like my girls, rare. Wait, no.",
    "My favorite class is the rat.",
    "Imagine having turned off `Tutorials`, and not seeing this.",
    "You are looking beautiful today :)"
};

// TODO! Add cases when which should be used (only use first two if `blockSpeciesChange==false` etc.)
array<string> warmupHints = {
    "Hold @vec3(1,0.5,0)@drop@@ and @vec3(1,0.5,0)@item@@ to activate character change...",
    "...then just press @vec3(1,0.5,0)@attack@@ to cycle through them.",
    "If your character wont change right now, it will on next respawn.",
    "Weapons will respawn after not being picked back up.",
    "Violet powerup is ninja mode, infinite throwing knife, just hold @vec3(1,0.5,0)@item@@.",
    "Blue powerup makes you sturdy as a rock.",
    "Green powerup will heal all your wounds.",
    "You can enable hints during game by turning on @vec3(0.6,0.6,0.6)Tutorials@ option in Settings"
};

// TODO! These will be scrambled
array<string> randomHints = {
    "Horizontal mobility is great, but cats and rats can dominate vertical spaces.",
    "Try using @vec3(1,0.5,0)@jump@@ as a dash, while playing cat or rat.",
    "You can disable these hints by disabling @vec3(0.6,0.6,0.6)Tutorials@ option in settings.",
    "Dogs are resilient, can withstand more punishment than other races.",
    "Wolves are a great target for sharp weapons.",
    "Wolves are slow, if they're about to attack, run.",
    "Rabbit kick is sometimes what a cheeky wolf needs.",
    "Fighting a wolf bare handed, probably not the best idea.",
    "Tired of getting things thrown at you? Be a cat!",
    "Holster weapons holding @vec3(1,0.5,0)@drop@@.",
    "Throwing a weapon does less damage than swinging it.",
    "You can time a @vec3(1,0.5,0)@grab@@ press to catch an thrown weapon.",
    "You can pull out a weapon stuck in a wolf, for a quick kill."
};

//Configurables
float respawnTime = 2.0f;
// This will block any stupid respawns calls from hotspots that kill on the way to spawn, higher values could help on bigger "trips"
float respawnBlockTime = 0.5f;
float spawnPointBlockTime = 5.0f;
bool constantRespawning = false;
bool useGenericSpawns = true;
bool useSingleSpawnType = false;
// Sets the lenght of victory state
float winStateTime = 10.0f;
// Starting species
int forcedSpecies = _rabbit;
// This blocks currentRace from being changed by player
bool blockSpeciesChange = false;
// This allows instant race change even during game (state>=2)
bool instantSpeciesChange = false;
bool enablePreload = true;
bool noReloads = false;
float maxCollateralKillTime = 5.0f;
float hintStayTime = 4.0f;
float suicideTime = 5;
bool crownEnabled = true;

// Team config
bool teamPlay = false;
int teamsAmount = 2;
bool allowUneven = false;
// TODO! Add team selection
bool allowTeamChange = true;
bool strictColors = false;

string crownObjectPath = "Data/Objects/versus-brawl/hotspots/leaderCrownHotspot.xml";

array<int> crownsIds = {};

// How often we want to make all char aware TODO! Fix up this?
float set_omniscientTimeSpan = 3.0f;
float set_omniscientTimer = set_omniscientTimeSpan;

//New UI Stuff
int playerIconSize = 100;
string placeholderRaceIconPath = "Textures/ui/challenge_mode/quit_icon_c.tga";

//States
int currentState=-1;
int winnerNr = -1;
float winStateTimer = 0;
array<float> suicideTimers = {0,0,0,0};

// For preloading characters
uint preloadSpeciesIndex = 0;
uint preloadIndex = 0;
int placeholderId = -1;
float placeholderTimer = 1;
bool preload = true;
int lastWinnerNr = -1;
int initPlayersNr;

string placeHolderActorPath = "Data/Objects/characters/rabbot_actor.xml";

// This controls whether to show keyboard and mouse keys
// last_mouse_event_time, last_keyboard_event_time and last_controller_event_time are using some kind of weird timer, not really compatible with what we have using `time_step`
// So we will just keep track, and if it increases, just restart our own timer
float ignoreKbMAfter = 2.0f;
float lastKbMInput = max(last_mouse_event_time, last_keyboard_event_time);
float scriptlastKbMInputTimer = 0;
// Hints system
float hintTimer = 0;
int currentHint = -1;
string lastHint = "";
bool hintBrake = false;
int funniesChance = 2; // out of 100
bool funniesActive = false;

VersusAHGUI versusAHGUI;
TimedExecution levelTimer;

array<SpawnPoint@> genericSpawnPoints = {};
array<VersusPlayer@> versusPlayers = {};

// All objects spawned by the script
array<int> spawned_object_ids;

class VersusPlayer{
    int playerNr;
    int objId;
    int teamNr;
    
    TimedExecution@ charTimer;
    
    int currentRace;
    
    bool respawnNeeded;
    float respawnQueue;
    array<SpawnPoint@> spawnPoints;

    VersusPlayer(int newPlayerNr){
        playerNr = newPlayerNr;
        objId = -1;
        teamNr = newPlayerNr;

        TimedExecution newCharTimer();
        @charTimer = @newCharTimer;
       
        // If lower than 0, just select random for each player
        if(forcedSpecies < 0){
            currentRace = rand()%speciesMap.size();
        }
        else{
            currentRace = forcedSpecies;
        }
        
        respawnNeeded = false;
        respawnQueue = -100;
        spawnPoints = {};
    }
    
    // TODO! These methods dont like being inside a class remove them
    Object@ SetObject(Object@ newObj){
        if(objId != -1){
            //TODO! Test whether this fucks up something regarding controllers
            
            newObj.SetPlayer(false);
            DeleteObjectID(newObj.GetID());
        }

        objId = newObj.GetID();

        return newObj;
    }
    
}

class SpawnPoint{
    int objId;
    float spawnPointBlockTimer;

    SpawnPoint(int newObjId){
        objId = newObjId;
        spawnPointBlockTimer = 0;
    }
}

class Species{
    string Name;
    string RaceIcon;
    array<string> CharacterPaths;
    Species(string newName, string newRaceIcon, array<string> newCharacterPaths){
        Name = newName;
        CharacterPaths = newCharacterPaths;
        RaceIcon = newRaceIcon;
    }
}
// This can be extended with new races
enum SpeciesInt {
    _rabbit = 0,
    _wolf = 1,
    _dog = 2,
    _rat = 3,
    _cat = 4
};

array<Species@> speciesMap={
    Species("rabbit", "Textures/ui/arena_mode/glyphs/rabbit_foot_1x1.png",
    {
            "Data/Characters/male_rabbit_1.xml",
            "Data/Characters/male_rabbit_2.xml",
            "Data/Characters/male_rabbit_3.xml",
            "Data/Characters/female_rabbit_1.xml",
            "Data/Characters/female_rabbit_2.xml",
            "Data/Characters/female_rabbit_3.xml",
            "Data/Characters/pale_rabbit_civ.xml"
    }),
    Species("wolf", "Textures/ui/arena_mode/glyphs/skull.png",
        {
            "Data/Characters/male_wolf.xml"
        }),
    Species("dog", "Textures/ui/arena_mode/glyphs/fighter_swords.png",
        {
            "Data/Characters/lt_dog_big.xml",
            "Data/Characters/lt_dog_female.xml",
            "Data/Characters/lt_dog_male_1.xml",
            "Data/Characters/lt_dog_male_2.xml"
        }),
    Species("rat", "Textures/ui/arena_mode/glyphs/slave_shackles.png",
        {
            "Data/Characters/hooded_rat.xml",
            "Data/Characters/female_rat.xml",
            "Data/Characters/rat.xml"
        }),
    Species("cat", "Textures/ui/arena_mode/glyphs/contender_crown.png",
        {
            "Data/Characters/fancy_striped_cat.xml",
            "Data/Characters/female_cat.xml",
            "Data/Characters/male_cat.xml",
            "Data/Characters/striped_cat.xml"
        })
};

///
///     This section contains the gamemode interface methods
///

//Requests a respawn for a player
//TODO! This shouldnt need objID, just playerNr
void CallRespawn(int playerNr, int objId) {
    VersusPlayer@ player = GetPlayerByNr(playerNr);
    if(!player.respawnNeeded && player.respawnQueue<-respawnBlockTime){
        player.respawnNeeded = true;
        player.respawnQueue = respawnTime;
        Log(error, "Respawn requested objId:"+player.objId+" playerNr:"+player.playerNr);
    }
}

// This creates a pseudo random character by juggling all available parameters
Object@ CreateCharacter(int playerNr, string species, int teamNr) {
    // Select random species character and create it
    int obj_id = CreateObject(placeHolderActorPath, true);
    string characterPath = GetSpeciesRandCharacterPath(species);

    // Remember to track him for future cleanup
    spawned_object_ids.push_back(obj_id);
    Object@ char_obj = ReadObjectFromID(obj_id);
    MovementObject@ char = ReadCharacterID(char_obj.GetID());
    ScriptParams@ charParams = char_obj.GetScriptParams();

    //You need to set Species param before SwitchCharacter(), otherwise `species` field wont be changed
    charParams.SetString("Species", species);
    // Reset any Teams
    if(teamNr != -1){
        charParams.SetString("Teams", "VersusBrawl_" + teamNr);
    }
    else{
        charParams.SetString("Teams", "");
    }
    
    string executeCmd = "SwitchCharacter(\""+ characterPath +"\");";
    char.Execute(executeCmd);
    char.controller_id = playerNr;
    
    if(teamNr != -1 && strictColors) {
        RecolorCharacter(teamNr, species, char_obj);
    }
    else{
        RecolorCharacter(playerNr, species, char_obj);
    }
    
    addSpeciesStats(char_obj);

    return char_obj;
}

void AttachTimers(int obj_id){
   
    VersusPlayer@ player = GetPlayerByObjectId(obj_id);
    player.charTimer.DeleteAll();
    
    player.charTimer.Add(CharDeathJob(obj_id, function(char_a){
        // This should respawn on kill
        VersusPlayer@ player = GetPlayerByObjectId(char_a.GetID());
        if(currentState==0 || constantRespawning){
            CallRespawn(player.playerNr, player.objId);
        }
        return false;
    }));

    player.charTimer.Add(CharDeathJob(obj_id, function(char_a){
        if(currentState < 100){
            MovementObject@ char = ReadCharacterID(char_a.GetID());
            Log(error, "Death of:"+ char_a.GetID() +" attacked_by_id:" + char.GetIntVar("attacked_by_id"));
            for (uint k = 0; k < spawned_object_ids.size(); k++)
            {
                if(char.GetIntVar("attacked_by_id") == spawned_object_ids[k] && maxCollateralKillTime > char.GetFloatVar("timeSinceAttackedById")){
                    level.SendMessage("oneKilledByTwo "+ char_a.GetID()+ " " + char.GetIntVar("attacked_by_id"));
                    return false;
                }
            }

            level.SendMessage("suicideDeath " + char_a.GetID() + " " + char.GetIntVar("attacked_by_id"));
        }

        return false;
    }));
}

// Just moves character into the position and activates him
void SpawnCharacter(Object@ spawn, Object@ char, bool isAlreadyPlayer = false, bool isFirst = true) {
    Log(error, "spawn:"+spawn.GetTranslation().x+","+spawn.GetTranslation().y+","+spawn.GetTranslation().z);
    Log(error, "char:"+char.GetID()+" isAlreadyPlayer"+isAlreadyPlayer+" isFirst:"+isFirst);
    
    if(currentState >= 2 ){
        // If game is inprogress, send spawn event
        level.SendMessage("spawned "+ char.GetID() +" " + isFirst);
    }
    
    if(isAlreadyPlayer){
        MovementObject@ mo = ReadCharacterID(char.GetID());
        mo.position = spawn.GetTranslation();
        mo.velocity = vec3(0);
    }
    
    char.SetTranslation(spawn.GetTranslation());
    vec4 rot_vec4 = spawn.GetRotationVec4();
    quaternion q(rot_vec4.x, rot_vec4.y, rot_vec4.z, rot_vec4.a);
    char.SetRotation(q);

    AttachTimers(char.GetID());

    if(!isAlreadyPlayer){
        char.SetPlayer(true);
    }

    // This is used to reset the camera
    MovementObject@ mo = ReadCharacterID(char.GetID());
    mo.Execute("SetCameraFromFacing();FixDiscontinuity();");
}

// Find a suitable spawn
// `useGenericSpawns` will take into account generic spawns
// `useSingleSpawnType` will only take team spawns if `useGeneric = false` adn only generic spawns if `useGeneric = true`
Object@ FindRandSpawnPoint(int playerNr) {
    
    //Lets do a quick copy
    VersusPlayer@ playerTemp = GetPlayerByNr(playerNr);
    VersusPlayer@ player = GetPlayerByNr(playerTemp.teamNr);

    array<SpawnPoint@> availableSpawnPoints = player.spawnPoints;
    // This keeps start of the total list of the spawns, incase you have too many locked ones atm
    array<SpawnPoint@> startListSpawnPoints = player.spawnPoints;
    
    //If useGenericSpawns is true, add generic ones too
    if(useGenericSpawns && !useSingleSpawnType){
        for(uint i = 0; i <genericSpawnPoints.size() ; i++) {
            availableSpawnPoints.push_back(genericSpawnPoints[i]);
            startListSpawnPoints.push_back(genericSpawnPoints[i]);
        }
    }
    // If both useGenericSpawns and useSingleSpawnType are true, we ONLY use generic ones
    else if(useGenericSpawns && useSingleSpawnType){
        availableSpawnPoints = genericSpawnPoints;
        startListSpawnPoints = genericSpawnPoints;
    }
    
    while(availableSpawnPoints.size() > 0 ){
        int index = rand()%(availableSpawnPoints.size());
        int obj_id = availableSpawnPoints[index].objId;

        Object@ obj = ReadObjectFromID(obj_id);
        
        // If its disabled just go on
        if(obj.GetEnabled() && availableSpawnPoints[index].spawnPointBlockTimer<=0){
            availableSpawnPoints[index].spawnPointBlockTimer = spawnPointBlockTime;
            return obj;
        }
        else {
            availableSpawnPoints.removeAt(index);
        }
    }

    // If you cant found anything, just ignore the block timer
    while(startListSpawnPoints.size() > 0 ) {
        int index = rand() % (startListSpawnPoints.size());
        int obj_id = startListSpawnPoints[index].objId;
        Object @obj = ReadObjectFromID(obj_id);
        if (obj.GetEnabled()) {
            return obj;
        } 
        else {
            startListSpawnPoints.removeAt(index);
        }
    }
    
    DisplayError("FindRandSpawnPoint", "FindRandSpawnPoint couldnt find a spawn with playerNr:" + playerNr + " useGeneric:" + useGenericSpawns + " useOneType:" + useSingleSpawnType);
    return null;
}

// Warning! Rolling character also revives/heals him
void RerollCharacter(int playerNr, Object@ char) {
    VersusPlayer@ player = GetPlayerByNr(playerNr);
    Object@ obj = ReadObjectFromID(player.objId);
    ScriptParams@ charParams = obj.GetScriptParams();
    string species = IntToSpecies(player.currentRace);
    string newCharPath = GetSpeciesRandCharacterPath(species);

    //You need to set Species param before SwitchCharacter(), otherwise `species` field wont be changed
    charParams.SetString("Species", species);
    
    string executeCmd = "SwitchCharacter(\""+ newCharPath +"\");";
    Log(error, species+" "+newCharPath+" "+executeCmd);
    ReadCharacterID(player.objId).Execute(executeCmd);
    
    RecolorCharacter(playerNr, species, char);
    
    // This will add species specific stats
    addSpeciesStats(obj);
}

///
///     Utility stuff
///
VersusPlayer@ GetPlayerByObjectId(int id){
    for(uint i = 0; i < versusPlayers.size(); i++) {
        if(versusPlayers[i].objId == id){
            return versusPlayers[i];
        }
    }
    return null;
}

VersusPlayer@ GetPlayerByNr(int playerNr){
    for(uint i = 0; i < versusPlayers.size(); i++) {
        if(versusPlayers[i].playerNr == playerNr){
            return versusPlayers[i];
        }
    }
    return null;
}

// This thingamajig extract key name for text dialogs
string InsertKeysToString( string text )
{
    for( uint i = 0; i < text.length(); i++ ) {
    if( text[i] == '@'[0] ) {
        for( uint j = i + 1; j < text.length(); j++ ) {
            if( text[j] == '@'[0] ) {
                string first_half = text.substr(0,i);
                string second_half = text.substr(j+1);
                string input = text.substr(i+1,j-i-1);
               
                string middle = GetStringDescriptionForBinding("gamepad_0", input);

                // We only change them if we need to
                // TODO: `GetStringDescriptionForBinding` returns the same string if it cant find binding? Kinda weird
                if(middle != input){
                    // We decide whether we should show keyboard and mouse inputs
                    string middleKb = "";
                    if(ignoreKbMAfter > scriptlastKbMInputTimer){
                        middleKb = "/" + GetStringDescriptionForBinding("key", input);
                    }

                    text = first_half + middle + middleKb + second_half;
                    i += middle.length();
                }

                break;
            }
        }
    }
}
    return text;
}

string GetSpeciesRandCharacterPath(string species)
{
    // Dumb usage of uint, I know, shouldve used std::vector<T>::size_type ofc
    for (uint i = 0; i < speciesMap.size(); i++)
    {
        if (speciesMap[i].Name == species) {
            // Species found, now get a random entry
            if(speciesMap[i].CharacterPaths is null){
                DisplayError("GetSpeciesRandCharacterPath", "GetSpeciesRandCharacterPath found that speciesMap["+i+"].CharacterPaths is null");
            }

            return speciesMap[i].CharacterPaths[
            rand()%speciesMap[i].CharacterPaths.size()];
        }
    }
    DisplayError("GetSpeciesRandCharacterPath", "GetSpeciesRandCharacterPath couldnt find any paths for species: " + species);
    return "Data/Objects/characters/rabbot_actor.xml";
}

string IntToColorName(int playerNr) {
    switch (playerNr){
        case 0:return "Green";
        case 1:return "Red";
        case 2:return "Blue";
        case 3:return "Yellow";
    }
    return "Youre not supposed to see this!";
}

string IntToSpecies(int speciesNr) {
    int speciesSize = speciesMap.size();
    if(speciesNr> speciesSize|| speciesNr<0){
        DisplayError("IntToSpecies", "Unsuported IntToSpecies value of: " + speciesNr);
        return "rabbot";
    }

    return speciesMap[speciesNr].Name;
}

void DeleteObjectsInList(array<int> &inout ids) {
    int num_ids = ids.length();
    for(int i=0; i<num_ids; ++i){
        Log(info, "Test");
        DeleteObjectID(ids[i]);
    }
    ids.resize(0);
}

///
///     General stuff
///
void VersusInit(string p_level_name) {

    // Register callback for loading JSON config
    loadCallbacks.push_back(@VersusBaseLoad);
    loadCallbacks.push_back(@SpeciesStatsLoad);
    // Load speciesStats.json
    BaseSpeciesStatsLoad();

    ScriptParams@ lvlParams = level.GetScriptParams();
    lvlParams.AddString("game_type", "versusBrawl");
    
    // This makes sure player number is already set and not below 1
    initPlayersNr = GetConfigValueInt("local_players");
    Log(error, "local_players: " + initPlayersNr);
    if(initPlayersNr < 1)
        initPlayersNr = 1;
    
    
    for(int i = 0; i< initPlayersNr; i++) {
        VersusPlayer player (i);
        // TODO! Here add scrambling of the teams, more fun
        if(teamPlay)
            player.teamNr = player.playerNr % teamsAmount;
        versusPlayers.push_back(player);
    }
    
    FindSpawnPoints();
    
    if(currentState != 1){
        // Spawn players, otherwise it gets funky and spawns a player where editor camera was
        for(uint i = 0; i < versusPlayers.size(); i++)
        {
            Log(error, "INIT SpawnCharacter");
            VersusPlayer@ player = GetPlayerByNr(i);
            SpawnCharacter(FindRandSpawnPoint(player.playerNr),player.SetObject(CreateCharacter(i, IntToSpecies(player.currentRace), player.teamNr)));
        }
    }
    
    levelTimer.Add(LevelEventJob("reset", function(_params){
        // We cleanup everything that could be problematic
        for(uint i = 0; i < versusPlayers.size(); i++)
        {
            VersusPlayer@ player = GetPlayerByNr(i);
            player.charTimer.DeleteAll();
        }
        DeleteObjectsInList(spawned_object_ids);
        
        for(uint i = 0; i < versusPlayers.size(); i++)
        {
            Log(error, "RESET EVENT SpawnCharacter");
            VersusPlayer@ player = GetPlayerByNr(i);
            player.objId = -1;
            player.respawnQueue = -100;
            player.respawnNeeded = false;

            SpawnCharacter(FindRandSpawnPoint(player.playerNr),player.SetObject(CreateCharacter(i,IntToSpecies(player.currentRace), player.teamNr)));
        }
        return true;
    }));
}


void VersusReset(){

}

void VersusDrawGUI(){
    versusAHGUI.Render();
}

void VersusUpdate() {
    
    if(initPlayersNr != GetConfigValueInt("local_players")){
        //Reload if the setting changed
        LoadLevel(GetCurrLevelRelPath());
    }
    
    scriptlastKbMInputTimer += time_step;
    if(lastKbMInput < max(last_mouse_event_time, last_keyboard_event_time))
    {
        //Log(error, "KbM Event! resetting scriptlastKbMInputTimer! Diff: " + (last_mouse_event_time - scriptlastKbMInputTimer) );
        scriptlastKbMInputTimer = 0;
        lastKbMInput = max(last_mouse_event_time, last_keyboard_event_time);
    }
    
    if(!CheckSpawnsNumber()) {
        //Warn about the incorrect number of spawns
        ChangeGameState(1);
    }
    
    //`AssetManager` is not exposed to `as_context` and `Preload.xml` is a static file, so I need to do this the dirty way
    // We load a new model each frame, onto the actor
    if(preload){
        // Disables preloading
        if(!enablePreload)
            preload = false;
        
        placeholderTimer -= time_step;
        if(placeholderId == -1)
            placeholderId = CreateObject(placeHolderActorPath, true);
        
        // This will load all character models, avoids hitching on first swaps
        Object@ char_obj = ReadObjectFromID(placeholderId);
        if(preloadSpeciesIndex< speciesMap.size()){
            if(preloadIndex< speciesMap[preloadSpeciesIndex].CharacterPaths.size()) {
                string executeCmd = "SwitchCharacter(\""+ speciesMap[preloadSpeciesIndex].CharacterPaths[preloadIndex] +"\");";
                Log(warning, " "+executeCmd);
                //DisplayError("", "Loading: "+executeCmd+" preloadSpeciesIndex:"+preloadSpeciesIndex+" preloadIndex:"+preloadIndex);   
                ReadCharacterID(placeholderId).Execute(executeCmd);
                preloadIndex++;
            }
            else{
                //DisplayError("", "Going next: preloadSpeciesIndex:"+preloadSpeciesIndex+" preloadIndex:"+preloadIndex);
                preloadSpeciesIndex++;
                preloadIndex = 0;
            }
        }
        else{
            if(placeholderTimer<0){
                DeleteObjectID(placeholderId);
                preload = false; 
            }
        }
    }
    
    levelTimer.Update();

    // Update crowns
    if(winnerNr != lastWinnerNr && crownEnabled){
        lastWinnerNr = winnerNr;
        // first we clear old ones
        for (uint i = 0; i < crownsIds.size(); i++)
        {
            if (crownsIds[i] != -1) {
                DeleteObjectID(crownsIds[i]);
            }
        }
        crownsIds = {};
        
        if(teamPlay){
            for (uint i = 0; i < versusPlayers.size(); i++)
            {
                VersusPlayer @player = GetPlayerByNr(i);
                if(player.teamNr != winnerNr)
                    continue;
                
                int crownId = CreateObject("Data/Objects/versus-brawl/hotspots/leaderCrownHotspot.xml");
                crownsIds.push_back(crownId);

                // TODO: This is copy pasta :/
                Object@ crown = ReadObjectFromID(crownId);
                ScriptParams @crownParams = crown.GetScriptParams();
                VersusPlayer @onePlayer = GetPlayerByNr(i);
                crownParams.SetInt("followObjId", onePlayer.objId);
                crownParams.SetInt("dampenMovement", 1);
            }
        }
        else{
            int crownId = CreateObject("Data/Objects/versus-brawl/hotspots/leaderCrownHotspot.xml");
            crownsIds.push_back(crownId);

            // TODO: This is copy pasta :/
            Object@ crown = ReadObjectFromID(crownId);
            ScriptParams @crownParams = crown.GetScriptParams();
            VersusPlayer @onePlayer = GetPlayerByNr(winnerNr);
            crownParams.SetInt("followObjId", onePlayer.objId);
            crownParams.SetInt("dampenMovement", 1);
        }
    }

    // Suicide check
    for (uint k = 0; k < versusPlayers.size(); k++)
    {
        VersusPlayer@ player = GetPlayerByNr(k);
        if (GetInputDown(player.playerNr, "attack") && GetInputDown(player.playerNr, "grab")) {
            suicideTimers[player.playerNr] += time_step;
            if(suicideTimers[player.playerNr]>suicideTime){
                if(ReadCharacterID(player.objId).GetIntVar("knocked_out") == _awake)
                    ReadCharacterID(player.objId).Execute("CutThroat();");
                suicideTimers[player.playerNr] = 0;
            }
        } else {
            suicideTimers[player.playerNr] = 0;
        }
    }
    
    for(uint i = 0; i < versusPlayers.size(); i++)
    {
        VersusPlayer@ player = GetPlayerByNr(i);
        if(player is null){
            DisplayError("","player is null");
            LoadLevel(GetCurrLevelRelPath());
        }
        player.charTimer.Update();
    }

    if(GetInputPressed(0,"f10")){
        LoadLevel(GetCurrLevelRelPath());
    }

    // Forces call `Notice` on all characters (helps with npc just standing there like morons)

    // TODO: Somehow this sometimes causes crashes? Maybe when the event arives during cleanup?
    // if(set_omniscientTimeSpan<0){
    //     set_omniscientTimer = set_omniscientTimer-time_step;
    //    
    //     for(uint i = 0; i < versusPlayers.size(); i++)
    //     {
    //         VersusPlayer@ player = GetPlayerByNr(i);
    //         ReadObjectFromID(player.objId).ReceiveScriptMessage("set_omniscient true");
    //     }
    // }
    
    // Reduce spawns block timers
    for(uint i = 0; i <genericSpawnPoints.size() ; i++) {
        if(genericSpawnPoints[i].spawnPointBlockTimer>0){
            genericSpawnPoints[i].spawnPointBlockTimer -= time_step;
            if(genericSpawnPoints[i].spawnPointBlockTimer<0){
                Log(error, "resetting spawnPointBlockTimer for:"+genericSpawnPoints[i].objId);
                genericSpawnPoints[i].spawnPointBlockTimer = 0;
            }
        }
    }
    for(uint i = 0; i <versusPlayers.size() ; i++) {
        VersusPlayer@ player = GetPlayerByNr(i);
            
        for(uint k = 0; k <player.spawnPoints.size() ; k++)
        {
            if (player.spawnPoints[k].spawnPointBlockTimer > 0) {
                player.spawnPoints[k].spawnPointBlockTimer -= time_step;
                if (player.spawnPoints[k].spawnPointBlockTimer < 0) {
                    Log(error, "resetting spawnPointBlockTimer for:"+player.spawnPoints[k].objId);
                    player.spawnPoints[k].spawnPointBlockTimer = 0;
                }
            }
        }
    }

    CheckPlayersState();
    // On first update we switch to warmup state
    if(currentState==-1 && !preload){
        ChangeGameState(0);
    }

    // Dont count time for hints if its preloading
    if(currentState >= 0)
        hintTimer += time_step;
    // Only show hits if: warmup (these are important) or: `tutorials` setting is turned on (random hints that can help)
    if(hintTimer > hintStayTime && (GetConfigValueBool("tutorials") || currentState == 0)){
        currentHint++;
        
        hintTimer = 0;
        
        // Warmup hints cycle
        if(currentState == 0){
            if(currentHint > int(warmupHints.size()) - 1)
                currentHint = 0;
            SetHint(warmupHints[currentHint]);
        }
        else{
            // If its empty, or still displaying previous hint, take new one
            //Log(error, "lastHint: " + lastHint);
            if(versusAHGUI.extraText == "" || versusAHGUI.extraText == InsertKeysToString(lastHint))
            {
                if(currentHint > int(randomHints.size()) - 1){
                    currentHint = 0;
                }
                if(hintBrake){
                    versusAHGUI.SetExtraText("", vec3(1));
                    hintBrake = false;
                    currentHint--;
                }
                else{
                    SetHint(randomHints[currentHint]);
                    hintBrake = true;
                }
            }
        }
    }

    PlaySong("ambient-tense");
    versusAHGUI.Update();
}

void SetHint(string hint){
    
    //Log(error, "currentHint: " + currentHint);
    if(rand()%100 < funniesChance && !funniesActive && false){
        string funni = funnies[rand()%funnies.size()];
        versusAHGUI.SetExtraText(funni);
        currentHint--;
        funniesActive = true;
        lastHint = funni;
    }
    else{
        versusAHGUI.SetExtraText(hint);
        funniesActive = false;
        lastHint = hint;
    }
    
}

void VersusReceiveMessage(string msg){
    levelTimer.AddLevelEvent(msg);
    for(uint i = 0; i < versusPlayers.size(); i++)
    {
        VersusPlayer@ player = GetPlayerByNr(i);
        player.charTimer.AddLevelEvent(msg);
    }
}

void VersusPreScriptReload(){
    levelTimer.DeleteAll();
    for(uint i = 0; i < versusPlayers.size(); i++)
    {
        VersusPlayer@ player = GetPlayerByNr(i);
        player.charTimer.DeleteAll();
    }
    if(!noReloads)
        LoadLevel(GetCurrLevelRelPath());
}

class VersusAHGUI : AHGUI::GUI {
    VersusAHGUI() {
        // Call the superclass to set things up
        super();
    }
    
    bool layoutChanged = true;
    string text="Loading...";
    string extraText="";
    vec3 textColor = vec3(1.0f);
    vec3 extraTextColor = vec3(1.0f);
    int assignmentTextSize = 70;
    int footerTextSize = 50;
    bool initUI = true;

    // DebugStuff
    bool showBorders = false;
    
    array<string> currentIcon =  {"","","",""};
    array<bool> currentGlow =  {false,false,false,false};
    
    void Render() {
        // Update the background
        // TODO: fold this into AHGUI
        hud.Draw();
    
        // Update the GUI
        AHGUI::GUI::render();
    }
    
    void processMessage( AHGUI::Message@ message ) {
    }
    
    //Use this to easily set current onscreen text
    void SetMainText(string maintext, vec3 color = vec3(1.0f)){
        text = InsertKeysToString(maintext);
        textColor = color;
        layoutChanged = true;
    }

    void SetText(string maintext, string subtext, vec3 color = vec3(1.0f)){
        text = InsertKeysToString(maintext);
        extraText = InsertKeysToString(subtext);
        textColor = color;
        extraTextColor = color;
        layoutChanged = true;
    }

    void SetExtraText( string subtext, vec3 color = vec3(1.0f)){
        extraText = InsertKeysToString(subtext);
        extraTextColor = color;
        layoutChanged = true;
    }
    
    void UpdateText(){
    
        AHGUI::Element@ headerElement = root.findElement("header");
        if(headerElement is null) {
            DisplayError("GUI Error", "Unable to find header");
            // Just reload the level on this error
            LoadLevel(GetCurrLevelRelPath());
        }

        AHGUI::Element@ extraHeaderElement = root.findElement("extraHeader");
        if(extraHeaderElement is null) {
            DisplayError("GUI Error", "Unable to find extraHeader");
            // Just reload the level on this error
            LoadLevel(GetCurrLevelRelPath());
        }
        AHGUI::Divider@ header = cast<AHGUI::Divider>(headerElement);
        AHGUI::Divider@ extraHeader = cast<AHGUI::Divider>(extraHeaderElement);
        // Get rid of the old contents
        header.clear();
        header.clearUpdateBehaviors();
        header.setDisplacement();
        extraHeader.clear();
        extraHeader.clearUpdateBehaviors();
        extraHeader.setDisplacement();
    
        // If in editor hide the text
        if(EditorModeActive()){
            DisplayText(DDTop, header, extraHeader, 100, "", 90, "", 55);
        }
        else{
            DisplayText(DDTop, header, extraHeader, 100, text, 90, extraText, 55);
        }
    }
    
    void ChangeIcon(int playerIdx, int iconNr, bool glow)
    {
        if(blockSpeciesChange)
            return;
        AHGUI::Element@ headerElement = root.findElement("quitButton"+playerIdx);
        if( headerElement is null  ) {
            //DisplayError("GUI Error", "Unable to find quitButton"+playerIdx);
            return;
        }
        AHGUI::Image@ quitButton = cast<AHGUI::Image>(headerElement);
        string iconPath;
        if(iconNr == -1){
            // For -1 we use generic icon
            iconPath= placeholderRaceIconPath;
        }else{
            iconPath=speciesMap[iconNr].RaceIcon;
        }
        if(currentIcon[playerIdx] != iconPath){
            currentIcon[playerIdx] = iconPath;
    
            quitButton.setImageFile(iconPath);
            quitButton.scaleToSizeX(playerIconSize);
        }
    
        if(currentGlow[playerIdx] != glow){
            Log(error, "glow"+glow);
            currentGlow[playerIdx] = glow;
            if(glow){
                quitButton.setColor(vec4(0.7,0.7,0.7,0.8));
            }
            else{
                quitButton.setColor(vec4(GetTeamUIColor(playerIdx), 1.0f));
            }
            quitButton.scaleToSizeX(playerIconSize);
        }
    }
    
    void CheckForUIChange(){
        if(initUI) {
            initUI = false;
            //Violet 
            AHGUI::Divider
            @container = root.addDivider(DDCenter, DOVertical, ivec2(AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE));
            container.setVeritcalAlignment(BACenter);
            if (showBorders) {
                container.setBorderSize(5);
                container.setBorderColor(1.0, 0.0, 1.0, 1.0);
                container.showBorder();
            }

            //Cyan For Text
            AHGUI::Divider
            @header = container.addDivider(DDTopLeft, DOHorizontal, ivec2(50, AH_UNDEFINEDSIZE));
            header.setName("header");
            header.setVeritcalAlignment(BACenter);
            header.setHorizontalAlignment(BACenter);
            if (showBorders) {
                header.setBorderSize(4);
                header.setBorderColor(0.0, 1.0, 1.0, 1.0);
                header.showBorder();
            }

            //Orange
            AHGUI::Divider
            @extraHeader = container.addDivider(DDBottomRight, DOHorizontal, ivec2(50, AH_UNDEFINEDSIZE));
            extraHeader.setName("extraHeader");
            extraHeader.setVeritcalAlignment(BACenter);
            extraHeader.setHorizontalAlignment(BACenter);
            if (showBorders) {
                extraHeader.setBorderSize(4);
                extraHeader.setBorderColor(1.0, 0.5, 0.0, 1.0);
                extraHeader .showBorder();
            }

            AHGUI::Divider
            @containerBottom = root.addDivider(DDTop, DOHorizontal, ivec2(AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE));
            AHGUI::Divider
            @containerTop = root.addDivider(DDBottom, DOHorizontal, ivec2(AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE));

            int playerNr = versusPlayers.size();
            
            //Yellow
            AHGUI::Divider
            @header3 = containerBottom.addDivider(DDRight, DOHorizontal, ivec2(AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE));
            header3.setName("header3");
            header3.setVeritcalAlignment(BALeft);
            header3.setHorizontalAlignment(BABottom);
            if (showBorders) {
                header3.setBorderSize(4);
                header3.setBorderColor(1.0, 1.0, 0.0, 1.0);
                header3.showBorder();
            }
            AHGUI::Image
            @quitButton3 = AHGUI::Image(placeholderRaceIconPath);
            if (playerNr > 3) {
                quitButton3.setImageFile(placeholderRaceIconPath);
            }
            quitButton3.scaleToSizeX(playerIconSize);
            quitButton3.setName("quitButton3");
            quitButton3.setColor(vec4(GetTeamUIColor(3), 1.0f));
            header3.addElement(quitButton3, DDRight);

            //Blue
            AHGUI::Divider
            @header2 = containerBottom.addDivider(DDLeft, DOHorizontal, ivec2(AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE));
            header2.setName("header2");
            header2.setVeritcalAlignment(BALeft);
            header2.setHorizontalAlignment(BABottom);
            if (showBorders) {
                header2.setBorderSize(4);
                header2.setBorderColor(0.0, 0.0, 1.0, 1.0);
                header2.showBorder();
            }
            AHGUI::Image
            @quitButton2 = AHGUI::Image(placeholderRaceIconPath);
            if (playerNr > 2) {
                quitButton2.setImageFile(placeholderRaceIconPath);
            }
            quitButton2.scaleToSizeX(playerIconSize);
            quitButton2.setName("quitButton2");
            quitButton2.setColor(vec4(GetTeamUIColor(2), 1.0f));
            header2.addElement(quitButton2, DDLeft);

            //Red
            AHGUI::Divider
            @header1 = containerTop.addDivider(DDRight, DOHorizontal, ivec2(AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE));
            header1.setName("header1");
            header1.setVeritcalAlignment(BALeft);
            header1.setHorizontalAlignment(BABottom);
            if (showBorders) {
                header1.setBorderSize(4);
                header1.setBorderColor(1.0, 0.0, 0.0, 1.0);
                header1.showBorder();
            }
            AHGUI::Image
            @quitButton1 = AHGUI::Image(placeholderRaceIconPath);
            if (playerNr > 1) {
                quitButton1.setImageFile(placeholderRaceIconPath);
            }
            quitButton1.scaleToSizeX(playerIconSize);
            quitButton1.setName("quitButton1");
            quitButton1.setColor(vec4(GetTeamUIColor(1), 1.0f));
            header1.addElement(quitButton1, DDRight);


            //Green
            AHGUI::Divider
            @header0 = containerTop.addDivider(DDLeft, DOHorizontal, ivec2(AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE));
            header0.setName("header0");
            header0.setVeritcalAlignment(BALeft);
            header0.setHorizontalAlignment(BABottom);
            if (showBorders) {
                header0.setBorderSize(4);
                header0.setBorderColor(0.0, 1.0, 0.0, 1.0);
                header0.showBorder();
            }
            AHGUI::Image
            @quitButton0 = AHGUI::Image(placeholderRaceIconPath);
            if (playerNr > 0) {
                quitButton0.setImageFile(placeholderRaceIconPath);
            }
            quitButton0.scaleToSizeX(playerIconSize);
            quitButton0.setName("quitButton0");
            quitButton0.setColor(vec4(GetTeamUIColor(0), 1.0f));
            header0.addElement(quitButton0, DDLeft);
        }
    
        if(layoutChanged){
            layoutChanged = false;
        }
        UpdateText();
        AHGUI::GUI::update();
    }

    // TODO! This is needlessly complicated
    void DisplayText(DividerDirection dd, AHGUI::Divider@ div, AHGUI::Divider@ extraDiv, int maxWords, string text, int textSize, string extraTextVal = "", int extraTextSize = 0) {
        //The maxWords is the amount of words per line.
        array<string> sentences;

        array<string> words = text.split(" ");
        string sentence;
        for(uint i = 0; i < words.size(); i++){
            sentence += words[i] + " ";
            if((i+1) % maxWords == 0 || words.size() == (i+1)){
                sentences.insertLast(sentence);
                sentence = "";
            }
        }
        for(uint k = 0; k < sentences.size(); k++){
            BuildColoredTextBox(dd, div, text, textSize, textColor);
        }
        if(extraTextVal != ""){
            BuildColoredTextBox(dd, extraDiv, extraTextVal, extraTextSize, extraTextColor);
        }
    }

    // TODO! Clean this up
    void BuildColoredTextBox(DividerDirection dd, AHGUI::Divider@ div, string text, int textSize, vec3 defaultColor) {

        array<string> parts = {};
        array<vec3> colors = {};
        int lastPartEnd = 0;
    
        int foundAt = text.findFirst("@", lastPartEnd);
        while(foundAt >= 0){
            if(lastPartEnd != foundAt){
                string lastPart = text.substr(lastPartEnd, foundAt - lastPartEnd);
                parts.push_back(lastPart);
                colors.push_back(defaultColor);
                lastPartEnd = foundAt;
            }

            int foundVec3 = text.findFirst("vec3(", foundAt + 1);

            if(foundVec3 >= 0) {
                int foundClosingBrace = text.findFirst(")", foundVec3 + 1);
               
                if(foundClosingBrace >= 0) {
                    int foundClosingAt = text.findFirst("@", foundClosingBrace);
                    string vec3Str = text.substr(foundVec3,foundClosingBrace - foundVec3+1);
                    vec3 color = parseVec3(vec3Str);
                   
                    if(foundClosingAt > 0) {
                        string input = text.substr(foundClosingBrace + 1, foundClosingAt - foundClosingBrace-1);

                        parts.push_back(input);
                        colors.push_back(color);
                        lastPartEnd = foundClosingAt + 1;
                    }
                }
            }

            foundAt = text.findFirst("@", lastPartEnd);
        }

        // Add all not colored text between back
        if(uint(lastPartEnd) < text.length()-1){
            parts.push_back(text.substr(lastPartEnd, text.length() - lastPartEnd));
            colors.push_back(defaultColor);
        }
    
        // string partsText = "Parts: ";
        // for(uint i = 0; i < parts.size(); i++) {
        //     partsText +=  parts[i] + " | ";
        // }
        //
        // string colorsText = "Colors: ";
        // for(uint i = 0; i < colors.size(); i++) {
        //     colorsText += colors[i] + " | ";
        // }

        for(uint i = 0; i < parts.size(); i++) {
            AHGUI::Text singleSentence(parts[i], "edosz", textSize, colors[i].x, colors[i].y, colors[i].z, 1.0f );
            singleSentence.setShadowed(true);
            singleSentence.setVeritcalAlignment(BACenter);
            singleSentence.setHorizontalAlignment(BACenter);
            div.addElement(singleSentence, dd);
            if(showBorders){
                singleSentence.setBorderSize(1);
                singleSentence.setBorderColor(colors[i].x, colors[i].y, colors[i].z, 1.0);
                singleSentence.showBorder();
            }
        }
        
    }
    
    void Update(){
        CheckForUIChange();
        AHGUI::GUI::update();
    }
}

vec3 parseVec3(string text){
    int findVec3 = text.findFirst("vec3(");
    if(findVec3 >= 0) {
        
        int findFirstComa = text.findFirst(",", findVec3);
        if(findFirstComa >= 0) {

            int findSecondComa = text.findFirst(",", findFirstComa+1);
            if(findSecondComa >= 0) {

                int findClosing = text.findFirst(")", findSecondComa);
                if(findClosing >= 0) {

                    int x1 = findVec3+5;
                    int x2 = findFirstComa;
                    int xc = x2 - x1;

                    int y1 = findFirstComa+1;
                    int y2 = findSecondComa;
                    int yc = y2 - y1;

                    int z1 = findSecondComa+1;
                    int z2 = findClosing;
                    int zc = z2 - z1;

                    string inputX = text.substr(x1,xc);
                    string inputY = text.substr(y1,yc);
                    string inputZ = text.substr(z1,zc);

                    float x = parseFloat(inputX);
                    float y = parseFloat(inputY);
                    float z = parseFloat(inputZ);

                    return vec3(x,y,z);
                }
            }
        }
    }
    DisplayError("parseVec3", "Couldnt parseVec3: " + text);
    return vec3();
}

// Inspired, again, by how its done in arena_level.as 
//TODO: maybe add compatibility with default arena maps, just by replacing script with this one?
void FindSpawnPoints(){
    //TODO! Make spawnpoints supported in a better way, maybe also add clumping spawns together (useful for bigger maps)
    // Remove all spawned objects
    DeleteObjectsInList(spawned_object_ids);
    spawned_object_ids.resize(0);

    // Identify all the spawn points for the current game type
    array<int> @object_ids = GetObjectIDs();
    int num_objects = object_ids.length();
    for(int i=0; i<num_objects; ++i){
        Object @obj = ReadObjectFromID(object_ids[i]);
        ScriptParams@ params = obj.GetScriptParams();
        if(params.HasParam("game_type")){
            // Check whether this spawn is "versusBrawl" type
            if(params.GetString("game_type")=="versusBrawl"){
                // Check for PlayerNr
                if(params.HasParam("playerNr")) {
                    int playerNr = params.GetInt("playerNr");
                    if(playerNr < -1 || playerNr > 3){
                        DisplayError("FindSpawnPoints Error", "Spawn:"+object_ids[i]+" has PlayerNr less than -1 or greater than 3");
                    }
                    else if(playerNr==-1){
                        // If its -1, its a generic spawn point, add it to the last array (generic spawns)
                        
                        genericSpawnPoints.push_back(SpawnPoint(object_ids[i]));
                    }
                    else{
                        // If its 0 or greater, make sure it lands on the correct playerIndex array
                        VersusPlayer@ player = GetPlayerByNr(playerNr);
                        // Ignore if null is returned, no such player
                        if(!(player is null))
                            player.spawnPoints.push_back(SpawnPoint(object_ids[i]));
                    }
                }
            }
        }
    }
}

void VersusBaseLoad(JSONValue settings){
    Log(error, "VersusBase:");
    if(FoundMember(settings, "VersusBase")){
        JSONValue versusBase = settings["VersusBase"];
        Log(error, "Available: " + join(versusBase.getMemberNames(),","));

        if(FoundMember(versusBase, "RespawnTime"))
            respawnTime = versusBase["RespawnTime"].asFloat();
        
        if(FoundMember(versusBase, "RespawnBlockTime"))
            respawnBlockTime = versusBase["RespawnBlockTime"].asFloat();
        
        if(FoundMember(versusBase, "SpawnPointBlockTime"))
            spawnPointBlockTime = versusBase["SpawnPointBlockTime"].asFloat();
        
        if(FoundMember(versusBase, "WinStateTime"))
            winStateTime = versusBase["WinStateTime"].asFloat();
        
        if(FoundMember(versusBase, "ForcedSpecies")){
            forcedSpecies = versusBase["ForcedSpecies"].asInt();
            
            //This makes sure first spawned character are correct species
            for(uint i = 0; i < versusPlayers.size(); i++)
            {
                VersusPlayer@ player = GetPlayerByNr(i);
                player.currentRace = forcedSpecies;
                RerollCharacter(player.playerNr, ReadObjectFromID(player.objId));
            }
            
            Log(error, "Refreshing currentRace, cause loaded new forcedSpecies: " + forcedSpecies);
        }
        
        if(FoundMember(versusBase, "ConstantRespawning"))
            constantRespawning = versusBase["ConstantRespawning"].asBool();
        
        if(FoundMember(versusBase, "UseGenericSpawns"))
            useGenericSpawns = versusBase["UseGenericSpawns"].asBool();

        if(FoundMember(versusBase, "UseSingleSpawnType"))
            useSingleSpawnType = versusBase["UseSingleSpawnType"].asBool();

        if(FoundMember(versusBase, "BlockSpeciesChange"))
            blockSpeciesChange = versusBase["BlockSpeciesChange"].asBool();

        if(FoundMember(versusBase, "InstantSpeciesChange"))
            instantSpeciesChange = versusBase["InstantSpeciesChange"].asBool();

        if(FoundMember(versusBase, "EnablePreload"))
            enablePreload = versusBase["EnablePreload"].asBool();

        if(FoundMember(versusBase, "NoReloads"))
            noReloads = versusBase["NoReloads"].asBool();

        if(FoundMember(versusBase, "MaxCollateralKillTime"))
            maxCollateralKillTime = versusBase["MaxCollateralKillTime"].asFloat();

        if(FoundMember(versusBase, "HintStayTime"))
            hintStayTime = versusBase["HintStayTime"].asFloat();

        if (FoundMember(versusBase, "suicideTime"))
            suicideTime = versusBase["SuicideTime"].asFloat();

        if(FoundMember(versusBase, "CrownsEnabled"))
            crownEnabled = versusBase["CrownsEnabled"].asBool();

        if(FoundMember(versusBase, "TeamPlay"))
            teamPlay = versusBase["TeamPlay"].asBool();

        if(FoundMember(versusBase, "TeamsAmount"))
            teamsAmount = versusBase["TeamsAmount"].asInt();

        if(FoundMember(versusBase, "AllowUneven"))
            allowUneven = versusBase["AllowUneven"].asBool();

        if(FoundMember(versusBase, "AllowTeamChange"))
            allowTeamChange = versusBase["AllowTeamChange"].asBool();

        if(FoundMember(versusBase, "StrictColors"))
            strictColors = versusBase["StrictColors"].asBool();
    }
}

// This makes sure there is atleast a single spawn per playerNr
bool CheckSpawnsNumber() {
    bool okPlayerSpawns = true;
    bool okGenericSpawns = true;
    
    int teamsToChecks = int(versusPlayers.size());
    if(teamPlay){
        teamsToChecks = teamsAmount;
    }

    for(int i = 0; i < teamsToChecks; i++) {
        //Log(error, "Checking " + i + " teamsToChecks: " + teamsToChecks );
        if(versusPlayers[i].spawnPoints.size() < 1){
            //Log(error, "spawnPoints.size()<1");
            okPlayerSpawns = false;
        }
    }
    if(genericSpawnPoints.size() < 1)
        okGenericSpawns = false;
    
    if(!useGenericSpawns){
        return okPlayerSpawns;
    }
    else if(useGenericSpawns && useSingleSpawnType){
        return okGenericSpawns;
    }
    else if(useGenericSpawns && !useSingleSpawnType){
        return okPlayerSpawns || okGenericSpawns;
    }

    return true;
}

void CheckPlayersState() {
    if(currentState==0){
        bool blockStart = false;
        // TODO! Inform players that teams are uneven
        if(teamPlay && !allowUneven){
            array<int> teamSizes = {0, 0, 0, 0};
            for(uint i = 0; i< versusPlayers.size(); i++) {
                VersusPlayer@ player = GetPlayerByNr(i);
                teamSizes[player.teamNr]++;
            }
            int lastVal = teamSizes[0];
            for(int i = 1; i< teamsAmount; i++)
            {
                if(lastVal != teamSizes[i]){
                    blockStart = true;
                    break;
                }
            }
            
            // TODO! This is kinda dumb, but should work for now.
            //Log(error, "blockStart: " + blockStart);

            if(blockStart){
                versusAHGUI.SetMainText("Teams uneven!", vec3(1,0.5f,0));
            }
            else{
                versusAHGUI.SetMainText("Warmup!", vec3(1));
            }
        }
        
        //Select players number
		if(GetInputDown(0,"skip_dialogue") && !blockStart){
            ChangeGameState(2); //Start game
		}
    }
    
    if(currentState < 100){
        // Respawning logic
        for(uint i = 0; i < versusPlayers.size(); i++) {
            VersusPlayer@ player = GetPlayerByNr(i);
            if(player.respawnQueue>-respawnBlockTime){
                player.respawnQueue = player.respawnQueue-time_step;
                
                Object@ char_obj = ReadObjectFromID(player.objId);
                MovementObject@ char = ReadCharacterID(char_obj.GetID());
                
                if(player.respawnQueue<0 && player.respawnNeeded){
                    player.respawnNeeded = false;
                    // This line took me 4hrs to figure out
                    // This also makes character invincible, for the spawn protection aka. `respawnBlockTime`
                    char.Execute("SetState(0);Recover();invincible = true;");
                    
                    RerollCharacter(player.playerNr, char_obj);
                    
                    Log(error, "UPDATE SpawnCharacter");
                    SpawnCharacter(FindRandSpawnPoint(player.playerNr), char_obj, true, false);
                }
                else if(player.respawnQueue<=-respawnBlockTime) {
                    // Removing player temporary resistance
                    Log(error, "Removing spawn protection for " + i);
                    char.Execute("invincible = false;");
                }
            }
        }
    }
    
    if(!blockSpeciesChange){
        for(uint i = 0; i < versusPlayers.size(); i++) {
            VersusPlayer@ player = GetPlayerByNr(i);
            if(GetInputDown(i,"item") && GetInputDown(i,"drop")) {
                if(GetInputPressed(i,"attack")) {
                    player.currentRace++;
                    player.currentRace = player.currentRace % speciesMap.size();
                    
                    if(currentState==0 || instantSpeciesChange){
                        MovementObject@ mo = ReadCharacter(player.playerNr);
                        Object@ char = ReadObjectFromID(mo.GetID());
                        RerollCharacter(player.playerNr,ReadObjectFromID(player.objId));
                    }
                }
                versusAHGUI.ChangeIcon(player.playerNr, player.currentRace, true);
            }
            else {
                // Last element is always the default state icon
                versusAHGUI.ChangeIcon(player.playerNr, -1, false);
            }
        }
    }
    
    if(currentState >= 100){
        winStateTimer += time_step;
        
        // We want this to occur atleast frame late, to allow custom win state things to occur
        if(winStateTimer-time_step>winStateTime){
            // Now we just need to reset few things
            winStateTimer = 0;
            
            ChangeGameState(2);
        }
    }
}

void ChangeGameState(uint newState) {
    if(currentState != -1)
        if(newState == uint(currentState))
            return;
    currentState = newState;
    switch (newState) {
        case 0: 
            //Warmup, select player number
            versusAHGUI.SetText("Warmup!",
                "Press @vec3(1,0.5,0)@skip_dialogue@@ button to begin.");
            break;
        case 1: 
            //Failsafe, not enough spawns, waiting for acknowledgment
            //TODO: Inform what is the amount of what type needed for the current settings
            versusAHGUI.SetText("Warning! Not enough player spawns detected!",
                "After adding more player spawns, please save and reload the map.");
            break;
        case 2:
            //Game Start
            winnerNr = -1;
            PlaySound("Data/Sounds/versus/voice_start_1.wav");
            // Clear text
            versusAHGUI.SetText("", "");
            level.SendMessage("reset");
            break;
        case 100:
            versusAHGUI.SetText(""+IntToColorName(winnerNr)+" wins!",insults[rand()%insults.size()], GetTeamUIColor(winnerNr));
            break;
        default:
            break;
    }
}
