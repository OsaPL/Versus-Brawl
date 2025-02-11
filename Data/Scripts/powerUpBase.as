#include "timed_execution/timed_execution.as"
#include "timed_execution/char_death_job.as"
#include "timed_execution/level_event_job.as"

#include "hotspots/placeholderFollower.as"

float respawnPickupTimer = 0;
int lastEnteredPlayerObjId = -1;
bool readyForPickup = true;
vec3 fixedScale = vec3(0.27,0.27,0.27);
bool _error = false;
bool active = false;
bool init = false;
bool ignoreRefreshMessages = false;

int particleEmitterId = -1;

TimedExecution powerupTimer;

void PowerupInit()
{
    // Enables receiving level msgs (performance heavy)
    level.ReceiveLevelEvents(hotspot.GetID());
    // Get hotspot
    Object@ me = ReadObjectFromID(hotspot.GetID());
    me.SetScale(fixedScale);

    powerupTimer.Add(LevelEventJob("RefreshPowerup", function(char_a){
        //Refresh powerup

        RefreshPowerup();
        return true;
    }));

    powerupTimer.Add(LevelEventJob("RefreshAllPowerups", function(_params){
        //Refresh powerup

        RefreshPowerup();
        return true;
    }));
}

void RefreshPowerup(){
    if(ignoreRefreshMessages)
        return;
    Object@ me = ReadObjectFromID(hotspot.GetID());
    me.ReceiveScriptMessage("deactivate");
    readyForPickup = true;
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
                    if(params.HasParam("boneToFollow"))
                        objParams.SetString("boneToFollow", params.GetString("boneToFollow"));
                    objParams.SetFloat("particleDelay", params.GetFloat("particleDelay"));
                    objParams.SetFloat("particleRangeMultiply", params.GetFloat("particleRangeMultiply"));
                    objParams.SetString("pathToParticles", params.GetString("pathToParticles"));
                    objParams.SetString("boneToFollow", params.GetString("boneToFollow"));
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
    params.AddString("boneToFollow", "");
    params.AddFloatSlider("particleColorR", 1.0f,"min:0,max:1,step:0.01,text_mult:255");
    params.AddFloatSlider("particleColorG", 1.0f,"min:0,max:1,step:0.01,text_mult:255");
    params.AddFloatSlider("particleColorB", 1.0f,"min:0,max:1,step:0.01,text_mult:255");

    params.AddIntCheckbox("oneTimeUse", false);

    params.AddFloatSlider("respawnTime", 6.0f,"min:0,max:100,step:0.1,text_mult:1");
    params.AddFloatSlider("activeTime", 3.0f,"min:0,max:100,step:0.1,text_mult:1");
}

void PowerupReceiveMessage(string msg)
{
    // if(msg.findFirst("RefreshAllPowerups") != -1)
    //     Log(error, "RefreshAllPowerups:  " + msg);
    // if(msg.findFirst("RefreshPowerup") != -1)
    //     Log(error, "RefreshPowerup:  " + msg);
    // this will receive messages aimed at this object
    powerupTimer.AddLevelEvent(msg);
    
    // this will receive level messages
    powerupTimer.AddEvent(msg);
}

void PowerupPreScriptReload()
{
    powerupTimer.DeleteAll();
    Object@ me = ReadObjectFromID(hotspot.GetID());
    me.ReceiveScriptMessage("deactivate");
    init = true;
}

void PowerupUpdate(){
    Object@ me = ReadObjectFromID(hotspot.GetID());
    
    // This init is called only after ScriptReload(
    if(init){
        Init(); 
        init = false;
    }
    
    powerupTimer.Update();
    vec3 color = vec3(params.GetFloat("colorR"), params.GetFloat("colorG"), params.GetFloat("colorB"));
    
    if(!readyForPickup){
        PlaceHolderFollowerUpdate(params.GetString("notReadyIconPath"), "", 2.0f, false, vec4(color, params.GetFloat("notReadyAlpha")));
    }
    else{
        PlaceHolderFollowerUpdate(params.GetString("readyIconPath"), "", 2.0f, false, vec4(color, params.GetFloat("readyAlpha")));
    }
    
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

    // TODO! We'll need to check whether he is still close enough to be considered for pickup
    // Get lastEnteredPlayerObjId and check its translation, if its close enough to activate

    if(!readyForPickup && lastEnteredPlayerObjId != -1 && respawnPickupTimer>0 && active) {
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
        if(respawnPickupTimer>params.GetFloat("respawnTime") && params.GetInt("oneTimeUse") == 0){
            lastEnteredPlayerObjId = -1;
            readyForPickup = true;
        }
    }
}

void PowerupDispose(){
    level.StopReceivingLevelEvents(hotspot.GetID());
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
    
}

void PowerupReset(){
    Object@ me = ReadObjectFromID(hotspot.GetID());
    me.ReceiveScriptMessage("deactivate");
}