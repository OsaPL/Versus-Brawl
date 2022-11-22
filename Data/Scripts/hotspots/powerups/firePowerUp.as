#include "powerUpBase.as"

float fireTime = 0.2f;
float fireStep = 0.02f;
float fireStepCounter = 0;
string slapSoundPath = "Data/Sounds/pop1.wav";
array<float> fireTimer = {};
array<int> fireTargets = {};

// did it expire or has been used
bool used = false;

void Init(){
    PowerupInit();
    
    powerupTimer.Add(LevelEventJob("activate", function(_params){
        PlaySound(params.GetString("startSoundPath"));

        return true;
    }));
    powerupTimer.Add(LevelEventJob("deactivate", function(_params){
        PlaySound(params.GetString("stopSoundPath"));

        return true;
    }));

    powerupTimer.Add(LevelEventJob("bluntHit", function(_params){
        Log(error, "FirePowerUp bluntHit: "+ _params[1]+ " " +_params[2]+" lastEnteredPlayerObjId: " + lastEnteredPlayerObjId);
        IgniteEnemyCheck(parseInt(_params[1]),parseInt(_params[2]));
        
        return true;
    }));
    powerupTimer.Add(LevelEventJob("character_thrown", function(_params){
        Log(error, "FirePowerUp character_thrown: "+ _params[1]+ " " +_params[2]+" lastEnteredPlayerObjId: " + lastEnteredPlayerObjId);
        IgniteEnemyCheck(parseInt(_params[2]),parseInt(_params[1]));

        return true;
    }));
    powerupTimer.Add(LevelEventJob("passive_blocked", function(_params){
        Log(error, "FirePowerUp passive_blocked: "+ _params[1]+ " " +_params[2]+" lastEnteredPlayerObjId: " + lastEnteredPlayerObjId);
        IgniteEnemyCheck(parseInt(_params[1]),parseInt(_params[2]));

        return true;
    }));
    powerupTimer.Add(LevelEventJob("active_blocked", function(_params){
        Log(error, "FirePowerUp active_blocked: "+ _params[1]+ " " +_params[2]+" lastEnteredPlayerObjId: " + lastEnteredPlayerObjId);
        IgniteEnemyCheck(parseInt(_params[1]),parseInt(_params[2]));

        return true;
    }));

}

void IgniteEnemyCheck (int victimId, int attackerId){
    if(active){
        if(lastEnteredPlayerObjId == attackerId)
        {
            // Check if hands are empty
            MovementObject@ mo = ReadCharacterID(lastEnteredPlayerObjId);
            int pWeapon = mo.GetArrayIntVar("weapon_slots",mo.GetIntVar("primary_weapon_slot"));

            if(pWeapon == -1) {
                fireTimer.push_back(fireTime);
                fireTargets.push_back(victimId);
                PlaySound("Data/Sounds/fire/character_fire_extinguish_small_shortened.wav");
            }
        }
    }
}

void SetParameters() {
    PowerupSetParameters();

    // These ones are specific
    params.SetFloat("activeTime", 15.0f);
    params.SetFloat("respawnTime", 16.0f);

    params.SetString("startSoundPath", "Data/Sounds/fire/character_catch_fire.wav");
    params.SetString("stopSoundPath", "Data/Sounds/fire/character_catch_fire_small.wav");

    params.SetFloat("colorR", 1.0f);
    params.SetFloat("colorG", 0.2f);
    params.SetFloat("colorB", 0.0f);

    params.SetFloat("particleDelay", 0.001f);
    params.SetString("pathToParticles", "Data/Particles/explosion_fire.xml");
    params.SetFloat("particleRangeMultiply", 0.3f);
    params.SetFloat("particleColorR", 1.0f);
    params.SetFloat("particleColorG", 0.3f);
    params.SetFloat("particleColorB", 0.0f);
}

void HandleEvent(string event, MovementObject @mo){
    PowerupHandleEvent(event, @mo);
}

void Update()
{
    // This is mainly done so that first roll after getting hit doesnt almost completely negate this powerup
    fireStepCounter += time_step;
    if(fireStepCounter>=fireStep){
        array<int> toRemove = {};
        for (uint i = 0; i < fireTimer.size(); i++)
        {
            fireTimer[i] -= fireStep;
            // Fire expires
            if(fireTimer[i] < 0){
                toRemove.push_back(i);
            }
            // Reapply fire
            else {
                MovementObject@victim = ReadCharacterID(fireTargets[i]);
                victim.Execute("SetOnFire(true);");
                //victim.Execute("SetOnFire(true);TakeBloodDamage(" + dmgBoost + "f);");
            }
        }
        
        // Cleanup expired ones
        for (uint i = 0; i < toRemove.size(); i++)
        {
            fireTimer.removeAt(toRemove[i]);
            fireTargets.removeAt(toRemove[i]);
        }

        fireStepCounter = 0;
    }
    
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