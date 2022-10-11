#include "ui_effects.as"
#include "music_load.as"
#include "ui_tools.as"
#include "speciesStats.as"

MusicLoad ml("Data/Music/challengelevel.xml");

int controller_id = 0;
float time = 0.0f;
int score_leftUp = 0;
int score_rightUp = 0;
int score_leftDown = 0;
int score_rightDown = 0;
float reset_timer = 2.0f;
float end_game_delay = 0.0f;
uint player_number;
uint currentState=99;
bool failsafe;

int playerIconSize = 100;

// All objects spawned by the script
array<int> spawned_object_ids;

void Init(string p_level_name) {
    versus_gui.Init();
    FindSpawnPoints();
    // Spawn 4 players, otherwise it gets funky and spawns a player where editor camera was
    for(int i = 0; i < 4; i++)
    {
        SpawnCharacter(FindRandSpawnPoint(i),CreateCharacter(i, IntToSpecies(currentRace[i])));
    }
}

// Stolen from arena_level.as
enum MessageParseType {
    kSimple = 0,
    kOneInt = 1,
    kTwoInt = 2
}

array<bool> respawnNeeded ={false,false,false,false};
array<float> respawnQueue ={-100,-100,-100,-100};
float respawnTime = 2;
// This will block any stupid respawns calls from hotspots that kill on the way to spawn
float respawnBlockTime = 0.5;

void ReceiveMessage(string msg) {
    TokenIterator token_iter;
    token_iter.Init();
    if(!token_iter.FindNextToken(msg)){
        return;
    }
    string token = token_iter.GetToken(msg);
    if(token == "reset"){
        DeleteObjectsInList(spawned_object_ids);
        for(uint i = 0; i < player_number; i++)
        {
            SpawnCharacter(FindRandSpawnPoint(i),CreateCharacter(i, IntToSpecies(currentRace[i])));
        }
        time = 0.0f;
        reset_timer = 2.0f;
    } else if(token == "manual_reset"){
        ClearVersusScores();
    }

    // Handle simple tokens, or mark as requiring extra parameters
    MessageParseType type = kSimple;

    if( token != "added_object" && token != "notify_deleted" )
    {
        //Log( info, "ArenaMessage: " + msg );
    }

    if(token == "knocked_over" ||
        token == "passive_blocked" ||
        token == "active_blocked" ||
        token == "dodged" ||
        token == "character_attack_feint" ||
        token == "character_attack_missed" ||
        token == "character_throw_escape" ||
        token == "character_thrown" ||
        token == "cut")
    {
        type = kTwoInt;
    } else if(token == "character_died" ||
        token == "character_knocked_out" ||
        token == "character_start_flip" ||
        token == "character_start_roll" ||
        token == "character_failed_flip"||
        token == "item_hit")
    {
        type = kOneInt;
    }

    if(type == kOneInt) {
        token_iter.FindNextToken(msg);
        int char_a = atoi(token_iter.GetToken(msg));
        if(token == "character_died") {
            Log(info, "Player "+char_a+" was killed");
        } else if(token == "character_knocked_out") {
            Log(info, "Player "+char_a+" was knocked out");
        } else if(token == "character_start_flip") {
            Log(info, "Player "+char_a+" started a flip");
        } else if(token == "character_start_roll") {
            Log(info, "Player "+char_a+" started a roll");
        } else if(token == "character_failed_flip") {
            Log(info, "Player "+char_a+" failed a flip");
        } else if(token == "item_hit") {
            Log(info, "Player "+char_a+" was hit by an item");
        }

        if( token == "character_died" )
        {
            
            // This should respawn on kill
            if(currentState==0){
                for (uint i = 0; i < spawned_object_ids.size(); i++) {
                    if(spawned_object_ids[i] == char_a){
                        CallRespawn(i, char_a);
                    }
                }
            }
            
            // if(char_a != battle.playerObjectId ) TODO! What is this checking?
            // {
            //     Object@ player_obj = ReadObjectFromID(battle.playerObjectId);
            //     ScriptParams@ player_params = player_obj.GetScriptParams();
            //
            //     Object@ other_obj = ReadObjectFromID(char_a);
            //     ScriptParams@ other_params = other_obj.GetScriptParams();
            //
            //
            //     if( player_params.GetString("Teams") != other_params.GetString("Teams") )
            //     {
            //         //msh.PlayerKilledCharacter();
            //         Log(info,"Player got a kill\n");
            //         global_data.player_kills++;
            //     }
            // }
            // else
            // {
            //     //msh.PlayerDied();
            //     Log(info,"Player got mortally wounded\n");
            // }
        }
        else if( token == "character_knocked_out" )
        {
            // This should respawn on kill
            if(currentState==0){
                for (uint i = 0; i < spawned_object_ids.size(); i++) {
                    if(spawned_object_ids[i] == char_a){
                        CallRespawn(i, char_a);
                    }
                }
            }
            
            // if( char_a != battle.playerObjectId )
            // {
            //     Object@ player_obj = ReadObjectFromID(battle.playerObjectId);
            //     ScriptParams@ player_params = player_obj.GetScriptParams();
            //
            //     Object@ other_obj = ReadObjectFromID(char_a);
            //     ScriptParams@ other_params = other_obj.GetScriptParams();
            //
            //     if( player_params.GetString("Teams") != other_params.GetString("Teams") )
            //     {
            //         //msh.PlayerKilledCharacter();
            //         Log(info,"Player got a ko\n");
            //     }
            // }
            // else
            // {
            //     ///msh.PlayerDied();
            // }
        }
    } else if(type == kTwoInt) {
        token_iter.FindNextToken(msg);
        int char_a = atoi(token_iter.GetToken(msg));
        token_iter.FindNextToken(msg);
        int char_b = atoi(token_iter.GetToken(msg));
        if(token == "knocked_over") {
            Log(info, "Player "+char_a+" was knocked over by player "+char_b);
        } else if(token == "passive_blocked") {
            Log(info, "Player "+char_a+" passive-blocked an attack by player "+char_b);
        } else if(token == "active_blocked") {
            Log(info, "Player "+char_a+" active-blocked an attack by player "+char_b);
        } else if(token == "dodged") {
            Log(info, "Player "+char_a+" dodged an attack by player "+char_b);
        } else if(token == "character_attack_feint") {
            Log(info, "Player "+char_a+" feinted an attack aimed at "+char_b);
        } else if(token == "character_attack_missed") {
            Log(info, "Player "+char_a+" missed an attack aimed at "+char_b);
        } else if(token == "character_throw_escape") {
            Log(info, "Player "+char_a+" escaped a throw attempt by "+char_b);
        } else if(token == "character_thrown") {
            Log(info, "Player "+char_a+" was thrown by "+char_b);
        } else if(token == "cut") {
            Log(info, "Player "+char_a+" was cut by "+char_b);
        }
    }
}

