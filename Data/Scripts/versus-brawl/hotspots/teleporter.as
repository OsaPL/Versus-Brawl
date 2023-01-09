#include "timed_execution/timed_execution.as"
#include "timed_execution/level_event_job.as"

#include "hotspots/placeholderFollower.as"

vec3 color = vec3(0);
string okIconPath = "Data/Textures/ui/versusBrawl/teleporterOk.png";
string notOkIconPath = "Data/Textures/ui/versusBrawl/teleporterNotOk.png";
string notReadyIconPath = "Data/Textures/ui/versusBrawl/teleporterNotReady.png";
int parentId = -1;
float cooldown = 2;
float timer = cooldown;
TimedExecution teleportTimer;

void Init(){
    Object@ me = ReadObjectFromID(hotspot.GetID());
    me.SetScale(vec3(0.3f));

    teleportTimer.Add(LevelEventJob("teleport", function(_params){
        timer = cooldown;
        return true;
    }));
}

void SetParameters(){
    params.AddString("type", "teleporterHotspot");
    params.AddFloatSlider("red", 1.0f, "min:0,max:3,step:0.01");
    params.AddFloatSlider("green", 1.0f, "min:0,max:3,step:0.01");
    params.AddFloatSlider("blue", 1.0f, "min:0,max:3,step:0.01");
    params.AddFloatSlider("cooldown", 2.0f, "min:0,max:60,step:0.01");
    params.AddString("teleportSound", "Data/Sounds/sword/light_weapon_swoosh_1.wav");
    params.AddIntSlider("velocityTranslator", 1, "min:-1.0,max:1.0");
}

void HandleEvent(string event, MovementObject @mo){
    if (event == "enter") {
        if (mo.is_player && parentId != -1) {
            Teleport(mo.GetID());
        }
    }
}

void Update(){
    teleportTimer.Update();
    cooldown = params.GetFloat("cooldown");
    Object@ me = ReadObjectFromID(hotspot.GetID());
    string billboardPath = okIconPath;
    float trans = 1;
    
    if(parentId == -1){
        billboardPath = notOkIconPath;
    }
    else if(timer <= cooldown){
        if(timer - time_step > 0){
            // Still not ready
            timer -= time_step;
            billboardPath = notReadyIconPath;
            // We use some gradation for transparency
            if(!EditorModeActive())
                trans = abs((timer - cooldown) / cooldown);
        }
        else{
            timer = 0;
        }
    }

    color = vec3(params.GetFloat("red"), params.GetFloat("green"), params.GetFloat("blue"));

    if(!EditorModeActive())
        DebugDrawBillboard(billboardPath,
            me.GetTranslation() + vec3(0, 0.5f, 0),
        2.0f,
            vec4(color,trans),
            _delete_on_update);

    PlaceHolderFollowerUpdate(billboardPath, "[" + (parentId != -1 ? "Connected" : "Not Connected") + "] [" + timer + "]", 2.0f, true, vec4(color, trans), vec3(0, 0.5f, 0));
}

void ReceiveMessage(string msg)
{
    // this will receive messages aimed at this object
    teleportTimer.AddLevelEvent(msg);
}

bool AcceptConnectionsFrom(Object@ other) {
    return true;
}

bool AcceptConnectionsTo(Object@ other) {
    return true;
}

bool ConnectTo(Object@ other)
{
    parentId = other.GetID();
    ScriptParams @objParams = other.GetScriptParams();
    if(objParams.HasParam("type")) {
        string type = objParams.GetString("type");
        if (type == "teleporterHotspot"){
            // If another teleporter, just clone their settings
            params.SetFloat("red", objParams.GetFloat("red"));
            params.SetFloat("green", objParams.GetFloat("green"));
            params.SetFloat("blue", objParams.GetFloat("blue"));
            params.SetFloat("cooldown", objParams.GetFloat("cooldown"));
            params.SetString("teleportSound", objParams.GetString("teleportSound"));
            params.SetInt("velocityTranslator", objParams.GetInt("velocityTranslator"));
        }
    }
    return true;
}

bool Disconnect(Object@ other)
{
    parentId = -1;
    return true;
}

void Teleport(int charId)
{
    if (parentId == -1)
        return;

    if (timer > 0)
        return;

    timer = cooldown;

    PlaySound(params.GetString("teleportSound"));

    Object
    @me = ReadObjectFromID(hotspot.GetID());
    Object
    @destination = ReadObjectFromID(parentId);
    Object
    @char = ReadObjectFromID(charId);
    MovementObject
    @mo = ReadCharacterID(charId);

    vec3 vel = mo.velocity;
    bool side = CheckSide(charId, vel);
    mo.position = destination.GetTranslation();
    mo.velocity = 0;

    char.SetTranslation(destination.GetTranslation());
    vec4
    rot_vec4 = destination.GetRotationVec4();
    quaternion
    q(rot_vec4.x, rot_vec4.y, rot_vec4.z, rot_vec4.a);
    char.SetRotation(q);

    mo.Execute("SetCameraFromFacing();FixDiscontinuity();");

    // Send `teleport` to inform destination object
    destination.ReceiveScriptMessage("teleport");
    
    int velTranslator = params.GetInt("velocityTranslator");
    //-1 dont translate velocity on exit
    // 0 use one to one (no direction change)
    // 1 translate lenght onto direction directly, reversing if needed
    // missing 2 translate only using snap 90 degrees angles
    // missing 3 full galaxy brain translation of local origins
    if (velTranslator != -1) {
        vec3 dest;
        switch (velTranslator) {
            case 0:
                dest = vel;
                break;
            case 1: {
                vec3
                inputDir = normalize(me.GetRotation() * vec3(0, 0, 1));
                vec3
                outputDir = normalize(destination.GetRotation() * vec3(0, 0, 1));
                float
                len = length(vel);
                dest = len * outputDir;
                Log(error, "" + me.GetID() + " side: " + side);
                if(side)
                    dest *= -1;
                break;
            }
            case 2:
                break;
        }
        mo.velocity = dest;
    }
}

// Check on which side of the portal are you, false is opposite of the portal direction
// velocity helps with collisions that could occur a frame late
bool CheckSide(int charId, vec3 vel = vec3()){
    Object@ me = ReadObjectFromID(hotspot.GetID());
    MovementObject@ char = ReadCharacterID(charId);
    
    vec3 offset = me.GetTranslation() - (char.position - vel);
    float portalSide = dot(offset, normalize(me.GetRotation() * vec3(0, 0, 1)));

    // DebugDrawText(
    //     me.GetTranslation(),
    //     "" + (portalSide > 0),
    //     1.0f,
    //     true,
    //     _delete_on_update);
    
    return portalSide < 0;
}