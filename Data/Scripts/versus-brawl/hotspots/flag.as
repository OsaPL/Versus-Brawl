#include "timed_execution/timed_execution.as"
#include "timed_execution/level_event_job.as"

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

// configurables
float returnCooldown = 10;
vec3 color = vec3(0, 0.7f, 0);
float manualReturnBlockCooldown = 2;

// TODO: Make these configurable
string billboardPath = "Data/Textures/ui/versusBrawl/flag_icon.png";

string flagManualReturnSound = "Data/Sounds/sword/hard_drop_1.wav";
string flagReturnSound = "Data/Sounds/sword/sword_wood_1.wav";

// states
int weaponId = -1;
int lightId = -1;
bool justReleased = false;
FlagState flagState = FlagHome;
float returnTimer = 0;
TimedExecution flagTimer;
float manualReturnBlockTimer = 0;

float timeToUnlock = 5;
float unlockTimer = 0;

int holder_id = -1;

string polePath = "Data/Items/versus-brawl/flagPoleItem.xml";

void Init(){
    Object@ me = ReadObjectFromID(hotspot.GetID());
    me.SetScale(vec3(0.2f));

    flagTimer.Add(LevelEventJob("flagReturn", function(_params){
        //Log(error, "flagReturn " + _params[1]);
        FlagManualReturnCheck(parseInt(_params[1]), _params[2] == "true" );
        return true;
    }));
}

void SetParameters()
{
    params.AddString("type", "flagHotspot");
    params.AddFloatSlider("red", 1.0f, "min:0,max:3,step:0.01");
    params.AddFloatSlider("green", 1.0f, "min:0,max:3,step:0.01");
    params.AddFloatSlider("blue", 1.0f, "min:0,max:3,step:0.01");
    params.AddFloatSlider("debuffCarrier", 1.0f, "min:0.0,max:1.0,step:0.01");
    params.AddIntSlider("teamId", -1, "min:-1.0,max:3.0");
}

void Reset(){
    Dispose();
}

void ReceiveMessage(string msg)
{
    // this will receive messages aimed at this object
    flagTimer.AddLevelEvent(msg);
}

