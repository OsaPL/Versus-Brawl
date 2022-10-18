int placeholderId = -1;
float respawnPickupTimer = 0;
int lastEnteredPlayerObjId = -1; 
bool readyForPickup = true;

vec3 fixedScale = vec3(0.27,0.27,0.27);

array<int> spawned_objectIds = {};

void Init()
{
    // Get hotspot
    Object
    @me = ReadObjectFromID(hotspot.GetID());
    me.SetScale(fixedScale);
}

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
            if(readyForPickup){
                lastEnteredPlayerObjId = mo.GetID();
                readyForPickup = false;
                respawnPickupTimer = params.GetFloat("activeTime");
                int emitterId = CreateObject("Data/Objects/powerups/objectFollowerEmitter.xml");
                spawned_objectIds.push_back(emitterId);
                Object@ obj = ReadObjectFromID(emitterId);
                ScriptParams@ objParams = obj.GetScriptParams();
                objParams.SetInt("objectIdToFollow", lastEnteredPlayerObjId);
                obj.UpdateScriptParams();
                PlaySound(params.GetString("startSoundPath"));
            }
        }
    }
}

void SetParameters() {
    params.AddString("game_type", "versusBrawl");
    params.AddFloatSlider("respawnTime", 6.0f,"min:0,max:100,step:0.1,text_mult:1");
    params.AddFloatSlider("activeTime", 3.0f,"min:0,max:100,step:0.1,text_mult:1");
    params.AddString("startSoundPath", "Data/Sounds/versus/voice_end_1.wav");
    params.AddString("endSoundPath", "Data/Sounds/versus/voice_end_2.wav");
    params.AddString("notReadyIconPath", "Data/Textures/ui/arena_mode/glyphs/10_kills_1x1.png");
    params.AddString("readyIconPath", "Data/Textures/ui/arena_mode/glyphs/10_kos_1x1.png");
    params.AddFloatSlider("colorR", 0.5f,"min:0,max:1,step:0.1,text_mult:255");
    params.AddFloatSlider("colorG", 0.0f,"min:0,max:1,step:0.1,text_mult:255");
    params.AddFloatSlider("colorB", 1.0f,"min:0,max:1,step:0.1,text_mult:255");
}

void Update(){
    // Get hotspot
    Object@ me = ReadObjectFromID(hotspot.GetID());
    
    me.SetEditorLabel("["+readyForPickup+" "+lastEnteredPlayerObjId+" "+ respawnPickupTimer+"]");

    // TODO! We'll need to check whether he is still close enough to be considered for pickup
    // Get lastEnteredPlayerObjId and check its translation, if its close enough to activate
    
    if(!readyForPickup && lastEnteredPlayerObjId != -1 && respawnPickupTimer>0){
        respawnPickupTimer -= time_step;

        //Powerup logic
        MovementObject@ mo = ReadCharacterID(lastEnteredPlayerObjId);
        int weapon = mo.GetArrayIntVar("weapon_slots",mo.GetIntVar("primary_weapon_slot"));
        
        if(weapon == -1) {
            int knifeId = CreateObject("Data/Items/rabbit_weapons/rabbit_knife.xml");
            spawned_objectIds.push_back(knifeId);
            mo.Execute("AttachWeapon(" + knifeId + ");");
        }
    }
    else{
        respawnPickupTimer += time_step;
        // Cleanup knives
        if(spawned_objectIds.size()>0){
            lastEnteredPlayerObjId = -1;
            PlaySound(params.GetString("endSoundPath"));
            DeleteObjectsInList(spawned_objectIds);
        }
        lastEnteredPlayerObjId = -1;
        if(respawnPickupTimer>params.GetFloat("respawnTime"))
            readyForPickup = true;
    }
}

void Dispose(){
    DeleteObjectsInList(spawned_objectIds);
}

void DeleteObjectsInList(array<int> &inout ids) {
    int num_ids = ids.length();
    for(int i=0; i<num_ids; ++i){
        Log(info, "Test");
        DeleteObjectID(ids[i]);
    }
    ids.resize(0);
}

void Draw(){
    // Get hotspot
    Object@ me = ReadObjectFromID(hotspot.GetID());
    // Its really dumb we cant use SetBillboardColorMap on hotspots
    if(!readyForPickup){
        DebugDrawBillboard(params.GetString("notReadyIconPath"),
            me.GetTranslation(),
            me.GetScale()[1]*5.0,
            vec4(vec3(params.GetFloat("colorR"),params.GetFloat("colorG"),params.GetFloat("colorB")), 1.0),
            _delete_on_draw);
    }
    else{
        DebugDrawBillboard(params.GetString("readyIconPath"),
            me.GetTranslation(),
            me.GetScale()[1]*6.0,
            vec4(vec3(params.GetFloat("colorR"),params.GetFloat("colorG"),params.GetFloat("colorB")), 1.0),
            _delete_on_draw);
    }
}