void CallRespawn(int playerNr, int objId){
    if(!respawnNeeded[playerNr] && respawnQueue[playerNr]<-respawnBlockTime){
        respawnNeeded[playerNr] = true;
        respawnQueue[playerNr]= respawnTime;
        Object@ char = ReadObjectFromID(objId);
        MovementObject@ mo = ReadCharacterID(objId);
        Log(error, "Respawn requested objId:"+objId+" playerNr:"+playerNr);
    }
}

void DrawGUI() {
    versus_gui.DrawGUI(); 
}

// This thingamajig extract key name for text dialogs
string InsertKeysToString( string text )
{
    for( uint i = 0; i < text.length(); i++ ) {
    if( text[i] == '@'[0] ) {
        for( uint j = i + 1; j < text.length(); j++ ) {
            if( text[j] == '@'[0] ) {
                string first_half = text.substr(0,i);
                string second_half = text.substr(j+1);
                string input = text.substr(i+1,j-i-1);
                //TODO! This can be fix to also support keyboard mappings if I use the same:
                //bool use_keyboard = (max(last_mouse_event_time, last_keyboard_event_time) > last_controller_event_time);
                // as in aschar.as
                string middle = GetStringDescriptionForBinding("gamepad_0", input);

                text = first_half + middle + second_half;
                i += middle.length();
                break;
            }
        }
    }
}
    return text;
}

class VersusAHGUI : AHGUI::GUI {
    VersusAHGUI() {
        // Call the superclass to set things up
        super();
    }
    
    bool layoutChanged = true;
    string text="1";
    string extraText="2";
    int assignmentTextSize = 70;
    int footerTextSize = 50;
    bool showBorders = false;
    bool initUI = true;

 
    array<string> currentIcon =  {"","","",""};
    array<bool> currentGlow =  {false,false,false,false};
    
    void Render() {
        // Update the background
        // TODO: fold this into AHGUI
        hud.Draw();

        // Update the GUI
        AHGUI::GUI::render();
    }

    void processMessage( AHGUI::Message@ message ) {
    }

    void UpdateText(){
        AHGUI::Element@ headerElement = root.findElement("header");
        if( headerElement is null  ) {
            DisplayError("GUI Error", "Unable to find header");
        }
        AHGUI::Divider@ header = cast<AHGUI::Divider>(headerElement);
        // Get rid of the old contents
        header.clear();
        header.clearUpdateBehaviors();
        header.setDisplacement();
        DisplayText(DDTop, header, 8, text, 90, vec4(1,1,1,1), extraText, 70);
    }

    void ChangeIcon(int playerIdx, int iconNr, bool glow)
    {
        AHGUI::Element@ headerElement = root.findElement("quitButton"+playerIdx);
        AHGUI::Image@ quitButton = cast<AHGUI::Image>(headerElement);
        string iconPath;
        if(iconNr == -1){
            // For -1 we use generic icon
            iconPath= placeholderRaceIconPath;
        }else{
            iconPath=speciesMap[iconNr].RaceIcon;
        }
        if(currentIcon[playerIdx] != iconPath){
            currentIcon[playerIdx] = iconPath;
            
            quitButton.setImageFile(iconPath);
            quitButton.scaleToSizeX(playerIconSize);
        }
        
        if(currentGlow[playerIdx] != glow){
            Log(error, "glow"+glow);
            currentGlow[playerIdx] = glow;
            if(glow){
                quitButton.setColor(vec4(0.7,0.7,0.7,0.8));
            }
            else{
                quitButton.setColor(vec4(1.0,1.0,1.0,1.0));
            }
            quitButton.scaleToSizeX(playerIconSize);
        }
    }

    void CheckForUIChange(){
        if(initUI){
            initUI = false;
            //TODO: #1 this is a dumb fix for the whole UI being moved a little to right for some reason

            //Violet 
            AHGUI::Divider@ container = root.addDivider( DDCenter,  DOVertical, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );
            container.setVeritcalAlignment(BACenter);
            if(showBorders){
                container.setBorderSize(5);
                container.setBorderColor(1.0, 0.0, 1.0, 1.0);
                container.showBorder();
            }

            //Cyan For Text
            AHGUI::Divider@ header = container.addDivider( DDTopLeft,  DOVertical, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );
            header.setName("header");
            header.setVeritcalAlignment(BARight);
            header.setHorizontalAlignment(BABottom);
            if(showBorders){
                header.setBorderSize(3);
                header.setBorderColor(0.0, 1.0, 1.0, 1.0);
                header.showBorder();
            }
            
            AHGUI::Divider@ containerBottom = root.addDivider( DDTop,  DOHorizontal, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );
            AHGUI::Divider@ containerTop = root.addDivider( DDBottom,  DOHorizontal, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );

            //Yellow
            AHGUI::Divider@ header3 = containerBottom.addDivider( DDRight,  DOHorizontal, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );
            header3.setName("header3");
            header3.setVeritcalAlignment(BALeft);
            header3.setHorizontalAlignment(BABottom);
            if(showBorders){
                header3.setBorderSize(3);
                header3.setBorderColor(1.0, 1.0, 0.0, 1.0);
                header3.showBorder();
            }

            AHGUI::Image@ quitButton3 = AHGUI::Image(placeholderRaceIconPath);
            //#1
            quitButton3.setPadding(0,0,0,70);
            quitButton3.scaleToSizeX(playerIconSize);
            quitButton3.setName("quitButton3");
            header3.addElement(quitButton3,DDLeft);

            
            //Blue
            AHGUI::Divider@ header2 = containerBottom.addDivider( DDLeft,  DOHorizontal, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );
            header2.setName("header2");
            header2.setVeritcalAlignment(BALeft);
            header2.setHorizontalAlignment(BABottom);
            if(showBorders){
                header2.setBorderSize(3);
                header2.setBorderColor(0.0, 0.0, 1.0, 1.0);
                header2.showBorder();
            }

            AHGUI::Image@ quitButton2 = AHGUI::Image(placeholderRaceIconPath);
            quitButton2.scaleToSizeX(playerIconSize);
            quitButton2.setName("quitButton2");
            header2.addElement(quitButton2,DDLeft);

            //Red
            AHGUI::Divider@ header1 = containerTop.addDivider( DDRight,  DOHorizontal, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );
            header1.setName("header1");
            header1.setVeritcalAlignment(BALeft);
            header1.setHorizontalAlignment(BABottom);
            if(showBorders){
                header1.setBorderSize(3);
                header1.setBorderColor(1.0, 0.0, 0.0, 1.0);
                header1.showBorder();
            }

            AHGUI::Image@ quitButton1 = AHGUI::Image(placeholderRaceIconPath);
            quitButton1.scaleToSizeX(playerIconSize);
            //#1
            quitButton1.setPadding(0,0,0,70);
            quitButton1.setName("quitButton1");
            header1.addElement(quitButton1,DDLeft);

            //Green
            AHGUI::Divider@ header0 = containerTop.addDivider( DDLeft,  DOHorizontal, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );
            header0.setName("header0");
            header0.setVeritcalAlignment(BALeft);
            header0.setHorizontalAlignment(BABottom);
            if(showBorders){
                header0.setBorderSize(3);
                header0.setBorderColor(0.0, 1.0, 0.0, 1.0);
                header0.showBorder();
            }

            AHGUI::Image@ quitButton0 = AHGUI::Image(placeholderRaceIconPath);
            quitButton0.scaleToSizeX(playerIconSize);
            quitButton0.setName("quitButton0");
            header0.addElement(quitButton0,DDLeft);
        }
        
        if(layoutChanged){
            layoutChanged = false;
        }
        UpdateText();
        AHGUI::GUI::update();
    }

