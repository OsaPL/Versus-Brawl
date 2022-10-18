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
    params.SetFloat("activeTime", 0.1f);
    params.SetFloat("respawnTime", 3.0f);

    params.SetFloat("colorR", 0.0f);
    params.SetFloat("colorG", 1.0f);
    params.SetFloat("colorB", 0.1f);

    params.SetFloat("particleDelay", 0.02f);
    params.SetString("pathToParticles", "Data/Particles/ninja_smoke.xml");
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
    powerupTimer.DeleteAll();
}