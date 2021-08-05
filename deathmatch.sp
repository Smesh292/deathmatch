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

KeyValues gKV_spawnpoint

bool gB_roundStart[MAXPLAYERS + 1]
bool gB_onSpawn[MAXPLAYERS + 1]

int gI_countT
int gI_countCT

bool gI_closeIf
int gI_time

char sKVString[128]
char sRandomInt[32]
int gI_randomInt

bool gB_slayed

char gS_weapon[][] = {"Glock", "USP", "P228", "Deagle", "Elite", "FiveSeven", "M3", "XM1014", "Galil", 
					"AK47", "Scout", "SG552", "AWP", "G3SG1", "Famas", "M4A1", "Aug",
					"SG550", "Mac10", "TMP", "MP5Navy", "Ump45", "P90", "M249"}

public Plugin myinfo =
{
	name = "Deathmatch",
	author = "Nick Jurevics (Smesh, Smesh292)",
	description = "Make able to spawn instantly after death on the map in random place.",
	version = "1.1",
	url = "http://www.sourcemod.net/"
}

public void OnPluginStart()
{
	HookEvent("round_start", round_start)
	HookEvent("player_death", playerdeath)
	AddCommandListener(joinclass, "joinclass")
	RegConsoleCmd("sm_guns", cmd_gunsmenu)
	RegConsoleCmd("sm_getscore", cmd_getscore)
	RegConsoleCmd("sm_score", cmd_getscore)
}

public void OnMapStart()
{
	GetCurrentMap(gS_map, 192)
	gKV_spawnpoint = CreateKeyValues("GlobalKey") //https://github.com/alliedmodders/sourcemod/blob/master/plugins/testsuite/keyvalues.sp
	char sFormat[256]
	Format(sFormat, 256, "cfg/sourcemod/deathmatch/%s.txt", gS_map)
	gKV_spawnpoint.ImportFromFile(sFormat)
	char sKVStringTest[128]
	gI_randomInt = 0
	for(int i = 1; i <= 1000; i++)
	{
		IntToString(i, sRandomInt, 32)
		gKV_spawnpoint.GetString(sRandomInt, sKVStringTest, 128)
		if(strlen(sKVStringTest) > 0)
			gI_randomInt++
		if(strlen(sKVString) == 0)
			continue
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_SpawnPost, sdkspawnpost)
	SDKHook(client, SDKHook_WeaponDrop, sdkweapondrop)
	SDKHook(client, SDKHook_WeaponEquipPost, sdkweaponequippost)
	gB_roundStart[client] = false
}

public void OnClientDisconnect(int client)
{
	removeDrop(client)
}