    void DisplayText(DividerDirection dd, AHGUI::Divider@ div, int maxWords, string text, int textSize, vec4 color, string extraTextVal = "", int extraTextSize = 0) {
        //The maxWords is the amount of words per line.
        array<string> sentences;

        text = InsertKeysToString( text );

        array<string> words = text.split(" ");
        string sentence;
        for(uint i = 0; i < words.size(); i++){
            sentence += words[i] + " ";
            if((i+1) % maxWords == 0 || words.size() == (i+1)){
                sentences.insertLast(sentence);
                sentence = "";
            }
        }
        for(uint k = 0; k < sentences.size(); k++){
            AHGUI::Text singleSentence( sentences[k], "OpenSans-Regular", textSize, color.x, color.y, color.z, color.a );
            singleSentence.setShadowed(true);
            //singleSentence.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );
            div.addElement(singleSentence, dd);
            if(showBorders){
                singleSentence.setBorderSize(1);
                singleSentence.setBorderColor(1.0, 1.0, 1.0, 1.0);
                singleSentence.showBorder();
            }
        }
        if(extraTextVal != ""){
            AHGUI::Text extraSentence(extraTextVal, "OpenSans-Regular", extraTextSize, color.x, color.y, color.z, color.a );
            extraSentence.setShadowed(true);
            div.addElement(extraSentence, dd);
        }
    }
    
    void Update(){
        CheckForUIChange();
        AHGUI::GUI::update();
    }
}

class VersusGUI_ScoreMark {
    bool mirrored;
    bool lit;
    float scale_mult;
};

class VersusGUI  {
    float player_one_win_alpha;
    float player_two_win_alpha;
	float player_three_win_alpha;
	float player_four_win_alpha;
    float blackout_amount;
    float score_change_time;

    VersusAHGUI versusAHGUI;
    
    array<VersusGUI_ScoreMark> rightUp_score_marks;
    array<VersusGUI_ScoreMark> leftUp_score_marks;
	array<VersusGUI_ScoreMark> rightDown_score_marks;
    array<VersusGUI_ScoreMark> leftDown_score_marks;

    VersusGUI(){
        rightUp_score_marks.resize(5);
        leftUp_score_marks.resize(5);
		rightDown_score_marks.resize(5);
        leftDown_score_marks.resize(5);
    }
    
    void Init() {
        player_one_win_alpha = 0.0f;
        player_two_win_alpha = 0.0f;
        player_three_win_alpha = 0.0f;
        player_four_win_alpha = 0.0f;
		player_number = 2;
        blackout_amount = 0.0f;
        score_change_time = 0.0f;
		failsafe = true;
		array<int> movement_objects = GetObjectIDsType(_movement_object);
		
        for(int i=0; i<5; ++i){
            rightUp_score_marks[i].mirrored = false;
            rightUp_score_marks[i].lit = false;
            rightUp_score_marks[i].scale_mult = 1.0f;
        }
        for(int i=0; i<5; ++i){
            rightDown_score_marks[i].mirrored = false;
            rightDown_score_marks[i].lit = false;
            rightDown_score_marks[i].scale_mult = 1.0f;
        }        
        for(int i=0; i<5; ++i){
            leftUp_score_marks[i].mirrored = true;
            leftUp_score_marks[i].lit = false;
            leftUp_score_marks[i].scale_mult = 1.0f;
        }
        for(int i=0; i<5; ++i){
            leftDown_score_marks[i].mirrored = true;
            leftDown_score_marks[i].lit = false;
            leftDown_score_marks[i].scale_mult = 1.0f;
        }
		
		
    }
    void Update(){
        versusAHGUI.Update();
        for(int i=0; i<5; ++i){
            if(rightUp_score_marks[i].lit){
                rightUp_score_marks[i].scale_mult = mix(1.0f, rightUp_score_marks[i].scale_mult, 0.9f);
            } else {
                rightUp_score_marks[i].scale_mult = mix(0.0f, rightUp_score_marks[i].scale_mult, 0.9f);
            }
        }
        for(int i=0; i<5; ++i){
            if(leftUp_score_marks[i].lit){
                leftUp_score_marks[i].scale_mult = mix(1.0f, leftUp_score_marks[i].scale_mult, 0.9f);
            } else {
                leftUp_score_marks[i].scale_mult = mix(0.0f, leftUp_score_marks[i].scale_mult, 0.9f);
            }
        }
		        for(int i=0; i<5; ++i){
            if(rightDown_score_marks[i].lit){
                rightDown_score_marks[i].scale_mult = mix(1.0f, rightDown_score_marks[i].scale_mult, 0.9f);
            } else {
                rightDown_score_marks[i].scale_mult = mix(0.0f, rightDown_score_marks[i].scale_mult, 0.9f);
            }
        }
        for(int i=0; i<5; ++i){
            if(leftDown_score_marks[i].lit){
                leftDown_score_marks[i].scale_mult = mix(1.0f, leftDown_score_marks[i].scale_mult, 0.9f);
            } else {
                leftDown_score_marks[i].scale_mult = mix(0.0f, leftDown_score_marks[i].scale_mult, 0.9f);
            }
        }
    }
    
    void SetText(string maintext, string subtext=""){
        versusAHGUI.text = InsertKeysToString(maintext);
        versusAHGUI.extraText = InsertKeysToString(subtext);
        versusAHGUI.layoutChanged = true;
    }

    void ChangeIcon(int playerIdx, int iconNr, bool glow){
        versusAHGUI.ChangeIcon(playerIdx, iconNr, glow);
    }

