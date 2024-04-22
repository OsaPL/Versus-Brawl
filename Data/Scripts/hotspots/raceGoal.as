#include "timed_execution/timed_execution.as"
#include "timed_execution/char_death_job.as"
#include "timed_execution/level_event_job.as"

#include "hotspots/placeholderFollower.as"

array<int> connected_object_ids;
array<LinkedObjectState@> atLoadState;

uint playersMax = 4;

class LinkedObjectState{
    int id;
    bool state;
    LinkedObjectState(int newId, bool newState){
        id = newId;
        state = newState;
    }
}

bool init=true;

bool firstActivation = true;

void Init() {

}

void SetParameters() {
    for (uint i = 0; i < playersMax; i++) {
        params.AddIntCheckbox("player"+i+"Reached", false);
    }
    params.AddString("type", "raceGoalHotspot");
    params.AddString("gameMode", "Race");
    params.AddString("game_type", "versusBrawl");
}

void Update(){
    if(init){
        connected_object_ids = hotspot.GetConnectedObjects();
        
        //Disable all spawns objects
        for (uint i = 0; i < connected_object_ids.size(); i++) {
            Object@ obj = ReadObjectFromID(connected_object_ids[i]);
            
            // Check if its a spawn
            if(IsSpawnObject(obj)){
                obj.SetEnabled(false);
                Log(error, "Disabled:"+connected_object_ids[i]);
            }
        }
        init = false;
    }

    Object@ me = ReadObjectFromID(hotspot.GetID());
    
    string playersReached = "[Reached]";
    vec3 meScale = me.GetScale();
    float avgScale = (meScale.x + meScale.y) / 2;
    

    for (uint j = 0; j < playersMax; j++)
    {
        string playerString = " ";
        string reached = params.GetInt("player" + j + "Reached") == 1 ? "yes" : "no";
        playerString += j + ":" + reached;
        playersReached += playerString;
        vec3 teamColor = GetTeamUIColor(j);

        float xDir = (j == 3 || j == 1) ? -1 : 1;
        float yDir = (j == 1 || j == 0) ? -1 : 1;
        vec3 direction = me.GetRotation() * vec3(xDir, yDir , 0);
        vec3 teamOffset = vec3(meScale.x / 2, meScale.y / 2, meScale.z) * 2.0f * direction;

        //Log(error, "j: "+ j + " xDir: " + xDir + " yDir: " + yDir);
        
        if(params.GetInt("player" + j + "Reached") == 1)
            PlaceHolderFollowerUpdate("Data/Textures/ui/challenge_mode/checkmark_icon.png", "", avgScale, false, vec4(teamColor, 0.7f), teamOffset);
    }
    string enabled = me.GetEnabled() ? "Enabled" : "Disabled";
    if(EditorModeActive()){
        PlaceHolderFollowerUpdate("Data/Textures/ui/versusBrawl/flag_icon.png", "[RaceGoal] " + playersReached + " [" + enabled + "]", avgScale, true);
    }
    else{
        PlaceHolderFollowerUpdate("Data/Textures/ui/versusBrawl/flag_icon.png", "", avgScale, false, vec4(1.5f));
    }
}

void Reset(){
    
    for (uint i = 0; i < playersMax; i++) {
        params.SetInt("player"+i+"Reached", 0);
    }

    //Switch all nonspawns back
    for (uint j = 0; j <atLoadState.size() ; j++) {
        Object@ obj = ReadObjectFromID(atLoadState[j].id);
        
        obj.SetEnabled(atLoadState[j].state);
        Log(error, "Reset switch:" + obj.GetID());
    }
    
    init = true;
    firstActivation = true;
}

void Dispose(){

}

bool AcceptConnectionsTo(Object@ other) {
    return true;
}

bool AcceptConnectionsFrom(Object@ other) {
    ScriptParams@ objParams = other.GetScriptParams();
    
    if(IsGoalObject(other))
        return true;
    return false;
}

bool ConnectTo(Object@ other){
    Log(error, "connecting to:"+other.GetID());
    // Disable the spawns
    if(IsSpawnObject(other)) {
        other.SetEnabled(false);
    }
    else{
        // Put its initial state in
        ScriptParams@ objParams = other.GetScriptParams();
        if(objParams.HasParam("KeepDisabled")){
            atLoadState.push_back(LinkedObjectState(other.GetID(), false));
            other.SetEnabled(false);
            Log(error, "non spawn object:"+other.GetID() + " KeepDisabled");
        }
        else{
            atLoadState.push_back(LinkedObjectState(other.GetID(), true));
            Log(error, "non spawn object:"+other.GetID());
        }
    }
    return true;
}

