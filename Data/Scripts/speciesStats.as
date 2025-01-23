class Species{
    string Name; // TODO! its `id` being mapped to this field, not the "Name" field
    string RaceIcon;
    array<string> CharacterPaths;
    ColorPreset@ colorPreset;
    array<Param@> BaseParams;
    array<Param@> LevelParams;
    Species(string newName, string newRaceIcon, array<string> newCharacterPaths, 
     array<string> newPlayerChannels, array<string> newTeamChannels, array<string> newFurChannels){
        Name = newName;
        CharacterPaths = newCharacterPaths;
        RaceIcon = newRaceIcon;
        BaseParams = {};
        LevelParams = {};
        ColorPreset newColorPreset(newPlayerChannels, newTeamChannels,newFurChannels);
        @colorPreset = @newColorPreset;
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

class ColorPreset{
    array<string> PlayerChannels;
    array<string> TeamChannels;
    array<string> FurChannels;
    
    ColorPreset(array<string> newPlayerChannels, array<string> newTeamChannels, array<string> newFurChannels){
        PlayerChannels = newPlayerChannels;
        TeamChannels = newTeamChannels;
        FurChannels = newFurChannels;
    }
}

// This can be extended with new species
// TODO! This should have the ability to be filled with json files

array<Species@> speciesMap = {};

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
    //Log(error, "LevelSpeciesStats:");
    // TODO! AAAAAAAH copy pasta!
    if(FoundMember(settings, "SpeciesStats")){
        JSONValue levelSpeciesStatsJson = settings["SpeciesStats"];
        array<string> speciesMembers = levelSpeciesStatsJson.getMemberNames();
        //Log(error, "Available: " + join(levelSpeciesStatsJson.getMemberNames(),","));
        for (uint i = 0; i < speciesMembers.size(); i++)
        {
            for (uint k = 0; k < speciesMap.size(); k++)
            {
                // Find the same name
                if(speciesMap[k].Name == speciesMembers[i]){
                    speciesMap[k].LevelParams = {};
                    //Log(error, "speciesMap[k].Name: " + speciesMap[k].Name + " speciesMembers[i]: " + speciesMembers[i]);

                    JSONValue speciesEntry = levelSpeciesStatsJson[speciesMembers[i]];
                    array<string> paramMembers = speciesEntry.getMemberNames();

                    for (uint j = 0; j < paramMembers.size(); j++)
                    {
                        JsonValueType jsonType = speciesEntry[paramMembers[j]].type();
                        string paramName = paramMembers[j];
                        string paramValue = speciesEntry[paramMembers[j]].asString();

                        speciesMap[k].LevelParams.push_back(Param(paramName, paramValue, jsonType));
                        //Log(error, "LevelSpeciesStats " + speciesMap[k].Name + " " + paramName + " " + paramValue + " " + jsonType);
                    }
                }
            }
        }
        //Log(error, "Available: " + join(levelSpeciesStatsJson.getMemberNames(),","));
    }
}

string addonSpeciesFilePath = "Data/Addons/versus-brawl/%modId%.species.json";
string baseSpeciesFile = "Data/Scripts/versus-brawl/speciesStats.json";

// This is used to load `.species.json` as well as the base one
void LoadSpeciesFile(string filePath){
    // Load Species map first
    JSONValue settings = LoadJSONFile(filePath);
    if(FoundMember(settings, "SpeciesStats")){
        JSONValue baseSpeciesStatsJson = settings["SpeciesStats"];
        array<string> speciesMembers = baseSpeciesStatsJson.getMemberNames();
        //Log(error, "Available: " + join(baseSpeciesStatsJson.getMemberNames(),","));
        for (uint i = 0; i < speciesMembers.size(); i++)
        {
            JSONValue speciesEntry = baseSpeciesStatsJson[speciesMembers[i]];
            array<string> characterXmls = {};
            for (uint k = 0; k < speciesEntry["Characters"].size(); k++) {
                characterXmls.push_back(speciesEntry["Characters"][k].asString());
            }
            
            // Load color presets if available
            // TODO: Ew, I can do better than copy pasting 3 times
            array<string> playerChannels = {};
            array<string> teamChannels = {};
            array<string> furChannels = {};
            if(FoundMember(speciesEntry, "ColorPresets")){
                Log(error, "speciesMembers[i]: " + speciesMembers[i]);
                JSONValue colorPresets = speciesEntry["ColorPresets"];
                
                for (uint k = 0; k < colorPresets["PlayerChannels"].size(); k++) {
                    playerChannels.push_back(colorPresets["PlayerChannels"][k].asString());
                }
                for (uint k = 0; k < colorPresets["TeamChannels"].size(); k++) {
                    teamChannels.push_back(colorPresets["TeamChannels"][k].asString());
                }
                for (uint k = 0; k < colorPresets["FurChannels"].size(); k++) {
                    furChannels.push_back(colorPresets["FurChannels"][k].asString());
                }
                Log(error, "playerChannels: " + join(playerChannels,","));
                Log(error, "teamChannels: " + join(teamChannels,","));
                Log(error, "furChannels: " + join(furChannels,","));
            }
            // Finally create the entry
            Species newSpecies (speciesMembers[i], speciesEntry["Icon"].asString(), characterXmls,
             playerChannels, teamChannels, furChannels);
            speciesMap.push_back(newSpecies);
        }
    }
    
    // Load base species stats
    //Log(error, "BaseSpeciesStats:");
    if(FoundMember(settings, "SpeciesStats")){
        JSONValue baseSpeciesStatsJson = settings["SpeciesStats"];
        array<string> speciesMembers = baseSpeciesStatsJson.getMemberNames();
        //Log(error, "Available: " + join(baseSpeciesStatsJson.getMemberNames(),","));
        for (uint i = 0; i < speciesMembers.size(); i++)
        {
            for (uint k = 0; k < speciesMap.size(); k++)
            {
                // Find the same name
                if(speciesMap[k].Name == speciesMembers[i]){
                    // TODO! For some reason I need to cleanup `LevelParams` before proceeding with `BaseParams`?
                    speciesMap[k].LevelParams = {};
                    //Log(error, "speciesMap[k].Name: " + speciesMap[k].Name + " speciesMembers[i]: " + speciesMembers[i]);
    
                    JSONValue speciesEntry = baseSpeciesStatsJson[speciesMembers[i]]["Parameters"];
                    array<string> paramMembers = speciesEntry.getMemberNames();
    
                    for (uint j = 0; j < paramMembers.size(); j++)
                    {
                        JsonValueType jsonType = speciesEntry[paramMembers[j]].type();
                        string paramName = paramMembers[j];
                        string paramValue = speciesEntry[paramMembers[j]].asString();
    
                        speciesMap[k].BaseParams.push_back(Param(paramName, paramValue, jsonType));
                        //Log(error, "BaseSpeciesStats " + speciesMap[k].Name + " " + paramName + " " + paramValue + " " + jsonType);
                    }
                }
            }
        }
        //Log(error, "Available: " + join(baseSpeciesStatsJson.getMemberNames(),","));
    }
}

void BaseSpeciesStatsLoad(){
    // First load base one
    LoadSpeciesFile(baseSpeciesFile);
    
    // Then addon ones
    array<string> addonSpecies = GetAdditionalFiles(addonSpeciesFilePath, addonTag, baseModId);
    Log(error, "addonSpecies: " + join(addonSpecies,","));
    for (uint i = 0; i < addonSpecies.size(); i++){
        LoadSpeciesFile(addonSpecies[i]);
    }
}

void SetSpeciesParams(Object@ char){
    ScriptParams@ params = char.GetScriptParams();
    string species = params.GetString("SpeciesId");
    MovementObject@ mo = ReadCharacterID(char.GetID());
    character_getter.Load(mo.char_path);
    
    
    for (uint i = 0; i < speciesMap.size(); i++)
    {
        Log(error, "SetSpeciesParams speciesMap[i].Name: " + speciesMap[i].Name + " looking for:" + species);
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

                //Log(error, "SetSpeciesParams Level " + speciesMap[i].Name + " " + Name1 + " " + StringValue1 + " " + jsonType1);

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
// TODO! This is a modified version on RecolorCharacter, should we rework original or just leave it as it is? 
void RecolorCharacterWithColorPresets(int playerNr, string species, Object@ char_obj, int teamNr = -1) {
    
    // Setup
    MovementObject@ mo = ReadCharacterID(char_obj.GetID());
    character_getter.Load(mo.char_path);
    ScriptParams@ charParams = char_obj.GetScriptParams();
    // Some small tweaks to make it look more unique
    // Scale, Muscle and Fat has to be 0-1 range
    //TODO: these would be cool to have governing variables (max_fat, minimum_fat etc.)
    //TODO! Scale is overwritten by addSpeciesStats() atm!
    float scale = (90.0+(rand()%15))/100;
    charParams.SetFloat("Character Scale", scale);
    float muscles = (50.0+((rand()%15)))/100;
    charParams.SetFloat("Muscle", muscles);
    float fat = (50.0+((rand()%15)))/100;
    charParams.SetFloat("Fat", fat);

    // Color the dinosaur, or even the rabbit
    vec3 furColor = GetRandomFurColor();
    vec3 clothesColor = RandReasonableTeamColor(playerNr);
    
    //Log(error, "playerNr: "+playerNr + " species: "+species + " teamNr: "+teamNr);
    //Log(error, "furColor: "+furColor + " clothesColor: "+clothesColor);
    
    bool foundClothChannel = false;
    
    // Get ColorPreset first
    int speciesIndex = -1;
    for(uint i = 0; i < speciesMap.size(); i++){
        // TODO! This should compare to id not the Name
        if(speciesMap[i].Name == species){
           speciesIndex = i; 
        }
    }
    ColorPreset@ preset = speciesMap[speciesIndex].colorPreset;
    // if ColorPreset is configured
    if(preset.PlayerChannels.size() != 0 && 
       preset.TeamChannels.size() != 0 && 
       preset.FurChannels.size() != 0){
       Log(info, "ColorPreset detected!");
    
        for(uint i = 0; i < preset.PlayerChannels.size(); i++){
            string entry = preset.PlayerChannels[i];
            if(entry.substr(0,1) == "#"){
                // Go with channel number
                int channelIndex = parseInt(entry.substr(1));
                char_obj.SetPaletteColor(channelIndex, clothesColor);
                clothesColor = mix(clothesColor, vec3(0.0), 0.9);
            }
            else{
                RecolorNamedChannels(char_obj, entry, clothesColor);
            }
        }
        for(uint i = 0; i < preset.TeamChannels.size(); i++){
            string entry = preset.TeamChannels[i];
            if(playerNr != teamNr && teamNr != -1){
                clothesColor = mix(RandReasonableTeamColor(teamNr), vec3(0.0), 0.6);
            }
            
            if(entry.substr(0,1) == "#"){
                int channelIndex = parseInt(entry.substr(1));
                char_obj.SetPaletteColor(channelIndex, clothesColor);
            }
            else{
                RecolorNamedChannels(char_obj, entry, clothesColor);
            }
        }
        for(uint i = 0; i < preset.FurChannels.size(); i++){
            string entry = preset.FurChannels[i];
            if(entry.substr(0,1) == "#"){
                int channelIndex = parseInt(entry.substr(1));
                char_obj.SetPaletteColor(channelIndex, furColor);
            }
            else{
                RecolorNamedChannels(char_obj, entry, furColor);
            }
            furColor = mix(furColor, GetRandomFurColor(), 0.7);
        }
    }
    else{
        //Log(error, "furColor:"+furColor + " clothesColor:"+clothesColor);
        for(int i = 0; i < 4; i++) {
            const string channel = character_getter.GetChannel(i);
            //Log(error, "species:"+species + " channel:"+channel);
            
            if(channel == "fur" ) {
                // These will use fur generator color, mixed with another
                char_obj.SetPaletteColor(i, mix(furColor, GetRandomFurColor(), 0.7));
    
                // Wolves are problematic for coloring all channels are marked as `fur`
                if(species == "wolf"){
                    if(i==3){
                        foundClothChannel = true;
                        char_obj.SetPaletteColor(i, clothesColor);
                    }
                    if(i==1 && playerNr != teamNr && teamNr != -1){
                        char_obj.SetPaletteColor(i, mix(RandReasonableTeamColor(teamNr), vec3(0.0), 0.7));
                    }
                }
            } else if(channel == "cloth" ) {
                if(!foundClothChannel)
                {
                    // Lets make first channel glow a little
                    char_obj.SetPaletteColor(i, clothesColor);
                    foundClothChannel = true;
                }
                else{
                    if(playerNr != teamNr && teamNr != -1){
                        clothesColor = mix(RandReasonableTeamColor(teamNr), vec3(0.0), 0.6);
                    }
                    char_obj.SetPaletteColor(i, clothesColor);
                }
                clothesColor = mix(clothesColor, vec3(0.0), 0.9);
            }
        }
        
        if(!foundClothChannel){
            // Since I cant find any cloth channel, just use the first one
            char_obj.SetPaletteColor(0, clothesColor);
        }
    }
    char_obj.UpdateScriptParams();
}

void RecolorNamedChannels(Object@ char_obj, string channelName, vec3 color){
    MovementObject@ mo = ReadCharacterID(char_obj.GetID());
    character_getter.Load(mo.char_path);
    
    vec3 mixColor = color;
    for(int i = 0; i < 4; i++) {
        const string channel = character_getter.GetChannel(i);
        if(channel == channelName){
            char_obj.SetPaletteColor(i, mixColor);
            mixColor = mix(mixColor, vec3(0.0), 0.9);
        }
    }
}