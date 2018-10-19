#if defined _hns_const_included
	#endinput
#endif
#define _hns_const_included

#define BEGIN_FUNC_BASED_ON_PREVIOUS_SIZE(%0)		(any:%0Func)

enum HNSFunc
{
	/*
	* Description:	-
	* Params:		()
	*/
	HNS_Freezetime,

	/*
	* Description:	-
	* Params:		()
	*/
	HNS_StartRound
};

enum HNSWeaponFunc
{
	/*
	* Description:	-
	* Params:		(const player)
	*/
	HNS_Weapon_GiveKnife = BEGIN_FUNC_BASED_ON_PREVIOUS_SIZE(HNS),

	/*
	* Description:	-
	* Params:		(const player)
	*/
	HNS_Weapon_GiveGrenades,

	/*
	* Description:	-
	* Params:		(const player, const ent)
	*/
	HNS_Weapon_KnifePrimaryAttackPost,

	/*
	* Description:	-
	* Params:		(const player, const ent)
	*/
	HNS_Weapon_KnifeSecondaryAttackPost
};