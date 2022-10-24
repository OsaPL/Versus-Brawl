﻿#include "versusmode.as"
// ^^ only this is needed

// Configurables
// How long does a round takes
float roundMaxTime = 20;
// For how long freeze the chasers on spawn
float freezeTime = 3;
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
array<bool> killedRunners = { false, false, false, false };
array<bool> currentChasers = { false, false, false, false };
array<float> freezeTimers = { 0, 0, 0, 0 };
array<bool> isFreezed = { false, false, false, false };
array<int> freezeEmmiters = { -1, -1, -1, -1 };
float timer = 0;
int lastTimer = 0;
bool initUI = true;
bool updateChaserRunnerLabels = false;
bool start = true;

int whoWon = -1;
// 0=runner, 1=chasers, 3=draw
string IntToWinnerName(int teamNr){
    switch (teamNr) {
        case 0: return "Runners";
        case 1: return "Chasers";
        case 3: return "Nobody";
    }
    return "Error m8";
}

void ResetTag(){
    whoWon = -1;

    killedRunners = { false, false, false, false };
    currentChasers = { false, false, false, false };
    freezeTimers = { 0, 0, 0, 0 };
    isFreezed = { false, false, false, false };
    freezeEmmiters = { -1, -1, -1, -1 };
    timer = 0;
    lastTimer = 0;
    start = true;

    //Select a random chaser
    int firstChaserNr = rand()%currentChasers.size();
    SetChaser(firstChaserNr);

    for (uint i = 0; i < versusPlayers.size(); i++) {
        //Make the rest a runner
        if(i != uint(firstChaserNr))
            SetRunner(i);
    }

    Log(error, "Registered Reset");
    for (uint i = 0; i < versusPlayers.size(); i++) {
        VersusPlayer@ playerToAttach = versusPlayers[i];
        playerToAttach.charTimer.Add(CharDeathJob(playerToAttach.objId, function(char_a){
            // This should respawn on kill
            VersusPlayer@ player = GetPlayerByObjectId(char_a.GetID());
            if(currentState==2){
                // Runner death means, no respawn, but also not another catcher
                if(!currentChasers[player.playerNr]){
                    currentChasers[player.playerNr] = true;
                    killedRunners[player.playerNr] = true;
                    updateChaserRunnerLabels = true;
                }
                else{
                    // First check if its not an already dead runner
                    if(!killedRunners[player.playerNr]){
                        // Respawn if its the catcher
                        CallRespawn(player.playerNr, player.objId);   
                    }
                }
            }
            return true;
        }));
    }
    
    updateChaserRunnerLabels = true;
}

