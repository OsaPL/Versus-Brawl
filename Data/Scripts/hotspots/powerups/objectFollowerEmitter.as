
void Init() {
    hotspot.SetCollisionEnabled(false);
}

void SetParameters() {
    params.SetString("game_type", "versusBrawl");
    
    params.AddFloatSlider("particleDelay", 1.0f, "min:0,max:5,step:0.01");
    params.AddFloatSlider("particleRangeMultiply", 1.0f, "min:0,max:5,step:0.01");
    params.AddString("pathToParticles", "Data/Particles/smoke.xml");
    params.AddFloatSlider("particleColorR", 1.0f,"min:0,max:1,step:0.01,text_mult:255");
    params.AddFloatSlider("particleColorG", 1.0f,"min:0,max:1,step:0.01,text_mult:255");
    params.AddFloatSlider("particleColorB", 1.0f,"min:0,max:1,step:0.01,text_mult:255");
}

void Update(){
    if(!params.HasParam("objectIdToFollow"))
        return;
    
    int objectIdToFollow = params.GetInt("objectIdToFollow");
    string pathToParticles = params.GetString("pathToParticles");
    //Log(error, "Following:"+objectIdToFollow);
    if(objectIdToFollow != -1){
        Object@ me = ReadObjectFromID(hotspot.GetID());
        Object@ obj = ReadObjectFromID(objectIdToFollow);
        MovementObject@ mo = ReadCharacterID(objectIdToFollow);
        PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(obj);
        me.SetTranslation(mo.position);
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
                float rangeMlt = params.GetFloat("particleRangeMultiply");
                vec3 color = vec3(params.GetFloat("particleColorR"),params.GetFloat("particleColorG"),params.GetFloat("particleColorB"));
                offset.x += RangedRandomFloat(-scale.x*rangeMlt,scale.x*rangeMlt);
                offset.y += RangedRandomFloat(-scale.y*rangeMlt,scale.y*rangeMlt);
                offset.z += RangedRandomFloat(-scale.z*rangeMlt,scale.z*rangeMlt);
                uint32 id = MakeParticle(pathToParticles, pos + Mult(rotation, offset), vec3(0.0f), color);
            }
            delay += params.GetFloat("particleDelay");
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
