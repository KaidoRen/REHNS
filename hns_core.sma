#include <amxmodx>
#include <hns>
#include <reapi>
#include <hamsandwich>

#pragma semicolon           1
#pragma ctrlchar            '\'

#define MAX_TIMER_VALUE     "60"

new const PLUGIN[]          = "HNS Core";

new HookChain: g_pResetMaxSpeed,
g_pCvarFreezetime;

native Array: HNS_GetForwardsHandle();

public plugin_init()
{
    register_plugin(PLUGIN, HNS_VERSION_STR, "gamingEx");

    g_pResetMaxSpeed = RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "CBasePlayer_ResetMaxSpeed", .post = false);
    RegisterHookChain(RG_CBasePlayer_GiveDefaultItems, "CBasePlayer_GiveDefaultItems", .post = false);
    
    RegisterHookChain(RG_CSGameRules_RestartRound, "CSGameRules_RestartRound", .post = false); 
    RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "CSGameRules_OnRoundFreezeEnd", .post = true);
    RegisterHookChain(RG_CSGameRules_GiveC4, "CSGameRules_GiveC4", .post = false);

    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "CBaseWeapon_PrimaryAttack", .Post = false);
    RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "CBaseWeapon_SecondaryAttack", .Post = false);
    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "CBaseWeapon_PrimaryAttackPost", .Post = true);
    RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "CBaseWeapon_SecondaryAttackPost", .Post = true);

    HNS_RegisterEvent(CF_Main_ParseEnd, "Config_ParseEnd"), HNS_RegisterEvent(CF_Map_ParseEnd, "Config_ParseEnd");

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
        new iValue = HNS_CF_GetAttributeCell("flashbangs");
        if (iValue) {
            rg_give_item(player, "weapon_flashbang");
            rg_set_user_bpammo(player, WEAPON_FLASHBANG, iValue);
        }

        if ((iValue = HNS_CF_GetAttributeCell("hegrenades"))) {
            rg_give_item(player, "weapon_hegrenade");
            rg_set_user_bpammo(player, WEAPON_HEGRENADE, iValue);
        }

        if ((iValue = HNS_CF_GetAttributeCell("smokegrenades"))) {
            rg_give_item(player, "weapon_smokegrenade");
            rg_set_user_bpammo(player, WEAPON_SMOKEGRENADE, iValue);
        }

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

public Config_ParseEnd()
{
    set_pcvar_num(g_pCvarFreezetime, HNS_CF_GetAttributeCell("timer"));
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

public plugin_precache()
{
    g_pForwards = HNS_GetForwardsHandle();
}

public plugin_natives()
{
    register_native("HNS_RegisterEvent",            "Native__RegisterEvent");
    register_native("HNS_DisableEvent",             "Native__DisableEvent");
    register_native("HNS_EnableEvent",              "Native__EnableEvent");
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

stock bool: ExecuteAllForwards(const {HNSFunc, HNSWeaponFunc}: funcID, &result, bool: post, any: ...)
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