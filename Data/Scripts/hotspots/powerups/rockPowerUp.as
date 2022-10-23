#include "powerUpBase.as"

float originalDamageReduction;

void Init(){
    PowerupInit();
    
    powerupTimer.Add(LevelEventJob("activate", function(_params){
        Object @obj = ReadObjectFromID(lastEnteredPlayerObjId);
        ScriptParams@ objParams = obj.GetScriptParams();
        originalDamageReduction = objParams.GetFloat("Damage Resistance");
        objParams.SetFloat("Damage Resistance", originalDamageReduction*params.GetFloat("reduction"));
        obj.UpdateScriptParams();
        
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
        
        PlaySound(params.GetString("endSoundPath"));

        return true;
    }));
}

void SetParameters() {
    PowerupSetParameters();

    params.AddFloatSlider("reduction", 6.0f,"min:0,max:100,step:0.01,text_mult:1");

    // These ones are specific
    params.SetFloat("activeTime", 12.0f);
    params.SetFloat("respawnTime", 25.0f);

    params.SetString("startSoundPath", "Data/Sounds/rockbreak.wav");
    params.SetString("endSoundPath", "Data/Sounds/rockhit.wav");

    params.SetFloat("colorR", 0.1f);
    params.SetFloat("colorG", 0.1f);
    params.SetFloat("colorB", 0.7f);

    params.SetFloat("particleDelay", 0.02f);
    params.SetString("pathToParticles", "Data/Particles/explosion_fire.xml");
    params.SetFloat("particleColorR", 0.2f);
    params.SetFloat("particleColorG", 0.2f);
    params.SetFloat("particleColorB", 1.0f);
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