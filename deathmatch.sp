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
	HookEvent("player_death", playerdeath)
	AddCommandListener(joinclass, "joinclass")
}

public void OnMapStart()
{
	GetCurrentMap(gS_map, 192)
}

Action joinclass(int client, const char[] command, int argc)
{
	GetPossition(client)
}

void GetPossition(int client)
{
	KeyValues kv_spawn = CreateKeyValues("GlobalKey") //https://github.com/alliedmodders/sourcemod/blob/master/plugins/testsuite/keyvalues.sp
	char sFormat[64]
	Format(sFormat, 64, "cfg/sourcemod/deathmatch/%s.txt", gS_map)
	kv_spawn.ImportFromFile(sFormat)
	char sKVString[64]
	int randomint = GetRandomInt(1, 31)
	PrintToServer("%i", randomint)
	char sRandomInt[32]
	IntToString(randomint, sRandomInt, 32)
	kv_spawn.GetString(sRandomInt, sKVString, 64)
	//PrintToServer("1. %s", sKVString)
	char sString[7][64]
	ExplodeString(sKVString, " ", sString, 6, 64)
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
	CreateTimer(1.0, respawnTimer, client)
}

Action playerdeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"))
	GetPossition(client)
	//TeleportEntity(client, gF_origin, gF_angles, {0.0, 0.0, 0.0}) //https://github.com/alliedmodders/cssdm
}

Action respawnTimer(Handle timer, int client)
{
	if(IsClientInGame(client))
	{
		CS_RespawnPlayer(client)
		//RequestFrame(frame, client)
		TeleportEntity(client, gF_origin[client], gF_angles[client], view_as<float>({0.0, 0.0, 0.0}))
		//https://forums.alliedmods.net/showthread.php?t=267445
	}
	return Plugin_Stop
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
