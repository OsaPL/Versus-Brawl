#include "versusmode.as"
// ^^ only this is needed
#include "versus-brawl/pointUIBase.as"

//Configurables
bool onlyOneLife = false;
bool highestPointsWin = false;

//State
bool raceInit = true;
array<bool> dead = {false, false, false, false};
float loadedWinStateTime = 10;

//Level methods
void Init(string msg){
    // Race specific hints
    //Remove first 3, cause you cant change species here
    warmupHints.removeAt(0);
    warmupHints.removeAt(0);
    warmupHints.removeAt(0);
    warmupHints.insertAt(0, "@vec3(0.8,0.2,0.2)No rules@, dont feel bad for hitting people.");
    warmupHints.insertAt(0, "You need to get all the checkpoints, order doesnt matter.");
    
    //We setup the parameters before init call
    useGenericSpawns = false;
    useSingleSpawnType = true;
    constantRespawning = true;
    blockSpeciesChange = true;
    respawnTime = 1;
    suicideTime = 1;

    // pointUIBase configuration
    pointsToWin = 10;
    pointsTextFormat = "@points@";
    playingToTextFormat = "Racing to: @points@ checkpoints!";

    //Always need to call this first!
    VersusInit("");

    loadCallbacks.push_back(@RaceLoad);
    
    // This is used to inform any hotspots whether the game is in progress
    ScriptParams@ lvlParams = level.GetScriptParams();
    lvlParams.SetInt("InProgress", 0);

    levelTimer.Add(LevelEventJob("checkpoint", function(_params){
        Log(error, "Received checkpoint "+_params[1]);
        pointsCount[parseInt(_params[1])]++;
        updateScores = true;
        return true;
    }));

    levelTimer.Add(LevelEventJob("reset", function(_params) {
        ResetRace();
        return true;
    }));

    // And finally load JSON Params
    LoadJSONLevelParams();

    loadedWinStateTime = winStateTime;
}

