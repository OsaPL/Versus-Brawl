int placeholderId = -1;

void Init() {
    hotspot.SetCollisionEnabled(false);
}

void SetParameters() {
    params.AddIntSlider("playerNr", -1, "min:-1.0,max:3.0");
    params.AddString("game_type", "versusBrawl");
}

void Update(){
    // placeholder is missing create it
    if(placeholderId == -1)
        placeholderId = CreateObject("Data/Objects/placeholder/placeholder_arena_spawn.xml");
    
    int playerNr = params.GetInt("playerNr");
    // Get hotspot and placeholder, and then setup
    Object@ me = ReadObjectFromID(hotspot.GetID());
    Object@ obj = ReadObjectFromID(placeholderId);
    PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(obj);
    placeholder_object.SetBillboard("Data/Textures/ui/versusBrawl/placeholder_arena_spawn_"+playerNr+".png");
    obj.SetEditorLabel("["+playerNr+"]");
    // This part makes placeholder follow
    obj.SetTranslation(me.GetTranslation());
    obj.SetRotation(me.GetRotation());
}

void Dispose(){
    if(ObjectExists(placeholderId)) {
        // Cleanup placeholder
        DeleteObjectID(placeholderId);
    }
}