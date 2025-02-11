#include "aschar.as"
#include "situationawareness.as"

// Drunk mode
bool drunkMode = false;

bool DrunkModeInputDownCheck(int controllerId, string action){
    if(drunkMode){
        if(action == "item"){
            return GetInputDown(this_mo.controller_id, "drop");
        }
        else if(action == "drop"){
            return GetInputDown(this_mo.controller_id, "item");
        }
        else if(action == "grab"){
            return GetInputDown(this_mo.controller_id, "attack");
        }
        else if(action == "attack"){
            return GetInputDown(this_mo.controller_id, "grab");
        }
        else if(action == "jump"){
            return GetInputDown(this_mo.controller_id, "crouch");
        }
        else if(action == "crouch"){
            return GetInputDown(this_mo.controller_id, "jump");
        }

        DisplayError("DrunkModeInputDownCheck", "Not supported action: " + action);
        return GetInputDown(controllerId, action);
    }
    else{
        return GetInputDown(controllerId, action);
    }
}

bool DrunkModeInputPressedCheck(int controllerId, string action){
    if(drunkMode){
        if(action == "item"){
            return GetInputPressed(this_mo.controller_id, "drop");
        }
        else if(action == "drop"){
            return GetInputPressed(this_mo.controller_id, "item");
        }
        else if(action == "grab"){
            return GetInputPressed(this_mo.controller_id, "attack");
        }
        else if(action == "attack"){
            return GetInputPressed(this_mo.controller_id, "grab");
        }
        else if(action == "jump"){
            return GetInputPressed(this_mo.controller_id, "crouch");
        }
        else if(action == "crouch"){
            return GetInputPressed(this_mo.controller_id, "jump");
        }

        DisplayError("DrunkModeInputPressedCheck", "Not supported action: " + action);
        return GetInputPressed(controllerId, action);
    }
    else{
        return GetInputPressed(controllerId, action);
    }
}

float DrunkModeGetMoveYAxis(int controllerId){
    if(drunkMode){
        return GetMoveYAxis(controllerId) * -1;
    }
    else{
        return GetMoveYAxis(controllerId);
    }
}
float DrunkModeGetMoveXAxis(int controllerId){
    if(drunkMode){
        return GetMoveXAxis(controllerId) * -1;
    }
    else{
        return GetMoveXAxis(controllerId);
    }
}

// Already noticed characters
array<NoticedCharacter@> alreadyNoticedIds = {};
class NoticedCharacter {
    int objId;
    float lastNoticedTime;
    NoticedCharacter(int newObjId, float newLastNoticedTime){
        objId = newObjId;
        lastNoticedTime = newLastNoticedTime;
    }
}
// After what time, trigger notice sound again
float noticeCooldown = 120.0f;
// Colldown before combat sound
float attackCooldown = 1.5f;
float lastAttackTime = 0.0f;
int chanceToSkip = 10;
// Last char state
int lastState = 0;
///

float grab_key_time;
bool listening = false;
bool delay_jump;

const float kWalkSpeed = 0.2f;

// For pressing crouch to drop off ledges
bool crouch_pressed_on_ledge = false;
bool crouch_pressable_on_ledge = false;

Situation situation;
int got_hit_by_leg_cannon_count = 0;

int IsUnaware() {
    return 0;
}

enum DropKeyState {
    _dks_nothing,
        _dks_pick_up,
        _dks_drop,
        _dks_throw
};

DropKeyState drop_key_state = _dks_nothing;

enum ItemKeyState {
    _iks_nothing,
        _iks_sheathe,
        _iks_unsheathe
};

ItemKeyState item_key_state = _iks_nothing;

void AIMovementObjectDeleted(int id) {
}

string GetIdleOverride() {
    return "";
}

float last_noticed_time;

void DrawAIStateDebug() {
}

void DrawStealthDebug() {
}

bool DeflectWeapon() {
    return active_blocking;
}

int IsAggro() {
    return 1;
}

bool StuckToNavMesh() {
    return false;
}

float timeSinceLastDropKeyPress = 0;
float maxTimeForQuickDrop = 0.5f;