    void DrawGUI(){
        versusAHGUI.Render();
        
        float ui_scale = GetScreenWidth() / 4000.0f;//2560.0f
		
		HUDImage @leftup_portrait_image = hud.AddImage();
        leftup_portrait_image.SetImageFromPath("Data/Textures/ui/versus_mode/rabbit_1_portrait.tga");
        leftup_portrait_image.position.y = GetScreenHeight() - 512 * ui_scale * 0.6f;
        leftup_portrait_image.position.x = GetScreenWidth() * 0.5 - 850 * ui_scale;
        leftup_portrait_image.position.z = 1.0f;
        leftup_portrait_image.scale = vec3(ui_scale * 0.6f);
        
        HUDImage @rightup_portrait_image = hud.AddImage();
        rightup_portrait_image.SetImageFromPath("Data/Textures/ui/versus_mode/rabbit_2_portrait.tga");
        rightup_portrait_image.position.y = GetScreenHeight() - 512 * ui_scale * 0.6f;
        rightup_portrait_image.position.x = GetScreenWidth() * 0.5 + 530 * ui_scale;
        rightup_portrait_image.position.z = 1.0f;
        rightup_portrait_image.scale = vec3(ui_scale * 0.6f);
		
        HUDImage @top_crete_image = hud.AddImage();
        top_crete_image.SetImageFromPath("Data/Textures/ui/versus_mode/top_crete.tga");
        top_crete_image.position.y = GetScreenHeight() - 256 * ui_scale;
        top_crete_image.position.x = GetScreenWidth() * 0.5 - 1024 * ui_scale;
        top_crete_image.scale = vec3(ui_scale);
        
		if(player_number >= 3){
		HUDImage @leftdown_portrait_image = hud.AddImage();
        leftdown_portrait_image.SetImageFromPath("Data/Textures/ui/versus_mode/rabbit_3_portrait.tga");
        leftdown_portrait_image.position.y = GetScreenHeight() - 700 * ui_scale * 0.6f;
        leftdown_portrait_image.position.x = GetScreenWidth() * 0.5 - 740 * ui_scale;
        leftdown_portrait_image.position.z = 0.99f; //for consistency, reason look down
        leftdown_portrait_image.scale = vec3(ui_scale * 0.5f);
		}
		
		if(player_number == 4){
		HUDImage @rightdown_portrait_image = hud.AddImage();
		rightdown_portrait_image.SetImageFromPath("Data/Textures/ui/versus_mode/rabbit_4_portrait.tga");
        rightdown_portrait_image.position.y = GetScreenHeight() - 700 * ui_scale * 0.6f;
        rightdown_portrait_image.position.x = GetScreenWidth() * 0.5 + 460 * ui_scale;
        rightdown_portrait_image.position.z = 0.99f; //to fix overlap? doesnt happen to the leftdown portrait
        rightdown_portrait_image.scale = vec3(ui_scale * 0.5f);
        }
		
        HUDImage @leftup_vignette_image = hud.AddImage();
        leftup_vignette_image.SetImageFromPath("Data/Textures/ui/versus_mode/corner_vignette.tga");
        leftup_vignette_image.position.y = GetScreenHeight() - 256 * ui_scale * 2.0f;
        leftup_vignette_image.position.x = 0.0f;
        leftup_vignette_image.position.z = -1.0f;
        leftup_vignette_image.scale = vec3(ui_scale * 2.0f);
        
        HUDImage @rightup_vignette_image = hud.AddImage();
        rightup_vignette_image.SetImageFromPath("Data/Textures/ui/versus_mode/corner_vignette.tga");
        rightup_vignette_image.position.y = GetScreenHeight() - 256 * ui_scale * 2.0f;
        rightup_vignette_image.position.x = GetScreenWidth();
        rightup_vignette_image.position.z = -1.0f;
        rightup_vignette_image.scale = vec3(ui_scale * 2.0f);
        rightup_vignette_image.scale.x *= -1.0f;        
        
        HUDImage @blackout_image = hud.AddImage();
        blackout_image.SetImageFromPath("Data/Textures/diffuse.tga");
        blackout_image.position.y = (GetScreenWidth() + GetScreenHeight())*-1.0f;
        blackout_image.position.x = (GetScreenWidth() + GetScreenHeight())*-1.0f;
        blackout_image.position.z = -2.0f;
        blackout_image.scale = vec3(GetScreenWidth() + GetScreenHeight())*2.0f;
        blackout_image.color = vec4(0.0f,0.0f,0.0f,blackout_amount);
        
        HUDImage @blackout_over_image = hud.AddImage();
        blackout_over_image.SetImageFromPath("Data/Textures/diffuse.tga");
        blackout_over_image.position.y = 0;
        blackout_over_image.position.x = 0;
        blackout_over_image.position.z = 2.0f;
        blackout_over_image.scale = vec3(GetScreenWidth() + GetScreenHeight());
        blackout_over_image.color = vec4(0.0f,0.0f,0.0f,max(player_one_win_alpha,player_two_win_alpha)*0.5f);
        
        HUDImage @player_one_win_image = hud.AddImage();
        player_one_win_image.SetImageFromPath("Data/Textures/ui/versus_mode/rabbit_1_win.tga");
        float player_one_scale = 1.5f + sin(player_one_win_alpha*1.570796f) * 0.2f;
        player_one_win_image.position.y = GetScreenHeight() * 0.5 - 512 * ui_scale * player_one_scale;
        player_one_win_image.position.x = GetScreenWidth() * 0.5 - 512 * ui_scale * player_one_scale;
        player_one_win_image.position.z = 3.0f;
        player_one_win_image.scale = vec3(ui_scale * player_one_scale);
        player_one_win_image.color.a = player_one_win_alpha;
        
        HUDImage @player_two_win_image = hud.AddImage();
        player_two_win_image.SetImageFromPath("Data/Textures/ui/versus_mode/rabbit_2_win.tga");
        float player_two_scale = 1.5f + sin(player_two_win_alpha*1.570796f) * 0.2f;
        player_two_win_image.position.y = GetScreenHeight() * 0.5 - 512 * ui_scale * player_two_scale;
        player_two_win_image.position.x = GetScreenWidth() * 0.5 - 512 * ui_scale * player_two_scale;
        player_two_win_image.position.z = 3.0f;
        player_two_win_image.scale = vec3(ui_scale * player_two_scale);
        player_two_win_image.color.a = player_two_win_alpha;
		
		HUDImage @player_three_win_image = hud.AddImage();
        player_three_win_image.SetImageFromPath("Data/Textures/ui/versus_mode/rabbit_3_win.tga_converted.dds");
        float player_three_scale = 1.5f + sin(player_three_win_alpha*1.570796f) * 0.2f;
        player_three_win_image.position.y = GetScreenHeight() * 0.5 - 512 * ui_scale * player_three_scale;
        player_three_win_image.position.x = GetScreenWidth() * 0.5 - 512 * ui_scale * player_three_scale;
        player_three_win_image.position.z = 3.0f;
        player_three_win_image.scale = vec3(ui_scale * player_three_scale);
        player_three_win_image.color.a = player_three_win_alpha;
        
        HUDImage @player_four_win_image = hud.AddImage();
        player_four_win_image.SetImageFromPath("Data/Textures/ui/versus_mode/rabbit_4_win.tga_converted.dds");
        float player_four_scale = 1.5f + sin(player_four_win_alpha*1.570796f) * 0.2f;
        player_four_win_image.position.y = GetScreenHeight() * 0.5 - 512 * ui_scale * player_four_scale;
        player_four_win_image.position.x = GetScreenWidth() * 0.5 - 512 * ui_scale * player_four_scale;
        player_four_win_image.position.z = 3.0f;
        player_four_win_image.scale = vec3(ui_scale * player_four_scale);
        player_four_win_image.color.a = player_four_win_alpha;
        
        for(int i=0; i<5; ++i){ //rightup
            float special_scale = 1.0f;
            HUDImage @hud_image = hud.AddImage();
            hud_image.SetImageFromPath("Data/Textures/ui/versus_mode/match_mark.tga");
            hud_image.position.y = GetScreenHeight() - (122 + 128 * special_scale) * ui_scale;
            hud_image.position.x = GetScreenWidth() * 0.5 + (498 - 128 * special_scale) * ui_scale - i * 90 * ui_scale;
            hud_image.scale = vec3(ui_scale * 0.6f * special_scale);
            special_scale = rightUp_score_marks[i].scale_mult;
            HUDImage @glow_image = hud.AddImage();
            glow_image.SetImageFromPath("Data/Textures/ui/versus_mode/match_win.tga");
            glow_image.position.y = GetScreenHeight() - (122 + 128 * special_scale) * ui_scale;
            glow_image.position.z = 0.1f;
            glow_image.position.x = GetScreenWidth() * 0.5 + (498 - 128 * special_scale) * ui_scale - i * 90 * ui_scale;
            glow_image.scale = vec3(ui_scale * 0.6f * special_scale);
            glow_image.color.a = 1.0f - abs(special_scale - 1.0f);
        }
		if(player_number == 4)
		for(int i=0; i<5; ++i){ //rightdown
            float special_scale = 1.0f;
            HUDImage @hud_image = hud.AddImage();
            hud_image.SetImageFromPath("Data/Textures/ui/versus_mode/match_mark.tga");
            hud_image.position.y = GetScreenHeight() - (122 + 256 * special_scale) * ui_scale;
            hud_image.position.x = GetScreenWidth() * 0.5 + (498 - 228 * special_scale) * ui_scale - i * 90 * ui_scale;
            hud_image.scale = vec3(ui_scale * 0.6f * special_scale);
            special_scale = rightDown_score_marks[i].scale_mult;
            HUDImage @glow_image = hud.AddImage();
            glow_image.SetImageFromPath("Data/Textures/ui/versus_mode/match_win.tga");
            glow_image.position.y = GetScreenHeight() - (122 + 256 * special_scale) * ui_scale;
            glow_image.position.z = 0.1f;
            glow_image.position.x = GetScreenWidth() * 0.5 + (498 - 228 * special_scale) * ui_scale - i * 90 * ui_scale;
            glow_image.scale = vec3(ui_scale * 0.6f * special_scale);
            glow_image.color.a = 1.0f - abs(special_scale - 1.0f);
        }
		
        for(int i=0; i<5; ++i){ //left up
            float special_scale = 1.0f;
            HUDImage @hud_image = hud.AddImage();
            hud_image.SetImageFromPath("Data/Textures/ui/versus_mode/match_mark.tga");
            hud_image.position.y = GetScreenHeight() - (122 + 128 * special_scale) * ui_scale;
            hud_image.position.x = GetScreenWidth() * 0.5 - (528 - 128 * special_scale) * ui_scale + i * 90 * ui_scale;
            hud_image.scale = vec3(ui_scale * 0.6f * special_scale);
            hud_image.scale.x *= -1.0f;
            special_scale = leftUp_score_marks[i].scale_mult;
            HUDImage @glow_image = hud.AddImage();
            glow_image.SetImageFromPath("Data/Textures/ui/versus_mode/match_win.tga");
            glow_image.position.y = GetScreenHeight() - (122 + 128 * special_scale) * ui_scale;
            glow_image.position.z = 0.1f;
            glow_image.position.x = GetScreenWidth() * 0.5 - (528 - 128 * special_scale) * ui_scale + i * 90 * ui_scale;
            glow_image.scale = vec3(ui_scale * 0.6f * special_scale);
            glow_image.scale.x *= -1.0f;
            glow_image.color.a = 1.0f - abs(special_scale - 1.0f);
        }
		if(player_number >= 3)
        for(int i=0; i<5; ++i){ //left down
            float special_scale = 1.0f;
            HUDImage @hud_image = hud.AddImage();
            hud_image.SetImageFromPath("Data/Textures/ui/versus_mode/match_mark.tga");
            hud_image.position.y = GetScreenHeight() - (122 + 256 * special_scale) * ui_scale;
            hud_image.position.x = GetScreenWidth() * 0.5 - (528 - 228 * special_scale) * ui_scale + i * 90 * ui_scale;
            hud_image.scale = vec3(ui_scale * 0.6f * special_scale);
            hud_image.scale.x *= -1.0f;
            special_scale = leftDown_score_marks[i].scale_mult;
            HUDImage @glow_image = hud.AddImage();
            glow_image.SetImageFromPath("Data/Textures/ui/versus_mode/match_win.tga");
            glow_image.position.y = GetScreenHeight() - (122 + 256 * special_scale) * ui_scale;
            glow_image.position.z = 0.1f;
            glow_image.position.x = GetScreenWidth() * 0.5 - (528 - 228 * special_scale) * ui_scale + i * 90 * ui_scale;
            glow_image.scale = vec3(ui_scale * 0.6f * special_scale);
            glow_image.scale.x *= -1.0f;
            glow_image.color.a = 1.0f - abs(special_scale - 1.0f);
        }		
    }
    
