#include "versusmode.as"
// ^^ only this is needed
#include "versus-brawl/pointUIBase.as"

//Configurables

//State

//Level methods
void Init(string msg){
    // Race specific hints
    //Remove first 3, cause you cant change species here
    warmupHints.removeAt(0);
    warmupHints.removeAt(0);
    warmupHints.removeAt(0);
    warmupHints.insertAt(0, "You need to get all the checkpoints, order doesnt matter.");
    randomHints.insertAt(0, "No rules, dont feel bad for hitting people.");
    
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
        return true;
    }));

    // And finally load JSON Params
    LoadJSONLevelParams();
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

        ScriptParams@ lvlParams = level.GetScriptParams();
        lvlParams.SetInt("InProgress", 1);

        for (uint k = 0; k < versusPlayers.size(); k++)
        {
            VersusPlayer@ player = GetPlayerByNr(k);
            //Checks for win
            if(pointsCount[player.playerNr]>=checkPointsNeeded){
                // 3 is win state
                winnerNr = player.playerNr;
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
        }
    }
    
    if(currentState == 100){
        if(winStateTimer>winStateTime){
            // Now we just need to reset few things
            pointsCount = {0,0,0,0};
            constantRespawning = true;
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