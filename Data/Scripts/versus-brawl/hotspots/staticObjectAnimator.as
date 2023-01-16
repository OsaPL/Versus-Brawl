#include "versus-brawl/utilityStuff/fileChecks.as"
#include "hotspots/placeholderFollower.as"
#include "versus-brawl/save_load.as"

class AnimationFrame{
    float frameTime;
    int objectIndex;
}

class Animation{
    string animName;
    bool repeat;
    array<AnimationFrame@> animFrames;

    Animation(){
        animFrames = {};
        repeat = true;
    }
}

class Config{
    array<string> objectPaths = {};
    array<Animation@> animations = {};

    Config(){
        objectPaths = {};
        animations = {};
    }
}

void LoadConfig(string path){
    //TODO: Load json here
    JSON jsonFile;
    jsonFile.parseFile(path);
    Log(error, "LoadConfig(" + path + "): " + jsonFile.writeString());

    JSONValue root;

    root = jsonFile.getRoot();

    Log(error, "LoadConfig loaded: " + join(root.getMemberNames(),","));
    
    // Extract config
    cfg.objectPaths = {};
    cfg.animations = {};
    if(FoundMember(root, "objectPaths")) {
        JSONValue objectPaths = root["objectPaths"];
        for (uint i = 0; i < objectPaths.size(); i++) {
            cfg.objectPaths.push_back(objectPaths[i].asString());
            Log(error, "LoadConfig objectPaths["+i+"]: " + cfg.objectPaths[cfg.objectPaths.size()-1]);
        }
    }

    if(FoundMember(root, "animations")) {
        JSONValue animations = root["animations"];
        for (uint i = 0; i < animations.size(); i++) {
            Animation animToAdd();
            JSONValue loadedAnim = animations[i];
            
            if(FoundMember(loadedAnim, "animName")) {
                animToAdd.animName = loadedAnim["animName"].asString();
                Log(error, "LoadConfig animations["+i+"].animName: " + animToAdd.animName);
            }
            if(FoundMember(loadedAnim, "repeat")) {
                animToAdd.repeat = loadedAnim["repeat"].asBool();
                Log(error, "LoadConfig animations["+i+"].repeat: " + animToAdd.repeat);
            }

            if(FoundMember(loadedAnim, "animFrames")) {
                JSONValue animFrames = animations[i]["animFrames"];
                for (uint j = 0; j < animFrames.size(); j++) {
                    AnimationFrame frameToAdd();
                    JSONValue loadedFrame = animFrames[j];
                    
                    if(FoundMember(loadedFrame, "frameTime")) {
                        frameToAdd.frameTime = loadedFrame["frameTime"].asFloat();
                        Log(error, "LoadConfig animations["+i+"].frames["+j+"].frameTime: " + frameToAdd.frameTime);
                        Log(error, "" + loadedFrame["frameTime"].asFloat());
                    }
                    if(FoundMember(loadedFrame, "objectIndex")) {
                        frameToAdd.objectIndex = loadedFrame["objectIndex"].asInt();
                        Log(error, "LoadConfig animations["+i+"].frames["+j+"].objectIndex: " + frameToAdd.objectIndex);
                        Log(error, "" + loadedFrame["objectIndex"].asInt());
                    }

                    animToAdd.animFrames.push_back(frameToAdd);
                }
            }
            
            cfg.animations.push_back(animToAdd);
        }
    }
    
}

string billboardPath = "Data/Textures/ui/versusBrawl/phase_icon.png";

Config cfg;
array<int> objectIds = {};
float time = 0;
float timeSinceLastFrame = 0;
string currentAnim;
int currentFrame;
bool justStarted = true;

string lastConfigPath;
vec3 lastTranslation;
quaternion lastRotation;
vec3 lastScale;

void PrepareObjects(){
    for (uint i = 0; i < cfg.objectPaths.size(); i++) {
        // Spawn all in
        int createdObjectId = CreateObject(cfg.objectPaths[i]);
        if(createdObjectId != -1){
            Object@ createdObject = ReadObjectFromID(createdObjectId);
            // and disable them
            createdObject.SetEnabled(false);
            objectIds.push_back(createdObjectId);
            TransferTransform(createdObjectId);
        }
    }
}

void RefreshTransform(){
    Object@ me = ReadObjectFromID(hotspot.GetID());

    lastTranslation = me.GetTranslation();
    lastRotation = me.GetRotation();
    lastScale = me.GetScale();
}

// TODO: haha lovely name
void TransferTransform(int objectId){
    Object@ me = ReadObjectFromID(hotspot.GetID());
    Object@ createdObject = ReadObjectFromID(objectId);
    
    createdObject.SetTranslation(me.GetTranslation());
    createdObject.SetRotation(me.GetRotation());
    createdObject.SetScale(me.GetScale());
}