    void IncrementScoreLeftUp(int score){
        leftUp_score_marks[score].lit = true;
        leftUp_score_marks[score].scale_mult = 2.0f;
    }
    
	void IncrementScoreLeftDown(int score){
        leftDown_score_marks[score].lit = true;
        leftDown_score_marks[score].scale_mult = 2.0f;
    }
	
    void IncrementScoreRightUp(int score){
        rightUp_score_marks[score].lit = true;
        rightUp_score_marks[score].scale_mult = 2.0f;
    }
	
	void IncrementScoreRightDown(int score){
        rightDown_score_marks[score].lit = true;
        rightDown_score_marks[score].scale_mult = 2.0f;
    }
    
    void ClearScores() {
        for(int i=0; i<5; ++i){
            leftUp_score_marks[i].lit = false;
            rightUp_score_marks[i].lit = false;
			leftDown_score_marks[i].lit = false;
            rightDown_score_marks[i].lit = false;
        }
		
    }
}

VersusGUI versus_gui;

array<Species@> speciesMap={
    Species("rabbit", "Textures/ui/arena_mode/glyphs/rabbit_foot_1x1.png",
        {
            "Data/Objects/characters/rabbits/male_rabbit_2_actor.xml", 
            "Data/Objects/IGF_Characters/pale_turner_actor.xml"
        }),
    Species("dog", "Textures/ui/arena_mode/glyphs/fighter_swords.png",
        {
            "Data/Objects/characters/dogs/light_armored_dog_male_1_actor.xml"
        }),
    Species("cat", "Textures/ui/arena_mode/glyphs/contender_crown.png",
        {
            "Data/Objects/characters/cats/female_cat_actor.xml"
        }),
    Species("rat", "Textures/ui/arena_mode/glyphs/slave_shackles.png",
        {
            "Data/Objects/characters/rats/hooded_rat_actor.xml"
        }),
    Species("wolf", "Textures/ui/arena_mode/glyphs/skull.png",
        {
            "Data/Objects/characters/wolves/male_wolf_actor.xml"
        })
};

