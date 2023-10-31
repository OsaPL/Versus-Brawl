#include "powerUpBase.as"

int parentId = -1;
string billboardPath = "Data/Textures/ui/menus/main/icon-retry.png";

void Init(){
    PowerupInit();

    powerupTimer.Add(LevelEventJob("activate", function(_params){
        if(params.GetInt("RefreshAll") != 0) {
            level.SendMessage("RefreshAllPowerups");
        }
        else{
            if(parentId != -1){
                Object@ me = ReadObjectFromID(parentId);
                me.ReceiveScriptMessage("RefreshPowerup");
            }
        }
        PlaySound(params.GetString("startSoundPath"));
        return true;
    }));
    powerupTimer.Add(LevelEventJob("deactivate", function(_params){

        return true;
    }));
}

void SetParameters() {
    PowerupSetParameters();

    params.AddIntCheckbox("RefreshAll", false);

    // These ones are specific
    params.SetFloat("activeTime", 0.0f);
    params.SetFloat("respawnTime", 10.0f);

    params.SetString("startSoundPath", "Data/Sounds/unused/blow_dart_02.wav");

    //params.SetString("notReadyIconPath", billboardPath);
    params.SetString("readyIconPath", billboardPath);

    params.SetFloat("colorR", 0.0f);
    params.SetFloat("colorG", 0.3f);
    params.SetFloat("colorB", 0.35f);
}

void HandleEvent(string event, MovementObject @mo){
    PowerupHandleEvent(event, @mo);
}

void Update()
{
    ignoreRefreshMessages = true;
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

bool AcceptConnectionsFrom(Object@ other) {
    return false;
}

bool AcceptConnectionsTo(Object@ other) {
    return true;
}

bool ConnectTo(Object@ other)
{
    parentId = other.GetID();
    return true;
}

bool Disconnect(Object@ other)
{
    parentId = -1;
    return true;
}