void removeDrop(int client)
{
	int entity
	while((entity = FindEntityByClassname(entity, "weapon_*")) > 0)
		if(GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity") == client)
			RemoveEntity(entity)
}

void sdkspawnpost(int client)
{
	if(IsFakeClient(client))
	{
		int random = GetRandomInt(0, 5)
		char sWeapon[32]
		Format(sWeapon, 32, "weapon_%s", gS_weapon[random])
		GivePlayerItem(client, sWeapon)
		random = GetRandomInt(6, 23)
		Format(sWeapon, 32, "weapon_%s", gS_weapon[random])
		GivePlayerItem(client, sWeapon)
	}
	gB_onSpawn[client] = true
	GetPossition(client)
}

Action sdkweapondrop(int client, int weapon)
{
	if(IsValidEntity(weapon))
		RemoveEntity(weapon)
}

void sdkweaponequippost(int client, int weapon)
{
	removeDrop(client)
}

Action cmd_getscore(int client, int args)
{
	PrintToServer("Counter-Terorist score is: %i", gI_countCT)
	PrintToServer("Terorist score is: %i", gI_countT)
	Handle convar = FindConVar("mp_roundtime")
	float roundtime = GetConVarFloat(convar)
	PrintToServer("%f round time", roundtime)
	PrintToServer("%f %i", float(gI_time) + roundtime, GetTime())
	return Plugin_Handled
}

Action joinclass(int client, const char[] command, int argc)
{
	GetPossition(client)
}

void GetPossition(int client)
{
	int randomint = GetRandomInt(1, gI_randomInt)
	IntToString(randomint, sRandomInt, 32)
	gKV_spawnpoint.GetString(sRandomInt, sKVString, 128)
	char sString[7][128]
	ExplodeString(sKVString, " ", sString, 6, 128)
	float origin[3]
	origin[0] = StringToFloat(sString[0])
	gF_origin[client][0] = origin[0]
	origin[1] = StringToFloat(sString[1])
	gF_origin[client][1] = origin[1]
	origin[2] = StringToFloat(sString[2])
	gF_origin[client][2] = origin[2]
	float angles[3]
	angles[0] = StringToFloat(sString[3])
	gF_angles[client][0] = angles[0]
	angles[1] = StringToFloat(sString[4])
	gF_angles[client][1] = angles[1]
	angles[2] = StringToFloat(sString[5])
	gF_angles[client][2] = angles[2]
	if(!gB_onSpawn[client])
		CreateTimer(1.0, respawnTimer, client)
	else
	{
		TeleportEntity(client, gF_origin[client], gF_angles[client], view_as<float>({0.0, 0.0, 0.0}))
		gB_onSpawn[client] = false
	}
}

public void OnEntityCreated(int entity, const char[] classname) //https://forums.alliedmods.net/showthread.php?t=247957
{
	if(StrEqual(classname, "weapon_c4"))
		RemoveEntity(entity) //https://www.bing.com/search?q=hostage+cs+source&cvid=8d2fdfec401e4826b26c977db5f1395d&aqs=edge..69i57.3328j0j4&FORM=ANAB01&PC=U531
	if(StrEqual(classname, "hostage_entity")) //https://www.bing.com/search?q=bomb+trigger+cs+source&cvid=447663238dd4439f990d357f235b993b&aqs=edge..69i57.6657j0j4&FORM=ANAB01&PC=U531
		RemoveEntity(entity)
}

Action round_start(Event event, const char[] name, bool dontBroadcast)
{
	gI_countT = 0
	gI_countCT = 0
	gI_closeIf = true
	gI_time = GetTime()
	gB_slayed = false
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i)) //thanks to log for this idea . skin pref .sp
			gB_roundStart[i] = true
}

public void OnGameFrame()
{
	Handle convar = FindConVar("mp_roundtime")
	Handle convar2 = FindConVar("mp_freezetime")
	float roundtime = GetConVarFloat(convar)
	int freezetime = GetConVarInt(convar2)
	char sRoundtime[32]
	FloatToString(roundtime, sRoundtime, 32)
	char sExploded[3][32]
	ExplodeString(sRoundtime, ".", sExploded, 2, 32)
	int exploded[2]
	exploded[0] = StringToInt(sExploded[0])
	exploded[0] = exploded[0] * 60
	exploded[1] = StringToInt(sExploded[1])
	exploded[1] = exploded[1] / 100000
	exploded[1] = (exploded[1] * 60) / 10
	if(gI_time + exploded[0] + exploded[1] + freezetime - 1 == GetTime() && gI_closeIf)
	{
		Handle convar3 = FindConVar("mp_round_restart_delay")
		float roundrestartdelay = GetConVarFloat(convar3)
		if(gI_countT < gI_countCT && !gB_slayed)
		{
			for(int i = 1; i <= MaxClients; i++)
				if(IsClientInGame(i) && GetClientTeam(i) == 2)
				{
					char sName[MAX_NAME_LENGTH]
					GetClientName(i, sName, MAX_NAME_LENGTH)
					FakeClientCommand(i, "kill")
					PrintToChatAll("Player '%s' lose the round.", sName)
				}
			gB_slayed = true
			CS_TerminateRound(roundrestartdelay, CSRoundEnd_CTWin)
		}
		if(gI_countT > gI_countCT && !gB_slayed)
		{
			for(int i = 1; i <= MaxClients; i++)
				if(IsClientInGame(i) && GetClientTeam(i) == 3)
				{
					char sName[MAX_NAME_LENGTH]
					GetClientName(i, sName, MAX_NAME_LENGTH)
					FakeClientCommand(i, "kill")
					PrintToChatAll("Player '%s' lose the round.", sName)
				}
			gB_slayed = true
			CS_TerminateRound(roundrestartdelay, CSRoundEnd_TerroristWin) //https://www.bing.com/search?q=CSRoundEnd_TerroristWin&cvid=f8db94b57b5a41b59b8f6042a76dfed1&aqs=edge..69i57.399j0j4&FORM=ANAB01&PC=U531
		}
		gI_closeIf = false
	}
}

