#include "hotspots/placeholderFollower.as"

bool init = true;
bool switched = false;

void Init() {
    hotspot.SetCollisionEnabled(false);
    Object@ me = ReadObjectFromID(hotspot.GetID());
    me.SetScale(vec3(1, 0.1f, 1));
}

void SetParameters() {
    params.AddIntSlider("Phase", 0, "min:0.0,max:10.0");
    params.AddString("game_type", "versusBrawl");
}

void ReceiveMessage(string msg){
    if(msg == "switch") {
        Switch();
    }
}

void Reset(){
    if(!switched && params.GetInt("Phase") == 0)
        Switch();
    if(switched && params.GetInt("Phase") != 0)
        Switch();
}

void Update(){
    string switchedString = "OFF";
    if(switched)
        switchedString = "ON";
    
    PlaceHolderFollowerUpdate("Data/UI/spawner/thumbs/Hotspot/water.png", "Phase: ["+ params.GetInt("Phase") +"] [" + switchedString + "]");
    
    Object@ me = ReadObjectFromID(hotspot.GetID());
    
    // Reset on entering the editor
    if(EditorModeActive() || init){
        Reset();
        init = false;
    }
}

void Dispose(){
}

bool AcceptConnectionsFrom(Object@ other) {
    ScriptParams@ objParams = other.GetScriptParams();
    // TOOD: Not a pretty way to check, but works
    if(objParams.HasParam("Bobbing Multiplier"))
        return true;
    
    return false;
}

bool AcceptConnectionsTo(Object@ other) {
    // TODO: This should probably just use permission check `obj.permission_flags & Object::CAN_SELECT`
    if(other.IsExcludedFromSave())
        return false;
    
    return true;
}

bool ConnectTo(Object@ other){
    // Put its initial state in
    ScriptParams@ objParams = other.GetScriptParams();
    if(objParams.HasParam("KeepDisabled")){
        other.SetEnabled(false);
        Log(error, "object:"+other.GetID() + " KeepDisabled");
    }
    else{
        Log(error, "object:"+other.GetID());
    }
    return true;
}

void Switch(){
    switched = !switched;

    Object@ phaseObj = ReadObjectFromID(hotspot.GetID());
    array<int> connectedObjs = hotspot.GetConnectedObjects();

    Log(error, "SetEnabledState switched: " + switched + " phases[i]: "+ hotspot.GetID() + " phaseHotspot.GetID(): "+ hotspot.GetID() + " connectedObjs.size(): " + connectedObjs.size());

    // TODO: This is kinda dumb, but it works
    // Switch
    for (uint j = 0; j < connectedObjs.size(); j++) {

        Log(error, "SetEnabledState connectedObjs[j]: "+ connectedObjs[j]);

        Object@ obj = ReadObjectFromID(connectedObjs[j]);
        ScriptParams@ objParams = obj.GetScriptParams();

        if(objParams.HasParam("KeepDisabled")){
            obj.SetEnabled(switched);
        }
        else{
            obj.SetEnabled(!switched);
        }

        // Propagate event further
        obj.ReceiveScriptMessage("switch");
    }
}

// switched    KeepDisabled    Enabled ->switched  Result
// false       true            false   ->true      true
// true        true            true    ->false     false
//
// false       false           true    ->true      false
// true        false           false   ->false     true