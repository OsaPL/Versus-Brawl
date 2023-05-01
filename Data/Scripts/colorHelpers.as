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
    
    Log(error, "furColor:"+furColor + " clothesColor:"+clothesColor);
    for(int i = 0; i < 4; i++) {
        const string channel = character_getter.GetChannel(i);
        Log(error, "species:"+species + " channel:"+channel);
        
        if(channel == "fur" ) {
            // These will use fur generator color, mixed with another
            char_obj.SetPaletteColor(i, mix(furColor, GetRandomFurColor(), 0.7));

            // Wolves are problematic for coloring all channels are marked as `fur`
            if(species == "wolf"){
                if(i==3){
                    foundClothChannel = true;
                    char_obj.SetPaletteColor(i, clothesColor*2);
                }
                if(i==1 && playerNr != teamNr && teamNr != -1){
                    char_obj.SetPaletteColor(i, mix(RandReasonableTeamColor(teamNr), vec3(0.0), 0.7)*2);
                }
            }
        } else if(channel == "cloth" ) {
            if(!foundClothChannel)
            {
                // Lets make first channel glow a little
                char_obj.SetPaletteColor(i, clothesColor*2);
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

vec3 RandReasonableWolfTeamColor(int playerNr) {
    switch (playerNr) {
        case 0:return vec3(0.0,255.0,0.0);
        case 1:return vec3(255.0,0.0,0.0);
        case 2:return vec3(0.0,0.0,255.0);
        case 3:return vec3(255.0,255.0,0.0);
    }
    return vec3(255,255,255);
}

vec3 RandReasonableTeamColor(int playerNr) {
    int max_red;
    int max_green;
    int max_blue;

    int max_main=100;
    int max_sub=0+rand()%20;

    switch (playerNr) {
        case 0:
            //Green
            max_red = max_sub;
            max_green = max_main;
            max_blue = max_sub;
            break;
        case 1:
            //Red
            max_red = max_main;
            max_green = max_sub;
            max_blue = max_sub;
            break;
        case 2:
            //Blue
            max_red = max_sub;
            max_green = max_sub;
            max_blue = max_main;
            break;
        case 3:
            //Yellow
            max_red = max_main;
            max_green = max_main;
            max_blue = max_sub;
            break;
        default: DisplayError("RandReasonableTeamColor", "Unsuported RandReasonableTeamColor value of: " + playerNr);
            //Purple guy?
            max_red = max_main;
            max_green = max_sub;
            max_blue = max_main;
            break;
    }

    vec3 color;
    color.x = max_red;
    color.y = max_green;
    color.z = max_blue;
    float avg = (color.x + color.y + color.z) / 3.0f;
    color = mix(color, vec3(avg), 0.3f);
    return FloatTintFromByte(color);
}

vec3 GetTeamUIColor(int playerNr){
    switch (playerNr) {
        case 0:
            //Green
            return vec3(0.0f,0.8f,0.0f);
        case 1:
            //Red
            return vec3(0.8f,0.0f,0.0f);
        case 2:
            //Blue
            return vec3(0.1f,0.1f,0.8f);
        case 3:
            //Yellow
            return vec3(0.9f,0.9f,0.1f);
        default: DisplayError("RandReasonableTeamColor", "Unsuported RandReasonableTeamColor value of: " + playerNr);
            //Purple guy?
            return vec3(1.0f,0.0f,1.0f);
    }
    return vec3(1.0f);
}

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