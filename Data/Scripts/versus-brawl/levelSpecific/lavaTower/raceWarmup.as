#include "hotspots/placeholderFollower.as"

bool inProgress = false;
bool init = true;

void Init() {

}

void SetParameters() {
    params.AddString("game_type", "versusBrawl");
    params.AddString("type", "raceWarmupHotspot");
}

void ReceiveMessage(string msg){
    if(msg == "switch") {
        inProgress = !inProgress;
    }
}

void Reset(){

}

void Update(){
    string switchedString = "OFF";
    if(inProgress)
        switchedString = "ON";
    
    if(EditorModeActive())
        PlaceHolderFollowerUpdate("Data/Textures/ui/versusBrawl/flag_icon.png", "[raceWarmupHotspot] [" + switchedString + "]", 1.0f, false, vec4(0.2f, 0.8f, 1.0f, 1.0f));
    
    Object@ me = ReadObjectFromID(hotspot.GetID());
    if(me.GetEnabled()){
        Switch();
    }
}

void Dispose(){
}

bool AcceptConnectionsFrom(Object@ other) {
    return false;
}

bool AcceptConnectionsTo(Object@ other) {
    return true;
}

bool ConnectTo(Object@ other){
    return true;
}

void Switch(){
    Object@ me = ReadObjectFromID(hotspot.GetID());
    ScriptParams@ lvlParams = level.GetScriptParams();
    me.SetScale(vec3(0.3f));
    
    if(!lvlParams.HasParam("InProgress"))
        return;
        
    bool currentProgress = lvlParams.GetInt("InProgress") > 0;
    
    if(currentProgress == inProgress)
        return;
    Log(error, "currentProgress: " + currentProgress);
        
    if(currentProgress){
        inProgress = true;
    }
    else{
        inProgress = false;
    }
    
    array<int> @object_ids = hotspot.GetConnectedObjects();
    for (uint i = 0; i < object_ids.size(); i++) {
        Object @obj = ReadObjectFromID(object_ids[i]);
        ScriptParams@ objParams = obj.GetScriptParams();
        
        if(objParams.HasParam("KeepDisabled")){
            obj.SetEnabled(inProgress);
        }
        else{
            obj.SetEnabled(!inProgress);
        }
    }
}