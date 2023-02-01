class Species{
    string Name;
    string RaceIcon;
    array<string> CharacterPaths;
    array<Param@> BaseParams;
    array<Param@> LevelParams;
    Species(string newName, string newRaceIcon, array<string> newCharacterPaths){
        Name = newName;
        CharacterPaths = newCharacterPaths;
        RaceIcon = newRaceIcon;
        BaseParams = {};
        LevelParams= {};
    }
}

class Param{
    string Name;
    string StringValue;
    JsonValueType Type;
    Param(string newName, string newValue, JsonValueType newType){
        Name = newName;
        StringValue = newValue;
        Type = newType;
    }
}

// This can be extended with new races
enum SpeciesInt {
    _rabbit = 0,
        _wolf = 1,
        _dog = 2,
        _rat = 3,
        _cat = 4
};

array<Species@> speciesMap={
    Species("rabbit", "Textures/ui/arena_mode/glyphs/rabbit_foot_1x1.png",
        {
            "Data/Characters/male_rabbit_1.xml",
            "Data/Characters/male_rabbit_2.xml",
            "Data/Characters/male_rabbit_3.xml",
            "Data/Characters/female_rabbit_1.xml",
            "Data/Characters/female_rabbit_2.xml",
            "Data/Characters/female_rabbit_3.xml",
            "Data/Characters/pale_rabbit_civ.xml"
        }),
    Species("wolf", "Textures/ui/arena_mode/glyphs/skull.png",
        {
             "Data/Characters/male_wolf.xml"
        }),
    Species("dog", "Textures/ui/arena_mode/glyphs/fighter_swords.png",
        {
            "Data/Characters/lt_dog_big.xml",
            "Data/Characters/lt_dog_female.xml",
            "Data/Characters/lt_dog_male_1.xml",
            "Data/Characters/lt_dog_male_2.xml"
        }),
    Species("rat", "Textures/ui/arena_mode/glyphs/slave_shackles.png",
        {
            "Data/Characters/hooded_rat.xml",
            "Data/Characters/female_rat.xml",
            "Data/Characters/rat.xml"
        }),
    Species("cat", "Textures/ui/arena_mode/glyphs/contender_crown.png",
        {
            "Data/Characters/fancy_striped_cat.xml",
            "Data/Characters/female_cat.xml",
            "Data/Characters/male_cat.xml",
            "Data/Characters/striped_cat.xml"
        })
};

void addSpeciesStats(Object@ char){

    ScriptParams@ params = char.GetScriptParams();
    string species = character_getter.GetTag("species");
    MovementObject@ mo = ReadCharacterID(char.GetID());
    character_getter.Load(mo.char_path);

    // Set `species` param accordingly
    params.SetString("species", species);

    char.UpdateScriptParams();

    // First we apply baseSpeciesStats, then levelSpeciesStats (if loaded)
    SetSpeciesParams(char);
}

void SpeciesStatsLoad(JSONValue settings){
    Log(error, "LevelSpeciesStats:");
    // TODO! AAAAAAAH copy pasta!
    if(FoundMember(settings, "SpeciesStats")){
        JSONValue levelSpeciesStatsJson = settings["SpeciesStats"];
        array<string> speciesMembers = levelSpeciesStatsJson.getMemberNames();
        Log(error, "Available: " + join(levelSpeciesStatsJson.getMemberNames(),","));
        for (uint i = 0; i < speciesMembers.size(); i++)
        {
            for (uint k = 0; k < speciesMap.size(); k++)
            {
                // Find the same name
                if(speciesMap[k].Name == speciesMembers[i]){
                    speciesMap[k].LevelParams = {};
                    Log(error, "speciesMap[k].Name: " + speciesMap[k].Name + " speciesMembers[i]: " + speciesMembers[i]);

                    JSONValue speciesEntry = levelSpeciesStatsJson[speciesMembers[i]];
                    array<string> paramMembers = speciesEntry.getMemberNames();

                    for (uint j = 0; j < paramMembers.size(); j++)
                    {
                        JsonValueType jsonType = speciesEntry[paramMembers[j]].type();
                        string paramName = paramMembers[j];
                        string paramValue = speciesEntry[paramMembers[j]].asString();

                        speciesMap[k].LevelParams.push_back(Param(paramName, paramValue, jsonType));
                        Log(error, "LevelSpeciesStats " + speciesMap[k].Name + " " + paramName + " " + paramValue + " " + jsonType);
                    }
                }
            }
        }
        Log(error, "Available: " + join(levelSpeciesStatsJson.getMemberNames(),","));
    }
}

