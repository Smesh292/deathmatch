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

public Plugin myinfo =
{
	name = "Anti tk",
	author = "Nick Jurevics (Smesh, Smesh292)",
	description = "Prevent team killing by punishment.",
	version = "0.1",
	url = "http://www.sourcemod.net/"
}

int gI_punishCount[MAXPLAYERS + 1]

public void OnPluginStart()
{
	HookEvent("player_death", OnDeath)
}

public void OnClientPutInServer(int client)
{
	gI_punishCount[client] = 0
}

Action OnDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid")) //user ID who died
	int attacker = GetClientOfUserId(event.GetInt("attacker")) //user ID who killed
	if(0 < attacker <= MaxClients && IsClientInGame(attacker) && !IsFakeClient(attacker))
	{
		if(GetClientTeam(client) == GetClientTeam(attacker))
		{
			gI_punishCount[attacker]++
			CreateTimer(120.0, timer_punish, attacker, TIMER_FLAG_NO_MAPCHANGE)
			if(gI_punishCount[attacker] == 3)
				KickClient(attacker, "Punishment for team killing")
		}
	}
}

Action timer_punish(Handle timer, int client)
{
	if(IsClientInGame(client))
		gI_punishCount[client]--
}