void Cleanup(){
    for (uint i = 0; i < objectIds.size(); i++) {
        QueueDeleteObjectID(objectIds[i]);
    }
    objectIds = {};
    currentFrame = 0;
    justStarted = true;
}

void Animate(){
    if(currentAnim != params.GetString("currentAnim")){
        currentAnim = params.GetString("currentAnim");
        currentFrame = 0;
    }

    int animId = -1;
    for (uint i = 0; i < cfg.animations.size(); i++) {
        if(cfg.animations[i].animName == currentAnim){
            animId = i;
            break;
        }
    }
    if(animId == -1){
        //TODO: didnt find anim
        Log(error, "animId: " + animId + " not found!");
        return;
    }
    Animation@ anim = cfg.animations[animId];
    // Log(error, "animations.size(): " + cfg.animations.size());
    
    // Reset to the first frame
    
    if(currentFrame  >= int(anim.animFrames.size())){
        if(anim.repeat || params.GetInt("forceRepeat") != 0){
            currentFrame = 0;
        }
        else{
            Log(error, "Skipping frame");
            return;
        }
    }
    //Log(error, "animFrames.size(): " + anim.animFrames.size());

    AnimationFrame@ currentAnimFrame = anim.animFrames[currentFrame];

    int nextFrameId = -1;
    if(currentFrame+1 >= int(anim.animFrames.size())){
        // if were at at last get first
        nextFrameId = 0;
    }
    else{
        nextFrameId = currentFrame+1;
    }
    AnimationFrame@ nextAnimFrame = anim.animFrames[nextFrameId];
    //Log(error, "nextFrameId: " + nextFrameId + " currentFrame: " + currentFrame);

    //Log(error, "animFrame.frameTime: " + animFrame.frameTime + " timeSinceLastFrame: " + timeSinceLastFrame);
    
    if(justStarted){
        Object@ currentObj = ReadObjectFromID(objectIds[currentAnimFrame.objectIndex]);
        Log(error, "currentObj: " + currentObj.GetID());
        currentObj.SetEnabled(true);
        justStarted = false;
    }
    else if(currentAnimFrame.frameTime <= timeSinceLastFrame){
        Log(error, "nextFrameId: " + nextFrameId + " currentFrame: " + currentFrame);
        timeSinceLastFrame = 0;

        int lastObjId = -1;
        // Disable previous frame

        Object@ currentObj = ReadObjectFromID(objectIds[currentAnimFrame.objectIndex]);
        //Log(error, "currentObj: " + currentObj.GetID());
        currentObj.SetEnabled(false);
        
        // Enable next 
        Object@ nextObj = ReadObjectFromID(objectIds[nextAnimFrame.objectIndex]);
        //Log(error, "nextObjId: " + nextObj.GetID());
        nextObj.SetEnabled(true);
        
        currentFrame++;
    }
    else{
        timeSinceLastFrame += time_step * params.GetFloat("speed");
    }
}

void Init(){
    Object@ me = ReadObjectFromID(hotspot.GetID());
    RefreshTransform();
}

void SetParameters(){
    params.AddString("configPath", "");
    params.AddString("currentAnim", "");
    params.AddIntCheckbox("paused", true);
    params.AddIntCheckbox("forceRepeat", false);
    params.AddFloatSlider("speed", 1.0,"min:0,max:2,step:0.1,text_mult:1");
}

void Update(){
    Object@ me = ReadObjectFromID(hotspot.GetID());

    string label = "[" + (me.GetEnabled() ? "Enabled" : "Disabled") + "] [" + params.GetString("currentAnim") + "] [" + currentFrame + "] [" + params.GetFloat("speed") + "x]";
    PlaceHolderFollowerUpdate(billboardPath, label);
    
    if(!me.GetEnabled()){
        Cleanup();
        lastConfigPath = "";
        return;
    }
    
    if(lastConfigPath != params.GetString("configPath")){
        lastConfigPath = params.GetString("configPath");
        Log(error, "Config reloaded! lastConfigPath: " + lastConfigPath + " params.GetString(\"configPath\"): " + params.GetString("configPath"));
        if(!FileExistsWithType(lastConfigPath, ".json")){
            return;
        }
        Cleanup();
        LoadConfig(lastConfigPath);
        PrepareObjects();
    }
    // If any of the Transform values changed, update
    if(lastTranslation != me.GetTranslation() || lastRotation != me.GetRotation() || lastScale != me.GetScale()){
        RefreshTransform();
        for (uint i = 0; i < objectIds.size(); i++)
        {
            TransferTransform(objectIds[i]);
        }
    }
    
    if(params.GetInt("paused") == 0){
        Animate();
    }
}

void Dispose(){
    Cleanup();
}

void PreScriptReload()
{
    Log(error, "PreScriptReload");
    lastConfigPath = "";
}