﻿void Init(){
    Object@ me = ReadObjectFromID(hotspot.GetID());

    oldPos = me.GetTranslation();
    oldRot = me.GetRotation();

    me.SetScale(vec3(0.1f));
}

vec3 oldPos;
quaternion oldRot;
string oldPath = "Data/Items/Rapier.xml";
float spawnTimer = 0;
int weaponId = -1;

int placeholderId = -1;

void SetParameters() {
    params.AddString("ItemPath", oldPath);
    params.AddIntSlider("RespawnTime", 10.0f, "min:0.0,max:100.0");
    params.AddIntSlider("RespawnDistance", 3.0f, "min:0.0,max:100.0");
    params.AddString("game_type", "versusBrawl");
}

void Update(){
    // placeholder is missing create it
    if(placeholderId == -1)
        placeholderId = CreateObject("Data/Objects/placeholder/placeholder_arena_spawn.xml");
    
    // Get hotspot and placeholder, and then setup
    Object@ me = ReadObjectFromID(hotspot.GetID());
    Object@ placeholderObj = ReadObjectFromID(placeholderId);
    PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(placeholderObj);
    placeholder_object.SetBillboard("Data/Textures/ui/versusBrawl/placeholder_weapon_spawn.png");
    placeholderObj.SetEditorLabel("["+oldPath+"]");
    // This part makes placeholder follow
    placeholderObj.SetTranslation(me.GetTranslation());
    placeholderObj.SetRotation(me.GetRotation());
    placeholderObj.SetScale(vec3(2));
    
    if(weaponId == -1){
        Log(error, "weaponId missing, spawning");
        weaponId = CreateObject(params.GetString("ItemPath"));
        Object@ obj = ReadObjectFromID(weaponId);
        obj.SetTranslation(me.GetTranslation());
        obj.SetRotation(me.GetRotation());
        spawnTimer = params.GetInt("RespawnTime");
    }
    
    if(oldPath != params.GetString("ItemPath")) {
        Log(error, "ItemPath changed, removing");
        DeleteObjectID(weaponId);
        weaponId = -1;
        spawnTimer = params.GetInt("RespawnTime");
        oldPath = params.GetString("ItemPath");
        return;
    }

    Object@ obj = ReadObjectFromID(weaponId);

    if(oldPos != me.GetTranslation() || oldRot != me.GetRotation()) {
        Log(error, "pos or rot changed, moving");
        obj.SetTranslation(me.GetTranslation());
        obj.SetRotation(me.GetRotation());
    }

    ItemObject@ itemObj = ReadItemID(weaponId);
    if(!itemObj.IsHeld()){
        vec3 distVec = itemObj.GetPhysicsTransform()* vec3(0.0f, 0.0f, 0.0f) - me.GetTransform()* vec3(0.0f, 0.0f, 0.0f);
        
        if(length(distVec)> params.GetInt("RespawnDistance"))
        {
            //Log(error, "Is too far "+ length(distVec) + " spawnTimer:"+spawnTimer);
            spawnTimer -= time_step;
            if(spawnTimer<0){
                Log(error, "removing: "+weaponId+" distance:"+length(distVec)); 
                DeleteObjectID(weaponId);
                weaponId = -1;
                spawnTimer = 0;
            }

        }
        else
        {
            spawnTimer = params.GetInt("RespawnTime");
        }
    }
}

void Dispose(){
    if(weaponId != -1){
        DeleteObjectID(weaponId);
        weaponId = -1;
    }
    if(ObjectExists(placeholderId)) {
        // Cleanup placeholder
        DeleteObjectID(placeholderId);
    }
}

void Reset(){
    if(weaponId != -1){
        DeleteObjectID(weaponId);
        weaponId = -1;
    }
}