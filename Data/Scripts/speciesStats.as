void addSpeciesStats(Object@ char){

    ScriptParams@ params = char.GetScriptParams();
    string species = character_getter.GetTag("species");
    MovementObject@ mo = ReadCharacterID(char.GetID());
    character_getter.Load(mo.char_path);
    
    //TODO! Stats to implement:
    //1)jump height
    //2)No blocking
    //TODO! Extract it to top level for ease of editing if needed
    if(species == "rabbit"){
        params.SetFloat("Attack Damage",    1.0); //params.AddFloatSlider("Attack Damage", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Attack Knockback", 1.0); //params.AddFloatSlider("Attack Knockback", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Attack Speed",     1.0); //params.AddFloatSlider("Attack Speed", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Damage Resistance",0.8); //params.AddFloatSlider("Damage Resistance", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Movement Speed",   0.8); //params.AddFloatSlider("Movement Speed", 1, "min:0.1,max:1.5,step:0.1,text_mult:100");
        params.SetFloat("Character Scale",  0.8); //params.AddFloatSlider("Character Scale", 1, "min:0.6,max:1.4,step:0.02,text_mult:100");
    }
    else if(species == "dog"){
        params.SetFloat("Attack Damage",      1.2); //params.AddFloatSlider("Attack Damage", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Attack Knockback",   1.2); //params.AddFloatSlider("Attack Knockback", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Attack Speed",       0.8); //params.AddFloatSlider("Attack Speed", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Damage Resistance",  1.2); //params.AddFloatSlider("Damage Resistance", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Movement Speed",     0.8); //params.AddFloatSlider("Movement Speed", 1, "min:0.1,max:1.5,step:0.1,text_mult:100");
        params.SetFloat("Character Scale",    1.2); //params.AddFloatSlider("Character Scale", 1, "min:0.6,max:1.4,step:0.02,text_mult:100");

        params.SetInt("Cannot Be Disarmed",     1); //params.AddIntCheckbox("Cannot Be Disarmed", false);
    }
    else if(species == "cat"){
        params.SetFloat("Attack Damage",       1.0); //params.AddFloatSlider("Attack Damage", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Attack Knockback",    0.6); //params.AddFloatSlider("Attack Knockback", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Attack Speed",        1.2); //params.AddFloatSlider("Attack Speed", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Damage Resistance",   0.6); //params.AddFloatSlider("Damage Resistance", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Movement Speed",      1.2); //params.AddFloatSlider("Movement Speed", 1, "min:0.1,max:1.5,step:0.1,text_mult:100");
        params.SetFloat("Character Scale",     1.0); //params.AddFloatSlider("Character Scale", 1, "min:0.6,max:1.4,step:0.02,text_mult:100");

        params.SetFloat("Fall Damage Multiplier",0); //params.AddFloatSlider("Fall Damage Multiplier", default_fall_damage_multiplier, "min:0,max:10,step:0.1,text_mult:1");
    }
    else if(species == "rat"){
        params.SetFloat("Attack Damage",    0.7); //params.AddFloatSlider("Attack Damage", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Attack Knockback", 1.5); //params.AddFloatSlider("Attack Knockback", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Attack Speed",     1.2); //params.AddFloatSlider("Attack Speed", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Damage Resistance",0.6); //params.AddFloatSlider("Damage Resistance", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Movement Speed",   1.2); //params.AddFloatSlider("Movement Speed", 1, "min:0.1,max:1.5,step:0.1,text_mult:100");
        params.SetFloat("Character Scale",  1.0); //params.AddFloatSlider("Character Scale", 1, "min:0.6,max:1.4,step:0.02,text_mult:100");

        params.SetInt("Knockout Shield",    1); //params.AddIntSlider("Knockout Shield", 0, "min:0,max:10");
    }
    else if(species == "wolf"){
        params.SetFloat("Attack Damage",    0.15); //params.AddFloatSlider("Attack Damage", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Attack Knockback", 0.7); //params.AddFloatSlider("Attack Knockback", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Attack Speed",     0.5); //params.AddFloatSlider("Attack Speed", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Damage Resistance",1.2); //params.AddFloatSlider("Damage Resistance", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Movement Speed",   0.6); //params.AddFloatSlider("Movement Speed", 1, "min:0.1,max:1.5,step:0.1,text_mult:100");
        params.SetFloat("Character Scale",  1.0); //params.AddFloatSlider("Character Scale", 1, "min:0.6,max:1.4,step:0.02,text_mult:100");
    }

    char.UpdateScriptParams();
    Log(error, "Added stats to:"+species);
}

/* Some balancing notes:
Wolf shouldnt be able to one hit kill dog
wolf is weak vs weapons
cat is glass cannon, good vs lower hp rabbit and rat
rat is great for pushing opponents

playtesting sessions notes:

-session #1 (mostly blocks, 3 players) 11 Oct 
wolf is in a surprisingly good place, maybe make attack or movement speed slightly higher?
rat is kinda annoying on maps with hazards, good, tis the way of the rat
cats feel weak, even with high movements and attack speeds, buff them a little?
rabbits feel now better that default, maybe even a slight dmg nerf is needed still
nobody played dog, other than to counter wolf, maybe hes too weak against other species? maybe he feels sluggish and underpowered when comparing to wolf?
 */