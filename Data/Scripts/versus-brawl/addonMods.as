string addonTag = "VersusBrawl";
string baseModId = "versus-brawl";

// TODO! Big refactor needed, species should be referenced by their `key` not index, to maintain addon compatibility

// %modId% is replaced with the desired modId
string addonSpeciesFilePath = "Addons/versus-brawl/%modId%Species.json";
string addonLevelsFilePath = "Addons/versus-brawl/%modId%Levels.json";

// Return list of additional files, `expectedFilePath` requires `%modId%` wildcard in path
array<string>@ GetAdditionalFiles(string expectedFilePath, string addonTag, string ignoreId) {
    //TODO! This should be called after the base json has been loaded
    // Get mods list
    array<string>@ modsTagged = GetModsWithAddonTag(addonTag, ignoreId);
    array<string> filesList = {};
    for (uint i = 0; i < modsTagged.size(); i++) {
        // Replace `%modId%` with actual modId
        int foundChar = expectedFilePath.findFirst("%modId%");
        string realPath = expectedFilePath;
        realPath.erase(foundChar, 7);
        realPath.insert(foundChar, modsTagged[i]);
        
        // Check if file under that path exists
        if (FileExists(realPath)){
            modsTagged.push_back(realPath);
        }
    } 
    return filesList;
}

array<string>@ GetModsWithAddonTag(string addonTag, string ignoreId) {
    array<ModID>@ active_mods = GetActiveModSids();
    array<string> modsTagged = {};

    for (uint i = 0; i < active_mods.size(); i++) {
        // Ignore base versus brawl mod
        string modId = ModGetID(active_mods[i]);
        if (modId != ignoreId) {
            // Does it contain the `addonTag`
            string tags = ModGetTags(active_mods[i]);
            if (tags.findFirst(addonTag) >= 0) {
                modsTagged.push_back(modId);
            }
        }
    } 
    return modsTagged;
}
