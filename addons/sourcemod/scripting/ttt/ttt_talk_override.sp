#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

#include <ttt>
#include <config_loader>

#define PLUGIN_NAME TTT_PLUGIN_NAME ... " - Talk Override"

bool g_bEnableTVoice = false;
bool g_bTVoice[MAXPLAYERS + 1] =  { false, ... };
char g_sConfigFile[PLATFORM_MAX_PATH];
char g_sPluginTag[PLATFORM_MAX_PATH] = "";

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = TTT_PLUGIN_AUTHOR,
	description = TTT_PLUGIN_DESCRIPTION,
	version = TTT_PLUGIN_VERSION,
	url = TTT_PLUGIN_URL
};

public void OnPluginStart()
{
	TTT_IsGameCSGO();
	
	BuildPath(Path_SM, g_sConfigFile, sizeof(g_sConfigFile), "configs/ttt/config.cfg");
	Config_Setup("TTT", g_sConfigFile);
	
	Config_LoadString("ttt_plugin_tag", "{orchid}[{green}T{darkred}T{blue}T{orchid}]{lightgreen} %T", "The prefix used in all plugin messages (DO NOT DELETE '%T')", g_sPluginTag, sizeof(g_sPluginTag));
	
	Config_Done();
	
	BuildPath(Path_SM, g_sConfigFile, sizeof(g_sConfigFile), "configs/ttt/talk_override.cfg");
	Config_Setup("TTT-TalkOverride", g_sConfigFile);
	g_bEnableTVoice = Config_LoadBool("tor_traitor_voice_chat", true, "Enable traitor voice chat (command for players: sm_tvoice)?");
	Config_Done();
	
	if(g_bEnableTVoice)
		RegConsoleCmd("sm_tvoice", Command_TVoice);
	
	HookEvent("player_death", Event_PlayerDeath);
}

public Action Command_TVoice(int client, int args)
{
	if(!TTT_IsClientValid(client))
		return Plugin_Handled;
	
	if(!TTT_IsRoundActive())
		return Plugin_Handled;
	
	if(!IsPlayerAlive(client))
		return Plugin_Handled;
	
	if(TTT_GetClientRole(client) != TTT_TEAM_TRAITOR)
		return Plugin_Handled;
	
	if(g_bTVoice[client])
	{
		PrintToChat(client, g_sPluginTag, "Traitor Voice Chat: Disabled!", client);
		g_bTVoice[client] = false;
		LoopValidClients(i)
		{
			SetListenOverride(i, client, Listen_Yes);
			if(TTT_GetClientRole(i) == TTT_TEAM_TRAITOR)
				PrintToChat(i, g_sPluginTag, "stopped talking in Traitor Voice Chat", i, client);
		}
	}
	else
	{
		g_bTVoice[client] = true;
		PrintToChat(client, g_sPluginTag, "Traitor Voice Chat: Enabled!", client);
		LoopValidClients(i)
		{
			if(TTT_GetClientRole(i) != TTT_TEAM_TRAITOR)
				SetListenOverride(i, client, Listen_No);
			else
				PrintToChat(i, g_sPluginTag, "is now talking in Traitor Voice Chat", i, client);
		}
	}
	return Plugin_Continue;
}

public void OnClientPostAdminCheck(int client)
{
	LoopValidClients(i)
	{
		if(IsPlayerAlive(i))
		{
			if(TTT_IsRoundActive())
				SetListenOverride(i, client, Listen_No);
			else
				SetListenOverride(i, client, Listen_Yes);
		}else{
			SetListenOverride(i, client, Listen_Yes);
		}
	}
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	g_bTVoice[victim] = false;
	LoopValidClients(i)
	{
		if(IsPlayerAlive(i))
			SetListenOverride(i, victim, Listen_No);
		else
			SetListenOverride(i, victim, Listen_Yes);
	}
}

public void TTT_OnClientGetRole(int client, int role)
{
	LoopValidClients(i)
		SetListenOverride(i, client, Listen_Yes);
}