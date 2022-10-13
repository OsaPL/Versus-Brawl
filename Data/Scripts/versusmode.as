#include "ui_effects.as"
#include "music_load.as"
#include "ui_tools.as"

#include "speciesStats.as"

#include "timed_execution/timed_execution.as"
#include "timed_execution/char_death_job.as"
#include "timed_execution/level_event_job.as"

//Configurables
float respawnTime = 2;
// This will block any stupid respawns calls from hotspots that kill on the way to spawn, higher values could help on bigger "trips"
float respawnBlockTime = 0.5;
bool constantRespawning = false;
// How often we want to make all char aware
float set_omniscientTimeSpan = 3;
float set_omniscientTimer = set_omniscientTimeSpan;
// This blocks currentRace from being changed by player
bool blockSpeciesChange = false; 
// This allows instant race change even during game (state==2)
bool instantSpeciesChange = false;

//New UI Stuff
int playerIconSize = 100;
string placeholderRaceIconPath = "Textures/ui/challenge_mode/quit_icon_c.tga";

//States
uint players_number;
uint currentState=99;
bool failsafe;

array<uint> currentRace = {0,1,2,3};
array<bool> respawnNeeded ={false,false,false,false};
// indexes 0-3 are for playerNr ones, last one is for generic spawns
array<array<int>> spawnPointIds={{},{},{},{},{},{}};
array<float> respawnQueue ={-100,-100,-100,-100};
string placeHolderActorPath = "Data/Objects/characters/rabbot_actor.xml";

VersusAHGUI versusAHGUI;
TimedExecution timer;

// All objects spawned by the script
array<int> spawned_object_ids;

///
///     This section contains the gamemode interface methods
///

//Requests a respawn for a player
//TODO! This shouldnt need objID, just playerNr
void CallRespawn(int playerNr, int objId) {
    if(!respawnNeeded[playerNr] && respawnQueue[playerNr]<-respawnBlockTime){
        respawnNeeded[playerNr] = true;
        respawnQueue[playerNr]= respawnTime;
        Object@ char = ReadObjectFromID(objId);
        MovementObject@ mo = ReadCharacterID(objId);
        Log(error, "Respawn requested objId:"+objId+" playerNr:"+playerNr);
    }
}

// This creates a pseudo random character by juggling all available parameters
Object@ CreateCharacter(int playerNr, string species) {
    // Select random species character and create it
    int obj_id = CreateObject(placeHolderActorPath, true);
    string characterPath = GetSpeciesRandCharacterPath(species);

    // Remember to track him for future cleanup
    spawned_object_ids.push_back(obj_id);
    Object@ char_obj = ReadObjectFromID(obj_id);
    MovementObject@ char = ReadCharacterID(char_obj.GetID());

    string executeCmd = "SwitchCharacter(\""+ characterPath +"\");";
    char.Execute(executeCmd);
    RecolorCharacter(playerNr, species, char_obj);

    //Adds respawning on warmup
    timer.Add(CharDeathJob(obj_id, function(char_a){
        // This should respawn on kill
        if(currentState==0 || constantRespawning){
            for (uint i = 0; i < spawned_object_ids.size(); i++) {
                if(spawned_object_ids[i] == char_a.GetID()){
                    CallRespawn(i, char_a.GetID());
                }
            }
        }
        return true;
    }));

    return char_obj;
}

void RecolorCharacter(int playerNr, string species, Object@ char_obj) {
    // Setup
    MovementObject@ mo = ReadCharacterID(char_obj.GetID());
    character_getter.Load(mo.char_path);
    ScriptParams@ params = char_obj.GetScriptParams();
    // Some small tweaks to make it look more unique
    // Scale, Muscle and Fat has to be 0-1 range
    //TODO: these would be cool to have governing variables (max_fat, minimum_fat etc.)
    //TODO! Scale is overwritten by addSpeciesStats() atm!
    float scale = (90.0+(rand()%15))/100;
    params.SetFloat("Character Scale", scale);
    float muscles = (50.0+((rand()%15)))/100;
    params.SetFloat("Muscle", muscles);
    float fat = (50.0+((rand()%15)))/100;
    params.SetFloat("Fat", fat);

    // Color the dinosaur, or even the rabbit
    vec3 furColor = GetRandomFurColor();
    vec3 clothesColor = RandReasonableTeamColor(playerNr);

    for(int i = 0; i < 4; i++) {
        const string channel = character_getter.GetChannel(i);
        Log(error, "species:"+species + "channel:"+channel);
        //TODO: fill this up more, maybe even extract to a top level variable for easy edits?


        if(channel == "fur" ) {
            // These will use fur generator color, mixed with another
            char_obj.SetPaletteColor(i, mix(furColor, GetRandomFurColor(), 0.7));

            // Wolves are problematic for coloring all channels are marked as `fur`
            if(species == "wolf"){
                if(i==1 || i==4){
                    char_obj.SetPaletteColor(i, clothesColor);
                }
            }
        } else if(channel == "cloth" ) {
            char_obj.SetPaletteColor(i, clothesColor);
            clothesColor = mix(clothesColor, vec3(0.0), 0.9);
        }
    }

    // Reset any Teams
    //TODO: Here probably will be the team assignment stufff
    params.SetString("Teams", "");

    char_obj.UpdateScriptParams();

    // This will add species specific stats
    addSpeciesStats(char_obj);
}

