#include <amxmodx>
#include <hns>
#include <reapi>
#include <hamsandwich>

#pragma semicolon           1
#pragma ctrlchar            '\'

#define MAX_TIMER_VALUE     "60"

new const PLUGIN[]          = "HNS Core";
new const VERSION[]         = "1.2.4";

const IS_SECTION            = -2;

new Trie: g_pConfigAssoc, HookChain: g_pResetMaxSpeed,
g_pCvarFreezetime;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, "gamingEx");

    g_pResetMaxSpeed = RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "CBasePlayer_ResetMaxSpeed", .post = false);
    RegisterHookChain(RG_CBasePlayer_GiveDefaultItems, "CBasePlayer_GiveDefaultItems", .post = false);
    
    RegisterHookChain(RG_CSGameRules_RestartRound, "CSGameRules_RestartRound", .post = false); 
    RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "CSGameRules_OnRoundFreezeEnd", .post = true);
    RegisterHookChain(RG_CSGameRules_GiveC4, "CSGameRules_GiveC4", .post = false);

    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "CBaseWeapon_PrimaryAttack", .Post = false);
    RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "CBaseWeapon_SecondaryAttack", .Post = false);
    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "CBaseWeapon_PrimaryAttackPost", .Post = true);
    RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "CBaseWeapon_SecondaryAttackPost", .Post = true);

    g_pCvarFreezetime = get_cvar_pointer("mp_freezetime");
}

public CSGameRules_RestartRound()
{
    new iResult; ExecuteAllForwards(HNS_Freezetime, iResult, true);
    EnableHookChain(g_pResetMaxSpeed);
}

const Float: DEFAULT_MAXSPEED = 250.0;
public CBasePlayer_ResetMaxSpeed(const player)
{
    if (get_member(player, m_iTeam) == TEAM_TERRORIST) {
        set_entvar(player, var_maxspeed, DEFAULT_MAXSPEED);
        return HC_SUPERCEDE;
    }
    
    return HC_CONTINUE;
}

public CBasePlayer_GiveDefaultItems(const player)
{
    new iResult;
    if (ExecuteAllForwards(HNS_Weapon_GiveKnife, iResult, false, player) && iResult == HNS_CONTINUE) {
        rg_give_item(player, "weapon_knife");
        ExecuteAllForwards(HNS_Weapon_GiveKnife, iResult, true, player);
    }

    if (get_member(player, m_iTeam) == TEAM_TERRORIST && ExecuteAllForwards(HNS_Weapon_GiveGrenades, iResult, false, player) && iResult == HNS_CONTINUE) {
        rg_give_item(player, "weapon_flashbang");
        rg_give_item(player, "weapon_smokegrenade");
        ExecuteAllForwards(HNS_Weapon_GiveGrenades, iResult, true, player);
    }

    return HC_SUPERCEDE;
}

public CSGameRules_OnRoundFreezeEnd()
{
    new iResult; ExecuteAllForwards(HNS_StartRound, iResult, true);
    DisableHookChain(g_pResetMaxSpeed);
}

public CSGameRules_GiveC4()
{
    return HC_SUPERCEDE;
}

public CBaseWeapon_PrimaryAttack(const this)
{
    new iPlayer = get_member(this, m_pPlayer);

    if (get_member(iPlayer, m_iTeam) == TEAM_CT) {
        ExecuteHamB(Ham_Weapon_SecondaryAttack, this);
    }

    return HAM_SUPERCEDE;
}

public CBaseWeapon_SecondaryAttack(const this)
{
    new iPlayer = get_member(this, m_pPlayer);

    if (get_member(iPlayer, m_iTeam) == TEAM_TERRORIST) {
        return HAM_SUPERCEDE;
    }

    return HAM_IGNORED;
}

public CBaseWeapon_PrimaryAttackPost(const this)
{
    new iResult, iPlayer = get_member(this, m_pPlayer);
    ExecuteAllForwards(HNS_Weapon_KnifePrimaryAttackPost, iResult, true, iPlayer, this);
}

public CBaseWeapon_SecondaryAttackPost(const this)
{
    new iResult, iPlayer = get_member(this, m_pPlayer);
    ExecuteAllForwards(HNS_Weapon_KnifeSecondaryAttackPost, iResult, true, iPlayer, this);
}

