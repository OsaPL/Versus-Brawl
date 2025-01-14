#include "menu_common.as"
#include "music_load.as"
#include "versus-brawl/save_load.as"
#include "versus-brawl/addonMods.as"

MusicLoad ml("Data/Music/menu.xml");

IMGUI@ imGUI;

bool HasFocus() {
	return false;
}

const int item_per_screen = 4;
const int rows_per_screen = 3;

string this_campaign_name = "custom_campaign";

array<LevelInfo@> level_list;

void LoadModCampaign() {
	string campaign_id = GetCurrCampaignID();
	this_campaign_name = campaign_id;
	level_list.removeRange(0, level_list.length());
	Log(info, campaign_id);
	Campaign c = GetCampaign(campaign_id);

	array<ModLevel>@ campaign_levels = c.GetLevels();

	Log( info, "size: " + campaign_levels.length());
	for( uint k = 0; k < campaign_levels.length(); k++ ) {
		level_list.insertLast(LevelInfo(campaign_levels[k],GetHighestDifficultyFinishedCampaign(campaign_id),GetLevelPlayed(campaign_levels[k].GetID()),true,false));
	}
}

string GetModTitle() {
	string campaign_id = GetCurrCampaignID();
	this_campaign_name = campaign_id;
	Campaign c = GetCampaign(campaign_id);
	return c.GetTitle();
}

void Initialize() {
	@imGUI = CreateIMGUI();
	LoadModCampaign();

	// Start playing some music
	PlaySong("overgrowth_main");

	// We're going to want a 100 'gui space' pixel header/footer
	imGUI.setHeaderHeight(200);
	imGUI.setFooterHeight(200);

	// Actually setup the GUI -- must do this before we do anything
	imGUI.setup();
	BuildUI();
	// setup our background
	setBackGround();
}

void BuildUI(){
	int initial_offset = 0;
	if( StorageHasInt32( this_campaign_name + "-shift_offset" )){
		initial_offset = StorageGetInt32( this_campaign_name + "-shift_offset" );
	}
	while( initial_offset >= int(level_list.length()) ) {
		initial_offset -= item_per_screen;
		if( initial_offset < 0 ) {
			initial_offset = 0;
			break;
		}
	}
	IMDivider mainDiv( "mainDiv", DOHorizontal );
	mainDiv.setAlignment(CACenter, CACenter);
	CreateMenu(mainDiv, level_list, this_campaign_name, initial_offset, item_per_screen, rows_per_screen, false, false);
	// Add it to the main panel of the GUI
	imGUI.getMain().setElement( @mainDiv );
	IMDivider header_divider( "header_div", DOHorizontal );
	AddTitleHeader(GetModTitle(), header_divider);
	imGUI.getHeader().setElement(header_divider);
	AddBackButton();

	SavedLevel@ saved_level = save_file.GetSavedLevel("versus-brawl");
	useCustomSettings = saved_level.GetValue("useCustomSettings") == "true";
}

IMText@ titleHead;

void Dispose() {
	imGUI.clear();
}

bool CanGoBack() {
	return true;
}

void Update() {
	UpdateKeyboardMouse();
	// process any messages produced from the update
	while( imGUI.getMessageQueueSize() > 0 ) {
		IMMessage@ message = imGUI.getNextMessage();

		//Log( info, "Got processMessage " + message.name );

		if( message.name == "Back" )
		{
			this_ui.SendCallback( "back" );
		}
		else if( message.name == "run_file" )
		{
			string previousSelectedPath = selectedPath;
			selectedName = message.getString(1);
			selectedPath = message.getString(0);
			
			// Save useCustomSettings value
			SavedLevel@ saved_level = save_file.GetSavedLevel("versus-brawl");
			saved_level.SetValue("useCustomSettings", ""+useCustomSettings);
			save_file.WriteInPlace();
			
			// If we click two times, it should just load
			if(!useCustomSettings || selectedPath == previousSelectedPath){
				SaveUserConfig();
				
				this_ui.SendCallback(message.getString(0));
			}
			else{
				selectedPathJustChanged = true;
			}
		}
		else if( message.name == "shift_menu" ){
			StorageSetInt32( this_campaign_name + "-shift_offset", ShiftMenu(message.getInt(0)));
			SetControllerItemBeforeShift();
			BuildUI();
			SetControllerItemAfterShift(message.getInt(0));
		}
		else if( message.name == "refresh_menu_by_name" ){
			string current_controller_item_name = GetCurrentControllerItemName();
			BuildUI();
			SetCurrentControllerItem(current_controller_item_name);
		}
		else if( message.name == "refresh_menu_by_id" ){
			int index = GetCurrentControllerItemIndex();
			BuildUI();
			SetCurrentControllerItem(index);
		}
	}
	// Do the general GUI updating
	imGUI.update();
	UpdateController();
}

