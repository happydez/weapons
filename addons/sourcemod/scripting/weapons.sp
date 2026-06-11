#pragma semicolon 1
#pragma newdecls required

#include <cstrike>
#include <sdkhooks>
#include <sdktools>
#include <clientprefs>

#include <convar_class>

#include <printer>
#include <flags-core>

#define WEAPONS_TAG     "[Weapons]"
#define WEAPONS_PLUGIN  "weapons"

#define PBMAX 4

printer_colors_t gS_ChatStrings;

Convar gCV_AllowNades = null;

Cookie gH_AntiflashCookie = null;
Cookie gH_PaintballCookie = null;
Cookie gH_SparksCookie = null;
Cookie gH_ElectroCookie = null;
Cookie gH_TracersCookie = null;

bool gB_AntiFlash[MAXPLAYERS+1];
bool gB_Paintball[MAXPLAYERS+1];
bool gB_Sparks[MAXPLAYERS+1];
bool gB_Electro[MAXPLAYERS+1];
bool gB_Tracers[MAXPLAYERS+1];

int gI_LastWeaponTick[MAXPLAYERS+1];
int gI_PaintballPIndxs[PBMAX];

int gI_TracersSprite;
int gI_SpriteLightning;

char gS_PrefixWeapons[][] = {
    "weapon_ak47",
    "weapon_aug",
    "weapon_awp",
    "weapon_deagle",
    "weapon_elite",
    "weapon_famas",
    "weapon_fiveseven",
    "weapon_galil",
    "weapon_g3sg1",
    "weapon_glock",
    "weapon_knife", 
    "weapon_mp5navy",
    "weapon_m249",
    "weapon_m3",
    "weapon_m4a1",
    "weapon_mac10",
    "weapon_p228",
    "weapon_p90",
    "weapon_sg550",
    "weapon_sg552",
    "weapon_scout",
    "weapon_tmp",
    "weapon_ump45",
    "weapon_usp",
    "weapon_flashbang",
    "weapon_smokegrenade",
    "weapon_hegrenade"
};

char gS_Weapons[][] = {
    "ak47",
    "aug",
    "awp",
    "deagle",
    "elite",
    "famas",
    "fiveseven",
    "galil",
    "g3sg1",
    "glock",
    "knife", 
    "mp5navy",
    "m249",
    "m3",
    "m4a1",
    "mac10",
    "p228",
    "p90",
    "sg550",
    "sg552",
    "scout",
    "tmp",
    "ump45",
    "usp",
    "flashbang",
    "smokegrenade",
    "hegrenade"
};

int gI_Slots[] = {0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 3, 3, 3 };

int gI_WeaponsAmount = 0;

int gI_Colors[][3] = {
    {224,  49,  49},   // #E03131
    {230, 126,  34},   // #E67E22
    {255, 214,  10},   // #FFD60A
    {46,  204, 113},   // #2ECC71
    {0,   230, 118},   // #00E676
    {81,   43, 212},   // #512BD4
    {139,   43, 255},  // #8B2BFF
    {0,   191, 255},   // #00BFFF
    {255,  99,  71},   // #FF6347
    {255,  51, 255},   // #FF33FF
    {211,  84,   0}    // #D35400
};

public Plugin myinfo =
{
	name		= "Weapons",
	author		= "happydez",
	description	= "Weapons",
	version		= "1.0.0",
	url			= "https://github.com/happydez"
};

