#include "versusmode.as"
// ^^ only this is needed
#include "versus-brawl/pointUIBase.as"

// Configurables
float timeBetweenWaves = 15.0f;
bool healAfterWave = true;
bool respawnAfterWave = true;
bool scaleWithPlayers = true;
bool friendlyAttacks = true;

// States
array<int> spawners = {};
float intermissionTimer = 0;
float waveTimer = 0;
int lastFullWaveTimer = 0;
int currentWave = -1;
bool spawnEnemies = true;
array<Wave@> waves = {};
array<EnemyTemplate@> enemyTemplates = {};

class EnemyTemplate{
    string name;
    string actorPath;
    string weaponPath;
    string backWeaponPath;
    
    EnemyTemplate(string newName, string newActorPath, string newWeaponPath = "none", string newBackWeaponPath = "none"){
        name = newName;
        actorPath = newActorPath;
        weaponPath = newWeaponPath;
        backWeaponPath = newBackWeaponPath;
    }
}

class WaveEnemies{
    string type;
    int amount;
    string spawnName;
    WaveEnemies(string newType, int newAmount, string newSpawnName = ""){
        type = newType;
        amount = newAmount;
        spawnName = newSpawnName;
    }
}

class Wave{
    float time;
    bool killAll;
    array<WaveEnemies@> enemies;
    Wave(float newTime, bool newKillAll){
        time = newTime;
        killAll = newKillAll;
        enemies = {};
    }
}


//Level methods
void Init(string msg){
    warmupHints.insertAt(0, "@vec3(0.6,0.1,0)Kill@ everyone before the time runs out!");

    //randomHints.insertAt(0, "Two's company, three's a crowd, and @vec3(1,0.8,0)fourth@ gets kills.");
    
    constantRespawning = true;
    crownEnabled = false;
    forcedSpecies = -1;
    respawnTime = 0;
    
    // pointUIBase configuration
    pointsToWin = 10;
    pointsTextFormat = "@points@";
    playingToTextFormat = "Last wave: @points@!";
    
    //Always need to call this first!
    VersusInit("");

    loadCallbacks.push_back(@HordeLoad);

    levelTimer.Add(LevelEventJob("reset", function(_params) {
        ResetHorde();
        return true;
    }));

    // And finally load JSON Params
    LoadJSONLevelParams();
    
    //Find all NpcSpawners
    array<int> @object_ids = GetObjectIDs();
    uint num_objects = object_ids.size();
    for (uint i = 0; i < num_objects; i++) {
        Object@ obj = ReadObjectFromID(object_ids[i]);
        ScriptParams @objParams = obj.GetScriptParams();
        if(objParams.HasParam("type")) {
            string type = objParams.GetString("type");
            if (type == "npcSpawnerHotspot")
            {
               spawners.push_back(object_ids[i]);
            }
        }
    }
    
    pointsToWin = waves.size();
}

