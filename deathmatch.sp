/*
	GNU GENERAL PUBLIC LICENSE
	VERSION 2, JUNE 1991
	Copyright (C) 1989, 1991 Free Software Foundation, Inc.
	51 Franklin Street, Fith Floor, Boston, MA 02110-1301, USA
	Everyone is permitted to copy and distribute verbatim copies
	of this license document, but changing it is not allowed.
	GNU GENERAL PUBLIC LICENSE VERSION 3, 29 June 2007
	Copyright (C) 2007 Free Software Foundation, Inc. {http://fsf.org/}
	Everyone is permitted to copy and distribute verbatim copies
	of this license document, but changing it is not allowed.
							Preamble
	The GNU General Public License is a free, copyleft license for
	software and other kinds of works.
	The licenses for most software and other practical works are designed
	to take away your freedom to share and change the works. By contrast,
	the GNU General Public license is intended to guarantee your freedom to 
	share and change all versions of a progrm--to make sure it remins free
	software for all its users. We, the Free Software Foundation, use the
	GNU General Public license for most of our software; it applies also to
	any other work released this way by its authors. You can apply it to
	your programs, too.
*/
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define MAXPLAYER MAXPLAYERS + 1

//float g_origin[2048 + 1][3]
//float g_angles[2048 + 1][3]
ArrayList g_spawnInfo;
char g_map[192];
int g_scoreT;
int g_scoreCT;
float g_time;
int g_spawnpointMax;
bool g_endgame;
bool g_buyAble[MAXPLAYER];
bool g_silentKnife;
Handle gCV_roundtime;
Handle gCV_freezetime;
Handle gCV_buytime;
Handle gCV_timelimit;
float g_roundtime;
int g_freezetime;
int g_timelimit;
char g_weaponAmmo[][] = {"glock;120", "usp;100", "p228;52", "deagle;35", "elite;120", "fiveseven;100", 
						"m3;32", "xm1014;32", "galil;90", "ak47;90", "scout;90", "sg552;90", 
						"awp;30", "g3sg1;90", "famas;90", "m4a1;90", "aug;90", "sg550;90", 
						"mac10;100", "tmp;120", "mp5navy;120", "ump45;100", "p90;100", "m249;100"}; //https://wiki.alliedmods.net/Counter-Strike:_Source_Weapons
#define debug false
#if debug
int gI_step[MAXPLAYER];
#endif

enum struct eSpawn
{
	float origin[3];
	float angles[3];
}

public Plugin myinfo =
{
	name = "Deathmatch",
	author = "Nick Jurevics (Smesh, Smesh292)",
	description = "Make able to spawn instantly after death on the map in random place.",
	version = "1.4",
	url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart);
	HookEvent("player_death", OnDeath);
	HookEvent("player_spawn", OnSpawn);
	HookEvent("player_team", OnTeam);

	AddCommandListener(joinclass, "joinclass");

	#if debug
	RegConsoleCmd("sm_getscore", cmd_getscore);
	RegConsoleCmd("sm_score", cmd_getscore);
	#endif

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);

			if(!IsPlayerAlive(i))
				GetPossition(i);
		}
	}

	GetMaxSpawnpoint();
	GetConVar();
	AddNormalSoundHook(SoundHook);
}

public void OnMapStart()
{
	GetMaxSpawnpoint();
}

stock void GetMaxSpawnpoint()
{
	GetCurrentMap(g_map, sizeof(g_map));

	char format[256];
	Format(format, sizeof(format), "cfg/sourcemod/deathmatch/%s.txt", g_map);

	if(FileExists(format))
	{
		File f = OpenFile(format, "r");

		char line[96];
		char origin_[3][96];
		char angles_[6][96];

		g_spawnpointMax = 0;

		eSpawn spawn;

		float origin[3];
		float angles[3];

		delete g_spawnInfo;

		g_spawnInfo = new ArrayList(sizeof(eSpawn));

		while(!f.EndOfFile() && f.ReadLine(line, 96))
		{
			ExplodeString(line, " ", origin_, 3, 96);
			ExplodeString(line, " ", angles_, 6, 96);

			for(int i = 0; i <= 2; i++)
			{
				origin[i] = StringToFloat(origin_[i]);
				angles[i] = StringToFloat(angles_[i + 3]);
			}
			
			for(int i = 0; i <= 2; i++)
			{
				spawn.origin[i] = origin[i];
				spawn.angles[i] = angles[i];
			}

			g_spawnInfo.Resize(g_spawnpointMax + 2);
			g_spawnInfo.SetArray(++g_spawnpointMax, spawn, sizeof(spawn));
		}

		delete f;
	}
}

