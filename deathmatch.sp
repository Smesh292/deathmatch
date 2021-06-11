public void OnMapStart()
{
	KeyValues spawn
	spawn.FileToKeyValues("cfg/sourcemod/deathmmatch/spawn.txt")
	char sSpawn[32]
	spawn.KvGetString(NULL_STRING, sSpawn, 32)
	PrintToServer("%s", sSpawn)
	//FileType_Directory(
}
