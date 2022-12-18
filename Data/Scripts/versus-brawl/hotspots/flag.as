#include "hotspots/placeholderFollower.as"

enum FlagState {
    Home = 0,
    Taken = 1,
    Dropped = 2
};

string FlagStateToString(FlagState toConvert){
    switch(toConvert){
        case Home: return "Home";
        case Taken: return "Taken";
        case Dropped: return "Dropped";
    }
    return "NA";
}

int weaponId = -1;
int lightId = -1;
bool justReleased = false;
vec3 color = vec3(0, 0.7f, 0);
int teamNr = -1;
FlagState state;

string polePath = "Data/Items/versus-brawl/flagPoleItem.xml";

void Init(){
    Object@ me = ReadObjectFromID(hotspot.GetID());
    me.SetScale(vec3(0.2f));
}

void SetParameters()
{
    params.AddFloatSlider("red", 1.0f, "min:0,max:3,step:0.01");
    params.AddFloatSlider("green", 1.0f, "min:0,max:3,step:0.01");
    params.AddFloatSlider("blue", 1.0f, "min:0,max:3,step:0.01");
    params.AddIntSlider("teamId", -1, "min:-1.0,max:3.0");
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

    PlaceHolderFollowerUpdate("Data/Textures/ui/versusBrawl/flag_icon.png", "["+teamNr+"] ["+ FlagStateToString(state) +"] [" + me.GetEnabled() + "]", 2.0f, false, vec4(color, 1), vec3(0, 0.5f, 0));
    
    color = vec3(params.GetFloat("red"), params.GetFloat("green"), params.GetFloat("blue"));
    
    if(weaponId == -1){
        //spawn weapon
        ReCreateFlagItem();
        Object@ obj = ReadObjectFromID(weaponId);
        obj.SetTranslation(me.GetTranslation()+vec3(0, 0.5f, 0));
        obj.SetRotation(me.GetRotation());
        state = Home;
    }
    if(lightId == -1){
        //spawn light
        lightId = CreateObject("Data/Objects/lights/dynamic_light.xml");
        Object@ obj = ReadObjectFromID(lightId);

        obj.SetScale(vec3(8));
    }

    Object@ weapObj = ReadObjectFromID(weaponId);
    ItemObject@ weap = ReadItemID(weaponId);
    weapObj.SetTint(color);

    // Move the light
    if(lightId != -1){
        Object@ obj = ReadObjectFromID(lightId);
        mat4 trans = weap.GetPhysicsTransform();
        mat4 rot = trans.GetRotationPart();
        obj.SetTranslation((trans*vec3())+(vec3(0,0.5f,0)));
        obj.SetRotation(QuaternionFromMat4(rot));
        obj.SetTint(color*2);
    }
    
    if(!weap.IsHeld()){
        if(justReleased){
            justReleased = false;
            // Recreate the flag and move it (moving itemObject is scuffed) to make it upright
            mat4 trans = weap.GetPhysicsTransform();
            ReCreateFlagItem();
            weapObj.SetTranslation(trans * vec3());
            state = Dropped;
        }
    }
    else{
        state = Taken;
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