new g_szConfigsDir[128];
new const g_szMainConfigDir[] = "/hns";
new const g_szMainConfigFile[] = "hns_config.ini";
public plugin_cfg()
{
    new INIParser: pParser, iResult;

    get_localinfo("amxx_configsdir", g_szConfigsDir, charsmax(g_szConfigsDir));

    Config__SetDefaultParams();
    INI_SetReaders(pParser = INI_CreateParser(), "OnParserFinds_KeyValuePair", "OnParserFinds_NewSection");
    INI_SetParseEnd(pParser, "OnMainParseEnd");
    
    if (ExecuteAllForwards(CF_Main_ParseStart, iResult, false) && iResult == HNS_CONTINUE && !INI_ParseFile(pParser, fmt("%s/%s/%s", g_szConfigsDir, g_szMainConfigDir, g_szMainConfigFile))) {
        server_print("HNS: The configuration file (%s) is missing. The mod settings are set by default.", fmt("%s/%s/%s", g_szConfigsDir, g_szMainConfigDir, g_szMainConfigFile));
    }

    if (iResult == HNS_CONTINUE) {
        ExecuteAllForwards(CF_Main_ParseStart, iResult, true);
    }

    INI_DestroyParser(pParser);
}

public OnMainParseEnd(INIParser: handle, bool: halted, data)
{
    new szMap[128];
    new const szConfigExtension[] = ".ini";

    ExecuteAllForwards(CF_Main_ParseEnd, data, true);

    set_pcvar_num(g_pCvarFreezetime, HNS_CF_GetAttributeCell("timer"));

    get_mapname(szMap, charsmax(szMap));
    if (file_exists(fmt("%s/%s/maps/%s%s", g_szConfigsDir, g_szMainConfigDir, szMap, szConfigExtension))) {
        ReadMapConfig(fmt("%s/%s/maps/%s%s", g_szConfigsDir, g_szMainConfigDir, szMap, szConfigExtension), szMap);
        return;
    }

    new szPrefix[32]; strtok(szMap, szPrefix, charsmax(szPrefix), "", 0, '_', true);
    if (file_exists(fmt("%s/%s/maps/prefix_%s%s", g_szConfigsDir, g_szMainConfigDir, szPrefix, szConfigExtension))) {
        ReadMapConfig(fmt("%s/%s/maps/prefix_%s%s", g_szConfigsDir, g_szMainConfigDir, szMap, szConfigExtension), szMap);
    }
}

public bool: OnParserFinds_KeyValuePair(INIParser: handle, const key[], value[])
{
    new iResult;
    if (equal(value, "enabled")) {
        strclamp(value, strlen(value) + 1/*+ break symbol (\n)*/, value, false, true);
    }
    else if (equal(value, "timer")) {
        strclamp(value, strlen(MAX_TIMER_VALUE) + 1/*+ break symbol (\n)*/, value, 0, str_to_num(MAX_TIMER_VALUE));
    }

    if (TrieKeyExists(g_pConfigAssoc, key) && value[0] != EOS && ExecuteAllForwards(CF_FindsSectionOrKey, iResult, false, false, key, value)) {
        if (iResult == HNS_CONTINUE) {
            TrieSetString(g_pConfigAssoc, key, value);
            ExecuteAllForwards(CF_FindsSectionOrKey, iResult, true, false, key, value);
            return true;
        }
    }

    return false;
}

public bool: OnParserFinds_NewSection(INIParser: handle, const section[], bool:invalidTokens, bool: closeBracket, bool: extraTokens)
{
    new iResult;
    if (!extraTokens && closeBracket && TrieKeyExists(g_pConfigAssoc, section) && ExecuteAllForwards(CF_FindsSectionOrKey, iResult, false, true, section) && iResult == HNS_CONTINUE) {
        ExecuteAllForwards(CF_FindsSectionOrKey, iResult, true, true, section);
        return true;
    }

    return false;
}

Config__SetDefaultParams()
{
    g_pConfigAssoc = TrieCreate();

    TrieSetCell(g_pConfigAssoc, "core", IS_SECTION);
    TrieSetString(g_pConfigAssoc, "enabled", "1");
    TrieSetString(g_pConfigAssoc, "timer", "5");
}

