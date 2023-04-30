#include "hotspots/placeholderFollower.as"

// This can be used to give an object a follower particle emitter 
// can also fill `boneToFollow` param, to follow a bone (empty will default to torso, same as `obj.GetTranslation();` I think?)

int lightId = -1;
float time = 0;
vec3 originalScale = vec3(1);
vec3 desiredScale = vec3(0.0513f);
string lastPath = "";
bool lastPathOk = false;

void Init() {
    hotspot.SetCollisionEnabled(false);
    Object@ me = ReadObjectFromID(hotspot.GetID());
    originalScale = me.GetScale();
    params.SetString("originalScale", ""+ originalScale);

    // Makes sure that the scale is kept low, to make all those bounding boxes smaller
    //me.SetScale(desiredScale);
}

void SetParameters() {
    params.SetString("game_type", "versusBrawl");
    
    params.AddFloatSlider("particleDelay", 1.0f, "min:0,max:5,step:0.01");
    params.AddFloatSlider("particleRangeMultiply", 1.0f, "min:0,max:5,step:0.01");
    params.AddString("pathToParticles", "Data/Particles/smoke.xml");
    params.AddIntCheckbox("Circle Zone", false);

    params.AddFloatSlider("particleColorR", 1.0f,"min:0,max:1,step:0.01,text_mult:255");
    params.AddFloatSlider("particleColorG", 1.0f,"min:0,max:1,step:0.01,text_mult:255");
    params.AddFloatSlider("particleColorB", 1.0f,"min:0,max:1,step:0.01,text_mult:255");

    params.AddFloatSlider("Min Distance To Activate", 40, "min:0.0,max:1000.0");
}

void Update(){
    Object@ me = ReadObjectFromID(hotspot.GetID());

    int objectIdToFollow = -1;
    if(params.HasParam("objectIdToFollow"))
        objectIdToFollow = params.GetInt("objectIdToFollow");

    // Find closest player
    float minDistanceToActivate = params.GetFloat("Min Distance To Activate");

    if(!PlayerProximityCheck(minDistanceToActivate) && !EditorModeActive()){
        me.SetEnabled(false);
    }
    else{
        me.SetEnabled(true);
    }

    if(me.GetScale() != originalScale && me.GetScale() != desiredScale){
        originalScale = me.GetScale();
        params.SetString("originalScale", ""+ originalScale);
    }
    //me.SetScale(desiredScale);
    
    time += time_step;

    string pathToParticles = params.GetString("pathToParticles");
    //Log(error, "pathToParticles: "+pathToParticles);

    string enabled = me.GetEnabled() ? "Enabled" : "Disabled";
    vec3 color = vec3(params.GetFloat("particleColorR"), params.GetFloat("particleColorG"), params.GetFloat("particleColorB"));
    
    PlaceHolderFollowerUpdate("Data/Textures/ui/versusBrawl/particle.png", "[FollowerEmitter] Path: [" +  lastPath + "] Follows: [" + objectIdToFollow + "] [" + enabled + "]", 1, false, vec4(color, 0.8f));

    if(lastPath != pathToParticles){
        lastPath = pathToParticles;
        if(!FileExistsWithType(pathToParticles, ".xml")){
            //Log(error, "Cant find:"+pathToParticles);
            lastPathOk = false;
            return;
        }
        lastPathOk = true;
        //Log(error, "Found:"+pathToParticles);
    }
    
    // Here is the follow logic
    //Log(error, "Following:"+objectIdToFollow);
    if(objectIdToFollow != -1){
        Object@ obj = ReadObjectFromID(objectIdToFollow);
        
        vec3 pos = vec3(0);
        if(params.HasParam("boneToFollow")){
            // if `boneToFollow` is set, follow a bone
            MovementObject@ mo = ReadCharacterID(objectIdToFollow);
            string bonName = params.GetString("boneToFollow");
            if(bonName == "")
                bonName = "torso";
            vec3 bonePos = mo.rigged_object().GetIKTargetTransform(bonName).GetTranslationPart();
            pos = bonePos;
        }
        else{
            // We just use default GetTranslation() if no bones set
            pos = obj.GetTranslation();
        }
        
        PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(obj);
        me.SetTranslation(pos);
        
        // Also we move the light
        if(lightId == -1){
            // Lets spawn a small light
            lightId = CreateObject("Data/Objects/lights/dynamic_light.xml");
            Log(error, "Created lightId: " + lightId);
            Object@ lightObj = ReadObjectFromID(lightId);
            lightObj.SetScale(vec3(1));
            lightObj.SetTint(color);
        }

        Object@ lightObj = ReadObjectFromID(lightId);
        lightObj.SetScale(vec3(2.6f) + (vec3(sin(time)) / 5));
        //Log(error, "lightObj.GetScale(): " + lightObj.GetScale());

        lightObj.SetTranslation(pos);
    }
}

vec3 GetPoint(float xRange, float yRange, float zRange) {
    float d, x, y, z;

    do {
        x = RangedRandomFloat(0, xRange)  * 2.0 - xRange;
        d = x*x;
    } while(d > xRange);

    do {
        y = RangedRandomFloat(0, yRange)  * 2.0 - yRange;
        d = y*y;
    } while(d > yRange);

    do {
        z = RangedRandomFloat(0, zRange)  * 2.0 - zRange;
        d = z*z;
    } while(d > zRange);
    return vec3(x, y, z);
}

// This is just yanked from emmiter.as
float delay = 0.0;
float last_game_time = 0.0;
void PreDraw(float curr_game_time) {
    EnterTelemetryZone("Emitter Update");
    
    if(ReadObjectFromID(hotspot.GetID()).GetEnabled() && lastPathOk){
        
        float delta_time = curr_game_time - last_game_time;

        Object@ obj = ReadObjectFromID(hotspot.GetID());
        vec3 pos = obj.GetTranslation();
        vec3 scale = originalScale;
        vec4 v = obj.GetRotationVec4();
        quaternion rotation(v.x,v.y,v.z,v.a);
        delay -= delta_time;
        if(delay <= 0.0f){
            for(int i=0; i<1; ++i){
                vec3 offset;
                float rangeMlt = params.GetFloat("particleRangeMultiply");
                vec3 color = vec3(params.GetFloat("particleColorR"), params.GetFloat("particleColorG"), params.GetFloat("particleColorB"));

                if(params.GetInt("Circle Zone") != 0){
                    vec3 point = GetPoint(scale.x*rangeMlt, scale.y*rangeMlt, scale.z*rangeMlt);

                    offset.x += point.x;
                    offset.y += point.y;
                    offset.z += point.z;
                }
                else{
                    offset.x += RangedRandomFloat(-scale.x*rangeMlt,scale.x*rangeMlt);
                    offset.y += RangedRandomFloat(-scale.y*rangeMlt,scale.y*rangeMlt);
                    offset.z += RangedRandomFloat(-scale.z*rangeMlt,scale.z*rangeMlt);
                }

                uint32 id = MakeParticle(lastPath, pos + Mult(rotation, offset), vec3(0.0f), color);
            }
            // If `particle_field` disabled, we halve the rate for more fps
            if(!GetConfigValueBool("particle_field"))
                delay += params.GetFloat("particleDelay");
            
            delay += params.GetFloat("particleDelay");
        }
        if(delay < -1.0){
            delay = -1.0;
        }
    }
    last_game_time = curr_game_time;
    LeaveTelemetryZone();
}

void Dispose(){
    if(ObjectExists(lightId)){
        DeleteObjectID(lightId);
    }
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