Action playerdeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid")) //user ID who died
	GetPossition(client)
	gB_roundStart[client] = false
	int attacker = GetClientOfUserId(event.GetInt("attacker")) //user ID who killed
	if(0 < attacker <= MaxClients && IsClientInGame(attacker))
	{
		int team = GetClientTeam(attacker)
		if(team == CS_TEAM_T)
			gI_countT++
		if(team == CS_TEAM_CT)
			gI_countCT++
	}
}

Action respawnTimer(Handle timer, int client)
{
	if(IsClientInGame(client))
	{
		if(!gB_roundStart[client])
		{
			int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll")
			if(IsValidEntity(ragdoll))
				RemoveEntity(ragdoll)
			CreateTimer(0.1, timer_ragdoll, client)
		}
	}
	return Plugin_Stop
}

Action timer_ragdoll(Handle timer, int client)
{
	if(IsClientInGame(client))
	{
		CS_RespawnPlayer(client)
		TeleportEntity(client, gF_origin[client], gF_angles[client], view_as<float>({0.0, 0.0, 0.0})) //https://github.com/alliedmodders/cssdm
	}
	return Plugin_Stop
}

Action cmd_gunsmenu(int client, int args)
{
	gunsmenu(client)
	return Plugin_Handled
}

void gunsmenu(int client)
{
	Menu menu = new Menu(menu_handler)
	menu.SetTitle("Pistols")
	for(int i = 0; i <= 5; i++)
		menu.AddItem(gS_weapon[i], gS_weapon[i])
	menu.Display(client, 20)
}

int menu_handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32]
			menu.GetItem(param2, sItem, 32)
			Format(sItem, 32, "weapon_%s", sItem)
			GivePlayerItem(param1, sItem) //https://www.sourcemod.net/new-api/sdktools_functions/GivePlayerItem
			menurifle(param1)
		}
	}
}

void menurifle(int client)
{
	Menu menu = new Menu(menu2_handler)
	menu.SetTitle("Rifles")
	for(int i = 6; i <= 23; i++)
		menu.AddItem(gS_weapon[i], gS_weapon[i])
	menu.Display(client, 20)
}

int menu2_handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32]
			menu.GetItem(param2, sItem, 32)
			Format(sItem, 32, "weapon_%s", sItem)
			GivePlayerItem(param1, sItem)
		}
	}
}

int Stuck(int client)
{
	float mins[3]
	float maxs[3]
	float origin[3]
	GetClientMins(client, mins)
	GetClientMaxs(client, maxs)
	GetClientAbsOrigin(client, origin)
	TR_TraceHullFilter(origin, origin, mins, maxs, MASK_PLAYERSOLID, TR_donthitself, client) //skiper, gurman idea, plugin 2020
	return TR_GetEntityIndex()
}

bool TR_donthitself(int entity, int mask, int client)
{
	return entity != client && 0 < entity <= MaxClients
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	int other = Stuck(client)
	if(0 < other <= MaxClients && IsPlayerAlive(client))
		if(GetEntProp(other, Prop_Data, "m_CollisionGroup") == 5)
			SetEntProp(other, Prop_Data, "m_CollisionGroup", 2)
	if(IsPlayerAlive(client) && other == -1)
		if(GetEntProp(client, Prop_Data, "m_CollisionGroup") == 2)
			SetEntProp(client, Prop_Data, "m_CollisionGroup", 5)
}