void UpdateBrain(const Timestep &in ts) {
    EnterTelemetryZone("playercontrol.as UpdateBrain");
    startled = false;

    if(DrunkModeInputDownCheck(this_mo.controller_id, "grab")) {
        grab_key_time += ts.step();
    } else {
        grab_key_time = 0.0f;
    }

    // Allows for easier item dropping by just tapping `drop` two times
    if(DrunkModeInputPressedCheck(this_mo.controller_id, "drop")) {
        if(maxTimeForQuickDrop > timeSinceLastDropKeyPress &&
            (weapon_slots[primary_weapon_slot] != -1 || weapon_slots[secondary_weapon_slot] != -1))
            drop_key_state = _dks_drop;

        timeSinceLastDropKeyPress = 0;
    } else {
        timeSinceLastDropKeyPress += ts.step();
    }

    if(ledge_info.on_ledge && !DrunkModeInputDownCheck(this_mo.controller_id, "crouch")) {
        crouch_pressable_on_ledge = true;
    } else if(!ledge_info.on_ledge) {
        crouch_pressable_on_ledge = false;
        crouch_pressed_on_ledge = false;
    }

    if(DrunkModeInputDownCheck(this_mo.controller_id, "crouch") && crouch_pressable_on_ledge) {
        crouch_pressed_on_ledge = true;
    }

    // Use this if you want to limit the sounds made while in combat
    if(lastAttackTime + attackCooldown < time){
        // Check if state changed
        if(lastState != state){
            lastState = state;
            if(state == _attack_state){
                if(rand()%100 > chanceToSkip)
                    this_mo.PlaySoundGroupVoice("attack", 0.0f);
                
                lastAttackTime = time;
            }
            else if(state == _hit_reaction_state){
                if(rand()%100 > chanceToSkip)
                    this_mo.PlaySoundGroupVoice("hit", 0.0f);
    
                lastAttackTime = time;
            }
        }
    }

    if(time > last_noticed_time + 0.2f) {
        bool shouldSendSound = false;
        bool isThisSus = false;

        array<int> characters;
        GetVisibleCharacters(0, characters);

        for(uint i = 0; i < characters.size(); ++i) {
            situation.Notice(characters[i]);

            // Added
            MovementObject @char = ReadCharacterID(characters[i]);

            //Log(error, "sanity check: " + char.GetID() + " shouldnt be: " + this_mo.GetID());

            if (!ReadObjectFromID(char.GetID()).GetEnabled() || char.GetID() == this_mo.GetID()) {
                continue;
            }

            bool found = false;
            for (uint j = 0; j < alreadyNoticedIds.size(); j++)
            {
                //Log(error, "checking: " + alreadyNoticedIds[j].objId + " if its: " + char.GetID());
                //Log(error, "time: " + time + " if its over: " + (alreadyNoticedIds[j].lastNoticedTime));
                //Log(error, "checking: " + alreadyNoticedIds[j].objId + " if its: " + char.GetID());
                if (alreadyNoticedIds[j].objId == char.GetID()) {
                    found = true;
                    //Log(error, "found: " + char.GetID());

                    if (alreadyNoticedIds[j].lastNoticedTime + noticeCooldown < time) {
                        alreadyNoticedIds[j].lastNoticedTime = time;
                        shouldSendSound = true;
                        //Log(error, "should notice!");
                    }
                    break;
                }
            }
            // Not found it, we should probably play sound
            if (!found) {
                //Log(error, "pushing new: " + char.GetID());
                shouldSendSound = true;
                alreadyNoticedIds.push_back(NoticedCharacter(char.GetID(), time));
            }

            if(shouldSendSound){
                if (this_mo.OnSameTeam(char)) {
                    if (char.GetIntVar("knocked_out") != _awake) {
                        isThisSus = true;
                        shouldSendSound = true;
                        //Log(error, "isThisSus state");
                    }
                    else{
                        shouldSendSound = false;
                    }
                }
                else {
                    if (char.GetIntVar("knocked_out") == _awake) {
                        // Play engage
                        shouldSendSound = true;
                        //Log(error, "engage state");
                    }
                    else{
                        shouldSendSound = false;
                    }
                }
            }
        }

        last_noticed_time = time;

        if(shouldSendSound){
            if(isThisSus){
                //Log(error, "suspicious play");
                this_mo.PlaySoundGroupVoice("suspicious", 0.0f);
            }
            else{
                //Log(error, "engage play");
                this_mo.PlaySoundGroupVoice("engage", 0.0f);
            }
        }
    }

    force_look_target_id = situation.GetForceLookTarget();


    if(!DrunkModeInputDownCheck(this_mo.controller_id, "drop")) {
        if(maxTimeForQuickDrop < timeSinceLastDropKeyPress){
            drop_key_state = _dks_drop;
        }

        drop_key_state = _dks_nothing;
    } else if (drop_key_state == _dks_nothing) {
        if((weapon_slots[primary_weapon_slot] == -1 || (weapon_slots[secondary_weapon_slot] == -1 && duck_amount < 0.5f)) &&
        GetNearestPickupableWeapon(this_mo.position, _pick_up_range) != -1) {
            drop_key_state = _dks_pick_up;
        } else {
            if(DrunkModeInputDownCheck(this_mo.controller_id, "crouch") &&
                duck_amount > 0.5f &&
            on_ground &&
            !flip_info.IsFlipping() &&
            GetThrowTarget() == -1 &&
            target_rotation2 < -60.0f) {
                drop_key_state = _dks_drop;
            } else if(DrunkModeInputDownCheck(this_mo.controller_id, "grab") && tethered != _TETHERED_REARCHOKE ) {
                drop_key_state = _dks_drop;
            } else {
                drop_key_state = _dks_throw;
            }
        }
    }

    int primary_weapon_id = weapon_slots[primary_weapon_slot];
    string label = "";

    if(primary_weapon_id != -1) {
        label = ReadItemID(weapon_slots[primary_weapon_slot]).GetLabel();
    }

    if (!DrunkModeInputDownCheck(this_mo.controller_id, "item")){
        item_key_state = _iks_nothing;
    } else if (item_key_state == _iks_nothing) {
        if (primary_weapon_id == -1
            || (primary_weapon_id == -1 && weapon_slots[secondary_weapon_slot] == -1 && (weapon_slots[_sheathed_left] != -1 || weapon_slots[_sheathed_right] != -1) && !IsHolding2HandedWeapon())) {
            ////Log(error, "_iks_unsheathe!");
            item_key_state = _iks_unsheathe;
        } else {  // if(held_weapon != -1 && sheathed_weapon == -1) {
            ////Log(error, "_iks_sheathe!");
            item_key_state = _iks_sheathe;
        }
    }

    if(delay_jump && !DrunkModeInputDownCheck(this_mo.controller_id, "jump")) {
        delay_jump = false;
    }

    LeaveTelemetryZone();
}