void HordeLoad(JSONValue settings) {
    Log(error, "HordeLoad:");
    if(FoundMember(settings, "Horde")) {
        JSONValue horde = settings["Horde"];
        Log(error, "Available: " + join(horde.getMemberNames(),","));

        if (FoundMember(horde, "PointsToWin"))
            pointsToWin = horde["PointsToWin"]["Value"].asInt();
        
        if (FoundMember(horde, "PointsTextShowTime"))
            pointsTextShowTime = horde["PointsTextShowTime"]["Value"].asFloat();
            
        if (FoundMember(horde, "TimeBetweenWaves"))
            timeBetweenWaves = horde["TimeBetweenWaves"]["Value"].asFloat();
            
        if (FoundMember(horde, "HealAfterWave"))
            healAfterWave = horde["HealAfterWave"]["Value"].asBool();
        
        if (FoundMember(horde, "RespawnAfterWave"))
            respawnAfterWave = horde["RespawnAfterWave"]["Value"].asBool();
            
        if (FoundMember(horde, "ScaleWithPlayers"))
            scaleWithPlayers = horde["ScaleWithPlayers"]["Value"].asBool();
            
        if (FoundMember(horde, "FriendlyAttacks"))
            friendlyAttacks = horde["FriendlyAttacks"]["Value"].asBool();
            
            
        // Wave and Enemies lists load
        if (FoundMember(horde, "Waves")){
            Log(error, "Waves found!");
            JSONValue wavesJson = horde["Waves"];
            Log(error, "Waves: " + wavesJson.typeName() + " " + wavesJson.size() + " !");
            
            // Fill out waves list
            for (uint i = 0; i < wavesJson.size(); i++) {
                Log(error, "Wave: " + i);
                JSONValue theWaveJson = wavesJson[i];
                float time = 0;
                if (FoundMember(theWaveJson, "Time")){
                    time = theWaveJson["Time"].asFloat();
                    Log(error, "  Time: " + time);
                }
                bool killAll = false;
                if (FoundMember(theWaveJson, "KillAll")){
                    killAll = theWaveJson["KillAll"].asBool();
                    Log(error, "  killAll: " + killAll);
                }
                Wave waveObj (time, killAll);
                
                // Fill out enemies list
                if (FoundMember(theWaveJson, "Enemies")){
                    JSONValue enemiesJson = theWaveJson["Enemies"];
                    for (uint j = 0; j < enemiesJson.size(); j++) {
                        Log(error, "  Enemies: " + j);
                        JSONValue theEnemiesJson = enemiesJson[j];
                    
                        string type = theEnemiesJson["Type"].asString();
                        Log(error, "    Type: " + type);
                        int amount = theEnemiesJson["Amount"].asInt();
                        Log(error, "    Amount: " + amount);
                        string spawnName = "";
                        if (FoundMember(theEnemiesJson, "SpawnName")){
                            spawnName = theWaveJson["SpawnName"].asString();
                            Log(error, "    SpawnName: " + spawnName);
                        }
                        
                        WaveEnemies waveEnemies (type, amount, spawnName);
                        waveObj.enemies.push_back(waveEnemies);
                    }
                }
                
                waves.push_back(waveObj);
            }
        }
        
        // Fill out EnemyTemplates
        if (FoundMember(horde, "EnemyTemplates")){
            JSONValue enemyTemplatesJson = horde["EnemyTemplates"];
            array<string> enemyTemplatesNames = enemyTemplatesJson.getMemberNames();
            for (uint i = 0; i < enemyTemplatesNames.size(); i++) {
                Log(error, "Name: " + enemyTemplatesNames[i]);
                JSONValue theEnemyTemplateJson = enemyTemplatesJson[enemyTemplatesNames[i]];
                
                string actorPath = theEnemyTemplateJson["ActorPath"].asString();
                Log(error, "  ActorPath: " + actorPath);
                
                string weaponPath = "none";
                if (FoundMember(theEnemyTemplateJson, "WeaponPath")){
                    weaponPath = theEnemyTemplateJson["WeaponPath"].asString();
                    Log(error, "  WeaponPath: " + weaponPath);
                }
                
                string backWeaponPath = "none";
                if (FoundMember(theEnemyTemplateJson, "BackWeaponPath")){
                    backWeaponPath = theEnemyTemplateJson["BackWeaponPath"].asString();
                    Log(error, "  BackWeaponPath: " + backWeaponPath);
                }
                
                EnemyTemplate enemyTemplate (enemyTemplatesNames[i], actorPath, weaponPath, backWeaponPath);
                enemyTemplates.push_back(enemyTemplate);
            }
        }
    }
}

void DrawGUI() {
    //Always need to call this first!
    VersusDrawGUI();
}

