#include "versusmode.as"
// ^^ only this is needed
#include "versus-brawl/pointUIBase.as"

string phaseChangeSound = "Data/Sounds/lugaru/consolesuccess.ogg";
string attackerChangeSound = "Data/Sounds/versus/fight_win2_2.wav";
string noAttackerChangeSound = "Data/Sounds/versus/fight_lose1_2.wav";
string attacketIconPath = "Data/Textures/versus-brawl/point_icon.png";
// 2 means stalemate
int teamAttacking = 2;
// Phase zero means start location
int currentPhase = 0;
// 0 means none are open to go through
int openPhase = 0;
bool init = true;
// sword, spear, dual daggers, big sword, rapier, staff, hammer?
array<string> weaponQueuePaths = { "Data/Items/DogWeapons/DogSword.xml", "Data/Items/DogWeapons/DogGlaive.xml", "2x Data/Items/MainGauche.xml", "Data/Items/DogWeapons/DogBroadSword.xml", "Data/Items/Rapier.xml", "Data/Items/staffbasic.xml", "Data/Items/DogWeapons/DogHammer.xml" };
array<string> weaponQueueNames = { "Shortsword", "Glaive", "Daggers", "Broadsword", "Rapier", "Staff", "Hammer" };
array<int> currentWeaponQueuesIndexes = {0, 0, 0, 0};
array<array<int>> currentWeaponsIds = {{}, {}, {}, {}};
bool queueClearWeapons = false;
bool clearAllWeapons = false;
array<int> giveWeaponQueue = {};

bool updatePhases = false;
int allOpen = 1;

array<AHGUI::Text@> uiNextWeaponTextElem = {};

// DEBUG stuff
bool enableDebugKeys = false;
bool showPossibleStraglers = false;
bool showDebugPhases = false;

