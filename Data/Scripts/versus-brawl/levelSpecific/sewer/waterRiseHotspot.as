#include "hotspots/placeholderFollower.as"

// TODO! Add support for Reset!

float bobbingMlt = 800;
float defaultStep = 0.003f;
float phaseChangeTime = 10;
// This will change whether phase changes to 0 after last one, or should it reverse the order (true: 0->1->2(last)->0->1->2(last)->0... or false: 0->1->2(last)->1->0(first)->1...)
bool loop = true;
//Defines how we move in phases array
bool startPhaseDirectionForward = false;
float addDelay = 0;

uint currentPhase = 0;
uint previousPhase = 0;
bool phaseDirectionForward = false;
bool rising = false;
float step;
float time = 0;
float bobbingTime = 0;
float soundTimer=0;
float phaseHeight;
float startingPhaseHeight;
array<int> objectsToMove;
array<int> savedConnectedObjectIds;
array<vec3> savedConnectedObjectStartPositions;
bool exitedEditorMode = false;
// Phases hotspot IDs
array<int> phases;
bool init = true;
//Defines how we move in physical space
bool movementDirectionForward = true;

void Init() {
    hotspot.SetCollisionEnabled(false);
    Object@ me = ReadObjectFromID(hotspot.GetID());
    me.SetScale(vec3(0.5f));
}

void SetParameters() {
    params.AddFloatSlider("Rise Speed", 0.005f, "min:0.0,max:3.0,step:0.01");
    params.AddFloatSlider("Bobbing Multiplier", 800, "min:200.0,max:1800.0");
    params.AddFloatSlider("Phase Change Time", 2.0f, "min:0.0,max:360.0,step:0.1");
    params.AddIntCheckbox("Loop Phases", true);
    params.AddIntCheckbox("Phase Starting Direction Forward", true);
    params.AddFloatSlider("Delay Time", 0.0f, "min:0.0,max:9.8696,step:0.01"); // 2x PI is ~9.8696
    params.AddString("game_type", "versusBrawl");
}

void UpdateParameters(){
    defaultStep = params.GetFloat("Rise Speed");
    bobbingMlt = params.GetFloat("Bobbing Multiplier");
    phaseChangeTime = params.GetFloat("Phase Change Time");
    loop = params.GetInt("Loop Phases") != 0;
    startPhaseDirectionForward = params.GetInt("Phase Starting Direction Forward") != 0;
    addDelay = params.GetFloat("Delay Time");
}

