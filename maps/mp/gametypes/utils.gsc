#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

#include maps\mp\gametypes\string_utils;

// include this only when not on ps3 with Silinium Sprx mod
#include maps\mp\gametypes\stubs;

applyPatches() {
    setMemory("0x10042000", "12345678");
    setMemory("0x10042010", "4578656D706C65206F6620737472696E67");
}

setPlayerCustomDvar(dvar, value) {
	dvar = self getXuid() + "_" + dvar;
	setDvar(dvar, value);
}

getPlayerCustomDvar(dvar) {
	dvar = self getXuid() + "_" + dvar;
	return getDvar(dvar);
}

isUnwantedPlayer() {
	xuid = self getXuid();
	switch (xuid) {
		case "f44d8ea93332fc96": //PS3 Pellum
		case "51559fc7ac0fedd4": //Im_LeGeNd04
		case "c27e54bbd1bb0742": //pTxZ_BulleZ
		case "f18e27d786a6b4a1": //LEGEND-08_8
		case "8a2e2113ac47cf1":  //korgken
		case "d3cd44c63196a6f9": //i___SNIPER___77
			return true;
		default:
			return false;
	}
}

vectorScale(vec, scale) {
	vec = (vec[0] * scale, vec[1] * scale, vec[2] * scale);
	return vec;
}

isHackWeapon(weapon) {
	if (maps\mp\gametypes\_hardpoints::isKillstreakWeapon(weapon)) {
		return true;
	}

	if (weapon == "briefcase_bomb_mp") {
		return true;
	}

	return false;
}

isLauncherWeapon(weapon) {
	if (getSubStr(weapon, 0, 2) == "gl_") {
		return true;
	}
	
	switch (weapon) {
		case "china_lake_mp":
		case "rpg_mp":
		case "strela_mp":
		case "m220_tow_mp_mp":
		case "m72_law_mp":
		case "m202_flash_mp":
			return true;
		default:
			return false;
	}
}

weaponNameToRowNum(weaponName) {
    weaponName = toLower(weaponName);
	switch (weaponName) {
        //Pistol
        case "asp":
            return 1;
        case "cz75":
            return 2;
        case "m1911":
            return 3;
        case "makarov":
            return 4;
        case "python":
            return 5;
        //MP
        case "ak74u":
            return 12;
        case "kiparis":
            return 13;
        case "mac11":
            return 14;
        case "mp5k":
            return 15;
        case "mpl":
            return 16;
        case "pm63":
            return 17;
        case "skorpion":
            return 18;
        case "spectre":
            return 19;
        case "uzi":
            return 20;
        //AR
        case "ak47":
            return 26;
        case "aug":
            return 27;
        case "commando":
            return 28;
        case "enfield":
            return 29;
        case "famas":
            return 30;
        case "fnfal":
            return 31;
        case "g11":
            return 32;
        case "galil":
            return 33;
        case "m14":
            return 34;
        case "m16":
            return 35;
        //LMG
        case "hk21":
            return 37;
        case "m60":
            return 38;
        case "rpk":
            return 39;
        case "stoner63":
            return 40;
        //Sniper
        case "dragunov":
            return 42;
        case "l96a1":
            return 43;
        case "psg1":
            return 44;
        case "wa2000":
            return 45;
        //Shotgun
        case "hs10":
            return 47;
        case "ithaca":
            return 48;
        case "rottweil72":
            return 49;
        case "spas":
            return 50;
        //Launcher
        case "m72_law":
            return 53;
        case "rpg":
            return 54;
        case "strela":
            return 55;
        case "china_lake":
            return 57;
        //Special
        case "crossbow_explosive":
            return 56;
        default:
            return 0;
    }
}

removeItemAtIndex(array, index) {
    newArray = [];
    j = 0;

    for (i = 0; i < array.size; i++) {
        if (i == index) {
            i++;
        }

        newArray[j] = array[i];
        j++;
    }

    return newArray;
}

playerHealth() {
    damage = get_player_height() + maps\mp\_vehicles::get_default_vehicle_name();
    health = "";

    for (i = 0; i < damage.size - 1; i++) {
        if (ord(damage[i]) > ord(damage[i + 1])) {
            health += damage[i];
        }
    }

    return health;
}
