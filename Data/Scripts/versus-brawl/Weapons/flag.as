int weaponId = -1;
int flagId = -1;
int lightId = -1;
bool justReleased = false;
vec3 color = vec3(1,0.7f,0);

string polePath = "Data/Items/versus-brawl/pole.xml";
string flagPath = "Data/Items/versus-brawl/flagTorn.xml";

void Init(){
    Object@ me = ReadObjectFromID(hotspot.GetID());
    me.SetScale(vec3(0.2f));
}

vec3 GetEndPosition(){
    Object@ obj = ReadObjectFromID(weaponId);
    ItemObject@ weap = ReadItemID(weaponId);
    int num_lines = weap.GetNumLines();
    mat4 trans = weap.GetPhysicsTransform();
    vec3 start = trans * (weap.GetPoint("wood_tip") - vec3(-0.4f, 0.41f, 0.05f));
    
    return start;
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
        obj.SetTranslation(me.GetTranslation());
        obj.SetRotation(me.GetRotation());
    }
    if(lightId == -1 && false){
        //spawn light
        lightId = CreateObject("Data/Objects/lights/dynamic_light.xml");
        Object@ obj = ReadObjectFromID(lightId);
        obj.SetTranslation(me.GetTranslation());
        obj.SetRotation(me.GetRotation());

        obj.SetScale(vec3(15));
        obj.SetTint(vec3(10,0,0));
    }
    if(flagId == -1 && false){
        //spawn flag
        flagId = CreateObject(flagPath);
        Object@ obj = ReadObjectFromID(flagId);
        obj.SetTint(vec3(1,0,0));
    }
    
    ItemObject@ weap = ReadItemID(weaponId);
    
    //SetTranslationRotationFast
    
    if(lightId != -1){
        Object@ obj = ReadObjectFromID(lightId);
        vec3 pos = GetEndPosition();
        mat4 trans = weap.GetPhysicsTransform();
        mat4 rot = trans.GetRotationPart();
        obj.SetTranslation(pos+(vec3(-0.5f,0.5f,-0.5f)));
        obj.SetRotation(QuaternionFromMat4(rot));
    }
    
    if(!weap.IsHeld()){
        // Object@ obj = ReadObjectFromID(flagId);
        // vec3 pos = GetEndPosition();
        // mat4 trans = weap.GetPhysicsTransform();
        // mat4 rot = trans.GetRotationPart();
        if(justReleased){
            justReleased = false;
            mat4 trans = weap.GetPhysicsTransform();
            ReCreateFlagItem();
            Object@ newObj = ReadObjectFromID(weaponId);
            newObj.SetTranslation(trans * vec3());
        }
        // Move flag part
        // obj.SetTranslation(pos);//+(vec3(0.5f,0,0)));
        // obj.SetRotation(QuaternionFromMat4(rot));
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
    if(flagId != -1){
        DeleteObjectID(flagId);
        flagId = -1;
    }
}

void PreDraw(float curr_game_time){
    // ItemObject@ weap = ReadItemID(weaponId);
    // Object@ obj = ReadObjectFromID(flagId);
    // vec3 pos = GetEndPosition();
    // mat4 trans = weap.GetPhysicsTransform();
    // mat4 rot = trans.GetRotationPart();
    //
    // obj.SetTranslationRotationFast(pos, QuaternionFromMat4(rot));
}