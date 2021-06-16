/*GNU GENERAL PUBLIC LICENSE
VERSION 2, JUNE 1991
Copyright (C) 1989, 1991 Free Software Foundation, Inc.
51 Franklin Street, Fith Floor, Boston, MA 02110-1301, USA
Everyone is permitted to copy and distribute verbatim copies
of this license document, but changing it is not allowed.*/

/*GNU GENERAL PUBLIC LICENSE VERSION 3, 29 June 2007
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
	your programs, too.*/

#include <cstrike>
#include <sdktools>
#include <sdkhooks>

float gF_origin[MAXPLAYERS + 1][3]
float gF_angles[MAXPLAYERS + 1][3]
char gS_map[192]

Handle gH_timer[MAXPLAYERS + 1] = null

KeyValues gKV_spawnpoint

bool gB_roundStart
bool gB_onSpawn[MAXPLAYERS + 1]

enum WeaponType
{
	Weapon_Glock = 0,
	Weapon_USP,
	Weapon_P228,
	Weapon_Deagle,
	Weapon_Elite,
	Weapon_FiveSeven,
	Weapon_M3,
	Weapon_XM1014,
	Weapon_Galil,
	Weapon_AK47,
	Weapon_Scout,
	Weapon_SG552,
	Weapon_AWP,
	Weapon_G3SG1,
	Weapon_Famas,
	Weapon_M4A1,
	Weapon_Aug,
	Weapon_SG550,
	Weapon_Mac10,
	Weapon_TMP,
	Weapon_MP5Navy,
	Weapon_Ump45,
	Weapon_P90,
	Weapon_M249
}

//char weapon[2][WeaponType]
char gS_weapon[][] = {"Glock", "USP", "P228", "Deagle", "Elite", "FiveSeven", "M3", "XM1014", "Galil", 
					"AK47", "Scout", "SG552", "AWP", "G3SG1", "Famas", "M4A1", "Aug",
					"SG550", "Mac10", "TMP", "MP5Navy", "Ump45", "P90", "M249"}

public Plugin myinfo =
{
	name = "Deathmatch",
	author = "Nick Jurevics (Smesh, Smesh292)",
	description = "Make able to spawn instantly on the map in random place",
	version = "1.0",
	url = "http://www.sourcemod.net/"
}

public void OnPluginStart()
{
	HookEvent("round_start", round_start, EventHookMode_Post)
	HookEvent("player_death", playerdeath)
	AddCommandListener(joinclass, "joinclass")
	RegConsoleCmd("sm_guns", cmd_gunsmenu)
}

public void OnMapStart()
{
	GetCurrentMap(gS_map, 192)
	gKV_spawnpoint = CreateKeyValues("GlobalKey")
	char sFormat[256]
	Format(sFormat, 256, "cfg/sourcemod/deathmatch/%s.txt", gS_map)
	gKV_spawnpoint.ImportFromFile(sFormat)
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_SpawnPost, sdkspawnpost)
}

void sdkspawnpost(int client)
{
	if(IsFakeClient(client)
	{
		//for(int i = 0; 
		int random = GetRandomInt(0, 5)
		char sWeapon[32]
		Format(sWeapon, 32, "weapon_%s", gS_weapon[random])
		GivePlayerItem(client, sWeapon)
		random = GetRandomInt(6, 23)
		Format(sWeapon, 32, "weapon_%s", gS_weapon[random])
		GIvePlayerItem(client, sWeapon)
	}
	gB_onSpawn[client] = true
	GetPossition(client)
}

Action joinclass(int client, const char[] command, int argc)
{
	GetPossition(client)
}

void GetPossition(int client)
{
	//KeyValues kv_spawn = CreateKeyValues("GlobalKey") //https://github.com/alliedmodders/sourcemod/blob/master/plugins/testsuite/keyvalues.sp
	//char sFormat[64]
	//Format(sFormat, 64, "cfg/sourcemod/deathmatch/%s.txt", gS_map)
	//kv_spawn.ImportFromFile(sFormat)
	char sKVString[128]
	int randomint = GetRandomInt(1, 31)
	//PrintToServer("%i", randomint)
	char sRandomInt[32]
	IntToString(randomint, sRandomInt, 32)
	//kv_spawn.GetString(sRandomInt, sKVString, 128)
	gKV_spawnpoint.GetString(sRandomInt, sKVString, 128)
	//PrintToServer("1. %s", sKVString)
	char sString[7][128]
	ExplodeString(sKVString, " ", sString, 6, 128)
	//PrintToServer("2 origin. %s %s %s", sString[0], sString[1], sString[2])
	//PrintToServer("3 angles. %s %s %s", sString[3], sString[4], sString[5])
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
		gH_timer[client] = CreateTimer(1.0, respawnTimer, client)
	else
	{
		//CS_RespawnPlayer(client)
		//RequestFrame(frame, client)
		TeleportEntity(client, gF_origin[client], gF_angles[client], view_as<float>({0.0, 0.0, 0.0}))
		gB_onSpawn[client] = false
	}
}

/*void GetInstantPossition(int client)
{
	//KeyValues kv_spawn = CreateKeyValues("GlobalKey") //https://github.com/alliedmodders/sourcemod/blob/master/plugins/testsuite/keyvalues.sp
	//char sFormat[64]
	//Format(sFormat, 64, "cfg/sourcemod/deathmatch/%s.txt", gS_map)
	//kv_spawn.ImportFromFile(sFormat)
	char sKVString[128]
	int randomint = GetRandomInt(1, 31)
	//PrintToServer("%i", randomint)
	char sRandomInt[32]
	IntToString(randomint, sRandomInt, 32)
	//kv_spawn.GetString(sRandomInt, sKVString, 128)
	gKV_spawnpoint.GetString(sRandomInt, sKVString, 128)
	//PrintToServer("1. %s", sKVString)
	char sString[7][128]
	ExplodeString(sKVString, " ", sString, 6, 128)
	//PrintToServer("2 origin. %s %s %s", sString[0], sString[1], sString[2])
	//PrintToServer("3 angles. %s %s %s", sString[3], sString[4], sString[5])
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
	//if(!gB_roundStart)
		//gH_timer[client] = CreateTimer(1.0, respawnTimer, client)
	//else
	//{
		//CS_RespawnPlayer(client)
		//RequestFrame(frame, client)
	TeleportEntity(client, gF_origin[client], gF_angles[client], view_as<float>({0.0, 0.0, 0.0}))
		//gB_roundStart = false
	//}
}*/

public void OnEntityCreated(int entity, const char[] classname) //https://forums.alliedmods.net/showthread.php?t=247957
{
	//PrintToServer("OnEntityCreated succesfuly complete.")
	if(StrEqual(classname, "weapon_c4"))
		RemoveEntity(entity)
}

Action round_start(Event event, const char[] name, bool dontBroadcast)
{
	gB_roundStart = true
	PrintToServer("round start!")
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i)) //thanks to log for this idea . skin pref .sp
		{
			//GetPossition(i)
			if(gH_timer[i] != null)
				delete gH_timer[i] //https://wiki.alliedmods.net/Handles_(SourceMod_Scripting) code bottom
			//GetEntPropString(
		}
	}
}

