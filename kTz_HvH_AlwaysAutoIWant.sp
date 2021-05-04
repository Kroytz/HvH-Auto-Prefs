#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <ptah>
#include <clientprefs>

// Kxnrl
#include <smutils>

#define hasLength(%0)           (%0[0] != NULL_STRING[0])

#define TEAM_CTs 3
#define TEAM_TEs 2
#define TEAM_ANY 1

static StringMap g_adtWeapon;
static Handle    g_hCookie;
static char      g_szGaygunClass[MAXPLAYERS+1][32];

public void OnPluginStart(/*void*/)
{
    WeaponSkinOnInit();

    g_hCookie = RegClientCookie("kTz_AlwaysMyGaygun", "", CookieAccess_Private);

    // Init SM Utils Chat
    SMUitls_InitUserMessage();
    SMUtils_SetChatPrefix("[\x04AAW\x01]");
    SMUtils_SetChatSpaces(" ");

    HookEvent("round_start", Event_OnRoundStart);

    RegConsoleCmd("sm_gaygun", Show_GayMenu);
}

public Action Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    ChatAll("你可以输入 '{darkred}!gaygun{default}' 来设置你的连狙偏好.");
}

public void OnClientCookiesCached(int client)
{
    GetClientCookie(client, g_hCookie, g_szGaygunClass[client], sizeof(g_szGaygunClass[]));
}

public Action Show_GayMenu(int client, int args)
{
    Menu menu = new Menu(Handle_SkillsMenu);

    menu.SetTitle("[AAW]  选择你喜欢的连狙\n ");

    menu.AddItem("weapon_scar20", "SCAR-20");
    menu.AddItem("weapon_g3sg1", "G3SG1");

    menu.ExitButton = true;
    menu.Display(client, 0);

    return Plugin_Handled;
}

public int Handle_SkillsMenu(Menu menu, MenuAction action, int client, int itemNum)
{
    if (action == MenuAction_Select)
    {
        char info[512];
        GetMenuItem(menu, itemNum, info, sizeof(info));

        SetClientCookie(client, g_hCookie, info);
        strcopy(g_szGaygunClass[client], sizeof(g_szGaygunClass[]), info);

        Chat(client, "已将您的连狙习惯设置为 [{darkred}%s{default}], 当您购买连狙时会被自动替换.", info);
    }

    return 0;
}

void WeaponSkinOnInit()
{
    WeaponSkinInitWeapons();

    PTaH(PTaH_GiveNamedItemPre, Hook, WeaponSkinOnGiveItemPre);
}

public void OnClientPostAdminCheck(int client)
{
    if(!IsPlayerExist(client, false))
        return;

    SDKHook(client, SDKHook_WeaponEquipPost, Event_WeaponEquipPost);
}

public void Event_WeaponEquipPost(int client, int weapon)
{
    if (hasLength(g_szGaygunClass[client]))
    {
        char classname[32];
        WeaponSkinGetWeaponClassname(weapon, classname, 32);

        if (IsWeaponGayGun(classname))
        {
            if (!StrEqual(classname, g_szGaygunClass[client]))
            {
                RemovePlayerItem(client, weapon);
                AcceptEntityInput(weapon, "Kill");
                
                GivePlayerItem(client, g_szGaygunClass[client]);
            }
        }
    }
}

bool IsWeaponGayGun(const char[] weapon)
{
    if ((strcmp(weapon, "weapon_scar20") == 0) || (strcmp(weapon, "weapon_g3sg1") == 0))
        return true;

    return false;
}

public Action WeaponSkinOnGiveItemPre(int client, char classname[64], CEconItemView &Item, bool &IgnoredCEconItemView, bool &OriginIsNULL, float Origin[3])
{
    // If client is not in-game or not alive, then stop.
    if(!IsPlayerExist(client))
        return Plugin_Continue;

    // Get weapon origin team, if not m_bFind, then stop.
    int weaponTeam;
    if(!g_adtWeapon.GetValue(classname, weaponTeam))
        return Plugin_Continue;

    if (weaponTeam == TEAM_ANY)
    {
        weaponTeam = GetClientTeam(client);
    }

    // Get item definition
    CEconItemDefinition ItemDefinition = PTaH_GetItemDefinitionByName(classname); 

    // Item definition is null, then stop.
    if(!ItemDefinition)
        return Plugin_Continue;

    // Get item Loadout Slot
    int iLoadoutSlot = ItemDefinition.GetLoadoutSlot();

    // Get player's inventory
    CCSPlayerInventory Inventory = PTaH_GetPlayerInventory(client);

    // new Item Info
    CEconItemView newItem = Inventory.GetItemInLoadout(weaponTeam, iLoadoutSlot);
    CEconItemDefinition newItemDefinition = newItem.GetItemDefinition();
    if (newItemDefinition.GetDefinitionIndex() != ItemDefinition.GetDefinitionIndex()) return Plugin_Continue;

    Item = newItem;

    return Plugin_Changed;
}