void AIEndAttack() {

}

vec3 GetTargetJumpVelocity() {
    return vec3(0.0f);
}

bool TargetedJump() {
    return false;
}

bool IsAware() {
    return true;
}

void ResetMind() {
    situation.clear();
    got_hit_by_leg_cannon_count = 0;
}

int IsIdle() {
    return 0;
}

void HandleAIEvent(AIEvent event) {
    if(event == _climbed_up) {
        delay_jump = true;
    }
}

void MindReceiveMessage(string msg) {
}

bool WantsToCrouch() {
    if(!this_mo.controlled) {
        return false;
    }

    return DrunkModeInputDownCheck(this_mo.controller_id, "crouch");
}

bool WantsToRoll() {
    if(!this_mo.controlled) {
        return false;
    }

    return DrunkModeInputPressedCheck(this_mo.controller_id, "crouch");
}

bool WantsToJump() {
    if(!this_mo.controlled) {
        return false;
    }

    return DrunkModeInputDownCheck(this_mo.controller_id, "jump") && !delay_jump;
}

bool WantsToAttack() {
    if(!this_mo.controlled) {
        return false;
    }

    if(on_ground) {
        return DrunkModeInputDownCheck(this_mo.controller_id, "attack");
    } else {
        return DrunkModeInputPressedCheck(this_mo.controller_id, "attack");
    }
}

bool WantsToRollFromRagdoll() {
    if(game_difficulty <= 0.4 && on_ground) {
        return true;
    }

    if(!this_mo.controlled) {
        return false;
    }

    return DrunkModeInputPressedCheck(this_mo.controller_id, "crouch");
}

void BrainSpeciesUpdate() {

}

bool ActiveDodging(int attacker_id) {
    bool knife_attack = false;
    MovementObject@ char = ReadCharacterID(attacker_id);
    int enemy_primary_weapon_id = GetCharPrimaryWeapon(char);

    if(enemy_primary_weapon_id != -1) {
        ItemObject@ weap = ReadItemID(enemy_primary_weapon_id);

        if(weap.GetLabel() == "knife") {
            knife_attack = true;
        }
    }

    if(attack_getter2.GetFleshUnblockable() == 1 && knife_attack) {
        return active_dodge_time > time - (HowLongDoesActiveDodgeLast() + 0.2);  // Player gets bonus to dodge vs knife attacks
    } else {
        return active_dodge_time > time - HowLongDoesActiveDodgeLast();
    }
}

bool ActiveBlocking() {
    return active_blocking;
}

