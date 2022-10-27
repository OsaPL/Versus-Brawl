#include "hotspots/placeholderFollower.as"

void Init() {
    hotspot.SetCollisionEnabled(false);
}

void SetParameters() {
    params.AddIntSlider("playerNr", -1, "min:-1.0,max:3.0");
    params.AddString("game_type", "versusBrawl");
}

void Update(){
    PlaceHolderFollowerUpdate();

    int playerNr = params.GetInt("playerNr");

    // Get hotspot and placeholder, and then setup
    Object@ obj = ReadObjectFromID(placeholderId);
    PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(obj);
    placeholder_object.SetBillboard("Data/Textures/ui/versusBrawl/placeholder_arena_spawn_"+playerNr+".png");

    obj.SetEditorLabel("["+playerNr+"]");
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