#include "hotspots/placeholderFollower.as"
#include "versus-brawl/utilityStuff/fileChecks.as"

#include "timed_execution/timed_execution.as"
#include "timed_execution/level_event_job.as"
#include "timed_execution/delayed_job.as"
TimedExecution spawnerTimer;

vec3 oldPos;
quaternion oldRot;
string oldPath = "Data/Items/Rapier.xml";
float spawnTimer = 0;
int weaponId = -1;
bool justReleased = true;
int usesLeft = -1;
bool init = false;
int breakEmitterId = -1;

void Init(){
    Object@ me = ReadObjectFromID(hotspot.GetID());
    // Enables receiving level msgs (performance heavy)
    level.ReceiveLevelEvents(hotspot.GetID());

    oldPos = me.GetTranslation();
    oldRot = me.GetRotation();

    me.SetScale(vec3(0.1f));

    AddEvent();
}

void AddEvent(){
    // Adds durability counting
    spawnerTimer.Add(LevelEventJob("bluntHit", function(_params){
        Degrade(parseInt(_params[2]));
        return true;
    }));
    spawnerTimer.Add(LevelEventJob("cut", function(_params){
        Degrade(parseInt(_params[2]));
        return true;
    }));
    spawnerTimer.Add(LevelEventJob("weaponBlock", function(_params){
        // TOOD! Blocking should only use up weapon for the defender?
        Degrade(parseInt(_params[2]));
        return true;
    }));
}

void Degrade(int attackerId, int usageChance = 100){
    // Ignore since its not turned on
    if(params.GetInt("Durability") < 0)
        return;
        
    // Roll for usage save
    //if(rand()%100 < usageChance)    
        //return;
        
    if(ObjectExists(weaponId)){
        ItemObject@ weap = ReadItemID(weaponId);
        int holderId = weap.HeldByWhom();
        if(ObjectExists(holderId) && holderId == attackerId){
            if(usesLeft>0){
                // Use up durability
                usesLeft = usesLeft - 1;
            }
            else{
                // Its already used up, destroy
                
                mat4 transform = weap.GetPhysicsTransform();
                mat4 rot = transform.GetRotationPart();
                vec3 translation = (transform*vec3());
                breakEmitterId = CreateObject("Data/Objects/powerups/objectFollowerEmitter.xml");
                Object@ obj = ReadObjectFromID(breakEmitterId);
                obj.SetTranslation(translation);
                ScriptParams@ objParams = obj.GetScriptParams();
                objParams.SetFloat("particleDelay", 0.05f);
                objParams.SetFloat("particleRangeMultiply", 0.1f);
                //objParams.SetString("pathToParticles", params.GetString("pathToParticles"));
                objParams.SetFloat("particleColorR", 0.3f);
                objParams.SetFloat("particleColorG", 0.25f);
                objParams.SetFloat("particleColorB", 0.25f);
                obj.UpdateScriptParams();
                spawnerTimer.Add(DelayedJob(0.5f, function(){
                    QueueDeleteObjectID(breakEmitterId);
                }));
                PlaySound("Data/Sounds/unused/blow_dart_hit_02.wav");
                
                // TODO! Add a cool poof particle and sounds
                // Maybe even in DisposeWeapon() method itself?
                DisposeWeapon();
            }
        }
    }
}

void SetParameters() {
    params.AddString("ItemPath", oldPath);
    params.AddIntSlider("RespawnTime", 10.0f, "min:0.0,max:100.0");
    params.AddIntSlider("RespawnDistance", 3.0f, "min:0.0,max:100.0");
    params.AddIntSlider("Durability", 3.0f, "min:-1.0,max:100.0");
    params.AddString("game_type", "versusBrawl");
}

void Update(){
    if(EditorModeActive()) {
        PlaceHolderFollowerUpdate("Data/Textures/ui/versusBrawl/placeholder_weapon_spawn.png", "[" + oldPath + "]");
    }
    
    if(init){
        AddEvent();
        init = false;
    }
    
    // Get hotspot and placeholder, and then setup
    Object@ me = ReadObjectFromID(hotspot.GetID());
    
    if (oldPath != params.GetString("ItemPath")) {
        Log(info, "ItemPath changed, removing");
        DisposeWeapon();
        string path = params.GetString("ItemPath");
        if(!FileExistsWithType(path, ".xml")){
            // Path isnt an xml, just abort for now
            return;
        }
        spawnTimer = params.GetInt("RespawnTime");
        oldPath = params.GetString("ItemPath");
        justReleased = false;
        return;
    }
    
    if(weaponId == -1){
        Log(info, "weaponId missing, spawning");
        weaponId = CreateObject(params.GetString("ItemPath"));
        Object@ obj = ReadObjectFromID(weaponId);
        obj.SetTranslation(me.GetTranslation());
        obj.SetRotation(me.GetRotation());
        spawnTimer = params.GetInt("RespawnTime");
        justReleased = false;
        usesLeft = params.GetInt("Durability");
    }
    
    Object@ obj = ReadObjectFromID(weaponId);
    ItemObject@ itemObj = ReadItemID(weaponId);
    
    // TODO! Better way to signpost durabilioty?
    if(params.GetInt("Durability") >= 0){
        mat4 transform = itemObj.GetPhysicsTransform();
        mat4 rot = transform.GetRotationPart();
        DebugDrawText(
            (transform*vec3())+(vec3(0, 0.1f, 0)), 
            ""+usesLeft, 
            1.0f, 
            true,
            _delete_on_update);
    }
    
    if(!itemObj.IsHeld()){
        // Dont move if just dropped/thrown!
        if(!justReleased){
            if (oldPos != me.GetTranslation() || oldRot != me.GetRotation()) {
                //Log(error, "pos or rot changed, moving");
                if(spawnTimer != params.GetInt("RespawnTime"))
                    Log(error, "spawnTimer: " + spawnTimer);
                obj.SetTranslation(me.GetTranslation());
                obj.SetRotation(me.GetRotation());
            }
        }
        
        vec3 distVec = itemObj.GetPhysicsTransform()* vec3(0.0f, 0.0f, 0.0f) - me.GetTransform()* vec3(0.0f, 0.0f, 0.0f);

        if(length(distVec)> params.GetInt("RespawnDistance"))
        {
            //Log(error, "Is too far "+ length(distVec) + " spawnTimer:"+spawnTimer);
            spawnTimer -= time_step;
            if(spawnTimer<0){
                Log(error, "removing: "+weaponId+" distance:"+length(distVec));
                DisposeWeapon();
                spawnTimer = 0;
                justReleased = false;
            }
        }
        else
        {
            spawnTimer = params.GetInt("RespawnTime");
        }
    }
    else{
        justReleased = true;
    }
    
    spawnerTimer.Update();
}

void Dispose(){
    DisposeWeapon();
}

void Reset(){
    DisposeWeapon();
}

void DisposeWeapon(){
    if(weaponId != -1){
        DeleteObjectID(weaponId);
        weaponId = -1;
    }
}

void ReceiveMessage(string msg){
    spawnerTimer.AddEvent(msg);
    
}

void PreScriptReload(){
    spawnerTimer.DeleteAll();
    init = true;
}