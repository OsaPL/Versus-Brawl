#include "versusmode.as"
// ^^ only this is needed

// Configurables
int pointsToWin = 3;
bool pointsTextShow = true;
float pointsTextShowTime = 7.0f;

// States
bool initUI=true;
bool updateScores=false;
array<int> killsCount = {0,0,0,0};
float pointsTextShowTimer = 0;

//Level methods
void Init(string msg){
    constantRespawning = true;
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

void SetParameters() {
    //Always need to call this first!
    VersusSetParameters();

    // params.AddInt("DeathMatch - PointsToWin", pointsToWin);
    // params.AddFloatSlider("DeathMatch - PointsTextShowTime", pointsTextShowTime, "min:0,max:60,step:0.1");
}

void DrawGUI() {
    //Always need to call this first!
    VersusDrawGUI();
}

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
            if(pointsTextShowTimer>pointsTextShowTime){
                versusAHGUI.SetText("");
            }
            else{
                pointsTextShowTimer += time_step;
            }
        }
        for (uint i = 0; i < killsCount.size(); i++) {
            if(pointsToWin <= killsCount[i]){
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
            pointsTextShow = true;
            pointsTextShowTimer = 0;
            killsCount = {0,0,0,0};
            updateScores = true;
            constantRespawning = true;
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

            AHGUI::Text textElem("Kills: "+killsCount[i], "edosz", 65, 1, 1, 1, 1 );
            textElem.setShadowed(true);
            
            uiKillCounters.push_back(textElem);

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