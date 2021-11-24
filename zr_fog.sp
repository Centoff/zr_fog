#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zr_tools>
#include <zombiereloaded>

#define VERSION "1.2"

new pFogHuman = -1;
new pFogZombie = -1;
new pFogNemesis = -1;
new modeGame = -1;

public Plugin myinfo =
{
	name        	= "[ZR] Zombie Fog",
	author      	= "Centoff (Mikhail)",
	description 	= "Add a fog on maps",
	version     	= "1.2",
	url         	= "https://fromrus.su/"
}

// Cvars
new Handle:gCV_FogEnabled, bool:b_FogEnabled,
	Handle:gCV_mapFogStart, Float:f_mapFogStart,
	Handle:gCV_mapFogEnd, Float:f_mapFogEnd,
	Handle:gCV_mapFogDensity, Float:f_mapFogDensity;
	Handle:gCV_mapFogNemStart, Float:f_mapFogNemStart,
	Handle:gCV_mapFogNemEnd, Float:f_mapFogNemEnd,
	Handle:gCV_mapFogNemDensity, Float:f_mapFogNemDensity;

public OnPluginStart()
{
	CreateConVar("sm_fog_version", VERSION, "Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
	gCV_FogEnabled 		= 	CreateConVar("sm_fog_enabled", "1", "Enable fog on map", 0, true, 0.0, true, 1.0);
	gCV_mapFogStart 	= 	CreateConVar("sm_fog_start", "0.0", "Start visible fog", 0, true, 0.0, true, 60.0);
	gCV_mapFogEnd		= 	CreateConVar("sm_fog_end", "200.0", "End visible fog", 0, true, 0.0, true, 2700.0);
	gCV_mapFogDensity	= 	CreateConVar("sm_fog_density", "0.90", "Density fog", 0, true, 0.0, true, 1.0);
	gCV_mapFogNemStart 	= 	CreateConVar("sm_fog_nemesis_start", "50.0", "Start visible fog for Nemesis", 0, true, 0.0, true, 60.0);
	gCV_mapFogNemEnd		= 	CreateConVar("sm_fog_nemesis_end", "400.0", "End visible fog for Nemesis", 0, true, 0.0, true, 2700.0);
	gCV_mapFogNemDensity	= 	CreateConVar("sm_fog_nemesis_density", "0.80", "Density fog for Nemesis", 0, true, 0.0, true, 1.0);
	
	b_FogEnabled = GetConVarBool(gCV_FogEnabled);
	
	f_mapFogStart = GetConVarFloat(gCV_mapFogStart);
	f_mapFogEnd = GetConVarFloat(gCV_mapFogEnd);
	f_mapFogDensity = GetConVarFloat(gCV_mapFogDensity);
	f_mapFogNemStart = GetConVarFloat(gCV_mapFogNemStart);
	f_mapFogNemEnd = GetConVarFloat(gCV_mapFogNemEnd);
	f_mapFogNemDensity = GetConVarFloat(gCV_mapFogNemDensity);
	
	HookConVarChange(gCV_FogEnabled, OnConVarChanged);
	HookConVarChange(gCV_mapFogStart, OnConVarChanged);
	HookConVarChange(gCV_mapFogEnd, OnConVarChanged);
	HookConVarChange(gCV_mapFogDensity, OnConVarChanged);
	HookConVarChange(gCV_mapFogNemStart, OnConVarChanged);
	HookConVarChange(gCV_mapFogNemEnd, OnConVarChanged);
	HookConVarChange(gCV_mapFogNemDensity, OnConVarChanged);
	
	AutoExecConfig(true, "zombiereloaded/fog_effects");
	
	LoadTranslations("zr_fog_effects.phrases");
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
	//HookEvent("player_spawn", OnPlayerSpawn);
	//HookEvent("player_death", OnPlayerDeath);
	
	RegConsoleCmd("sm_fogoff", cmd_fogoff);
	RegConsoleCmd("sm_fogon", cmd_fogon);
}

public OnMapStart()
{
	new index; 
	index = FindEntityByClassname(-1, "env_fog_controller");
	if(index != -1)
	{
		pFogHuman = index;
		PrintToServer("Fog for Human on index: %d selected!", pFogHuman);
	}
	else
	{
		pFogHuman = CreateEntityByName("env_fog_controller");
		PrintToServer("Fog for Human on index: %d create and selected!", pFogHuman);
	}
	
	DispatchKeyValue(pFogHuman, "targetname", "FogHuman");
	DispatchKeyValue(pFogHuman, "fogenable", "1");
	DispatchKeyValue(pFogHuman, "spawnflags", "1");
	DispatchKeyValue(pFogHuman, "fogblend", "0");
	DispatchKeyValue(pFogHuman, "fogcolor", "0 0 0");  // 255 0 0 (nemesida)
	DispatchKeyValue(pFogHuman, "fogcolor2", "0 0 0"); // 255 0 0 (nemesida)
	DispatchKeyValueFloat(pFogHuman, "fogstart", f_mapFogStart);
	DispatchKeyValueFloat(pFogHuman, "fogend", f_mapFogEnd);
	DispatchKeyValueFloat(pFogHuman, "fogmaxdensity", f_mapFogDensity);
	DispatchSpawn(pFogHuman);
	PrintToServer("Fog to Human change. Id: %d", pFogHuman);
	//AcceptEntityInput(pFogHuman, "TurnOn");
	
	//Zombie Fog
	pFogZombie = CreateEntityByName("env_fog_controller");
	DispatchSpawn(pFogZombie);
	PrintToServer("Fog for Zombie on index: %d selected!", pFogZombie);
	if(pFogZombie != -1)
	{
		DispatchKeyValue(pFogZombie, "targetname", "FogZombie");
		DispatchKeyValue(pFogZombie, "fogenable", "1");
		DispatchKeyValue(pFogZombie, "spawnflags", "1");
		DispatchKeyValue(pFogZombie, "fogblend", "0");
		DispatchKeyValue(pFogZombie, "fogcolor", "255 0 0");  // 255 0 0 (nemesida)
		DispatchKeyValue(pFogZombie, "fogcolor2", "255 0 0"); // 255 0 0 (nemesida)
		DispatchKeyValueFloat(pFogZombie, "fogstart", f_mapFogStart);
		DispatchKeyValueFloat(pFogZombie, "fogend", f_mapFogEnd);
		DispatchKeyValueFloat(pFogZombie, "fogmaxdensity", f_mapFogDensity);
	}
	//AcceptEntityInput(pFogZombie, "TurnOff");
	PrintToServer("Fog to Zombie on index: %d create", pFogZombie);
	
	//Nemesis Fog
	pFogNemesis = CreateEntityByName("env_fog_controller");
	DispatchSpawn(pFogNemesis);
	PrintToServer("Fog for Nemesis on index: %d selected!", pFogNemesis);
	if(pFogNemesis != -1) 
	{
		DispatchKeyValue(pFogNemesis, "targetname", "FogNemesis");
		DispatchKeyValue(pFogNemesis, "fogenable", "1");
		DispatchKeyValue(pFogNemesis, "spawnflags", "1");
		DispatchKeyValue(pFogNemesis, "fogblend", "0");
		DispatchKeyValue(pFogNemesis, "fogcolor", "255 0 0");  // 255 0 0 (nemesida)
		DispatchKeyValue(pFogNemesis, "fogcolor2", "255 0 0"); // 255 0 0 (nemesida)
		DispatchKeyValueFloat(pFogNemesis, "fogstart", f_mapFogNemStart);
		DispatchKeyValueFloat(pFogNemesis, "fogend", f_mapFogNemEnd);
		DispatchKeyValueFloat(pFogNemesis, "fogmaxdensity", f_mapFogNemDensity);
	}
	//AcceptEntityInput(pFogNemesis, "TurnOn");
	PrintToServer("Fog for Nemesis on index: %d create", pFogNemesis);
	/*for (new i = 1; i <= MaxClients; i++)
	{
		SetVariantString("FogHuman");
		AcceptEntityInput(i, "SetFogController");		
	}*/
}

public Action:cmd_fogoff(client, args)
{
	char Arguments[256];
	GetCmdArg(1, Arguments, sizeof(Arguments));
	
	
	if (pFogHuman > 0 && StrEqual(Arguments, "human"))
	{
		AcceptEntityInput(pFogHuman, "TurnOff");
		PrintToServer("Turn Off Human Fog index: %d", pFogHuman);
	}
	if (pFogZombie > 0 && StrEqual(Arguments, "zombie"))
	{
		AcceptEntityInput(pFogZombie, "TurnOff");
		PrintToServer("Turn Off Zombie Fog index: %d", pFogZombie);
	}
	if (pFogNemesis > 0 && StrEqual(Arguments, "nemesis"))
	{
		AcceptEntityInput(pFogNemesis, "TurnOff");
		PrintToServer("Turn Off Nemesis Fog index: %d", pFogNemesis);
	}
	if (pFogHuman > 0 && pFogZombie > 0 && pFogNemesis > 0 && args == 0)
	{
		AcceptEntityInput(pFogHuman, "TurnOff");
		AcceptEntityInput(pFogZombie, "TurnOff");
		AcceptEntityInput(pFogNemesis, "TurnOff");
		PrintToServer("Turn Off All Fog on index's: %d %d %d", pFogHuman, pFogZombie, pFogNemesis);
	}
	//PrintToChat(client, "Fog is off")
	PrintToChatAll("%t", "Fog_off");
	return Plugin_Handled;
}    

public Action:cmd_fogon(client, args)
{
	char Arguments[256];
	GetCmdArg(1, Arguments, sizeof(Arguments));
	
	if (pFogHuman > 0 && StrEqual(Arguments, "human"))
	{
		AcceptEntityInput(pFogHuman, "TurnOn");
		PrintToServer("Turn On Human Fog index: %d", pFogHuman);
		SetVariantString("FogHuman");
		AcceptEntityInput(client, "SetFogController");
	}
	if (pFogZombie > 0 && StrEqual(Arguments, "zombie"))
	{
		AcceptEntityInput(pFogZombie, "TurnOn");
		PrintToServer("Turn On Zombie Fog index: %d", pFogZombie);
		SetVariantString("FogZombie");
		AcceptEntityInput(client, "SetFogController");
	}
	if (pFogNemesis > 0 && StrEqual(Arguments, "nemesis"))
	{
		AcceptEntityInput(pFogNemesis, "TurnOn");
		PrintToServer("Turn On Nemesis Fog index: %d", pFogNemesis);
		SetVariantString("FogNemesis");
		AcceptEntityInput(client, "SetFogController");
	}
	PrintToChatAll("%t", "Fog_on");
	return Plugin_Handled;
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	modeGame = GetModeInfected();
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i)) 
		{
			SetVariantString("FogHuman");
			AcceptEntityInput(i, "SetFogController");
			PrintToChat(i, "%t", "Fog_on");
		}
	} 
	AcceptEntityInput(pFogHuman, "TurnOn");
	AcceptEntityInput(pFogZombie, "TurnOff");
	AcceptEntityInput(pFogNemesis, "TurnOn");
	PrintToServer("Mod game! %d", modeGame);
}

