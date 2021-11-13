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
float gF_flashDuration[MAXPLAYERS + 1]

public Plugin myinfo =
{
	name = "Radar Hide",
	author = "Smesh(Nick Yurevich)",
	description = "Hide radar for alive player.",
	version = "0.1",
	url = "http://www.sourcemod.net/"
}

public void OnPluginStart()
{
	HookEvent("player_spawn", OnSpawn, EventHookMode_Post)
	HookEvent("player_blind", OnBlind, EventHookMode_Post)
}

Action OnSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"))
	gF_flashDuration[client] = GetGameTime()
	RadarHide(client)
}

Action OnBlind(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"))
	gF_flashDuration[client] = GetGameTime() + GetEntPropFloat(client, Prop_Send, "m_flFlashDuration")
	CreateTimer(GetEntPropFloat(client, Prop_Send, "m_flFlashDuration") - 0.1, timer_hide, client, TIMER_FLAG_NO_MAPCHANGE)
}

Action timer_hide(Handle timer, int client)
{
	RadarHide(client)
}

void RadarHide(int client)
{
	if(IsClientInGame(client) && !IsFakeClient(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3))
	{
		if(gF_flashDuration[client] - 0.1 <= GetGameTime())
		{
			SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 3600.0) //https://forums.alliedmods.net/showpost.php?p=2464729&postcount=3
			SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.5)
		}
	}
}