stock ReadMapConfig(const config[], const map[])
{
    new INIParser: pParser, iResult;

    INI_SetReaders(pParser = INI_CreateParser(), "OnParserFinds_KeyValuePair", "OnParserFinds_NewSection");
    INI_SetParseEnd(pParser, "OnMapParseEnd");
    
    if (ExecuteAllForwards(CF_Map_ParseStart, iResult, false, map, config) && iResult == HNS_CONTINUE && !INI_ParseFile(pParser, config)) {
        server_print("HNS: The configuration file (%s) is missing. The mod settings are set by default.", config);
    }

    if (iResult == HNS_CONTINUE) {
        ExecuteAllForwards(CF_Map_ParseStart, iResult, true, map, config);
    }

    INI_DestroyParser(pParser);
}

public OnMapParseEnd(INIParser: handle, bool: halted, data)
{
    ExecuteAllForwards(CF_Map_ParseEnd, data, true);
    set_pcvar_num(g_pCvarFreezetime, HNS_CF_GetAttributeCell("timer"));
}

stock strclamp(buffer[], const len, const value[], min = cellmin, max = cellmax)
{
    return num_to_str(clamp(str_to_num(value), min, max), buffer, len);
}

// **********************************************************************
// ********************************** API *******************************

#define MAX_ATTRIBUTE_SIZE 32
#define MAX_VALUE_SIZE 128

#define getarg_str(%0,%1,%2) \
    for (new i; i <= %2; i++) \
        if ((%1[i] = getarg(%0, i)) == EOS) break

enum forwardStruct
{
    any: forwardFuncID,
    forwardCallbackID,
    forwardPluginID,
    bool: forwardPost,
    bool: forwardDisable
} new Array: g_pForwards;

public plugin_natives()
{
    register_native("HNS_RegisterEvent",            "Native__RegisterEvent");
    register_native("HNS_DisableEvent",             "Native__DisableEvent");
    register_native("HNS_EnableEvent",              "Native__EnableEvent");

    register_native("HNS_CF_RegisterAttribute",     "Native__CF_RegisterAttribute");
    register_native("HNS_CF_AttributeExists",       "Native__CF_AttributeExists");
    register_native("HNS_CF_GetAttributeString",    "Native__CF_GetAttributeString");
    register_native("HNS_CF_GetAttributeCell",      "Native__CF_GetAttributeCell");
    register_native("HNS_CF_GetAttributeFloat",     "Native__CF_GetAttributeFloat");

    g_pForwards = ArrayCreate(forwardStruct);
}

public Native__RegisterEvent(amx, params)
{
    enum { argFuncID = 1, argCallback, argPost, argDisable };
    new pForwardData[forwardStruct];

    if (HNS_Freezetime > (pForwardData[forwardFuncID] = get_param(argFuncID)) > CF_FindsSectionOrKey) {
        return INVALID_HANDLE;
    }

    new szCallback[32]; get_string(argCallback, szCallback, charsmax(szCallback));
    if ((pForwardData[forwardCallbackID] = get_func_id(szCallback, amx)) == INVALID_HANDLE) {
        return INVALID_HANDLE;
    }

    pForwardData[forwardPluginID] = amx;
    pForwardData[forwardDisable] = bool: get_param(argDisable);

    switch (pForwardData[forwardFuncID]) {
        case HNS_Freezetime, HNS_StartRound, CF_Main_ParseEnd, CF_Map_ParseEnd: {
            pForwardData[forwardPost] = true;
        }
        default: {
            pForwardData[forwardPost] = bool: get_param(argPost);
        }
    }

    return ArrayPushArray(g_pForwards, pForwardData);
}

public Native__DisableEvent(amx, params)
{
    return ToggleState(get_param(1), true);
}

public Native__EnableEvent(amx, params)
{
    return ToggleState(get_param(1), false);
}


public Native__CF_RegisterAttribute(amx, params)
{
    enum { attribute = 1, defvalue }

    if (!g_pConfigAssoc) {
        return false;
    }

    new szAttribute[MAX_ATTRIBUTE_SIZE], szDefaultValue[MAX_VALUE_SIZE];
    get_string(attribute, szAttribute, charsmax(szAttribute));
    get_string(defvalue, szDefaultValue, charsmax(szDefaultValue));

    if (szAttribute[0] == EOS || szDefaultValue[0] == EOS) {
        return false;
    }

    return bool: TrieSetString(g_pConfigAssoc, szAttribute, szDefaultValue);
}

public Native__CF_AttributeExists(amx, params)
{
    enum { attribute = 1 }

    if (!g_pConfigAssoc) {
        return false;
    }

    new szAttribute[MAX_ATTRIBUTE_SIZE];
    get_string(attribute, szAttribute, charsmax(szAttribute));

    return TrieKeyExists(g_pConfigAssoc, szAttribute);
}