void CreateSpecies(){
    speciesMap.resize(5);
    array<string> rabbitChars = {""};
}

class Species{
    string Name;
    string RaceIcon;
    array<string> CharacterPaths;
    Species(string newName, string newRaceIcon, array<string> newCharacterPaths){
        Name = newName;
        CharacterPaths = newCharacterPaths;
        RaceIcon = newRaceIcon;
    }
}
string placeholderRaceIconPath = "Textures/ui/challenge_mode/quit_icon_c.tga";

array<uint> currentRace = {0,1,2,3};

string GetSpeciesRandCharacterPath(string species)
{
    // Dumb usage of uint, I know, shouldve used std::vector<T>::size_type ofc
    for (uint i = 0; i < speciesMap.size(); i++)
    {
        if (speciesMap[i].Name == species) {
            // Species found, now get a random entry
            if(speciesMap[i].CharacterPaths is null){
                DisplayError("GetSpeciesRandCharacterPath", "GetSpeciesRandCharacterPath found that speciesMap["+i+"].CharacterPaths is null"); 
            }

            return speciesMap[i].CharacterPaths[
                rand()%speciesMap[i].CharacterPaths.size()];
        }
    }
    DisplayError("GetSpeciesRandCharacterPath", "GetSpeciesRandCharacterPath couldnt find any paths for species: " + species);
    return "Data/Objects/characters/rabbot_actor.xml";
}
// This creates a pseudo random character by juggling all available parameters
Object@ CreateCharacter(int playerNr, string species){
    // Select random species character and create it
    string characterPath = GetSpeciesRandCharacterPath(species);
    int obj_id = CreateObject(characterPath, true);
    // Remember to track him for future cleanup
    spawned_object_ids.push_back(obj_id);
    Object@ char_obj = ReadObjectFromID(obj_id);
    
    // Setup
    MovementObject@ mo = ReadCharacterID(char_obj.GetID());
    character_getter.Load(mo.char_path);
    ScriptParams@ params = char_obj.GetScriptParams();
    // Some small tweaks to make it look more unique
    // Scale, Muscle and Fat has to be 0-1 range
    //TODO: these would be cool to have governing variables (max_fat, minimum_fat etc.)
    //TODO! Scale is overwritten by addSpeciesStats() atm!
    float scale = (90.0+(rand()%15))/100;
    params.SetFloat("Character Scale", scale);
    float muscles = (50.0+((rand()%15)))/100;
    params.SetFloat("Muscle", muscles);
    float fat = (50.0+((rand()%15)))/100;
    params.SetFloat("Fat", fat);
    
    // Color the dinosaur, or even the rabbit
    vec3 furColor = GetRandomFurColor();
    vec3 clothesColor = RandReasonableTeamColor(playerNr);
    
    for(int i = 0; i < 4; i++) {
        const string channel = character_getter.GetChannel(i);
        Log(error, "species:"+species + "channel:"+channel);
        //TODO: fill this up more, maybe even extract to a top level variable for easy edits?

        
        if(channel == "fur" ) {
            // These will use fur generator color, mixed with another
            char_obj.SetPaletteColor(i, mix(furColor, GetRandomFurColor(), 0.7));

            // Wolves are problematic for coloring all channels are marked as `fur`
            if(species == "wolf"){
                if(i==1 || i==4){
                    char_obj.SetPaletteColor(i, clothesColor);
                }
            }
        } else if(channel == "cloth" ) {
                char_obj.SetPaletteColor(i, clothesColor);
                clothesColor = mix(clothesColor, vec3(0.0), 0.9);
        }
    }

    // Reset any Teams
    //TODO: Here probably will be the team assignment stufff
    params.SetString("Teams", "");
    
    char_obj.UpdateScriptParams();
    
    // This will add species specific stats
    addSpeciesStats(char_obj);
    
    return char_obj;
}

//TODO! These colors are awful, make them slightly better?
vec3 RandReasonableWolfTeamColor(int playerNr){
    switch (playerNr) {
        case 0:return vec3(0.0,255.0,0.0);
        case 1:return vec3(255.0,0.0,0.0);
        case 2:return vec3(0.0,0.0,255.0);
        case 3:return vec3(255.0,255.0,0.0);
    }
    return vec3(255,255,255);
}
    
