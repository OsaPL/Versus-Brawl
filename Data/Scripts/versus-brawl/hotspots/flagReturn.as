#include "hotspots/placeholderFollower.as"

vec3 color = vec3(0, 0.7f, 0);
string flagManualReturnSound = "Data/Sounds/sword/hard_drop_1.wav";
string billboardPath = "Data/Textures/ui/versusBrawl/return_icon.png";
int deleteFlag = -1;

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

void HandleEvent(string event, MovementObject @mo)
{
    if (event == "enter") {
        if (mo.is_player) {
            Log(error, "entered!");
            
            int weapon = mo.GetArrayIntVar("weapon_slots",mo.GetIntVar("primary_weapon_slot"));
            ItemObject@ obj = ReadItemID(weapon);
            string label = obj.GetLabel();
            
            if(label == "flag"){
                ScriptParams @objParams = obj.GetScriptParams();
                int flagTeamId = objParams.GetInt("teamId");
                
                if(flagTeamId == params.GetInt("teamId")){
                    PlaySound(flagManualReturnSound);
                    deleteFlag = weapon;
                }
            }
        }
    }
}


void Update(){
    Object@ me = ReadObjectFromID(hotspot.GetID());
    
    PlaceHolderFollowerUpdate(billboardPath, "["+params.GetInt("teamId")+"] [" + (me.GetEnabled() ? "Enabled" : "Disabled") + "]", 2.0f, false, vec4(color, 1), vec3(0, 0.5f, 0));
    
    color = vec3(params.GetFloat("red"), params.GetFloat("green"), params.GetFloat("blue"));
    
    DebugDrawBillboard(billboardPath,
        me.GetTranslation() + vec3(0, 0.5f, 0),
    2.0f,
        vec4(color,1),
        _delete_on_update);

    if(deleteFlag != -1){
        DeleteObjectID(deleteFlag);
        deleteFlag = -1;
    }
}


