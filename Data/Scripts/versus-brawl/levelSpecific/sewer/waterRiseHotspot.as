#include "hotspots/placeholderFollower.as"

float bobbingMlt = 800;
float defaultStep = 0.005f;
float phaseChangeTime = 10;

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
    AnimateBobbing();

    // TIme elapsed, go to next
    if(time>phaseChangeTime) {
        NextPhase();
        Log(error, "Rising to: " + currentPhase);
        rising = true;
        time = 0;
        soundTimer = 1;

        Object@ startPhaseObj = ReadObjectFromID(phases[previousPhase]);
        float startPhasephaseHeight = startPhaseObj.GetTranslation().y;
        Object@ endPhasephaseObj = ReadObjectFromID(phases[currentPhase]);
        float endPhasephaseHeight = endPhasephaseObj.GetTranslation().y;

        Log(error, "startPhasephaseHeight: " + startPhasephaseHeight + " endPhasephaseHeight: " + endPhasephaseHeight);
        
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
        //Log(error, "phaseHeight: " + phaseHeight);
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
    bobbingTime += time_step;
    //Log(error, "AnimateBobbing");
    for (uint i = 0; i < objectsToMove.size(); i++) {
        Object@ obj = ReadObjectFromID(objectsToMove[i]);
        vec3 original = obj.GetTranslation();
        //Log(error, "sin(bobbingTime): "+ sin(bobbingTime)/bobbingMlt);
        obj.SetTranslation(vec3(original.x, original.y+sin(bobbingTime)/bobbingMlt, original.z));
    }
}

void NextPhase(){
    previousPhase = currentPhase;
    currentPhase++;
    for (uint i = currentPhase; i < phases.size(); i++)
    {
        if(phases[currentPhase] != -1){
            // Found the next PhaseHotspot
            break;
        }
        currentPhase++;
    }
    // Did we went over?
    if(currentPhase >= phases.size() - 1){
        currentPhase = 0;
        // Go again from the start then
        for (uint i = currentPhase; i < phases.size(); i++)
        {
            if(phases[currentPhase] != -1){
                // Found the next PhaseHotspot
                break;
            }
            currentPhase++;
        }
    }
}

void MoveObjects(){
    // TODO! Use some kind of log function, to smooth this out
    
    if(phaseHeight > 0){
        soundTimer += time_step;
        if(soundTimer> 0.5f){
            soundTimer = 0;
            PlaySoundGroup("Data/Sounds/water_foley/small_waves.xml");
        }
        if(phaseHeight < step)
            step = phaseHeight;
        
        if(step > 0){
            phaseHeight -= step;
        }
        else{
            phaseHeight += step;
        }
            
        Log(error, "phaseHeight left: " + phaseHeight);
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