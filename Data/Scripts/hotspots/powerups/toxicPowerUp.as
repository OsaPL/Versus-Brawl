#include "powerUpBase.as"

float range = 2.5f;
float decayTime = 5.0f;
string slapSoundPath = "Data/Sounds/pop1.wav";
array<int> affectedIds = {};
array<int> affectedEmittersIds = {};
array<float> affectedTimers = {};

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
    
}

void SetParameters() {
    PowerupSetParameters();

    params.AddFloatSlider("range", range,"min:0,max:100,step:0.01,text_mult:1");
    params.AddFloatSlider("decayTime", decayTime,"min:0,max:100,step:0.01,text_mult:1");

    // These ones are specific
    params.SetFloat("activeTime", 15.0f);
    params.SetFloat("respawnTime", 18.0f);

    params.SetString("startSoundPath", "Data/Sounds/footstep_mud_3.wav");
    params.SetString("stopSoundPath", "Data/Sounds/footstep_mud_7.wav");

    params.SetFloat("colorR", 0.05f);
    params.SetFloat("colorG", 0.4f);
    params.SetFloat("colorB", 0.3f);

    params.SetFloat("particleDelay", 0.06f);
    params.SetString("pathToParticles", "Data/Particles/toxic_cloud.xml");
    params.SetFloat("particleRangeMultiply", range * 1.0f);
    params.SetFloat("particleColorR", 0.05f);
    params.SetFloat("particleColorG", 0.4f);
    params.SetFloat("particleColorB", 0.3f);
}

void HandleEvent(string event, MovementObject @mo){
    PowerupHandleEvent(event, @mo);
}

void Update()
{
    if(active){
        int num_chars = GetNumCharacters();
        MovementObject @user = ReadCharacterID(lastEnteredPlayerObjId);
        for(int i=0; i<num_chars; ++i)
        {
            MovementObject@ mo = ReadCharacter(i);
            if(lastEnteredPlayerObjId != mo.GetID())
            {
                // Dont affect corpses
                if(mo.GetIntVar("knocked_out") != _awake){
                    //Disable powerup effect on dead characters
                    int toRemove = -1;
                    for(uint k=0; k<affectedIds.size(); ++k){
                        if(affectedIds[k] == mo.GetID()){
                            Log(error, "Drunkmode disabled cause died for: " + affectedIds[k]);
                            mo.Execute("drunkMode=false;");
                            PlaySound("Data/Sounds/unused/blow_dart_03.wav");

                            DeleteObjectID(affectedEmittersIds[k]);
                            toRemove = k;
                        }
                    }

                    if(toRemove != -1){
                        affectedIds.removeAt(toRemove);
                        affectedTimers.removeAt(toRemove);
                        affectedEmittersIds.removeAt(toRemove);
                    }
                    
                    return;
                }
                
                // First search for anyone who is in range
                float dist = distance(user.position, mo.position);
                //Log(error, "dist between " + user.GetID() + " and " + mo.GetID() + ": " + dist);
                if(dist < range){
                    bool found = false;
                    for(uint k=0; k<affectedIds.size(); ++k){
                        if(affectedIds[k] == mo.GetID()){
                            affectedTimers[k] = decayTime;
                            //Log(error, "Drunkmode timer reset for: " + mo.GetID());
                            found = true;
                        }
                    }
    
                    if(!found) {
                        Log(error, "Drunkmode set for: " + mo.GetID());
                        mo.Execute("drunkMode=true;");
                        PlaySound("Data/Sounds/unused/blow_dart_01.wav");
                        
                        affectedIds.push_back(mo.GetID());
                        affectedTimers.push_back(decayTime);
                        Log(error, "Drunkmode affectedIds.size(): " + affectedIds.size() + " affectedIds[affectedIds.size()-1]: " + affectedIds[affectedIds.size()-1]);

                        // Create a cloud around affected player
                        int emitterId = CreateObject("Data/Objects/powerups/objectFollowerEmitter.xml");
                        affectedEmittersIds.push_back(emitterId);
                        Object@ obj = ReadObjectFromID(emitterId);
                        ScriptParams@ objParams = obj.GetScriptParams();
                        objParams.SetInt("objectIdToFollow", mo.GetID());
                        objParams.SetFloat("particleDelay", params.GetFloat("particleDelay") * 12.0f);
                        objParams.SetFloat("particleRangeMultiply", params.GetFloat("particleRangeMultiply") * 0.15f);
                        objParams.SetString("pathToParticles", params.GetString("pathToParticles"));
                        objParams.SetFloat("particleColorR", params.GetFloat("particleColorR") * 2.5f);
                        objParams.SetFloat("particleColorG", params.GetFloat("particleColorG") * 2.5f);
                        objParams.SetFloat("particleColorB", params.GetFloat("particleColorB") * 2.5f);
                        obj.UpdateScriptParams();
                    }
                }
            }
        }
        
        // Now check if it expired for anyone
        array<int> toRemove = {};
        for(uint k=0; k<affectedTimers.size(); ++k)
        {
            affectedTimers[k] -= time_step;
            //Log(error, "Drunkmode timer for: " + mo.GetID());
            if (affectedTimers[k] < 0) {
                Log(error, "Drunkmode disabled for: " + affectedIds[k]);
                MovementObject@ mo = ReadCharacterID(affectedIds[k]);
                mo.Execute("drunkMode=false;");
                PlaySound("Data/Sounds/unused/blow_dart_03.wav");
                
                DeleteObjectID(affectedEmittersIds[k]);
                toRemove.push_back(k);
            }
        }
        
        for(uint k=0; k<toRemove.size(); ++k)
        {
            affectedIds.removeAt(toRemove[k]);
            affectedTimers.removeAt(toRemove[k]);
            affectedEmittersIds.removeAt(toRemove[k]);
        }
    }
    
    PowerupUpdate();
}


void Dispose(){
    PowerupDispose();
    for(uint k=0; k<affectedEmittersIds.size(); ++k)
    {
        DeleteObjectID(affectedEmittersIds[k]);
    }
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