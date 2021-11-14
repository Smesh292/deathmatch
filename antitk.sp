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
#include <clientprefs>

public Plugin myinfo =
{
	name = "Anti tk",
	author = "Nick Jurevics (Smesh, Smesh292)",
	description = "Prevent team killing by punishment.",
	version = "0.1",
	url = "http://www.sourcemod.net/"
}

int gI_punishCount[MAXPLAYERS + 1]
int gI_punishTime[MAXPLAYERS + 1]
int gI_punishTries[MAXPLAYERS + 1]
Handle gH_punish[3]
Database gH_database

public void OnPluginStart()
{
	HookEvent("player_death", OnDeath)
	HookEvent("player_hurt", OnHurt)
	gH_punish[0] = RegClientCookie("punishCount", "store team kills", CookieAccess_Protected)
	gH_punish[1] = RegClientCookie("punishTime", "store time to reset punish", CookieAccess_Protected)
	gH_punish[2] = RegClientCookie("punishTries", "store tries to kill team mate", CookieAccess_Protected)
	Database.Connect(SQLConnect, "clientprefs")
}

public void OnMapStart()
{
	if(gH_database)
		gH_database.Query(SQLGetCookieID, "SELECT id FROM sm_cookies WHERE name = 'punishTries'")
}

void SQLConnect(Database db, const char[] error, any data)
{
	if(!db)
	{
		PrintToServer("Failed to connect to database")
		return
	}
	PrintToServer("Successfuly connected to database.") //https://hlmod.ru/threads/sourcepawn-urok-13-rabota-s-bazami-dannyx-mysql-sqlite.40011/
	gH_database = db
}

void SQLGetCookieID(Database db, DBResultSet results, const char[] error, any data)
{
	if(results.FetchRow())
	{
		int id = results.FetchInt(0)
		char sQuery[512]
		Format(sQuery, 512, "DELETE FROM sm_cookie_cache WHERE cookie_id = %i", id)
		gH_database.Query(SQLDeleteCookieCache, sQuery)
	}
}

void SQLDeleteCookieCache(Database db, DBResultSet results, const char[] error, any data)
{
}

public void OnClientCookiesCached(int client)
{
	char sValue[16]
	GetClientCookie(client, gH_punish[0], sValue, 16)
	gI_punishCount[client] = StringToInt(sValue)
	GetClientCookie(client, gH_punish[1], sValue, 16)
	gI_punishTime[client] = StringToInt(sValue)
	GetClientCookie(client, gH_punish[2], sValue, 16)
	gI_punishTries[client] = StringToInt(sValue)
}

Action OnDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid")) //user ID who died
	int attacker = GetClientOfUserId(event.GetInt("attacker")) //user ID who killed
	if(0 < attacker <= MaxClients && IsClientInGame(attacker) && !IsFakeClient(attacker))
	{
		if(client != attacker && GetClientTeam(client) == GetClientTeam(attacker))
		{
			if(gI_punishTime[attacker] <= GetTime())
			{
				SetClientCookie(attacker, gH_punish[1], "0")
				gI_punishCount[attacker] = 0
			}
			char sValue[16]
			if(!gI_punishTime[attacker])
			{
				IntToString(GetTime() + 3600, sValue, 16)
				SetClientCookie(attacker, gH_punish[1], sValue)
			}
			gI_punishCount[attacker]++
			IntToString(gI_punishCount[attacker], sValue, 16)
			SetClientCookie(attacker, gH_punish[0], sValue)
			if(gI_punishCount[attacker] == 3)
				KickClient(attacker, "Punishment for team killing")
			else if(gI_punishCount[attacker] == 5)
				BanClient(attacker, 5, BANFLAG_AUTO, "Punishment for team killing (5 minutes)", "Punishment for team killing (5 minutes)")
			else if(gI_punishCount[attacker] >= 7)
				BanClient(attacker, 15, BANFLAG_AUTO, "Punishment for team killing (15 minutes)", "Punishment for team killing (15 minutes)")
		}
	}
}

Action OnHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid")) //user ID who died
	int attacker = GetClientOfUserId(event.GetInt("attacker")) //user ID who killed
	if(0 < attacker <= MaxClients && IsClientInGame(attacker) && !IsFakeClient(attacker))
	{
		if(client != attacker && GetClientTeam(client) == GetClientTeam(attacker))
		{
			int damaged = event.GetInt("dmg_health")
			if(damaged < 30)
				gI_punishTries[attacker]++
			else if(70 > damaged >= 30)
				gI_punishTries[attacker] += 2
			else if(damaged >= 70)
				gI_punishTries[attacker] += 3
			char sValue[16]
			IntToString(gI_punishTries[attacker], sValue, 16)
			SetClientCookie(attacker, gH_punish[2], sValue)
			if(gI_punishTries[attacker] == 30)
				KickClient(attacker, "Punishment for team killing attempt")
			else if(gI_punishTries[attacker] == 50)
				BanClient(attacker, 5, BANFLAG_AUTO, "Punishment for team killing attempt (5 minutes)", "Punishment for team killing attempt (5 minutes)")
			else if(gI_punishTries[attacker] >= 70)
				BanClient(attacker, 15, BANFLAG_AUTO, "Punishment for team killing attempt (15 minutes)", "Punishment for team killing attempt (15 minutes)")
		}
	}
}
