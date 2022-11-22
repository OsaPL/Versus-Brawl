#include "powerUpBase.as"

float knockbackMlt = 7.0f;
string slapSoundPath = "Data/Sounds/pop1.wav";

// did it expire or has been used
bool used = false;

void Init(){
    PowerupInit();
    
    powerupTimer.Add(LevelEventJob("activate", function(_params){
        PlaySound(params.GetString("startSoundPath"));
        Object@ obj = ReadObjectFromID(lastEnteredPlayerObjId);
        ScriptParams@ objParams = obj.GetScriptParams();
        objParams.SetFloat("Attack Knockback", objParams.GetFloat("Attack Knockback")*params.GetFloat("knockbackMlt"));

        obj.UpdateScriptParams();
        Log(error, "activated yeet " + lastEnteredPlayerObjId);
        return true;
    }));
    powerupTimer.Add(LevelEventJob("deactivate", function(_params){
        if(used){
            used = false;
            //TODO: maybe use explosion sound (its really loud tho)
            PlaySound(slapSoundPath);
        }
        else{
            PlaySound(params.GetString("stopSoundPath"));
        }
        Object@ obj = ReadObjectFromID(lastEnteredPlayerObjId);
        ScriptParams@ objParams = obj.GetScriptParams();
        objParams.SetFloat("Attack Knockback", objParams.GetFloat("Attack Knockback")/params.GetFloat("knockbackMlt"));

        obj.UpdateScriptParams();
        Log(error, "deactivated yeet " + lastEnteredPlayerObjId);

        return true;
    }));

    powerupTimer.Add(LevelEventJob("bluntHit", function(_params){
        Log(error, "YeetPowerUp bluntHit: "+ _params[1]+ " " +_params[2]+" lastEnteredPlayerObjId: " + lastEnteredPlayerObjId);
        
        if(active){
            // Reset after hit
            if(lastEnteredPlayerObjId == parseInt(_params[2]))
            {
                used = true;
                respawnPickupTimer = 0;
                Object@ me = ReadObjectFromID(hotspot.GetID());
                me.ReceiveScriptMessage("deactivate");
            }
        }
        return true;
    }));
}

void SetParameters() {
    PowerupSetParameters();

    params.AddFloatSlider("knockbackMlt", knockbackMlt,"min:0,max:100,step:0.01,text_mult:1");

    // These ones are specific
    params.SetFloat("activeTime", 15.0f);
    params.SetFloat("respawnTime", 18.0f);

    params.SetString("startSoundPath", "Data/Sounds/DirtImpact2.wav");
    params.SetString("stopSoundPath", "Data/Sounds/DirtImpact1.wav");

    params.SetFloat("colorR", 1.0f);
    params.SetFloat("colorG", 1.0f);
    params.SetFloat("colorB", 0.0f);

    params.SetFloat("particleDelay", 0.0005f);
    params.SetString("pathToParticles", "Data/Particles/metalspark.xml");
    params.SetFloat("particleColorR", 0.7f);
    params.SetFloat("particleColorG", 0.5f);
    params.SetFloat("particleColorB", 0.0f);
}

void HandleEvent(string event, MovementObject @mo){
    PowerupHandleEvent(event, @mo);
}

void Update()
{
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
}

void PreScriptReload()
{
    powerupTimer.DeleteAll();
}