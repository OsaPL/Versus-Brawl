#include "versusmode.as"
// ^^ only this is needed
#include "versus-brawl/pointUIBase.as"

int teamAttacking = 2;
// Phase zero means start loaction
int currentPhase = 0;
// -1 means none are open to go through
int openPhase = -1;
// TODO! Add a rotation queue of weapons
// dual daggers, spear, big sword, rapier, staff?
array<string> weaponQueue = {""};
array<int> currentWeaponQueuesIndexes = {0, 0, 0, 0};
bool updatePhases = false;

//Level methods
void Init(string msg){
    useGenericSpawns = false;
    useSingleSpawnType = true;
    constantRespawning = true;
    teamPlay = true;
    teamsAmount = 2;
    allowUneven = false;
    suicideTime = 1;

    // pointUIBase configuration
    diffToCloseBlinking = 0;
    pointsToWin = 1;
    pointsTextFormat = "@points@";
    playingToTextFormat = "Last phase: @points@!";
    
    //Always need to call this first!
    VersusInit("");

    levelTimer.Add(LevelEventJob("reset", function(_params){
        ResetNidhogg();
        return true;
    }));

    // And finally load JSON Params
    LoadJSONLevelParams();
}

void ResetNidhogg(){
    teamAttacking = 2;
    currentPhase = 0;
    pointsCount = {0, 0, 0, 0};
    updatePhases = true;
    updateScores = true;
}

void DrawGUI() {
    //Always need to call this first!
    VersusDrawGUI();
}

float timer = 0;
void Update(){
    //Always need to call this first!
    VersusUpdate();

    // TODO! The params that need to be shared with phase hotspots should be also put into levelParams
    if(currentState >= 2 && currentState < 100) {
        timer += time_step;
        if (GetInputPressed(0, "grab")) {
            teamAttacking = 1;
            currentPhase--;
            openPhase = currentPhase;
            if (currentPhase == 0)
                openPhase--;
            pointsCount[0] = pointsCount[0] - 1;
            pointsCount[1] = pointsCount[1] + 1;
            updatePhases = true;
            updateScores = true;
        }
        if (GetInputPressed(0, "attack")) {
            teamAttacking = 0;
            currentPhase++;
            openPhase = currentPhase;
            if (currentPhase == 0)
                openPhase++;
            pointsCount[0] = pointsCount[0] + 1;
            pointsCount[1] = pointsCount[1] - 1;
            updatePhases = true;
            updateScores = true;
        }
        if (GetInputPressed(0, "crouch")) {
            teamAttacking = 2;
            openPhase = -1;
            updatePhases = true;
        }
    }

    Log(error, "currentPhase: " + currentPhase );
    Log(error, "openPhase: " + openPhase );
    
    // UI
    if(currentState > 1 && currentState < 100 && updatePhases) {
        //TODO! Build a prettier UI for the progress thingy
        vec3 color = GetTeamUIColor(teamAttacking);
        string map = "";
        for (int i = -pointsToWin; i < pointsToWin + 1; i++)
        {
            if (i == currentPhase) {
                map += "v";
            } else {
                map += "_";
            }
        }
        versusAHGUI.SetMainText(map, color);
        updatePhases = false;
    }
    
    if(currentState > 1 && currentState < 100){
        if(pointsCount[0] > pointsToWin ){
            winnerNr = 0;
            ChangeGameState(100);
            constantRespawning = false;
            PlaySound("Data/Sounds/versus/fight_end.wav");
            ResetNidhogg();
        }
        else if(pointsCount[1] > pointsToWin){
            winnerNr = 1;
            ChangeGameState(100);
            constantRespawning = false;
            PlaySound("Data/Sounds/versus/fight_end.wav");
            ResetNidhogg();
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
    ResetNidhogg();
}
