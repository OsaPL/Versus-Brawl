#include "hotspots/placeholderFollower.as"

vec3 color = vec3(1, 0.5f, 0.2f);
string billboardPath = "Data/Textures/ui/versusBrawl/platform_icon.png";
string boingPath = "Data/Sounds/versus-brawl/boing-2-44164.wav";
int lastCharObjId = -1;

void Init(){
}

void SetParameters()
{
    params.AddString("type", "charCatapultHotspot");
    params.AddFloatSlider("velocity", 15.0f,"min:0,max:100,step:0.01");
    params.AddFloatSlider("upwardsBoostScale", 0.0f,"min:0,max:1,step:0.01");
    params.AddIntCheckbox("reuseCharactersVelocity", false);
    params.AddIntCheckbox("ragdoll", false);
    params.AddIntCheckbox("trampolineMode", false);
    // Under this velocity the trampoline will ignore player
    params.AddFloatSlider("trampolineMinimalVelocityY", 0.2f, "min:0,max:2,step:0.001");
    // Applied when space is held
    params.AddFloatSlider("trampolineBoost", 10, "min:0,max:50,step:0.01");
}

void HandleEvent(string event, MovementObject @mo)
{
    if (event == "enter") {
        if (mo.is_player) {
            lastCharObjId = mo.GetID();
            Boost();
        }
    }
}

void Boost(){
    Object@ me = ReadObjectFromID(hotspot.GetID());
    MovementObject@ mo = ReadCharacterID(lastCharObjId);

    vec3 outputDir = normalize(me.GetRotation() * vec3(0, params.GetFloat("upwardsBoostScale"), 1));
    float newVel = params.GetFloat("velocity");
    if(params.GetInt("reuseCharactersVelocity") != 0){
        newVel += length(mo.velocity);
    }
    if(params.GetInt("trampolineMode") != 0){
        
        if(abs(mo.velocity.y) < params.GetFloat("trampolineMinimalVelocityY"))
            return;
        if(GetInputDown(mo.controller_id, "jump") && newVel < params.GetFloat("trampolineBoost")){
            newVel = params.GetFloat("trampolineBoost");
        }
            
        PlaySound(boingPath);
    }

    mo.velocity = newVel * outputDir;

    if(params.GetInt("ragdoll") != 0){
        ragdollNextFrame = true;
    }
}

bool ragdollNextFrame = false;

void Update(){
    Object@ me = ReadObjectFromID(hotspot.GetID());

    vec3 direction = me.GetRotation() * vec3(0,0,1) *0.2f;
    PlaceHolderFollowerUpdate(billboardPath, "", 2.0f, true, vec4(color, 1), direction);
    
    if(ragdollNextFrame && lastCharObjId != -1){
        MovementObject@ mo = ReadCharacterID(lastCharObjId);

        ragdollNextFrame = false;
        lastCharObjId = -1;
        
        mo.Execute("Ragdoll(_RGDL_LIMP);");
    }

    // if(!EditorModeActive())
    //     DebugDrawBillboard(billboardPath,
    //         me.GetTranslation() + vec3(0),
    //         2.0f,
    //         vec4(color,1),
    //         _delete_on_update);
}