// Just moves character into the position and activates him
void SpawnCharacter(Object@ spawn, Object@ char, bool isAlreadyPlayer = false) {
    Log(warning, "spawn:"+spawn.GetTranslation().x+","+spawn.GetTranslation().y+","+spawn.GetTranslation().z);
    Log(warning, "char:"+char.GetID()+" isAlreadyPlayer"+isAlreadyPlayer);
    if(isAlreadyPlayer){
        MovementObject@ mo = ReadCharacterID(char.GetID());
        mo.position = spawn.GetTranslation();
        mo.velocity = vec3(0);
    }
    char.SetTranslation(spawn.GetTranslation());
    vec4 rot_vec4 = spawn.GetRotationVec4();
    quaternion q(rot_vec4.x, rot_vec4.y, rot_vec4.z, rot_vec4.a);
    char.SetRotation(q);

    if(!isAlreadyPlayer){
        char.SetPlayer(true);
    }
}

// Find a suitable spawn
// TODO: `useGeneric` will take into account generic spawns
// TODO: `useOneType` will only take team spawns if `useGeneric = false` adn only generic spawns if `useGeneric = true`
Object@ FindRandSpawnPoint(int playerNr, bool useGeneric = false, bool useOneType=true) {
    int obj_id = spawnPointIds[playerNr][
    rand()%(spawnPointIds[playerNr].size())];
    return ReadObjectFromID(obj_id);
}

// Warning! Rolling character also revives/heals him
void RerollCharacter(int playerNr, Object@ char) {
    MovementObject@ mo = ReadCharacterID(char.GetID());
    string species = IntToSpecies(currentRace[playerNr]);
    string newCharPath = GetSpeciesRandCharacterPath(species);

    string executeCmd = "SwitchCharacter(\""+ newCharPath +"\");";
    Log(error, species+" "+newCharPath+" "+executeCmd);
    mo.Execute(executeCmd);
    RecolorCharacter(playerNr, species, char);
}

///
///     Utility stuff
///
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
                //TODO! This can be fix to also support keyboard mappings if I use the same:
                //bool use_keyboard = (max(last_mouse_event_time, last_keyboard_event_time) > last_controller_event_time);
                // as in aschar.as
                string middle = GetStringDescriptionForBinding("gamepad_0", input);

                text = first_half + middle + second_half;
                i += middle.length();
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

//TODO! These colors are awful, make them slightly better?
vec3 RandReasonableWolfTeamColor(int playerNr) {
    switch (playerNr) {
        case 0:return vec3(0.0,255.0,0.0);
        case 1:return vec3(255.0,0.0,0.0);
        case 2:return vec3(0.0,0.0,255.0);
        case 3:return vec3(255.0,255.0,0.0);
    }
    return vec3(255,255,255);
}

vec3 RandReasonableTeamColor(int playerNr) {
    int max_red;
    int max_green;
    int max_blue;

    int max_main=100;
    int max_sub=0+rand()%20;

    switch (playerNr) {
        case 0:
            //Green
            max_red = max_sub;
            max_green = max_main;
            max_blue = max_sub;
            break;
        case 1:
            //Red
            max_red = max_main;
            max_green = max_sub;
            max_blue = max_sub;
            break;
        case 2:
            //Blue
            max_red = max_sub;
            max_green = max_sub;
            max_blue = max_main;
            break;
        case 3:
            //Yellow
            max_red = max_main;
            max_green = max_main;
            max_blue = max_sub;
            break;
        default: DisplayError("RandReasonableTeamColor", "Unsuported RandReasonableTeamColor value of: " + playerNr);
            //Purple guy?
            max_red = max_main;
            max_green = max_sub;
            max_blue = max_main;
            break;
    }

    vec3 color;
    color.x = max_red;
    color.y = max_green;
    color.z = max_blue;
    float avg = (color.x + color.y + color.z) / 3.0f;
    color = mix(color, vec3(avg), 0.3f);
    return FloatTintFromByte(color);
}

