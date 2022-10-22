﻿void addSpeciesStats(Object@ char){

    ScriptParams@ params = char.GetScriptParams();
    string species = character_getter.GetTag("species");
    MovementObject@ mo = ReadCharacterID(char.GetID());
    character_getter.Load(mo.char_path);

    // Reset any Teams
    params.SetString("Teams", "");
    
    //TODO! Stats to implement:
    //1)jump height
    //2)No blocking
    //TODO! Extract it to top level for ease of editing if needed
    if(species == "rabbit"){
        params.SetFloat("Attack Damage",    1.0); //params.AddFloatSlider("Attack Damage", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Attack Knockback", 1.0); //params.AddFloatSlider("Attack Knockback", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Attack Speed",     1.0); //params.AddFloatSlider("Attack Speed", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Damage Resistance",0.7); //params.AddFloatSlider("Damage Resistance", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Movement Speed",   0.8); //params.AddFloatSlider("Movement Speed", 1, "min:0.1,max:1.5,step:0.1,text_mult:100");
        params.SetFloat("Character Scale",  0.9); //params.AddFloatSlider("Character Scale", 1, "min:0.6,max:1.4,step:0.02,text_mult:100");
        
        // Jump slightly higher
        params.SetFloat("Jump - Initial Velocity",    7.0);//params.AddFloatSlider("Jump - Initial Velocity", 5.0, "min:0.1,max:50.0,step:0.01,text_mult:1");
        params.SetFloat("Jump - Air Control",         2.0);//params.AddFloatSlider("Jump - Air Control", 3.0, "min:0.0,max:50.0,step:0.01,text_mult:1");
        params.SetFloat("Jump - Jump Sustain",        5.0);//params.AddFloatSlider("Jump - Jump Sustain", 5.0, "min:0.0,max:50.0,step:0.01,text_mult:1");
        params.SetFloat("Jump - Jump Sustain Boost", 10.0);//params.AddFloatSlider("Jump - Jump Sustain Boost", 10.0, "min:0.0,max:100.0,step:0.01,text_mult:1");
    }
    else if(species == "dog"){
        params.SetFloat("Attack Damage",      1.2); //params.AddFloatSlider("Attack Damage", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Attack Knockback",   1.2); //params.AddFloatSlider("Attack Knockback", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Attack Speed",       0.8); //params.AddFloatSlider("Attack Speed", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Damage Resistance",  1.2); //params.AddFloatSlider("Damage Resistance", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Movement Speed",     0.8); //params.AddFloatSlider("Movement Speed", 1, "min:0.1,max:1.5,step:0.1,text_mult:100");
        params.SetFloat("Character Scale",    1.0); //params.AddFloatSlider("Character Scale", 1, "min:0.6,max:1.4,step:0.02,text_mult:100");

        //High, short, and slow jumps
        params.SetFloat("Jump - Initial Velocity",    10.0);//params.AddFloatSlider("Jump - Initial Velocity", 5.0, "min:0.1,max:50.0,step:0.01,text_mult:1");
        params.SetFloat("Jump - Air Control",         1.5);//params.AddFloatSlider("Jump - Air Control", 3.0, "min:0.0,max:50.0,step:0.01,text_mult:1");
        params.SetFloat("Jump - Jump Sustain",        3.0);//params.AddFloatSlider("Jump - Jump Sustain", 5.0, "min:0.0,max:50.0,step:0.01,text_mult:1");
        params.SetFloat("Jump - Jump Sustain Boost",  1.0);//params.AddFloatSlider("Jump - Jump Sustain Boost", 10.0, "min:0.0,max:100.0,step:0.01,text_mult:1");

        //TODO! These still make dog throw inaccurate
        params.SetFloat("Throw - Initial Velocity Multiplier",  2.0);//params.AddFloatSlider("Throw - Initial Velocity Multiplier", 1.0, "min:0.1,max:50.0,step:0.01,text_mult:1");
        params.SetFloat("Throw - Mass Multiplier",  1.0);//params.AddFloatSlider("Throw - Mass Multiplier", 1.0, "min:0.0,max:50.0,step:0.01,text_mult:1");
    }
    else if(species == "cat"){
        params.SetFloat("Attack Damage",       1.0); //params.AddFloatSlider("Attack Damage", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Attack Knockback",    0.6); //params.AddFloatSlider("Attack Knockback", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Attack Speed",        1.2); //params.AddFloatSlider("Attack Speed", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Damage Resistance",   0.5); //params.AddFloatSlider("Damage Resistance", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Movement Speed",      1.2); //params.AddFloatSlider("Movement Speed", 1, "min:0.1,max:1.5,step:0.1,text_mult:100");
        params.SetFloat("Character Scale",     1.0); //params.AddFloatSlider("Character Scale", 1, "min:0.6,max:1.4,step:0.02,text_mult:100");

        //Low, far and fast jumps
        params.SetFloat("Jump - Initial Velocity",    7.0);//params.AddFloatSlider("Jump - Initial Velocity", 5.0, "min:0.1,max:50.0,step:0.01,text_mult:1");
        params.SetFloat("Jump - Air Control",         5.0);//params.AddFloatSlider("Jump - Air Control", 3.0, "min:0.0,max:50.0,step:0.01,text_mult:1");
        params.SetFloat("Jump - Jump Sustain",        1.0);//params.AddFloatSlider("Jump - Jump Sustain", 5.0, "min:0.0,max:50.0,step:0.01,text_mult:1");
        params.SetFloat("Jump - Jump Sustain Boost",  1.0);//params.AddFloatSlider("Jump - Jump Sustain Boost", 10.0, "min:0.0,max:100.0,step:0.01,text_mult:1");

        params.SetFloat("Fall Damage Multiplier",0); //params.AddFloatSlider("Fall Damage Multiplier", default_fall_damage_multiplier, "min:0,max:10,step:0.1,text_mult:1");
    }
    else if(species == "rat"){
        params.SetFloat("Attack Damage",    0.7); //params.AddFloatSlider("Attack Damage", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Attack Knockback", 1.5); //params.AddFloatSlider("Attack Knockback", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Attack Speed",     1.2); //params.AddFloatSlider("Attack Speed", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Damage Resistance",0.5); //params.AddFloatSlider("Damage Resistance", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Movement Speed",   1.2); //params.AddFloatSlider("Movement Speed", 1, "min:0.1,max:1.5,step:0.1,text_mult:100");
        params.SetFloat("Character Scale",  0.9); //params.AddFloatSlider("Character Scale", 1, "min:0.6,max:1.4,step:0.02,text_mult:100");

        //Lowest, slightly further and fastest jumps
        params.SetFloat("Jump - Initial Velocity",    3.5);//params.AddFloatSlider("Jump - Initial Velocity", 5.0, "min:0.1,max:50.0,step:0.01,text_mult:1");
        params.SetFloat("Jump - Air Control",         4.0);//params.AddFloatSlider("Jump - Air Control", 3.0, "min:0.0,max:50.0,step:0.01,text_mult:1");
        params.SetFloat("Jump - Jump Sustain",        12.0);//params.AddFloatSlider("Jump - Jump Sustain", 5.0, "min:0.0,max:50.0,step:0.01,text_mult:1");
        params.SetFloat("Jump - Jump Sustain Boost", 12.0);//params.AddFloatSlider("Jump - Jump Sustain Boost", 10.0, "min:0.0,max:100.0,step:0.01,text_mult:1");

        params.SetInt("Knockout Shield",    1); //params.AddIntSlider("Knockout Shield", 0, "min:0,max:10");
    }
    else if(species == "wolf"){
        params.SetFloat("Attack Damage",    0.15); //params.AddFloatSlider("Attack Damage", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Attack Knockback", 0.7); //params.AddFloatSlider("Attack Knockback", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Attack Speed",     0.4); //params.AddFloatSlider("Attack Speed", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Damage Resistance",1.2); //params.AddFloatSlider("Damage Resistance", 1, "min:0,max:2,step:0.1,text_mult:100");
        params.SetFloat("Movement Speed",   0.5); //params.AddFloatSlider("Movement Speed", 1, "min:0.1,max:1.5,step:0.1,text_mult:100");
        params.SetFloat("Character Scale",  1.0); //params.AddFloatSlider("Character Scale", 1, "min:0.6,max:1.4,step:0.02,text_mult:100");

        //Really high, short, and slow jumps
        params.SetFloat("Jump - Initial Velocity",    10.0);//params.AddFloatSlider("Jump - Initial Velocity", 5.0, "min:0.1,max:50.0,step:0.01,text_mult:1");
        params.SetFloat("Jump - Air Control",         1.0);//params.AddFloatSlider("Jump - Air Control", 3.0, "min:0.0,max:50.0,step:0.01,text_mult:1");
        params.SetFloat("Jump - Jump Sustain",        5.0);//params.AddFloatSlider("Jump - Jump Sustain", 5.0, "min:0.0,max:50.0,step:0.01,text_mult:1");
        params.SetFloat("Jump - Jump Sustain Boost", 5.0);//params.AddFloatSlider("Jump - Jump Sustain Boost", 10.0, "min:0.0,max:100.0,step:0.01,text_mult:1");
    }

    char.UpdateScriptParams();
    //Log(error, "Added stats to:"+species);
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