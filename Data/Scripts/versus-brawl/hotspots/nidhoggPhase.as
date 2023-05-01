#include "hotspots/placeholderFollower.as"

string billboardPath = "Data/Textures/ui/versusBrawl/phase_icon.png";
bool switched = true;

bool enableRed = false;
bool enableGreen = false;

int lastCurrentPhase = 0;
int lastAttacking = -1;
int shadowId = -1;

void Init(){
    
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
            int phase = params.GetInt("phase");
            if(phase == 0)
                return;
            
            ScriptParams@ lvlParams = level.GetScriptParams();
            if(lvlParams.HasParam("OpenPhase")){
                int openPhase = lvlParams.GetInt("OpenPhase");
                if(openPhase == phase) {
                    Log(error, "sent phaseChange " + mo.GetID());
                    level.SendMessage("phaseChange " + mo.GetID());
                }
            }

            //TODO: If phase==0 hotspot if triggered, give the player triggering it Attacking? 
        }
    }
    else if(event == "exit") {
        if (mo.is_player) {
            mo.Execute("WaterExit(" + hotspot.GetID() + ");");
        }
    }
}

void Update(){
    Object@ me = ReadObjectFromID(hotspot.GetID());
    int phase = params.GetInt("phase");

    ScriptParams@ lvlParams = level.GetScriptParams();
    int openPhase = 0;
    int attacking = 2;
    if(lvlParams.HasParam("OpenPhase")) {
        openPhase = lvlParams.GetInt("OpenPhase");
    }
    if(lvlParams.HasParam("Attacking")) {
        attacking = lvlParams.GetInt("Attacking");
    }
    
    vec3 color = GetTeamUIColor(2);
    if(phase > 0)
        color = GetTeamUIColor(0);
    if(phase < 0)
        color = GetTeamUIColor(1);
    if(phase == openPhase && openPhase != 0)
        color = GetTeamUIColor(-1);

    // State management
    ManageSpawnsAndObjects();

    string label = "[" + params.GetInt("phase") + "] [Spawns: " + (enableRed ? "RED" : "") + (enableGreen ? "GREEN" : "") + "] [" + (phase == openPhase ? "OPEN" : "CLOSED") + "]";
    if(phase == 0){
        label = "";
    }
    PlaceHolderFollowerUpdate(billboardPath, EditorModeActive() ? label : "", 2.0f, EditorModeActive(), vec4(color, 1));

    if(!EditorModeActive())
        DebugDrawBillboard(
            billboardPath,
            me.GetTranslation(),
            2.0f,
            vec4(color,1),
            _delete_on_update);

    if(phase != 0){
        if(phase == openPhase && emitterId == -1){
            shadowId = CreateObject("Data/Objects/Decals/env_blob_shadow.xml");
            Object@ shadowObj = ReadObjectFromID(shadowId);
            shadowObj.SetScale(me.GetScale() * 6);
            shadowObj.SetTranslation(me.GetTranslation());
            shadowObj.SetRotation(me.GetRotation());
            shadowObj.SetTint(vec3(0.1f));
            
            vec3 attackColor = GetTeamUIColor(attacking);
            emitterId = CreateObject("Data/Objects/powerups/objectFollowerEmitter.xml");
            Object@ obj = ReadObjectFromID(emitterId);
            obj.SetScale(me.GetScale());

            // TODO: These should be probably exposed
            ScriptParams@ objParams = obj.GetScriptParams();
            objParams.SetInt("objectIdToFollow", hotspot.GetID());
            objParams.SetString("pathToParticles", "Data/Particles/versus-brawl/stone_sparks.xml");
            objParams.SetFloat("particleDelay", 0.002);
            objParams.SetFloat("particleColorR", attackColor.x);
            objParams.SetFloat("particleColorG", attackColor.y);
            objParams.SetFloat("particleColorB", attackColor.z);
            obj.UpdateScriptParams();
        }
        else if(phase != openPhase && emitterId != -1){
            QueueDeleteObjectID(emitterId);
            emitterId = -1;
            QueueDeleteObjectID(shadowId);
            shadowId = -1;
        }
    }
}

void Reset(){
    switched = false;
}

void ChangeObjectsState(bool state){
    for (uint i = 0; i < otherObjects.size(); i++)
    {
        //Log(error, "Changing " + otherObjects[i] + " to: " + state);
        Object@ obj = ReadObjectFromID(otherObjects[i]);
        obj.SetEnabled(state);
    }
}

