#include "timed_execution/timed_execution.as"
#include "timed_execution/char_death_job.as"
#include "timed_execution/level_event_job.as"

#include "hotspots/placeholderFollower.as"

// TODO! Make it so you can set paths in editor and make it spawn continuously 

string billboardPath = "Data/Textures/ui/versusBrawl/spawner.png";
vec3 color = vec3(1.0f, 0.3f, 0.1f);

TimedExecution npcTimer;

float timer = 0;

// Keeps track of already spawned things
array<int> spawnedCharacters = {};
array<int> staticCharacters = {};
array<int> spawnedWeapons = {};
array<int> spawnedBackWeap = {};
// Characters left to spawn
array<string> spawnQueue = {};

void SetParameters()
{
    params.AddString("type", "npcSpawnerHotspot");
    
    params.AddIntSlider("spawnLimit", 1,"min:1,max:5");
    params.AddIntSlider("characterLimit", 3,"min:1,max:15");
    params.AddIntCheckbox("respawnAutomatically", false);
    params.AddFloatSlider("respawnTimer", 15.0f,"min:0.5,max:300,step:0.01");
    params.AddIntCheckbox("pauseWhenEditor", true);
    params.AddIntCheckbox("noticeAllOnSpawn", false);
}

void Init(){
    npcTimer.Add(LevelEventJob("spawn", function(_params){
        spawnQueue.push_back(_params[1]+";"+_params[2]+";"+_params[3]);
        Log(error, "spawn handled: " + _params[1]+";"+_params[2]+";"+_params[3]);
        return true;
    }));
    npcTimer.Add(LevelEventJob("reset", function(_params){
        Cleanup();
        return true;
    }));
    npcTimer.Add(LevelEventJob("cleanup", function(_params){
        Cleanup();
        return true;
    }));
}

bool Spawn(string actorPath, string weaponPath, string backWeaponPath){
    Log(error, "Spawning: " + actorPath + " " + weaponPath + " " + backWeaponPath);
    if(spawnedCharacters.size() >= uint(params.GetInt("characterLimit"))){
        Log(error, "Too many characters!");
        return false;
    }
        
    Object@ me = ReadObjectFromID(hotspot.GetID());
    
    //Spawn actor
    int actorId = CreateObject(actorPath, true);
    Log(error, "actorId: " + actorId);
    Object@ obj = ReadObjectFromID(actorId);
    obj.SetTranslation(me.GetTranslation());
    obj.SetRotation(me.GetRotation());
    MovementObject@ mo = ReadCharacterID(actorId);
    
    // TODO! Do I want to leave this for mappers? Should they make sure teams are set correctly? What if they want some infighting?
    // Set teams to "attacker"
    ScriptParams @objParams = obj.GetScriptParams();
    objParams.SetString("Teams", "attacker");
        
    spawnedCharacters.push_back(actorId);
    
    //Spawn grip weapon
    if(weaponPath != "none"){
        int weapId = CreateObject(weaponPath, true);
        Object@ obj1 = ReadObjectFromID(weapId);
        obj1.SetTranslation(me.GetTranslation());
        obj1.SetRotation(me.GetRotation());
        
        mo.Execute("AttachWeapon(" + weapId + ");");
        spawnedWeapons.push_back(weapId);
    }
    else{
        spawnedWeapons.push_back(-1);
    }

    if(backWeaponPath != "none"){
        //Spawn backup weapon
        int backWeapId = CreateObject(backWeaponPath, true);
        Object@ obj2 = ReadObjectFromID(backWeapId);
        obj2.SetTranslation(me.GetTranslation());
        obj2.SetRotation(me.GetRotation());
        mo.Execute("AttachWeapon(" + backWeapId + ");");
    
        //Attach backup weapon
        ScriptParams@ charParams = obj.GetScriptParams();
        bool mirrored = false;
        if(charParams.HasParam("Left handed") && 
            charParams.GetInt("Left handed") != 0) {
            mirrored = true;
        }
        obj.AttachItem(obj2, _at_sheathe, mirrored);
        spawnedBackWeap.push_back(backWeapId);
    }
    else{
        spawnedBackWeap.push_back(-1);
    }

    return true;
}

void ReceiveMessage(string msg)
{
    Log(error, "msg: " + msg);
    // this will receive messages aimed at this object
    npcTimer.AddLevelEvent(msg);

    // this will receive level messages
    npcTimer.AddEvent(msg);
}

