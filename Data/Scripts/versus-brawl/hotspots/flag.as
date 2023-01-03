#include "hotspots/placeholderFollower.as"

enum FlagState {
    FlagHome = 0, 
    FlagTaken = 1, 
    FlagDropped = 2
};

string FlagStateToString(FlagState toConvert){
    switch(toConvert){
        case FlagHome: return "Home";
        case FlagTaken: return "Taken";
        case FlagDropped: return "Dropped";
    }
    return "NA";
}

int weaponId = -1;
int lightId = -1;
bool justReleased = false;
vec3 color = vec3(0, 0.7f, 0);
int teamNr = -1;
FlagState flagState = FlagHome;
float returnTimer = 0;
float returnCooldown = 10;

float manualReturnBlockTimer = 0;
float manualReturnBlockCooldown = 3;
string billboardPath = "Data/Textures/ui/versusBrawl/flag_icon.png";

string flagManualReturnSound = "Data/Sounds/sword/hard_drop_1.wav";
string flagReturnSound = "Data/Sounds/sword/sword_wood_1.wav";

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

void HandleEvent(string event, MovementObject @mo)
{
    if (event == "enter") {
        if (mo.is_player) {
            if(manualReturnBlockTimer >= manualReturnBlockCooldown){
                FlagManualReturnCheck(mo.GetID());
            }
        }
    }
}

void ReCreateFlagItem(){
    if(weaponId != -1)
        DeleteObjectID(weaponId);

    weaponId = CreateObject(polePath);
    Object@ obj = ReadObjectFromID(weaponId);
    ScriptParams @objParams = obj.GetScriptParams();
    objParams.SetInt("teamId", params.GetInt("teamId"));
    obj.UpdateScriptParams();

    obj.SetTint(color);
}


void FlagReturn(){
    FlagDispose();
    justReleased = false;
    returnTimer = 0;
    manualReturnBlockTimer = 0;
}

void FlagManualReturnCheck(int objId){
    Object@ weapObj = ReadObjectFromID(weaponId);
    ItemObject@ weap = ReadItemID(weaponId);
    if(objId == weap.HeldByWhom()){
        PlaySound(flagManualReturnSound);
        FlagReturn();
    }
}

void Update(){
    Object@ me = ReadObjectFromID(hotspot.GetID());

    PlaceHolderFollowerUpdate(billboardPath, "["+teamNr+"] ["+ FlagStateToString(flagState) +"] [" + returnTimer + "] [" + (me.GetEnabled() ? "Enabled" : "Disabled") + "]", 2.0f, false, vec4(color, 1), vec3(0, 0.5f, 0));
    
    color = vec3(params.GetFloat("red"), params.GetFloat("green"), params.GetFloat("blue"));

    DebugDrawBillboard(billboardPath,
        me.GetTranslation() + vec3(0, 0.5f, 0),
        2.0f,
        vec4(color,1),
        _delete_on_update);
    
    if(weaponId == -1){
        //spawn weapon
        ReCreateFlagItem();
        Object@ obj = ReadObjectFromID(weaponId);
        obj.SetTranslation(me.GetTranslation()+vec3(0, 0.5f, 0));
        obj.SetRotation(me.GetRotation());
        flagState = FlagHome;
        returnTimer = 0;
    }
    if(lightId == -1){
        //spawn light
        lightId = CreateObject("Data/Objects/lights/dynamic_light.xml");
        Object@ obj = ReadObjectFromID(lightId);

        obj.SetScale(vec3(8));
    }

    Object@ weapObj = ReadObjectFromID(|);
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
            flagState = FlagDropped;
        }
        if(flagState == FlagDropped){//dropped) {
            // Doing a "future" check to make sure we dont show -1;
            if(returnTimer + time_step >= returnCooldown){
                PlaySound(flagReturnSound);
                FlagReturn();
            }
            else{
                returnTimer += time_step;
                // TODO! Number is barely visible, add a more readable way (Big, texture based numbers? And Icon that lowers its transparency/saturation?)
                // Draws text with cooldown when dropped
                DebugDrawText(
                    weap.GetPhysicsTransform() * vec3(),
                    ""+ceil(returnCooldown - returnTimer),
                    2.0f,
                    true,
                    _delete_on_update);
            }
        }
    }
    else{
        flagState = FlagTaken;
        returnTimer = 0;

        // Guards from accidental returning when just taken
        if(manualReturnBlockTimer < manualReturnBlockCooldown){
            manualReturnBlockTimer += time_step;
        }
        
        justReleased = true;
    }
}

void Dispose(){
    FlagDispose();
}

void FlagDispose(){
    if(weaponId != -1){
        DeleteObjectID(weaponId);
        weaponId = -1;
    }
    if(lightId != -1){
        DeleteObjectID(lightId);
        lightId = -1;
    }
}