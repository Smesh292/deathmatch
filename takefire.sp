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
#define semicolon 1
#define newdelcs required

#include <sdkhooks>

ConVar g_showMsg;

public Plugin myinfo =
{
	name = "Visual damage",
	author = "Nick Jurevics (Smesh, Smesh292)",
	description = "Allow to take only visual damage.",
	version = "1.0",
	url = "http://www.sourcemod.net/"
}

public void OnPluginStart()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}

	g_showMsg = CreateConVar("sm_takefire_msg", "1", "Do chat message, if teamattack.", 0, false, 0.0, true, 1.0);
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, SDKOnTakeDamage);
}

stock Action SDKOnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
    if(0 < victim <= MaxClients && 0 < attacker <= MaxClients && GetClientTeam(victim) == GetClientTeam(attacker))
    {
		damage = 0.0;

		return GetConVarBool(g_showMsg) ? Plugin_Changed : Plugin_Handled;
    }

    return Plugin_Continue;
}
