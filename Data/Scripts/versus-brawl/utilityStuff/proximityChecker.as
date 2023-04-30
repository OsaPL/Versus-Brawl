// Used to check whether any player is close to it

bool PlayerProximityCheck(float minDistanceToActivate){
    // Find closest player
    if(minDistanceToActivate>0){
        Object@ hotspotObj = ReadObjectFromID(hotspot.GetID());
        vec3 pos = hotspotObj.GetTranslation();
        int num_chars = GetNumCharacters();
        //Log(error, "GetNumCharacters is " + num_chars);

        for(int i = 0;i < num_chars; i++){
            //Log(error, "i is " + i);
            MovementObject @mo = ReadCharacter(i);
            Object@ char_obj = ReadObjectFromID(mo.GetID());

            vec3 charPos = mo.position;
            float newDistance = distance(pos, charPos);

            if(newDistance<minDistanceToActivate)
                return true;

            //Log(error, "Distance is " + newDistance + " minDistanceToActivate: " + minDistanceToActivate);
        }
    }
    //Log(error, "Finally, no player close");
    
    return false;
}

bool EditorCameraProximityCheck(float minDistanceToActivate){
    if(minDistanceToActivate>0){
        Object@ hotspotObj = ReadObjectFromID(hotspot.GetID());
        vec3 pos = hotspotObj.GetTranslation();

        vec3 charPos = camera.GetPos();
        float newDistance = distance(pos, charPos);

        if(newDistance<minDistanceToActivate)
            return true;
    }

    return false;
}