void RaceLoad(JSONValue settings){
    Log(error, "RaceLoad:");
    if(FoundMember(settings, "Race")) {
        JSONValue race = settings["Race"];
        Log(error, "Available: " + join(race.getMemberNames(),","));

        if (FoundMember(race, "CheckPointsNeeded"))
            pointsToWin = race["CheckPointsNeeded"].asInt();

        if (FoundMember(race, "CheckPointsNeededTextShowTime"))
            pointsTextShowTime = race["CheckPointsNeededTextShowTime"].asFloat();

        if (FoundMember(race, "OnlyOneLife")) {
            onlyOneLife = race["OnlyOneLife"].asBool();
            if(onlyOneLife)
                constantRespawning = false;
        }

        if (FoundMember(race, "HighestPointsWin")) {
            highestPointsWin = race["HighestPointsWin"].asBool();
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

    if(currentState >= 2 && currentState < 100){

        ScriptParams@ lvlParams = level.GetScriptParams();
        lvlParams.SetInt("InProgress", 1);

        bool allDead = true;
        
        // Register the event, that will be used to check if everyones dead
        if(onlyOneLife) {
            if (raceInit) {
                for (uint k = 0; k < versusPlayers.size(); k++)
                {
                    VersusPlayer@ player = GetPlayerByNr(k);

                    player.charTimer.Add(CharDeathJob(player.objId, function(char_a) {
                        if(currentState >= 2 && currentState < 100){
                            VersusPlayer@ deadPlayer = GetPlayerByObjectId(char_a.GetID());
                            if(!dead[deadPlayer.playerNr])
                                dead[deadPlayer.playerNr] = true;
                        }
                        
                        return true;
                    }));
                }
                raceInit = false;
            }

            // Everyone dead?
            for (uint i = 0; i < versusPlayers.size(); i++)
            {
                if (!dead[i]){
                    allDead = false;
                    break;
                }
            }
        }

        for (uint k = 0; k < versusPlayers.size(); k++)
        {
            VersusPlayer@ player = GetPlayerByNr(k);
            
            //Checks for win
            if(pointsCount[player.playerNr]>=pointsToWin){
                // 3 is win state
                winnerNr = player.playerNr;
                // We make sure we dont use the shortened timer
                winStateTime = loadedWinStateTime;
                ChangeGameState(100);
                
                constantRespawning = false;
                PlaySound("Data/Sounds/versus/fight_end.wav");
                
                // TODO: Buff the winner?

                for (uint j = 0; j < versusPlayers.size(); j++)
                {
                    VersusPlayer@ playerTemp = GetPlayerByNr(j);
                    MovementObject@ mo = ReadCharacterID(playerTemp.objId);
                    Object@ objTemp = ReadObjectFromID(playerTemp.objId);
                    ScriptParams@ charParams = objTemp.GetScriptParams();
                    
                    if(playerTemp.playerNr != int(player.playerNr)){
                        // Weaken the losers
                        mo.Execute("TakeBloodDamage(0.6);");
                        charParams.SetFloat("Attack Damage",    0.0); //params.AddFloatSlider("Attack Damage", 1, "min:0,max:2,step:0.1,text_mult:100");
                        // Heheh yeet slap
                        charParams.SetFloat("Attack Knockback", 5.0); //params.AddFloatSlider("Attack Knockback", 1, "min:0,max:2,step:0.1,text_mult:100");
                        charParams.SetFloat("Attack Speed",     0.2); //params.AddFloatSlider("Attack Speed", 1, "min:0,max:2,step:0.1,text_mult:100");
                        charParams.SetFloat("Damage Resistance",0.2); //params.AddFloatSlider("Damage Resistance", 1, "min:0,max:2,step:0.1,text_mult:100");
                        charParams.SetFloat("Movement Speed",   0.1); //params.AddFloatSlider("Movement Speed", 1, "min:0.1,max:1.5,step:0.1,text_mult:100");
                    }
                    objTemp.UpdateScriptParams();
                }
                break;
            }

            if(onlyOneLife){
                if(allDead){
                    Log(error, "All probably dead");
                    
                    if(highestPointsWin){
                        int highestId = -1;
                        int highestPts = 0;
                        for (uint l = 0; l < versusPlayers.size(); l++)
                        {
                            VersusPlayer@ player = GetPlayerByNr(l);
                        
                            //Checks for win
                            if(pointsCount[player.playerNr]>highestPts) {
                                highestPts = pointsCount[player.playerNr];
                                highestId = player.playerNr;
                            }
                            else if(pointsCount[player.playerNr] == highestPts){
                                highestId = -1;
                            }
                        }
                        
                        winnerNr = highestId;
                    }
                    else{
                        winnerNr = -1;
                    }

                    // We make sure we dont use the shortened timer
                    if(winnerNr != -1)
                        winStateTime = loadedWinStateTime;
                    
                    PlaySound("Data/Sounds/voice/animal3/voice_rat_death_2.wav");
                    ChangeGameState(100);
                    break;
                }
            }
        }
    }
    
    if(currentState >= 100){
        if(winStateTimer>=winStateTime){
            // Now we just need to reset few things
            ResetRace();
            ScriptParams@ lvlParams = level.GetScriptParams();
            lvlParams.SetInt("InProgress", 1);

            // Enable all spawns back, not needed ones will get disabled by checkpoints themselves
            array<int> @object_ids = GetObjectIDs();
            for (uint j = 0; j <object_ids.size() ; j++) {
                Object@ objTemp = ReadObjectFromID(object_ids[j]);
                ScriptParams@ objParams = objTemp.GetScriptParams();

                if(objParams.HasParam("game_type") && objParams.HasParam("playerNr") ){
                    if(objParams.GetString("game_type") == "versusBrawl" ){
                        objTemp.SetEnabled(true);
                    }
                }
            }
        }
    }

    UpdateUI();
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
    ResetRace();
}   

void ResetRace(){
    Log(error, "ResetRace");
    raceInit = true;
    pointsTextShow = true;
    dead = {false, false, false, false};
    // We set the timer lower, for those `Nobody wins` cases
    winStateTime = loadedWinStateTime / 3;
    
    pointsCount = {0,0,0,0};
    updateScores = true;
    if(!onlyOneLife)
        constantRespawning = true;
}