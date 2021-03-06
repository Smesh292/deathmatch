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
	name = "Player history cvar",
	author = "Nick Jurevics (Smesh, Smesh292)",
	description = "Make able to disble sv_playerperfhistorycount.",
	version = "0.1",
	url = "http://www.sourcemod.net/"
}

public void OnPluginStart()
{
	ConVar cvHistory = FindConVar("sv_playerperfhistorycount")
	SetConVarBounds(cvHistory, ConVarBound_Lower, true, 0.0)
}