void BaseSpeciesStatsLoad(){
    string cfgPath = "Data/Scripts/versus-brawl/speciesStats.json";
    JSONValue settings = LoadJSONFile(cfgPath);
    Log(error, "BaseSpeciesStats:");
    if(FoundMember(settings, "SpeciesStats")){
        JSONValue baseSpeciesStatsJson = settings["SpeciesStats"];
        array<string> speciesMembers = baseSpeciesStatsJson.getMemberNames();
        Log(error, "Available: " + join(baseSpeciesStatsJson.getMemberNames(),","));
        for (uint i = 0; i < speciesMembers.size(); i++)
        {
            for (uint k = 0; k < speciesMap.size(); k++)
            {
                // Find the same name
                if(speciesMap[k].Name == speciesMembers[i]){
                    // TODO! For some reason I need to cleanup `LevelParams` before proceeding with `BaseParams`?
                    speciesMap[k].LevelParams = {};
                    Log(error, "speciesMap[k].Name: " + speciesMap[k].Name + " speciesMembers[i]: " + speciesMembers[i]);

                    JSONValue speciesEntry = baseSpeciesStatsJson[speciesMembers[i]];
                    array<string> paramMembers = speciesEntry.getMemberNames();

                    for (uint j = 0; j < paramMembers.size(); j++)
                    {
                        JsonValueType jsonType = speciesEntry[paramMembers[j]].type();
                        string paramName = paramMembers[j];
                        string paramValue = speciesEntry[paramMembers[j]].asString();

                        speciesMap[k].BaseParams.push_back(Param(paramName, paramValue, jsonType));
                        Log(error, "BaseSpeciesStats " + speciesMap[k].Name + " " + paramName + " " + paramValue + " " + jsonType);
                    }
                }
            }
        }
        Log(error, "Available: " + join(baseSpeciesStatsJson.getMemberNames(),","));
    }
}

void SetSpeciesParams(Object@ char){
    ScriptParams@ params = char.GetScriptParams();
    string species = character_getter.GetTag("species");
    MovementObject@ mo = ReadCharacterID(char.GetID());
    character_getter.Load(mo.char_path);
    
    
    for (uint i = 0; i < speciesMap.size(); i++)
    {
        if(speciesMap[i].Name == species){
            
            Log(error, "SetSpeciesParams speciesMap[i].Name: " + speciesMap[i].Name);
            array<Param@> speciesBaseParams = speciesMap[i].BaseParams;

            for (uint j = 0; j < speciesBaseParams.size(); j++)
            {
                string Name = speciesBaseParams[j].Name;
                string StringValue = speciesBaseParams[j].StringValue;
                JsonValueType jsonType = speciesBaseParams[j].Type;

                Log(error, "SetSpeciesParams Base " + speciesMap[i].Name + " " + Name + " " + StringValue + " " + jsonType);

                // Now we just convert the value and call correct params method
                if (jsonType == JSONintValue) {
                    params.SetInt(Name, parseInt(StringValue));
                } else if (jsonType == JSONrealValue) {
                    params.SetFloat(Name, parseFloat(StringValue));
                } else if (jsonType == JSONbooleanValue) {
                    params.SetInt(Name, StringValue == "true" ? 1 : 0);
                } else if (jsonType == JSONstringValue) {
                    params.SetString(Name, StringValue);
                } else if (jsonType == JSONobjectValue) {
                    // We cant do anything with an object value atm, just skip it.
                }
            }

            array<Param@> speciesLevelParams = speciesMap[i].LevelParams;
            for (uint k= 0; k < speciesLevelParams.size(); k++)
            {
                string Name1 = speciesLevelParams[k].Name;
                string StringValue1 = speciesLevelParams[k].StringValue;
                JsonValueType jsonType1 = speciesLevelParams[k].Type;

                Log(error, "SetSpeciesParams Level " + speciesMap[i].Name + " " + Name1 + " " + StringValue1 + " " + jsonType1);

                // Now we just convert the value and call correct params method
                if (jsonType1 == JSONintValue) {
                    params.SetInt(Name1, parseInt(StringValue1));
                } else if (jsonType1 == JSONrealValue) {
                    params.SetFloat(Name1, parseFloat(StringValue1));
                } else if (jsonType1 == JSONbooleanValue) {
                    params.SetInt(Name1, StringValue1 == "true" ? 1 : 0);
                } else if (jsonType1 == JSONstringValue) {
                    params.SetString(Name1, StringValue1);
                } else if (jsonType1 == JSONobjectValue) {
                    // We cant do anything with an object value atm, just skip it.
                }
            }
            
            break;
        }
    }
    char.UpdateScriptParams();
}