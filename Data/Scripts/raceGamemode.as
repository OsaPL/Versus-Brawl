#include "versusmode.as"
// ^^ only this is needed

//Configurables
float suicideTime = 1;
int forcedSpeciesType = 2;
int checkPointNeeded = 2;
float winStateTime = 10;

//State
array<float> suicideTimers = {0,0,0,0};
array<int> checkpointReached = {0,0,0,0};
float winStateTimer = 0;
int winnerNr = -1;

//Level methods
void Init(string msg){
    //We setup the parameters before init call
    useGenericSpawns = true;
    useSingleSpawnType = false;
    constantRespawning = true;
    blockSpeciesChange = true;
    respawnTime = 1;

    //Always need to call this first!
    VersusInit("");

    //TODO! Adding some level parameters
    ScriptParams@ lvlParams = level.GetScriptParams();
    if(!lvlParams.HasParam("Poo"))
        lvlParams.SetString("Poo", "Yes");
    
    lvlParams.SetInt("InProgress", 0);

    levelTimer.Add(LevelEventJob("checkpoint", function(_params){
        Log(error, "Received checkpoint "+_params[1]);
        checkpointReached[parseInt(_params[1])]++;
        return true;
    }));
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
        
        // Suicide check
        for (uint k = 0; k < versusPlayers.size(); k++)
        {
            VersusPlayer@ player = GetPlayerByNr(k);
            if (GetInputDown(player.playerNr, "attack") && GetInputDown(player.playerNr, "grab")) {
                suicideTimers[player.playerNr] += time_step;
                if(suicideTimers[player.playerNr]>suicideTime){
                    ReadCharacterID(player.objId).Execute("CutThroat();");
                    suicideTimers[player.playerNr] = 0;
                }
            } else {
                suicideTimers[player.playerNr] = 0;
            }
           
        }

        for (uint k = 0; k < versusPlayers.size(); k++)
        {
            VersusPlayer@ player = GetPlayerByNr(k);
            //Checks for win
            if(checkpointReached[player.playerNr]>=checkPointNeeded){
                // 3 is win state
                ChangeGameState(3);
                
                //GENERIC
                constantRespawning = false;
                PlaySound("Data/Sounds/versus/fight_end.wav");
                versusAHGUI.SetText(""+IntToColorName(player.playerNr)+" wins!","");
                
                // Buff the winner?
                winnerNr = player.playerNr;

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
    
    if(currentState == 3){
        winStateTimer += time_step;
        
        if(winStateTimer>=winStateTime){
            // Now we just need to reset few things
            winStateTimer = 0;
            ChangeGameState(2);
            checkpointReached = {0,0,0,0};
            constantRespawning = true;
            versusAHGUI.SetText("","");
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
            
            // And now reset level
            level.SendMessage("reset");
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