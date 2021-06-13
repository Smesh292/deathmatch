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

float gF_origin[MAXPLAYERS + 1][3]
float gF_angles[MAXPLAYERS + 1][3]
char gS_map[192]

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
	//EventHook(
	//Event
	//Event
	HookEvent("player_death", playerdeath)
	//HookEvent("player_class", playerclass)
	AddCommandListener(joinclass, "joinclass")
	RegConsoleCmd("sm_testbuyzone", cmd_testbuyzone)
}

public void OnMapStart()
{
	GetCurrentMap(gS_map, 192)
}

Action joinclass(int client, const char[] command, int argc)
{
	GetPossition(client)
}

//Action playerclass(Event event, const char[] name, bool dontBroadcast)
//{
	//int client = GetClientOfUserId(event.GetInt("userid"))
	//GetPossition(client)
	//CS_RespawnPlayer(client)
	//TeleportEntity(client, gF_origin[client], gF_angles[client], view_as<float>({0.0, 0.0, 0.0}))
//}

void GetPossition(int client)
{
	KeyValues kv_spawn = CreateKeyValues("GlobalKey") //https://github.com/alliedmodders/sourcemod/blob/master/plugins/testsuite/keyvalues.sp
	//KeyValues kv_angles = CreateKeyValues("GlobalKey")
	//spawn.ImportFromFile("cfg/sourcemod/deathmatch/spawn.txt")
	//kv_origin.ImportFromFile("cfg/sourcemod/deathmatch/de_dust_origin.txt")
	//kv_angles.ImportFromFile("cfg/sourcemod/deathmatch/de_dust_angles.txt")
	char sFormat[64]
	Format(sFormat, 64, "cfg/sourcemod/deathmatch/%s.txt", gS_map)
	kv_spawn.ImportFromFile(sFormat)
	//PrintToServer("%s", spawn.ImportFromFile("cfg/sourcemod/deathmmatch/spawn.txt"))
	//char sKVStringOrigin[32]
	//char sKVStringAngles[32]
	char sKVString[64]
	//spawn.ImportFromString("")
	//int count = 1
	int randomint = GetRandomInt(1, 31)
	//int client = GetClientOfUserId(event.GetInt("userid"))
	//while((count = (spawn.GetString(count, sKVStringOrigin, 32))))
	//for(int i = 1; i <= randomint; i++)
	//{
		//if(i == randomint)
		//{
	//int count = 1
	//while((count = (kv_spawn.GetString(count, sKVStringOrigin, 32))))
	//while
	//char sCount[32] = '1'
	//PrintToServer("sCount: %s", sCount)
	//while()
	//{
		//Format(sCount, 32, "%s", count)
		//while((count = kv_spawn.GetNum(sCount)) > 0)
		//{
			//count++
			//Format(sCount, 32, "%s", count)
			//PrintToServer("%i", count)
		//}
	//}
	//int randomint = GetRandomInt(1, count)
	char sRandomInt[32]
	IntToString(randomint, sRandomInt, 32)
	//kv_spawn.GetString(sRandomInt, sKVStringOrigin, 32)
	//kv_spawn.GetString(sRandomInt, sKVStringAngles, 32)
	kv_spawn.GetString(sRandomInt, sKVString, 64)
	//PrintToServer("1. %s", sKVStringOrigin)
	//PrintToServer("1 angles: %s", sKVStringAngles)
	PrintToServer("1. %s", sKVString)
	//char sOrigin[4][64]
	//char sAngles[7][64]
	char sString[7][64]
	//ExplodeString(sKVStringOrigin, " ", sOrigin, 3, 64)
	//ExplodeString(sKVStringAngles, " ", sAngles, 6, 64)
	ExplodeString(sKVString, " ", sString, 6, 64)
	PrintToServer("2 origin. %s %s %s", sString[0], sString[1], sString[2])
	PrintToServer("3 angles. %s %s %s", sString[3], sString[4], sString[5])
	//PrintToServer("%i", kv_spawn.GetNum("GlobalKey"))
	//int keyid
	//while((keyid = kv_spawn.JumpToKeySymbol(keyid)) != -1)
		//PrintToServer("%i", keyid)
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
	CreateTimer(1.0, respawnTimer, client)
}

Action playerdeath(Event event, const char[] name, bool dontBroadcast)
{
	//if(IsClientInGame(client) && IsValidEntity(client))
	//{
		int client = GetClientOfUserId(event.GetInt("userid"))
		GetPossition(client)
		//CreateTimer(1.0, respawnTimer, client)
		//CS_RespawnPlayer(client)
		//TeleportEntity(client, gF_origin, gF_angles, {0.0, 0.0, 0.0})
	//}
	//continue
//}
	//}
	//spawn.GetString("1", sKVString, 32)
	//PrintToServer("%s", sKVString)
	//char sSpawn[32]
	//spawn.GetString(NULL_STRING, sSpawn, 32)
	//PrintToServer("%s", sSpawn)
	//FileType_Directory(
	//int client
	//int client = event.EventInt("userid")
	//SetEntProp
	//CS_RespawnPlayer(client)
	//TeleportEntity(client, gF_origin, gF_angles, {0.0, 0.0, 0.0}) //https://github.com/alliedmodders/cssdm
}

Action respawnTimer(Handle timer, int client)
{
	if(IsClientInGame(client))
	{
		CS_RespawnPlayer(client)
		TeleportEntity(client, gF_origin[client], gF_angles[client], view_as<float>({0.0, 0.0, 0.0}))
		//https://forums.alliedmods.net/showthread.php?t=267445
		//SetEntProp(client, Prop_Send, "m_iAccount", 9)
		SetEntProp(client, Prop_Send, "m_bInBuyZone", 1)
	//}
		//RequestFrame(frame, client)
	}
	return Plugin_Stop
}

Action cmd_testbuyzone(int client, int args)
{
	PrintToServer("%i", GetEntProp(client, Prop_Send, "m_iAccount"))
	SetEntProp(client, Prop_Send, "m_bInBuyZone", 1)
	//SetEntProp(client, Prop_Data, "m_bInBuyZone", 1)
	return Plugin_Handled
}

//void frame(int client)
//{
	//RequestFrame(frame2, client)
	//TeleportEntity(client, gF_origin[client], gF_angles[client], view_as<float>({0.0, 0.0, 0.0}))
//}

//void frame2(int client)
//{
	//RequestFrame(frame2, client)
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
	return entity != client
}

public Action OnPlayerRunCmd(int client)
{
	int other = Stuck(client)
	
	//if(0 < other <= MaxClients)
	if(IsValidEntity(other))
	if(0 < other <= MaxClients)
	{
		if(GetEntProp(client, Prop_Data, "m_iCollisionGroup") == 5)
		{
			SetEntProp(client, Prop_Data, "m_iCollisionGroup", 2)
			PrintToServer("Stuck: %i %N", other, other)
		}
	}
	if(other < 0)
	{
		if(GetEntProp(client, Prop_Data, "m_iCollisionGroup") == 2)
		{
			SetEntProp(client, Prop_Data, "m_iCollisionGroup", 5)
			PrintToServer("Unstuck.")
		}
	}
	//if(0 < other < MaxClients && !IsValidEntity(other))
	//{
		//PrintToServer("%i %N", other, other)
	//}
}
