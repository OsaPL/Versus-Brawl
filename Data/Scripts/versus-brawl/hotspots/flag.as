int weaponId = -1;
int lightId = -1;
bool justReleased = false;
vec3 color = vec3(0, 0.7f, 0);

string polePath = "Data/Items/versus-brawl/flagPoleItem.xml";

void Init(){
    Object@ me = ReadObjectFromID(hotspot.GetID());
    me.SetScale(vec3(0.2f));
}

void Reset(){
    Dispose();
}

bool init = false;

void ReCreateFlagItem(){
    if(weaponId != -1)
        DeleteObjectID(weaponId);

    weaponId = CreateObject(polePath);
    Object@ obj = ReadObjectFromID(weaponId);
    obj.SetTint(color);
}


void Update(){
    Object@ me = ReadObjectFromID(hotspot.GetID());
    
    if(weaponId == -1){
        //spawn weapon
        ReCreateFlagItem();
        Object@ obj = ReadObjectFromID(weaponId);
        obj.SetTranslation(me.GetTranslation()+vec3(0, 0.5f, 0));
        obj.SetRotation(me.GetRotation());
    }
    if(lightId == -1){
        //spawn light
        lightId = CreateObject("Data/Objects/lights/dynamic_light.xml");
        Object@ obj = ReadObjectFromID(lightId);

        obj.SetScale(vec3(8));
        obj.SetTint(color*2);
    }
    
    ItemObject@ weap = ReadItemID(weaponId);
    
    // Move the light
    if(lightId != -1){
        Object@ obj = ReadObjectFromID(lightId);
        mat4 trans = weap.GetPhysicsTransform();
        mat4 rot = trans.GetRotationPart();
        obj.SetTranslation((trans*vec3())+(vec3(0,0.5f,0)));
        obj.SetRotation(QuaternionFromMat4(rot));
    }
    
    if(!weap.IsHeld()){
        if(justReleased){
            justReleased = false;
            // Recreate the flag and move it (moving itemObject is scuffed) to make it upright
            mat4 trans = weap.GetPhysicsTransform();
            ReCreateFlagItem();
            Object@ newObj = ReadObjectFromID(weaponId);
            newObj.SetTranslation(trans * vec3());
        }
    }
    else{
        justReleased = true;
    }
}

void Dispose(){
    if(weaponId != -1){
        DeleteObjectID(weaponId);
        weaponId = -1;
    }
    if(lightId != -1){
        DeleteObjectID(lightId);
        lightId = -1;
    }
}