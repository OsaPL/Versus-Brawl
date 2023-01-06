JSONValue baseSpeciesStats = JSONValue();
JSONValue levelSpeciesStats = JSONValue();

void addSpeciesStats(Object@ char){

    ScriptParams@ params = char.GetScriptParams();
    string species = character_getter.GetTag("species");
    MovementObject@ mo = ReadCharacterID(char.GetID());
    character_getter.Load(mo.char_path);

    // Set `species` param accordingly
    params.SetString("species", species);

    char.UpdateScriptParams();

    // First we apply baseSpeciesStats, then levelSpeciesStats (if loaded)
    SetSpeciesParams(char, baseSpeciesStats);
    SetSpeciesParams(char, levelSpeciesStats);
}

void SpeciesStatsLoad(JSONValue settings){
    Log(error, "LevelSpeciesStats:");
    if(FoundMember(settings, "SpeciesStats")){
        levelSpeciesStats = settings["SpeciesStats"];

        Log(error, "Available: " + join(levelSpeciesStats.getMemberNames(),","));
    }
}

void BaseSpeciesStatsLoad(){
    string cfgPath = "Data/Scripts/versus-brawl/speciesStats.json";
    JSONValue settings = LoadJSONFile(cfgPath);
    Log(error, "BaseSpeciesStats:");
    if(FoundMember(settings, "SpeciesStats")){
        baseSpeciesStats = settings["SpeciesStats"];

        Log(error, "Available: " + join(baseSpeciesStats.getMemberNames(),","));
    }
}

void SetSpeciesParams(Object@ char, JSONValue speciesStats){
    ScriptParams@ params = char.GetScriptParams();
    string species = character_getter.GetTag("species");
    MovementObject@ mo = ReadCharacterID(char.GetID());
    character_getter.Load(mo.char_path);

    //Log(error, "SetSpeciesParams speciesStats.size(): " + speciesStats.size());
    array<string> speciesMembers = speciesStats.getMemberNames();
    
    for (uint i = 0; i < speciesMembers.size(); i++)
    {
        JSONValue speciesEntry = speciesStats[speciesMembers[i]];
        //Log(error, "SetSpeciesParams speciesMembers[i]: " + speciesMembers[i]);

        array<string> valuesMembers = speciesEntry.getMemberNames();
        if(speciesMembers[i] == species){

            for (uint j = 0; j < valuesMembers.size(); j++)
            {
                JsonValueType jsonType = speciesEntry[valuesMembers[j]].type();
                //Log(error, "SetSpeciesParams value: " + valuesMembers[j] + " jsonType: " + jsonType + " .asString(): " + speciesEntry[valuesMembers[j]].asString());
                
                if (jsonType == JSONintValue) {
                    params.SetInt(valuesMembers[j], speciesEntry[valuesMembers[j]].asInt());
                } else if (jsonType == JSONrealValue) {
                    params.SetFloat(valuesMembers[j], speciesEntry[valuesMembers[j]].asFloat());
                } else if (jsonType == JSONbooleanValue) {
                    params.SetInt(valuesMembers[j], speciesEntry[valuesMembers[j]].asBool() ? 1 : 0);
                } else if (jsonType == JSONstringValue) {
                    params.SetString(valuesMembers[j], speciesEntry[valuesMembers[j]].asString());
                } else if (jsonType == JSONobjectValue) {
                    // TODO: Test this, object should be just transformed into a string
                    params.SetString(valuesMembers[j], speciesEntry[valuesMembers[j]].asString());
                }
            }

            break;
        }
    }
    char.UpdateScriptParams();
}