bool WantsToFlip() {
    if(!this_mo.controlled) {
        return false;
    }

    return DrunkModeInputPressedCheck(this_mo.controller_id, "crouch");
}

bool WantsToGrabLedge() {
    if(!this_mo.controlled) {
        return false;
    }

    if(GetConfigValueBool("auto_ledge_grab")) {
        return !crouch_pressed_on_ledge;
    } else {
        return DrunkModeInputDownCheck(this_mo.controller_id, "grab");
    }
}

bool WantsToThrowEnemy() {
    if(!this_mo.controlled) {
        return false;
    }

    // if(holding_weapon) {
    //     return false;
    // }

    return grab_key_time > 0.2f;
}

void Startle() {
}

bool WantsToDragBody() {
    if(!this_mo.controlled) {
        return false;
    }

    return DrunkModeInputDownCheck(this_mo.controller_id, "grab");
}

bool WantsToPickUpItem() {
    if(!this_mo.controlled) {
        return false;
    }

    if(species == _wolf) {
        return false;
    }

    return drop_key_state == _dks_pick_up;
}

bool WantsToDropItem() {
    if(!this_mo.controlled) {
        return false;
    }

    if(species == _wolf) {
        return true;
    }

    return drop_key_state == _dks_drop;
}

bool WantsToThrowItem() {
    if(!this_mo.controlled) {
        return false;
    }

    return drop_key_state == _dks_throw;
}

bool WantsToThroatCut() {
    if(!this_mo.controlled) {
        return false;
    }

    return DrunkModeInputDownCheck(this_mo.controller_id, "attack") || drop_key_state != _dks_nothing;
}

bool WantsToSheatheItem() {
    if(!this_mo.controlled) {
        return false;
    }

    return item_key_state == _iks_sheathe;
}

bool WantsToUnSheatheItem(int &out src) {
    if(!this_mo.controlled) {
        return false;
    }

    // Cant unsheathe if you holding a 2 handed weapon
    if(weapon_slots[primary_weapon_slot] != -1) {
        if(Is2HandedItemObject(weapon_slots[primary_weapon_slot])) {
            return false;
        }
    }

    if(item_key_state != _iks_unsheathe && throw_weapon_time < time - 0.2) {
        return false;
    }

    src = -1;

    // More intelligent weapon selection code
    // TODO: Extend?
    if(GetInputDown(this_mo.controller_id, "attack") && weapon_slots[_sheathed_right_back] != -1){
        src = _sheathed_right_back;
    }
    else if(GetInputDown(this_mo.controller_id, "grab") && weapon_slots[_sheathed_left] != -1){
        src = _sheathed_left;
    }
    else if(GetInputDown(this_mo.controller_id, "grab") && weapon_slots[_sheathed_right] != -1){
        src = _sheathed_right;
    }
    // If everything fails above, just take the biggest one
    else if(weapon_slots[_sheathed_left_back] != -1 && weapon_slots[secondary_weapon_slot] == -1) {
        ////Log(error, "_sheathed_left_back");
        src = _sheathed_left_back;
    }
    else if(weapon_slots[_sheathed_right_back] != -1 && weapon_slots[secondary_weapon_slot] == -1) {
        ////Log(error, "_sheathed_right_back");
        src = _sheathed_right_back;
    }
    else if(weapon_slots[_sheathed_left] != -1 && weapon_slots[_sheathed_right] != -1) {
        // If we have two weapons, draw better one

        // If for some reason weapon disappeared, just clear slot and go on.
        if(!ObjectExists(weapon_slots[_sheathed_left])){
            weapon_slots[_sheathed_left] = -1;
            return false;
        }
        string label1 = ReadItemID(weapon_slots[_sheathed_left]).GetLabel();

        if(!ObjectExists(weapon_slots[_sheathed_right])){
            weapon_slots[_sheathed_right] = -1;
            return false;
        }
        string label2 = ReadItemID(weapon_slots[_sheathed_right]).GetLabel();

        if((label1 == "sword" || label1 == "rapier") && label2 == "knife") {
            src = _sheathed_left;
        } else {
            src = _sheathed_right;
        }
    } else if(weapon_slots[_sheathed_right] != -1) {
        src = _sheathed_right;
    } else if(weapon_slots[_sheathed_left] != -1) {
        src = _sheathed_left;
    }

    // Lastly we check whether my hands are free to hold it if 2handed (if weapon choice combos are being used)
    if(weapon_slots[primary_weapon_slot] != -1 || weapon_slots[secondary_weapon_slot] != -1){
        if(Is2HandedItemObject(weapon_slots[src])) {
            return false;
        }
    }

    lastUnsheateSrc = src;

    return true;
}