//Level methods
void Init(string msg){
    // NIDHOGG specific hints
    warmupHints.insertAt(0, "Hold @vec3(1,0.5,0)@attack@@ and @vec3(1,0.5,0)@grab@@ to quickly suicide and respawn.");
    warmupHints.insertAt(0, "Attackers suicide will reset the @vec3(0.0,0.0,1.0)initiative@.");
    warmupHints.insertAt(0, "Killing the enemy will give you the @vec3(0.0,0.0,1.0)initiative@.");
    warmupHints.insertAt(0, "If you have the @vec3(0.0,0.0,1.0)initiative@, you can push through.");
    warmupHints.insertAt(0, "Who holds the @vec3(0.0,0.0,1.0)initiative@ is represented by the color of the @vec3(0.0,0.0,1.0)V@.");
    warmupHints.insertAt(0, "You goal is to sacrifice yourself to the @vec3(1,0.5,0.5)Nidhogg@!");
    
    randomHints.insertAt(0, "You dont have to kill if you have the @vec3(0.0,0.0,1.0)initiative@, just run!");
    randomHints.insertAt(0, "Your next weapon will be shown on the bottom.");
    
    useGenericSpawns = false;
    useSingleSpawnType = true;
    constantRespawning = true;
    teamPlay = true;
    teamsAmount = 2;
    allowUneven = true;
    suicideTime = 0.7f;
    respawnTime = 1;
    forcedSpecies = -1;
    strictTeamColors = false;

    // pointUIBase configuration
    diffToCloseBlinking = 0;
    pointsToWin = 2;
    pointsTextFormat = "@points@";
    playingToTextFormat = "Last phase: @points@!";
    decideWinner = false;
    
    //Always need to call this first!
    VersusInit("");

    loadCallbacks.push_back(@NidhoggLoad);

    levelTimer.Add(LevelEventJob("reset", function(_params){
        ResetNidhogg();
        return true;
    }));

    levelTimer.Add(LevelEventJob("phaseChange", function(_params){
        if(currentState < 2 || currentState > 100 )
            return true;
        
        Log(error, "received phaseChange " + _params[1]);
        
        VersusPlayer@ player = GetPlayerByObjectId(parseInt(_params[1]));
        if(player.teamNr == teamAttacking){
            PlaySound(phaseChangeSound);
            //Respawn everyone 
            for (uint i = 0; i < versusPlayers.size(); i++) {
                VersusPlayer@ playerToRespawn = GetPlayerByNr(i);
                MovementObject@ mo = ReadCharacterID(playerToRespawn.objId);
                if(mo.GetIntVar("knocked_out") != _awake && !playerToRespawn.respawnNeeded){
                    CallRespawn(playerToRespawn.playerNr, playerToRespawn.objId);
                    playerToRespawn.respawnQueue = 0.1f;
                }
            }
            NextNihoggPhase();
        }
        
        return true;
    }));

    levelTimer.Add(LevelEventJob("killStraglers", function(_params){
        if(currentState < 2 || currentState > 100 )
            return true;
        
        for (uint i = 0; i < versusPlayers.size(); i++) {
            VersusPlayer@ playerToKill = GetPlayerByNr(i);
            bool checkSide = CheckSide(playerToKill.objId, parseInt(_params[1]));
            if((!checkSide && teamAttacking == 0) || (checkSide && teamAttacking == 1)){
                Object @obj = ReadObjectFromID(parseInt(_params[1]));
                ScriptParams@ objParams = obj.GetScriptParams();
                Log(error, "phase: " + objParams.GetInt("phase") + " is killing: " + playerToKill.playerNr );
                MovementObject@ char = ReadCharacterID(playerToKill.objId);
                
                if(char.GetIntVar("knocked_out") == _awake){
                    if(playerToKill.teamNr == teamAttacking) {
                        // Dont kill, just respawn if its the attacking team
                        CallRespawn(playerToKill.playerNr, playerToKill.objId);
                        playerToKill.respawnQueue = 0.1f;
                    }
                    else {
                        char.Execute("CutThroat();Ragdoll(_RGDL_FALL);zone_killed=1;");
                    }
                }
            }
        }
        return true;
    }));
    
    levelTimer.Add(LevelEventJob("oneKilledByTwo", function(_params){
        if(currentState < 2 || currentState > 100 )
            return true;
        
        Log(error, "received oneKilledByTwo " + _params[1] + " " + _params[2]);
        VersusPlayer@ victim = GetPlayerByObjectId(parseInt(_params[1]));
        VersusPlayer@ killer = GetPlayerByObjectId(parseInt(_params[2]));
        if(killer.teamNr != teamAttacking){
            ChangeAttacker(killer.teamNr);
        }
        return true;
    }));

    levelTimer.Add(LevelEventJob("suicideDeath", function(_params){
        if(currentState < 2 || currentState > 100 )
            return true;
        
        Log(error, "received suicideDeath " + _params[1]);
        VersusPlayer@ victim = GetPlayerByObjectId(parseInt(_params[1]));
        if(victim.teamNr == teamAttacking){
            ChangeAttacker(2);
        }
        return true;
    }));

    levelTimer.Add(LevelEventJob("spawned", function(_params){
        if(currentState < 2 || currentState > 100)
            return true;

        Log(error, "received spawned " + _params[1] + " " +  _params[2]);
        VersusPlayer@ respawnedPlayer = GetPlayerByObjectId(parseInt(_params[1]));
        if(_params[2] == "false"){
            currentWeaponQueuesIndexes[respawnedPlayer.playerNr] += 1;
            currentWeaponQueuesIndexes[respawnedPlayer.playerNr] = currentWeaponQueuesIndexes[respawnedPlayer.playerNr] % weaponQueuePaths.size();
        }
        giveWeaponQueue.push_back(respawnedPlayer.playerNr);
        Log(error, "currentWeaponQueuesIndexes[respawnedPlayer.playerNr]: " + currentWeaponQueuesIndexes[respawnedPlayer.playerNr]);
        return true;
    }));

    ScriptParams@ lvlParams = level.GetScriptParams();
    lvlParams.SetInt("CurrentPhase", currentPhase);
    lvlParams.SetInt("Attacking", teamAttacking);
    lvlParams.SetInt("OpenPhase", openPhase);
    lvlParams.SetInt("AllOpen", allOpen);

    // And finally load JSON Params
    LoadJSONLevelParams();
}

void NidhoggLoad(JSONValue settings) {
    Log(error, "NidhoggLoad:");
    if(FoundMember(settings, "Nidhogg")) {
        JSONValue nidhogg = settings["Nidhogg"];
        Log(error, "Available: " + join(nidhogg.getMemberNames(),","));

        if (FoundMember(nidhogg, "PhasesToWin")){
            pointsToWin = nidhogg["PhasesToWin"]["Value"].asInt() - 1;
            Log(error, "PhasesToWin: " + pointsToWin);
        }
            
    }
}