void Update(){
    //Always need to call this first!
    VersusUpdate();

    if(currentState == 2){
        constantRespawning = false;
        if(currentWave < 0)
            currentWave = 0;
      
        if(spawnEnemies){
            // Make everyone same teams
            if(!friendlyAttacks){
                for (uint k = 0; k < versusPlayers.size(); k++)
                {
                    VersusPlayer@ player = GetPlayerByNr(k);
                    Object@ obj = ReadObjectFromID(player.objId);
                    ScriptParams @objParams = obj.GetScriptParams();
                    objParams.SetString("Teams", "defenders");
                }
            }
                
            spawnEnemies = false;
            SpawnRequiredEnemies();
        }
        
        int enemiesLeft = 0;
        waveTimer += time_step;
        lastFullWaveTimer = int(waveTimer);

        bool waveNotDone = false;
        
        //Log(error, "spawners.size(): " + spawners.size());
        for (uint i = 0; i < spawners.size(); i++) {
            Object@ obj = ReadObjectFromID(spawners[i]);
            ScriptParams @objParams = obj.GetScriptParams();
            if(objParams.HasParam("currentQueue")) {
                if(objParams.GetInt("currentQueue") > 0){
                    waveNotDone = true;
                    //Log(error, "waveNotDone: " + spawners[i]+ " currentQueue: " + objParams.GetInt("currentQueue"));
                    enemiesLeft += objParams.GetInt("currentQueue");
                }
            }
            if(objParams.HasParam("currentCharacters")) {
                if(objParams.GetInt("currentCharacters") > 0){
                    waveNotDone = true;
                    //Log(error, "waveNotDone: " + spawners[i]+ " currentCharacters: " + objParams.GetInt("currentCharacters"));
                    enemiesLeft += objParams.GetInt("currentCharacters");
                }
            }
        }
        
        versusAHGUI.SetText("Time left: " + (waves[currentWave].time - lastFullWaveTimer), 
        "Enemies left: " + enemiesLeft);
        
        // Minimum wave time, to make sure things spawn in
        if(waveTimer < 5.0f)
            waveNotDone = true;
            
        // Is everyone dead?
        bool allDead = true;    
        for (uint k = 0; k < versusPlayers.size(); k++)
        {
            VersusPlayer@ player = GetPlayerByNr(k);
            MovementObject@ mo = ReadCharacterID(player.objId);
            if(mo.GetIntVar("knocked_out") == _awake) {
                allDead = false;
                break;
            }
        }
        if(allDead)
            ChangeGameState(102);

        if(waveTimer > waves[currentWave].time){
            // Time run out
            if(waves[currentWave].killAll){
                ChangeGameState(103);
            }
            else{
                // Go to intermission
                intermissionTimer = 0;
                constantRespawning = true;
                ChangeGameState(3);
                
                // TODO! Add healing/respawning here
            }
        }
        else if(!waveNotDone){
            // Go to intermission
            intermissionTimer = 0;
            constantRespawning = true;
            ChangeGameState(3);
            
            // Respawn or/and heal
            if(respawnAfterWave){
                for (uint k = 0; k < versusPlayers.size(); k++)
                {
                    VersusPlayer@ player = GetPlayerByNr(k);
                    MovementObject@ mo = ReadCharacterID(player.objId);
                    if(mo.GetIntVar("knocked_out") != _awake) {
                        CallRespawn(player.playerNr, player.objId);
                    }
                }
            }
            
            if(healAfterWave){
                for (uint k = 0; k < versusPlayers.size(); k++)
                {
                    VersusPlayer@ player = GetPlayerByNr(k);
                    MovementObject@ mo = ReadCharacterID(player.objId);
                    mo.Execute("Recover();");
                }
            }
            
            // This will update players UI with current wave
            for (uint j = 0; j < versusPlayers.size(); j++)
            {
                pointsCount[j] = currentWave+1;
            }
            updateScores = true;

            PlaySound("Data/Sounds/versus/fight_end.wav");
        }
        //else{
        //    //TODO! Check if all playuers dead
        //    ChangeGameState(102);
        //}
    }
    // Intermission, between waves
    else if(currentState == 3){
        if(currentWave+1 >= int(waves.size()))
            ChangeGameState(101);
        versusAHGUI.SetText("Wave defeated!", "Next wave incoming...");
       
        intermissionTimer += time_step;
        if(intermissionTimer > timeBetweenWaves){
            waveTimer = 0;
            spawnEnemies = true;
            currentWave+=1;
            ChangeGameState(2);
        }
    }

    // Win state, this doesnt reuse the default 100 state, cause we need a custom UI label
    if(currentState == 101){
        winStateTime = 15.0f;
        versusAHGUI.SetText("Last wave defeated!", "You're winner !", GetTeamUIColor(0));
        ChangeGameState(110);
    }
    if(currentState == 102){
        winStateTime = 8.0f;
        versusAHGUI.SetText("Everyone died!", "Resetting wave...", GetTeamUIColor(1));
        ChangeGameState(111);
    }
    if(currentState == 103){
        winStateTime = 8.0f;
        versusAHGUI.SetText("Time ran out!", "Resetting wave...", GetTeamUIColor(1));
        ChangeGameState(111);
    }
    
    // Win
    if(currentState== 110){
        if(winStateTimer>=winStateTime) {
            ResetHorde();
        }
    }
    // Lost, reset wave only
    if(currentState== 111){
        if(winStateTimer>=winStateTime) {
            ResetHorde(false);
        }
    }
    
    //versusAHGUI.SetText("currentState", ""+currentState);
    
    UpdateUI();
}

