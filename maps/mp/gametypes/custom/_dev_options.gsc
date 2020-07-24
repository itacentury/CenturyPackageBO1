#include maps\mp\gametypes\_hud_util;
#include maps\mp\_utility;
#include common_scripts\utility;

printOrigin()
{
	self iprintln(self.origin);
}

printWeaponClass()
{
	weapon = self getcurrentweapon();
	weaponClass = maps\mp\gametypes\_missions::getWeaponClass(weapon);
	self iprintln(weaponClass);
}

printWeapon()
{
	weapon =  self GetCurrentWeapon();
	self iprintln(weapon);
}

printXUID()
{
	xuid = self getXUID();
	self iprintln(xuid);
}

printGUID()
{
	guid = self getGUID();
	self iprintln(guid);
}