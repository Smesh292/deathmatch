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
int gI_time
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
	AddCommandListener(joinclass, "joinclass")
	RegConsoleCmd("sm_getscore", cmd_getscore)
	RegConsoleCmd("sm_score", cmd_getscore)
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i))
			OnClientPutInServer(i)
	GetMaxSpawnpoint()
	GetConVar()
	AddNormalSoundHook(SoundHook)
	CreateTimer(3.0, timer_respawnDead, _, TIMER_REPEAT)
}

public void OnMapStart()
{
	GetMaxSpawnpoint()
	GetConVar()
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

Action cmd_getscore(int client, int args)
{
	PrintToServer("Counter-Terorist score is: %i", gI_scoreCT)
	PrintToServer("Terorist score is: %i", gI_scoreT)
	return Plugin_Handled
}

Action joinclass(int client, const char[] command, int argc)
{
	CreateTimer(1.0, timer_respawn, client, TIMER_FLAG_NO_MAPCHANGE)
}

void GetPossition(int client)
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
		gB_buyAble[client] = true
		SetEntProp(client, Prop_Data, "m_CollisionGroup", 2)
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
	gI_time = GetTime()
	gB_endgame = false
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && IsPlayerAlive(i))
			GetPossition(i)
	ServerCommand("mat_texture_list_txlod_sync reset")
	ServerCommand("mp_ignore_round_win_conditions 1")
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
	int team = GetClientTeam(client)
	if(team == CS_TEAM_T || team == CS_TEAM_CT)
		GetPossition(client)
}

Action timer_respawn(Handle timer, int client)
{
	if(IsClientInGame(client))
	{
		int team = GetClientTeam(client)
		if(team == CS_TEAM_T || team == CS_TEAM_CT)
			GetPossition(client)
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vec[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(gI_time + RoundFloat(gF_roundtime * 60.0) + gI_freezetime - 1 <= GetTime() && !gB_endgame)
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
		ServerCommand("mp_ignore_round_win_conditions 0")
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
	if(gI_time + gI_freezetime <= GetTime() && (buttons & IN_ATTACK || buttons & IN_ATTACK2))
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

Action timer_respawnDead(Handle timer)
{
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && IsFakeClient(i) && !IsPlayerAlive(i))
			GetPossition(i)
}