void Resize() {
	imGUI.doScreenResize(); // This must be called first
	setBackGround();
}

void ScriptReloaded() {
	// Clear the old GUI
	imGUI.clear();
	// Rebuild it
	Initialize();
}
// My stuff

//TODO! THIS IS AWFUL, I have no other idea atm, but still,
// 	I should be able somehow to malloc myself the values, and just keep the pointers, but docs are not existant.
//	Leaving me to believe that you cant malloc by yourself (AS uses a GC after all, and is considered "safeish" sandbox)
//	There is `ref` but I couldnt make it work, probably not supported by OGs AS version
array<int> configInts = {};
array<float> configFloats = {};
array<string> configStrings = {};
array<bool> configBools = {};

array<ConfigParam@> ConfigParams = {};

class ConfigParam{
	string Name;
	string Path;
	string StringValue;
	JsonValueType Type;

	string Default;
	string Min;
	string Max;

	// On the desired type list
	int TypeIndex;
	ConfigParam(string newName, string newPath, string newValue, string newMin, string newMax, JsonValueType newType, int newTypeIndex){
		Name = newName;
		Path = newPath;
		StringValue = newValue;
		Default = newValue;
		Type = newType;

		Min = newMin;
		Max = newMax;
		TypeIndex = newTypeIndex;
	}
}
string selectedName = "N/A";
string selectedPath = "N/A";
bool useCustomSettings = false;
bool useCustomSettingsJustChanged = false;
bool selectedPathJustChanged = false;
bool ignoreAuthorConfiguration = false;

int padding = 5;
int pointsToWin = 10;
float respawnTime = 3.0f;

//UI Configurables
//TODO! This should change UI to look more user friendly (no min, max fields, no default value, (maybe?) no description row
bool extendedUI = true;

