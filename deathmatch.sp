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

float gF_origin[MAXPLAYERS + 1][3]
float gF_angles[MAXPLAYERS + 1][3]
char gS_map[192]
int gI_scoreT
int gI_scoreCT
float gF_time
int gI_spawnpointMax
bool gB_endgame
bool gB_buyAble[MAXPLAYERS + 1]
bool gB_silentKnife
Handle gCV_roundtime
Handle gCV_freezetime
Handle gCV_buytime
Handle gCV_timelimit
float gF_roundtime
int gI_freezetime
int gI_timelimit
char gS_weaponAmmo[][] = {"glock;120", "usp;100", "p228;52", "deagle;35", "elite;120", "fiveseven;100", 
						"m3;32", "xm1014;32", "galil;90", "ak47;90", "scout;90", "sg552;90", 
						"awp;30", "g3sg1;90", "famas;90", "m4a1;90", "aug;90", "sg550;90", 
						"mac10;100", "tmp;120", "mp5navy;120", "ump45;100", "p90;100", "m249;100"} //https://wiki.alliedmods.net/Counter-Strike:_Source_Weapons
#define debug false
#if debug
int gI_step[MAXPLAYERS + 1]
#endif

public Plugin myinfo =
{
	name = "Deathmatch",
	author = "Nick Jurevics (Smesh, Smesh292)",
	description = "Make able to spawn instantly after death on the map in random place.",
	version = "1.2",
	url = "http://www.sourcemod.net/"
}

public void OnPluginStart()
{
	HookEvent("round_start", round_start)
	HookEvent("player_death", playerdeath)
	HookEvent("player_spawn", playerspawn)
	HookEvent("player_team", playerteam)
	AddCommandListener(joinclass, "joinclass")
	#if debug
	RegConsoleCmd("sm_getscore", cmd_getscore)
	RegConsoleCmd("sm_score", cmd_getscore)
	#endif
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i)
			if(!IsPlayerAlive(i))
				GetPossition(i)
		}
	}
	GetMaxSpawnpoint()
	GetConVar()
	AddNormalSoundHook(SoundHook)
}

public void OnMapStart()
{
	GetMaxSpawnpoint()
}

void GetMaxSpawnpoint()
{
	GetCurrentMap(gS_map, 192)
	char sFormat[256]
	Format(sFormat, 256, "cfg/sourcemod/deathmatch/%s.txt", gS_map)
	if(FileExists(sFormat))
	{
		File f = OpenFile(sFormat, "r")
		char sLine[96]
		gI_spawnpointMax = 0
		while(!f.EndOfFile() && f.ReadLine(sLine, 96))
			gI_spawnpointMax++
		delete f
	}
}

void GetConVar()
{
	gCV_roundtime = FindConVar("mp_roundtime")
	gCV_freezetime = FindConVar("mp_freezetime")
	gCV_buytime = FindConVar("mp_buytime")
	gCV_timelimit = FindConVar("mp_timelimit")
	gF_roundtime = GetConVarFloat(gCV_roundtime)
	gI_freezetime = GetConVarInt(gCV_freezetime)
	gI_timelimit = GetConVarInt(gCV_timelimit)
	SetConVarBounds(gCV_roundtime, ConVarBound_Upper, true, float(gI_timelimit)) //https://forums.alliedmods.net/showthread.php?t=317850
	SetConVarFloat(gCV_roundtime, float(gI_timelimit) - float(gI_freezetime) / 60.0 - 1.0 / 60.0)
	SetConVarFloat(gCV_buytime, float(gI_timelimit))
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponDrop, sdkweapondrop)
	SDKHook(client, SDKHook_PostThink, sdkpostthink)
	SDKHook(client, SDKHook_WeaponEquipPost, sdkweaponequip)
}

