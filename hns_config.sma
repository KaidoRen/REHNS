#include <amxmodx>
#include <hns>

new const PLUGIN[] = "HNS: Config";

const MAX_ATTRIBUTE_SIZE = 32;
const MAX_VALUE_SIZE = 128;
const CONFIGVAR_VALUE_MAX_LEN = 32;

#define ADD_SECTION(%0) { %0, "", 0, 0 }
#define ADD_CELL_VAR(%0,%1,%2,%3) { %0, %1, %2, %3 }
enum varStruct { varname[32], varvalue[32], varmin, varmax };
new const g_szConfigVars[][varStruct] = {
    ADD_SECTION("core"),
    ADD_CELL_VAR("enabled", "1", 0, 1),
    ADD_CELL_VAR("timer", "5", 0, 60),

    ADD_SECTION("weapons"),
    ADD_CELL_VAR("flashbangs", "2", 0, 99),
    ADD_CELL_VAR("hegrenades", "0", 0, 99),
    ADD_CELL_VAR("smokegrenades", "1", 0, 99)
};

new Trie: g_pConfigAssoc;

public plugin_init()
{
    register_plugin(PLUGIN, HNS_VERSION_STR, "gamingEx");

    ConfigParser_INIT();
}

new g_szConfigsDir[128];
new const g_szMainConfigDir[] = "/hns";
new const g_szMainConfigFile[] = "hns_config.ini";
ConfigParser_INIT()
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

Config__SetDefaultParams()
{
    g_pConfigAssoc = TrieCreate();

    for (new i; i < sizeof g_szConfigVars; i++) {
        TrieSetString(g_pConfigAssoc, g_szConfigVars[i][varname], g_szConfigVars[i][varvalue]);
    }
}

public OnMainParseEnd(INIParser: handle, bool: halted, data)
{
    new szMap[128];
    new const szConfigExtension[] = ".ini";

    ExecuteAllForwards(CF_Main_ParseEnd, data, true);

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

public bool: OnParserFinds_KeyValuePair(INIParser: handle, const key[], value[CONFIGVAR_VALUE_MAX_LEN])
{
    new iResult;
    for (new i; i < sizeof g_szConfigVars; i++) {
        if (equal(g_szConfigVars[i][varname], key)) {
            strclamp(value, charsmax(value), value, g_szConfigVars[i][varmin], g_szConfigVars[i][varmax]);
        }
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
    register_native("HNS_CF_RegisterAttribute",     "Native__CF_RegisterAttribute");
    register_native("HNS_CF_AttributeExists",       "Native__CF_AttributeExists");
    register_native("HNS_CF_GetAttributeString",    "Native__CF_GetAttributeString");
    register_native("HNS_CF_GetAttributeCell",      "Native__CF_GetAttributeCell");
    register_native("HNS_CF_GetAttributeFloat",     "Native__CF_GetAttributeFloat");

    register_native("HNS_GetForwardsHandle",        "Native__GetForwardsHandle");

    g_pForwards = ArrayCreate(forwardStruct);
}

public Array: Native__GetForwardsHandle()
{
    return g_pForwards;
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

stock bool: ExecuteAllForwards(const ConfigFunc: funcID, &result, bool: post, any: ...)
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