void GiveWeapon(int playerNr){
    VersusPlayer@ player = GetPlayerByNr(playerNr);

    string species = IntToSpecies(player.currentRace);

    // If its "wolf" dont give a weapon
    if(species == "wolf")
    {
        return;
    }
    
    string weaponPath = weaponQueuePaths[currentWeaponQueuesIndexes[playerNr]];
    if(weaponPath.substr(0,3) == "2x "){
        // if we have 2x, just repeat this
        weaponPath = weaponPath.substr(3,weaponPath.length()-3);
        // TODO! Copy pasta
        int weaponId = CreateObject(weaponPath);
        if(weaponId == -1)
            return;

        currentWeaponsIds[playerNr].push_back(weaponId);

        MovementObject@ playerMo = ReadCharacterID(player.objId);
        playerMo.Execute("AttachWeapon(" + weaponId + ");");
    }
    
    int weaponId = CreateObject(weaponPath);
    if(weaponId == -1)
        return;

    Log(error, "Adding: " + weaponPath + " id: " + weaponId);
    currentWeaponsIds[playerNr].push_back(weaponId);
    
    MovementObject@ playerMo = ReadCharacterID(player.objId);
    playerMo.Execute("AttachWeapon(" + weaponId + ");");
}

void ClearWeapons(bool ignoreHeld = false){
    
    for (uint i = 0; i < currentWeaponsIds.size(); i++) {
        array<int> toRemove = {};
        for (uint j = 0; j < currentWeaponsIds[i].size(); j++) {
            Log(error, "currentWeaponsIds["+i+"]["+j+"]: " + currentWeaponsIds[i][j]);
            // Sometimes the weapon wont be initialised completely but still will be in the array, we delay its removal till next check
            if(ObjectExists(currentWeaponsIds[i][j])) {
                ItemObject@ itemObj = ReadItemID(currentWeaponsIds[i][j]);

                if (!itemObj.IsHeld() || ignoreHeld) {
                    Log(error, "Removing: " + currentWeaponsIds[i][j]);
                    toRemove.push_back(j);
                    QueueDeleteObjectID(currentWeaponsIds[i][j]);
                }
            }
        }

        Log(error, "toRemove.size(): " + toRemove.size());
        for (int k = int(toRemove.size()) - 1; k >= 0; k--)
        {
            Log(error, "toRemove["+k+"]: ");
            // Log(error, "toRemove["+i+"]["+k+"]: " + toRemove[k]);
            // Log(error, "toRemove currentWeaponsIds["+i+"]["+k+"]: " + currentWeaponsIds[i][k]);
            currentWeaponsIds[i].removeAt(toRemove[k]);
        }
    }

    for (uint i = 0; i < currentWeaponsIds.size(); i++) {
        for (uint j = 0; j < currentWeaponsIds[i].size(); j++)
        {
            Log(error, "Affter remove: currentWeaponsIds[" + i + "][" + j + "]: " + currentWeaponsIds[i][j]);
        }
    }
}

bool CheckSide(int charId, int objId){
    Object@ phaseObj = ReadObjectFromID(objId);
    MovementObject@ char = ReadCharacterID(charId);
    VersusPlayer@ player = GetPlayerByObjectId(charId);
    
    vec3 offset = phaseObj.GetTranslation() - (char.position);
    float portalSide = dot(offset, normalize(phaseObj.GetRotation() * vec3(0, 0, 1)));
    // Log(error, "CheckSide: " + portalSide + " for " + player.playerNr);
    // Log(error, "phaseObj.GetTranslation(): " + phaseObj.GetTranslation() + " char.position: " + char.position);
    
    if(teamAttacking == 0) {
        DebugDrawLine(char.position,
            phaseObj.GetTranslation(),
            (portalSide < 0) ? vec3(0, 0, 1) : vec3(1, 1, 0),
            _delete_on_update);
    }
    else if(teamAttacking == 1) {
        DebugDrawLine(char.position,
            phaseObj.GetTranslation(),
            (portalSide > 0) ? vec3(0, 0, 1) : vec3(1, 1, 0),
            _delete_on_update);
    }
    DebugDrawText(
        char.position,
        "" + portalSide,
        1.0f,
        true,
        _delete_on_update);

    return portalSide < 0;
}

void ResetNidhogg(){
    clearAllWeapons = true;
    allOpen = 1;
    teamAttacking = 2;
    currentPhase = 0;
    openPhase = 0;
    pointsCount = {0, 0, 0, 0};
    giveWeaponQueue = {};
    currentWeaponQueuesIndexes = {0, 0, 0, 0};
    updatePhases = true;
    updateScores = true;
    constantRespawning = true;
}

