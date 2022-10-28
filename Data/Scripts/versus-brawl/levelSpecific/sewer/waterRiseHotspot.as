#include "hotspots/placeholderFollower.as"

float bobbingMlt = 800;
float defaultStep = 0.005f;
float phaseChangeTime = 12;
// This will change whether phase changes to 0 after last one, or should it reverse the order (true: 0->1->2(last)->0->1->2(last)->0... or false: 0->1->2(last)->1->0(first)->1...)
bool loop = false;

uint currentPhase = 0;
uint previousPhase = 0;
bool rising = false;
float step;
float time = 0;
float bobbingTime = 0;
float soundTimer=0;
float phaseHeight;
float startingPhaseHeight;
array<int> objectsToMove;
array<int> phases;
bool phaseDirectionForward = true;

void Init() {
    hotspot.SetCollisionEnabled(false);
    Object@ me = ReadObjectFromID(hotspot.GetID());
    me.SetScale(vec3(2, 0.1f, 2));
}

void SetParameters() {
    params.AddFloatSlider("RiseSpeed", 0.05f, "min:0.0,max:3.0");
    params.AddString("game_type", "versusBrawl");
}

void Update(){
    PlaceHolderFollowerUpdate();
    
    // Get hotspot and placeholder, and then setup
    Object@ placeholderObj = ReadObjectFromID(placeholderId);
    PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(placeholderObj);
    placeholder_object.SetBillboard("Data/UI/spawner/thumbs/Hotspot/water.png");

    placeholderObj.SetEditorLabel("[WaterRise] CurrentPhase: [" +  currentPhase+ "] phaseHeight:[" + phaseHeight + "]");
    
    array<int> connected_object_ids = hotspot.GetConnectedObjects();

    objectsToMove = {};
    // TODO: Limiting to ten is not really necessary
    phases = {hotspot.GetID(),-1,-1,-1,-1,-1,-1,-1,-1,-1};
    
    // Get all WaterPhasesHotspots
    for (uint i = 0; i < connected_object_ids.size(); i++) {
        Object@ obj = ReadObjectFromID(connected_object_ids[i]);

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
    
    Object@ me = ReadObjectFromID(hotspot.GetID());
    me.SetEditorLabel("[WaterRise]");
    
    if(!me.GetEnabled() || EditorModeActive()){
        time = 0;
        return;
    }

    // Animate water and objects to bob around a little
    bobbingTime += time_step;
    AnimateBobbing();
    
    // TIme elapsed, go to next
    if(time>phaseChangeTime) {
        previousPhase = currentPhase;
        NextPhase();
        Log(error, "Rising to: " + currentPhase);
        rising = true;
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
        }
        else{
            step = defaultStep;
            phaseHeight = abs(endPhasephaseHeight - startPhasephaseHeight);
            startingPhaseHeight = phaseHeight;
        }
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
    PlaceHolderFollowerDispose();
}

bool AcceptConnectionsFrom(Object@ other) {
    return true;
}

bool AcceptConnectionsTo(Object@ other) {
    return true;
}

bool ConnectTo(Object@ other){
    Log(error, "" + hotspot.GetID() + "connecting to:"+other.GetID());
    return true;
}

float calculateStep(int x){
    return log10(x) - 2;
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
    Log(error, "NextPhase currentPhase: " + currentPhase);
    Log(error, "NextPhase phaseDirectionForward: " + phaseDirectionForward);


    if(phaseDirectionForward){
        // Go forward

        for (uint i = currentPhase+1; i < phases.size(); i++)
        {
            if(phases[i] != -1){
                // Found the next PhaseHotspot
                nextPhase = i;
                break;
            }
        }
        
        // Didnt found next one
        if(nextPhase == -1){
            if(loop){
                nextPhase = 0;
            }
            else{
                // Revert direction
                phaseDirectionForward = !phaseDirectionForward;
                NextPhase();
                return;
            }
        }
    }
    else{
        // Go back
        for (int i = currentPhase-1; i >= 0; i--)
        {
            if(phases[i] != -1){
                // Found the next PhaseHotspot
                nextPhase = i;
                break;
            }
        }

        // Didnt found next one
        if(nextPhase == -1){
            if(loop){
                for (uint i = phases.size()-1; i >= 0; i--)
                {
                    if(phases[i] != -1){
                        // Found the next PhaseHotspot
                        nextPhase = i;
                        break;
                    }
                }
            }
            else{
                // Revert direction
                currentPhase = 0;
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
            vec3 original = obj.GetTranslation();
            obj.SetTranslation(vec3(original.x, original.y+step, original.z));
        }
    }
    else{
        Log(error, "rising ended");
        rising = false;
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