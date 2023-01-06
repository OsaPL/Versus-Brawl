#include "hotspots/placeholderFollower.as"

vec3 color = vec3(0);
string billboardPath = "Data/Textures/ui/versusBrawl/return_icon.png";
int parentFlagHotspotId = -1;

void Init(){
    Object@ me = ReadObjectFromID(hotspot.GetID());
    me.SetScale(vec3(0.2f));
}

void SetParameters()
{
    params.AddString("type", "flagReturnHotspot");
}

void HandleEvent(string event, MovementObject @mo)
{
    if (event == "enter") {
        if (mo.is_player && parentFlagHotspotId != -1) {
            int weapon = mo.GetArrayIntVar("weapon_slots",mo.GetIntVar("primary_weapon_slot"));
            if(weapon == -1)
                return;
            ItemObject @obj = ReadItemID(weapon);
            string label = obj.GetLabel();

            if (label == "flag") {
                Object @parentObj = ReadObjectFromID(parentFlagHotspotId);
                parentObj.ReceiveScriptMessage("flagReturn " + weapon + " " + true);
                //Log(error, "flag entered! parentFlagHotspotId: " + parentFlagHotspotId);
            }
            
        }
    }
}


void Update(){
    Object@ me = ReadObjectFromID(hotspot.GetID());
    
    if(parentFlagHotspotId != -1){
        Object@ obj = ReadObjectFromID(parentFlagHotspotId);
        ScriptParams@ objParams = obj.GetScriptParams();

        color = vec3(objParams.GetFloat("red"), objParams.GetFloat("green"), objParams.GetFloat("blue"));
    }
    else{
        color = vec3();
    }

    PlaceHolderFollowerUpdate(billboardPath, "[" + (parentFlagHotspotId != -1 ? "Connected" : "Not Connected") + "]", 2.0f, false, vec4(color, 1), vec3(0, 0.5f, 0));

    if(!EditorModeActive())
        DebugDrawBillboard(billboardPath,
            me.GetTranslation() + vec3(0, 0.5f, 0),
        2.0f,
            vec4(color,1),
            _delete_on_update);
}

bool AcceptConnectionsFrom(Object@ other) {
    return false;
}

bool AcceptConnectionsTo(Object@ other) {
    ScriptParams @objParams = other.GetScriptParams();
    if(objParams.HasParam("type")) {
        string type = objParams.GetString("type");
        if (type == "flagHotspot")
            return true;
    }
    return false;
}

bool ConnectTo(Object@ other)
{
    parentFlagHotspotId = other.GetID();
    return true;
}

bool Disconnect(Object@ other)
{
    parentFlagHotspotId = -1;
    return true;
}
