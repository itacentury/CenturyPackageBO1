#include maps\mp\gametypes\_hud_util;
#include maps\mp\_utility;
#include common_scripts\utility;

printOrigin()
{
	self iprintln(self.origin);
}

printWeaponClass()
{
	weapon = self getCurrentWeapon();
	weaponClass = maps\mp\gametypes\_missions::getWeaponClass(weapon);
	self iprintln(weaponClass);
}

printWeapon()
{
	weapon =  self getCurrentWeapon();
	self iprintln(weapon);
}

printOwnXUID()
{
	xuid = self getXUID();
	self iprintln(xuid);
}

printWeaponLoop()
{
	self endon("death");

	for (;;)
	{
		weap = self getCurrentWeapon();
		self iprintln(weap);
		wait 1;
	} 
}

printOffHandWeapons()
{
	prim = self getWeaponsListPrimaries();
	offHand = array_exclude(self getWeaponsList(), prim);
	offHandWOKnife = array_remove(offHand, "knife_mp");
	for (i = 0; i < offHandWOKnife.size; i++)
	{
		self iprintln(offHandWOKnife[i]);
	}
}

testFastRestart()
{
	map_restart(false);
}
