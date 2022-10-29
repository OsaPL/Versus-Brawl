#include "hotspots/placeholderFollower.as"

bool init = true;
bool switched = false;

void Init() {
    Object@ me = ReadObjectFromID(hotspot.GetID());
    me.SetScale(vec3(1, 0.1f, 1));
    hotspot.SetCollisionEnabled(false);
}

void SetParameters() {
    params.AddIntSlider("Phase", 0, "min:0.0,max:10.0");
    params.AddString("game_type", "versusBrawl");
    
    Object@ me = ReadObjectFromID(hotspot.GetID());
    me.SetEditorLabel("["+ params.GetInt("Phase") +"]");
}

void ReceiveMessage(string msg){
    if(msg == "switch"){
        Switch();
    }
}

void Reset(){
    // Reset if switched back
    //TODO! This will be uncommented once, WaterRise starts supporting reset
    // if(switched)
    //     Switch();
}

void Update(){
    PlaceHolderFollowerUpdate();
    
    // Get hotspot and placeholder, and then setup
    Object@ obj = ReadObjectFromID(placeholderId);
    PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(obj);
    placeholder_object.SetBillboard("Data/UI/spawner/thumbs/Hotspot/water.png");

    obj.SetEditorLabel("Phase: ["+ params.GetInt("Phase") +"]");
}

void Dispose(){
    PlaceHolderFollowerDispose();
}

bool AcceptConnectionsFrom(Object@ other) {
    return true;
}

bool AcceptConnectionsTo(Object@ other) {
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
    Object@ phaseObj = ReadObjectFromID(hotspot.GetID());
    array<int> connectedObjs = hotspot.GetConnectedObjects();
    Log(error, "SwitchConnected phases[i]: "+ hotspot.GetID() + " phaseHotspot.GetID(): "+ hotspot.GetID() + " connectedObjs.size(): " + connectedObjs.size());

    // TODO: This is kinda dumb, but it works
    // Switch
    for (uint j = 0; j < connectedObjs.size(); j++) {

        Log(error, "switch connectedObjs[j]: "+ connectedObjs[j]);

        Object@ obj = ReadObjectFromID(connectedObjs[j]);
        ScriptParams@ objParams = obj.GetScriptParams();

        obj.SetEnabled(!obj.GetEnabled());
        switched = !switched;
        
        // Propagate event further
        obj.ReceiveScriptMessage("switch");
    }
}