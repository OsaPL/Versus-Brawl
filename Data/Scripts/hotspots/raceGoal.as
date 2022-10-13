
void Init() {

}

void SetParameters() {

}

void Update(){

}

void Dispose(){

}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        if(mo.is_player){
            PlaySoundGroup("Data/Sounds/versus/fight_win1.xml");
        }
    }
}