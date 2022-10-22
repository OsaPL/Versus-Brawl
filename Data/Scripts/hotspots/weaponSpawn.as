void Init(){
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

void SetParameters() {
    params.AddString("ItemPath", oldPath);
    params.AddIntSlider("RespawnTime", 2.0f, "min:0.0,max:10.0");
    params.AddString("game_type", "versusBrawl");
}

void Update(){
    Object@ me = ReadObjectFromID(hotspot.GetID());
    
    if(weaponId == -1){
        weaponId = CreateObject(params.GetString("ItemPath"));
        spawnTimer = params.GetInt("RespawnTime");
    }
    
    if(oldPath != params.GetString("ItemPath")) {
        DeleteObjectID(weaponId);
        weaponId = -1;
        spawnTimer = 0;
        oldPath = params.GetString("ItemPath");
        return;
    }

    Object@ obj = ReadObjectFromID(weaponId);

    if(oldPos != me.GetTranslation() || oldRot != me.GetRotation()) {
        obj.SetTranslation(me.GetTranslation());
        obj.SetRotation(me.GetRotation());
    }

    ItemObject@ itemObj = ReadItemID(weaponId);
    if(!itemObj.IsHeld()){
        vec3 distVec = itemObj.GetPhysicsTransform()* vec3(0.0f, 0.0f, 0.0f) - me.GetTransform()* vec3(0.0f, 0.0f, 0.0f);

        
        if(length(distVec)> 3.0f)
        {
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
    if(weaponId != -1)
        DeleteObjectID(weaponId);
}