#include "hotspots/placeholderFollower.as"

void Init() {
    hotspot.SetCollisionEnabled(false);
}

void SetParameters() {
    params.AddIntSlider("playerNr", -1, "min:-1.0,max:3.0");
    params.AddString("game_type", "versusBrawl");
    params.AddString("type", "playerSpawnHotspot");
}

void Update(){
    Object@ me = ReadObjectFromID(  hotspot.GetID());

    string enabled = me.GetEnabled() ? "Enabled" : "Disabled";
    int playerNr = params.GetInt("playerNr");

    if(EditorModeActive()){
        PlaceHolderFollowerUpdate("Data/Textures/ui/versusBrawl/placeholder_arena_spawn_"+playerNr+".png", "["+playerNr+"] [" + enabled + "]", 2.0f, true);
    }
}

void Dispose(){
}

bool AcceptConnectionsFrom(Object@ other) {
    return true;
}

bool AcceptConnectionsTo(Object@ other) {
    return true;
}

bool ConnectTo(){
    return true;
}