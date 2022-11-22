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

        lvlParams.SetInt("MainPlayerId", obj_id);

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
        vec3 translation = charObj.GetTranslation();
        // Space them a little to avoid clipping
        translation.y += 1;
        switch (j) {
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
        newCharObj.SetTranslation(translation);
        
        //TEST
        RecolorCharacter(j, newCharParams.GetString("Species"), newCharObj);
        newChar.controller_id = j;
        newCharObj.SetPlayer(true);
    }
}