public void OnPluginStart()
{
    // if you're using this plugin with bhoptimer, it's better to set cvar shavit_misc_weaponcommands to 1
    gCV_AllowNades = new Convar("weapons_allow_nades", "1", "Allow everyone to use grenades. When 0, access is checked against flags-core (flags f/s/h for plugin 'weapons').", 0, true, 0.0, true, 1.0);
    Convar.AutoExecConfig("weapons");

    gH_AntiflashCookie = new Cookie("weapons-antiflash", "weapons-antiflash", CookieAccess_Protected);
    gH_PaintballCookie = new Cookie("weapons-paintball", "weapons-paintball", CookieAccess_Protected);
    gH_SparksCookie = new Cookie("weapons-sparks", "weapons-sparks", CookieAccess_Protected);
    gH_ElectroCookie = new Cookie("weapons-electro", "weapons-electro", CookieAccess_Protected);
    gH_TracersCookie = new Cookie("weapons-tracers", "weapons-tracers", CookieAccess_Protected);

    HookEventEx("weapon_fire", OnWeaponFire_Post, EventHookMode_Post);
    HookEventEx("weapon_fire_on_empty", OnWeaponFire_Post, EventHookMode_Post);
    HookEvent("player_blind", OnFlashPlayer_Pre, EventHookMode_Pre);
    HookEvent("smokegrenade_detonate", OnSmokegrenadeDetonate_Post, EventHookMode_Post);
    HookEvent("bullet_impact", OnBulletImpact_Post, EventHookMode_Post);

    RegConsoleCmd("sm_antiflash", Command_AntiFlash, "enable anti-flash");
    RegConsoleCmd("sm_paintball", Command_Paintball, "enable paintball");
    RegConsoleCmd("sm_sparks", Command_Sparks, "enable sparks");
    RegConsoleCmd("sm_electroeffects", Command_ElectroEffects, "enable electro effects");
    RegConsoleCmd("sm_tracers", Command_Tracers, "enable tracers effects");

	RegConsoleCmd("sm_gun", Command_WeaponsList, "");
    RegConsoleCmd("sm_guns", Command_WeaponsList, "");
    RegConsoleCmd("sm_weapon", Command_WeaponsList, "");
    RegConsoleCmd("sm_weapons", Command_WeaponsList, "");

    gI_WeaponsAmount = sizeof(gS_Weapons);

    RegConsoleCmd("sm_ak47", Command_ak47, "");
    RegConsoleCmd("sm_aug", Command_aug, "");
    RegConsoleCmd("sm_awp", Command_awp, "");
    RegConsoleCmd("sm_deagle", Command_deagle, "");
    RegConsoleCmd("sm_elite", Command_elite, "");
    RegConsoleCmd("sm_famas", Command_famas, "");
    RegConsoleCmd("sm_fiveseven", Command_fiveseven, "");
    RegConsoleCmd("sm_galil", Command_galil, "");
    RegConsoleCmd("sm_g3sg1", Command_g3sg1, "");
    RegConsoleCmd("sm_glock", Command_glock, "");
    RegConsoleCmd("sm_knife", Command_knife, "");
    RegConsoleCmd("sm_mp5navy", Command_mp5navy, "");
    RegConsoleCmd("sm_m249", Command_m249, "");
    RegConsoleCmd("sm_m3", Command_m3, "");
    RegConsoleCmd("sm_m4a1", Command_m4a1, "");
    RegConsoleCmd("sm_mac10", Command_mac10, "");
    RegConsoleCmd("sm_p228", Command_p228, "");
    RegConsoleCmd("sm_p90", Command_p90, "");
    RegConsoleCmd("sm_sg550", Command_sg550, "");
    RegConsoleCmd("sm_sg552", Command_sg552, "");
    RegConsoleCmd("sm_scout", Command_scout, "");
    RegConsoleCmd("sm_tmp", Command_tmp, "");
    RegConsoleCmd("sm_ump45", Command_ump45, "");
    RegConsoleCmd("sm_usp", Command_usp, "");
    
    RegConsoleCmd("sm_flashbang", Command_flashbang, "");
    RegConsoleCmd("sm_smokegrenade", Command_smokegrenade, "");
    RegConsoleCmd("sm_hegrenade", Command_hegrenade, "");

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && AreClientCookiesCached(i))
        {
            OnClientCookiesCached(i);
        }
    }
}

public void OnMapStart()
{
    AddFileToDownloadsTable("materials/decals/concretes/shot1_paint.vmt");
    AddFileToDownloadsTable("materials/decals/concretes/shot2_paint.vmt");
    AddFileToDownloadsTable("materials/decals/concretes/shot3_paint.vmt");
    AddFileToDownloadsTable("materials/decals/concretes/shot4_paint.vmt");

    gI_PaintballPIndxs[0] = PrecacheDecal("decals/concretes/shot1_paint.vmt", true);
    gI_PaintballPIndxs[1] = PrecacheDecal("decals/concretes/shot2_paint.vmt", true);
    gI_PaintballPIndxs[2] = PrecacheDecal("decals/concretes/shot3_paint.vmt", true);
    gI_PaintballPIndxs[3] = PrecacheDecal("decals/concretes/shot4_paint.vmt", true);

    AddFileToDownloadsTable("materials/decals/concretes/shot1_paint.vtf");
    AddFileToDownloadsTable("materials/decals/concretes/shot1norm_paint.vtf");
    AddFileToDownloadsTable("materials/decals/concretes/shot2_paint.vtf");
    AddFileToDownloadsTable("materials/decals/concretes/shot2norm_paint.vtf");
    AddFileToDownloadsTable("materials/decals/concretes/shot3_paint.vtf");
    AddFileToDownloadsTable("materials/decals/concretes/shot3norm_paint.vtf");
    AddFileToDownloadsTable("materials/decals/concretes/shot4_paint.vtf");
    AddFileToDownloadsTable("materials/decals/concretes/shot4norm_paint.vtf");

    gI_TracersSprite = PrecacheModel("sprites/laser.vmt", true);
    gI_SpriteLightning = PrecacheModel("sprites/lgtning.vmt", true);
}

public void PP_OnColorsLoaded()
{
    PP_GetColors(gS_ChatStrings);
}

public void OnAllPluginsLoaded()
{
    Flags_RegisterPlugin(WEAPONS_PLUGIN, "Weapons", "fsh", false, "", 0);
}

// Grenade access: the open convar lets everyone use them, otherwise the matching
// flags-core flag is required (f = flashbang, s = smoke, h = he).
bool CanUseNade(int client, const char[] flag)
{
    if (gCV_AllowNades.BoolValue)
    {
        return true;
    }

    return Flags_HasForClient(client, WEAPONS_PLUGIN, flag);
}

