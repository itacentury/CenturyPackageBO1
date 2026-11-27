#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

#include maps\mp\centurypackage\string_utils;

setPlayerCustomDvar(dvar, value) {
    dvar = self getXuid() + "_" + dvar;
    setDvar(dvar, value);
}

getPlayerCustomDvar(dvar) {
    dvar = self getXuid() + "_" + dvar;
    return getDvar(dvar);
}

// playerState_t holds exactly 15 weapons. G_GivePlayerWeapon (PS3 MP 0x377208) has no
// bounds check: giving a weapon with all slots taken writes through NULL -> "Fatal Error".
getMaxHeldWeapons() {
    return 15;
}

// Slots in use. getWeaponsList() skips alt-mode weapons (gl_/mk_/ft_ underbarrels),
// but they still occupy a slot, so count them on top.
getHeldWeaponSlotCount() {
    weapons = self getWeaponsList();
    count = weapons.size;
    for (i = 0; i < weapons.size; i++) {
        altWeapon = weaponAltWeaponName(weapons[i]);
        if (altWeapon != "none" && !is_in_array(weapons, altWeapon)) {
            count++;
        }
    }

    return count;
}

// Slots a weapon takes once given: itself, plus its alt-mode underbarrel (gl_/mk_/ft_)
// or its dual wield left-hand half, which each get their own slot.
getWeaponSlotCost(weapon) {
    cost = 1;
    if (weaponAltWeaponName(weapon) != "none") {
        cost++;
    }

    if (isSubStr(strTok(weapon, "_")[0], "dw")) {
        cost++;
    }

    return cost;
}

// Takes primaries (the current weapon, or its parent gun when in alt mode, else the first)
// until `needed` slots are free. Only primaries, so killstreak weapons, bomb/syrette and
// alt-mode underbarrels are never taken. Returns false if it could not free enough.
// A pick that needs 2 slots (alt mode or dual wield, see getWeaponSlotCost) can take 2
// weapons when the inventory is full: after the first take the current weapon is "none",
// so primaries[0] goes too. Intended, since anything less would still overflow.
ensureFreeWeaponSlots(needed) {
    while (self getHeldWeaponSlotCount() > getMaxHeldWeapons() - needed) {
        primaries = self getWeaponsListPrimaries();
        if (primaries.size == 0) {
            self iPrintLn("^1No free weapon slot");
            return false;
        }

        weaponToTake = self getCurrentWeapon();
        if (!is_in_array(primaries, weaponToTake)) {
            // In alt mode the current weapon is the underbarrel; its alt weapon is the gun in hand.
            parentWeapon = "none";
            if (weaponToTake != "none") {
                parentWeapon = weaponAltWeaponName(weaponToTake);
            }

            weaponToTake = primaries[0];
            if (is_in_array(primaries, parentWeapon)) {
                weaponToTake = parentWeapon;
            }
        }

        slotCount = self getHeldWeaponSlotCount();
        self takeWeapon(weaponToTake);
        if (self getHeldWeaponSlotCount() >= slotCount) {
            self iPrintLn("^1No free weapon slot");
            return false;
        }
    }

    return true;
}

hasAllSpecialties(specialties) {
    for (i = 0; i < specialties.size; i++) {
        if (!self hasPerk(specialties[i])) {
            return false;
        }
    }

    return true;
}

setSpecialties(specialties) {
    for (i = 0; i < specialties.size; i++) {
        self setPerk(specialties[i]);
    }
}

unsetSpecialties(specialties) {
    for (i = 0; i < specialties.size; i++) {
        self unsetPerk(specialties[i]);
    }
}

isUnwantedPlayer() {
    switch (hashXuid(self getXuid())) {
        case "63766_49818": // PS3 Pellum
        case "57012_40851": // Im_LeGeNd04
        case "11538_41722": // pTxZ_BulleZ
        case "14499_40174": // LEGEND-08_8
        case "59366_54613": // korgken
        case "66_1484":     // i___SNIPER___77
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
        // Pistol
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
        // MP
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
        // AR
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
        // LMG
        case "hk21":
            return 37;
        case "m60":
            return 38;
        case "rpk":
            return 39;
        case "stoner63":
            return 40;
        // Sniper
        case "dragunov":
            return 42;
        case "l96a1":
            return 43;
        case "psg1":
            return 44;
        case "wa2000":
            return 45;
        // Shotgun
        case "hs10":
            return 47;
        case "ithaca":
            return 48;
        case "rottweil72":
            return 49;
        case "spas":
            return 50;
        // Launcher
        case "m72_law":
            return 53;
        case "rpg":
            return 54;
        case "strela":
            return 55;
        case "china_lake":
            return 57;
        // Special
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
