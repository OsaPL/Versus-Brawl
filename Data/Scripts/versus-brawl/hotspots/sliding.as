#include "hotspots/placeholderFollower.as"

vec3 color = vec3(1.1f, 0.1f, 0.1f);
string billboardPath = "Data/Textures/ui/versusBrawl/platform_slide.png";
double timer = 0;
double delta = 0.000001f;

class SlideInstance{
    int objId;
    float turnRate;
    int particleEmmiterIdLeft;
    int particleEmmiterIdRight;
    int soundHandle;
    vec3 entranceVelocity;
    bool slidingAlready = false;
    float slideTime = 0;

    SlideInstance(int newObjId, vec3 newEntranceVelocity){
        objId = newObjId;
        entranceVelocity = newEntranceVelocity;
    }
}
array<SlideInstance@> currentSlides = {};

void Init(){
}

void SetParameters()
{
    params.AddString("type", "slidingHotspot");
    params.AddFloatSlider("maxVelocity", 10.0f,"min:0,max:100,step:0.01");
    // decides how slow can the slide go
    params.AddFloatSlider("minVelocity", 1.0f,"min:0,max:100,step:0.01");
    // how much the angle of the character has to similar to the sliding angle to start
    params.AddFloatSlider("startAngleTolerance", 0.2f,"min:0,max:1,step:0.01");
    // how much % of the speed will be reduced when going against it
    params.AddFloatSlider("upRampReduction", 0.1f,"min:0,max:1,step:0.01");
    params.AddFloatSlider("accelaration", 0.10f,"min:0,max:5,step:0.01");
    // % of how much to allow player to steer
    params.AddFloatSlider("steerability", 2.0f,"min:0,max:5,step:0.01");
    // max directed velocity to steer
    params.AddFloatSlider("maxTurnRate", 2.5f,"min:0,max:5,step:0.01");
    // how strongly you will be corrected to the original direction, if no steering
    params.AddFloatSlider("decayTurnRate", 0.01f,"min:0,max:1,step:0.01");
    // Allows player to control the velocity (it also turns off player friction, so be aware of increased velocity>>)
    params.AddIntCheckbox("allowPlayerSpeedControl", true);
    params.AddString("soundSlideLoop", "Data/Sounds/dirtyrock_foley/slide_dirt_loop_3.wav");
    params.AddString("soundSlideEnd", "Data/Sounds/dirtyrock_foley/bf_dirtyrock_medium.xml");
}

void HandleEvent(string event, MovementObject @mo)
{
    if (event == "enter") {
        currentSlides.push_back(SlideInstance(mo.GetID(), mo.velocity));
    }
    if (event == "exit") {
        int toRemove = -1;
        //Log(error, "Exited: " + mo.GetID());
        for (uint j = 0; j < currentSlides.size(); j++){
            if(currentSlides[j].objId == mo.GetID())
                toRemove = j;
        }
        //Log(error, "Found: " + toRemove);
        if(toRemove != -1){
            CancelSlide(toRemove, true);
        }
    }
}

void CancelSlide(int index, bool moExited = false){
    if(currentSlides[index].slidingAlready){
        currentSlides[index].slideTime = 0;
        
        if(currentSlides[index].particleEmmiterIdLeft != -1){
            QueueDeleteObjectID(currentSlides[index].particleEmmiterIdLeft);
            currentSlides[index].particleEmmiterIdLeft = -1;
        }
        if(currentSlides[index].particleEmmiterIdRight != -1){
            QueueDeleteObjectID(currentSlides[index].particleEmmiterIdRight);
            currentSlides[index].particleEmmiterIdRight = -1;
        }
        
        if(currentSlides[index].soundHandle != -1){
            StopSound(currentSlides[index].soundHandle);
            currentSlides[index].soundHandle = -1;
        }
        currentSlides[index].slidingAlready = false;
        // TODO! Before playing check if its a sound or soundgroup (.xml?)
        PlaySoundGroup(params.GetString("soundSlideEnd"), 0.2f);
    }
    if(moExited)
        currentSlides.removeAt(index);
}

void Slide(SlideInstance@ slide){
    Object@ me = ReadObjectFromID(hotspot.GetID());
    MovementObject@ mo = ReadCharacterID(slide.objId);
    
    if(GetInputDown(mo.controller_id, "left") || GetInputDown(mo.controller_id, "right")){
        slide.turnRate -= (params.GetFloat("steerability")/100.0f)*GetMoveXAxis(mo.controller_id);
    }
    else{
        // If no input, just get closer the target direction
        if(abs(slide.turnRate) < delta){
            slide.turnRate = 0;
        }
        else{
            slide.turnRate = slide.turnRate/(1.0f+params.GetFloat("decayTurnRate"));
        }
    }
    //Log(error, "before slide.turnRate: " + slide.turnRate);
    // Clamp turning
    if(slide.turnRate > params.GetFloat("maxTurnRate")){
        slide.turnRate = params.GetFloat("maxTurnRate");
    }
    else if(slide.turnRate < -params.GetFloat("maxTurnRate")){
        slide.turnRate = -params.GetFloat("maxTurnRate");
    }
    
    vec3 outputDir = normalize(me.GetRotation() * vec3(slide.turnRate, 0, 1));

    float newVel = params.GetFloat("accelaration");
    if(params.GetInt("allowPlayerSpeedControl") != 0){
        newVel += length(mo.velocity);
    }
    else{
        // We ignore the real velocity and keep track of our own
        newVel += length(slide.entranceVelocity);
    }

    if(newVel > params.GetFloat("maxVelocity"))
        newVel = params.GetFloat("maxVelocity");
    mo.velocity = newVel * outputDir;
    slide.entranceVelocity = newVel * outputDir;
    slide.slideTime += time_step;
    
    // We reduce the particle delay, for more intense smoke on higher speeds
    float newParticlesDelay = 0.1f-(length(mo.velocity)/150);
    //Log(error, "particleDelay: " + newParticlesDelay);
    Object@ objL = ReadObjectFromID(slide.particleEmmiterIdLeft);
    ScriptParams @objParamsL = objL.GetScriptParams();
    objParamsL.SetFloat("particleDelay", newParticlesDelay);
    objL.UpdateScriptParams();
    
    Object@ objR = ReadObjectFromID(slide.particleEmmiterIdRight);
    ScriptParams @objParamsR = objR.GetScriptParams();
    objParamsR.SetFloat("particleDelay", newParticlesDelay);
    objR.UpdateScriptParams();
    
    //Log(error, "mo.velocity: " + mo.velocity);
}