bool IsAcceptedConnectionType(Object@ other){
    ScriptParams@ params = other.GetScriptParams();
    if(params.HasParam("playerNr")){
        return true;
    }
    return false;
}

bool IsGoalObject(Object@ obj){
    ScriptParams@ objParams = obj.GetScriptParams();
    if(objParams.HasParam("type"))
        if(objParams.GetString("type") == "raceGoalHotspot")
            return true;
    return false;
}

bool IsSpawnObject(Object@ obj){
    ScriptParams@ objParams = obj.GetScriptParams();
    if(objParams.HasParam("playerNr") && objParams.HasParam("game_type")) {
        if (objParams.GetString("game_type") == "versusBrawl") {
            return true;
        }
    }
    return false;
}

void HandleEvent(string event, MovementObject @mo){
    Object@ me = ReadObjectFromID(hotspot.GetID());
   
    
    // If disabled, ignore
    if(!me.GetEnabled())
        return;

    ScriptParams@ lvlParams = level.GetScriptParams();
    
    if(event == "enter"){
        if(mo.is_player){
            // Check if this is already taken by that playerNr
            if(params.GetInt("player"+mo.controller_id+"Reached") != 1){
                params.SetInt("player"+mo.controller_id+"Reached", 1);
                level.SendMessage("checkpoint "+mo.controller_id);  
                
                PlaySoundGroup("Data/Sounds/versus/fight_win1.xml");

                for (uint i = 0; i < connected_object_ids.size(); i++) {
                    Object@ obj = ReadObjectFromID(connected_object_ids[i]);
                    ScriptParams@ params = obj.GetScriptParams();
                    
                    // If theyre linked both ways, means theyre brothers, and should set what player reached
                    if(IsGoalObject(obj)){
                        Hotspot@ otherGoal = cast<Hotspot>(obj);
                        array<int> @object_ids = otherGoal.GetConnectedObjects();
                        
                        if(object_ids.find(me.GetID()) >= 0){
                            params.SetInt("player"+mo.controller_id+"Reached", 1);
                            continue;
                        }
                    }
    
                    // Check if its a spawn
                    if(IsSpawnObject(obj)){
                        if(params.GetInt("playerNr") == mo.controller_id){
                            // Disable all other ones for this player
                            array<int> @object_ids = GetObjectIDs();
                            for (uint j = 0; j <object_ids.size() ; j++) {
                                Object@ objTemp = ReadObjectFromID(object_ids[j]);
                                ScriptParams@ objParams = objTemp.GetScriptParams();
                
                                if(objParams.HasParam("game_type") && objParams.HasParam("playerNr") ){
                                    if(objParams.GetString("game_type") == "versusBrawl" && objParams.GetInt("playerNr") ==  mo.controller_id){
                                        Log(error, "Found spawn with ID:"+ object_ids[j]+" playerNr:"+ objParams.GetInt("playerNr"));
                                        objTemp.SetEnabled(false);
                                    }
                                }
                            }
                            
                
                            // Switch the one connected
                            obj.SetEnabled(true);
                        }
                    }
                }
            }

            // Its not a spawn, just switch the enable flag it and send an event to notify
            if(firstActivation){
                // Switch the one connected
                for (uint j = 0; j <atLoadState.size() ; j++) {
                    Object@ objTemp = ReadObjectFromID(atLoadState[j].id);
                    
                    // If theyre linked both ways, means theyre brothers, dont do anything
                    if(IsGoalObject(objTemp)){
                        Hotspot@ otherGoal = cast<Hotspot>(objTemp);
                        array<int> @object_ids = otherGoal.GetConnectedObjects();
                        
                        if(object_ids.find(me.GetID()) >= 0){
                            // No need to change Enabled state in this case
                            continue;
                        }
                    }
                                        
                    objTemp.SetEnabled(!atLoadState[j].state);
                    objTemp.ReceiveScriptMessage("switch");
                    
                    Log(error, "checkpoint switch:"+atLoadState[j].id + " enabled:" + objTemp.GetEnabled());
                }
                firstActivation = false;
            }
            
        }
    }
}

// TODO: this is already in colorHelper
vec3 GetTeamUIColor(int playerNr){
    switch (playerNr) {
        case 0:
            //Green
            return vec3(0.0f,0.8f,0.0f);
        case 1:
            //Red
            return vec3(0.8f,0.0f,0.0f);
        case 2:
            //Blue
            return vec3(0.1f,0.1f,0.8f);
        case 3:
            //Yellow
            return vec3(0.9f,0.9f,0.1f);
        default: //DisplayError("RandReasonableTeamColor", "Unsuported RandReasonableTeamColor value of: " + playerNr);
            //Purple guy?
            return vec3(1.0f,0.0f,1.0f);
    }
    return vec3(1.0f);
}