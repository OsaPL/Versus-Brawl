void Init() {
}

int count = 0;
int water_surface_id = -1;
int water_decal_id = -1;

void SetParameters() {
    params.AddFloatSlider("Wave Density",0.25f,"min:0,max:1,step:0.01");
    params.AddFloatSlider("Wave Height",0.5f,"min:0,max:1,step:0.01");
    params.AddFloatSlider("Water Fog",1.0f,"min:0,max:1,step:0.01");

}

void Dispose() {
    if(water_decal_id != -1){
        QueueDeleteObjectID(water_decal_id);
        water_decal_id = -1;
    }
    if(water_surface_id != -1){
        QueueDeleteObjectID(water_surface_id);
        water_surface_id = -1;
    }
}

void HandleEvent(string event, MovementObject @mo){
    //DebugText("wed", "Event: " + event, _fade);
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
    mo.Execute("zone_killed=1;TakeBloodDamage(1.0f);Ragdoll(_RGDL_INJURED);");
    mo.ReceiveScriptMessage("ignite");
    //mo.ReceiveScriptMessage("extinguish");
    //mo.Execute("TakeBloodDamage(1.0f);Ragdoll(_RGDL_FALL);zone_killed=1;");
}

void OnExit(MovementObject @mo) {
    mo.Execute("water_id=-1;");
}


void PreDraw(float curr_game_time) {
}

void Update() {
    EnterTelemetryZone("wet cube update");
    Object@ obj = ReadObjectFromID(hotspot.GetID());
    /*array<int> nearby_characters;
    GetCharacters(nearby_characters);
    int num_chars = nearby_characters.size();
    for(int i=0; i<num_chars; ++i){
        MovementObject@ mo = ReadCharacterID(nearby_characters[i]);
        mo.rigged_object().AddWaterCube(obj.GetTransform());
    }    */
    if(!params.HasParam("Invisible")){
        if(water_surface_id == -1){
            water_surface_id = CreateObject("Data/Objects/versus-brawl/magma_test.xml", true);
        }
        Object@ water_surface_obj = ReadObjectFromID(water_surface_id);
        water_surface_obj.SetTranslation(obj.GetTranslation());
        water_surface_obj.SetRotation(obj.GetRotation());
        water_surface_obj.SetScale(obj.GetScale() * 2.0f);

        water_surface_obj.SetTint(vec3(params.GetFloat("Wave Height"),params.GetFloat("Wave Density"),params.GetFloat("Water Fog")));
    }    
    if(water_decal_id == -1){
        water_decal_id = CreateObject("Data/Objects/versus-brawl/Decals/magmaDecal.xml", true);
    }
    Object@ water_decal_obj = ReadObjectFromID(water_decal_id);
    water_decal_obj.SetTranslation(obj.GetTranslation());
    water_decal_obj.SetRotation(obj.GetRotation());
    water_decal_obj.SetScale(obj.GetScale() * 4.00f);

    array<int> collides_with;
    level.GetCollidingObjects(hotspot.GetID(), collides_with);
    for(int i=0, len=collides_with.size(); i<len; ++i){
        int id = collides_with[i];
        if(ObjectExists(id) && ReadObjectFromID(id).GetType() == _movement_object){
            MovementObject@ mo = ReadCharacterID(id);
            LavaIntersect(hotspot.GetID(), id); 
        }
    }
    LeaveTelemetryZone();
}

void LavaIntersect(int id, int moID){
    // This is hardcoded in aschar.as lmao
    float _leg_sphere_size = 0.45f;
    
    MovementObject@ this_mo = ReadCharacterID(moID);
    
    this_mo.Execute("water_id = "+id+";");
    mat4 transform = ReadObjectFromID(id).GetTransform();
    vec3 pos = invert(transform) * this_mo.position;
    float water_penetration = (pos[1] - 2.0) * ReadObjectFromID(id).GetScale()[1];
    pos[1] = 2.0;
    float water_depth = _leg_sphere_size - water_penetration;
    this_mo.Execute("water_depth = "+water_depth+";");
}