//TODO!    
int SpeciesToInt(string species) {
    return -1;
}

string IntToSpecies(int speciesNr) {
    int speciesSize = speciesMap.size();
    if(speciesNr> speciesSize|| speciesNr<0){
        DisplayError("IntToSpecies", "Unsuported IntToSpecies value of: " + speciesNr);
        return "rabbot";
    }

    return speciesMap[speciesNr].Name;
}

/// This code is just stolen from arena_level.as
Object@ SpawnObjectAtSpawnPoint(Object@ spawn, string &in path) {
    int obj_id = CreateObject(path, true);
    spawned_object_ids.push_back(obj_id);
    Object @new_obj = ReadObjectFromID(obj_id);
    new_obj.SetTranslation(spawn.GetTranslation());
    vec4 rot_vec4 = spawn.GetRotationVec4();
    quaternion q(rot_vec4.x, rot_vec4.y, rot_vec4.z, rot_vec4.a);
    new_obj.SetRotation(q);
    return new_obj;
}

void DeleteObjectsInList(array<int> &inout ids) {
    int num_ids = ids.length();
    for(int i=0; i<num_ids; ++i){
        Log(info, "Test");
        DeleteObjectID(ids[i]);
    }
    ids.resize(0);
}

vec3 GetRandomFurColor() {
    vec3 fur_color_byte;
    int rnd = rand() % 7;

    //TODO! Extend this
    switch(rnd) {
        case 0: fur_color_byte = vec3(255); break;
        case 1: fur_color_byte = vec3(34); break;
        case 2: fur_color_byte = vec3(137); break;
        case 3: fur_color_byte = vec3(105, 73, 54); break;
        case 4: fur_color_byte = vec3(53, 28, 10); break;
        case 5: fur_color_byte = vec3(172, 124, 62); break;
        case 6: fur_color_byte = vec3(74, 86, 89); break;
    }

    return FloatTintFromByte(fur_color_byte);
}

// Convert byte colors to float colors (255,0,0) to (1.0f,0.0f,0.0f)
vec3 FloatTintFromByte(const vec3 &in tint) {
    vec3 float_tint;
    float_tint.x = tint.x / 255.0f;
    float_tint.y = tint.y / 255.0f;
    float_tint.z = tint.z / 255.0f;
    return float_tint;
}

///
///     General stuff
///

void VersusInit(string p_level_name) {
    FindSpawnPoints();
    // Spawn 4 players, otherwise it gets funky and spawns a player where editor camera was
    for(int i = 0; i < 4; i++)
    {
        SpawnCharacter(FindRandSpawnPoint(i),CreateCharacter(i, IntToSpecies(currentRace[i])));
    }
    
    timer.Add(LevelEventJob("reset", function(_params){
        DeleteObjectsInList(spawned_object_ids);
        for(uint i = 0; i < players_number; i++)
        {
            SpawnCharacter(FindRandSpawnPoint(i),CreateCharacter(i, IntToSpecies(currentRace[i])));
        }
        return true;
    }));
}

void VersusReset(){
    DeleteObjectsInList(spawned_object_ids);
    for(uint i = 0; i < players_number; i++)
    {
        SpawnCharacter(FindRandSpawnPoint(i),CreateCharacter(i, IntToSpecies(currentRace[i])));
    }
}

void VersusDrawGUI(){
    versusAHGUI.Render();
}

void VersusUpdate() {
    timer.Update();

    if(GetInputDown(0,"f8")){
        LoadLevel(GetCurrLevelRelPath());
    }

    if(GetInputDown(0,"f10")){
        level.SendMessage("reset");
    }

    // Forces call `Notice` on all characters (helps with npc just standing there like morons)
    if(set_omniscientTimeSpan<0){
        set_omniscientTimer = set_omniscientTimer-time_step;
        for (uint i = 0; i < spawned_object_ids.size(); i++) {
            Object@ char = ReadObjectFromID(spawned_object_ids[i]);
            char.ReceiveScriptMessage("set_omniscient true");
        }
    }

    CheckPlayersState();
    // On first update we switch to warmup state
    if(currentState==99){
        ChangeGameState(0);
    }

    PlaySong("ambient-tense");
    versusAHGUI.Update();
}