public void OnClientCookiesCached(int client)
{
    char cookie[2];

    gH_AntiflashCookie.Get(client, cookie, 2);
    if (cookie[0] == '\0')
    {
        gB_AntiFlash[client] = true;
        gH_AntiflashCookie.Set(client, "1");
    }
    else
    {
        gB_AntiFlash[client] = (StringToInt(cookie) == 1);
    }

    gH_PaintballCookie.Get(client, cookie, 2);
    if (cookie[0] == '\0')
    {
        gB_Paintball[client] = true;
        gH_PaintballCookie.Set(client, "1");
    }
    else
    {
        gB_Paintball[client] = (StringToInt(cookie) == 1);
    }

    gH_SparksCookie.Get(client, cookie, 2);
    if (cookie[0] == '\0')
    {
        gB_Sparks[client] = true;
        gH_SparksCookie.Set(client, "1");
    }
    else
    {
        gB_Sparks[client] = (StringToInt(cookie) == 1);
    }

    gH_ElectroCookie.Get(client, cookie, 2);
    if (cookie[0] == '\0')
    {
        gB_Electro[client] = true;
        gH_ElectroCookie.Set(client, "1");
    }
    else
    {
        gB_Electro[client] = (StringToInt(cookie) == 1);
    }

    gH_TracersCookie.Get(client, cookie, 2);
    if (cookie[0] == '\0')
    {
        gB_Tracers[client] = true;
        gH_TracersCookie.Set(client, "1");
    }
    else
    {
        gB_Tracers[client] = (StringToInt(cookie) == 1);
    }
}

public Action Command_AntiFlash(int client, int args)
{
    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }

    gB_AntiFlash[client] = !gB_AntiFlash[client];
    gH_AntiflashCookie.Set(client, gB_AntiFlash[client] ? "1" : "0");

    if (gB_AntiFlash[client])
    {
        PP_PrintToChat(client, "%s%s%s Anti-flash is now %senabled", gS_ChatStrings.sPrefix, WEAPONS_TAG, gS_ChatStrings.sText, gS_ChatStrings.sVariable2);
    }
    else
    {
        PP_PrintToChat(client, "%s%s%s Anti-flash is now %sdisabled", gS_ChatStrings.sPrefix, WEAPONS_TAG, gS_ChatStrings.sText, gS_ChatStrings.sWarning);
    }

    return Plugin_Handled;
}

public Action Command_Paintball(int client, int args)
{
    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }

    gB_Paintball[client] = !gB_Paintball[client];
    gH_PaintballCookie.Set(client, gB_Paintball[client] ? "1" : "0");

    if (gB_Paintball[client])
    {
        PP_PrintToChat(client, "%s%s%s Paintball is now %senabled", gS_ChatStrings.sPrefix, WEAPONS_TAG, gS_ChatStrings.sText, gS_ChatStrings.sVariable2);
    }
    else
    {
        PP_PrintToChat(client, "%s%s%s Paintball is now %sdisabled", gS_ChatStrings.sPrefix, WEAPONS_TAG, gS_ChatStrings.sText, gS_ChatStrings.sWarning);
    }

    return Plugin_Handled;
}

public Action Command_Sparks(int client, int args)
{
    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }

    gB_Sparks[client] = !gB_Sparks[client];
    gH_SparksCookie.Set(client, gB_Sparks[client] ? "1" : "0");

    if (gB_Sparks[client])
    {
        PP_PrintToChat(client, "%s%s%s Sparks is now %senabled", gS_ChatStrings.sPrefix, WEAPONS_TAG, gS_ChatStrings.sText, gS_ChatStrings.sVariable2);
    }
    else
    {
        PP_PrintToChat(client, "%s%s%s Sparks is now %sdisabled", gS_ChatStrings.sPrefix, WEAPONS_TAG, gS_ChatStrings.sText, gS_ChatStrings.sWarning);
    }

    return Plugin_Handled;
}

public Action Command_ElectroEffects(int client, int args)
{
    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }

    gB_Electro[client] = !gB_Electro[client];
    gH_ElectroCookie.Set(client, gB_Electro[client] ? "1" : "0");

    if (gB_Electro[client])
    {
        PP_PrintToChat(client, "%s%s%s Electro effects is now %senabled", gS_ChatStrings.sPrefix, WEAPONS_TAG, gS_ChatStrings.sText, gS_ChatStrings.sVariable2);
    }
    else
    {
        PP_PrintToChat(client, "%s%s%s Electro effects is now %sdisabled", gS_ChatStrings.sPrefix, WEAPONS_TAG, gS_ChatStrings.sText, gS_ChatStrings.sWarning);
    }

    return Plugin_Handled;
}

public Action Command_Tracers(int client, int args)
{
    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }

    gB_Tracers[client] = !gB_Tracers[client];
    gH_TracersCookie.Set(client, gB_Tracers[client] ? "1" : "0");

    if (gB_Tracers[client])
    {
        PP_PrintToChat(client, "%s%s%s Tracers effects is now %senabled", gS_ChatStrings.sPrefix, WEAPONS_TAG, gS_ChatStrings.sText, gS_ChatStrings.sVariable2);
    }
    else
    {
        PP_PrintToChat(client, "%s%s%s Tracers effects is now %sdisabled", gS_ChatStrings.sPrefix, WEAPONS_TAG, gS_ChatStrings.sText, gS_ChatStrings.sWarning);
    }

    return Plugin_Handled;
}

public void OnWeaponFire_Post(Event event, const char[] name, bool dontBroadcast)
{
    char weapon[64];
    event.GetString("weapon", weapon, sizeof(weapon));

    if (StrEqual(weapon, "flashbang") || StrEqual(weapon, "smokegrenade") || StrEqual(weapon, "hegrenade"))
    {
        return;
    }

    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client <= 0 || !IsClientInGame(client))
    {
        return;
    }

    int weaponEnt = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

    if (weaponEnt <= 0 || !IsValidEntity(weaponEnt))
    {
        return;
    }

    SetMaxWeaponAmmo(client, weaponEnt, true);
}

public Action OnFlashPlayer_Pre(Event event, const char[] name, bool dontBroadcast)
{
    int client =  GetClientOfUserId(event.GetInt("userid"));
    if(!client || !IsClientInGame(client) || !gB_AntiFlash[client])
    {
        return Plugin_Continue;
    }

    SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.5);

	return Plugin_Continue;
}