void DrawGUI() {
    //Always need to call this first!
    VersusDrawGUI();
}

int CalculateChangePhase(int value, int step){
    int plus = (step > 0 ? 1 : -1);
    if(value + step == 0)
        return value + step + plus;
    return value + step;
}

void NextNihoggPhase(){
    if(teamAttacking == 0){
        currentPhase = CalculateChangePhase(currentPhase, -1);
        openPhase = CalculateChangePhase(currentPhase, -1);
    }
    else if(teamAttacking == 1){
        currentPhase = CalculateChangePhase(currentPhase, 1);
        openPhase = CalculateChangePhase(currentPhase, 1);
    }
    updatePhases = true;
    updateScores = true;
    queueClearWeapons = true;
}

void ChangeAttacker(int newAttacker){
    Log(error, "ChangeAttacker: " + newAttacker);
    if(newAttacker != teamAttacking){
        if(newAttacker != 2){
            PlaySound(attackerChangeSound);
        }
        else{
            PlaySound(attackerChangeSound);
        }
    }
        
    

    teamAttacking = newAttacker;
    if(teamAttacking == 0){
        openPhase = CalculateChangePhase(currentPhase, -1);
        winnerNr = 0;
    }
    else if(teamAttacking == 1){
        openPhase = CalculateChangePhase(currentPhase, 1);
        winnerNr = 1;
    }
    else{
        openPhase = 0;
        winnerNr = -1;
    }

    updatePhases = true;
    updateScores = true;
}

