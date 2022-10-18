
void Init() {
    hotspot.SetCollisionEnabled(false);
}

void SetParameters() {
    params.SetString("game_type", "versusBrawl");
    //params.SetInt("objectIdToFollow", -1);
    params.SetString("pathToParticles", "Data/Particles/ninja_smoke.xml");
}

void Update(){
    if(!params.HasParam("objectIdToFollow"))
        return;
    
    int objectIdToFollow = params.GetInt("objectIdToFollow");
    string pathToParticles = params.GetString("pathToParticles");
    Log(error, "Following:"+objectIdToFollow);
    if(objectIdToFollow != -1){
        Object@ me = ReadObjectFromID(hotspot.GetID());
        Object@ obj = ReadObjectFromID(objectIdToFollow);
        MovementObject@ mo = ReadCharacterID(objectIdToFollow);
        PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(obj);
        // This part makes placeholder follow
        me.SetTranslation(mo.position);
        //me.SetRotation(mo.rotation);
    }
}

// This is just yanked from emmiter.as
float delay = 0.0;
float last_game_time = 0.0;
void PreDraw(float curr_game_time) {
    EnterTelemetryZone("Emitter Update");
    string pathToParticles = params.GetString("pathToParticles");
    
    if(ReadObjectFromID(hotspot.GetID()).GetEnabled()){
        float delta_time = curr_game_time - last_game_time;

        Object@ obj = ReadObjectFromID(hotspot.GetID());
        vec3 pos = obj.GetTranslation();
        vec3 scale = obj.GetScale();
        vec4 v = obj.GetRotationVec4();
        quaternion rotation(v.x,v.y,v.z,v.a);
        delay -= delta_time;
        if(delay <= 0.0f){
            for(int i=0; i<1; ++i){
                vec3 offset;
                offset.x += RangedRandomFloat(-scale.x*1.0f,scale.x*1.0f);
                offset.y += RangedRandomFloat(-scale.y*1.0f,scale.y*1.0f);
                offset.z += RangedRandomFloat(-scale.z*1.0f,scale.z*1.0f);
                uint32 id = MakeParticle(pathToParticles, pos + Mult(rotation, offset), vec3(0.0f), vec3(0.1f));
            }
            delay += 0.02f;
        }
        if(delay < -1.0){
            delay = -1.0;
        }
    }
    last_game_time = curr_game_time;
    LeaveTelemetryZone();
}

bool AcceptConnectionsFrom(Object@ other) {
    return true;
}

bool AcceptConnectionsTo(Object@ other) {
    return true;
}

bool ConnectTo(Object@ other)
{
    Log(error, "connecting to:" + other.GetID());
    params.AddInt("objectIdToFollow", other.GetID());
    return true;
}
