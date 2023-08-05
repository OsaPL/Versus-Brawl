#include "hotspots/placeholderFollower.as"

int parentId = -1;
int toSkip = 0;
string billboardPath = "Data/Textures/ui/menus/main/icon-retry.png";
vec3 color = vec3(0, 0.7f, 0.8f);
float timeSinceLastRotate = 0;
vec3 lastAxis = vec3();

float rotateDelay = 0.2f;
float rotatoSpeed = 0.0003f; // min. 0.0003f

void SetParameters()
{
    params.AddString("type", "rotatoHotspot");
    // Times 100 for readability
    params.AddFloatSlider("rotateDelay", 0.01f*100,"min:0,max:30,step:0.01");
    params.AddFloatSlider("rotatoSpeed", 0.0003f*100,"min:0.03,max:10,step:0.01");
    params.AddIntCheckbox("useFastRotate", true);
    params.AddString("rotationAxis", "vec3(0, 1, 0)");
}

vec3 parseVec3(string text){
    int findVec3 = text.findFirst("vec3(");
    if(findVec3 >= 0) {

        int findFirstComa = text.findFirst(",", findVec3);
        if(findFirstComa >= 0) {

            int findSecondComa = text.findFirst(",", findFirstComa+1);
            if(findSecondComa >= 0) {

                int findClosing = text.findFirst(")", findSecondComa);
                if(findClosing >= 0) {

                    int x1 = findVec3+5;
                    int x2 = findFirstComa;
                    int xc = x2 - x1;

                    int y1 = findFirstComa+1;
                    int y2 = findSecondComa;
                    int yc = y2 - y1;

                    int z1 = findSecondComa+1;
                    int z2 = findClosing;
                    int zc = z2 - z1;

                    string inputX = text.substr(x1,xc);
                    string inputY = text.substr(y1,yc);
                    string inputZ = text.substr(z1,zc);

                    float x = parseFloat(inputX);
                    float y = parseFloat(inputY);
                    float z = parseFloat(inputZ);

                    return vec3(x,y,z);
                }
            }
        }
    }
    //DisplayError("parseVec3", "Couldnt parseVec3: " + text);
    return vec3();
}

void Init(){
    
}

void Update()
{
    Object@ me = ReadObjectFromID(hotspot.GetID());
    me.SetScale(vec3(0.2f));

    rotateDelay = params.GetFloat("rotateDelay")/100;
    rotatoSpeed = params.GetFloat("rotatoSpeed")/100;
    
    if(EditorModeActive()){
        PlaceHolderFollowerUpdate(billboardPath, "[Rotato] LinkedId: "+ parentId, 1.0f, false, vec4(color, 1));
    }
    
    if(parentId == -1 || !me.GetEnabled())
        return;
    
    if(timeSinceLastRotate<rotateDelay) {
        timeSinceLastRotate += time_step;
        return;
    }
    timeSinceLastRotate = 0;
    
    Object@ obj = ReadObjectFromID(parentId);
    vec3 original = obj.GetTranslation();
    quaternion rot = obj.GetRotation();
    vec3 axis = parseVec3(params.GetString("rotationAxis"));
    
    // Reset rotation if axis changed
    if(lastAxis != axis) {
        obj.SetRotation(quaternion());
        lastAxis = axis;
        return;
    }

    vec3 direction = obj.GetRotation() * vec3(0,0,1);
    DebugDrawLine(original,
        original+axis,
        color,
        _delete_on_update);

    // Stop rotating if obj is selected
    if(obj.IsSelected()){
        return;
    }

    if(params.GetInt("useFastRotate") != 0){
        obj.SetTranslationRotationFast(original, rot * quaternion(vec4(axis.x, axis.y, axis.z, (rotatoSpeed))));
    }
    else{
        obj.SetRotation(rot * quaternion(vec4(axis.x, axis.y, axis.z, (rotatoSpeed))));
    }
}

bool AcceptConnectionsFrom(Object@ other) {
    return false;
}

bool AcceptConnectionsTo(Object@ other) {
    return true;
}

bool ConnectTo(Object@ other)
{
    parentId = other.GetID();
    // Reset rotation if object connected
    Object@ obj = ReadObjectFromID(parentId);
    obj.SetRotation(quaternion());
    return true;
}

bool Disconnect(Object@ other)
{
    parentId = -1;
    // Reset rotation if object disconnected
    Object@ obj = ReadObjectFromID(parentId);
    obj.SetRotation(quaternion());
    return true;
}