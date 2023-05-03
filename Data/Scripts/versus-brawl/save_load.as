#include "versus-brawl/utilityStuff/fileChecks.as"

// This whole script is due to levelParams being buggy as hell atm (using floatSlider crash the game, using `SetFloat` provides UI with an intSlider and truncate)

funcdef void ConfigCallback(JSONValue settings);

array<ConfigCallback@> loadCallbacks = {};

// This is called by implementation to load JSON with level params, and call all `loadCallbacks`
void LoadJSONLevelParams(){
	
	string cfgPath = GetCurrLevelRelPath() + ".json";
	
	// Load defaults from the levels cfgPath
	JSONValue settings = LoadJSONFile(cfgPath);

	for (uint i = 0; i < loadCallbacks.size(); i++){
		loadCallbacks[i](settings);
	}

	// Dont load customSettings if user has unchecked it in the main menu
	SavedLevel@ saved_level = save_file.GetSavedLevel("versus-brawl");
	bool useCustomSettings = saved_level.GetValue("useCustomSettings") == "true";
	if(!useCustomSettings)
		return;
	
	// We load any user value, if there are any in savefile.sav3 file
	bool parsed;
	//We cut the "Data/Levels/` part, 12 chars
	JSONValue userSettings = LoadUserLevelParams(GetCurrLevelRelPath().substr(12), parsed);

	if(parsed){
		for (uint i = 0; i < loadCallbacks.size(); i++){
			loadCallbacks[i](userSettings);
		}
	}
}

JSONValue LoadJSONFile(string file){
	JSON jsonFile;
	jsonFile.parseFile(file);
	Log(error, "parseFile(" + file + "): " + jsonFile.writeString());

	JSONValue root;
	root = jsonFile.getRoot();

	// If we find override, use that instead
	if(FoundMember(root, "Override")){
		Log(error, "Override found!");

		return LoadJSONFile(root["Override"].asString());
	}

	Log(error, "json loaded: " + join(root.getMemberNames(),","));
	
	return root;
}

JSONValue LoadUserLevelParams(string path, bool &out success){
	SavedLevel@ saved_level = save_file.GetSavedLevel(path);
	string userConfigJson = saved_level.GetValue("userConfig");
	JSON data;

	if(userConfigJson != "" && data.parseString(userConfigJson)) {
		JSONValue root;

		root = data.getRoot();
		Log(error, "LoadUserLevelParams(" + path + ") is not empty");
		array<string> rootMembers = root.getMemberNames();
		Log(error, "Members: " +join(root.getMemberNames(),","));

		success = true;
		
		return root;
	}
	Log(error, "LoadUserLevelParams(" + path + ") is empty");
	success = false;
	return JSONValue("");
}

bool FoundMember(JSONValue root, string varName){
	array<string> members = root.getMemberNames();
	Log(error, "Members: " +join(root.getMemberNames(),","));


	for(uint i = 0; i < members.size(); i++){
		if(members[i] == varName)
			return true;
	}

	Log(error, "Cant find in JSON: " + varName + " Available: " + join(members, ","));
	return false;
}