public void OnClientDisconnect(int client)
{
	int entity
	while((entity = FindEntityByClassname(entity, "weapon_*")) > 0)
		if(GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity") == client)
			RemoveEntity(entity)
}

Action sdkweapondrop(int client, int weapon)
{
	if(IsValidEntity(weapon))
		RemoveEntity(weapon)
}

void sdkpostthink(int client)
{
	if(gB_buyAble[client])
		SetEntProp(client, Prop_Send, "m_bInBuyZone", true) //https://forums.alliedmods.net/showthread.php?t=216370&page=2
	else
		SetEntProp(client, Prop_Send, "m_bInBuyZone", false)
	SetEntProp(client, Prop_Send, "m_bInBombZone", false)
}

void sdkweaponequip(int client, int weapon)
{
	SDKHook(weapon, SDKHook_ReloadPost, sdkreload)
}

void sdkreload(int weapon, bool bSuccessful)
{
	if(bSuccessful)
	{
		int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType")
		int start = FindSendPropInfo("CBasePlayer", "m_iAmmo")
		char sClassname[32]
		GetEntityClassname(weapon, sClassname, 32)
		char sExploded[24][16]
		for(int i = 0; i < sizeof(gS_weaponAmmo); i++)
		{
			ExplodeString(gS_weaponAmmo[i], ";", sExploded, 24, 16)
			if(StrContains(sClassname, sExploded[0]) != -1)
			{
				SetEntData(GetEntPropEnt(weapon, Prop_Data, "m_hOwnerEntity"), (start + (ammotype * 4)), StringToInt(sExploded[1])) //https://forums.alliedmods.net/showpost.php?p=1460194&postcount=3
				break
			}
		}
	}
}

#if debug
Action cmd_getscore(int client, int args)
{
	PrintToServer("Counter-Terorist score is: %i", gI_scoreCT)
	PrintToServer("Terorist score is: %i", gI_scoreT)
	char sFormat[256]
	Format(sFormat, 256, "cfg/sourcemod/deathmatch/%s.txt", gS_map)
	char sCmd[8]
	GetCmdArgString(sCmd, 8)
	if(StrEqual(sCmd, "?"))
	{
		float vec[3]
		GetClientAbsOrigin(client, vec)
		PrintToConsole(client, "%f %f %f", vec[0], vec[1], vec[2])
		return Plugin_Handled
	}
	char sExploded[8][8]
	ExplodeString(sCmd, ";", sExploded, 8, 8)
	if(FileExists(sFormat))
	{
		File f = OpenFile(sFormat, "r")
		char sLine[96]
		int lineChosen = StringToInt(sExploded[0])
		int lineCurrect
		while(!f.EndOfFile() && f.ReadLine(sLine, 96))
		{
			if(lineChosen == lineCurrect)
				break
			lineCurrect++
		}
		delete f
		char sOrigin[3][96]
		ExplodeString(sLine, " ", sOrigin, 3, 96)
		char sAngles[6][96]
		ExplodeString(sLine, " ", sAngles, 6, 96)
		for(int i = 0; i <= 2; i++)
		{
			gF_origin[client][i] = StringToFloat(sOrigin[i])
			gF_angles[client][i] = StringToFloat(sAngles[i + 3])
		}
		TeleportEntity(client, gF_origin[client], gF_angles[client], view_as<float>({0.0, 0.0, 0.0})) //https://github.com/alliedmodders/cssdm
	}
	Menu menu = new Menu(spawnpointfixer_handler)
	menu.SetTitle("Spawnpoint fixer")
	menu.AddItem("0", "X+")
	menu.AddItem("1", "X-")
	menu.AddItem("2", "Y+")
	menu.AddItem("3", "Y-")
	menu.AddItem("4", "Z+")
	menu.AddItem("5", "Z-")
	menu.Display(client, MENU_TIME_FOREVER)
	gI_step[client] = StringToInt(sExploded[1])
	return Plugin_Handled
}

int spawnpointfixer_handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			float vec[3]
			GetClientAbsOrigin(param1, vec)
			switch(param2)
			{
				case 0:
					vec[0] += gI_step[param1]
				case 1:
					vec[0] -= gI_step[param1]
				case 2:
					vec[1] += gI_step[param1]
				case 3:
					vec[1] -= gI_step[param1]
				case 4:
					vec[2] += gI_step[param1]
				case 5:
					vec[2] -= gI_step[param1]
			}
			TeleportEntity(param1, vec, NULL_VECTOR, NULL_VECTOR)
			menu.DisplayAt(param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER)
		}
	}
}
#endif

Action joinclass(int client, const char[] command, int argc)
{
	CreateTimer(1.0, timer_respawn, client, TIMER_FLAG_NO_MAPCHANGE)
}

