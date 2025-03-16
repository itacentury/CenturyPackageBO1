#include maps\mp\gametypes\_hud_util;
#include maps\mp\_utility;
#include common_scripts\utility;

giveGrenade(grenade) {
	primaryWeapons = self getWeaponsListPrimaries();
	offHandWeapons = array_exclude(self getWeaponsList(), primaryWeapons);
	offHandWeapons = array_remove(offHandWeapons, "knife_mp");
	for (i = 0; i < offHandWeapons.size; i++) {
		weapon = offHandWeapons[i];
		if (maps\mp\gametypes\_clientids::isHackWeapon(weapon) || maps\mp\gametypes\_clientids::isLauncherWeapon(weapon)) {
			continue;
		}

		switch (weapon) {
			case "frag_grenade_mp":
			case "sticky_grenade_mp":
			case "hatchet_mp":
				self takeWeapon(weapon);
				self giveWeapon(grenade);
				self giveStartAmmo(grenade);
				self iprintln(grenade + " ^2Given");
				break;
			default:
				break;
		}
	}
}

changeCamoRandom() {
	camo = randomIntRange(1, 16);
	weap = self getCurrentWeapon();
	weapAmmoClip = self getWeaponAmmoClip(weap);
    weapAmmoStock = self getWeaponAmmoStock(weap);
	self takeWeapon(weap);
	weaponOptions = self calcWeaponOptions(camo, 0, 0, 0, 0);
	self giveWeapon(weap, 0, weaponOptions);
	self switchToWeapon(weap);
	self setSpawnWeapon(weap);
	self setWeaponAmmoClip(weap, weapAmmoClip);
    self setWeaponAmmoStock(weap, weapAmmoStock);
	self.camo = camo;
	self maps\mp\gametypes\_clientids::setPlayerCustomDvar("camo", self.camo);
}

changeCamo(num) {
	weap = self getCurrentWeapon();
	weapAmmoClip = self getWeaponAmmoClip(weap);
    weapAmmoStock = self getWeaponAmmoStock(weap);
	self takeWeapon(weap);
	weaponOptions = self calcWeaponOptions(num, 0, 0, 0, 0);
	self giveWeapon(weap, 0, weaponOptions);
	self switchToWeapon(weap);
	self setSpawnWeapon(weap);
	self setWeaponAmmoClip(weap, weapAmmoClip);
    self setWeaponAmmoStock(weap, weapAmmoStock);
	self.camo = num;
	self maps\mp\gametypes\_clientids::setPlayerCustomDvar("camo", self.camo);
}

givePlayerPerk(perkDesk) {
	switch (perkDesk) {
		case "lightweightPro":
			self toggleLightweightPro();
			break;
		case "flakJacketPro":
			self toggleFlakJacketPro();
			break;
		case "scoutPro":
			self toggleScoutPro();
			break;
		case "steadyAimPro":
			self toggleSteadyAimPro();
			break;
		case "sleightOfHandPro":
			self toggleSleightOfHandPro();
			break;
		case "ninjaPro":
			self toggleNinjaPro();
			break;
		case "tacticalMaskPro":
			self toggleTacticalMaskPro();
			break;
		default:
			self iprintln("An ^1error ^7occured");
			break;
	}
}

toggleLightweightPro() {
	if (self hasPerk("specialty_fallheight") && self hasPerk("specialty_movefaster")) {
		self unsetPerk("specialty_fallheight");
		self unsetPerk("specialty_movefaster");
		self maps\mp\gametypes\_clientids::setPlayerCustomDvar("lightweight", "0");
		self iprintln("Lightweight Pro ^1removed");
	}
	else {
		self setPerk("specialty_fallheight");
		self setPerk("specialty_movefaster");
		self maps\mp\gametypes\_clientids::setPlayerCustomDvar("lightweight", "1");
		self iprintln("Lightweight Pro ^2given");
		self maps\mp\gametypes\_hud_util::showPerk(0, "perk_lightweight_pro", 10);
		wait 1;
		self maps\mp\gametypes\_hud_util::hidePerk(0, 1);
	}
}

toggleFlakJacketPro() {
	if (self hasPerk("specialty_flakjacket") && self hasPerk("specialty_fireproof") && self hasPerk("specialty_pin_back")) {
		self unsetPerk("specialty_flakjacket");
		self unsetPerk("specialty_fireproof");
		self unsetPerk("specialty_pin_back");
		self maps\mp\gametypes\_clientids::setPlayerCustomDvar("flakJacket", "0");
		self iprintln("Flak Jacket Pro ^1removed");
	}
	else {
		self setPerk("specialty_flakjacket");
		self setPerk("specialty_fireproof");
		self setPerk("specialty_pin_back");
		self maps\mp\gametypes\_clientids::setPlayerCustomDvar("flakJacket", "1");
		self iprintln("Flak Jacket Pro ^2given");
		self maps\mp\gametypes\_hud_util::showPerk(0, "perk_flak_jacket_pro", 10);
		wait 1;
		self maps\mp\gametypes\_hud_util::hidePerk(0, 1);
	}
}