void VersusReceiveMessage(string msg){
    timer.AddLevelEvent(msg);
}

void VersusPreScriptReload(){
    timer.DeleteAll();
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
    Species("dog", "Textures/ui/arena_mode/glyphs/fighter_swords.png",
        {
            "Data/Characters/lt_dog_big.xml",
            "Data/Characters/lt_dog_female.xml",
            "Data/Characters/lt_dog_male_1.xml",
            "Data/Characters/lt_dog_male_2.xml"
        }),
    Species("cat", "Textures/ui/arena_mode/glyphs/contender_crown.png",
        {
            "Data/Characters/fancy_striped_cat.xml",
            "Data/Characters/female_cat.xml",
            "Data/Characters/male_cat.xml",
            "Data/Characters/striped_cat.xml"
        }),
    Species("rat", "Textures/ui/arena_mode/glyphs/slave_shackles.png",
        {
            "Data/Characters/hooded_rat.xml",
            "Data/Characters/female_rat.xml",
            "Data/Characters/rat.xml"
        }),
    Species("wolf", "Textures/ui/arena_mode/glyphs/skull.png",
        {
            "Data/Characters/male_wolf.xml"
        })
};

class VersusAHGUI : AHGUI::GUI {
    VersusAHGUI() {
        // Call the superclass to set things up
        super();
    }
    
    bool layoutChanged = true;
    string text="1";
    string extraText="2";
    int assignmentTextSize = 70;
    int footerTextSize = 50;
    bool showBorders = false;
    bool initUI = true;
    
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
    void SetText(string maintext, string subtext=""){
        text = InsertKeysToString(maintext);
        extraText = InsertKeysToString(subtext);
        layoutChanged = true;
    }
    
    void UpdateText(){
        AHGUI::Element@ headerElement = root.findElement("header");
        if( headerElement is null  ) {
            DisplayError("GUI Error", "Unable to find header");
        }
        AHGUI::Divider@ header = cast<AHGUI::Divider>(headerElement);
        // Get rid of the old contents
        header.clear();
        header.clearUpdateBehaviors();
        header.setDisplacement();
        DisplayText(DDTop, header, 8, text, 90, vec4(1,1,1,1), extraText, 70);
    }
    
