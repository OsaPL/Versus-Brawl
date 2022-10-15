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
int winnerId = -1;

//Level methods
void Init(string msg){
    //We setup the parameters before init call
    constantRespawning = true;
    blockSpeciesChange = true;
    respawnTime = 1;
    for (uint i = 0; i < currentRace.size() ; i++) {
        currentRace[i] = forcedSpeciesType;
    }

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
        for(int i=0; i<GetNumCharacters(); i++)
        {
            if (GetInputDown(i, "attack") && GetInputDown(i, "grab")) {
                suicideTimers[i] += time_step;
                Log(error, "suicideTimers "+i+": "+suicideTimers[i]); 
                if(suicideTimers[i]>suicideTime){
                    MovementObject@ mo = ReadCharacter(i);
                    mo.Execute("CutThroat();");
                    suicideTimers[i] = 0;
                }
            } else {
                suicideTimers[i] = 0;
            }
           
        }

        for(uint i=0; i<checkpointReached.size(); i++)
        {
            //Checks for win
            if(checkpointReached[i]>=checkPointNeeded){
                // 3 is win state
                currentState = 3;
                constantRespawning = false;
                PlaySound("Data/Sounds/versus/fight_end.wav");
                versusAHGUI.SetText(""+IntToColorName(i)+" wins!","");

                for(int j=0; j<GetNumCharacters(); j++)
                {
                    MovementObject@ mo = ReadCharacter(j);
                    Object@ objTemp = ReadObjectFromID(mo.GetID());
                    ScriptParams@ params = objTemp.GetScriptParams();
                    
                    if(j != int(i)){
                        // Weaken the losers
                        mo.Execute("TakeBloodDamage(0.6);");
                        params.SetFloat("Attack Damage",    0.0); //params.AddFloatSlider("Attack Damage", 1, "min:0,max:2,step:0.1,text_mult:100");
                        // Heheh yeet slap
                        params.SetFloat("Attack Knockback", 5.0); //params.AddFloatSlider("Attack Knockback", 1, "min:0,max:2,step:0.1,text_mult:100");
                        params.SetFloat("Attack Speed",     0.2); //params.AddFloatSlider("Attack Speed", 1, "min:0,max:2,step:0.1,text_mult:100");
                        params.SetFloat("Damage Resistance",0.2); //params.AddFloatSlider("Damage Resistance", 1, "min:0,max:2,step:0.1,text_mult:100");
                        params.SetFloat("Movement Speed",   0.1); //params.AddFloatSlider("Movement Speed", 1, "min:0.1,max:1.5,step:0.1,text_mult:100");
                    }
                    else{
                        // Buff the winner?
                        winnerId = objTemp.GetID();
                    }
                    objTemp.UpdateScriptParams();
                }
                break;
            }
        }
    }
    
    if(currentState == 3){
        winStateTimer += time_step;

        //Ninja mode, this probably needs to be extracted into a powerup
        MovementObject@ mo = ReadCharacterID(winnerId);
        int weapon = mo.GetArrayIntVar("weapon_slots",mo.GetIntVar("primary_weapon_slot"));
        if(weapon == -1) {
            int knifeId = CreateObject("Data/Items/rabbit_weapons/rabbit_knife.xml");
            mo.Execute("AttachWeapon(" + knifeId + ");");
        }
        
        if(winStateTimer>winStateTime){
            // Now we just need to reset few things
            winStateTimer = 0;
            currentState = 2;
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