toggleScoutPro() {
	if (self hasPerk("specialty_holdbreath") && self hasPerk("specialty_fastweaponswitch")) {
		self unsetPerk("specialty_holdbreath");
		self unsetPerk("specialty_fastweaponswitch");
		self maps\mp\gametypes\_clientids::setPlayerCustomDvar("scout", "0");
		self iprintln("Scout Pro ^1removed");
	}
	else {
		self setPerk("specialty_holdbreath");
		self setPerk("specialty_fastweaponswitch");
		self maps\mp\gametypes\_clientids::setPlayerCustomDvar("scout", "1");
		self iprintln("Scout Pro ^2given");
		self maps\mp\gametypes\_hud_util::showPerk(0, "perk_scout_pro", 10);
		wait 1;
		self maps\mp\gametypes\_hud_util::hidePerk(0, 1);
	}
}

toggleSteadyAimPro() {
	if(self hasPerk("specialty_bulletaccuracy") && self hasPerk("specialty_sprintrecovery") && self hasPerk("specialty_fastmeleerecovery")) {
		self unsetPerk("specialty_bulletaccuracy");
		self unsetPerk("specialty_sprintrecovery");
		self unsetPerk("specialty_fastmeleerecovery");
		self maps\mp\gametypes\_clientids::setPlayerCustomDvar("steadyAim", "0");
		self iprintln("Steady Aim Pro ^1removed");
	}
	else {
		self setPerk("specialty_bulletaccuracy");
		self setPerk("specialty_sprintrecovery");
		self setPerk("specialty_fastmeleerecovery");
		self maps\mp\gametypes\_clientids::setPlayerCustomDvar("steadyAim", "1");
		self iprintln("Steady Aim Pro ^2given");
		self maps\mp\gametypes\_hud_util::showPerk(0, "perk_steady_aim_pro", 10);
		wait 1;
		self maps\mp\gametypes\_hud_util::hidePerk(0, 1);
	}
}

toggleSleightOfHandPro() {
	if (self hasPerk("specialty_fastreload") && self hasPerk("specialty_fastads")) {
		self unsetPerk("specialty_fastreload");
		self unsetPerk("specialty_fastads");
		self maps\mp\gametypes\_clientids::setPlayerCustomDvar("sleightOfHand", "0");
		self iprintln("Sleight of Hand Pro ^1removed");
	}
	else {
		self setPerk("specialty_fastreload");
		self setPerk("specialty_fastads");
		self maps\mp\gametypes\_clientids::setPlayerCustomDvar("sleightOfHand", "1");
		self iprintln("Sleight of Hand Pro ^2given");
		self maps\mp\gametypes\_hud_util::showPerk(0, "perk_sleight_of_hand_pro", 10);
		wait 1;
		self maps\mp\gametypes\_hud_util::hidePerk(0, 1);
	}
}

toggleNinjaPro() {
	if (self hasPerk("specialty_quieter") && self hasPerk("specialty_loudenemies")) {
		self unsetPerk("specialty_quieter");
		self unsetPerk("specialty_loudenemies");
		self maps\mp\gametypes\_clientids::setPlayerCustomDvar("ninja", "0");
		self iprintln("Ninja Pro ^1removed");
	}
	else {
		self setPerk("specialty_quieter");
		self setPerk("specialty_loudenemies");
		self maps\mp\gametypes\_clientids::setPlayerCustomDvar("ninja", "1");
		self iprintln("Ninja Pro ^2given");
		self maps\mp\gametypes\_hud_util::showPerk(0, "perk_ninja_pro", 10);
		wait 1;
		self maps\mp\gametypes\_hud_util::hidePerk(0, 1);
	}
}

toggleTacticalMaskPro() {
	if (self hasPerk("specialty_gas_mask") && self hasPerk("specialty_stunprotection") && self hasPerk("specialty_shades")) {
		self unsetPerk("specialty_gas_mask");
		self unsetPerk("specialty_stunprotection");
		self unsetPerk("specialty_shades");
		self maps\mp\gametypes\_clientids::setPlayerCustomDvar("tacMask", "0");
		self iprintln("Tactical Mask Pro ^1removed");
	}
	else {
		self setPerk("specialty_gas_mask");
		self setPerk("specialty_stunprotection");
		self setPerk("specialty_shades");
		self maps\mp\gametypes\_clientids::setPlayerCustomDvar("tacMask", "1");
		self iprintln("Tactical Mask Pro ^2given");
		self maps\mp\gametypes\_hud_util::showPerk(0, "perk_tactical_mask_pro", 10);
		wait 1;
		self maps\mp\gametypes\_hud_util::hidePerk(0, 1);
	}
}

