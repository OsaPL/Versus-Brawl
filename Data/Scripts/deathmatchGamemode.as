#include "versusmode.as"
// ^^ only this is needed

// States
bool initUI=true;
bool updateScores=false;
array<int> killsCount = {0,0,0,0};


//Level methods
void Init(string msg){
    //Always need to call this first!
    VersusInit("");
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
        updateScores=true;
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

AHGUI::Divider@ killCounterDiv;
AHGUI::Text@ singleSentence;
void UpdateUI(){
    // TODO! Probably would be cooler to use Textures\ui\arena_mode icons to count deaths
    AHGUI::Element@ headerElement = versusAHGUI.root.findElement("header0");
    AHGUI::Divider@ div = cast<AHGUI::Divider>(headerElement);
    
    if(initUI){
        Log(error, "initUI");
        @singleSentence = @AHGUI::Text(""+killsCount[0], "OpenSans-Regular", 50, 1, 1, 1, 1 );
        singleSentence.setName("killsCounter0");
        
        @killCounterDiv = @div.addDivider( DDCenter,  DOVertical, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );
        killCounterDiv.addElement(singleSentence,DDCenter);

        killCounterDiv.setBorderSize(4);
        killCounterDiv.setBorderColor(0.0, 1.0, 1.0, 1.0);
        killCounterDiv.showBorder();
        
        initUI = false;
    }
    
    if(updateScores){
        Log(error, "updateScores");

        singleSentence.setText(""+killsCount[0]);

        // killCounterDiv.clear();
        // killCounterDiv.clearUpdateBehaviors();
        // killCounterDiv.setDisplacement();

        updateScores=false;
    }
}