JSONValue baseSpeciesStats = JSONValue();
JSONValue levelSpeciesStats = JSONValue();

void addSpeciesStats(Object@ char){

    ScriptParams@ params = char.GetScriptParams();
    string species = character_getter.GetTag("species");
    MovementObject@ mo = ReadCharacterID(char.GetID());
    character_getter.Load(mo.char_path);

    // Set `species` param accordingly
    params.SetString("species", species);
    
    //TODO! Stats to implement:
    //1)No blocking
    // if(species == "rabbit"){
    //     params.SetFloat("Attack Damage",    1.0); //params.AddFloatSlider("Attack Damage", 1, "min:0,max:2,step:0.1,text_mult:100");
    //     params.SetFloat("Attack Knockback", 1.0); //params.AddFloatSlider("Attack Knockback", 1, "min:0,max:2,step:0.1,text_mult:100");
    //     params.SetFloat("Attack Speed",     1.0); //params.AddFloatSlider("Attack Speed", 1, "min:0,max:2,step:0.1,text_mult:100");
    //     params.SetFloat("Damage Resistance",0.7); //params.AddFloatSlider("Damage Resistance", 1, "min:0,max:2,step:0.1,text_mult:100");
    //     params.SetFloat("Movement Speed",   0.8); //params.AddFloatSlider("Movement Speed", 1, "min:0.1,max:1.5,step:0.1,text_mult:100");
    //     params.SetFloat("Character Scale",  0.9); //params.AddFloatSlider("Character Scale", 1, "min:0.6,max:1.4,step:0.02,text_mult:100");
    //    
    //     // Jump slightly higher
    //     params.SetFloat("Jump - Initial Velocity",    7.0);//params.AddFloatSlider("Jump - Initial Velocity", 5.0, "min:0.1,max:50.0,step:0.01,text_mult:1");
    //     params.SetFloat("Jump - Air Control",         2.0);//params.AddFloatSlider("Jump - Air Control", 3.0, "min:0.0,max:50.0,step:0.01,text_mult:1");
    //     params.SetFloat("Jump - Jump Sustain",        5.0);//params.AddFloatSlider("Jump - Jump Sustain", 5.0, "min:0.0,max:50.0,step:0.01,text_mult:1");
    //     params.SetFloat("Jump - Jump Sustain Boost", 10.0);//params.AddFloatSlider("Jump - Jump Sustain Boost", 10.0, "min:0.0,max:100.0,step:0.01,text_mult:1");
    // }
    // else if(species == "dog"){
    //     params.SetFloat("Attack Damage",      1.2); //params.AddFloatSlider("Attack Damage", 1, "min:0,max:2,step:0.1,text_mult:100");
    //     params.SetFloat("Attack Knockback",   1.2); //params.AddFloatSlider("Attack Knockback", 1, "min:0,max:2,step:0.1,text_mult:100");
    //     params.SetFloat("Attack Speed",       0.8); //params.AddFloatSlider("Attack Speed", 1, "min:0,max:2,step:0.1,text_mult:100");
    //     params.SetFloat("Damage Resistance",  1.2); //params.AddFloatSlider("Damage Resistance", 1, "min:0,max:2,step:0.1,text_mult:100");
    //     params.SetFloat("Movement Speed",     0.8); //params.AddFloatSlider("Movement Speed", 1, "min:0.1,max:1.5,step:0.1,text_mult:100");
    //     params.SetFloat("Character Scale",    1.0); //params.AddFloatSlider("Character Scale", 1, "min:0.6,max:1.4,step:0.02,text_mult:100");
    //
    //     //High, short, and slow jumps
    //     params.SetFloat("Jump - Initial Velocity",    10.0);//params.AddFloatSlider("Jump - Initial Velocity", 5.0, "min:0.1,max:50.0,step:0.01,text_mult:1");
    //     params.SetFloat("Jump - Air Control",         1.5);//params.AddFloatSlider("Jump - Air Control", 3.0, "min:0.0,max:50.0,step:0.01,text_mult:1");
    //     params.SetFloat("Jump - Jump Sustain",        3.0);//params.AddFloatSlider("Jump - Jump Sustain", 5.0, "min:0.0,max:50.0,step:0.01,text_mult:1");
    //     params.SetFloat("Jump - Jump Sustain Boost",  1.0);//params.AddFloatSlider("Jump - Jump Sustain Boost", 10.0, "min:0.0,max:100.0,step:0.01,text_mult:1");
    //
    //     //TODO! These still make dog throw inaccurate
    //     params.SetFloat("Throw - Initial Velocity Multiplier",  5.0);//params.AddFloatSlider("Throw - Initial Velocity Multiplier", 1.0, "min:0.1,max:50.0,step:0.01,text_mult:1");
    //     params.SetFloat("Throw - Mass Multiplier",  2.0);//params.AddFloatSlider("Throw - Mass Multiplier", 1.0, "min:0.0,max:50.0,step:0.01,text_mult:1");
    // }
    // else if(species == "cat"){
    //     params.SetFloat("Attack Damage",       1.0); //params.AddFloatSlider("Attack Damage", 1, "min:0,max:2,step:0.1,text_mult:100");
    //     params.SetFloat("Attack Knockback",    0.6); //params.AddFloatSlider("Attack Knockback", 1, "min:0,max:2,step:0.1,text_mult:100");
    //     params.SetFloat("Attack Speed",        1.2); //params.AddFloatSlider("Attack Speed", 1, "min:0,max:2,step:0.1,text_mult:100");
    //     params.SetFloat("Damage Resistance",   0.5); //params.AddFloatSlider("Damage Resistance", 1, "min:0,max:2,step:0.1,text_mult:100");
    //     params.SetFloat("Movement Speed",      1.2); //params.AddFloatSlider("Movement Speed", 1, "min:0.1,max:1.5,step:0.1,text_mult:100");
    //     params.SetFloat("Character Scale",     1.0); //params.AddFloatSlider("Character Scale", 1, "min:0.6,max:1.4,step:0.02,text_mult:100");
    //
    //     //Low, far and fast jumps
    //     params.SetFloat("Jump - Initial Velocity",    8.0);//params.AddFloatSlider("Jump - Initial Velocity", 5.0, "min:0.1,max:50.0,step:0.01,text_mult:1");
    //     params.SetFloat("Jump - Air Control",         5.0);//params.AddFloatSlider("Jump - Air Control", 3.0, "min:0.0,max:50.0,step:0.01,text_mult:1");
    //     params.SetFloat("Jump - Jump Sustain",        2.0);//params.AddFloatSlider("Jump - Jump Sustain", 5.0, "min:0.0,max:50.0,step:0.01,text_mult:1");
    //     params.SetFloat("Jump - Jump Sustain Boost",  2.0);//params.AddFloatSlider("Jump - Jump Sustain Boost", 10.0, "min:0.0,max:100.0,step:0.01,text_mult:1");
    //
    //     params.SetFloat("Fall Damage Multiplier",0); //params.AddFloatSlider("Fall Damage Multiplier", default_fall_damage_multiplier, "min:0,max:10,step:0.1,text_mult:1");
    // }
    // else if(species == "rat"){
    //     params.SetFloat("Attack Damage",    0.7); //params.AddFloatSlider("Attack Damage", 1, "min:0,max:2,step:0.1,text_mult:100");
    //     params.SetFloat("Attack Knockback", 1.5); //params.AddFloatSlider("Attack Knockback", 1, "min:0,max:2,step:0.1,text_mult:100");
    //     params.SetFloat("Attack Speed",     1.2); //params.AddFloatSlider("Attack Speed", 1, "min:0,max:2,step:0.1,text_mult:100");
    //     params.SetFloat("Damage Resistance",0.5); //params.AddFloatSlider("Damage Resistance", 1, "min:0,max:2,step:0.1,text_mult:100");
    //     params.SetFloat("Movement Speed",   1.2); //params.AddFloatSlider("Movement Speed", 1, "min:0.1,max:1.5,step:0.1,text_mult:100");
    //     params.SetFloat("Character Scale",  0.9); //params.AddFloatSlider("Character Scale", 1, "min:0.6,max:1.4,step:0.02,text_mult:100");
    //
    //     //Lowest, slightly further and fastest jumps
    //     params.SetFloat("Jump - Initial Velocity",    3.5);//params.AddFloatSlider("Jump - Initial Velocity", 5.0, "min:0.1,max:50.0,step:0.01,text_mult:1");
    //     params.SetFloat("Jump - Air Control",         4.0);//params.AddFloatSlider("Jump - Air Control", 3.0, "min:0.0,max:50.0,step:0.01,text_mult:1");
    //     params.SetFloat("Jump - Jump Sustain",        10.0);//params.AddFloatSlider("Jump - Jump Sustain", 5.0, "min:0.0,max:50.0,step:0.01,text_mult:1");
    //     params.SetFloat("Jump - Jump Sustain Boost", 10.0);//params.AddFloatSlider("Jump - Jump Sustain Boost", 10.0, "min:0.0,max:100.0,step:0.01,text_mult:1");
    //
    //     params.SetInt("Knockout Shield",    1); //params.AddIntSlider("Knockout Shield", 0, "min:0,max:10");
    // }
    // else if(species == "wolf"){
    //     params.SetFloat("Attack Damage",    0.15); //params.AddFloatSlider("Attack Damage", 1, "min:0,max:2,step:0.1,text_mult:100");
    //     params.SetFloat("Attack Knockback", 0.7); //params.AddFloatSlider("Attack Knockback", 1, "min:0,max:2,step:0.1,text_mult:100");
    //     params.SetFloat("Attack Speed",     0.35); //params.AddFloatSlider("Attack Speed", 1, "min:0,max:2,step:0.1,text_mult:100");
    //     params.SetFloat("Damage Resistance",1.0); //params.AddFloatSlider("Damage Resistance", 1, "min:0,max:2,step:0.1,text_mult:100");
    //     params.SetFloat("Movement Speed",   0.5); //params.AddFloatSlider("Movement Speed", 1, "min:0.1,max:1.5,step:0.1,text_mult:100");
    //     params.SetFloat("Character Scale",  1.0); //params.AddFloatSlider("Character Scale", 1, "min:0.6,max:1.4,step:0.02,text_mult:100");
    //
    //     //Really high, short, and slow jumps
    //     params.SetFloat("Jump - Initial Velocity",    10.0);//params.AddFloatSlider("Jump - Initial Velocity", 5.0, "min:0.1,max:50.0,step:0.01,text_mult:1");
    //     params.SetFloat("Jump - Air Control",         1.0);//params.AddFloatSlider("Jump - Air Control", 3.0, "min:0.0,max:50.0,step:0.01,text_mult:1");
    //     params.SetFloat("Jump - Jump Sustain",        5.0);//params.AddFloatSlider("Jump - Jump Sustain", 5.0, "min:0.0,max:50.0,step:0.01,text_mult:1");
    //     params.SetFloat("Jump - Jump Sustain Boost", 5.0);//params.AddFloatSlider("Jump - Jump Sustain Boost", 10.0, "min:0.0,max:100.0,step:0.01,text_mult:1");
    // }
    
    //LoadSpeciesValues();

    char.UpdateScriptParams();

    // First we apply baseSpeciesStats, then levelSpeciesStats (if loaded)
    SetSpeciesParams(char, baseSpeciesStats);
    SetSpeciesParams(char, levelSpeciesStats);
    
    //Log(error, "Added stats to:"+species);
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