public Action OnBulletImpact_Post(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
    {
        return Plugin_Handled;
    }

    float fPos[3];
    fPos[0] = event.GetFloat("x");
    fPos[1] = event.GetFloat("y");
    fPos[2] = event.GetFloat("z");

    if (gB_Sparks[client])
    {
        TE_SetupSparks(fPos, {0.0, 0.0, 0.0}, 5000, 1000);
        TE_SendToClient(client);
    }

    if (gB_Paintball[client])
    {
        int pri = gI_PaintballPIndxs[GetRandomInt(0, PBMAX - 1)];
        TE_SetupWorldDecal(fPos, pri);
        TE_SendToClient(client);
    }

    if (gB_Electro[client])
    {
        ElectroWaveAt(client, fPos);
    }

    if (gB_Tracers[client])
    {
        float bulletOrigin[3], newBulletOrigin[3];
        GetClientEyePosition(client, bulletOrigin);

        float distance = GetVectorDistance(bulletOrigin, fPos), percentage = 0.4 / (distance / 100);

        newBulletOrigin[0] = bulletOrigin[0] + ((fPos[0] - bulletOrigin[0]) * percentage);
        newBulletOrigin[1] = bulletOrigin[1] + ((fPos[1] - bulletOrigin[1]) * percentage) - 0.08;
        newBulletOrigin[2] = bulletOrigin[2] + ((fPos[2] - bulletOrigin[2]) * percentage);

        int color[4];
        int colorIndx = GetRandomInt(0, sizeof(gI_Colors) - 1);
        color[0] = gI_Colors[colorIndx][0];
        color[1] = gI_Colors[colorIndx][1];
        color[2] = gI_Colors[colorIndx][2];
        color[3] = 255;

        TE_SetupBeamPoints(newBulletOrigin, fPos, gI_TracersSprite, 0, 0, 0, 0.2, 2.0, 2.0, 1, 0.0, color, 0);
        TE_SendToClient(client);
    }

    return Plugin_Handled;
}

public Action OnSmokegrenadeDetonate_Post(Event event, const char[] name, bool dontBroadcast)
{
    float pos[3];
    pos[0] = event.GetFloat("x");
    pos[1] = event.GetFloat("y");
    pos[2] = event.GetFloat("z");

    int smokeEnt = -1;
    bool found = false;

    float org[3];
    while ((smokeEnt = FindEntityByClassname(smokeEnt, "env_particlesmokegrenade")) != -1)
    {
        GetEntPropVector(smokeEnt, Prop_Send, "m_vecOrigin", org);

        float dx = org[0] - pos[0];
        float dy = org[1] - pos[1];
        float dz = org[2] - pos[2];
        float distSq = dx*dx + dy*dy + dz*dz;

        if (distSq <= 4.0)
        {
            found = true;
            break;
        }
    }

    if (!found)
    {
        return Plugin_Continue;
    }

    int light = CreateEntityByName("light_dynamic");
    if (light == -1)
    {
        return Plugin_Continue;
    }

    int idx = GetRandomInt(0, sizeof(gI_Colors) - 1);
    char colorBuf[32];
    Format(colorBuf, sizeof(colorBuf), "%d %d %d 255", gI_Colors[idx][0], gI_Colors[idx][1], gI_Colors[idx][2]);

    DispatchKeyValue(light, "_light", colorBuf);

    char nameBuf[32];
    Format(nameBuf, sizeof(nameBuf), "smokelight_%d", light);
    DispatchKeyValue(light, "targetname", nameBuf);

    char originBuf[64];
    Format(originBuf, sizeof(originBuf), "%f %f %f", pos[0], pos[1], pos[2]);
    DispatchKeyValue(light, "origin", originBuf);

    DispatchKeyValue(light, "pitch", "-90");
    DispatchKeyValue(light, "distance", "256");
    DispatchKeyValue(light, "spotlight_radius", "96");
    DispatchKeyValue(light, "brightness", "3");
    DispatchKeyValue(light, "style", "6");
    DispatchKeyValue(light, "spawnflags", "1");

    DispatchSpawn(light);
    AcceptEntityInput(light, "DisableShadow");
    AcceptEntityInput(light, "TurnOn");

    if (IsValidEntity(smokeEnt))
    {
        char parentName[32];
        Format(parentName, sizeof(parentName), "rm_smoke_%d", smokeEnt);
        DispatchKeyValue(smokeEnt, "targetname", parentName);
        SetVariantString(parentName);
        AcceptEntityInput(light, "SetParent");
    }

    CreateTimer(20.0, Timer_DeleteEntRef, EntIndexToEntRef(light), TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Continue;
}

public Action Timer_DeleteEntRef(Handle timer, any entRef)
{
    int ent = EntRefToEntIndex(entRef);
    if (ent != INVALID_ENT_REFERENCE && ent > 0 && IsValidEntity(ent))
    {
        AcceptEntityInput(ent, "Kill");
    }

    return Plugin_Stop;
}

void SetMaxWeaponAmmo(int client, int weapon, bool setClip1)
{
	int iAmmo = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");

	if (iAmmo < 0)
	{
		return;
	}

	SetEntProp(client, Prop_Send, "m_iAmmo", 255, 4, iAmmo);

	if (setClip1)
	{
		int amount = GetEntProp(weapon, Prop_Send, "m_iClip1") + 1;

		if (HasEntProp(weapon, Prop_Send, "m_bBurstMode") && GetEntProp(weapon, Prop_Send, "m_bBurstMode"))
		{
			amount += 2;
		}

		SetEntProp(weapon, Prop_Data, "m_iClip1", amount);
	}
}

public void OnClientPutInServer(int client)
{
    gI_LastWeaponTick[client] = 0;

    if (AreClientCookiesCached(client))
    {
        OnClientCookiesCached(client);
        return;
    }

    gB_AntiFlash[client] = false;
    gB_Paintball[client] = false;
    gB_Sparks[client] = false;
    gB_Electro[client] = false;
    gB_Tracers[client] = false;
}

public Action Command_ak47(int client, int args)
{
    if (IsValidClient(client))
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }

        gI_LastWeaponTick[client] = GetGameTickCount();

        RemoveClientSlot(client, gI_Slots[0]);
        GivePlayerItem(client, gS_PrefixWeapons[0]);
        FakeClientCommand(client, "use %s", gS_PrefixWeapons[0]);
    }

    return Plugin_Handled;
}