// Colors
vec4 warning_color(0.8f, 0.6f, 0.2f, 1.0f);
vec4 critical_color(1.0f, 0.3f, 0.2f, 1.0f);
vec4 greyish_color(0.7f, 0.7f, 0.7f, 1.0f);
vec4 darkgreyish_color(0.5f, 0.5f, 0.5f, 1.0f);
//
bool userOptionsLoaded = false;
void DrawGUI() {
	imGUI.render();

	bool open = true;
	ImGui_Begin("Versus Brawl Settings Pane", open, ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoResize);
	// Window
	float target_height = screenMetrics.getScreenHeight() * 0.15f;
	float target_width = screenMetrics.getScreenWidth() * 0.7f;
	ImGui_SetWindowPos(vec2((screenMetrics.getScreenWidth() * 0.25f), screenMetrics.getScreenHeight() * 0.9f - (target_height / 2.0f)));
	ImGui_SetWindowSize(vec2(target_width, target_height));

	//Inside
	if(ImGui_BeginChildFrame(55, vec2(ImGui_GetWindowWidth()  - (padding * 3.0), ImGui_GetWindowHeight() - (padding * 3.0)))){
		float option_name_width = 150.0;

		ImGui_Columns(5, false);
		ImGui_SetColumnWidth(0, option_name_width);
		ImGui_SetColumnWidth(1, option_name_width*0.2);
		ImGui_SetColumnWidth(2, option_name_width*5);
		ImGui_SetColumnWidth(3, option_name_width*0.2);
		ImGui_SetColumnWidth(4, option_name_width*1);
		
		ImGui_Text("Use Custom Settings");
		ImGui_NextColumn();
		
		ImGui_Checkbox("##Use Custom Settings", useCustomSettings);
		
		float second_column_width = ImGui_GetContentRegionAvailWidth();
		
		if((useCustomSettingsJustChanged || selectedPathJustChanged) && selectedPath != "N/A"){
			Log(error, "LoadConfig! " + useCustomSettingsJustChanged + " " + selectedPathJustChanged);
			useCustomSettingsJustChanged = false;
			selectedPathJustChanged = false;
			//TODO! Reload Config values from 
			string cfgPath = "Data/Levels/" + selectedPath + ".json";
			Log(error, "LoadDefaultConfig! " + cfgPath);
			LoadDefaultConfig(cfgPath);
			userOptionsLoaded = LoadUserConfig();
		}
		if(useCustomSettings){
			ImGui_NextColumn();
			
			//TODO! No idea if giving user this much power is a good idea, if he really wants to break things, he can always edit json afterall
			// ImGui_TextColored(warning_color,"Ignore Author Configuration");
			// ImGui_SameLine();
			// ImGui_Checkbox("##Ignore Author Configuration", ignoreAuthorConfiguration);
			// if(ignoreAuthorConfiguration) {
			// 	ImGui_SameLine();
			// 	ImGui_TextColored(critical_color, "Warning! Maps will break if the parameter is not supported by author!");
			// }
			// SkipColumns(5);
			// LineEnd
			// Small padding
			ImGui_Text("Currently selected:");
			ImGui_SameLine();
			ImGui_TextColored(greyish_color, selectedName + " ("+selectedPath+")");
			SkipColumns(3);
			// LineEnd
			
			// Small padding between modes
			if(userOptionsLoaded){
				ImGui_TextColored(warning_color, "Loaded user settings.");
			}
			else{
				ImGui_InvisibleButton("##padded-text", vec2(15,15));
			}
			
			if(selectedPath == "N/A" || ConfigParams.size() <= 0){
				SkipColumns(2);
				ImGui_TextColored(greyish_color, "Nothing to configure here. Go on.");
				ImGui_EndChildFrame();
				ImGui_End();
				return;
			}
			SkipColumns(4);
			if(ImGui_Button("Reset all")) {
				RemoveUserConfig();
				userOptionsLoaded = false;
				useCustomSettingsJustChanged = true;
			}
			SkipColumns(1);
			// LineEnd
			
			ImGui_TextColored(darkgreyish_color, "Param name");
			ImGui_NextColumn();
			ImGui_TextColored(darkgreyish_color, "Min");
			ImGui_NextColumn();
			ImGui_TextColored(darkgreyish_color, "Value");
			ImGui_NextColumn();
			ImGui_TextColored(darkgreyish_color, "Max");
			ImGui_NextColumn();
			ImGui_TextColored(darkgreyish_color, "Defaults");
			ImGui_NextColumn();
			// LineEnd

			string lastPath = "";
			for (uint j = 0; j < ConfigParams.size(); j++)
			{
				ConfigParam@ currectConfigParam = ConfigParams[j];
				//Log(error, "currectConfigParam:" + currectConfigParam.Name);
				
				if(currectConfigParam.Path != lastPath){
					lastPath = currectConfigParam.Path;

					// Small padding
					ImGui_InvisibleButton("##padded-text", vec2(10,10));
					SkipColumns(5);
					// LineEnd
					
					ImGui_TextColored(greyish_color, lastPath);
					SkipColumns(5);
					// LineEnd
				}
				
				string uniqueId = currectConfigParam.Path+"-"+currectConfigParam.Name;
				
				// Now we just convert the value and add to correct list
				if (currectConfigParam.Type == JSONintValue) {
					// INT
					ImGui_Text(currectConfigParam.Name);
					ImGui_NextColumn();
					ImGui_Text(""+parseInt(currectConfigParam.Min));
					ImGui_NextColumn();
					// Negative means fill
					ImGui_PushItemWidth(-1);
					ImGui_SliderInt("##slider-"+uniqueId, 
						configInts[currectConfigParam.TypeIndex],
						parseInt(currectConfigParam.Min),
						parseInt(currectConfigParam.Max));
					ImGui_NextColumn();
					ImGui_Text(""+parseInt(currectConfigParam.Max));
					ImGui_NextColumn();

					if(ImGui_Button("X##X"+currectConfigParam.Name)){
						configInts[currectConfigParam.TypeIndex] = parseInt(currectConfigParam.Default);
					}
					
				} else if (currectConfigParam.Type == JSONrealValue) {
					// FLOAT
					ImGui_Text(currectConfigParam.Name);
					ImGui_NextColumn();
					ImGui_Text(""+parseFloat(currectConfigParam.Min));
					ImGui_NextColumn();
					// Negative means fill
					ImGui_PushItemWidth(-1);
					ImGui_SliderFloat("##slider-"+uniqueId,
						configFloats[currectConfigParam.TypeIndex],
						parseFloat(currectConfigParam.Min),
						parseFloat(currectConfigParam.Max));
					ImGui_NextColumn();
					ImGui_Text(""+parseFloat(currectConfigParam.Max));
					ImGui_NextColumn();
					
					if(ImGui_Button("X##X"+uniqueId)){
						configFloats[currectConfigParam.TypeIndex] = parseFloat(currectConfigParam.Default);
					}
					
				} else if (currectConfigParam.Type == JSONbooleanValue) {
					// FLOAT
					ImGui_Text(currectConfigParam.Name);
					SkipColumns(2);
					
					// Negative means fill
					ImGui_PushItemWidth(-1);
					ImGui_Checkbox("##checkBox-"+uniqueId,
						configBools[currectConfigParam.TypeIndex]);
					SkipColumns(2);

					if(ImGui_Button("X##X"+uniqueId)){
						configBools[currectConfigParam.TypeIndex] = currectConfigParam.Default == "true";
					}
				} else if (currectConfigParam.Type == JSONstringValue) {
					ImGui_Text(currectConfigParam.Name);
					SkipColumns(2);

					// Negative means fill
					ImGui_PushItemWidth(-1);
					ImGui_InputText(configStrings[currectConfigParam.TypeIndex], configStrings[currectConfigParam.TypeIndex], 64);
					SkipColumns(2);

					if(ImGui_Button("X##X"+uniqueId)){
						configBools[currectConfigParam.TypeIndex] = currectConfigParam.Default == "true";
					}
				} else if (currectConfigParam.Type == JSONobjectValue) {
					// We cant do anything with an object value atm, just skip it.
				}
				
				ImGui_SameLine();
				ImGui_Text(currectConfigParam.Default);
				ImGui_NextColumn();
			}
			// LineEnd

			SkipColumns(2);
			if(ImGui_Button("Save Config")) {
				SaveUserConfig();
				userOptionsLoaded = true;
			}
			if(ImGui_Button("Start Custom Game")){
				//We save config for level to load, but also settings for the UI itself
				SaveUserConfig();

				SavedLevel@ saved_level = save_file.GetSavedLevel("versus-brawl");
				saved_level.SetValue("useCustomSettings", ""+useCustomSettings);
				save_file.WriteInPlace();

				this_ui.SendCallback(selectedPath);
			}
		}
		else {
			useCustomSettingsJustChanged = true;
		}
		
		ImGui_EndChildFrame();
	}
		
	ImGui_End();
}