bool WantsToStartActiveBlock(const Timestep &in ts) {
    if(!this_mo.controlled) {
        return false;
    }

    return DrunkModeInputDownCheck(this_mo.controller_id, "grab");
}

bool WantsToFeint() {
    if(!this_mo.controlled || game_difficulty <= 0.5) {
        return false;
    } else {
        return DrunkModeInputDownCheck(this_mo.controller_id, "grab");
    }
}

bool WantsToCounterThrow() {
    if(!this_mo.controlled) {
        return false;
    }

    return DrunkModeInputDownCheck(this_mo.controller_id, "grab") && !DrunkModeInputDownCheck(this_mo.controller_id, "attack");
}

bool WantsToJumpOffWall() {
    if(!this_mo.controlled) {
        return false;
    }

    return DrunkModeInputPressedCheck(this_mo.controller_id, "jump");
}

bool WantsToFlipOffWall() {
    if(!this_mo.controlled) {
        return false;
    }

    return DrunkModeInputPressedCheck(this_mo.controller_id, "crouch");
}

bool WantsToAccelerateJump() {
    if(!this_mo.controlled) {
        return false;
    }

    return DrunkModeInputDownCheck(this_mo.controller_id, "jump");
}

vec3 GetDodgeDirection() {
    return GetTargetVelocity();
}

bool WantsToDodge(const Timestep &in ts) {
    if(!this_mo.controlled) {
        return false;
    }

    vec3 targ_vel = GetTargetVelocity();
    bool movement_key_down = false;

    if(length_squared(targ_vel) > 0.1f) {
        movement_key_down = true;
    }

    return movement_key_down;
}

bool WantsToCancelAnimation() {
    return GetInputDown(this_mo.controller_id, "jump") ||
        GetInputDown(this_mo.controller_id, "crouch") ||
        GetInputDown(this_mo.controller_id, "grab") ||
        GetInputDown(this_mo.controller_id, "attack") ||
        GetInputDown(this_mo.controller_id, "move_up") ||
        GetInputDown(this_mo.controller_id, "move_left") ||
        GetInputDown(this_mo.controller_id, "move_right") ||
        GetInputDown(this_mo.controller_id, "move_down");
}

// Converts the keyboard controls into a target velocity that is used for movement calculations in aschar.as and aircontrol.as.
vec3 GetTargetVelocity() {
    vec3 target_velocity(0.0f);

    if(!this_mo.controlled) {
        return target_velocity;
    }

    vec3 right;

    {
        right = camera.GetFlatFacing();
        float side = right.x;
        right.x = -right .z;
        right.z = side;
    }

    target_velocity -= DrunkModeGetMoveYAxis(this_mo.controller_id) * camera.GetFlatFacing();
    target_velocity += DrunkModeGetMoveXAxis(this_mo.controller_id) * right;

    if(GetInputDown(this_mo.controller_id, "walk")) {
        if(length_squared(target_velocity)>kWalkSpeed * kWalkSpeed) {
            target_velocity = normalize(target_velocity) * kWalkSpeed;
        }
    } else {
        if(length_squared(target_velocity)>1) {
            target_velocity = normalize(target_velocity);
        }
    }

    if(trying_to_get_weapon > 0) {
        target_velocity = get_weapon_dir;
    }

    return target_velocity;
}

// Called from aschar.as, bool front tells if the character is standing still. Only characters that are standing still may perform a front kick.
void ChooseAttack(bool front, string &out attack_str) {
    attack_str = "";

    if(on_ground) {
        if(!WantsToCrouch()) {
            if(front) {
                attack_str = "stationary";
            } else {
                attack_str = "moving";
            }
        } else {
            attack_str = "low";
        }
    } else {
        attack_str = "air";
    }
}

WalkDir WantsToWalkBackwards() {
    return FORWARDS;
}

bool WantsReadyStance() {
    return true;
}

int CombatSong() {
    return situation.PlayCombatSong() ? 1 : 0;
}

int IsAggressive() {
    return 0;
}

int GetLeftFootPlanted() {
    if(foot[0].progress == 1.0f) {
        return 1;
    } else {
        return 0;
    }
}

int GetRightFootPlanted() {
    Log(info, "progress " + foot[1].progress);

    if(foot[1].progress >= 1.0f) {
        return 1;
    } else {
        return 0;
    }
}