givePlayerAttachment(attachment) {
    weapon = self getCurrentWeapon();
    opticAttach = "";
    underBarrelAttach = "";
    clipAttach = "";
	attachmentAttach = "";
    opticWeap = "";
    underBarrelWeap = "";
    clipWeap = "";
	attachmentWeap = "";
	weaponToArray = strTok(weapon, "_");

	for (i = 0; i < weaponToArray.size; i++) {
		if (isAttachmentOptic(weaponToArray[i])) {
			opticAttach = weaponToArray[i];
		}

		if (isAttachmentUnderBarrel(weaponToArray[i])) {
			underBarrelAttach = weaponToArray[i];
		}

		if (isAttachmentClip(weaponToArray[i])) {
			clipAttach = weaponToArray[i];
		}

        if (weaponToArray[i] != "mp" && !isAttachmentClip(weaponToArray[i]) && !isAttachmentUnderBarrel(weaponToArray[i]) && !isAttachmentOptic(weaponToArray[i]) && weaponToArray[i] != weaponToArray[0]) {
            attachmentWeap = weaponToArray[i];
        }
	}

	baseWeapon = weaponToArray[0];
	number = weaponNameToNumber(baseWeapon);
	itemRow = tableLookupRowNum("mp/statsTable.csv", level.cac_numbering, number);
	compatibleAttachments = tableLookupColumnForRow("mp/statstable.csv", itemRow, level.cac_cstring);
	if (!isSubStr(compatibleAttachments, attachment)) {
		return;
	}

	if (attachmentWeap == attachment) {
		return;
	}

	if (isSubStr(baseWeapon, "dw")) {
		baseWeapon = getSubStr(baseWeapon, 0, baseWeapon.size - 2);
	}

	if (isSubStr(attachment, "dw")) {
		newWeapon = baseWeapon + "dw_mp";
		if (isDefined(self.camo)) {
			weaponOptions = self calcWeaponOptions(self.camo, 0, 0, 0, 0);
		}
		else {
			self.camo = 15;
			weaponOptions = self calcWeaponOptions(self.camo, 0, 0, 0, 0);
		}

		self takeWeapon(weapon);
		self giveWeapon(newWeapon, 0, weaponOptions);
		self setSpawnWeapon(newWeapon);
		return;
	}

    if (isAttachmentOptic(attachment)) {
        opticWeap = attachment + "_";
    }
    else if(isAttachmentUnderBarrel(attachment)) {
        underBarrelWeap = attachment + "_";
    }
    else if(isAttachmentClip(attachment)) {
        clipWeap = attachment + "_";
    }
	else if(!isAttachmentOptic(attachment) && !isAttachmentUnderBarrel(attachment) && !isAttachmentClip(attachment)) {
		attachmentWeap = attachment + "_";
	}

	if (opticAttach == attachment) {
		opticAttach = "";
		opticWeap = "";
	}

	if (underBarrelAttach == attachment) {
		underBarrelAttach = "";
		underBarrelWeap = "";
	}

	if (clipAttach == attachment) {
		clipAttach = "";
		clipWeap = "";
	}

	if (attachmentWeap != "") {
		if (!isAttachmentOptic(attachmentWeap) && !isAttachmentUnderBarrel(attachmentWeap) && !isAttachmentClip(attachmentWeap)) {
			if (!isAttachmentOptic(attachment) && !isAttachmentUnderBarrel(attachment) && !isAttachmentClip(attachment)) {
				attachmentWeap = attachment + "_";
			}
		}
	}

	if (opticAttach != "" && opticWeap == "") {
        opticWeap = opticAttach + "_";
    }

    if (underBarrelAttach != "" && underBarrelWeap == "") {
        underBarrelWeap = underBarrelAttach + "_";
    }

    if (clipAttach != "" && clipWeap == "") {
        clipWeap = clipAttach + "_";
    }

	if (attachmentWeap != "") {
		if(!isSubStr(attachmentWeap, "_")) {
			attachmentWeap = attachmentWeap + "_";
        }
    }
	
    self takeWeapon(weapon);
	newWeapon = baseWeapon + "_" + opticWeap + underBarrelWeap + clipWeap + attachmentWeap + weaponToArray[weaponToArray.size - 1];
	if (isDefined(self.camo)) {
		weaponOptions = self calcWeaponOptions(self.camo, 0, 0, 0, 0);
	}
	else {
		self.camo = 15;
		weaponOptions = self calcWeaponOptions(self.camo, 0, 0, 0, 0);
	}

    self giveWeapon(newWeapon, 0, weaponOptions);
    self setSpawnWeapon(newWeapon);
}

