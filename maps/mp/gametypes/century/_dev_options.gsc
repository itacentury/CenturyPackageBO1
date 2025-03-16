#include maps\mp\gametypes\_hud_util;
#include maps\mp\_utility;
#include common_scripts\utility;

printOrigin() {
	self iprintln(self.origin);
}

printWeaponClass() {
	currentWeapon = self getCurrentWeapon();
	weaponClass = maps\mp\gametypes\_missions::getWeaponClass(currentWeapon);
	self iprintln(weaponClass);
}

printWeapon() {
	currentWeapon = self getCurrentWeapon();
	self iprintln(currentWeapon);
}

printOwnXUID() {
	xuid = self getXUID();
	self iprintln(xuid);
}

printWeaponLoop() {
	self endon("death");

	for (;;) {
		self printWeapon();
		wait 1;
	} 
}

printOffHandWeapons() {
	primaryWeaponList = self getWeaponsListPrimaries();
	offHandWeaponList = array_exclude(self getWeaponsList(), primaryWeaponList);
	offHandWeaponList = array_remove(offHandWeaponList, "knife_mp");
	for (i = 0; i < offHandWeaponList.size; i++) {
		self iprintln(offHandWeaponList[i]);
	}
}

testFastRestart() {
	map_restart(false);
}