// Load default level Config and its configurables
void LoadDefaultConfig(string path){
	ConfigParams = {};

	if(!FileExistsWithType(path, ".json")){
		Log(error, "Cant find path:" + path);
		return;
	}

	//Log(error, "path:" + path);
	JSONValue rooted = LoadJSONFile(path);

	array<string> rootMembers = rooted.getMemberNames();
	
	for (uint i = 0; i < rootMembers.size(); i++)
	{
		// Gametype
		string gamemodePath = rootMembers[i];
		JSONValue gameTyperoot = rooted[gamemodePath];

		array<string> gameTypeMembers = gameTyperoot.getMemberNames();
		for (uint j = 0; j < gameTypeMembers.size(); j++)
		{
			// Properties
			JSONValue property = gameTyperoot[gameTypeMembers[j]];

			// Found Configurable, loading them too
			if(FoundMember(property, "Configurable")) {
				JSONValue configurable = property["Configurable"];
				JSONValue gamemodeValue = property["Value"];
				JsonValueType jsonType1 = gamemodeValue.type();
				
				
				string min = configurable["Min"].asString();
				string max = configurable["Max"].asString();
				
				int index = -1;
				string StringValue1 = gamemodeValue.asString();
				
				// Now we just convert the value, add to correct list, and use the index+type combo as a indirect pointer
				if (jsonType1 == JSONintValue) {
					configInts.push_back(parseInt(StringValue1));
					index = configInts.size() - 1;
				} else if (jsonType1 == JSONrealValue) {
					configFloats.push_back(parseFloat(StringValue1));
					index = configFloats.size() - 1;
				} else if (jsonType1 == JSONbooleanValue) {
					configBools.push_back(StringValue1 == "true");
					index = configBools.size() - 1;
				} else if (jsonType1 == JSONstringValue) {
					configStrings.push_back(StringValue1);
					index = configStrings.size() - 1;
				} else if (jsonType1 == JSONobjectValue) {
					// We cant do anything with an object value atm, just skip it.
				}
				ConfigParams.push_back(ConfigParam(gameTypeMembers[j], gamemodePath, gamemodeValue.asString(), min, max, jsonType1, index));
			}
		}
	}
}