void Update(){
    Object@ me = ReadObjectFromID(hotspot.GetID());
    string enabled = me.GetEnabled() ? "Enabled" : "Disabled";
    
    PlaceHolderFollowerUpdate("Data/UI/spawner/thumbs/Hotspot/water.png", "[WaterRise] CurrentPhase: [" +  currentPhase+ "] phaseHeight:[" + phaseHeight + "] [" + enabled + "]");
    
    UpdateParameters();
    
    if(init){
        bobbingTime = addDelay;
        phaseDirectionForward = startPhaseDirectionForward;
        init = false;
    }
    
    objectsToMove = {};
    // TODO: Limiting to ten is not really necessary
    phases = {-1,-1,-1,-1,-1,-1,-1,-1,-1,-1};
    
    // Get all WaterPhasesHotspots
    for (uint i = 0; i < savedConnectedObjectIds.size(); i++) {
        Object@ obj = ReadObjectFromID(savedConnectedObjectIds[i]);
        // Check if its a phase
        if(IsWaterPhase(obj)){
            ScriptParams@ objParams = obj.GetScriptParams();
            //Log(error, "Found" + obj.GetID() + "phase:" + objParams.GetInt("Phase"));
            phases[objParams.GetInt("Phase")] = obj.GetID();
        }
        else{
            objectsToMove.push_back(obj.GetID());
        }
    }
    
    // This helps mapping, since it stops and resets everything if disabled or in editor
    if(!me.GetEnabled() || EditorModeActive()){
        if(!exitedEditorMode){
            Reset();
            exitedEditorMode = true;
        }

        // Clearing savedConnectedObjectStartPositions helps with making changes to object placements
        savedConnectedObjectStartPositions = {};
        return;
    }

    // If we exited editormode, fill again savedConnectedObjectStartPositions
    if(exitedEditorMode){
        for (uint i = 0; i < savedConnectedObjectIds.size(); i++) {
            Object@ other = ReadObjectFromID(savedConnectedObjectIds[i]);
            savedConnectedObjectStartPositions.push_back(other.GetTranslation());
        }
        exitedEditorMode = false;
    }

    // Animate water and objects to bob around a little
    bobbingTime += time_step;
    AnimateBobbing();
    
    // There is something wrong with the setup, dont bother
    if(phases[previousPhase] == -1 || phases[currentPhase] == -1 )
        return;
    
    // TIme elapsed, go to next
    if(time>phaseChangeTime) {
        NextPhase();
        Log(error, "Rising to: " + currentPhase);
        rising = true;
        
        // If rising up, just enable next one right away
        
        time = 0;
        soundTimer = 1;

        Object@ startPhaseObj = ReadObjectFromID(phases[previousPhase]);
        float startPhasephaseHeight = startPhaseObj.GetTranslation().y;
        Object@ endPhasephaseObj = ReadObjectFromID(phases[currentPhase]);
        float endPhasephaseHeight = endPhasephaseObj.GetTranslation().y;
        
        if(startPhasephaseHeight > endPhasephaseHeight){
            step = defaultStep*-1;
            phaseHeight = abs(startPhasephaseHeight - endPhasephaseHeight);
            startingPhaseHeight = phaseHeight;
            movementDirectionForward = false;
        }
        else{
            step = defaultStep;
            phaseHeight = abs(endPhasephaseHeight - startPhasephaseHeight);
            startingPhaseHeight = phaseHeight;
            movementDirectionForward = true;
        }

        if(movementDirectionForward)
            SwitchConnected();
        
        Log(error, "startPhasephaseHeight: " + startPhasephaseHeight + " endPhasephaseHeight: " + endPhasephaseHeight + " step:" + step);
        Log(error, "phaseHeight: " + phaseHeight);
    }
    else {
        if(!rising)
            time += time_step;
        //Log(error, "time: " + time);
    }
    
    // Rising water logic
    if(rising){
        MoveObjects();
    }
}

void Dispose(){
}

bool AcceptConnectionsFrom(Object@ other) {
    return false;
}

bool AcceptConnectionsTo(Object@ other) {
    if(other.IsExcludedFromSave())
        return false;
    
    return true;
}

bool ConnectTo(Object@ other){
    // Put its initial state in
    ScriptParams@ objParams = other.GetScriptParams();
    if(objParams.HasParam("KeepDisabled")){
        other.SetEnabled(false);
        Log(error, "object:"+other.GetID() + " KeepDisabled");
    }
    else{
        Log(error, "object:"+other.GetID());
    }

    savedConnectedObjectIds.push_back(other.GetID());
    savedConnectedObjectStartPositions.push_back(other.GetTranslation());
    
    return true;
}

bool Disconnect(Object@ other)
{
    int removeIndex = -1;
    for (uint i = 0; i < savedConnectedObjectIds.size(); i++)
    {
        if(savedConnectedObjectIds[i] == other.GetID()){
            removeIndex = i;
        }
    }
    
    if(removeIndex != -1){
        savedConnectedObjectIds.removeAt(removeIndex);
        savedConnectedObjectStartPositions.removeAt(removeIndex);

        return true;
    }
    else{
        return false;
    }
}

void Reset(){
    time = 0;
    bobbingTime = addDelay;
    phaseDirectionForward = startPhaseDirectionForward;
    currentPhase = 0;
    previousPhase = 0;
    phaseHeight = 0;
    rising = false;
    ResetObjectsPos();
}

void ResetObjectsPos(){
    // If its too low, its probably been cleared
    if(savedConnectedObjectStartPositions.size() < savedConnectedObjectIds.size())
        return;
        
    for (uint i = 0; i < savedConnectedObjectIds.size(); i++) {
        Object@ obj = ReadObjectFromID(savedConnectedObjectIds[i]);
        vec3 original = savedConnectedObjectStartPositions[i];
        obj.SetTranslation(vec3(original.x, original.y, original.z));
    }
}

void AnimateBobbing(){
    //Log(error, "AnimateBobbing");
    for (uint i = 0; i < objectsToMove.size(); i++) {
        Object@ obj = ReadObjectFromID(objectsToMove[i]);
        vec3 original = obj.GetTranslation();
        //Log(error, "sin(bobbingTime): "+ sin(bobbingTime)/bobbingMlt);
        obj.SetTranslation(vec3(original.x, original.y+sin(bobbingTime)/bobbingMlt, original.z));
    }
}

