void PlaceHolderFollowerUpdate(string iconPath, string text, float scale = 1){

    if(EditorModeActive()){
        Object@ me = ReadObjectFromID(hotspot.GetID());
        vec4 color;
        if(me.GetEnabled()){
            color = vec4(1);
        }
        else{
            color = vec4(vec3(1), 0.2f);
        }
        
        DebugDrawBillboard(iconPath,
            me.GetTranslation(),
            scale,
            color,
            _delete_on_update);
        
        DebugDrawText(
            me.GetTranslation(), 
            text, 
            1.0f, 
            true,
            _delete_on_update);
    }
}