void HandleEvent(string event, MovementObject @mo)
{
    if (event == "enter") {
        if (mo.is_player) {
            int weapon = mo.GetArrayIntVar("weapon_slots",mo.GetIntVar("primary_weapon_slot"));
            if(weapon == -1)
                return;
            
            Object@ obj = ReadObjectFromID(weapon);
            ScriptParams @objParams = obj.GetScriptParams();
            ItemObject @item = ReadItemID(weapon);
            string label = item.GetLabel();

            if (label != "flag")
                return;
            
            Log(error, "inc: " + objParams.GetInt("teamId") + " this: " + params.GetInt("teamId"));
            if(objParams.GetInt("teamId") != params.GetInt("teamId")){
                Object@ parentHotspotObj = ReadObjectFromID(objParams.GetInt("parentHotspotId"));

                parentHotspotObj.ReceiveScriptMessage("flagReturn " + weapon + " " + false);

                // Captured enemy flag event message "FlagCaptured <team whose flag got captured> <team capturing flag>
                level.SendMessage("flagCaptured " + params.GetInt("teamId") + " " + objParams.GetInt("teamId"));
            }
            else if(manualReturnBlockTimer >= manualReturnBlockCooldown){
                FlagManualReturnCheck(weapon, true);
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
    objParams.SetInt("parentHotspotId", hotspot.GetID());
    obj.UpdateScriptParams();

    obj.SetTint(color);
}


void FlagReturn(){
    FlagDispose();
    justReleased = false;
    returnTimer = 0;
    manualReturnBlockTimer = 0;
}

void FlagManualReturnCheck(int objId, bool sameTeam){
    //Log(error, "FlagManualReturnCheck " + objId + " " + weaponId);

    if(objId == weaponId){
        if(sameTeam)
            PlaySound(flagManualReturnSound);
        
        FlagReturn();
    }
}

void Update(){
    flagTimer.Update();
    
    Object@ me = ReadObjectFromID(hotspot.GetID());

    float trans = 0;
    if(flagState != FlagHome){
        if(manualReturnBlockTimer > 0)
            trans = manualReturnBlockTimer / manualReturnBlockCooldown;
    }

    PlaceHolderFollowerUpdate(billboardPath, EditorModeActive() ? "["+params.GetFloat("teamId")+"] ["+ FlagStateToString(flagState) +"] [" + returnTimer + "] [" + (me.GetEnabled() ? "Enabled" : "Disabled") + "]" : "", 2.0f, false, vec4(color, trans), vec3(0, 0.5f, 0));
    
    color = vec3(params.GetFloat("red"), params.GetFloat("green"), params.GetFloat("blue"));

    if(weaponId == -1){
        // FOR SOME FRICKIN REASON
        // Dropping the flag just crashes the game if done pretty close to loading the json
        if(unlockTimer < timeToUnlock){
            flagState = FlagTaken;
            unlockTimer += time_step;
            return;
        }
        
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

    Object@ weapObj = ReadObjectFromID(weaponId);
    ItemObject@ weap = ReadItemID(weaponId);
    weapObj.SetTint(color);

    // Move the light
    if(lightId != -1){
        Object@ obj = ReadObjectFromID(lightId);
        mat4 transform = weap.GetPhysicsTransform();
        mat4 rot = transform.GetRotationPart();
        obj.SetTranslationRotationFast((transform*vec3())+(vec3(0, 0.5f, 0)), obj.GetRotation());
        obj.SetRotation(QuaternionFromMat4(rot));
        obj.SetTint(color/2);
    }
    
    if(!weap.IsHeld()){
        if(justReleased){
            justReleased = false;
            // Recreate the flag and move it (moving itemObject is scuffed) to make it upright
            mat4 transform = weap.GetPhysicsTransform();
            //ReCreateFlagItem();
            weapObj.SetTranslation(transform * vec3() - vec3(0, 0.3f, 0 ));
            flagState = FlagDropped;

            debuffed = true;
        }
        if(flagState == FlagDropped){
            // Doing a "future" check to make sure we dont show -1;
            if(params.HasParam("returnCooldown"))
                returnCooldown = params.GetFloat("returnCooldown");
            
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
    else {
        flagState = FlagTaken;

        debuffed = false;
        
        returnTimer = 0;

        // Guards from accidental returning when just taken
        if(manualReturnBlockTimer < manualReturnBlockCooldown){
            manualReturnBlockTimer += time_step;
        }
        
        justReleased = true;
    }

    params.SetInt("flagState", int(flagState));
    DebuffCheck();
}

void Dispose(){
    unlockTimer = 0;
    FlagDispose();
}
bool debuffed = false;
void DebuffCheck(){
    if(weaponId == -1)
        return;
    
    ItemObject@ weap = ReadItemID(weaponId);
    if(params.HasParam("debuffCarrier")){
        float debuffMlt = params.GetFloat("debuffCarrier");
        if(debuffMlt < 1 && holder_id == -1 && !debuffed){
            holder_id = weap.HeldByWhom();
            if(holder_id == -1)
                return;
            
            MovementObject@ char = ReadCharacterID(holder_id);
            Object@ charObj = ReadObjectFromID(char.GetID());
            ScriptParams@ charParams = charObj.GetScriptParams();

            int holderTeamNr = parseInt(charParams.GetString("Teams").substr(12));
            if(holderTeamNr == params.GetInt("teamId")){
                // same team, ignore debuffing
                return;
            }

            charParams.SetFloat("Movement Speed", charParams.GetFloat("Movement Speed") * debuffMlt);
            charParams.SetFloat("Jump - Initial Velocity", charParams.GetFloat("Jump - Initial Velocity") * debuffMlt);

            charObj.UpdateScriptParams();
            Log(error, "Enabled debuff: " + debuffMlt + " for: " + holder_id);
        }
        else if(debuffMlt < 1 && debuffed){
            if(holder_id == -1)
                return;
            
            MovementObject@ char = ReadCharacterID(holder_id);
            Object@ charObj = ReadObjectFromID(char.GetID());
            ScriptParams@ charParams = charObj.GetScriptParams();

            int holderTeamNr = parseInt(charParams.GetString("Teams").substr(12));
            if(holderTeamNr == params.GetInt("teamId")){
                // same team, ignore buffing back
                return;
            }

            charParams.SetFloat("Movement Speed", charParams.GetFloat("Movement Speed") * (1/debuffMlt));
            charParams.SetFloat("Jump - Initial Velocity", charParams.GetFloat("Jump - Initial Velocity") * (1/debuffMlt));

            charObj.UpdateScriptParams();
            Log(error, "Disabled debuff: " + debuffMlt + " for: " + holder_id);
            holder_id = -1;
        }
    }
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

bool AcceptConnectionsFrom(Object@ other) {
    ScriptParams @objParams = other.GetScriptParams();
    if(objParams.HasParam("type")) {
        string
        type = objParams.GetString("type");
        if (type == "flagReturnHotspot")
            return true;
    }
    return false;
}

bool AcceptConnectionsTo(Object@ other) {
    return false;
}

bool ConnectTo(Object@ other)
{
    return false;
}