#include "versusmode.as"
// ^^ only this is needed

//Level methods
void Init(string msg){
    //Always need to call this first!
    VersusInit("");

    // Your code between

    // And finally load JSON Params
    LoadJSONLevelParams();
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