    void ChangeIcon(int playerIdx, int iconNr, bool glow)
    {
        if(blockSpeciesChange)
            return;
        AHGUI::Element@ headerElement = root.findElement("quitButton"+playerIdx);
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
                quitButton.setColor(vec4(1.0,1.0,1.0,1.0));
            }
            quitButton.scaleToSizeX(playerIconSize);
        }
    }
    
    void CheckForUIChange(){
        if(initUI){
            initUI = false;
            //TODO: #1 this is a dumb fix for the whole UI being moved a little to right for some reason
    
            //Violet 
            AHGUI::Divider@ container = root.addDivider( DDCenter,  DOVertical, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );
            container.setVeritcalAlignment(BACenter);
            if(showBorders){
                container.setBorderSize(5);
                container.setBorderColor(1.0, 0.0, 1.0, 1.0);
                container.showBorder();
            }
    
            //Cyan For Text
            AHGUI::Divider@ header = container.addDivider( DDTopLeft,  DOVertical, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );
            header.setName("header");
            header.setVeritcalAlignment(BARight);
            header.setHorizontalAlignment(BABottom);
            if(showBorders){
                header.setBorderSize(3);
                header.setBorderColor(0.0, 1.0, 1.0, 1.0);
                header.showBorder();
            }
    
            AHGUI::Divider@ containerBottom = root.addDivider( DDTop,  DOHorizontal, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );
            AHGUI::Divider@ containerTop = root.addDivider( DDBottom,  DOHorizontal, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );
    
            //Yellow
            AHGUI::Divider@ header3 = containerBottom.addDivider( DDRight,  DOHorizontal, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );
            header3.setName("header3");
            header3.setVeritcalAlignment(BALeft);
            header3.setHorizontalAlignment(BABottom);
            if(showBorders){
                header3.setBorderSize(3);
                header3.setBorderColor(1.0, 1.0, 0.0, 1.0);
                header3.showBorder();
            }
    
            AHGUI::Image@ quitButton3 = AHGUI::Image(placeholderRaceIconPath);
            //#1
            quitButton3.setPadding(0,0,0,70);
            quitButton3.scaleToSizeX(playerIconSize);
            quitButton3.setName("quitButton3");
            header3.addElement(quitButton3,DDLeft);
    
    
            //Blue
            AHGUI::Divider@ header2 = containerBottom.addDivider( DDLeft,  DOHorizontal, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );
            header2.setName("header2");
            header2.setVeritcalAlignment(BALeft);
            header2.setHorizontalAlignment(BABottom);
            if(showBorders){
                header2.setBorderSize(3);
                header2.setBorderColor(0.0, 0.0, 1.0, 1.0);
                header2.showBorder();
            }
    
            AHGUI::Image@ quitButton2 = AHGUI::Image(placeholderRaceIconPath);
            quitButton2.scaleToSizeX(playerIconSize);
            quitButton2.setName("quitButton2");
            header2.addElement(quitButton2,DDLeft);
    
            //Red
            AHGUI::Divider@ header1 = containerTop.addDivider( DDRight,  DOHorizontal, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );
            header1.setName("header1");
            header1.setVeritcalAlignment(BALeft);
            header1.setHorizontalAlignment(BABottom);
            if(showBorders){
                header1.setBorderSize(3);
                header1.setBorderColor(1.0, 0.0, 0.0, 1.0);
                header1.showBorder();
            }
    
            AHGUI::Image@ quitButton1 = AHGUI::Image(placeholderRaceIconPath);
            quitButton1.scaleToSizeX(playerIconSize);
            //#1
            quitButton1.setPadding(0,0,0,70);
            quitButton1.setName("quitButton1");
            header1.addElement(quitButton1,DDLeft);
    
            //Green
            AHGUI::Divider@ header0 = containerTop.addDivider( DDLeft,  DOHorizontal, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );
            header0.setName("header0");
            header0.setVeritcalAlignment(BALeft);
            header0.setHorizontalAlignment(BABottom);
            if(showBorders){
                header0.setBorderSize(3);
                header0.setBorderColor(0.0, 1.0, 0.0, 1.0);
                header0.showBorder();
            }
    
            AHGUI::Image@ quitButton0 = AHGUI::Image(placeholderRaceIconPath);
            quitButton0.scaleToSizeX(playerIconSize);
            quitButton0.setName("quitButton0");
            header0.addElement(quitButton0,DDLeft);
        }
    
        if(layoutChanged){
            layoutChanged = false;
        }
        UpdateText();
        AHGUI::GUI::update();
    }
    
    void DisplayText(DividerDirection dd, AHGUI::Divider@ div, int maxWords, string text, int textSize, vec4 color, string extraTextVal = "", int extraTextSize = 0) {
        //The maxWords is the amount of words per line.
        array<string> sentences;
    
        text = InsertKeysToString( text );
    
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
            AHGUI::Text singleSentence( sentences[k], "OpenSans-Regular", textSize, color.x, color.y, color.z, color.a );
            singleSentence.setShadowed(true);
            //singleSentence.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );
            div.addElement(singleSentence, dd);
            if(showBorders){
                singleSentence.setBorderSize(1);
                singleSentence.setBorderColor(1.0, 1.0, 1.0, 1.0);
                singleSentence.showBorder();
            }
        }
        if(extraTextVal != ""){
            AHGUI::Text extraSentence(extraTextVal, "OpenSans-Regular", extraTextSize, color.x, color.y, color.z, color.a );
            extraSentence.setShadowed(true);
            div.addElement(extraSentence, dd);
        }
    }
    
    void Update(){
        CheckForUIChange();
        AHGUI::GUI::update();
    }
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

        //SetSpawnPointPreview(obj,level.GetPath("spawn_preview"));
        Object @obj = ReadObjectFromID(object_ids[i]);
        ScriptParams@ params = obj.GetScriptParams();
        if(params.HasParam("game_type")){
            // Check whether this spawn is "versusBrawl" type
            if(params.GetString("game_type")=="versusBrawl"){
                // Check for PlayerNr
                if(params.HasParam("playerNr")) {
                    int playerNr= params.GetInt("playerNr");
                    if(playerNr < -1 || playerNr > 3){
                        DisplayError("FindSpawnPoints Error", "Spawn has PlayerNr less than -1 and greater than 3");
                    }
                    if(playerNr==-1){
                        // If its -1, its a generic spawn point, add it to the last array (generic spawns)
                        spawnPointIds[spawnPointIds.size()].resize(spawnPointIds[spawnPointIds.size()].size() + 1);
                        spawnPointIds[spawnPointIds.size()][spawnPointIds[spawnPointIds.size()].size()] = object_ids[i];
                    }
                    else{
                        // If its 0 or greater, make sure it lands on the correct playerIndex array
                        spawnPointIds[playerNr].resize(spawnPointIds[playerNr].size() + 1);
                        spawnPointIds[playerNr][spawnPointIds[playerNr].size()-1] = object_ids[i];
                    }
                }
            }
        }
    }
}

