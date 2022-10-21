array<int> coopPartners = {-1,-1,-1,-1};
array<float> coopPartnersToSetup = {0.0f,0.0f,0.0f};
float timeToWait = 0.8f;
int coopPartnersNr = 0;

void CoopPartnersDispose(){
    for (uint i = 1; i < coopPartners.size(); i++)
    {
        if(coopPartners[i] != -1)
            DeleteObjectID(coopPartners[i]);
    }
}

void CoopPartnersCheck(){
    
    // If this level is `versusBrawl` ignore, no need to interfere
    ScriptParams@ lvlParams = level.GetScriptParams();
    if(lvlParams.HasParam("game_type"))
        if(lvlParams.GetString("game_type") == "versusBrawl")
            return;
    
    // Adds spawning in coop players
    for (uint i = 0; i < coopPartnersToSetup.size(); i++) {
        // We delay the SetPlayer call, cause otherwise its prone to crashes, some kind of race?
        if(coopPartnersToSetup[i]> timeToWait && coopPartnersToSetup[i] < 10.0f){
            Object@ newCharObj = ReadObjectFromID(coopPartners[i+1]);
            ScriptParams@ newCharParams = newCharObj.GetScriptParams();

            RecolorCharacter(coopPartnersNr, newCharParams.GetString("Species"), newCharObj);

            newCharObj.SetPlayer(true);
            coopPartners[i+1] = -1;
            coopPartnersToSetup[i] = 10.0f;
        }
    else{
            if(coopPartners[i+1] != -1)
                coopPartnersToSetup[i] += time_step;
        }
    }

    // Find player 0
    for (int i = 0; i < GetNumCharacters(); i++) {
        MovementObject@ char = ReadCharacter(i);
        Object@ charObj = ReadObjectFromID(char.GetID());
        ScriptParams@ charParams = charObj.GetScriptParams();

        if(char.is_player){
            if(coopPartners[0] == -1){
                coopPartners[0] = char.GetID();
            }

            if(coopPartnersNr<3){
                // This will only allow the last controller_ids to get a into "join in" state
                uint start = coopPartnersNr;
                for (uint j = start; j < coopPartners.size(); j++)
                {
                    if (GetInputPressed(j, "skip_dialogue") && coopPartners[coopPartnersNr + 1] == -1) {
                        coopPartnersNr++;
                        string placeHolderActorPath = "Data/Objects/characters/rabbot_actor.xml";

                        DisplayError("CoopPartnersCheck", "CoopPartnersCheck Created:" + coopPartnersNr);

                        int obj_id = CreateObject(placeHolderActorPath, true);

                        coopPartners[coopPartnersNr] = obj_id;

                        Object@ newCharObj = ReadObjectFromID(obj_id);
                        MovementObject@ newChar = ReadCharacterID(newCharObj.GetID());
                        ScriptParams@ newCharParams = newCharObj.GetScriptParams();

                        // Rewrite character
                        newChar.Execute("SwitchCharacter(\"" + char.char_path + "\");");
                        //newCharObj.SetScriptParams(charObj.GetScriptParams());
                        // TODO! Find a way to copy this cleanly? It looks like you cant really copy/enumerate over script params. Options are:
                        // 1. Expose SetScriptParams() for AS in ScriptParams.cpp
                        // 2. Create a "configure-character <objId>" event message for actor/map makers to use
                        // 3. Make a janky list of possible params ppl use and just do a nasty 'HasParam()` on each of them
                        newCharParams.SetString("Teams", charParams.GetString("Teams"));

                        // Place into the level
                        newCharObj.SetTranslation(charObj.GetTranslation());

                        // Make sure its using corerct controller Id
                        char.controller_id = coopPartnersNr;
                        return;
                    }
                }
            }
        }
    }
}