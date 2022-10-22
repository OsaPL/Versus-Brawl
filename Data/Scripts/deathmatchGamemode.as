#include "versusmode.as"
// ^^ only this is needed

// Configurables
int pointsToWin = 3;
float winStateTime = 10;

// States
bool initUI=true;
bool updateScores=false;
array<int> killsCount = {0,0,0,0};
float winStateTimer = 0;
int winnerId = -1;

array<string> insults = {
    "For sure not thanks to always hogging all the weapons...",
    "ez, gg no re",
    "Maybe you should try Tai Chi instead."
};

//Level methods
void Init(string msg){
    constantRespawning = true;
    useGenericSpawns = true;
    useSingleSpawnType = false;
    //Always need to call this first!
    VersusInit("");

    Log(error, "Adding oneKilledByTwo handler");
    levelTimer.Add(LevelEventJob("oneKilledByTwo", function(_params){
        if(currentState>=2){
            Log(error, "Player "+_params[1]+" was killed by player "+_params[2]);
            for (uint k = 0; k < versusPlayers.size(); k++)
            {
                VersusPlayer@ player = GetPlayerByNr(k);
                if(player.objId == parseInt(_params[2])){
                    killsCount[player.playerNr]++;
                    updateScores = true;
                }
            }
        }
        return true;
    }));
}

void DrawGUI() {
    //Always need to call this first!
    VersusDrawGUI();
}

float time = 0;
bool pointsTextShow = true;
float pointsTextShowTime = 7.0f;

void Update(){
    //Always need to call this first!
    VersusUpdate();

    if(GetInputPressed(0, "F3")){
        killsCount[0]++;
        killsCount[2]++;
        updateScores=true;
    }
    
    if(currentState == 2){
        
        if(pointsTextShow){
            pointsTextShow = false;
            versusAHGUI.SetText("Playing to: "+pointsToWin+" kills!");
        }
        else{
            if(time>pointsTextShowTime){
                versusAHGUI.SetText("");
            }
            else{
                time += time_step;
            }
        }
        for (uint i = 0; i < killsCount.size(); i++) {
            if(pointsToWin <= killsCount[i]){
                // 3 is win state
                ChangeGameState(3);
                constantRespawning = false;
                PlaySound("Data/Sounds/versus/fight_end.wav");
                versusAHGUI.SetText(""+IntToColorName(i)+" wins!",insults[rand()%insults.size()], GetTeamUIColor(i));
            }
        }
    }

    // TODO! This "win state" could be generic
    if(currentState == 3){
        winStateTimer += time_step;
        
        if(winStateTimer>winStateTime){
            // Now we just need to reset few things
            winStateTimer = 0;
            time = 0;
            pointsTextShow = true;
            ChangeGameState(2);
            killsCount = {0,0,0,0};
            updateScores = true;
            constantRespawning = true;
            versusAHGUI.SetText("","");
            ScriptParams@ lvlParams = level.GetScriptParams();

            // And now reset level
            level.SendMessage("reset");
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

}

array<AHGUI::Divider@> uiKillCountersDivs={};
array<AHGUI::Text@> uiKillCounters={};

void UpdateUI(){
    // TODO! Probably would be cooler to use Textures\ui\arena_mode icons to count deaths
    
    if(initUI){
        for (uint i = 0; i < versusPlayers.size(); i++) {
            Log(error, "initUI");

            AHGUI::Element@ headerElement = versusAHGUI.root.findElement("header"+i);
            AHGUI::Divider@ div = cast<AHGUI::Divider>(headerElement);
            
            uiKillCounters.push_back(@AHGUI::Text("Kills: "+killsCount[i], "edosz", 65, 1, 1, 1, 1 ));

            uiKillCountersDivs.push_back(@div.addDivider( DDCenter,  DOVertical, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE)));
            uiKillCountersDivs[i].addElement(uiKillCounters[i],DDCenter);

            uiKillCountersDivs[i].setBorderSize(4);
            uiKillCountersDivs[i].setBorderColor(0.0, 1.0, 1.0, 1.0);
            //uiKillCountersDivs[i].showBorder();
        }
        
        initUI = false;
    }
    
    if(updateScores){
        Log(error, "updateScores");

        for (uint i = 0; i < uiKillCounters.size(); i++)
        {
            uiKillCounters[i].setText("Kills: " + killsCount[i]);
        }

        updateScores=false;
    }
}