// TODO! This should probably be somehow generalised together with LoadDefaultConfig
bool LoadUserConfig(){

	bool parsed;
	JSONValue rooted = LoadUserLevelParams(selectedPath, parsed);
	if(!parsed)
		return parsed;

	array<string> rootMembers = rooted.getMemberNames();
	
	int elementNr = 0;

	for (uint i = 0; i < rootMembers.size(); i++)
	{
		// Gametype
		string gamemodePath = rootMembers[i];
		JSONValue gameTyperoot = rooted[gamemodePath];
		Log(error, "gamemodePath:" + gamemodePath);
		array<string> gameTypeMembers = gameTyperoot.getMemberNames();
		
		for (uint j = 0; j < gameTypeMembers.size(); j++)
		{
			//Properties
			ConfigParam@ currectConfigParam;
			
			JSONValue property = gameTyperoot[gameTypeMembers[j]];
			Log(error, "property:" + gameTypeMembers[j]);
			
			JSONValue gamemodeValue = property["Value"];
			JsonValueType jsonType1 = gamemodeValue.type();
			Log(error, "jsonType1:" + jsonType1);
			string StringValue1 = gamemodeValue.asString();
			Log(error, "StringValue1:" + StringValue1);

			// Find corresponding ConfigParam
			for (uint k = 0; k < ConfigParams.size(); k++)
			{
				Log(error, "ConfigParams[k].Name: " + ConfigParams[k].Name );
				Log(error, "ConfigParams[k].Path: " + ConfigParams[k].Path );
				if(ConfigParams[k].Name == gameTypeMembers[j] && ConfigParams[k].Path == gamemodePath)
					@currectConfigParam = @ConfigParams[k];
			}
			
			// We couldnt find a pair, bail to skip crashes
			if(currectConfigParam is null){
				Log(error, "currectConfigParam is null");
				return false;
			}
			
			// Now we just convert the value and update it
			if (currectConfigParam.Type == JSONintValue) {
				configInts[currectConfigParam.TypeIndex] = parseInt(StringValue1);
			} else if (currectConfigParam.Type == JSONrealValue) {
				configFloats[currectConfigParam.TypeIndex] = parseFloat(StringValue1);
			} else if (currectConfigParam.Type == JSONbooleanValue) {
				configBools[currectConfigParam.TypeIndex] = StringValue1 == "true";
			} else if (currectConfigParam.Type == JSONstringValue) {
				configStrings[currectConfigParam.TypeIndex] = StringValue1;
			} else if (currectConfigParam.Type == JSONobjectValue) {
				// We cant do anything with an object value atm, just skip it.
			}
			
			elementNr++;
		}
	}
	
	return parsed;
}

void SaveUserConfig(){
	JSON data;
	JSONValue root;
	
	string lastPath = "";
	
	for (uint i = 0; i < ConfigParams.size(); i++)
	{
		// Did we change gamemode scope?
		if(lastPath != ConfigParams[i].Path)
			lastPath = ConfigParams[i].Path;
		JSONValue gameType;
		
		for (uint j = i; j < ConfigParams.size(); j++)
		{
			// Gamemode changed switch
			if(lastPath != ConfigParams[i].Path){
				i--;
				break;
			}
			
			ConfigParam@ currectConfigParam = ConfigParams[i];
			JSONValue property;
			
			// Now we just convert the value and add as a value
			if (currectConfigParam.Type == JSONintValue) {
				property["Value"] = JSONValue(configInts[currectConfigParam.TypeIndex]);
			} else if (currectConfigParam.Type == JSONrealValue) {
				property["Value"] = JSONValue(configFloats[currectConfigParam.TypeIndex]);
			} else if (currectConfigParam.Type == JSONbooleanValue) {
				property["Value"] = JSONValue(configBools[currectConfigParam.TypeIndex]);
			} else if (currectConfigParam.Type == JSONstringValue) {
				property["Value"] = JSONValue(configStrings[currectConfigParam.TypeIndex]);
			} else if (currectConfigParam.Type == JSONobjectValue) {
				// We cant do anything with an object value atm, just skip it.
			}

			gameType[currectConfigParam.Name] = property;
			i++;
		}

		root[lastPath] = gameType;
	}

	// Save the user config into save_file
	data.getRoot() = root;
	SavedLevel@ saved_level = save_file.GetSavedLevel(selectedPath);
	saved_level.SetValue("userConfig", data.writeString(false));
	save_file.WriteInPlace();
}

void RemoveUserConfig(){
	SavedLevel@ saved_level = save_file.GetSavedLevel(selectedPath);
	saved_level.SetValue("userConfig", "");
	save_file.WriteInPlace();
}

void SkipColumns(uint x){
	for (uint j = 0; j < x; j++)
	{
		ImGui_NextColumn();
	}
}

void Draw() {
}

void Init(string str) {
}
