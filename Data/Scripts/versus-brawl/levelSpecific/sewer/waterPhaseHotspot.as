void Init() {
    Object@ me = ReadObjectFromID(hotspot.GetID());
    me.SetScale(vec3(1, 0.1f, 1));
    hotspot.SetCollisionEnabled(false);
}

void SetParameters() {
    params.AddIntSlider("Phase", 0, "min:0.0,max:10.0");
    params.AddString("game_type", "versusBrawl");
}

void Update(){
    Object@ me = ReadObjectFromID(hotspot.GetID());
    me.SetEditorLabel("["+ params.GetInt("Phase") +"]");
}

void Dispose(){
}

bool AcceptConnectionsFrom(Object@ other) {
    return true;
}

bool AcceptConnectionsTo(Object@ other) {
    return true;
}

bool ConnectTo(Object@ other){
    Log(error, "" + hotspot.GetID() + "connecting to:"+other.GetID());
    return true;
}