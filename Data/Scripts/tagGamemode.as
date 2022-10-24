#include "versusmode.as"
// ^^ only this is needed

// Configurables
// How long does a round takes
float roundMaxTime = 60;
// For how long freeze the chasers on spawn
float freezeTime = 2;
// Dying as runner switches to Chasers, if `false` just a direct hit is enough
bool deathsChangesToChasers = false;
// Killing a Chaser respawns him as Runner, if `false` they just respawn
bool killsChangesToRunners = false;
// These two only work if `blockSpeciesChange==true`, otherwise player can just switch off to another
int chaserSpecies = _cat;
int runnerSpecies = _rat;
// Bigger team wins on timeout, if `false` chasers win when there are no more runners.
bool biggerTeamWins = false;

// States
array<bool> currentChasers = { false, false, false, false };
array<float> freezeTimers = { 0, 0, 0, 0 };
array<bool> isFreezed = { false, false, false, false };
array<int> freezeEmmiters = { -1, -1, -1, -1 };
float timer = 0;
bool initUI = true;
bool updateChaserRunnerLabels = false;

//Level methods
void Init(string msg){
    forcedSpecies = _rat;
    blockSpeciesChange = true;
    //Always need to call this first!
    VersusInit("");
    
    //Select a random chaser
    int firstChaserNr = 0;//rand()%currentChasers.size();
    SetChaser(firstChaserNr);
    
    //Make the rest a runner
    for (uint i = 0; i < versusPlayers.size(); i++) {
        if(i != uint(firstChaserNr))
            SetRunner(i);
    }

    // Adds tag mechanics 
    levelTimer.Add(LevelEventJob("bluntHit", function(_params){
        Log(error, "bluntHit: "+ _params[1]+ " " +_params[2]);

        VersusPlayer@ victim = GetPlayerByObjectId(parseInt(_params[1]));
        VersusPlayer@ attacker = GetPlayerByObjectId(parseInt(_params[2]));
        
        if(!currentChasers[victim.playerNr] && currentChasers[attacker.playerNr]){
            // Change team, if hit by 
            SetChaser(victim.playerNr);
        }

        Object@ VcharObj = ReadObjectFromID(victim.objId);
        ScriptParams@ VcharParams = VcharObj.GetScriptParams();
        Object@ AcharObj = ReadObjectFromID(attacker.objId);
        ScriptParams@ AcharParams = AcharObj.GetScriptParams();

        Log(error, "teams victim: " + VcharParams.GetString("Teams") + " attacker:" + AcharParams.GetString("Teams"));
        
        return true;
    }));
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
    
    if(currentState <= 2){
        timer += time_step;
        //Check if Chasers won
        bool allChasers = true;
        for (uint i = 0; i < currentChasers.size(); i++) {
            if(!currentChasers[i])
                allChasers = false;
        }
        
        if(allChasers){
            // TODO! Chasers win
            for (uint i = 0; i < freezeTimers.size(); i++)
            {
                freezeTimers[i] = -1    ;
            }
            ChangeGameState(3);
        }
        
        // Timeout
        if(timer > roundMaxTime){
            if(biggerTeamWins){
                int chasers = 0;
                int runners = 0;
                for (uint i = 0; i < currentChasers.size(); i++)
                {
                    if(currentChasers[i]){
                        chasers++;
                    }
                    else{
                        runners++;
                    }
                }
                
                if(chasers == runners){
                    // TODO! Draw
                }
                else if(chasers > runners){
                    // TODO! Chasers win
                }
                else{
                    // TODO! Runners win
                }
            }
        }

        // Unfreeze
        Log(error, "freezeTimers[3]: " + freezeTimers[3] + "isFreezed[3]: "+isFreezed[3]);

        for (uint i = 0; i < freezeTimers.size(); i++) 
        {
            if(freezeTimers[i]< 0 && isFreezed[i]){
                VersusPlayer@ victim = GetPlayerByNr(i);
                Log(error, "unfreeze: "+ victim.playerNr);

                // Remove the emitter
                if(freezeEmmiters[i] != -1)
                    DeleteObjectID(freezeEmmiters[i]);
                freezeEmmiters[i] = -1;
                
                addSpeciesStats(ReadObjectFromID(victim.objId));
                isFreezed[i] = false;
                updateChaserRunnerLabels = true;
                
            }else if(freezeTimers[i]>= 0 && isFreezed[i]){
                freezeTimers[i] -= time_step;
            }
        }
    }
    
    // Win state
    if(currentState == 3){
        
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

array<AHGUI::Divider@> uiLabelsDivs={};
array<AHGUI::Text@> uiLabels={};

void UpdateUI(){
    // TODO! Probably would be cooler to use Textures\ui\arena_mode icons to count deaths

    if(initUI){
        for (uint i = 0; i < versusPlayers.size(); i++) {
            Log(error, "initUI");

            AHGUI::Element@ headerElement = versusAHGUI.root.findElement("header"+i);
            AHGUI::Divider@ div = cast<AHGUI::Divider>(headerElement);
            AHGUI::Text textElem;
            if(currentChasers[i]){
                vec3 uiChaserColor = GetTeamUIColor(1);
                textElem = AHGUI::Text("Chaser", "edosz", 65, uiChaserColor.x, uiChaserColor.y, uiChaserColor.z, 1 );
            }
            else{
                vec3 uiRunnerColor = GetTeamUIColor(0);
                textElem = AHGUI::Text("Runner", "edosz", 65, uiRunnerColor.x, uiRunnerColor.y, uiRunnerColor.z, 1 );
            }
            
            textElem.setShadowed(true);

            uiLabels.push_back(textElem);

            uiLabelsDivs.push_back(@div.addDivider( DDCenter,  DOVertical, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE)));
            uiLabelsDivs[i].addElement(uiLabels[i],DDCenter);

            uiLabelsDivs[i].setBorderSize(4);
            uiLabelsDivs[i].setBorderColor(0.0, 1.0, 1.0, 1.0);
            //uiKillCountersDivs[i].showBorder();
        }

        initUI = false;
    }

    if(updateChaserRunnerLabels){
        Log(error, "updateChaserRunnerLabels");

        for (uint i = 0; i < uiLabels.size(); i++)
        {
            if(currentChasers[i]){
                if(isFreezed[i]){
                    Log(error, "updateChaserRunnerLabels freeze");
                    vec3 uiFreezedChaserColor = GetTeamUIColor(2);
                    uiLabels[i].setColor(vec4(uiFreezedChaserColor, 1.0f));
                    uiLabels[i].setText("Freezed Chaser");
                }
                else{
                    Log(error, "updateChaserRunnerLabels unfreeze");
                    vec3 uiChaserColor = GetTeamUIColor(1);
                    uiLabels[i].setColor(vec4(uiChaserColor, 1.0f));
                    uiLabels[i].setText("Chaser");
                }
            }
            else{
                vec3 uiRunnerColor = GetTeamUIColor(0);
                uiLabels[i].setColor(vec4(uiRunnerColor, 1.0f));
                uiLabels[i].setText("Runner");
            }
        }

        updateChaserRunnerLabels=false;
    }
}

void SetChaser(int playerNr){

    VersusPlayer@ victim = GetPlayerByNr(playerNr);
    
    currentChasers[playerNr] = true;
    
    victim.currentRace = chaserSpecies;
    RerollCharacter(victim.playerNr, ReadObjectFromID(victim.objId));

    //TODO: Freeze chaser
    Object@ charObj = ReadObjectFromID(victim.objId);
    ScriptParams@ charParams = charObj.GetScriptParams();
    charParams.SetString("Teams", "chasers");
    charParams.SetFloat("Attack Speed",     0.1f);
    charParams.SetFloat("Movement Speed",   0.0f);
    charParams.SetFloat("Jump - Initial Velocity",    0.1f);
    charParams.SetFloat("Jump - Air Control",         0.1f);
    charParams.SetFloat("Jump - Jump Sustain",        0.1f);
    charParams.SetFloat("Jump - Jump Sustain Boost",  0.1f);
    charObj.UpdateScriptParams();

    freezeTimers[playerNr] = freezeTime;
    isFreezed[playerNr] = true;
    updateChaserRunnerLabels = true;

    // Create a freezeEmmiter
    int emitterId = CreateObject("Data/Objects/powerups/objectFollowerEmitter.xml");
    freezeEmmiters[playerNr] = emitterId;
    Object@ obj = ReadObjectFromID(emitterId);
    ScriptParams@ objParams = obj.GetScriptParams();
    objParams.SetInt("objectIdToFollow", victim.objId);
    objParams.SetFloat("particleDelay", 0.005f);
    objParams.SetFloat("particleRangeMultiply", 1.0f);
    objParams.SetString("pathToParticles", "Data/Particles/smoke.xml");
    objParams.SetFloat("particleColorR", 0.6f);
    objParams.SetFloat("particleColorG", 0.6f);
    objParams.SetFloat("particleColorB", 0.9f);
    

    Log(error, "SetChaser: "+ playerNr + " teams: " + charParams.GetString("Teams"));
}

void SetRunner(int playerNr){

    VersusPlayer@ victim = GetPlayerByNr(playerNr);

    currentChasers[playerNr] = false;

    victim.currentRace = runnerSpecies;
    RerollCharacter(victim.playerNr, ReadObjectFromID(victim.objId));
    
    addSpeciesStats(ReadObjectFromID(victim.objId));

    Object@ charObj = ReadObjectFromID(victim.objId);
    ScriptParams@ charParams = charObj.GetScriptParams();
    charParams.SetString("Teams", "runners");
    charObj.UpdateScriptParams();
    
    isFreezed[playerNr] = false;
    updateChaserRunnerLabels = true;

    Log(error, "SetRunner: "+ playerNr + " teams: " + charParams.GetString("Teams"));
}