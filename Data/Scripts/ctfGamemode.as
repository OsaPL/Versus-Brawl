#include "versusmode.as"
// ^^ only this is needed
#include "versus-brawl/pointUIBase.as"

// configurables
float flagRespawnTime = 10;
float debuffMlt = 0.8f;

// states
bool init = true;
array<int> flagIds = {};

//Level methods
void Init(string msg){
    constantRespawning = true;
    forcedSpecies = -1;
    useGenericSpawns = false;
    teamPlay = true;
    teamsAmount = 2;
    allowUneven = true;
    strictTeamColors = true;

    // pointUIBase configuration
    pointsToWin = 3;
    pointsTextFormat = "@points@";
    playingToTextFormat = "Playing to: @points@ captures!";
    
    //Always need to call this first!
    VersusInit("");

    loadCallbacks.push_back(@CTFLoad);

    levelTimer.Add(LevelEventJob("flagCaptured", function(_params){
        
        PlaySound("Data/Sounds/versus/voice_end_1.wav");
        Log(error, "flagCaptured: " + _params[1] + " for: " + _params[2]);

        // Ignore captures if warmup or game is done
        if(currentState <= 0 || currentState >= 100)
            return true;
        
        int teamCapturing = parseInt(_params[1]);
        pointsCount[teamCapturing]++;
        Log(error, "teamPoints["+_params[1]+"]: " + pointsCount[teamCapturing]);
        updateScores = true;

        if(pointsCount[teamCapturing] >= pointsToWin){
            winnerNr = teamCapturing;
            ChangeGameState(100);
            constantRespawning = false;
            PlaySound("Data/Sounds/versus/fight_end.wav");
        }
        return true;
    }));

    levelTimer.Add(LevelEventJob("reset", function(_params){
        ResetCTF();
        return true;
    }));
    
    // And finally load JSON Params
    LoadJSONLevelParams();
}

void CTFLoad(JSONValue settings) {
    Log(error, "CTFLoad:");
    if(FoundMember(settings, "CTF")) {
        JSONValue ctf = settings["CTF"];
        Log(error, "Available: " + join(ctf.getMemberNames(),","));

        if (FoundMember(ctf, "PointsToWin"))
            pointsToWin = ctf["PointsToWin"]["Value"].asInt();

        if (FoundMember(ctf, "PointsTextShowTime"))
            pointsTextShowTime = ctf["PointsTextShowTime"]["Value"].asFloat();

        if (FoundMember(ctf, "FlagRespawnTime"))
            flagRespawnTime = ctf["FlagRespawnTime"]["Value"].asFloat();

        if (FoundMember(ctf, "CarrierDebuffMlt"))
            debuffMlt = ctf["CarrierDebuffMlt"]["Value"].asFloat();
        
    }
}

void DrawGUI() {
    //Always need to call this first!
    VersusDrawGUI();
}

void Update(){
    //Always need to call this first!
    VersusUpdate();

    if(init){
        GetFlagHotspotsIds();
        init = false;
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

void ResetCTF(){
    pointsTextShow = true;

    pointsCount = {};
    for (int j = 0; j < teamsAmount; j++)
    {
        pointsCount.push_back(0);
    }
    updateScores = true;

    constantRespawning = true;
}

void GetFlagHotspotsIds(){
    array<int> hotspots = GetObjectIDsType(_hotspot_object);
    array<int> teamsFound = {};

    for (uint i = 0; i < hotspots.size(); i++) {
        Object@ foundHotspot = ReadObjectFromID(hotspots[i]);
        ScriptParams@ objParams = foundHotspot.GetScriptParams();
        if(objParams.HasParam("type")) {
            string type = objParams.GetString("type");
            if (type == "flagHotspot"){
                int teamId = objParams.GetInt("teamId");
                if(teamId >= teamsAmount || teamId == -1){
                    // We ignore not correct teamIds
                    Log(error, "Incorrect flag found! hotspotId: " + hotspots[i] + " teamId:" + teamId);
                    continue;
                }
                // TODO: For now we will only allow a single flag hotspot per teamId
                if(teamsFound.find(teamId) < 0){
                    teamsFound.push_back(teamId);
                    flagIds.push_back(hotspots[i]);

                    objParams.SetFloat("returnCooldown", flagRespawnTime);
                    objParams.SetFloat("debuffCarrier", debuffMlt);

                    // Optionally we recolor flags
                    if(strictTeamColors){
                        vec3 color = GetTeamUIColor(teamId);
                        objParams.SetFloat("red", color.x * 0.4f);
                        objParams.SetFloat("green", color.y * 0.4f);
                        objParams.SetFloat("blue", color.z * 0.4f);
                    }
                }
                else{
                    Log(error, "Duplicate flag found! teamsFound.find(teamId): " + teamsFound.find(teamId));
                }
            }
        }
    }
    
    if(teamsAmount != int(flagIds.size())){
        errorMessage = "Not enough flags detected! teamsAmount: " + teamsAmount + " flagIds.size(): " + flagIds.size();
        ChangeGameState(1);
    }
}