vec3 lastBonePos;
bool init = false;
float overHeadDistance = 0.5f;
int lightId = -1;

void Init(){
    Object@ me = ReadObjectFromID(hotspot.GetID());
    me.SetScale(vec3(0.05f));
}

void Reset(){
    Dispose();
}

void Update(){
    if(lightId == -1){
        //spawn light
        lightId = CreateObject("Data/Objects/lights/dynamic_light.xml");
        Object@ obj = ReadObjectFromID(lightId);

        obj.SetScale(vec3(8));
        obj.SetTint(vec3(0.35f,0.2f,0));
    }
}

void SetParameters(){
    params.AddFloatSlider("delayScale", 0.06f, "min:0,max:1.0,step:0.001");
    params.AddInt("followObjId", -1);
    params.AddInt("bonePosGetter", 0); // 0 is the newer method, 1 is the old stuttercity method
    params.AddInt("dampenMovement", 0);
}

vec3 GetBonePos(){
    MovementObject@ mo = ReadCharacterID(params.GetInt("followObjId"));
    RiggedObject@ rigged_object = mo.rigged_object();
    Skeleton@ skeleton = rigged_object.skeleton();
    int num_bones = skeleton.NumBones();

    array<BoneTransform> inv_skeleton_bind_transforms = {};
    array<BoneTransform> skeleton_bind_transforms = {};
    array<int> ik_chain_elements = {};

    inv_skeleton_bind_transforms.resize(num_bones);
    skeleton_bind_transforms.resize(num_bones);

    for(int i = 0; i < num_bones; ++i) {
        skeleton_bind_transforms[i] = BoneTransform(skeleton.GetBindMatrix(i));
        inv_skeleton_bind_transforms[i] = invert(skeleton_bind_transforms[i]);
    }
    int head_bone = skeleton.IKBoneStart("head");
    
    BoneTransform world_head = BoneTransform(rigged_object.GetDisplayBoneMatrix(head_bone)) * inv_skeleton_bind_transforms[head_bone];
    return world_head.origin;
}

void Draw() {
    Object@ me = ReadObjectFromID(hotspot.GetID());

    if(params.GetInt("followObjId") == -1)
        return;
    
    MovementObject@ mo = ReadCharacterID(params.GetInt("followObjId"));

    string bonName = "head";
    if(params.HasParam("boneToFollow")){
        bonName = params.GetString("boneToFollow");
    }

    vec3 bonePos;
    if(params.GetInt("bonePosGetter") == 0){
        // This uses bone matrix, updates much faster (thanks for finding that out @Gyrth)
        bonePos = GetBonePos();
    }
    else{
        // This probably will stutter without dampening
        bonePos = mo.rigged_object().GetIKTargetTransform(bonName).GetTranslationPart();
    }
    if(!init){
        // First move
        lastBonePos = bonePos;
        init = true;
        me.SetTranslation(bonePos + vec3(0, overHeadDistance, 0));
        return;
    }
    
    vec3 pos = bonePos;

    if(params.GetInt("dampenMovement") > 0){
        // This moves it while dampening the transformspeed
        float d1 = params.GetFloat("delayScale");
        if(distance(lastBonePos, bonePos) > d1){
            float d = distance(lastBonePos, bonePos);
            float t = d1/d;
            float x = (1-t)*lastBonePos.x + t*bonePos.x;
            float y = (1-t)*lastBonePos.y + t*bonePos.y;
            float z = (1-t)*lastBonePos.z + t*bonePos.z;
            pos = vec3(x,y,z);
        }
    }
    lastBonePos = pos;

    Object@ lightObj = ReadObjectFromID(lightId);
    lightObj.SetTranslation(pos + vec3(0, overHeadDistance, 0));
    me.SetTranslation(pos + vec3(0, overHeadDistance, 0));
    // Its really dumb we cant use SetBillboardColorMap on hotspots
    DebugDrawBillboard("Data/Textures/versus-brawl/crown.png",
        pos + vec3(0, overHeadDistance, 0),
    me.GetScale()[1]*5,
        vec4(vec3(3,2,0), 1),
        _delete_on_draw);
}

void Dispose(){
    if(lightId != -1){
        DeleteObjectID(lightId);
        lightId = -1;
    }
}