void SwitchTrails(int index, bool state){
    int particleEmitterIdL = currentSlides[index].particleEmmiterIdLeft;
    Object@ objL = ReadObjectFromID(particleEmitterIdL);
    if(particleEmitterIdL != -1 && objL.GetEnabled()){
        ScriptParams @objParamsL = objL.GetScriptParams();
        objParamsL.SetInt("Disable draw", state ? 0 : 1);
    }
        
    int particleEmitterIdR = currentSlides[index].particleEmmiterIdRight;
    Object@ objR = ReadObjectFromID(particleEmitterIdR);
    if(particleEmitterIdR != -1 && objR.GetEnabled()){
        ScriptParams @objParamsR = objR.GetScriptParams();
        objParamsR.SetInt("Disable draw", state ? 0 : 1);
    }
}

void Update(){
    Object@ me = ReadObjectFromID(hotspot.GetID());

    vec3 direction = me.GetRotation() * vec3(0,0,1) *0.2f;
    
    if(EditorModeActive()){
        PlaceHolderFollowerUpdate(billboardPath, "", length(me.GetScale()), true, vec4(color, 1));
    }
    else{
        // TODO: Remove this?
        PlaceHolderFollowerUpdate(billboardPath, "", length(me.GetScale()), false, vec4(color, 0.5f));
    }
    
    timer += time_step;
    
    for (uint j = 0; j < currentSlides.size(); j++){
        MovementObject@ mo = ReadCharacterID(currentSlides[j].objId);
        
        // Ignore all airborne players
        if(mo.GetIntVar("on_ground") != 1){
            // Disable trails if already sliding
            if(currentSlides[j].slidingAlready){
                SwitchTrails(j, false);
            }
            continue;
        }
            
        if(dot(normalize(mo.velocity), normalize(me.GetRotation() * vec3(0, 0, 1))) > params.GetFloat("startAngleTolerance") 
        && !currentSlides[j].slidingAlready
        && params.GetFloat("minVelocity")*0.75f < length(mo.velocity)){
            currentSlides[j].slidingAlready = true;
            
            // This helps to make animations transition faster
            mo.Execute("SetOnGround(true);");
            
            // TODO: Make these configurable too?
            // foot trail effect
            int particleEmitterIdL = CreateObject("Data/Objects/powerups/objectFollowerEmitter.xml");
            Object@ obj = ReadObjectFromID(particleEmitterIdL);
            ScriptParams @objParams = obj.GetScriptParams();
            objParams.SetInt("objectIdToFollow", mo.GetID());
            objParams.SetInt("No Light", 1);
            objParams.SetFloat("particleDelay", 0.1f);
            objParams.SetString("pathToParticles", "Data/Particles/breath_fog.xml");
            objParams.SetFloat("particleRangeMultiply", 0.1f);
            objParams.SetString("boneToFollow", "left_leg");
            obj.UpdateScriptParams();
            
            int particleEmitterIdR = DuplicateObject(obj);
            Object@ objR = ReadObjectFromID(particleEmitterIdR);
            ScriptParams @objRParams = objR.GetScriptParams();
            objParams.SetString("boneToFollow", "right_leg");
            obj.UpdateScriptParams();
            
            // Slide sound
            int soundHandle = PlaySoundLoop(params.GetString("soundSlideLoop"),0.2f);
            
            currentSlides[j].particleEmmiterIdLeft = particleEmitterIdL;
            currentSlides[j].particleEmmiterIdRight = particleEmitterIdR;
            currentSlides[j].soundHandle = soundHandle;
            currentSlides[j].entranceVelocity = mo.velocity;
        }
        
        if(currentSlides[j].slidingAlready){
            // Cancel sliding if too slow
            if(params.GetFloat("minVelocity") > length(mo.velocity)){
                CancelSlide(j);
            }
            else{
                // TODO! this animation kinda sucks
                float slideBlend = 5 + (currentSlides[j].slideTime);
                if(slideBlend > 40)
                    slideBlend = 40;
                    
                SwitchTrails(j, true);
                    
                mo.Execute("this_mo.SetAnimation(\"Data/Animations/r_wallpress.anm\", "+slideBlend+", 1)");
                Slide(currentSlides[j]);
            }
        }
        else{
            
            mo.velocity = mo.velocity * (1.0f - params.GetFloat("upRampReduction"));
        }
    }

    // if(!EditorModeActive())
    //     DebugDrawBillboard(billboardPath,
    //         me.GetTranslation() + vec3(0),
    //         2.0f,
    //         vec4(color,1),
    //         _delete_on_update);
}

void PreScriptReload()
{
    // Makes sure looping sound is dealt with BEFORE script reload
    for (uint j = 0; j < currentSlides.size(); j++){
        StopSound(currentSlides[j].soundHandle);
        currentSlides[j].soundHandle = -1;
    }
}