void WeaponSkinInitWeapons()
{
    g_adtWeapon = new StringMap();

    // Pistol
    g_adtWeapon.SetValue("weapon_cz75a",         TEAM_ANY);
    g_adtWeapon.SetValue("weapon_p250",          TEAM_ANY);
    g_adtWeapon.SetValue("weapon_deagle",        TEAM_ANY);
    g_adtWeapon.SetValue("weapon_revolver",      TEAM_ANY);
    g_adtWeapon.SetValue("weapon_elite",         TEAM_ANY);
    g_adtWeapon.SetValue("weapon_glock",         TEAM_TEs);
    g_adtWeapon.SetValue("weapon_tec9",          TEAM_TEs);
    g_adtWeapon.SetValue("weapon_fiveseven",     TEAM_CTs);
    g_adtWeapon.SetValue("weapon_hkp2000",       TEAM_CTs);
    g_adtWeapon.SetValue("weapon_usp_silencer",  TEAM_CTs);
    
    // Heavy
    g_adtWeapon.SetValue("weapon_nova",          TEAM_ANY);
    g_adtWeapon.SetValue("weapon_xm1014",        TEAM_ANY);
    g_adtWeapon.SetValue("weapon_m249",          TEAM_ANY);
    g_adtWeapon.SetValue("weapon_negev",         TEAM_ANY);
    g_adtWeapon.SetValue("weapon_mag7",          TEAM_CTs);
    g_adtWeapon.SetValue("weapon_swadeoff",      TEAM_TEs);

    // SMG
    g_adtWeapon.SetValue("weapon_ump45",         TEAM_ANY);
    g_adtWeapon.SetValue("weapon_p90",           TEAM_ANY);
    g_adtWeapon.SetValue("weapon_bizon",         TEAM_ANY);
    g_adtWeapon.SetValue("weapon_mp7",           TEAM_ANY);
    g_adtWeapon.SetValue("weapon_mp9",           TEAM_CTs);
    g_adtWeapon.SetValue("weapon_mac10",         TEAM_TEs);
    g_adtWeapon.SetValue("weapon_mp5sd",         TEAM_ANY);

    // Rifle
    g_adtWeapon.SetValue("weapon_ssg08",         TEAM_ANY);
    g_adtWeapon.SetValue("weapon_awp",           TEAM_ANY);
    g_adtWeapon.SetValue("weapon_galilar",       TEAM_TEs);
    g_adtWeapon.SetValue("weapon_ak47",          TEAM_TEs);
    g_adtWeapon.SetValue("weapon_sg556",         TEAM_TEs);
    g_adtWeapon.SetValue("weapon_g3sg1",         TEAM_TEs);
    g_adtWeapon.SetValue("weapon_famas",         TEAM_CTs);
    g_adtWeapon.SetValue("weapon_m4a1",          TEAM_CTs);
    g_adtWeapon.SetValue("weapon_m4a1_silencer", TEAM_CTs);
    g_adtWeapon.SetValue("weapon_aug",           TEAM_CTs);
    g_adtWeapon.SetValue("weapon_scar20",        TEAM_CTs);
}

void WeaponSkinGetWeaponClassname(int weapon, char[] classname, int maxLen)
{
    GetEdictClassname(weapon, classname, maxLen);
    switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
    {
        case 23: strcopy(classname, maxLen, "weapon_mp5sd");
        case 60: strcopy(classname, maxLen, "weapon_m4a1_silencer");
        case 61: strcopy(classname, maxLen, "weapon_usp_silencer");
        case 63: strcopy(classname, maxLen, "weapon_cz75a");
        case 64: strcopy(classname, maxLen, "weapon_revolver");
    }
}

stock bool IsPlayerExist(int client, bool bAlive = true)
{
    // If client isn't valid, then stop
    if (client <= 0 || client > MaxClients)
    {
        return false;
    }

    // If client isn't connected, then stop
    if (!IsClientConnected(client))
    {
        return false;
    }

    // If client isn't in game, then stop
    if (!IsClientInGame(client) || IsClientInKickQueue(client))
    {
        return false;
    }

    // If client is TV, then stop
    if (IsClientSourceTV(client))
    {
        return false;
    }

    // If client isn't alive, then stop
    if (bAlive && !IsPlayerAlive(client))
    {
        return false;
    }

    // If client exist
    return true;
}