void SpawnRequiredEnemies(){
    array<int> availableSpawnPoints = spawners;
    // This keeps start of the total list of the spawns, incase you have too many locked ones atm
    array<int> startListSpawnPoints = spawners;
    
    Log(error, "waves: " + waves.size());
    Wave@ currentWaveObj = waves[currentWave];
    for (uint j = 0; j < currentWaveObj.enemies.size(); j++)
    {
        availableSpawnPoints = spawners;
        WaveEnemies@ toSpawn = currentWaveObj.enemies[j];
        // Find template
        EnemyTemplate@ template = null;
        bool templateFound = false;
        for (uint k = 0; k < enemyTemplates.size(); k++)
        {
            if(enemyTemplates[k].name == toSpawn.type){
                @template = enemyTemplates[k];
                templateFound = true;
                break;
            }
        }
        if(templateFound){
            // If `scaleWithPlayers` is set, we want to multiply by players amount 
            int spawnMlt = 1;
            if(scaleWithPlayers)
                spawnMlt = versusPlayers.size();
            // Search for correlated SpawnName
            if(toSpawn.spawnName != ""){
                int desiredSpawnerId = -1;
                for (uint m = 0; m < spawners.size(); m++)
                {
                    Object@ spawnerObj = ReadObjectFromID(spawners[m]);
                    string name = spawnerObj.GetName();
                    if(name == toSpawn.spawnName){
                        desiredSpawnerId = spawners[m];
                    }
                }
                if(desiredSpawnerId != -1){
                    Object@ desiredSpawnerObj = ReadObjectFromID(desiredSpawnerId);
                    for (int n = 0; n < spawnMlt; n++){
                        desiredSpawnerObj.ReceiveScriptMessage("spawn " + " " 
                        + template.actorPath + " " + template.weaponPath + " " + template.backWeaponPath);
                    }
                }
                else{
                    //TODO! Couldnt find this spawn, what to do now?
                }
            }
            // If no SpawnName, just find a not used one
            else{
                bool foundSpawn = false;
                while(availableSpawnPoints.size() > 0){
                    int index = rand()%(availableSpawnPoints.size());
                    int obj_id = availableSpawnPoints[index];
                    Object@ obj = ReadObjectFromID(obj_id);
                    
                    // If its disabled just go on
                    if(obj.GetEnabled()){
                        foundSpawn = true;
                        for (int n = 0; n < spawnMlt; n++){
                            obj.ReceiveScriptMessage("spawn " + " " 
                            + template.actorPath + " " + template.weaponPath + " " + template.backWeaponPath);
                        }
                        break;
                    }
                    else {
                        availableSpawnPoints.removeAt(index);
                    }
                }
                
                // Could find a free one, just take a random one (this will not care if its been already used)
                if(!foundSpawn){
                    int randIndex = rand()%(startListSpawnPoints.size());
                    int randId = startListSpawnPoints[randIndex];
                    Object@ randSpawnerObj = ReadObjectFromID(randId);
                    randSpawnerObj.ReceiveScriptMessage("spawn " + " " 
                    + template.actorPath + " " + template.weaponPath + " " + template.backWeaponPath);
                }
            }
        }
    }
}

void ReceiveMessage(string msg){
    //Always need to call this first!
    VersusReceiveMessage(msg);
}

void PreScriptReload(){
    //Always need to call this first!
    VersusPreScriptReload();
}

void Reset(){
    //Always need to call this first!
    VersusReset();
}

void ResetHorde(bool fullReset = true){
    currentState = 2;
    pointsTextShow = true;
    intermissionTimer = 0;
    waveTimer = 0;
    winStateTimer = 0;
    spawnEnemies = true;
    
    if(fullReset){
        currentWave = -1;
        pointsCount = {};
        for (uint j = 0; j < versusPlayers.size(); j++)
        {
            pointsCount.push_back(0);
        }
    }
    else{
        // Respawn all players
        for (uint k = 0; k < versusPlayers.size(); k++)
        {
            VersusPlayer@ player = GetPlayerByNr(k);
            MovementObject@ mo = ReadCharacterID(player.objId);
            if(mo.GetIntVar("knocked_out") != _awake) {
                CallRespawn(player.playerNr, player.objId);
            }
        }
        // Notify all spawners to cleanup
        for (uint m = 0; m < spawners.size(); m++)
        {
            Object@ spawnerObj = ReadObjectFromID(spawners[m]);
            spawnerObj.ReceiveScriptMessage("cleanup");
        }
    }
    updateScores = true;
}