public Native__CF_GetAttributeString(amx, params)
{
    enum { attribute = 1, output, outputsize }

    if (!g_pConfigAssoc) {
        return false;
    }

    new szAttribute[MAX_ATTRIBUTE_SIZE], szValue[MAX_VALUE_SIZE];
    get_string(attribute, szAttribute, charsmax(szAttribute));

    if (TrieGetString(g_pConfigAssoc, szAttribute, szValue, charsmax(szValue))) {
        set_string(output, szValue, outputsize);
        return true;
    }

    return false;
}

public Native__CF_GetAttributeCell(amx, params)
{
    enum { attribute = 1 }

    if (!g_pConfigAssoc) {
        return -1;
    }

    new szAttribute[MAX_ATTRIBUTE_SIZE], szValue[MAX_VALUE_SIZE];
    get_string(attribute, szAttribute, charsmax(szAttribute));

    if (TrieGetString(g_pConfigAssoc, szAttribute, szValue, charsmax(szValue))) {
        return str_to_num(szValue);
    }

    return -1;
}

public Float: Native__CF_GetAttributeFloat(amx, params)
{
    enum { attribute = 1 }

    if (!g_pConfigAssoc) {
        return -1.0;
    }

    new szAttribute[MAX_ATTRIBUTE_SIZE], szValue[MAX_VALUE_SIZE];
    get_string(attribute, szAttribute, charsmax(szAttribute));

    if (TrieGetString(g_pConfigAssoc, szAttribute, szValue, charsmax(szValue))) {
        return str_to_float(szValue);
    }

    return -1.0;
}

stock bool: ToggleState(const eventHandle, const bool: eventDisable)
{
    new iEventHandle = eventHandle, pForwardData[forwardStruct];
    if (!ArrayGetArray(g_pForwards, iEventHandle, pForwardData)) {
        return false;
    }

    pForwardData[forwardDisable] = eventDisable;
    ArraySetArray(g_pForwards, iEventHandle, pForwardData);
    return true;
}

stock bool: ExecuteAllForwards(const {HNSFunc, HNSWeaponFunc, ConfigFunc}: funcID, &result, bool: post, any: ...)
{
    new pForwardData[forwardStruct], iIter, iResult;

    result = HNS_CONTINUE;

    while (iIter < ArraySize(g_pForwards)) {
        ArrayGetArray(g_pForwards, iIter++, pForwardData);

        if (pForwardData[forwardFuncID] != funcID || pForwardData[forwardDisable] || pForwardData[forwardPost] != post) {
            continue;
        }

        if (callfunc_begin_i(pForwardData[forwardCallbackID], pForwardData[forwardPluginID]) != 1) {
            continue;
        }
        
        switch (funcID) {
            case CF_Map_ParseStart: {
                enum { map = 3, config };
                new szArg[2][256];

                getarg_str(map, szArg[0], charsmax(szArg[])); callfunc_push_str(szArg[0]);
                getarg_str(config, szArg[1], charsmax(szArg[])); callfunc_push_str(szArg[1]);
            }

            case CF_FindsSectionOrKey: {
                enum { section = 3, name, value }; 
                new szArg[2][32];
                
                callfunc_push_int(getarg(section));
                getarg_str(name, szArg[0], charsmax(szArg[])); callfunc_push_str(szArg[0]);
                getarg_str(value, szArg[1], charsmax(szArg[])); callfunc_push_str(szArg[1]);
            }

            case HNS_Weapon_GiveKnife, HNS_Weapon_GiveGrenades: {
                enum { player = 3 };
                callfunc_push_int(getarg(player));
            }

            case HNS_Weapon_KnifePrimaryAttackPost, HNS_Weapon_KnifeSecondaryAttackPost: {
                enum { player = 3, ent };
                callfunc_push_int(getarg(player));
                callfunc_push_int(getarg(ent));
            }
        }

        if (post) {
            callfunc_end();
            continue;
        }

        if ((iResult = callfunc_end()) == HNS_SUPERCEDE) {
            result = HNS_SUPERCEDE;
        }

        if (iResult == HNS_BREAK) {
            result = HNS_BREAK;
            return false;
        }
    }

    return true;
}

// **********************************************************************
// **********************************************************************