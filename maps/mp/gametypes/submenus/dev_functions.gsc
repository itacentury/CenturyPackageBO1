#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

printOrigin() {
	self iPrintLn(self.origin);
}

printWeaponClass() {
	currentWeapon = self getCurrentWeapon();
	weaponClass = maps\mp\gametypes\_missions::getWeaponClass(currentWeapon);
	self iPrintLn(weaponClass);
}

printWeapon() {
	currentWeapon = self getCurrentWeapon();
	self iPrintLn(currentWeapon);
}

printOwnXUID() {
	xuid = self getXuid();
	self iPrintLn(xuid);
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
		self iPrintLn(offHandWeaponList[i]);
	}
}

printKillstreaks() {
    for (i = 0; i < self.killstreak.size; i++) {
        self iPrintLn(self.killstreak[i]);
	}
}
