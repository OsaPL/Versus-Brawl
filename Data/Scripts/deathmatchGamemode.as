#include "versusmode.as"
// ^^ only this is needed
#include "versus-brawl/pointUIBase.as"

// #2 is killfeed stuff, probably I need to seperate setText into setMainText(mainText,mainColor) and setSubText(subText,subColor)

// Configurables

// States

//Level methods
void Init(string msg){
    // DM specific hints
    warmupHints.insertAt(0, "Kills give points, duh.");
    warmupHints.insertAt(0, "You also get points for causing enemies clumsy deaths.");
    randomHints.insertAt(0, "Try changing species to counter someone else.");
    randomHints.insertAt(0, "Grabbing a weapon or a powerup could be the deciding factor.");
    randomHints.insertAt(0, "Two's company, three's a crowd, and fourth gets kills.");
    
    constantRespawning = true;
    forcedSpecies = -1;
    
    // pointUIBase configuration
    pointsToWin = 10;
    pointsTextFormat = "Kills: @points@";
    playingToTextFormat = "Playing to: @points@ kills!";
    
    //Always need to call this first!
    VersusInit("");

    loadCallbacks.push_back(@DeathmatchLoad);

    Log(error, "Adding oneKilledByTwo handler");
    levelTimer.Add(LevelEventJob("oneKilledByTwo", function(_params){
        if(currentState>=2 && currentState<100){
            Log(error, "Player "+_params[1]+" was killed by player "+_params[2]);
            for (uint k = 0; k < versusPlayers.size(); k++)
            {
                VersusPlayer@ player = GetPlayerByNr(k);
                if(player.objId == parseInt(_params[2])){
                    pointsCount[player.playerNr]++;
                    updateScores = true;
                    // TODO! Clean this up somehow to create a killfeed UI #2
                    // for (uint j = 0; j < versusPlayers.size(); j++)
                    // {
                    //     VersusPlayer@ playerVictim = GetPlayerByNr(j);
                    //     Log(error, "search for victim: " + _params[1] +" .objId: "+ playerVictim.objId + " .playerNr: " + playerVictim.playerNr + " ");
                    //     if(playerVictim.objId == parseInt(_params[1])) {
                    //         string killText = "" + IntToColorName(player.playerNr) + " x " + IntToColorName(playerVictim.playerNr);
                    //         Log(error, "FOUND! " + killText);
                    //        
                    //         versusAHGUI.SetText(killText, GetTeamUIColor(player.playerNr));
                    //         break;
                    //     }
                    // }
                    
                    break;
                }
            }
        }
        return true;
    }));

    levelTimer.Add(LevelEventJob("reset", function(_params) {
        ResetDM();
        return true;
    }));

    // And finally load JSON Params
    LoadJSONLevelParams();
}

void DeathmatchLoad(JSONValue settings) {
    Log(error, "DeathmatchLoad:");
    if(FoundMember(settings, "Deathmatch")) {
        JSONValue deathmatch = settings["Deathmatch"];
        Log(error, "Available: " + join(deathmatch.getMemberNames(),","));

        if (FoundMember(deathmatch, "PointsToWin"))
            pointsToWin = deathmatch["PointsToWin"].asInt();
        
        if (FoundMember(deathmatch, "PointsTextShowTime"))
            pointsTextShowTime = deathmatch["PointsTextShowTime"].asFloat();
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
        for (uint i = 0; i < pointsCount.size(); i++) {
            if(pointsToWin <= pointsCount[i]){
                // 100 is win state
                winnerNr = i;
                ChangeGameState(100);
                constantRespawning = false;
                PlaySound("Data/Sounds/versus/fight_end.wav");
            }
        }
    }

    if(currentState == 100){
        if(winStateTimer>=winStateTime){
            // Now we just need to reset few things
            ResetDM();
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
    ResetDM();
}

void ResetDM(){
    pointsTextShow = true;
    pointsCount = {0,0,0,0};
    updateScores = true;
    
    constantRespawning = true;
}