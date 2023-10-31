#include "powerUpBase.as"

void Init(){
    PowerupInit();
    
    powerupTimer.Add(LevelEventJob("activate", function(_params){
        MovementObject@ mo = ReadCharacterID(lastEnteredPlayerObjId);
        mo.Execute("Recover();");
        PlaySound(params.GetString("startSoundPath"));
        return true;
    }));
    powerupTimer.Add(LevelEventJob("deactivate", function(_params){
        
        return true;
    }));
}

void SetParameters() {
    PowerupSetParameters();

    // These ones are specific
    params.SetFloat("activeTime", 1.3f);
    params.SetFloat("respawnTime", 4.0f);

    params.SetString("startSoundPath", "Data/Sounds/cooling tower short.wav");

    params.SetFloat("colorR", 0.0f);
    params.SetFloat("colorG", 1.0f);
    params.SetFloat("colorB", 0.1f);

    params.SetFloat("particleDelay", 0.15f);
    params.AddFloatSlider("particleRangeMultiply", 0.6f,"min:0,max:100,step:0.1,text_mult:1");
    params.SetString("pathToParticles", "Data/Particles/versus-brawl/heals_puff.xml");
    params.SetFloat("particleColorR", 0.4f);
    params.SetFloat("particleColorG", 1.0f);
    params.SetFloat("particleColorB", 0.4f);
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
    PowerupPreScriptReload();
}