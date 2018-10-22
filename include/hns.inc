#if defined _hns_included
	#endinput
#endif
#define _hns_included

#include <hns_const>
#include <hns_config>

enum
{
	HNS_CONTINUE,    // plugin didn't take any action
	HNS_SUPERCEDE,   // skip real function
	HNS_BREAK        // skip real function, skip all forwards following after the current
};

enum HNSEvent
{
	INVALID_HNSEVENT = -1
};

/*
* Registers an event triggering in game mode.
*
* @param funcID     The function to hook
* @param callback   The forward to call
* @param post       Whether or not to forward this in post
* @param disable    Turn off by default
*
* @return           Returns a event handle. Use HNS_EnableEvent/HNS_DisableEvent to toggle the forward
*/
native HNSEvent: HNS_RegisterEvent(const {ConfigFunc, HNSFunc, HNSWeaponFunc}: funcID, const callback[], bool: post = false, bool: disable = false);

/*
* Stops a event hook from triggering.
*
* @param event      The event to stop
*
*/
native bool: HNS_EnableEvent(HNSEvent: event);

/*
* Disable calling a function when an event is triggered..
*
* @param event      The event to enable
*
*/
native bool: HNS_DisableEvent(HNSEvent: event);