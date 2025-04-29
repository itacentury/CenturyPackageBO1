#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

#include maps\mp\mod\string_utils;

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

checkIfUnwantedPlayers() {
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

lensToColor(lens) {
    switch (lens) {
        case 0: return "1,1,1,1";    // white
        case 1: return "1,0,0,1";    // red
        case 2: return "0,0,1,1";    // blue
        case 3: return "0,1,0,1";    // green
        case 4: return "1,0.29,0,1"; // orange
        case 5: return "1,1,0,1";    // yellow
        default: return "1,1,1,1";
    }
}

getReticleShader(reticle) {
    switch(reticle) {
        case 0: return "menu_mp_reticle_red_dot_main";           // Dot
        case 1: return "menu_mp_reticle_circle_split01";         // Semi-Circles
        case 2: return "menu_mp_reticle_lines_dots01";           // Lines With Dot
        case 3: return "menu_mp_reticle_circles05";               // Hollow Circle
        case 4: return "menu_mp_reticle_happyface01";            // Smiley Face
        case 5: return "menu_mp_reticle_arrows02";               // Arrows Vertical
        case 6: return "menu_mp_reticle_arrows01";               // Arrows Horizontal
        case 7: return "menu_mp_reticle_arrows03";               // Arrows With Dot
        case 8: return "menu_mp_reticle_bones";                  // Bones
        case 9: return "menu_mp_reticle_burst01";                // Burst
        case 10: return "menu_mp_reticle_circles01";             // Circle Within A Circle
        case 11: return "menu_mp_reticle_circles02";             // Circle
        case 12: return "menu_mp_reticle_circles03";             // Circle Outline
        case 13: return "menu_mp_reticle_circles04";             // Circle Outline With Dot
        case 14: return "menu_mp_reticle_circles_lines01";       // Circle With Crosshairs
        case 15: return "menu_mp_reticle_circles_lines02";       // Circle With Outer Lines
        case 16: return "menu_mp_reticle_circles_lines03";       // Circle With Inner Lines
        case 17: return "menu_mp_reticle_circles_triangles01";   // Circle With Arrows
        case 18: return "menu_mp_reticle_circles_triangles02";   // Circle With Triangles
        case 19: return "menu_mp_reticle_cross01";               // Outer Crosshairs
        case 20: return "menu_mp_reticle_cross02";               // Small Crosshairs
        case 21: return "menu_mp_reticle_cross03";               // Large Crosshairs
        case 22: return "menu_mp_reticle_cross04";               // Crosshairs
        case 23: return "menu_mp_reticle_cross05";               // Crosshairs With Dot
        case 24: return "menu_mp_reticle_diamond01";             // Diamond
        case 25: return "menu_mp_reticle_diamond02";             // Diamond Outline
        case 26: return "menu_mp_reticle_heart";                 // Heart
        case 27: return "menu_mp_reticle_radiation";             // Radiation
        case 28: return "menu_mp_reticle_skull01";               // Skull
        case 29: return "menu_mp_reticle_square01";              // Square
        case 30: return "menu_mp_reticle_square02";              // Square Outline
        case 31: return "menu_mp_reticle_squares_cross01";       // Square With Crosshairs
        case 32: return "menu_mp_reticle_star01";                // Star
        case 33: return "menu_mp_reticle_three_dots";            // Three Dots
        case 34: return "menu_mp_reticle_treyarch";              // Treyarch
        case 35: return "menu_mp_reticle_triangle01";            // Triangle
        case 36: return "menu_mp_reticle_triangle02";            // Outer Triangles
        case 37: return "menu_mp_reticle_x01";                   // X
        case 38: return "menu_mp_reticle_x02";                   // X With Dot
        case 39: return "menu_mp_reticle_yinyang";               // Yin Yang
        default: return "menu_mp_reticle_red_dot_main";          // fallback: Dot
    }
}

reticleToColor(reticleColor) {
    switch (reticleColor) {
        case 0: return "1,0,0,1";    // red
        case 1: return "0,1,0,1";    // green
        case 2: return "0,0,1,1";    // blue
        case 3: return "1,0,1,1";    // purple
        case 4: return "0,1,1,1";    // teal
        case 5: return "1,1,0,1";    // yellow
        case 6: return "1,0.29,0,1"; // orange
        default: return "1,0,0,1";
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
