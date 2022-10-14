#include "timed_execution/timed_execution.as"
#include "timed_execution/char_death_job.as"
#include "timed_execution/level_event_job.as"

array<int> connected_object_ids;
bool init=true;

void Init() {

}

void SetParameters() {
    for (int i = 0; i < 4; i++) {
        params.AddIntSlider("player"+i+"Reached", -1, "min:-1.0,max:0.0");
    }
    params.AddString("gameMode", "Race");
    params.AddString("game_type", "versusBrawl");
}

void Update(){
    if(init){
        connected_object_ids = hotspot.GetConnectedObjects();

        //Disable all connected objects
        for (uint i = 0; i < connected_object_ids.size(); i++) {
            Object@ obj = ReadObjectFromID(connected_object_ids[i]);
            obj.SetEnabled(false);
            Log(error, "is connected to:"+connected_object_ids[i]+ "enabled:"+ obj.GetEnabled());
        }
        init = false;
    }
}

void Reset(){
    for (int i = 0; i < 4; i++) {
        params.SetInt("player"+i+"Reached", -1);
    }
    init = true;
}

void Dispose(){

}

bool AcceptConnectionsTo(Object@ other) {
    ScriptParams@ objParams = other.GetScriptParams();
    if(objParams.HasParam("playerNr") && objParams.HasParam("game_type")){
        if(objParams.GetString("game_type") == "versusBrawl"){
            return true;
        }
    }
    return false;
}

bool AcceptConnectionsFrom(Object@ other) {
    return false;
}

bool ConnectTo(Object@ other){
    Log(error, "connecting to:"+other.GetID());
    // Disable the spawn
    other.SetEnabled(false);
    return true;
}

bool IsAcceptedConnectionType(Object@ other){
    ScriptParams@ params = other.GetScriptParams();
    if(params.HasParam("playerNr")){
        return true;
    }
    return false;
}

void HandleEvent(string event, MovementObject @mo){
    
    ScriptParams@ lvlParams = level.GetScriptParams();
    if(lvlParams.HasParam("InProgress"))
        if(lvlParams.GetInt("InProgress") < 1){
            //Ignore if the game didnt start yet
            return;
        }
    
    if(event == "enter"){
        if(mo.is_player){
            // Check if this is already taken by that playerNr
            if(params.GetInt("player"+mo.controller_id+"Reached") == 0){
                Log(error, "reached already by:"+mo.controller_id);
                return;
            }

            params.SetInt("player"+mo.controller_id+"Reached", 0);
            
            PlaySoundGroup("Data/Sounds/versus/fight_win1.xml");

            for (uint i = 0; i < connected_object_ids.size(); i++) {
                Object@ obj = ReadObjectFromID(connected_object_ids[i]);
                ScriptParams@ params = obj.GetScriptParams();
                
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

                    // Enable the one connected
                    obj.SetEnabled(true);
                    //TODO! receive and increment checkpoints number in race Gamemode script
                    level.SendMessage("checkpoint "+mo.controller_id);
                    break;
                }
            }
        }
    }
}