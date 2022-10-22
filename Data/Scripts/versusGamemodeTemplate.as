#include "versusmode.as"
// ^^ only this is needed

//Level methods
void Init(string msg){
    //Always need to call this first!
    VersusInit("");
}

void SetParameters()
{
    //Always need to call this first!
    VersusSetParameters();
}

void DrawGUI() {
    //Always need to call this first!
    VersusDrawGUI();
}

void Update(){
    //Always need to call this first!
    VersusUpdate();
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
