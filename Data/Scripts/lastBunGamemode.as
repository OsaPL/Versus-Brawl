#include "versusmode.as"
// ^^ only this is needed





// IMPORTANT NOTE
// If youre reading this file while trying to implement your own stuff, stop.
// This file is full of awfully unoptimized code, error prone variables names, copy-pasta like youve never seen and old-pre AHGUI/Imgui implementation of the ui.
// I did this only to port the old versus mode over, since its still fun.





MusicLoad ml("Data/Music/challengelevel.xml");

int controller_id = 0;

//Old UI stuff
int score_leftUp = 0;
int score_rightUp = 0;
int score_leftDown = 0;
int score_rightDown = 0;

//Versus values
float timeLBS = 0.0f;
float reset_timer = 2.0f;
float end_game_delay = 0.0f;
int players_number;

//Level methods
void Init(string msg){
    // LBS specific hints
    warmupHints.insertAt(0, "Survivor gets the point, thats it.");
    randomHints.insertAt(0, "Watching the fights unfold, is a way for sure.");
    
    forcedSpecies = -1;
    
    //Always need to call this first!
    VersusInit("");

    players_number = versusPlayers.size();
    
    //Gamemode specific below
    versus_gui.Init();
    
    levelTimer.Add(LevelEventJob("manual_reset", function(_params){
        ClearVersusScores();
        return true;
    }));
    levelTimer.Add(LevelEventJob("reset", function(_params){
        timeLBS = 0.0f;
        reset_timer = 2.0f;
        return true;
    }));
}

void DrawGUI() {
    //Always need to call this first!
    VersusDrawGUI();
    
    versus_gui.DrawGUI();
}

void Update(){
    //Always need to call this first!
    VersusUpdate();
    
    timeLBS += time_step;
    if(currentState==2)
        VictoryCheckVersus();
    versus_gui.Update();
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

// Gamemode stuff resides here
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
    if((players_number > 2) && (score_leftDown > max_score)){
        max_score = score_leftDown;
        who_wins = 2;
    }
    if((players_number > 3) && (score_rightDown > max_score)){
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

// UI stuff
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
        blackout_amount = 0.0f;
        score_change_time = 0.0f;
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

    void DrawGUI(){
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

        if(players_number >= 3){
            HUDImage @leftdown_portrait_image = hud.AddImage();
            leftdown_portrait_image.SetImageFromPath("Data/Textures/ui/versus_mode/rabbit_3_portrait.tga");
            leftdown_portrait_image.position.y = GetScreenHeight() - 700 * ui_scale * 0.6f;
            leftdown_portrait_image.position.x = GetScreenWidth() * 0.5 - 740 * ui_scale;
            leftdown_portrait_image.position.z = 0.99f; //for consistency, reason look down
            leftdown_portrait_image.scale = vec3(ui_scale * 0.5f);
        }

        if(players_number == 4){
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
        if(players_number == 4)
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
        if(players_number >= 3)
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

void IncrementScoreLeftUp() {
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

void IncrementScoreLeftDown() {
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

void ClearVersusScores() {
    score_leftUp = 0;
    score_rightUp = 0;
    score_leftDown = 0;
    score_rightDown = 0;
    versus_gui.ClearScores();
}