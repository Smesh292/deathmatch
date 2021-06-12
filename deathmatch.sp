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

float gF_origin[3]
float gF_angles[3]

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
}

Action playerdeath(Event event, const char[] name, bool dontBroadcast)
{
	KeyValues spawn = CreateKeyValues("GlobalKey") //https://github.com/alliedmodders/sourcemod/blob/master/plugins/testsuite/keyvalues.sp
	//spawn.ImportFromFile("cfg/sourcemod/deathmatch/spawn.txt")
	spawn.ImportFromFile("cfg/sourcemod/deathmatch/de_dust_origin.txt")
	//PrintToServer("%s", spawn.ImportFromFile("cfg/sourcemod/deathmmatch/spawn.txt"))
	char sKVStringOrigin[32]
	char sKVStringAngles[32]
	//spawn.ImportFromString("")
	int count = 1
	int randomint = GetRandomInt(1, 31)
	int client = event.GetInt("userid")
	//while((count = (spawn.GetString(count, sKVStringOrigin, 32))))
	for(int i = 1; i <= randomint; i++)
	{
		if(i == randomint)
		{
			char sInt[32]
			IntToString(i, sInt, 32)
			spawn.GetString(sInt, sKVStringOrigin, 32)
			char sOrigin[32][3]
			ExplodeString(sKVStringOrigin, " ", sOrigin, 2, 32)
			float origin[3]
			origin[0] = StringToInt(sOrigin[0])
			gF_origin[0] = origin[0]
			origin[1] = StringToInt(sOrigin[1])
			gF_origin[1] = origin[1]
			origin[2] = StringToInt(sOrigin[2])
			gF_origin[2] = origin[2]
			CS_RespawnPlayer(client)
			TeleportEntity(client, gF_origin, gF_angles, {0.0, 0.0, 0.0})
			continue
		}
	}
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

public void OnMapStart()
{

}
