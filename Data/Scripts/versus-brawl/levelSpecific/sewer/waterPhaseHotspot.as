#include "hotspots/placeholderFollower.as"

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
    Log(error, "" + hotspot.GetID() + "connecting to:"+other.GetID());
    return true;
}