// This is specifically detached from versusmode.as and its dependecies to be a easy and clean include for anyone implementing a modded aschar.as, to add cleanly Coop support

#include "colorHelpers.as"

int playerChars = 0;

void CoopPartnersCheck(){
    
    if(!this_mo.is_player)
        return;
    
    ScriptParams@ lvlParams = level.GetScriptParams();
    
    // If this level is `versusBrawl` ignore, no need to interfere
    if(lvlParams.HasParam("game_type"))
        if(lvlParams.GetString("game_type") == "versusBrawl"){
            //DisplayError("CoopPartnersCheck","Ignoring cause versusBrawl");
            return;
        }
    
    Object@ charObj = ReadObjectFromID(this_mo.GetID());
    ScriptParams@ charParams = charObj.GetScriptParams();
    
    if(charParams.HasParam("LocalPlayer")) {
        return;
    }
    
    // We move the character slightly up, to accomodate for more players
    charObj.SetTranslation(charObj.GetTranslation() + vec3(0, 0.5f, 0));
    
    int missingCharacters = GetConfigValueInt("local_players");
    int num_chars = GetNumCharacters();
    // We count already available player controlled characters
    for(int i=0; i<num_chars; ++i)
    {
        MovementObject@ mo = ReadCharacter(i);
        if(mo.is_player){
            playerChars++;
        }
    }

    // Calculate how many more to spawn
    missingCharacters -= playerChars;
    for (int j = 1; j < missingCharacters+1; j++)
    {
        string placeHolderActorPath = "Data/Objects/characters/rabbot_actor.xml";

        // We check for a custom actor path to use
        if (lvlParams.HasParam("characterActorPath"))
            placeHolderActorPath = lvlParams.GetString("characterActorPath");

        int obj_id = CreateObject(placeHolderActorPath, true);

        Object
        @newCharObj = ReadObjectFromID(obj_id);
        MovementObject
        @newChar = ReadCharacterID(newCharObj.GetID());
        ScriptParams
        @newCharParams = newCharObj.GetScriptParams();

        // Rewrite character
        newChar.Execute("SwitchCharacter(\"" + this_mo.char_path + "\");");
        //newCharObj.SetScriptParams(charObj.GetScriptParams());
        // TODO! Find a way to copy this cleanly? It looks like you cant really copy/enumerate over script params. Options are:
        // 1. Expose SetScriptParams() for AS in ScriptParams.cpp
        // 2. Create a "configure-character <objId>" event message for actor/map makers to use
        // 3. Make a janky list of all possible params ppl use and just do a nasty 'HasParam()` on each of them
        newCharParams.SetString("Teams", charParams.GetString("Teams"));
        newCharParams.SetInt("LocalPlayer", 1);
        newCharObj.UpdateScriptParams();

        // Place into the level
        MovePlayerObject(charObj ,newCharObj);
        
        //TEST
        RecolorCharacter(j, newCharParams.GetString("Species"), newCharObj);
        newChar.controller_id = j;
        newCharObj.SetPlayer(true);
    }
}

void CoopPanic(){
    // Dont allow first player to do this
    if(this_mo.controller_id == 0)
        return;
    
    if(GetInputPressed(this_mo.controller_id, "skip_dialogue")){
        Log(error, "skip_dialogue pressed on: " + this_mo.controller_id + "this_mo.GetID()" + this_mo.GetID() );

        //Revive if needed.
        // FUN fact, that took me like an hour to figure out, this doesnt work in the context of aschar.as
        //this_mo.Execute("SetState(0);Recover();");
        SetState(0);
        Recover();
        
        int obj_id = FindPlayerZero();
        MovementObject@ mainPlayerMo = ReadCharacterID(obj_id);
        Object @mainPlayerObj = ReadObjectFromID(obj_id);
        Object @obj = ReadObjectFromID(this_mo.GetID());
        
        this_mo.position = mainPlayerMo.position;
        this_mo.velocity = vec3(0);
        this_mo.SetRotationFromFacing(mainPlayerMo.GetFacing());
        
        //Also move the object itself
        MovePlayerObject(mainPlayerObj, obj, true);
    }
}

// This moves the characters object, helps with Resets
void MovePlayerObject(Object @mainPlayerObj, Object @obj, bool exact = false){
    
    vec3 translation = mainPlayerObj.GetTranslation();

    MovementObject@ newMo = ReadCharacterID(obj.GetID());
    
    // Space them a little to avoid clipping
    translation.y += 1;
    
    if(!exact){
        switch (newMo.controller_id) {
            case 1:
                translation.x += 1;
                break;
            case 2:
                translation.x -= 1;
                break;
            case 3:
                translation.z -= 1;
                break;
        }
    }

    obj.SetTranslation(translation);
    obj.SetRotation(mainPlayerObj.GetRotation());
}

int FindPlayerZero(){
    int num_chars = GetNumCharacters();
    // We count already available player controlled characters
    for(int i=0; i<num_chars; ++i)
    {
        MovementObject@ mo = ReadCharacter(i);
        if(mo.controller_id == 0 && mo.is_player){
            return mo.GetID();
        }
    }
    return -1;
}