stock void GetConVar()
{
	gCV_roundtime = FindConVar("mp_roundtime");
	gCV_freezetime = FindConVar("mp_freezetime");
	gCV_buytime = FindConVar("mp_buytime");
	gCV_timelimit = FindConVar("mp_timelimit");

	g_roundtime = GetConVarFloat(gCV_roundtime);
	g_freezetime = GetConVarInt(gCV_freezetime);
	g_timelimit = GetConVarInt(gCV_timelimit);

	SetConVarBounds(gCV_roundtime, ConVarBound_Upper, true, float(g_timelimit)); //https://forums.alliedmods.net/showthread.php?t=317850
	SetConVarFloat(gCV_roundtime, float(g_timelimit) - float(g_freezetime) / 60.0 - 1.0 / 60.0);
	SetConVarFloat(gCV_buytime, float(g_timelimit));
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponDrop, sdkweapondrop);
	SDKHook(client, SDKHook_PostThink, sdkpostthink);
	SDKHook(client, SDKHook_WeaponEquipPost, sdkweaponequip);
}

public void OnClientDisconnect(int client)
{
	int entity;
	while((entity = FindEntityByClassname(entity, "weapon_*")) > 0)
		if(GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity") == client)
			RemoveEntity(entity);
}

public Action sdkweapondrop(int client, int weapon)
{
	if(IsValidEntity(weapon))
		RemoveEntity(weapon);

	return Plugin_Continue;
}

public void sdkpostthink(int client)
{
	if(g_buyAble[client])
		SetEntProp(client, Prop_Send, "m_bInBuyZone", true); //https://forums.alliedmods.net/showthread.php?t=216370&page=2
	else
		SetEntProp(client, Prop_Send, "m_bInBuyZone", false);
	SetEntProp(client, Prop_Send, "m_bInBombZone", false);
}

public void sdkweaponequip(int client, int weapon)
{
	SDKHook(weapon, SDKHook_ReloadPost, sdkreload);
}

public void sdkreload(int weapon, bool bSuccessful)
{
	if(bSuccessful)
	{
		int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
		int start = FindSendPropInfo("CBasePlayer", "m_iAmmo");

		char classname[32];
		GetEntityClassname(weapon, classname, sizeof(classname));

		char exploded[24][16];

		for(int i = 0; i < sizeof(g_weaponAmmo); i++)
		{
			ExplodeString(g_weaponAmmo[i], ";", exploded, 24, 16);

			if(StrContains(classname, exploded[0]) != -1)
			{
				SetEntData(GetEntPropEnt(weapon, Prop_Data, "m_hOwnerEntity"), (start + (ammotype * 4)), StringToInt(exploded[1])); //https://forums.alliedmods.net/showpost.php?p=1460194&postcount=3
				
				break;
			}
		}
	}
}

#if debug
Action cmd_getscore(int client, int args)
{
	PrintToServer("Counter-Terorist score is: %i", g_scoreCT);
	PrintToServer("Terorist score is: %i", g_scoreT);

	char format[256];
	Format(format, sizeof(format), "cfg/sourcemod/deathmatch/%s.txt", g_map)

	char cmd[8]
	GetCmdArgString(cmd, sizeof(cmd))

	if(StrEqual(cmd, "?"))
	{
		float vec[3];
		GetClientAbsOrigin(client, vec);
		PrintToConsole(client, "%f %f %f", vec[0], vec[1], vec[2]);
		return Plugin_Handled;
	}

	char exploded[8][8];
	ExplodeString(cmd, ";", exploded, 8, 8);
	char format[256];
	Format(format, sizeof(format), "cfg/sourcemod/deathmatch/%s.txt", g_map);

	if(FileExists(format))
	{
		int random = GetRandomInt(1, g_spawnpointMax);

		eSpawn spawn;
		g_spawnInfo.GetArray(g_spawnpointMax, spawn, sizeof(spawn));

		TeleportEntity(client, spawn.origin, spawn.angles, view_as<float>({0.0, 0.0, 0.0})); //https://github.com/alliedmodders/cssdm
	}

	Menu menu = new Menu(spawnpointfixer_handler);

	menu.SetTitle("Spawnpoint fixer");

	menu.AddItem("0", "X+");
	menu.AddItem("1", "X-");
	menu.AddItem("2", "Y+");
	menu.AddItem("3", "Y-");
	menu.AddItem("4", "Z+");
	menu.AddItem("5", "Z-");

	menu.Display(client, MENU_TIME_FOREVER);

	gI_step[client] = StringToInt(exploded[1]);

	return Plugin_Handled;
}

public int spawnpointfixer_handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			float vec[3];
			GetClientAbsOrigin(param1, vec);

			switch(param2)
			{
				case 0:
					vec[0] += gI_step[param1];
				case 1:
					vec[0] -= gI_step[param1];
				case 2:
					vec[1] += gI_step[param1];
				case 3:
					vec[1] -= gI_step[param1];
				case 4:
					vec[2] += gI_step[param1];
				case 5:
					vec[2] -= gI_step[param1];
			}

			TeleportEntity(param1, vec, NULL_VECTOR, NULL_VECTOR);

			menu.DisplayAt(param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
		}
	}
}
#endif