public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	//ServerCommand("exec sourcemod/zombiereloaded/randommode.cfg");
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	if (IsClientInGame(client)) 
	{
		SetVariantString("FogZombie");
		AcceptEntityInput(client, "SetFogController");
		PrintToChat(client, "%t", "Fog_on");
	}
}

public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == gCV_FogEnabled)
	{
		b_FogEnabled = bool:StringToInt(newValue);
	}
	else if (convar == gCV_mapFogStart)
	{
		f_mapFogStart = StringToFloat(newValue);
	}
	else if (convar == gCV_mapFogEnd)
	{
		f_mapFogEnd = StringToFloat(newValue);
	}
	else if (convar == gCV_mapFogDensity)
	{
		f_mapFogDensity = StringToFloat(newValue);
	}
	else if (convar == gCV_mapFogNemStart)
	{
		f_mapFogNemStart = StringToFloat(newValue);
	}
	else if (convar == gCV_mapFogNemEnd)
	{
		f_mapFogNemEnd = StringToFloat(newValue);
	}
	else if (convar == gCV_mapFogNemDensity)
	{
		f_mapFogNemDensity = StringToFloat(newValue);
	}
}

GetModeInfected()
{
	new modG;
	decl String: modeName[128];
	GetConVarString(FindConVar("zr_classes_default_zombie"), modeName, sizeof(modeName));
	
	if (StrEqual(modeName, "Nemesis"))
	{
		modG = 1;
	}
	else
	{
		modG = 0;
	}

	return modG;
}