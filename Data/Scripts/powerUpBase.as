#include "timed_execution/timed_execution.as"
#include "timed_execution/char_death_job.as"
#include "timed_execution/level_event_job.as"

float respawnPickupTimer = 0;
int lastEnteredPlayerObjId = -1;
bool readyForPickup = true;
vec3 fixedScale = vec3(0.27,0.27,0.27);
bool _error = false;
bool active = false;

int particleEmitterId = -1;

TimedExecution powerupTimer;

void PowerupInit()
{
    // Get hotspot
    Object@me = ReadObjectFromID(hotspot.GetID());
    me.SetScale(fixedScale);
}

void PowerupHandleEvent(string event, MovementObject @mo)
{
    if (event == "enter") {
        if (mo.is_player) {
            // Bodies shouldnt be able to get powerups
            if(mo.GetIntVar("knocked_out") == _awake)
                if(readyForPickup && !active){
                    lastEnteredPlayerObjId = mo.GetID();
                    readyForPickup = false;
                    active = true;
                    Object@ me = ReadObjectFromID(hotspot.GetID());
                    me.ReceiveScriptMessage("activate");

                    powerupTimer.Add(CharDeathJob(lastEnteredPlayerObjId, function(char_a){
                        //Disable powerup on death 
                        if(lastEnteredPlayerObjId == char_a.GetID())
                        {
                            respawnPickupTimer = 0;
                        }
                        return false;
                    }));
                    
                    powerupTimer.Add(LevelEventJob("reset", function(_params){
                        //Reset powerup on reset
                        readyForPickup = true;

                        return false;
                    }));
                    
                    respawnPickupTimer = params.GetFloat("activeTime");
                    int emitterId = CreateObject("Data/Objects/powerups/objectFollowerEmitter.xml");
                    particleEmitterId = emitterId;
                    Object@ obj = ReadObjectFromID(emitterId);
                    ScriptParams@ objParams = obj.GetScriptParams();
                    objParams.SetInt("objectIdToFollow", lastEnteredPlayerObjId);
                    objParams.SetFloat("particleDelay", params.GetFloat("particleDelay"));
                    objParams.SetFloat("particleRangeMultiply", params.GetFloat("particleRangeMultiply"));
                    objParams.SetString("pathToParticles", params.GetString("pathToParticles"));
                    objParams.SetFloat("particleColorR", params.GetFloat("particleColorR"));
                    objParams.SetFloat("particleColorG", params.GetFloat("particleColorG"));
                    objParams.SetFloat("particleColorB", params.GetFloat("particleColorB"));
                    obj.UpdateScriptParams();
                }
        }
    }
}

void PowerupSetParameters() {
    params.AddString("game_type", "versusBrawl");
    
    params.AddString("startSoundPath", "Data/Sounds/versus/voice_end_1.wav");
    params.AddString("endSoundPath", "Data/Sounds/versus/voice_end_2.wav");
    params.AddString("notReadyIconPath", "Data/Textures/ui/arena_mode/glyphs/10_kills_1x1.png");
    params.AddString("readyIconPath", "Data/Textures/ui/arena_mode/glyphs/10_kos_1x1.png");
    params.AddFloatSlider("colorR", 1.0f,"min:0,max:1,step:0.01,text_mult:255");
    params.AddFloatSlider("colorG", 1.0f,"min:0,max:1,step:0.01,text_mult:255");
    params.AddFloatSlider("colorB", 1.0f,"min:0,max:1,step:0.01,text_mult:255");
    params.AddFloatSlider("notReadyAlpha", 0.5f,"min:0,max:1,step:0.01,text_mult:255");
    params.AddFloatSlider("readyAlpha", 0.9f,"min:0,max:1,step:0.01,text_mult:255");

    params.AddFloatSlider("particleDelay", 0.9f,"min:0,max:100,step:0.1,text_mult:1");
    params.AddFloatSlider("particleRangeMultiply", 0.9f,"min:0,max:100,step:0.1,text_mult:1");
    params.AddString("pathToParticles", "Data/Particles/ninja_smoke.xml");
    params.AddFloatSlider("particleColorR", 1.0f,"min:0,max:1,step:0.01,text_mult:255");
    params.AddFloatSlider("particleColorG", 1.0f,"min:0,max:1,step:0.01,text_mult:255");
    params.AddFloatSlider("particleColorB", 1.0f,"min:0,max:1,step:0.01,text_mult:255");

    params.AddFloatSlider("respawnTime", 6.0f,"min:0,max:100,step:0.1,text_mult:1");
    params.AddFloatSlider("activeTime", 3.0f,"min:0,max:100,step:0.1,text_mult:1");
}

void PowerupReceiveMessage(string msg)
{
    powerupTimer.AddLevelEvent(msg);
}

void PowerupPreScriptReload()
{
    powerupTimer.DeleteAll();
}

void PowerupUpdate(){
    powerupTimer.Update();
    // Show error and ignore updating this
    if(params.GetFloat("respawnTime") < params.GetFloat("activeTime") && !_error){
        DisplayError("PowerupsError", "respawnTime cant be smaller than activeTime! ID:"+hotspot.GetID());
        _error = true;
    }
    if(_error){
        if(params.GetFloat("respawnTime") >= params.GetFloat("activeTime"))
        {
            _error = false;
        }
        else{
            return;
        }
    }

    // Get hotspot
    Object@ me = ReadObjectFromID(hotspot.GetID());

    // TODO! We'll need to check whether he is still close enough to be considered for pickup
    // Get lastEnteredPlayerObjId and check its translation, if its close enough to activate

    if(!readyForPickup && lastEnteredPlayerObjId != -1 && respawnPickupTimer>0 && active){
        respawnPickupTimer -= time_step;
    }
    else{
        respawnPickupTimer += time_step;
        if(active){
            respawnPickupTimer = 0;
            me.ReceiveScriptMessage("deactivate");
            DeleteObjectID(particleEmitterId);
            active = false;
        }
        if(respawnPickupTimer>params.GetFloat("respawnTime")){
            lastEnteredPlayerObjId = -1;
            readyForPickup = true;
        }
    }
}

void PowerupDispose(){
    DeleteObjectID(particleEmitterId);
}

void DeleteObjectsInList(array<int> &inout ids) {
    int num_ids = ids.length();
    for(int i=0; i<num_ids; ++i){
        DeleteObjectID(ids[i]);
    }
    ids.resize(0);
}

void PowerupDraw(){
    // Get hotspot
    Object@ me = ReadObjectFromID(hotspot.GetID());
    // Its really dumb we cant use SetBillboardColorMap on hotspots
    if(!readyForPickup){
        DebugDrawBillboard(params.GetString("notReadyIconPath"),
            me.GetTranslation(),
            me.GetScale()[1]*5.0,
            vec4(vec3(params.GetFloat("colorR"),params.GetFloat("colorG"),params.GetFloat("colorB")), params.GetFloat("notReadyAlpha")),
            _delete_on_draw);
    }
    else{
        DebugDrawBillboard(params.GetString("readyIconPath"),
            me.GetTranslation(),
            me.GetScale()[1]*6.0,
            vec4(vec3(params.GetFloat("colorR"),params.GetFloat("colorG"),params.GetFloat("colorB")), params.GetFloat("readyAlpha")),
            _delete_on_draw);
    }
}