void ChangeSpawnState(bool state, bool isGreen){
    if(isGreen)
    {
        for (uint i = 0; i < greenSpawns.size(); i++)
        {
            //Log(error, "Changing " + otherObjects[i] + " to: " + state);
            Object@ obj = ReadObjectFromID(greenSpawns[i]);
            obj.SetEnabled(state);
        }
    }
    else{
        for (uint i = 0; i < redSpawns.size(); i++)
        {
            //Log(error, "Changing " + otherObjects[i] + " to: " + state);
            Object@ obj = ReadObjectFromID(redSpawns[i]);
            obj.SetEnabled(state);
        } 
    }

}
array<int> otherObjects = {};
array<int> greenSpawns = {};
array<int> redSpawns = {};
int lastAllOpen = -1;
int emitterId = -1;

void ManageSpawnsAndObjects(){
    int phase = params.GetInt("phase");
    ScriptParams@ lvlParams = level.GetScriptParams();
    int currentPhase = 0;
    int attacker = 2;
    int openPhase = 0;
    int allOpen = 0;
    if(lvlParams.HasParam("CurrentPhase")){
        currentPhase = lvlParams.GetInt("CurrentPhase");
    }
    if(lvlParams.HasParam("Attacking")){
        attacker = lvlParams.GetInt("Attacking");
    }
    if(lvlParams.HasParam("OpenPhase")){
        openPhase = lvlParams.GetInt("OpenPhase");
    }
    if(lvlParams.HasParam("AllOpen")){
        allOpen = lvlParams.GetInt("AllOpen");
    }
    
    if(lastCurrentPhase != currentPhase || lastAttacking != attacker){
        lastCurrentPhase = currentPhase;
        lastAttacking = attacker;
        
        // TODO! This is copy pasta
        array<int> connectedObjs = hotspot.GetConnectedObjects();
        greenSpawns = {};
        redSpawns = {};
        otherObjects = {};
        for (uint i = 0; i < connectedObjs.size(); i++) {
            Object@ obj = ReadObjectFromID(connectedObjs[i]);
            ScriptParams @objParams = obj.GetScriptParams();
            if(objParams.HasParam("type")) {
                string type = objParams.GetString("type");
                if (type == "playerSpawnHotspot")
                {
                    int team = objParams.GetInt("playerNr");
                    if(team == 0){
                        greenSpawns.push_back(connectedObjs[i]);
                    }
                    else if(team == 1){
                        redSpawns.push_back(connectedObjs[i]);
                    }
                }
            }
            else{
                otherObjects.push_back(connectedObjs[i]);
            }
        }
    
        // Decide what spawn should be on/off
        enableGreen = false;
        enableRed = false;
        if(currentPhase == 0){
            if(phase == -1){
                enableRed = true;
            }
            else if(phase == 1){
                enableGreen = true;
            }
        }
        else if(attacker == 0){
            if(currentPhase == phase){
                enableGreen = true;
            }
            else if(openPhase == phase){
                enableRed = true;
            }
        }
        else if (attacker == 1){
            if(currentPhase == phase){
                enableRed = true;
            }
            else if(openPhase == phase){
                enableGreen = true;
            }
        }
        else if (attacker == 2){
            if(CalculateChangePhase(currentPhase, -1) == phase){
                enableRed = true;
            }
            else if(CalculateChangePhase(currentPhase, 1) == phase){
                enableGreen = true;
            }
        }
        
        // Enable/disable spawns
        ChangeSpawnState(enableGreen, true);
        ChangeSpawnState(enableRed, false);

        // Switch object depending on the openPhase
        ChangeObjectsState(!(openPhase == phase || currentPhase == phase));
        
        if(phase == CalculateChangePhase(currentPhase, 1) && attacker == 0){
            Log(error, "sending killStraglers " + hotspot.GetID() + " phase: " + phase);
            level.SendMessage("killStraglers " + hotspot.GetID());
        }
        else if(phase == CalculateChangePhase(currentPhase, -1) && attacker == 1){
            Log(error, "sending killStraglers " + hotspot.GetID() + " phase: " + phase);
            level.SendMessage("killStraglers " + hotspot.GetID());
        }
    }

    if(lastAllOpen != allOpen){
        //Log(error, "lastAllOpen: " + lastAllOpen + " allOpen: " + allOpen);
        lastAllOpen = allOpen;
        if(allOpen > 0){
            ChangeObjectsState(false);
        }
        else{
            ChangeObjectsState(true);
        }
    }
}

// TODO: this is already in nidhoggGamemode
int CalculateChangePhase(int value, int step){
    int plus = (step > 0 ? 1 : -1);
    if(value + step == 0)
        return value + step + plus;
    return value + step;
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
        default: //DisplayError("RandReasonableTeamColor", "Unsuported RandReasonableTeamColor value of: " + playerNr);
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