//Level methods
void Init(string msg){
    forcedSpecies = _rat;
    blockSpeciesChange = true;
    //Always need to call this first!
    VersusInit("");

    ResetTag();

    levelTimer.Add(LevelEventJob("reset", function(_params){
        ResetTag();
        return true;
    }));

    // Adds tag mechanics 
    levelTimer.Add(LevelEventJob("bluntHit", function(_params){
        Log(error, "bluntHit: "+ _params[1]+ " " +_params[2]);

        VersusPlayer@ victim = GetPlayerByObjectId(parseInt(_params[1]));
        VersusPlayer@ attacker = GetPlayerByObjectId(parseInt(_params[2]));

        if(!currentChasers[victim.playerNr] && currentChasers[attacker.playerNr] && currentState == 2){
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
    
    levelTimer.Add(LevelEventJob("spawned", function(_params){
        Log(error, "spawned: "+ _params[1]+ " " +_params[2]);

        VersusPlayer@ victim = GetPlayerByObjectId(parseInt(_params[1]));

        // Ugh, angelscript doesnt have something like parseBool(string)
        if(currentChasers[victim.playerNr] && currentState == 2 && _params[2] == "false"){
            // Freeze chaser on respawn
            Freeze(victim.playerNr);
        }

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
    
    if(currentState == 2){
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
            whoWon = 1;
            PlaySound("Data/Sounds/voice/animal3/voice_cat_attack_2.wav");
            ChangeGameState(101);
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
                    PlaySound("Data/Sounds/voice/lugaru/rabbit_chitter_1.wav");
                    whoWon = 3;
                }
                else if(chasers > runners){
                    // TODO! Chasers win
                    PlaySound("Data/Sounds/voice/animal3/voice_cat_attack_2.wav");
                    whoWon = 1;
                }
                else{
                    // TODO! Runners win
                    whoWon = 0;
                    PlaySound("Data/Sounds/voice/animal3/voice_rat_death_2.wav");
                }
            }
            else{
                // TODO! Runners win
                whoWon = 0;
                PlaySound("Data/Sounds/voice/animal3/voice_rat_death_2.wav");
                ChangeGameState(101);
            }
        }
        else{
            if(start) {
                lastTimer = int(freezeTime) - int(timer) - 1;
                Log(error, "lastTimer: " + lastTimer);
                if(lastTimer == 0){
                    versusAHGUI.SetText("Time left: "+lastTimer, "Get ready!", vec3(0.0f, 0.6f, 1.0f));
                }
                else if(lastTimer == -1){
                    start = false;
                    timer = 0;
                }    
                else{
                    versusAHGUI.SetText("Time left: "+lastTimer, "Hide or run now!", vec3(0.0f, 0.0f, 1.0f));
                }
            }
            else{
                if(int(roundMaxTime) - int(timer) != lastTimer){
                    lastTimer = int(roundMaxTime) - int(timer);
                    if(lastTimer <= 15 && lastTimer%2==0){
                        versusAHGUI.SetText("Time left: "+lastTimer, "", vec3(1.0f, 0.5f, 0.0f));
                    }
                    else if(lastTimer <= 5) {
                        versusAHGUI.SetText("Time left: "+lastTimer, "", vec3(1.0f, 0.0f, 0.0f));
                    }
                    else{
                        versusAHGUI.SetText("Time left: "+lastTimer);
                    }
                }
            }
        }

        // Unfreeze
        //Log(error, "freezeTimers[3]: " + freezeTimers[3] + "isFreezed[3]: "+isFreezed[3]);

        for (uint i = 0; i < freezeTimers.size(); i++) 
        {
            if(freezeTimers[i]< 0 && isFreezed[i]){
                VersusPlayer@ victim = GetPlayerByNr(i);
                Log(error, "unfreeze: "+ victim.playerNr);
                PlaySound("Data/Sounds/ice_foley/bf_ice_medium_3.wav");

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
    if(currentState == 101){
        versusAHGUI.SetText(""+IntToWinnerName(whoWon)+" win!",insults[rand()%insults.size()], GetTeamUIColor(whoWon));
        whoWon = -1;
        ChangeGameState(102);
    }
    
    if(currentState== 102){
        if(winStateTimer>=winStateTime) {
            ResetTag();
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
                    uiLabels[i].setText("Freezed");
                }
                else{
                    Log(error, "updateChaserRunnerLabels unfreeze");
                    vec3 uiChaserColor = GetTeamUIColor(1);
                    uiLabels[i].setColor(vec4(uiChaserColor, 1.0f));
                    if(killedRunners[i]) {
                        uiLabels[i].setText("Dead");
                    }
                    else{
                        uiLabels[i].setText("Chaser");
                    }
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

void Freeze(int playerNr){
    VersusPlayer@ victim = GetPlayerByNr(playerNr);
    PlaySound("Data/Sounds/ice_foley/bf_ice_heavy_2.wav");
    
    // Freezes chaser on spawn
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

    if(freezeTimers[playerNr] != -1)
        DeleteObjectID(freezeEmmiters[playerNr]);
        
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

    Log(error, "Freeze: "+ playerNr + " teams: " + charParams.GetString("Teams"));
}

void SetChaser(int playerNr){

    VersusPlayer@ victim = GetPlayerByNr(playerNr);
    
    currentChasers[playerNr] = true;
    
    victim.currentRace = chaserSpecies;
    RerollCharacter(victim.playerNr, ReadObjectFromID(victim.objId));

    if(currentState == 2){
        Freeze(playerNr);
    }
}

void SetRunner(int playerNr){

    VersusPlayer@ victim = GetPlayerByNr(playerNr);

    currentChasers[playerNr] = false;

    victim.currentRace = runnerSpecies;
    RerollCharacter(victim.playerNr, ReadObjectFromID(victim.objId));

    if(currentState == 2) {
        addSpeciesStats(ReadObjectFromID(victim.objId));

        Object@ charObj = ReadObjectFromID(victim.objId);
        ScriptParams@ charParams = charObj.GetScriptParams();
        charParams.SetString("Teams", "runners");
        charObj.UpdateScriptParams();

        isFreezed[playerNr] = false;
        updateChaserRunnerLabels = true;

        Log(error, "SetRunner: " + playerNr + " teams: " + charParams.GetString("Teams"));
    }
}