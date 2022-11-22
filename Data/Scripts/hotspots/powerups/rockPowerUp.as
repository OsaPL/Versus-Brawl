#include "powerUpBase.as"

float originalDamageReduction;
string hitSoundGroup = "Data/Sounds/rocks_foley/fs_heavy_rocks_crouchwalk.xml";
float soundGain = 7;

TimedExecution rockTimer;

void Init(){
    PowerupInit();
    
    powerupTimer.Add(LevelEventJob("activate", function(_params){
        Object @obj = ReadObjectFromID(lastEnteredPlayerObjId);
        ScriptParams@ objParams = obj.GetScriptParams();
        originalDamageReduction = objParams.GetFloat("Damage Resistance");
        objParams.SetFloat("Damage Resistance", originalDamageReduction*params.GetFloat("reduction"));
        obj.UpdateScriptParams();
        
        // Attach timers for hit sounds
        rockTimer.Add(LevelEventJob("bluntHit", function(_params){
            if(lastEnteredPlayerObjId == parseInt(_params[1]))
                PlaySoundGroup(hitSoundGroup, soundGain);
            return true;
        }));
        rockTimer.Add(LevelEventJob("item_hit", function(_params){
            if(lastEnteredPlayerObjId == parseInt(_params[1]))
                PlaySoundGroup(hitSoundGroup, soundGain);
            return true;
        }));
        rockTimer.Add(LevelEventJob("active_blocked", function(_params){
            if(lastEnteredPlayerObjId == parseInt(_params[1]))
                PlaySoundGroup(hitSoundGroup, soundGain);
            return true;
        }));
        rockTimer.Add(LevelEventJob("passive_blocked", function(_params){
            if(lastEnteredPlayerObjId == parseInt(_params[1]))
                PlaySoundGroup(hitSoundGroup, soundGain);
            return true;
        }));
        rockTimer.Add(LevelEventJob("character_thrown", function(_params){
            if(lastEnteredPlayerObjId == parseInt(_params[1]))
                PlaySoundGroup(hitSoundGroup, soundGain);
            return true;
        }));
        
        PlaySound(params.GetString("startSoundPath"));
        return true;
    }));
    powerupTimer.Add(LevelEventJob("deactivate", function(_params){
        Log(error, "lastEnteredPlayerObjId:"+lastEnteredPlayerObjId);
        
        Object @obj = ReadObjectFromID(lastEnteredPlayerObjId);
        ScriptParams@ objParams = obj.GetScriptParams();
        originalDamageReduction = objParams.GetFloat("Damage Resistance");
        objParams.SetFloat("Damage Resistance", originalDamageReduction/params.GetFloat("reduction"));
        obj.UpdateScriptParams();

        // Delete all hitsound timers
        rockTimer.DeleteAll();
        
        PlaySound(params.GetString("endSoundPath"));

        return true;
    }));
}


void SetParameters() {
    PowerupSetParameters();

    params.AddFloatSlider("reduction", 4.0f,"min:0,max:100,step:0.01,text_mult:1");

    // These ones are specific
    params.SetFloat("activeTime", 12.0f);
    params.SetFloat("respawnTime", 25.0f);

    params.SetString("startSoundPath", "Data/Sounds/rockbreak.wav");
    params.SetString("endSoundPath", "Data/Sounds/rockhit.wav");

    params.SetFloat("colorR", 0.1f);
    params.SetFloat("colorG", 0.1f);
    params.SetFloat("colorB", 0.7f);

    params.SetFloat("particleDelay", 0.001f);
    params.SetString("pathToParticles", "Data/Particles/stone_sparks.xml");
    params.SetFloat("particleRangeMultiply", 0.5f);
    params.SetFloat("particleColorR", 0.2f);
    params.SetFloat("particleColorG", 0.2f);
    params.SetFloat("particleColorB", 1.0f);
}

void HandleEvent(string event, MovementObject @mo){
    PowerupHandleEvent(event, @mo);
}

void Update()
{
    rockTimer.Update();
    PowerupUpdate();
}

void Dispose(){
    PowerupDispose();
}

void Draw()
{
    PowerupDraw();
}

void ReceiveMessage(string msg){
    PowerupReceiveMessage(msg);

    rockTimer.AddLevelEvent(msg);
    rockTimer.AddEvent(msg);
}

void PreScriptReload()
{
    PowerupPreScriptReload();
    rockTimer.DeleteAll();
}