int placeholderId = -1;

void PlaceHolderFollowerUpdate(){
    // placeholder is missing create it
    if(placeholderId == -1)
        placeholderId = CreateObject("Data/Objects/placeholder/placeholder_arena_spawn.xml");

    Object@ obj = ReadObjectFromID(placeholderId);
    // This part makes placeholder follow
    Object@ me = ReadObjectFromID(hotspot.GetID());
    obj.SetTranslation(me.GetTranslation());
    obj.SetRotation(me.GetRotation());
}

void PlaceHolderFollowerDispose(){
    if(ObjectExists(placeholderId)) {
        // Cleanup placeholder
        DeleteObjectID(placeholderId);
    }
}