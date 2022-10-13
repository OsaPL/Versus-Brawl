#include "versusmode.as"
// ^^ only this is needed

//Configurables
float suicideTime = 1;
int forcedSpeciesType = 2;
int checkPointNeeded = 2;

//State
array<float> suicideTimers = {0,0,0,0};
array<int> checkpointReached = {0,0,0,0};

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
    ScriptParams@ params = level.GetScriptParams();
    if(!params.HasParam("Poo"))
        params.SetString("Poo", "Yes");
}

void DrawGUI() {
    //Always need to call this first!
    VersusDrawGUI();
}

void Update(){
    //Always need to call this first!
    VersusUpdate();

    if(currentState == 2){
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