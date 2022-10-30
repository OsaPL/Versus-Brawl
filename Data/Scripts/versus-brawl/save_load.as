// This whole script is due to levelParams being buggy as hell atm (using floatSlider crash the game, using `SetFloat` provides UI with an intSlider and truncate)

funcdef void ConfigCallback(JSONValue settings);

array<ConfigCallback@> loadCallbacks = {};

// This is called by implementation to load JSON with level params, and call all `loadCallbacks`
void LoadJSONLevelParams(){
	string cfgPath = GetCurrLevelRelPath() + ".json";
	// This will also call all loadCallbacks
	JSONValue settings = LoadJSONFile(cfgPath);
}

JSONValue LoadJSONFile(string file){
	JSON jsonFile;
	jsonFile.parseFile(file);
	Log(error, "parseFile(" + file + "): " + jsonFile.writeString());

	JSONValue root;

	root = jsonFile.getRoot();

	Log(error, "json loaded: " + join(root.getMemberNames(),","));

	for (uint i = 0; i < loadCallbacks.size(); i++){
		loadCallbacks[i](root);
	}

	return root;
}

bool FoundMember(JSONValue root, string varName){
	array<string> members = root.getMemberNames();
	
	for(uint i = 0; i < members.size(); i++){
		if(members[i] == varName)
			return true;
	}

	Log(error, "Cant find in JSON: " + varName + " Available: " + join(members, ","));
	return false;
}