void NextPhase(){
    int nextPhase = -1;
    previousPhase = currentPhase;
    
    Log(error, "NextPhase currentPhase: " + currentPhase);
    Log(error, "NextPhase phaseDirectionForward: " + phaseDirectionForward);

    // TODO: This is yucky
    if(phaseDirectionForward){
        Log(error, "phaseDirectionForward true");
        // Go forward
        for (uint i = currentPhase+1; i < phases.size(); i++)
        {
            if(phases[i] != -1){
                // Found the next PhaseHotspot
                Log(error, "found: " + phases[i]);
                nextPhase = i;
                break;
            }
        }
        
        // Didnt found next one
        if(nextPhase == -1){
            Log(error, "didnt find nextPhase");
            if(loop){
                nextPhase = 0;
            }
            else{
                // Revert direction
                Log(error, "reversing phaseDirectionForward");
                phaseDirectionForward = !phaseDirectionForward;
                NextPhase();
                return;
            }
        }
    }
    else{
        Log(error, "phaseDirectionForward false");
        // Go back
        for (int i = currentPhase-1; i >= 0; i--)
        {
            if(phases[i] != -1){
                // Found the next PhaseHotspot
                Log(error, "found: " + phases[i]);
                nextPhase = i;
                break;
            }
        }

        // Didnt found next one
        if(nextPhase == -1){
            Log(error, "didnt find nextPhase");
            if(loop){
                for (uint i = phases.size()-1; i >= 0; i--)
                {
                    if(phases[i] != -1){
                        // Found the next PhaseHotspot
                        Log(error, "found: " + phases[i]);
                        nextPhase = i;
                        break;
                    }
                }
            }
            else{
                // Revert direction
                currentPhase = 0;
                Log(error, "reversing phaseDirectionForward");
                phaseDirectionForward = !phaseDirectionForward;
                NextPhase();
                return;
            }
        }
    }
    currentPhase = nextPhase;
}

void MoveObjects(){
    // TODO! Use some kind of log function, to smooth this out
    
    if(phaseHeight > 0){
        soundTimer += time_step;
        if(soundTimer> 0.5f){
            soundTimer = 0;
            PlaySoundGroup("Data/Sounds/water_foley/small_waves.xml");
        }
        if(phaseHeight < step){
            Log(error, "phaseHeight than step smaller, fixing: step: " + step + " phaseHeight: " + phaseHeight);
            step = phaseHeight;
        }
        
        if(step > 0){
            phaseHeight -= step;
        }
        else{
            phaseHeight += step;
        }
            
        //Log(error, "phaseHeight left: " + phaseHeight);
        for (uint i = 0; i < objectsToMove.size(); i++) {
            Object@ obj = ReadObjectFromID(objectsToMove[i]);
            ScriptParams@ objParams = obj.GetScriptParams();
            
            if(objParams.HasParam("DontMove"))
                continue;
            
            vec3 original = obj.GetTranslation();
            obj.SetTranslation(vec3(original.x, original.y+step, original.z));
        }
    }
    else{
        Log(error, "rising ended");
        rising = false;
        // If rising down, enable after moving
        if(!movementDirectionForward)
            SwitchConnected();
    }
}

bool IsWaterPhase(Object@ obj){
    ScriptParams@ objParams = obj.GetScriptParams();
    if(objParams.HasParam("Phase") && objParams.HasParam("game_type")) {
        if (objParams.GetString("game_type") == "versusBrawl") {
            return true;
        }
    }
    return false;
}

// Should be called after currentPhase change, to switch connected to phase objects
void SwitchConnected(){
    Log(error, "SwitchConnected currentPhase: " + currentPhase + " previousPhase: "+previousPhase);
        if(phases[currentPhase] != -1) {
            Object@ phaseObj = ReadObjectFromID(phases[currentPhase]);

            phaseObj.ReceiveScriptMessage("switch");
            
            Log(error, "SwitchConnected phases[currentPhase]: "+ phases[currentPhase]);
        }

        if(phases[previousPhase] != -1) {
            Object@ phaseObj = ReadObjectFromID(phases[previousPhase]);
    
            phaseObj.ReceiveScriptMessage("switch");
    
            Log(error, "SwitchConnected phases[previousPhase]: "+ phases[previousPhase]);
        }
}