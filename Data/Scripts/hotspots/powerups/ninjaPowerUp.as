float respawnTime = 3;
float activeTime = 2;

int placeholderId = -1;
float respawnPickupTimer = 0;
int lastEnteredPlayerObjId = -1;
bool activated = true;

array<int> spawned_objectIds = {};

void HandleEvent(string event, MovementObject @mo)
{
    ScriptParams@ lvlParams = level.GetScriptParams();
    if (lvlParams.HasParam("InProgress"))
        if (lvlParams.GetInt("InProgress") < 1) {
            //Ignore if the game didnt start yet
            return;
        }
    
    if (event == "enter") {
        if (mo.is_player) {
            lastEnteredPlayerObjId = mo.GetID();
            
            if(respawnPickupTimer<=0 && !activated){
                activated = true;
                respawnPickupTimer = respawnTime;
                int emitterId = CreateObject("Data/Objects/powerups/objectFollowerEmitter.xml");
                spawned_objectIds.push_back(emitterId);
                Object@ obj = ReadObjectFromID(emitterId);
                ScriptParams@ params = obj.GetScriptParams();
                params.SetInt("objectIdToFollow", lastEnteredPlayerObjId);
                obj.UpdateScriptParams();
                PlaySound("Data/Sounds/versus/voice_end_1.wav");
            }
        }
    }
}

void SetParameters() {
    params.AddString("game_type", "versusBrawl");
}

void Update(){
    //TODO! This placeholder stuff is usefull, especially since you have dynamic control over whats displayed, extract it
    
    // placeholder is missing create it
    if(placeholderId == -1)
        placeholderId = CreateObject("Data/Objects/placeholder/placeholder_arena_spawn.xml");
    
    // Get hotspot and placeholder, and then setup
    Object@ me = ReadObjectFromID(hotspot.GetID());
    Object@ obj = ReadObjectFromID(placeholderId);
    PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(obj);
    if(respawnPickupTimer>0 ){
        placeholder_object.SetBillboard("Data/Textures/ui/arena_mode/10_kills.png");
    }
    else{
        placeholder_object.SetBillboard("Data/Textures/ui/arena_mode/1_kills.png");
    }
    
    obj.SetEditorLabel("["+activated+" "+lastEnteredPlayerObjId+" "+ respawnPickupTimer+"]");
    // This part makes placeholder follow
    obj.SetTranslation(me.GetTranslation());
    obj.SetRotation(me.GetRotation());

    // TODO! We'll need to check whether he is still close enough to be considered for pickup
    // Get lastEnteredPlayerObjId and check its translation, if its close enough to activate
    
    if(activated && lastEnteredPlayerObjId != -1 && respawnPickupTimer>0){
        respawnPickupTimer -= time_step;
        //Ninja mode, this probably needs to be extracted into a powerup
        MovementObject@ mo = ReadCharacterID(lastEnteredPlayerObjId);
        int weapon = mo.GetArrayIntVar("weapon_slots",mo.GetIntVar("primary_weapon_slot"));
        
        if(weapon == -1) {
            int knifeId = CreateObject("Data/Items/rabbit_weapons/rabbit_knife.xml");
            spawned_objectIds.push_back(knifeId);
            mo.Execute("AttachWeapon(" + knifeId + ");");
        }
        
    }
    else{
        
        // Cleanup knives
        if(spawned_objectIds.size()>0){
            PlaySound("Data/Sounds/versus/voice_end_2.wav");
            DeleteObjectsInList(spawned_objectIds);
        }
        lastEnteredPlayerObjId = -1;
        activated = false;
    }
}

void Dispose(){
    if(ObjectExists(placeholderId)) {
        // Cleanup placeholder
        DeleteObjectID(placeholderId);
    }
}

void DeleteObjectsInList(array<int> &inout ids) {
    int num_ids = ids.length();
    for(int i=0; i<num_ids; ++i){
        Log(info, "Test");
        DeleteObjectID(ids[i]);
    }
    ids.resize(0);
}