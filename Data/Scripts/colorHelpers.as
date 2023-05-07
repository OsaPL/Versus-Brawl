void RecolorCharacter(int playerNr, string species, Object@ char_obj, int teamNr = -1) {
    
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
    
    bool foundClothChannel = false;
    
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

    char_obj.UpdateScriptParams();
}

vec3 RandReasonableTeamColor(int playerNr) {
    vec3 color = GetTeamUIColor(playerNr) * 0.7f;
    return color;
}

class NamedColor{
    string name;
    vec3 value;

    NamedColor(string newName, vec3 newValue){
        name = newName;
        value = newValue;
    }
}

array<NamedColor@>@ GetColorTable(){
    array<NamedColor@> teamColors = {
        NamedColor("Green", vec3(60.0f, 180.0f, 75.0f)),
        NamedColor("Red", vec3(230.0f, 25.0f, 25.0f)),
        NamedColor("Blue", vec3(0.0f, 40.0f, 200.0f)),
        NamedColor("Yellow", vec3(255.0f, 225.0f, 25.0f)),
        NamedColor("Orange", vec3(245.0f, 130.0f, 48.0f)),
        NamedColor("Purple", vec3(145.0f, 30.0f, 180.0f)),
        NamedColor("Cyan", vec3(70.0f, 240.0f, 240.0f)),
        NamedColor("Magenta", vec3(240.0f, 50.0f, 230.0f)),
        NamedColor("Lime", vec3(210.0f, 245.0f, 60.0f)),
        NamedColor("Pink", vec3(250.0f, 190.0f, 212.0f)),
        NamedColor("Teal", vec3(0.0f, 128.0f, 128.0f)),
        NamedColor("Lavender", vec3(220.0f, 190.0f, 255.0f)),
        NamedColor("Brown", vec3(170.0f, 110.0f, 40.0f)),
        NamedColor("Beige", vec3(255.0f, 250.0f, 200.0f)),
        NamedColor("Maroon", vec3(128.0f, 0.0f, 0.0f)),
        NamedColor("Mint", vec3(170.0f, 255.0f, 195.0f)),
        NamedColor("Olive", vec3(128.0f, 128.0f, 0.0f)),
        NamedColor("Apricot", vec3(255.0f, 215.0f, 180.0f)),
        NamedColor("Navy", vec3(0.0f, 0.0f, 128.0f)),
        NamedColor("Grey", vec3(128.0f, 128.0f, 128.0f)),
        NamedColor("Black", vec3(0.0f, 0.0f, 0.0f)),
    
        NamedColor("White", vec3(255.0f, 255.0f, 255.0f))
    };

    return teamColors;
}

vec3 GetTeamUIColor(int playerNr, bool usePercent = true){
    vec3 color;

    array<NamedColor@>@ teamColors = GetColorTable();
    
    if(playerNr >= 20){
        color = teamColors[20].value;
    }
    else{
        color =  teamColors[playerNr].value;
    }
    
    if(usePercent)
        color = color / 255.0f;

    return color;
}

string GetTeamColorName(int playerNr){
    array<NamedColor@>@ teamColors = GetColorTable();
    
    if(playerNr >= 20){
        return teamColors[20].name;
    }
    else{
        return teamColors[playerNr].name;
    }
}
// Taken from https://sashamaps.net/docs/resources/20-colors/
// used: Convienient + RGB + 95%
// vec3(60.0f, 180.0f, 75.0f), vec3(230.0f, 25.0f, 75.0f), vec3(255.0f, 225.0f, 25.0f), vec3(0.0f, 130.0f, 200.0f), vec3(245.0f, 130.0f, 48.0f), vec3(145.0f, 30.0f, 180.0f), vec3(70.0f, 240.0f, 240.0f), vec3(240.0f, 50.0f, 230.0f), vec3(210.0f, 245.0f, 60.0f), vec3(250.0f, 190.0f, 212.0f), vec3(0.0f, 128.0f, 128.0f), vec3(220.0f, 190.0f, 255.0f), vec3(170.0f, 110.0f, 40.0f), vec3(255.0f, 250.0f, 200.0f), vec3(128.0f, 0.0f, 0.0f), vec3(170.0f, 255.0f, 195.0f), vec3(128.0f, 128.0f, 0.0f), vec3(255.0f, 215.0f, 180.0f), vec3(0.0f, 0.0f, 128.0f), vec3(128.0f, 128.0f, 128.0f), vec3(255.0f, 255.0f, 255.0f), vec3(0.0f, 0.0f, 0.0f)

vec3 GetRandomFurColor() {
    vec3 fur_color_byte;
    int rnd = rand() % 7;

    //TODO Extend this
    switch(rnd) {
        case 0: fur_color_byte = vec3(255); break;
        case 1: fur_color_byte = vec3(34); break;
        case 2: fur_color_byte = vec3(137); break;
        case 3: fur_color_byte = vec3(105, 73, 54); break;
        case 4: fur_color_byte = vec3(53, 28, 10); break;
        case 5: fur_color_byte = vec3(172, 124, 62); break;
        case 6: fur_color_byte = vec3(74, 86, 89); break;
    }

    return FloatTintFromByte(fur_color_byte);
}

// Convert byte colors to float colors (255,0,0) to (1.0f,0.0f,0.0f)
vec3 FloatTintFromByte(const vec3 &in tint) {
    vec3 float_tint;
    float_tint.x = tint.x / 255.0f;
    float_tint.y = tint.y / 255.0f;
    float_tint.z = tint.z / 255.0f;
    return float_tint;
}