void Update()
{
    timer += time_step;
    
    Object@ me = ReadObjectFromID(hotspot.GetID());
    me.SetScale(vec3(0.4f));
    string name = me.GetName();
    
    // To allow gamemode to track the amount still ready to be spawned
    params.SetInt("currentQueue", spawnQueue.size());
    params.SetInt("currentCharacters", spawnedCharacters.size());

    // if(EditorModeActive()) {
        PlaceHolderFollowerUpdate(billboardPath, "[NpcSpawner] " + name + " [" + spawnQueue.size() + "] " 
        + "[" + spawnedCharacters.size() + "]"  , 1.5f, true, vec4(color, 1));
    //}

    if(!me.GetEnabled())
        return;
        
    if(timer > params.GetFloat("respawnTimer")){
        // Remove all already dead characters
        Log(error, "before spawnQueue:");
        for (uint i = 0; i < spawnQueue.size(); i++) {
            Log(error, "    " + spawnQueue[i]);
        }
        
        array<int> toRemove = {};
        for (uint i = 0; i < spawnedCharacters.size(); i++) {
            MovementObject @mo = ReadCharacterID(spawnedCharacters[i]);
            if(mo.GetIntVar("knocked_out") != _awake) {
                toRemove.push_back(i);
                
                if(spawnedCharacters[i] != -1)
                    // TODO! Do I really need to remove them? Check how performance heavy is leaving them as static
                    //DeleteObjectID(spawnedCharacters[i]);
                    staticCharacters.push_back(spawnedCharacters[i]);
                    mo.Execute("this_mo.static_char = true;");
                if(spawnedWeapons[i] != -1)
                    DeleteObjectID(spawnedWeapons[i]);
                if(spawnedBackWeap[i] != -1)
                    DeleteObjectID(spawnedBackWeap[i]);
            }
        }
        for (uint i = toRemove.size()-1; i <= 0; i--) {
            spawnedCharacters.removeAt(toRemove[i]);
            spawnedWeapons.removeAt(toRemove[i]);
            spawnedBackWeap.removeAt(toRemove[i]);
        }
    
        // Dequeue
        toRemove = {};
        int spawned = 0;
        for (uint i = 0; i < spawnQueue.size(); i++) {
            if(spawned >= params.GetInt("spawnLimit"))
                break;
            array<string> toSpawn = spawnQueue[i].split(";");
            if(Spawn(toSpawn[0],toSpawn[1],toSpawn[2])){
                toRemove.push_back(i);
                spawned++;
            }
        }
        
        Log(error, "toRemove:");
        for (uint i = 0; i < toRemove.size(); i++) {
            Log(error, "    " + toRemove[i]);
        }
        
        for (uint i = toRemove.size()-1; i >= 0; i--) {
            // TODO: For some reason this is a thing? Weird, since I dont think it should be able.
            if(toRemove.size() <= 0)
                break;
                
            spawnQueue.removeAt(toRemove[i]);
            Log(error, "removing: " + toRemove[i] );
        }
        
        Log(error, "after spawnQueue:");
        for (uint i = 0; i < spawnQueue.size(); i++) {
            Log(error, "    " + spawnQueue[i]);
        }
        timer = 0;
    }
    
    npcTimer.Update();
}

void Cleanup(){
    spawnQueue = {};
    for (uint i = 0; i < spawnedCharacters.size(); i++) {
        if(spawnedCharacters[i] != -1)
            DeleteObjectID(spawnedCharacters[i]);
    }
    spawnedCharacters = {};
    for (uint i = 0; i < spawnedWeapons.size(); i++) {
        if(spawnedWeapons[i] != -1)
            DeleteObjectID(spawnedWeapons[i]);
    }
    spawnedWeapons = {};
    for (uint i = 0; i < spawnedBackWeap.size(); i++) {
        if(spawnedBackWeap[i] != -1)
            DeleteObjectID(spawnedBackWeap[i]);
    }
    spawnedBackWeap = {};
    for (uint i = 0; i < staticCharacters.size(); i++) {
        if(staticCharacters[i] != -1)
            DeleteObjectID(staticCharacters[i]);
    }
    staticCharacters = {};
}

void PreScriptReload()
{
    npcTimer.DeleteAll();
    Cleanup();
    Init();
}