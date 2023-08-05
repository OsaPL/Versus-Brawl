#include "hotspots/placeholderFollower.as"
#include "versus-brawl/utilityStuff/fileChecks.as"

vec3 oldPos;
quaternion oldRot;
string oldPath = "Data/Items/Rapier.xml";
float spawnTimer = 0;
int weaponId = -1;
bool justReleased = true;

void Init(){
    Object@ me = ReadObjectFromID(hotspot.GetID());

    oldPos = me.GetTranslation();
    oldRot = me.GetRotation();

    me.SetScale(vec3(0.1f));
}

void SetParameters() {
    params.AddString("ItemPath", oldPath);
    params.AddIntSlider("RespawnTime", 10.0f, "min:0.0,max:100.0");
    params.AddIntSlider("RespawnDistance", 3.0f, "min:0.0,max:100.0");
    params.AddString("game_type", "versusBrawl");
}

void Update(){
    if(EditorModeActive()) {
        PlaceHolderFollowerUpdate("Data/Textures/ui/versusBrawl/placeholder_weapon_spawn.png", "[" + oldPath + "]");
    }
    // Get hotspot and placeholder, and then setup
    Object@ me = ReadObjectFromID(hotspot.GetID());

    if (oldPath != params.GetString("ItemPath")) {
        Log(error, "ItemPath changed, removing");
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
        Log(error, "weaponId missing, spawning");
        weaponId = CreateObject(params.GetString("ItemPath"));
        Object@ obj = ReadObjectFromID(weaponId);
        obj.SetTranslation(me.GetTranslation());
        obj.SetRotation(me.GetRotation());
        spawnTimer = params.GetInt("RespawnTime");
        justReleased = false;
    }
    
    Object@ obj = ReadObjectFromID(weaponId);
    ItemObject@ itemObj = ReadItemID(weaponId);
    
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