#if defined _hns_config_included
	#endinput
#endif
#define _hns_config_included

enum ConfigFunc
{
	/*
	* Description:    Called when starting the parsing of the main configuration file
	* Params:         ()
	*/
	CF_Main_ParseStart = BEGIN_FUNC_BASED_ON_PREVIOUS_SIZE(HNSWeapon),

	/*
	* Description:    Called when ending the parsing of the main configuration file
	* Params:         ()
	*/
	CF_Main_ParseEnd,

	/*
	* Description:    Called when starting the parsing of the map configuration file
	* Params:         (const map[], const file[])
	*/
	CF_Map_ParseStart,

	/*
	* Description:    Called when ending the parsing of the map configuration file
	* Params:         ()
	*/
	CF_Map_ParseEnd,

	/*
	* Description:    Called when a key and value pair is found
	* Params:         (bool: section, const name[], const value[])
	* Return:         bool
	*/
	CF_FindsSectionOrKey
};

/*
* Register a new config attribute.
*
* @param attribute    Attribute name
* @param defvalue     Default value for this attribute
*
*/
native bool: HNS_CF_RegisterAttribute(const attribute[], const defvalue[]);

/*
* Checks the presence of an attribute in the config.
*
*/
native bool: HNS_CF_AttributeExists(const attribute[]);

/*
* Retrieves the attribute value as a string.
*
* @param attribute    Attribute name
* @param output       Buffer to copy the value to
* @param outputsize   Maximum size of buffer
*
*/
native bool: HNS_CF_GetAttributeString(const attribute[], output[], outputsize);

/*
* Retrieves the attribute value as a cell.
*
* @param attribute    Attribute name
* 
* @return             Value as a cell or -1
*
*/
native HNS_CF_GetAttributeCell(const attribute[]);

/*
* Retrieves the attribute value as a float.
*
* @param attribute    Attribute name
* 
* @return             Value as a float or -1.0
*
*/
native Float: HNS_CF_GetAttributeFloat(const attribute[]);