void GetPossition(int client)
{
	if(IsClientInGame(client))
	{
		int team = GetClientTeam(client)
		if(team == CS_TEAM_T || team == CS_TEAM_CT)
		{
			if(!IsPlayerAlive(client))
			{
				CS_RespawnPlayer(client)
				gB_silentKnife = true
			}
			else if(IsPlayerAlive(client))
			{
				char sFormat[256]
				Format(sFormat, 256, "cfg/sourcemod/deathmatch/%s.txt", gS_map)
				if(FileExists(sFormat))
				{
					File f = OpenFile(sFormat, "r")
					char sLine[96]
					int currentLine
					int randomLine = GetRandomInt(1, gI_spawnpointMax)
					while(!f.EndOfFile() && f.ReadLine(sLine, 96))
					{
						currentLine++
						if(currentLine == randomLine)
							break
					}
					delete f
					char sOrigin[3][96]
					ExplodeString(sLine, " ", sOrigin, 3, 96)
					char sAngles[6][96]
					ExplodeString(sLine, " ", sAngles, 6, 96)
					for(int i = 0; i <= 2; i++)
					{
						gF_origin[client][i] = StringToFloat(sOrigin[i])
						gF_angles[client][i] = StringToFloat(sAngles[i + 3])
					}
					TeleportEntity(client, gF_origin[client], gF_angles[client], view_as<float>({0.0, 0.0, 0.0})) //https://github.com/alliedmodders/cssdm
				}
				SetEntProp(client, Prop_Send, "m_iAccount", 16000)
				SetEntProp(client, Prop_Data, "m_CollisionGroup", 2)
				gB_buyAble[client] = true
			}
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname) //https://forums.alliedmods.net/showthread.php?t=247957
{
	if(StrEqual(classname, "func_hostage_rescue"))
		RemoveEntity(entity)
	else if(StrEqual(classname, "env_fog_controller"))
		RemoveEntity(entity)
}

Action round_start(Event event, const char[] name, bool dontBroadcast)
{
	gI_scoreT = 0
	gI_scoreCT = 0
	gF_time = GetGameTime()
	gB_endgame = false
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && IsPlayerAlive(i))
			GetPossition(i)
	ServerCommand("mat_texture_list_txlod_sync reset")
	ServerCommand("mp_ignore_round_win_conditions 1")
	GetConVar()
}

Action playerdeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid")) //user ID who died
	CreateTimer(1.0, timer_respawn, client, TIMER_FLAG_NO_MAPCHANGE)
	int attacker = GetClientOfUserId(event.GetInt("attacker")) //user ID who killed
	if(0 < attacker <= MaxClients && IsClientInGame(attacker))
	{
		int team = GetClientTeam(attacker)
		if(team == CS_TEAM_T)
			gI_scoreT++
		else if(team == CS_TEAM_CT)
			gI_scoreCT++
	}
}

Action playerspawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"))
	GetPossition(client)
}

Action playerteam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"))
	if(IsFakeClient(client))
		CreateTimer(1.0, timer_respawn, client, TIMER_FLAG_NO_MAPCHANGE)
}

Action timer_respawn(Handle timer, int client)
{
	if(IsClientInGame(client))
		GetPossition(client)
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vec[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(gF_time + gF_roundtime * 60.0 + float(gI_freezetime) - 1.0 <= GetGameTime() && !gB_endgame)
	{
		Handle convar = FindConVar("mp_round_restart_delay")
		float roundrestartdelay = GetConVarFloat(convar)
		if(gI_scoreT == gI_scoreCT)
		{
			int whoWin = GetRandomInt(CS_TEAM_T, CS_TEAM_CT)
			if(whoWin == CS_TEAM_T)
				gI_scoreT++
			else if(whoWin == CS_TEAM_CT)
				gI_scoreCT++
		}
		SetConVarInt(FindConVar("mp_ignore_round_win_conditions"), 0)
		if(gI_scoreT > gI_scoreCT)
		{
			SetTeamScore(CS_TEAM_T, GetTeamScore(CS_TEAM_T) + 1)
			CS_TerminateRound(roundrestartdelay, CSRoundEnd_TerroristWin) //https://www.bing.com/search?q=CSRoundEnd_TerroristWin&cvid=f8db94b57b5a41b59b8f6042a76dfed1&aqs=edge..69i57.399j0j4&FORM=ANAB01&PC=U531
		}
		else
		{
			SetTeamScore(CS_TEAM_CT, GetTeamScore(CS_TEAM_CT) + 1) //https://github.com/DoctorMcKay/sourcemod-plugins/blob/master/scripting/teamscores.sp#L63
			CS_TerminateRound(roundrestartdelay, CSRoundEnd_CTWin)
		}
		AcceptEntityInput(CreateEntityByName("game_end"), "EndGame") //https://forums.alliedmods.net/showthread.php?t=216503
		gB_endgame = true
	}
	if(gF_time + float(gI_freezetime) <= GetGameTime() && (buttons & IN_ATTACK || buttons & IN_ATTACK2))
		if(gB_buyAble[client])
			gB_buyAble[client] = false
}

public Action CS_OnBuyCommand(int client, const char[] weapon) //https://forums.alliedmods.net/showthread.php?t=314852
{
	if(StrEqual(weapon, "defuser"))
		return Plugin_Handled
	return Plugin_Continue
}

Action SoundHook(int clients[MAXPLAYERS], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags, char soundEntry[PLATFORM_MAX_PATH], int& seed) //https://github.com/alliedmodders/sourcepawn/issues/476
{
	if(StrEqual(sample, "weapons/knife/knife_deploy1.wav") && gB_silentKnife)
	{
		gB_silentKnife = false
		return Plugin_Handled
	}
	return Plugin_Continue
}
