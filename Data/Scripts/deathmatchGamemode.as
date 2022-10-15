#include "versusmode.as"
// ^^ only this is needed

// Conficurables
int pointsToWin = 3;
float winStateTime = 10;

// States
bool initUI=true;
bool updateScores=false;
array<int> killsCount = {0,0,0,0};
float winStateTimer = 0;
int winnerId = -1;

//Level methods
void Init(string msg){
    constantRespawning = true;
    
    //Always need to call this first!
    VersusInit("");

    Log(error, "Adding oneKilledByTwo handler");
    levelTimer.Add(LevelEventJob("oneKilledByTwo", function(_params){
        if(currentState>=2){
            Log(error, "Player "+_params[1]+" was killed by player "+_params[2]);
            for (uint k = 0; k < spawned_object_ids.size(); k++)
            {
                if(spawned_object_ids[k] == parseInt(_params[2])){
                    killsCount[k]++;
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


void Update(){
    //Always need to call this first!
    VersusUpdate();

    if(GetInputPressed(0, "F3")){
        killsCount[0]++;
        killsCount[2]++;
        updateScores=true;
    }

    //time += time_step;
    if(time>3.0){
        for (uint i = 0; i < 4; i++) {
            MovementObject@ char = ReadCharacter(i);
            Log(error, "Player "+i+" targets player "+char.GetIntVar("target_id"));
            Log(error, "Player "+i+" is attacked by player "+char.GetIntVar("attacked_by_id"));
        }
        time = 0;
    }
    
    if(currentState == 2){
        for (uint i = 0; i < killsCount.size(); i++) {
            if(pointsToWin <= killsCount[i]){
                // 3 is win state
                currentState = 3;
                constantRespawning = false;
                PlaySound("Data/Sounds/versus/fight_end.wav");
                versusAHGUI.SetText(""+IntToColorName(i)+" wins!","");
            }
        }
    }

    if(currentState == 3){
        winStateTimer += time_step;

        if(winStateTimer>winStateTime){
            // Now we just need to reset few things
            winStateTimer = 0;
            currentState = 2;
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

    TokenIterator token_iter;
    token_iter.Init();
    
    
    if(token_iter.FindNextToken(msg))
        return;
    string char_a = atoi(token_iter.GetToken(msg));
    
    if(token_iter.FindNextToken(msg))
        return;
    string char_b = atoi(token_iter.GetToken(msg));
    
    //TODO: find out all events and correlate them
    
    Log(error, "ReceiveMessage \""+ msg + "\"");
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
        for (int i = 0; i < 4; i++) {
            Log(error, "initUI");

            AHGUI::Element@ headerElement = versusAHGUI.root.findElement("header"+i);
            AHGUI::Divider@ div = cast<AHGUI::Divider>(headerElement);
            
            uiKillCounters.push_back(@AHGUI::Text(""+killsCount[i], "OpenSans-Regular", 50, 1, 1, 1, 1 ));

            uiKillCountersDivs.push_back(@div.addDivider( DDCenter,  DOVertical, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE)));
            uiKillCountersDivs[i].addElement(uiKillCounters[i],DDCenter);

            uiKillCountersDivs[i].setBorderSize(4);
            uiKillCountersDivs[i].setBorderColor(0.0, 1.0, 1.0, 1.0);
            uiKillCountersDivs[i].showBorder();
        }
        
        initUI = false;
    }
    
    if(updateScores){
        Log(error, "updateScores");

        for (uint i = 0; i < uiKillCounters.size(); i++)
        {
            uiKillCounters[i].setText("" + killsCount[i]);
        }

        // killCounterDiv.clear();
        // killCounterDiv.clearUpdateBehaviors();
        // killCounterDiv.setDisplacement();

        updateScores=false;
    }
}