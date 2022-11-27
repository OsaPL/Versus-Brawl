#include "powerUpBase.as"

array<int> spawned_objectIds = {};
float time = 0;
// Lowest time between spawns
float minDelay = 0.3f;

void Init(){
    PowerupInit();
    powerupTimer.Add(LevelEventJob("activate", function(_params){
        PlaySound(params.GetString("startSoundPath"));
        time = 0;
        return true;
    }));
    powerupTimer.Add(LevelEventJob("deactivate", function(_params){
        PlaySound(params.GetString("endSoundPath"));
        return true;
    }));
    powerupTimer.Add(LevelEventJob("item_hit", function(_params){
        MovementObject@ mo = ReadCharacterID(parseInt(_params[1]));
        if(mo.GetIntVar("attacked_by_id") == lastEnteredPlayerObjId)
            PlaySound("Data/Sounds/unused/blow_dart_hit_02.wav");
        return true;
    }));
}

void SetParameters() {
    PowerupSetParameters();

    // These ones are specific
    params.SetFloat("activeTime", 9.0f);
    params.SetFloat("respawnTime", 30.0f);
    
    params.SetFloat("colorR", 0.5f);
    params.SetFloat("colorG", 0.0f);
    params.SetFloat("colorR", 1.0f);

    params.SetFloat("particleDelay", 0.02f);
    params.SetString("pathToParticles", "Data/Particles/versus-brawl/ninja_smoke.xml");
    params.SetFloat("particleColorR", 0.1f);
    params.SetFloat("particleColorG", 0.1f);
    params.SetFloat("particleColorB", 0.1f);
}

void HandleEvent(string event, MovementObject @mo){
    PowerupHandleEvent(event, @mo);
}

void Update()
{
    PowerupUpdate();
    
    if(active){
        //Powerup logic
        MovementObject@ mo = ReadCharacterID(lastEnteredPlayerObjId);
        Object@ obj = ReadObjectFromID(mo.GetID());
        ScriptParams@ objParams = obj.GetScriptParams();
        
        // If its "wolf" dont give a knife, cause he cant hold one
        if(objParams.HasParam("species")){
            if(objParams.GetString("species") == "wolf")
            {
                return;
            }
        }

        time += time_step;
        // Down spawn too often
        if(time < minDelay) {
            return;
        }
        
        int weapon = mo.GetArrayIntVar("weapon_slots",mo.GetIntVar("primary_weapon_slot"));

        if(weapon == -1) {
            time = 0;
            int knifeId = CreateObject("Data/Items/rabbit_weapons/rabbit_knife.xml");
            spawned_objectIds.push_back(knifeId);
            mo.Execute("AttachWeapon(" + knifeId + ");");
        }
    }
    else{
        // Cleanup knives
        if(spawned_objectIds.size()>0){
            lastEnteredPlayerObjId = -1;
            DeleteObjectsInList(spawned_objectIds);
        }
    }
}

void Dispose(){
    PowerupDispose();
    DeleteObjectsInList(spawned_objectIds);
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