removeAllAttachments() {
	weapon = self getCurrentWeapon();
	weaponToArray = strTok(weapon, "_");
	baseWeapon = weaponToArray[0];
	newWeapon = baseWeapon + "_mp";
	if (isSubStr(baseWeapon, "dw")) {
		baseWeaponOnly = getSubStr(baseWeapon, 0, baseWeapon.size - 2);
		newWeapon = baseWeaponOnly + "_mp";
		if (isDefined(self.camo)) {
			weaponOptions = self calcWeaponOptions(self.camo, 0, 0, 0, 0);
		}
		else {
			self.camo = 15;
			weaponOptions = self calcWeaponOptions(self.camo, 0, 0, 0, 0);
		}
		
		self takeWeapon(weapon);
		self giveWeapon(newWeapon, 0, weaponOptions);
		self setSpawnWeapon(newWeapon);
		return;
	}

	self takeWeapon(weapon);
	if (isDefined(self.camo)) {
		weaponOptions = self calcWeaponOptions(self.camo, 0, 0, 0, 0);
	}
	else {
		self.camo = 15;
		weaponOptions = self calcWeaponOptions(self.camo, 0, 0, 0, 0);
	}

    self giveWeapon(newWeapon, 0, weaponOptions);
	self setSpawnWeapon(newWeapon);
}

isAttachmentOptic(attachment) {
	switch (attachment) {
		case "vzoom":
		case "acog":
		case "ir":
		case "reflex":
		case "elbit":
		case "lps":
		case "upgradesight":
			return true;
		default:
			return false;
	}
}

isAttachmentUnderBarrel(attachment) {
	if (isSubStr(attachment, "mk") || isSubStr(attachment, "ft") || isSubStr(attachment, "gl") || isSubStr(attachment, "grip")) {
		return true;
	}

	return false;
}

isAttachmentClip(attachment) {
	if (isSubStr(attachment, "extclip") || isSubStr(attachment, "dualclip") || isSubStr(attachment, "speed")) {
		return true;
	}

	return false;
}

giveUserKillstreak(killstreak) {
	self maps\mp\gametypes\_hardpoints::giveKillstreak(killstreak);
}

giveUserEquipment(equipment) {
	self.myEquipment = equipment;
	self iprintln(equipment + " ^2given");
}

weaponNameToNumber(weaponName) {
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

checkGivenPerks() {
	if (self maps\mp\gametypes\_clientids::getPlayerCustomDvar("lightweight") == "1") {
		self setPerk("specialty_fallheight");
		self setPerk("specialty_movefaster");
	}

	if (self maps\mp\gametypes\_clientids::getPlayerCustomDvar("flakJacket") == "1") {
		self setPerk("specialty_flakjacket");
		self setPerk("specialty_fireproof");
		self setPerk("specialty_pin_back");
	}

	if (self maps\mp\gametypes\_clientids::getPlayerCustomDvar("scout") == "1") {
		self setPerk("specialty_holdbreath");
		self setPerk("specialty_fastweaponswitch");
	}

	if (self maps\mp\gametypes\_clientids::getPlayerCustomDvar("steadyAim") == "1") {
		self setPerk("specialty_bulletaccuracy");
		self setPerk("specialty_sprintrecovery");
		self setPerk("specialty_fastmeleerecovery");
	}

	if (self maps\mp\gametypes\_clientids::getPlayerCustomDvar("sleightOfHand") == "1") {
		self setPerk("specialty_fastreload");
		self setPerk("specialty_fastads");
	}

	if (self maps\mp\gametypes\_clientids::getPlayerCustomDvar("ninja") == "1") {
		self setPerk("specialty_quieter");
		self setPerk("specialty_loudenemies");
	}

	if (self maps\mp\gametypes\_clientids::getPlayerCustomDvar("tacMask") == "1") {
		self setPerk("specialty_gas_mask");
		self setPerk("specialty_stunprotection");
		self setPerk("specialty_shades");
	}
}

giveUserTacticals(tactical) {
	primaryList = self getWeaponsListPrimaries();
	offHandList = array_exclude(self getWeaponsList(), primaryList);
	for (i = 0; i < offHandList.size; i++) {
		weap = offHandList[i];
		switch (weap) {
			case "willy_pete_mp":
			case "tabun_gas_mp":
			case "flash_grenade_mp":
			case "concussion_grenade_mp":
			case "nightingale_mp":
				self takeWeapon(weap);
				self giveWeapon(tactical);
				self giveStartAmmo(tactical);
				self iprintln(tactical + " ^2given");
				break;
			default:
				break;
		}
	}
}