// This makes sure there is atleast a single spawn per playerNr
bool CheckSpawnsNumber() {
    for (int i = 0; i < 3; i++) {
        if(spawnPointIds[i].size() < 1)
            return false;
    }
    return true;
}

void CheckPlayersState() {
    if(currentState==0){
        if(!CheckSpawnsNumber() && failsafe) {
            //Warn about the incorrect number of spawns
            ChangeGameState(1);
        }
		array<int> movement_objects = GetObjectIDsType(_movement_object);
        
        //Select players number
		if(GetInputDown(0,"item") && !GetInputDown(0,"drop")){
			if(GetInputDown(0,"crouch")){
				players_number = 2;
                ChangeGameState(2); //Start game
			}
			if(GetInputDown(0,"jump")){
				players_number = 3;
                ChangeGameState(2); //Start game
			}
			if(GetInputDown(0,"attack")){
				players_number = 4;
                ChangeGameState(2); //Start game
			}
		}
    }
    else if(currentState==1) {
        if (GetInputDown(0, "item")) {
            failsafe = false;
            ChangeGameState(0);
        }
    }
    
    if(currentState==2 || constantRespawning){
        // Respawning logic
        for (uint i = 0; i < respawnQueue.size() ; i++) {
            if(respawnQueue[i]>-respawnBlockTime){
                respawnQueue[i] = respawnQueue[i]-time_step;
                if(respawnQueue[i]<0 && respawnNeeded[i]){
                    respawnNeeded[i] = false;
                    MovementObject@ mo = ReadCharacter(i);
                    Object@ char = ReadObjectFromID(mo.GetID());
                    ScriptParams@ params = char.GetScriptParams();

                    // This line took me 4hrs to figure out
                    mo.Execute("SetState(0);Recover();");

                    SpawnCharacter(FindRandSpawnPoint(i),char,true);
                }
            }
        }
    }
    
    if((currentState>=2 || currentState==0) && !blockSpeciesChange){
        for(int i=0; i<GetNumCharacters(); i++){
            if(GetInputDown(i,"item") && GetInputDown(i,"drop")) {
                if(GetInputPressed(i,"attack")) {
                    currentRace[i]= currentRace[i]+1;
                    currentRace[i]= currentRace[i]%speciesMap.size();
                    
                    if(currentState==0 || instantSpeciesChange){
                        MovementObject@ mo = ReadCharacter(i);
                        Object@ char = ReadObjectFromID(mo.GetID());
                        RerollCharacter(i,char);
                    }
                }
                versusAHGUI.ChangeIcon(i, currentRace[i], true);
            }
            else {
                // Last element is always the default state icon
                versusAHGUI.ChangeIcon(i, -1, false);
            }
        }
    }
}

void ChangeGameState(uint newState) {
    if(newState == currentState)
        return;
    switch (newState) {
        case 0: 
            //Warmup, select player number
            failsafe = true;
            currentState = newState;
            versusAHGUI.SetText("Hold @item@ and select player number by then pressing:",
                "@crouch@=2, @jump@=3, @attack@=4");
            break;
        case 1: 
            //Failsafe, not enough spawns, waiting for acknowledgment
            //TODO! Rewrite this for spawns
            if(failsafe){
                array<int> movement_objects = GetObjectIDsType(_movement_object);
                versusAHGUI.SetText("Warning! Only "+movement_objects.size()+" players detected!",
                    "After adding more player controlled characters, please save and reload the map. Press @item@ to play anyway.");

                return;
            }
            currentState = newState;
            break;
        case 2:
            //Game Start
            currentState = newState;
            PlaySound("Data/Sounds/versus/voice_start_1.wav");
            // Clear text
            versusAHGUI.SetText("");
            level.SendMessage("reset");
            break;
    }
}
