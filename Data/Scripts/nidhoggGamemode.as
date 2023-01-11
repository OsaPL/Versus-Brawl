#include "versusmode.as"
// ^^ only this is needed
#include "versus-brawl/pointUIBase.as"

string phaseChangeSound = "Data/Sounds/lugaru/consolesuccess.ogg";
string attackerChangeSound = "Data/Sounds/versus/fight_win2_2.wav";
string noAttackerChangeSound = "Data/Sounds/versus/fight_lose1_2.wav";

// 2 means stalemate
int teamAttacking = 2;
// Phase zero means start location
int currentPhase = 0;
// 0 means none are open to go through
int openPhase = 0;
// TODO! Add a rotation queue of weapons
// dual daggers, spear, big sword, rapier, staff?
array<string> weaponQueuePath = {""};
array<int> currentWeaponQueuesIndexes = {0, 0, 0, 0};
bool updatePhases = false;
int allOpen = 1;

// DEBUG stuff
bool enableDebugKeys = false;
bool showPossibleStraglers = false;
bool showDebugPhases = false;

//Level methods
void Init(string msg){
    useGenericSpawns = false;
    useSingleSpawnType = true;
    constantRespawning = true;
    teamPlay = true;
    teamsAmount = 2;
    allowUneven = false;
    suicideTime = 1;
    respawnTime = 1;

    // pointUIBase configuration
    diffToCloseBlinking = 0;
    pointsToWin = 2;
    pointsTextFormat = "@points@";
    playingToTextFormat = "Last phase: @points@!";
    
    //Always need to call this first!
    VersusInit("");


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
                
                if(char.GetIntVar("knocked_out") == _awake)
                    char.Execute("CutThroat();Ragdoll(_RGDL_FALL);zone_killed=1;");
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

    ScriptParams@ lvlParams = level.GetScriptParams();
    lvlParams.SetInt("CurrentPhase", currentPhase);
    lvlParams.SetInt("Attacking", teamAttacking);
    lvlParams.SetInt("OpenPhase", openPhase);
    lvlParams.SetInt("AllOpen", allOpen);

    // And finally load JSON Params
    LoadJSONLevelParams();
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
    allOpen = 1;
    teamAttacking = 2;
    currentPhase = 0;
    openPhase = 0;
    pointsCount = {0, 0, 0, 0};
    updatePhases = true;
    updateScores = true;
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
    }
    else if(teamAttacking == 1){
        openPhase = CalculateChangePhase(currentPhase, 1);
    }
    else{
        openPhase = 0;
    }

    updatePhases = true;
    updateScores = true;
}

void Update(){
    //Always need to call this first!
    VersusUpdate();

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
        if(updatePhases) {
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

        if(pointsCount[0] > pointsToWin ){
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
        if(playerToKill.teamNr != winnerNr && winnerNr != -1){
            MovementObject@ char = ReadCharacterID(playerToKill.objId);
            char.Execute("TakeBloodDamage(1.0f);Ragdoll(_RGDL_FALL);zone_killed=1;SetOnFire(true);");
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
