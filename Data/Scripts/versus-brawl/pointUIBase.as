// This is a simple pointsUI I can use generally for any point based modes

// These can be manipulated dynamically
// Defines the amount of point that are considered to be "almost winning" and start blinking
int diffToCloseBlinking = 1;
// Text format `@points@` is used as point value placeholder
string pointsTextFormat = "Points: @points@";
string playingToTextFormat = "Playing to: @points@ points!";
float blinkTimeout = 1;
float pointsTextShowTime = 5;
int pointsToWin = 3;
// This controls whether to automatically decide the winner based on the points
bool decideWinner = true;

// TODO: These probably should be their own methods instead of setting them by hand
bool pointsTextShow = true;
bool updateScores = false;


// For UI states
bool initUI = true;
bool blink = false;
float blinkTimer = 0;
float pointsTextShowTimer = 0;

array<AHGUI::Divider@> uiPointsCountersDivs={};
array<AHGUI::Text@> uiPointsCounters={};
array<int> pointsCount = {};
uint teamsToGoThrough = 0;

string AddPointsText(string text, int points, bool addPointsNeeded = false){
    string converted = text;
    for( uint i = 0; i < converted.length(); i++ ) {
        if( text[i] == '@'[0] ) {
            for( uint j = i + 1; j < converted.length(); j++ )
            {
                if (text[j] == '@'[0]) {
                    string input = converted.substr(i+1,j-i-1);
                    if(input == "points"){
                        string first_half = converted.substr(0,i);
                        string second_half = converted.substr(j+1);
                        if(addPointsNeeded)
                            second_half = " / " + pointsToWin + second_half;
                        converted = first_half + points + second_half;
                    }
                }
            }
        }
    }
    return converted;
}

void UpdateUI(){

    if(initUI){
        teamsToGoThrough = versusPlayers.size();
        if(teamPlay)
            teamsToGoThrough = teamsAmount;
        
        InitUI();
        initUI = false;
    }
    
    // Check if suicide timers array is too small
    if(pointsCount.size() < versusPlayers.size()){
        int toAdd = versusPlayers.size() - pointsCount.size();

        Log(error, "pointsCount too small! Adding more: " + pointsCount.size() + " => " + versusPlayers.size() + " ++" + toAdd);
        for (uint j = 0; j < toAdd; j++)
        {
            pointsCount.push_back(0);
        }
    }

    if(currentState >= 2 && currentState < 100) {
        if (pointsTextShow) {
            pointsTextShowTimer = 0;
            pointsTextShow = false;
            versusAHGUI.SetMainText(AddPointsText(playingToTextFormat, pointsToWin));
        } else {
            //  Log(error, "pointsTextShow false pointsTextShowTimer: " + pointsTextShowTimer);
            if (pointsTextShowTimer > pointsTextShowTime && versusAHGUI.text == AddPointsText(playingToTextFormat, pointsToWin)) { 
                versusAHGUI.SetMainText("");
            } else {
                pointsTextShowTimer += time_step;
            }
        }
    }
    
    // TODO! Probably would be cooler to use Textures\ui\arena_mode icons to count deaths
    blinkTimer += time_step;
    if(blinkTimer > blinkTimeout){
        blink = !blink;

        for (uint i = 0; i < uiPointsCounters.size(); i++)
        {
            if(pointsCount[i] + diffToCloseBlinking >= pointsToWin){
                // B link red for almost win
                if(blink){
                    uiPointsCounters[i].setColor(1, 0.3f, 0, 1);
                }
                else{
                    uiPointsCounters[i].setColor(1, 0.0f, 0, 1);
                }
            }
        }
        blinkTimer = 0;
    }

    if(updateScores && currentState >= 2 && currentState < 100){
        //Log(error, "updateScores");
        
        bool noHighest = true;
        for (uint i = 0; i < pointsCount.size(); i++)
        {
            bool playersUI = !GetPlayerByNr(i).isNpc;
            if(playersUI)
                uiPointsCounters[i].setText(AddPointsText(pointsTextFormat, pointsCount[i], true));

            bool isHighest = true;
            for (uint k = 0; k < pointsCount.size(); k++)
            {
                // We skip ourselves
                if(i == k)
                    continue;
                if(pointsCount[i] <= pointsCount[k]){
                    isHighest = false;
                    break;
                }
            }
            
            if(isHighest)
                noHighest = false;
            
            if(isHighest){
                // Orange for winner, chicken dinner
                if(playersUI)
                    uiPointsCounters[i].setColor(1, 0.7f, 0, 1);

                if(decideWinner)
                    winnerNr = i;
            }
            else{
                if(playersUI)
                    uiPointsCounters[i].setColor(1,1,1,1);
            }
        }
        
        if(noHighest){
            if(decideWinner)
                winnerNr = -1;
        }
        
        updateScores=false;
    }

    if(updateScores && currentState >= 100) {
        for (uint i = 0; i < pointsCount.size(); i++)
        {
            bool playersUI = !GetPlayerByNr(i).isNpc;
            if(playersUI)
                uiPointsCounters[i].setText(AddPointsText("", pointsCount[i], true));
        }
    }
}

void InitUI(){

    pointsCount = {};
    for (uint j = 0; j < versusPlayers.size(); j++)
    {
        pointsCount.push_back(0);
    }
    
    for (uint i = 0; i < teamsToGoThrough; i++) {
        // Max supported local player UIs
        if(GetPlayerByNr(i).isNpc) 
            return;
        
        Log(error, "initUI"+i);

        AHGUI::Element@ headerElement = versusAHGUI.root.findElement("header"+i);
        AHGUI::Divider@ div = cast<AHGUI::Divider>(headerElement);

        AHGUI::Text textElem(AddPointsText(pointsTextFormat, pointsCount[i], true), "edosz", 65, 1, 1, 1, 1 );
        textElem.setShadowed(true);

        uiPointsCounters.push_back(textElem);

        uiPointsCountersDivs.push_back(@div.addDivider( DDCenter,  DOVertical, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE)));
        uiPointsCountersDivs[i].addElement(uiPointsCounters[i],DDCenter);

        uiPointsCountersDivs[i].setBorderSize(4);
        uiPointsCountersDivs[i].setBorderColor(0.0, 1.0, 1.0, 1.0);
        //uiPointsCountersDivs[i].showBorder();
    }
}