Action playerdeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid")) //user ID who died
	//if(IsClientInGame(client) && gH_timer[client] != null)
		//KillTimer(gH_timer[client])
	GetPossition(client)
	//TeleportEntity(client, gF_origin, gF_angles, {0.0, 0.0, 0.0}) //https://github.com/alliedmodders/cssdm
	//int attacker = GetClientOfUserId(event.GetInt("attacker")) //user ID who killed
	//float vecRagdollVelocity[3]
	//float vecEyePosition[3]
	//GetClientEyePosition(attacker, vecEyePosition)
	//if(vecEyePosition[0] > 0.0)
	//GetEntPropVector(client, Prop_Send, "m_vecRagdollVelocity")
		//vec
	/*bool headshot = event.GetBool("headshot") //https://sm.alliedmods.net/new-api/events
	if(headshot)
	{
		int ragdoll = GetEntProp(client, Prop_Send, "m_hRagdoll")
		//if()
		vecRagdollVelocity[2] = 15000.0
		GetEntPropVector(ragdoll, Prop_Send, "m_vecRagdollVelocity", vecRagdollVelocity)
		PrintToServer("%f %f %f", vecRagdollVelocity[0], vecRagdollVelocity[1], vecRagdollVelocity[2])
		SetEntPropVector(ragdoll, Prop_Send, "m_vecRagdollVelocity", vecRagdollVelocity)
	}*/
}

Action respawnTimer(Handle timer, int client)
{
	if(IsClientInGame(client) && gH_timer[client] != null && timer != null)
	{
		CS_RespawnPlayer(client)
		//RequestFrame(frame, client)
		TeleportEntity(client, gF_origin[client], gF_angles[client], view_as<float>({0.0, 0.0, 0.0}))
		//https://forums.alliedmods.net/showthread.php?t=267445
		KillTimer(gH_timer[client])
		KillTimer(timer)
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
	
	//{
		
	//}
}

int menu_handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			//for(int i = 0; i <= 5; i++)
			{
				char sItem[32]
				menu.GetItem(param2, sItem, 32)
				PrintToServer("weapon name: %s", sItem)
				Format(sItem, 32, "weapon_%s", sItem)
				GivePlayerItem(param1, sItem) //https://www.sourcemod.net/new-api/sdktools_functions/GivePlayerItem
			}
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
			PrintToServer("weapon name: %s", sItem)
			Format(sItem, 32, "weapon_%s", sItem)
			GivePlayerItem(param1, sItem)
		}
	}
}

//void frame(int client)
//{
	//RequestFrame(frame2, client)
//}

//void frame2(int client)
//{
	//TeleportEntity(client, gF_origin[client], gF_angles[client], view_as<float>({0.0, 0.0, 0.0}))
//}

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

public Action OnPlayerRunCmd(int client)
{
	int other = Stuck(client)
	
	if(0 < other <= MaxClients && IsPlayerAlive(client))
	{
		if(GetEntProp(other, Prop_Data, "m_CollisionGroup") == 5)
		{
			SetEntProp(other, Prop_Data, "m_CollisionGroup", 2)
			PrintToServer("Stuck: %i %N", other, other)
		}
	}
	if(IsPlayerAlive(client) && other == -1)
	{
		if(GetEntProp(client, Prop_Data, "m_CollisionGroup") == 2)
		{
			SetEntProp(client, Prop_Data, "m_CollisionGroup", 5)
			PrintToServer("Unstuck.")
		}
	}
	SetEntProp(client, Prop_Send, "m_bInBuyZone", true)
}