public Action Command_aug(int client, int args)
{
    if (IsValidClient(client))
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }

        gI_LastWeaponTick[client] = GetGameTickCount();

        RemoveClientSlot(client, gI_Slots[1]);
        GivePlayerItem(client, gS_PrefixWeapons[1]);
        FakeClientCommand(client, "use %s", gS_PrefixWeapons[1]);
    }
    
    return Plugin_Handled;
}

public Action Command_awp(int client, int args)
{
    if (IsValidClient(client))
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }

        gI_LastWeaponTick[client] = GetGameTickCount();

        RemoveClientSlot(client, gI_Slots[2]);
        GivePlayerItem(client, gS_PrefixWeapons[2]);
        FakeClientCommand(client, "use %s", gS_PrefixWeapons[2]);
    }

    return Plugin_Handled;
}

public Action Command_deagle(int client, int args)
{
    if (IsValidClient(client))
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }

        gI_LastWeaponTick[client] = GetGameTickCount();

        RemoveClientSlot(client, gI_Slots[3]);
        GivePlayerItem(client, gS_PrefixWeapons[3]);
        FakeClientCommand(client, "use %s", gS_PrefixWeapons[3]);
    }

    return Plugin_Handled;
}

public Action Command_elite(int client, int args)
{
    if (IsValidClient(client))
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }

        gI_LastWeaponTick[client] = GetGameTickCount();

        RemoveClientSlot(client, gI_Slots[4]);
        GivePlayerItem(client, gS_PrefixWeapons[4]);
        FakeClientCommand(client, "use %s", gS_PrefixWeapons[4]);
    }

    return Plugin_Handled;
}

public Action Command_famas(int client, int args)
{
    if (IsValidClient(client))
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }

        gI_LastWeaponTick[client] = GetGameTickCount();

        RemoveClientSlot(client, gI_Slots[5]);
        GivePlayerItem(client, gS_PrefixWeapons[5]);
        FakeClientCommand(client, "use %s", gS_PrefixWeapons[5]);
    }

    return Plugin_Handled;
}

public Action Command_fiveseven(int client, int args)
{
    if (IsValidClient(client))
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }

        gI_LastWeaponTick[client] = GetGameTickCount();

        RemoveClientSlot(client, gI_Slots[6]);
        GivePlayerItem(client, gS_PrefixWeapons[6]);
        FakeClientCommand(client, "use %s", gS_PrefixWeapons[6]);
    }

    return Plugin_Handled;
}

public Action Command_galil(int client, int args)
{
    if (IsValidClient(client))
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }

        gI_LastWeaponTick[client] = GetGameTickCount();

        RemoveClientSlot(client, gI_Slots[7]);
        GivePlayerItem(client, gS_PrefixWeapons[7]);
        FakeClientCommand(client, "use %s", gS_PrefixWeapons[7]);
    }

    return Plugin_Handled;
}

public Action Command_g3sg1(int client, int args)
{
    if (IsValidClient(client))
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }

        gI_LastWeaponTick[client] = GetGameTickCount();

        RemoveClientSlot(client, gI_Slots[8]);
        GivePlayerItem(client, gS_PrefixWeapons[8]);
        FakeClientCommand(client, "use %s", gS_PrefixWeapons[8]);
    }

    return Plugin_Handled;
}

public Action Command_glock(int client, int args)
{
    if (IsValidClient(client))
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }

        gI_LastWeaponTick[client] = GetGameTickCount();

        RemoveClientSlot(client, gI_Slots[9]);
        GivePlayerItem(client, gS_PrefixWeapons[9]);
        FakeClientCommand(client, "use %s", gS_PrefixWeapons[9]);
    }

    return Plugin_Handled;
}

public Action Command_knife(int client, int args)
{
    if (IsValidClient(client))
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }

        gI_LastWeaponTick[client] = GetGameTickCount();

        RemoveClientSlot(client, gI_Slots[10]);
        GivePlayerItem(client, gS_PrefixWeapons[10]);
        FakeClientCommand(client, "use %s", gS_PrefixWeapons[10]);
    }

    return Plugin_Handled;
}

public Action Command_mp5navy(int client, int args)
{
    if (IsValidClient(client))
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }

        gI_LastWeaponTick[client] = GetGameTickCount();

        RemoveClientSlot(client, gI_Slots[11]);
        GivePlayerItem(client, gS_PrefixWeapons[11]);
        FakeClientCommand(client, "use %s", gS_PrefixWeapons[11]);
    }

    return Plugin_Handled;
}

