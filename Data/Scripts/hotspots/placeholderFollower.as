#include "versus-brawl/utilityStuff/fileChecks.as"

void PlaceHolderFollowerUpdate(string iconPath, string text, float scale = 1, bool showDirection = false, vec4 color = vec4(1), vec3 offset = vec3()){

    //TODO: Is .dds supported?
    if(!FileExistsWithType(iconPath, ".png") && !FileExistsWithType(iconPath, ".tga")){
        return;
    }
    
    if(EditorModeActive()){
        Object@ me = ReadObjectFromID(hotspot.GetID());
        vec4 tempColor = color;
        if(!me.GetEnabled()){
            tempColor = vec4(tempColor.x, tempColor.y, tempColor.z, tempColor.a * 0.2f);
        }
        if(me.IsSelected()){
            float selectedBoost = 2.0f;
            tempColor = vec4(tempColor.x * selectedBoost, tempColor.y * selectedBoost, tempColor.z * selectedBoost, tempColor.a);
        }
        
        DebugDrawBillboard(iconPath,
            me.GetTranslation() + offset,
            scale,
            tempColor,
            _delete_on_update);
        
        DebugDrawText(
            me.GetTranslation() + offset, 
            text, 
            1.0f, 
            true,
            _delete_on_update);
        
        if(showDirection){
            // Just multiply by UP vector
            vec3 direction = me.GetRotation() * vec3(0,0,1);
            DebugDrawText(
                me.GetTranslation() + direction,
                "+",
                2.0f,
                true,
                _delete_on_update);
        }
    }
}