vec3 RandReasonableTeamColor(int playerNr){
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
    
// Just moves character into the position and activates him
void SpawnCharacter(Object@ spawn, Object@ char, bool isAlreadyPlayer = false)
{
    Log(warning, "spawn:"+spawn.GetTranslation().x+","+spawn.GetTranslation().y+","+spawn.GetTranslation().z);
    Log(warning, "char:"+char.GetID()+" isAlreadyPlayer"+isAlreadyPlayer);
    if(isAlreadyPlayer){
        MovementObject@ mo = ReadCharacterID(char.GetID());
        mo.position = spawn.GetTranslation();
        mo.velocity = vec3(0);
    }
    char.SetTranslation(spawn.GetTranslation());
    vec4 rot_vec4 = spawn.GetRotationVec4();
    quaternion q(rot_vec4.x, rot_vec4.y, rot_vec4.z, rot_vec4.a);
    char.SetRotation(q);

    if(!isAlreadyPlayer){
        char.SetPlayer(true);
    }

    //TODO: this probably should be called after everyone has spawned, for the best effect
    // Forces call `Notice` on all characters (helps with npc just standing there like morons)
    char.ReceiveScriptMessage("set_omniscient true");
}
    
// Find a suitable spawn
// TODO: `useGeneric` will take into account generic spawns
// TODO: `useOneType` will only take team spawns if `useGeneric = false` adn only generic spawns if `useGeneric = true`
Object@ FindRandSpawnPoint(int playerNr, bool useGeneric = false, bool useOneType=true){
    int obj_id = spawnPointIds[playerNr][
        rand()%(spawnPointIds[playerNr].size())];
    return ReadObjectFromID(obj_id);
}
    
//TODO!    
int SpeciesToInt(string species){
    return -1;
}

string IntToSpecies(int speciesNr){
    int speciesSize = speciesMap.size();
    if(speciesNr> speciesSize|| speciesNr<0){
        DisplayError("IntToSpecies", "Unsuported IntToSpecies value of: " + speciesNr);
        return "rabbot";
    }
    
    return speciesMap[speciesNr].Name;
}

void Update() {
    if(GetInputDown(0,"f8")){
        LoadLevel(GetCurrLevelRelPath());
    }

    if(GetInputDown(0,"f9")){

    }
    if(GetInputDown(0,"f10")) {
        MovementObject@ mo = ReadCharacter(0);
        Object@ char = ReadObjectFromID(mo.GetID());
        Object@ spawn = FindRandSpawnPoint(0);
        SpawnCharacter(FindRandSpawnPoint(0),char,true);
    }

    
    CheckPlayersState();
    // On first update we switch to warmup state
    if(currentState==99){
        ChangeGameState(0);
    }
    versus_gui.Update();
    time += time_step;
	if(currentState==2)
    VictoryCheckVersus();
    PlaySong("ambient-tense");
}

// This makes sure there is atleast a single spawn per playerNr
bool CheckSpawnsNumber(){
    for (int i = 0; i < 3; i++) {
        if(spawnPointIds[i].size() < 1)
            return false;
    }
    return true;
}

void CheckPlayersState(){
    if(currentState==0){
        if(!CheckSpawnsNumber() && failsafe) {
            //Warn about the incorrect number of spawns
            ChangeGameState(1);
        }
		array<int> movement_objects = GetObjectIDsType(_movement_object);
        
        //Select players number
		if(GetInputDown(0,"item") && !GetInputDown(0,"drop")){
			if(GetInputDown(0,"crouch")){
				player_number = 2;
                ChangeGameState(2); //Start game
			}
			if(GetInputDown(0,"jump")){
				player_number = 3;
                ChangeGameState(2); //Start game
			}
			if(GetInputDown(0,"attack")){
				player_number = 4;
                ChangeGameState(2); //Start game
			}
		}
        
        // Warmup respawning logic
        for (uint i = 0; i < respawnQueue.size() ; i++) {
            if(respawnQueue[i]>-respawnBlockTime){
                respawnQueue[i] = respawnQueue[i]-time_step;
                if(respawnQueue[i]<0 && respawnNeeded[i]){
                    respawnNeeded[i] = false;
                    MovementObject@ mo = ReadCharacter(i);
                    Object@ char = ReadObjectFromID(mo.GetID());
                    ScriptParams@ params = char.GetScriptParams();

                    // This line took me 4hrs to figure out
                    mo.Execute("SetState(0);Recover();");
                    
                    SpawnCharacter(FindRandSpawnPoint(i),char,true);
                }
            }
        }

    }
    else if(currentState==1) {
        if (GetInputDown(0, "item")) {
            failsafe = false;
            ChangeGameState(0);
        }
    }
    
    if(currentState==2 || currentState==0){
        for(int i=0; i<GetNumCharacters(); i++){
            if(GetInputDown(i,"item") && GetInputDown(i,"drop")) {
                if(GetInputPressed(i,"attack")) {
                    currentRace[i]= currentRace[i]+1;
                    currentRace[i]= currentRace[i]%speciesMap.size();
                }
                versus_gui.ChangeIcon(i, currentRace[i], true);
            }
            else {
                // Last element is always the default state icon
                versus_gui.ChangeIcon(i, -1, false);
            }
        }

    }
}

void ChangeGameState(uint newState){
    if(newState == currentState)
        return;
    switch (newState) {
        case 0: 
            //Warmup, select player number
            failsafe = true;
            currentState = newState;
            versus_gui.SetText("Hold @item@ and select player number by then pressing:",
                "@crouch@=2, @jump@=3, @attack@=4");
            break;
        case 1: 
            //Failsafe, not enough spawns, waiting for acknowledgment
            //TODO! Rewrite this for spawns
            if(failsafe){
                array<int> movement_objects = GetObjectIDsType(_movement_object);
                versus_gui.SetText("Warning! Only "+movement_objects.size()+" players detected!",
                    "After adding more player controlled characters, please save and reload the map. Press @item@ to play anyway.");

                return;
            }
            currentState = newState;
            break;
        case 2:
            //Game Start
            currentState = newState;
            // Clear text
            versus_gui.SetText("");
            level.SendMessage("reset");
            break;
    }
}

void IncrementScoreLeftUp(){
    if(score_leftUp < 5){
        versus_gui.IncrementScoreLeftUp(score_leftUp);
    }
    if(score_leftUp < 4){
        PlaySoundGroup("Data/Sounds/versus/fight_win1.xml");
    }
    ++score_leftUp;
}

void IncrementScoreRightUp() {
    if(score_rightUp < 5){
        versus_gui.IncrementScoreRightUp(score_rightUp);
    }
    if(score_rightUp < 4){
        PlaySoundGroup("Data/Sounds/versus/fight_win2.xml");
    }
    ++score_rightUp;
}

void IncrementScoreLeftDown(){
    if(score_leftDown < 5){
        versus_gui.IncrementScoreLeftDown(score_leftDown);
    }
    if(score_leftDown < 4){
        PlaySoundGroup("Data/Sounds/versus/fight_win1.xml");
    }
    ++score_leftDown;
}

void IncrementScoreRightDown() {
    if(score_rightDown < 5){
        versus_gui.IncrementScoreRightDown(score_rightDown);
    }
    if(score_rightDown < 4){
        PlaySoundGroup("Data/Sounds/versus/fight_win2.xml");
    }
    ++score_rightDown;
}

void ClearVersusScores(){
    score_leftUp = 0;
    score_rightUp = 0;
	score_leftDown = 0;
    score_rightDown = 0;
    versus_gui.ClearScores();        
}

int CheckScores(){
	int who_wins = -1;
	int max_score = -1;
	if(score_leftUp > max_score){
		max_score = score_leftUp;
		who_wins = 0;
	}
	if(score_rightUp > max_score){
		max_score = score_rightUp;
		who_wins = 1;
	}
	if((player_number > 2) && (score_leftDown > max_score)){
		max_score = score_leftDown;
		who_wins = 2;
	}
	if((player_number > 3) && (score_rightDown > max_score)){
		max_score = score_rightDown;
		who_wins = 3;
	}
	return who_wins;
}

void VictoryCheckVersus() {
    int which_alive = -1;
    int num_alive = 0;
	string alivenr = "";
    int num = GetNumCharacters();
	array<int> movement_objects = GetObjectIDsType(_movement_object);
	int mos = movement_objects.size();
    for(int i=0; i<num; ++i){
        MovementObject@ char = ReadCharacter(i);
        if(char.GetIntVar("knocked_out") == _awake){
            which_alive = i;
            ++num_alive;
			alivenr += " "+i;
        }
    }
    const float _blackout_speed = 2.0f;
    if(num_alive <= 1){
        if(reset_timer <= 1.0f / _blackout_speed){
            versus_gui.blackout_amount = min(1.0f, versus_gui.blackout_amount + time_step * _blackout_speed);
        }
        if(end_game_delay == 0.0f){
            reset_timer -= time_step;
            if(reset_timer <= 0.0f){
                if(num_alive == 1){
                    MovementObject @char = ReadCharacter(which_alive);
                    int controller = char.controller_id;
                    if(controller == 0){
                        IncrementScoreLeftUp();
                    }
					if(controller == 1){
                        IncrementScoreRightUp();
                    }
					if(controller == 2){
                        IncrementScoreLeftDown();
                    }
					if(controller == 3){
                        IncrementScoreRightDown();
                    }
					switch(CheckScores()){
					case 0:
						if(score_leftUp>=5){
							end_game_delay = 3.0f;
							PlaySound("Data/Sounds/versus/fight_end.wav");
						}
						else{
							level.SendMessage("reset");
						}break;
					case 1:
						if(score_rightUp>=5){
							end_game_delay = 3.0f;
							PlaySound("Data/Sounds/versus/fight_end.wav");
						}
						else{
							level.SendMessage("reset");
						}break;
					case 2:
						if(score_leftDown>=5){
							end_game_delay = 3.0f;
							PlaySound("Data/Sounds/versus/fight_end.wav");
						}
						else{
							level.SendMessage("reset");
						}break;
					case 3:
						if(score_rightDown>=5){
							end_game_delay = 3.0f;
							PlaySound("Data/Sounds/versus/fight_end.wav");
						}
						else{
							level.SendMessage("reset");
						}break;
					default:
					}
					
            }
			else{
				PlaySound("Data/Sounds/versus/fight_end.wav");
				level.SendMessage("reset");
			}
        }
		}
    } else {
        versus_gui.blackout_amount = max(0.0f, versus_gui.blackout_amount - time_step * _blackout_speed);
        reset_timer = 2.0f;
    }
    if(end_game_delay != 0.0f){
        float old_end_game_delay = end_game_delay;
        end_game_delay = max(0.0f, end_game_delay - time_step);
        if(old_end_game_delay > 2.0f && end_game_delay <= 2.0f){
			
            /*if(CheckScores()){
                PlaySound("Data/Sounds/versus/voice_end_1.wav");
            } else {
                PlaySound("Data/Sounds/versus/voice_end_2.wav");
            }*/
        }
        if(end_game_delay > 1.0f){
					switch(CheckScores()){
					case 0:
						versus_gui.player_one_win_alpha = min(1.0f, versus_gui.player_one_win_alpha + time_step);
						break;
					case 1:
						versus_gui.player_two_win_alpha = min(1.0f, versus_gui.player_two_win_alpha + time_step);
						break;
					case 2:
						versus_gui.player_three_win_alpha = min(1.0f, versus_gui.player_three_win_alpha + time_step);
						break;
					case 3:
						versus_gui.player_four_win_alpha = min(1.0f, versus_gui.player_four_win_alpha + time_step);
						break;
					default:
					}
        } else {
            versus_gui.player_one_win_alpha = max(0.0f, versus_gui.player_one_win_alpha - time_step);
            versus_gui.player_two_win_alpha = max(0.0f, versus_gui.player_two_win_alpha - time_step);
			versus_gui.player_three_win_alpha = max(0.0f, versus_gui.player_three_win_alpha - time_step);
            versus_gui.player_four_win_alpha = max(0.0f, versus_gui.player_four_win_alpha - time_step);
        }
        if(end_game_delay == 0.0f){
            ClearVersusScores();
            level.SendMessage("reset");
            PlaySound("Data/Sounds/versus/voice_start_1.wav");
        }
    } else {
        versus_gui.player_one_win_alpha = 0.0f;
        versus_gui.player_two_win_alpha = 0.0f;
		versus_gui.player_three_win_alpha = 0.0f;
        versus_gui.player_four_win_alpha = 0.0f;
    }
}

/// This code is just stolen from arena_level.as
Object@ SpawnObjectAtSpawnPoint(Object@ spawn, string &in path){
    int obj_id = CreateObject(path, true);
    spawned_object_ids.push_back(obj_id);
    Object @new_obj = ReadObjectFromID(obj_id);
    new_obj.SetTranslation(spawn.GetTranslation());
    vec4 rot_vec4 = spawn.GetRotationVec4();
    quaternion q(rot_vec4.x, rot_vec4.y, rot_vec4.z, rot_vec4.a);
    new_obj.SetRotation(q);
    return new_obj;
}
void DeleteObjectsInList(array<int> &inout ids){
    int num_ids = ids.length();
    for(int i=0; i<num_ids; ++i){
        Log(info, "Test");
        DeleteObjectID(ids[i]);
    }
    ids.resize(0);
}

vec3 GetRandomFurColor() {
    vec3 fur_color_byte;
    int rnd = rand() % 7;

    //TODO! Extend this
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
vec3 FloatTintFromByte(const vec3 &in tint){
    vec3 float_tint;
    float_tint.x = tint.x / 255.0f;
    float_tint.y = tint.y / 255.0f;
    float_tint.z = tint.z / 255.0f;
    return float_tint;
}
///

// indexes 0-3 are for playerNr ones, 4 is for generic spawns
array<array<int>> spawnPointIds={{},{},{},{},{},{}};

// Inspire, again, by how its done in arena_level.as 
//TODO: maybe add compatibility with default arena maps, just by replacing script with this one?
void FindSpawnPoints(){
    //TODO! Make spawnpoints supported in a better way, maybe also add clumping spawns together (useful for bigger maps)
    // Remove all spawned objects
    DeleteObjectsInList(spawned_object_ids);
    spawned_object_ids.resize(0);

    // Identify all the spawn points for the current game type
    array<int> @object_ids = GetObjectIDs();
    int num_objects = object_ids.length();
    for(int i=0; i<num_objects; ++i){
        
        //SetSpawnPointPreview(obj,level.GetPath("spawn_preview"));
        Object @obj = ReadObjectFromID(object_ids[i]);
        ScriptParams@ params = obj.GetScriptParams();
        if(params.HasParam("game_type")){
            // Check whether this spawn is "versusBrawl" type
            if(params.GetString("game_type")=="versusBrawl"){
                // Check for PlayerNr
                if(params.HasParam("playerNr")) {
                    int playerNr= params.GetInt("playerNr");
                    if(playerNr < -1 || playerNr > 3){
                        DisplayError("FindSpawnPoints Error", "Spawn has PlayerNr less than -1 and greater than 3");
                    }
                    if(playerNr==-1){
                        // If its -1, its a generic spawn point, add it to the 5th array (generic spawns)
                        spawnPointIds[4].resize(spawnPointIds[4].size() + 1);
                        spawnPointIds[4][spawnPointIds[4].size()] = object_ids[i];
                    }
                    else{
                        // If its 0 or greater, make sure it lands on the correct playerIndex array
                        spawnPointIds[playerNr].resize(spawnPointIds[playerNr].size() + 1);
                        spawnPointIds[playerNr][spawnPointIds[playerNr].size()-1] = object_ids[i];
                    }
                }
            }
        }
    }
}