public Action Command_m249(int client, int args)
{
    if (IsValidClient(client))
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }

        gI_LastWeaponTick[client] = GetGameTickCount();

        RemoveClientSlot(client, gI_Slots[12]);
        GivePlayerItem(client, gS_PrefixWeapons[12]);
        FakeClientCommand(client, "use %s", gS_PrefixWeapons[12]);
    }

    return Plugin_Handled;
}

public Action Command_m3(int client, int args)
{
    if (IsValidClient(client))
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }

        gI_LastWeaponTick[client] = GetGameTickCount();

        RemoveClientSlot(client, gI_Slots[13]);
        GivePlayerItem(client, gS_PrefixWeapons[13]);
        FakeClientCommand(client, "use %s", gS_PrefixWeapons[13]);
    }

    return Plugin_Handled;
}

public Action Command_m4a1(int client, int args)
{
    if (IsValidClient(client))
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }

        gI_LastWeaponTick[client] = GetGameTickCount();

        RemoveClientSlot(client, gI_Slots[14]);
        GivePlayerItem(client, gS_PrefixWeapons[14]);
        FakeClientCommand(client, "use %s", gS_PrefixWeapons[14]);
    }

    return Plugin_Handled;
}

public Action Command_mac10(int client, int args)
{
    if (IsValidClient(client))
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }

        gI_LastWeaponTick[client] = GetGameTickCount();

        RemoveClientSlot(client, gI_Slots[15]);
        GivePlayerItem(client, gS_PrefixWeapons[15]);
        FakeClientCommand(client, "use %s", gS_PrefixWeapons[15]);
    }

    return Plugin_Handled;
}

public Action Command_p228(int client, int args)
{
    if (IsValidClient(client))
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }

        gI_LastWeaponTick[client] = GetGameTickCount();

        RemoveClientSlot(client, gI_Slots[16]);
        GivePlayerItem(client, gS_PrefixWeapons[16]);
        FakeClientCommand(client, "use %s", gS_PrefixWeapons[16]);
    }

    return Plugin_Handled;
}

public Action Command_p90(int client, int args)
{
    if (IsValidClient(client))
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }
        
        gI_LastWeaponTick[client] = GetGameTickCount();

        RemoveClientSlot(client, gI_Slots[17]);
        GivePlayerItem(client, gS_PrefixWeapons[17]);
        FakeClientCommand(client, "use %s", gS_PrefixWeapons[17]);
    }

    return Plugin_Handled;
}

public Action Command_sg550(int client, int args)
{
    if (IsValidClient(client))
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }

        gI_LastWeaponTick[client] = GetGameTickCount();

        RemoveClientSlot(client, gI_Slots[18]);
        GivePlayerItem(client, gS_PrefixWeapons[18]);
        FakeClientCommand(client, "use %s", gS_PrefixWeapons[18]);
    }

    return Plugin_Handled;
}

public Action Command_sg552(int client, int args)
{
    if (IsValidClient(client))
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }

        gI_LastWeaponTick[client] = GetGameTickCount();

        RemoveClientSlot(client, gI_Slots[19]);
        GivePlayerItem(client, gS_PrefixWeapons[19]);
        FakeClientCommand(client, "use %s", gS_PrefixWeapons[19]);
    }

    return Plugin_Handled;
}

public Action Command_scout(int client, int args)
{
    if (IsValidClient(client))
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }

        gI_LastWeaponTick[client] = GetGameTickCount();

        RemoveClientSlot(client, gI_Slots[20]);
        GivePlayerItem(client, gS_PrefixWeapons[20]);
        FakeClientCommand(client, "use %s", gS_PrefixWeapons[20]);
    }

    return Plugin_Handled;
}

public Action Command_tmp(int client, int args)
{
    if (IsValidClient(client))
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }

        gI_LastWeaponTick[client] = GetGameTickCount();

        RemoveClientSlot(client, gI_Slots[21]);
        GivePlayerItem(client, gS_PrefixWeapons[21]);
        FakeClientCommand(client, "use %s", gS_PrefixWeapons[21]);
    }

    return Plugin_Handled;
}

public Action Command_ump45(int client, int args)
{
    if (IsValidClient(client))
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }

        gI_LastWeaponTick[client] = GetGameTickCount();

        RemoveClientSlot(client, gI_Slots[22]);
        GivePlayerItem(client, gS_PrefixWeapons[22]);
        FakeClientCommand(client, "use %s", gS_PrefixWeapons[22]);
    }

    return Plugin_Handled;
}

public Action Command_usp(int client, int args)
{
    if (IsValidClient(client))
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }

        gI_LastWeaponTick[client] = GetGameTickCount();

        RemoveClientSlot(client, gI_Slots[23]);
        GivePlayerItem(client, gS_PrefixWeapons[23]);
        FakeClientCommand(client, "use %s", gS_PrefixWeapons[23]);
    }

    return Plugin_Handled;
}

