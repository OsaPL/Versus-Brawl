
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
    
    for (int j = 1; j < GetConfigValueInt("local_players"); j++)
    {
        DisplayError("CoopPartnersCheck","CoopPartnersCheck: "+GetConfigValueInt("local_players") + " j:" + j);
        
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
        newCharObj.SetTranslation(charObj.GetTranslation());
        
        //TEST
        RecolorCharacter(j, newCharParams.GetString("Species"), newCharObj);
        newChar.controller_id = j;
        newCharObj.SetPlayer(true);
    }
}