void Update(){
    //Always need to call this first!
    VersusUpdate();

    if(init){
        // We create the label with next weapon value
        for (uint k = 0; k < versusPlayers.size(); k++)
        {
            VersusPlayer@ player = GetPlayerByNr(k);
            AHGUI::Element @headerElement = versusAHGUI.root.findElement("header" + player.playerNr);
            AHGUI::Divider @div = cast < AHGUI::Divider > (headerElement);
            AHGUI::Text textElem("Next Weapon", "edosz", 65, 1, 1, 1, 1);
            textElem.setShadowed(true);
            
            if(player.playerNr == 0 || player.playerNr == 2){
                div.addElement(textElem, DDLeft);
                div.addSpacer( 20, DDLeft );
            }
            else{
                div.addElement(textElem, DDRight);
                div.addSpacer( 20, DDRight );
            }
            uiNextWeaponTextElem.push_back(textElem);
        }
        init = false;
    }

    // TODO! Clean this mess up
    if(currentState >= 2 && currentState < 100){
        allOpen = 0;

        // To debug the gamemode without playing it
        if(enableDebugKeys) {
            if (GetInputPressed(0, "grab")) {
                ChangeAttacker(0);
            } else if (GetInputPressed(0, "attack")) {
                ChangeAttacker(1);
            } else if (GetInputPressed(0, "crouch") && teamAttacking != 2) {
                NextNihoggPhase();
            } else if (GetInputPressed(0, "item")) {
                ChangeAttacker(2);
            }
        }

        // Shows "possible" stranglers to kill ("possible" cause it can change next frame)
        if(showPossibleStraglers){
            array<int> hotspots = GetObjectIDsType(_hotspot_object);

            for (uint i = 0; i < hotspots.size(); i++) {
                Object@ foundHotspot = ReadObjectFromID(hotspots[i]);
                ScriptParams@ objParams = foundHotspot.GetScriptParams();
                if(objParams.HasParam("type")) {
                    if (objParams.GetString("type") == "nidhoggPhaseHotspot") {
                        int phase = objParams.GetInt("phase");
                        if(currentPhase == 0 && teamAttacking == 0){
                            phase = -1;
                        }
                        else if(currentPhase == 0 && teamAttacking == 1){
                            phase = 1;
                        }
                        if(phase == currentPhase && (teamAttacking == 0 || teamAttacking == 1)){
                            for (uint k = 0; k < versusPlayers.size(); k++)
                            {
                                VersusPlayer@ player = GetPlayerByNr(k);

                                CheckSide(player.objId, hotspots[i]);
                            }
                        }
                    }
                }
            }
        }

        // UI
        if(updatePhases && pointsTextShowTimer > pointsTextShowTime) {
            //TODO! Build a prettier UI for the progress thingy
            vec3 color;

            string map = "";
            int phase = currentPhase;
            if(currentPhase * openPhase < 0)
                phase = 0;

            pointsCount[0] = -1*currentPhase;
            pointsCount[1] = currentPhase;

            if(teamAttacking == 0 )
                map += "";

            for (int i = -pointsToWin; i < pointsToWin+1 ; i++)
            {
                if(i < phase){
                    color = GetTeamUIColor(1);
                }
                else if(i > phase) {
                    color = GetTeamUIColor(0);
                }

                if (i == phase) {
                    if(teamAttacking == 0){
                        color = GetTeamUIColor(0);
                    }
                    else if(teamAttacking == 1){
                        color = GetTeamUIColor(1);
                    }
                    else{
                        color = GetTeamUIColor(2);
                    }
                    map += "@" + color + "v@";

                } else {
                    map += "@" + color + "_@";
                }
            }
            if(teamAttacking == 1)
                map += "";

            versusAHGUI.SetMainText(map, color);
            updatePhases = false;
        }
        // Updates next weapon label
        for (uint k = 0; k < versusPlayers.size(); k++)
        {
            VersusPlayer@ player = GetPlayerByNr(k);

            if(player.respawnNeeded){
                // Color label if respawn in progress
                uiNextWeaponTextElem[player.playerNr].setColor(vec4(0.3f, 0.3f, 0.3f, 1));
            }
            else{
                uiNextWeaponTextElem[player.playerNr].setColor(vec4(1));
            }

            uiNextWeaponTextElem[player.playerNr].setText(weaponQueueNames[(currentWeaponQueuesIndexes[player.playerNr] + 1) % weaponQueueNames.size()]);
        }


        if(pointsCount[0] > pointsToWin ){
            // green wins
            constantRespawning = false;
            allOpen = 1;
            winnerNr = 0;
            currentPhase = -pointsToWin+1;
            openPhase = 0;

            ChangeGameState(100);
            PlaySound("Data/Sounds/versus/fight_end.wav");
            IgniteNotWinners();

            ResetNidhogg();
        }
        else if(pointsCount[1] > pointsToWin){
            // red wins
            constantRespawning = false;
            allOpen = 1;
            winnerNr = 1;
            currentPhase = pointsToWin-1;
            openPhase = 0;

            ChangeGameState(100);
            PlaySound("Data/Sounds/versus/fight_end.wav");
            IgniteNotWinners();

            ResetNidhogg();
        }

        if(showDebugPhases)
            versusAHGUI.SetExtraText("currentPhase: " + currentPhase + " openPhase: " + openPhase, vec3(0.9f));

        if(queueClearWeapons || clearAllWeapons){
            // This makes sure the weapon is fully created before we try to clean it up
            queueClearWeapons = false;
            clearAllWeapons = false;
            ClearWeapons(clearAllWeapons);
        }

        if(teamAttacking != 2){
            for (uint i = 0; i < crownsIds.size(); i++) {
                Object@ crown = ReadObjectFromID(crownsIds[i]);
                ScriptParams @crownParams = crown.GetScriptParams();
                vec3 color = GetTeamUIColor(teamAttacking);
                crownParams.SetFloat("red", color.x);
                crownParams.SetFloat("greeb", color.y);
                crownParams.SetFloat("blue", color.z);
                crownParams.SetString("billboardPath", attacketIconPath);
            }
        }

        // Give weapons
        for (uint i = 0; i < giveWeaponQueue.size(); i++) {
            GiveWeapon(giveWeaponQueue[i]);
        }
        giveWeaponQueue = {};
    }

    ScriptParams@ lvlParams = level.GetScriptParams();
    lvlParams.SetInt("CurrentPhase", currentPhase);
    lvlParams.SetInt("Attacking", teamAttacking);
    lvlParams.SetInt("OpenPhase", openPhase);
    lvlParams.SetInt("AllOpen", allOpen);

    UpdateUI();
}

void IgniteNotWinners(){
    for (uint i = 0; i < versusPlayers.size(); i++) {
        VersusPlayer@ playerToKill = GetPlayerByNr(i);
        MovementObject@ char = ReadCharacterID(playerToKill.objId);
        char.Execute("TakeBloodDamage(2.0f);Ragdoll(_RGDL_FALL);zone_killed=1;");
        if(playerToKill.teamNr != winnerNr && winnerNr != -1){  
            char.Execute("SetOnFire(true);");
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
    ResetNidhogg();
}