public Action Command_hegrenade(int client, int args)
{
    if (IsValidClient(client))
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }

        gI_LastWeaponTick[client] = GetGameTickCount();

        if (!CanUseNade(client, "h"))
        {
            PP_PrintToChat(client, "%s%s%s You %sdon't have access%s to %shegrenade", gS_ChatStrings.sPrefix, WEAPONS_TAG, gS_ChatStrings.sText, gS_ChatStrings.sWarning, gS_ChatStrings.sText, gS_ChatStrings.sVariable);

            return Plugin_Handled;
        }

        RemoveClientSlot(client, gI_Slots[26]);
        GivePlayerItem(client, gS_PrefixWeapons[26]);
        FakeClientCommand(client, "use %s", gS_PrefixWeapons[26]);
    }

    return Plugin_Handled;
}

public Action Command_smokegrenade(int client, int args)
{
    if (IsValidClient(client))
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }

        gI_LastWeaponTick[client] = GetGameTickCount();

        if (!CanUseNade(client, "s"))
        {
            PP_PrintToChat(client, "%s%s%s You %sdon't have access%s to %ssmokegrenade", gS_ChatStrings.sPrefix, WEAPONS_TAG, gS_ChatStrings.sText, gS_ChatStrings.sWarning, gS_ChatStrings.sText, gS_ChatStrings.sVariable);

            return Plugin_Handled;
        }

        RemoveClientSlot(client, gI_Slots[25]);
        GivePlayerItem(client, gS_PrefixWeapons[25]);
        FakeClientCommand(client, "use %s", gS_PrefixWeapons[25]);
    }

    return Plugin_Handled;
}

public Action Command_flashbang(int client, int args)
{
    if (IsValidClient(client))
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }

        gI_LastWeaponTick[client] = GetGameTickCount();

        if (!CanUseNade(client, "f"))
        {
            PP_PrintToChat(client, "%s%s%s You %sdon't have access%s to %sflashbang", gS_ChatStrings.sPrefix, WEAPONS_TAG, gS_ChatStrings.sText, gS_ChatStrings.sWarning, gS_ChatStrings.sText, gS_ChatStrings.sVariable);

            return Plugin_Handled;
        }

        RemoveClientSlot(client, gI_Slots[24]);
        GivePlayerItem(client, gS_PrefixWeapons[24]);
        FakeClientCommand(client, "use %s", gS_PrefixWeapons[24]);
    }

    return Plugin_Handled;
}

public Action Command_WeaponsList(int client, int args)
{
    OpenWeaponsMenu(client);

    return Plugin_Handled;
}

void OpenWeaponsMenu(int client, int displayAt = 0)
{
    Menu menu = new Menu(WeaponsMenu_Handler);

    int k = 0;
    char info[1024];
    FormatEx(info, 1024, "Weapons List\n \n");
    for (int i = 0; i < gI_WeaponsAmount; i++)
    {
        if (k % 5 == 0)
        {
            FormatEx(info, 1024, "%s\n!%s", info, gS_Weapons[i]);
        }
        else
        {
            FormatEx(info, 1024, "%s, !%s", info, gS_Weapons[i]);
        }

        k++;
    }

    menu.SetTitle("%s\n \n", info);

    if (gB_AntiFlash[client])
    {
        menu.AddItem("af", "Anti-flash: [+]");
    }
    else
    {
        menu.AddItem("af", "Anti-flash: [-]");
    }

    if (gB_Paintball[client])
    {
        menu.AddItem("pb", "Paintball: [+]");
    }
    else
    {
        menu.AddItem("pb", "Paintball: [-]");
    }

    if (gB_Sparks[client])
    {
        menu.AddItem("sp", "Sparks: [+]");
    }
    else
    {
        menu.AddItem("sp", "Sparks: [-]");
    }

    if (gB_Electro[client])
    {
        menu.AddItem("el", "Electro Effects: [+]");
    }
    else
    {
        menu.AddItem("el", "Electro Effects: [-]");
    }

    if (gB_Tracers[client])
    {
        menu.AddItem("tr", "Tracers Effects: [+]\n \n");
    }
    else
    {
        menu.AddItem("tr", "Tracers Effects: [-]\n \n");
    }

    bool okFlash = CanUseNade(client, "f");
    bool okSmoke = CanUseNade(client, "s");
    bool okHE    = CanUseNade(client, "h");

    for (int i = 0; i < sizeof(gI_Slots); i++)
    {
        char display[80];
        int style = ITEMDRAW_DEFAULT;

        if ((i == 24 && !okFlash) || (i == 25 && !okSmoke) || (i == 26 && !okHE))
        {
            FormatEx(display, sizeof(display), "%s (No Access)", gS_Weapons[i]);
            style = ITEMDRAW_DISABLED;
        }
        else
        {
            strcopy(display, sizeof(display), gS_Weapons[i]);
        }

        menu.AddItem(gS_Weapons[i], display, style);
    }

    menu.Pagination = 7;
    menu.ExitButton = true;
    menu.DisplayAt(client, displayAt, 120);
}

