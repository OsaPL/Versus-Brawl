#include "hotspots/placeholderFollower.as"

string billboardPath = "Data/Textures/ui/versusBrawl/phase_icon.png";
bool switched = true;

void Init(){
    Object@ me = ReadObjectFromID(hotspot.GetID());
    me.SetScale(vec3(0.4f));
    
    // TODO: On reset message, call Reset()?
}

void SetParameters()
{
    params.AddString("type", "nidhoggPhaseHotspot");
    params.AddIntSlider("phase", 0, "min:-10.0,max:10.0");
}

void HandleEvent(string event, MovementObject @mo)
{
    if (event == "enter") {
        if (mo.is_player) {
            //TODO! check for current phase in levelparams and if ok, pass to next one4
            //TODO: If phase==0 hotspot if triggered, give the player trigg ering it Attacking? 
        }
    }
}

void Update(){
    Object@ me = ReadObjectFromID(hotspot.GetID());
    int phase = params.GetInt("phase");
    vec3 color = GetTeamUIColor(2);
    if(phase > 0)
        color = GetTeamUIColor(0);
    if(phase < 0)
        color = GetTeamUIColor(1);

    PlaceHolderFollowerUpdate(billboardPath, "[" + params.GetInt("phase") + "]", 2.0f, false, vec4(color, 1));

    if(!EditorModeActive())
        DebugDrawBillboard(billboardPath,
            me.GetTranslation(),
    2.0f,
        vec4(color,1),
        _delete_on_update);
}

void Reset(){
    switched = false;
}

// TODO: this is already in colorHelper
vec3 GetTeamUIColor(int playerNr){
    switch (playerNr) {
        case 0:
            //Green
            return vec3(0.0f,0.8f,0.0f);
        case 1:
            //Red
            return vec3(0.8f,0.0f,0.0f);
        case 2:
            //Blue
            return vec3(0.1f,0.1f,0.8f);
        case 3:
            //Yellow
            return vec3(0.9f,0.9f,0.1f);
        default: DisplayError("RandReasonableTeamColor", "Unsuported RandReasonableTeamColor value of: " + playerNr);
            //Purple guy?
            return vec3(1.0f,0.0f,1.0f);
    }
    return vec3(1.0f);
}

//TODO! All connected objects should get "switched", do the same thing as in waterphase and checkpoint, maybe even create a separate script for "switching" objects?
bool AcceptConnectionsFrom(Object@ other) {
    return false;
}

bool AcceptConnectionsTo(Object@ other) {
    return true;
}

bool ConnectTo(Object@ other)
{
    return true;
}

bool Disconnect(Object@ other)
{
    return true;
}
