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
ConVar gCV_bot_quota

public Plugin myinfo =
{
	name = "Force bot refresh",
	author = "Nick Jurevics (Smesh, Smesh292)",
	description = "Automatical bot correction.",
	version = "1.0",
	url = "http://www.sourcemod.net/"
}

public void OnPluginStart()
{
	CreateTimer(2.0, timer_refresh, _, TIMER_REPEAT)
	gCV_bot_quota = CreateConVar("sm_bot_quota", "10", "Similar to bot_quota and bot_quota_mode fill.")
	AutoExecConfig(true)
	SetConVarFlags(FindConVar("bot_quota"), GetConVarFlags(FindConVar("bot_quota")) &~ FCVAR_NOTIFY) //https://hlmod.ru/threads/kak-ubrat-otobrazhenie-izmenenija-peremennyx-servera.5317/#post-38223
}

public void OnPluginEnd()
{
	SetConVarFlags(FindConVar("bot_quota"), GetConVarFlags(FindConVar("bot_quota")) | FCVAR_NOTIFY)
}

Action timer_refresh(Handle timer)
{
	int countT
	int countCT
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(GetClientTeam(i) == 2)
				countT++
			if(GetClientTeam(i) == 3)
				countCT++
		}
	}
	if(gCV_bot_quota.IntValue == countT + countCT)
	{
		if(countT > countCT)
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2)
				{
					ServerCommand("bot_kick %N", i)
					break
				}
			}
			ServerCommand("bot_add_ct")
		}
		else if(countT < countCT)
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 3)
				{
					ServerCommand("bot_kick %N", i)
					break
				}
			}
			ServerCommand("bot_add_t")
		}
	}
	else if(gCV_bot_quota.IntValue > countT + countCT)
	{
		if(countT > countCT)
			ServerCommand("bot_add_ct")
		else if(countT < countCT)
			ServerCommand("bot_add_t")
		else if(countT == countCT)
		{
			int random = GetRandomInt(2, 3)
			if(random == 2)
				ServerCommand("bot_add_t")
			else if(random == 2)
				ServerCommand("bot_add_ct")
		}
	}
	else if(gCV_bot_quota.IntValue < countT + countCT)
	{
		if(countT > countCT)
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2)
				{
					ServerCommand("bot_kick %N", i)
					break
				}
			}
		}
		else if(countT < countCT)
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 3)
				{
					ServerCommand("bot_kick %N", i)
					break
				}
			}
		}
		else if(countT == countCT)
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && IsFakeClient(i))
				{
					int random = GetRandomInt(2, 3)
					if(GetClientTeam(i) == random)
					{
						ServerCommand("bot_kick %N", i)
						break
					}
				}
			}
		}
	}
}