public Action joinclass(int client, const char[] command, int argc)
{
	if(!IsPlayerAlive(client))
		CreateTimer(1.0, timer_respawn, client, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

stock void GetPossition(int client)
{
	if(IsClientInGame(client))
	{
		int team = GetClientTeam(client);

		if(team == CS_TEAM_T || team == CS_TEAM_CT)
		{
			if(!IsPlayerAlive(client))
			{
				CS_RespawnPlayer(client);

				g_silentKnife = true;
			}

			else if(IsPlayerAlive(client))
			{
				char format[256];
				Format(format, sizeof(format), "cfg/sourcemod/deathmatch/%s.txt", g_map);

				if(FileExists(format))
				{
					int random = GetRandomInt(1, g_spawnpointMax);

					eSpawn spawn;
					g_spawnInfo.GetArray(random, spawn, sizeof(spawn));

					TeleportEntity(client, spawn.origin, spawn.angles, view_as<float>({0.0, 0.0, 0.0})); //https://github.com/alliedmodders/cssdm
				}

				SetEntProp(client, Prop_Send, "m_iAccount", 16000);
				SetEntProp(client, Prop_Data, "m_CollisionGroup", 2);

				g_buyAble[client] = true;
			}
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname) //https://forums.alliedmods.net/showthread.php?t=247957
{
	if(StrEqual(classname, "func_hostage_rescue"))
		RemoveEntity(entity);
	//else if(StrEqual(classname, "env_fog_controller")) //fog filter is plugin avaliabe
	//	RemoveEntity(entity)
}

stock Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_scoreT = 0;
	g_scoreCT = 0;
	g_time = GetGameTime();
	g_endgame = false;

	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && IsPlayerAlive(i))
			GetPossition(i);

	ServerCommand("mat_texture_list_txlod_sync reset");
	ServerCommand("mp_ignore_round_win_conditions 1");
	GetConVar();

	return Plugin_Continue;
}

public Action OnDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid")); //user ID who died
	CreateTimer(1.0, timer_respawn, client, TIMER_FLAG_NO_MAPCHANGE);

	int attacker = GetClientOfUserId(event.GetInt("attacker")); //user ID who killed

	if(0 < attacker <= MaxClients && IsClientInGame(attacker))
	{
		int team = GetClientTeam(attacker);

		if(team == CS_TEAM_T)
			g_scoreT++;
		else if(team == CS_TEAM_CT)
			g_scoreCT++;
	}

	return Plugin_Continue;
}

public Action OnSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	GetPossition(client);

	return Plugin_Continue;
}

public Action OnTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if(IsFakeClient(client))
		CreateTimer(1.0, timer_respawn, client, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

public Action timer_respawn(Handle timer, int client)
{
	if(IsClientInGame(client))
		GetPossition(client);

	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vec[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(g_time + g_roundtime * 60.0 + float(g_freezetime) - 1.0 <= GetGameTime() && !g_endgame)
	{
		Handle convar = FindConVar("mp_round_restart_delay");
		float roundrestartdelay = GetConVarFloat(convar);

		if(g_scoreT == g_scoreCT)
		{
			int whoWin = GetRandomInt(CS_TEAM_T, CS_TEAM_CT);

			if(whoWin == CS_TEAM_T)
				g_scoreT++;
			else if(whoWin == CS_TEAM_CT)
				g_scoreCT++;
		}

		SetConVarInt(FindConVar("mp_ignore_round_win_conditions"), 0);

		if(g_scoreT > g_scoreCT)
		{
			SetTeamScore(CS_TEAM_T, GetTeamScore(CS_TEAM_T) + 1);
			CS_TerminateRound(roundrestartdelay, CSRoundEnd_TerroristWin); //https://www.bing.com/search?q=CSRoundEnd_TerroristWin&cvid=f8db94b57b5a41b59b8f6042a76dfed1&aqs=edge..69i57.399j0j4&FORM=ANAB01&PC=U531
		}

		else
		{
			SetTeamScore(CS_TEAM_CT, GetTeamScore(CS_TEAM_CT) + 1); //https://github.com/DoctorMcKay/sourcemod-plugins/blob/master/scripting/teamscores.sp#L63
			CS_TerminateRound(roundrestartdelay, CSRoundEnd_CTWin);
		}

		AcceptEntityInput(CreateEntityByName("game_end"), "EndGame"); //https://forums.alliedmods.net/showthread.php?t=216503
		g_endgame = true;
	}

	if(g_time + float(g_freezetime) <= GetGameTime() && (buttons & IN_ATTACK || buttons & IN_ATTACK2))
		if(g_buyAble[client])
			g_buyAble[client] = false;

	return Plugin_Continue;
}

public Action CS_OnBuyCommand(int client, const char[] weapon) //https://forums.alliedmods.net/showthread.php?t=314852
{
	if(StrEqual(weapon, "defuser"))
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action SoundHook(int clients[MAXPLAYERS], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags, char soundEntry[PLATFORM_MAX_PATH], int& seed) //https://github.com/alliedmodders/sourcepawn/issues/476
{
	if(StrEqual(sample, "weapons/knife/knife_deploy1.wav") && g_silentKnife)
	{
		g_silentKnife = false;

		return Plugin_Handled;
	}

	return Plugin_Continue;
}