public int WeaponsMenu_Handler(Menu menu, MenuAction action, int client, int info)
{
    if (action == MenuAction_Select)
    {
        if (GetGameTickCount() - gI_LastWeaponTick[client] < 10)
        {
            return Plugin_Handled;
        }

        gI_LastWeaponTick[client] = GetGameTickCount();

        if (IsValidClient(client))
        {
            char weapon[32];
            menu.GetItem(info, weapon, 32);

            if (StrEqual(weapon, "af"))
            {
                FakeClientCommand(client, "sm_antiflash");
                OpenWeaponsMenu(client);
            }
            else if (StrEqual(weapon, "pb"))
            {
                FakeClientCommand(client, "sm_paintball");
                OpenWeaponsMenu(client);
            }
            else if (StrEqual(weapon, "sp"))
            {
                FakeClientCommand(client, "sm_sparks");
                OpenWeaponsMenu(client);
            }
            else if (StrEqual(weapon, "el"))
            {
                FakeClientCommand(client, "sm_electroeffects");
                OpenWeaponsMenu(client);
            }
            else if (StrEqual(weapon, "tr"))
            {
                FakeClientCommand(client, "sm_tracers");
                OpenWeaponsMenu(client);
            }
            else
            {
                for (int i = 0; i < gI_WeaponsAmount; i++)
                {
                    if (StrEqual(gS_Weapons[i], weapon))
                    {
                        bool allowed = true;

                        if (i == 24)
                        {
                            allowed = CanUseNade(client, "f");
                        }
                        else if (i == 25)
                        {
                            allowed = CanUseNade(client, "s");
                        }
                        else if (i == 26)
                        {
                            allowed = CanUseNade(client, "h");
                        }

                        if (allowed)
                        {
                            RemoveClientSlot(client, gI_Slots[i]);
                            GivePlayerItem(client, gS_PrefixWeapons[i]);
                            FakeClientCommand(client, "use %s", gS_PrefixWeapons[i]);
                        }

                        OpenWeaponsMenu(client, ((i + 5) / 7) * 7);
                        break;
                    }
                }
            }
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }

    return 0 ;
}

void RemoveClientSlot(int client, int slot)
{
    if (IsValidClient(client))
    {
        int entity = GetPlayerWeaponSlot(client, slot);
        if (entity != -1)
        {
            RemovePlayerItem(client, entity);
            AcceptEntityInput(entity, "Kill");
        }
    }
}

bool IsValidClient(int client)
{
	return (0 < client <= MaxClients && IsPlayerAlive(client));
}

stock void TE_SetupWorldDecal(float vecOrigin[3], int index)
{
    TE_Start("World Decal");
    TE_WriteVector("m_vecOrigin",vecOrigin);
    TE_WriteNum("m_nIndex",index);
}

void ElectroWaveAt(int client, const float impact[3])
{
    int col[4];
    int ci = GetRandomInt(0, sizeof(gI_Colors) - 1);
    col[0] = gI_Colors[ci][0];
    col[1] = gI_Colors[ci][1];
    col[2] = gI_Colors[ci][2];
    col[3] = 255;

    float eyePos[3];
    GetClientEyePosition(client, eyePos);

    float bulletDir[3];
    MakeVectorFromPoints(eyePos, impact, bulletDir);
    NormalizeVector(bulletDir, bulletDir);

    // perpendicular plane to bullet direction
    float right[3], up[3], ref[3];
    if (FloatAbs(bulletDir[2]) < 0.9)
    {
        ref[0] = 0.0; ref[1] = 0.0; ref[2] = 1.0;
    }
    else
    {
        ref[0] = 1.0; ref[1] = 0.0; ref[2] = 0.0;
    }

    GetVectorCrossProduct(bulletDir, ref, right);
    NormalizeVector(right, right);
    GetVectorCrossProduct(right, bulletDir, up);
    NormalizeVector(up, up);

    // vertical ring perpendicular to bullet
    int segments = 24;
    float angleStep = 6.283185 / float(segments);
    float radius = 48.0;

    float first[3], prev[3], curr[3];
    first[0] = impact[0] + right[0] * radius;
    first[1] = impact[1] + right[1] * radius;
    first[2] = impact[2] + right[2] * radius;

    prev[0] = first[0]; prev[1] = first[1]; prev[2] = first[2];

    for (int s = 1; s <= segments; s++)
    {
        if (s < segments)
        {
            float angle = float(s) * angleStep;
            float cosA = Cosine(angle);
            float sinA = Sine(angle);

            curr[0] = impact[0] + (right[0] * cosA + up[0] * sinA) * radius;
            curr[1] = impact[1] + (right[1] * cosA + up[1] * sinA) * radius;
            curr[2] = impact[2] + (right[2] * cosA + up[2] * sinA) * radius;
        }
        else
        {
            curr[0] = first[0]; curr[1] = first[1]; curr[2] = first[2];
        }

        TE_SetupBeamPoints(prev, curr, gI_SpriteLightning, 0, 0, 0, 0.3, 4.0, 4.0, 0, 0.0, col, 0);
        TE_SendToClient(client);

        prev[0] = curr[0]; prev[1] = curr[1]; prev[2] = curr[2];
    }

    // lightning bolts from impact
    for (int j = 0; j < 2; j++)
    {
        float ang[3];
        ang[0] = GetRandomFloat(-48.0, 48.0);
        ang[1] = GetRandomFloat(0.0, 360.0);
        ang[2] = 0.0;

        float dir[3];
        GetAngleVectors(ang, dir, NULL_VECTOR, NULL_VECTOR);

        float len = GetRandomFloat(300.0, 800.0);
        float end[3];
        end[0] = impact[0] + dir[0] * len;
        end[1] = impact[1] + dir[1] * len;
        end[2] = impact[2] + dir[2] * len;

        TE_SetupBeamPoints(impact, end, gI_SpriteLightning, 0, 0, 0, 0.18, 6.0, 4.0, 1, 12.0, col, 0);
        TE_SendToClient(client);
    }

    // energy splash
    TE_SetupEnergySplash(impact, bulletDir, true);
    TE_SendToClient(client);

    // sparks
    TE_SetupSparks(impact, {0.0, 0.0, 0.0}, 4, 16);
    TE_SendToClient(client);
}

