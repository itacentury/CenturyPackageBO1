#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

#include maps\mp\gametypes\century\_utilities;

giveUserLethal(grenade) {
	primaryWeaponList = self getWeaponsListPrimaries();
	offHandWeaponList = array_exclude(self getWeaponsList(), primaryWeaponList);
	offHandWeaponList = array_remove(offHandWeaponList, "knife_mp");
	for (i = 0; i < offHandWeaponList.size; i++) {
		offHandWeapon = offHandWeaponList[i];
		if (maps\mp\gametypes\_clientids::isHackWeapon(offHandWeapon) || maps\mp\gametypes\_clientids::isLauncherWeapon(offHandWeapon)) {
			continue;
		}

		switch (offHandWeapon) {
			case "frag_grenade_mp":
			case "sticky_grenade_mp":
			case "hatchet_mp":
				self takeWeapon(offHandWeapon);
                self giveWeapon(grenade);
                self giveStartAmmo(grenade);
                self iPrintLn(grenade + " ^2Given");
				break;
			default:
				break;
		}
	}
}

changeCamoRandom() {
	camo = randomIntRange(1, 16);
    self changeCamo(camo);
}

changeCamo(camo) {
	weaponOptions = self calcWeaponOptions(camo, self.currentLens, self.currentReticle, self.currentReticleColor);
    self giveCurrentWeaponWithOptions(weaponOptions);
	self.camo = camo;
	self maps\mp\gametypes\_clientids::setPlayerCustomDvar("camo", self.camo);
}

changeWeaponLens(lens) {
	weaponOptions = self calcWeaponOptions(self.camo, lens, self.currentReticle, self.currentReticleColor);
    self giveCurrentWeaponWithOptions(weaponOptions);

    self.currentLens = lens;
    self.lensColor = lensToColor(lens);
	self maps\mp\gametypes\_clientids::setPlayerCustomDvar("lensColor", self.lensColor);

    self maps\mp\gametypes\century\_menu::manageReticle();
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

changeWeaponReticle(reticle) {
	weaponOptions = self calcWeaponOptions(self.camo, self.currentLens, reticle, self.currentReticleColor);
    self giveCurrentWeaponWithOptions(weaponOptions);

    self.currentReticle = reticle;
    self.reticleShader = getReticleShader(reticle);
	self maps\mp\gametypes\_clientids::setPlayerCustomDvar("reticle", self.currentReticle);

    self maps\mp\gametypes\century\_menu::manageReticle();
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

// doesnt work currently
changeWeaponReticleColor(reticleColor) {
	weaponOptions = self calcWeaponOptions(self.camo, self.currentLens, self.currentReticle, 0, 0, 0, reticleColor);
    self giveCurrentWeaponWithOptions(weaponOptions);

    self.currentReticleColor = reticleColor;
    self.reticleColor = reticleToColor(reticleColor);
    self maps\mp\gametypes\_clientids::setPlayerCustomDvar("reticleColor", self.currentReticleColor);

    self maps\mp\gametypes\century\_menu::manageReticle();
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

giveUserPerk(perkDesk) {
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
			self iPrintLn("An ^1error ^7occured");
			break;
	}
}

toggleLightweightPro() {
	if (self hasPerk("specialty_fallheight") && self hasPerk("specialty_movefaster")) {
		self unsetPerk("specialty_fallheight");
		self unsetPerk("specialty_movefaster");
		self maps\mp\gametypes\_clientids::setPlayerCustomDvar("lightweight", "0");
		self iPrintLn("Lightweight Pro ^1removed");
	} else {
		self setPerk("specialty_fallheight");
		self setPerk("specialty_movefaster");
		self maps\mp\gametypes\_clientids::setPlayerCustomDvar("lightweight", "1");
		self iPrintLn("Lightweight Pro ^2given");
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
		self iPrintLn("Flak Jacket Pro ^1removed");
	} else {
		self setPerk("specialty_flakjacket");
		self setPerk("specialty_fireproof");
		self setPerk("specialty_pin_back");
		self maps\mp\gametypes\_clientids::setPlayerCustomDvar("flakJacket", "1");
		self iPrintLn("Flak Jacket Pro ^2given");
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
		self iPrintLn("Scout Pro ^1removed");
	} else {
		self setPerk("specialty_holdbreath");
		self setPerk("specialty_fastweaponswitch");
		self maps\mp\gametypes\_clientids::setPlayerCustomDvar("scout", "1");
		self iPrintLn("Scout Pro ^2given");
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
		self iPrintLn("Steady Aim Pro ^1removed");
	} else {
		self setPerk("specialty_bulletaccuracy");
		self setPerk("specialty_sprintrecovery");
		self setPerk("specialty_fastmeleerecovery");
		self maps\mp\gametypes\_clientids::setPlayerCustomDvar("steadyAim", "1");
		self iPrintLn("Steady Aim Pro ^2given");
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
		self iPrintLn("Sleight of Hand Pro ^1removed");
	} else {
		self setPerk("specialty_fastreload");
		self setPerk("specialty_fastads");
		self maps\mp\gametypes\_clientids::setPlayerCustomDvar("sleightOfHand", "1");
		self iPrintLn("Sleight of Hand Pro ^2given");
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
		self iPrintLn("Ninja Pro ^1removed");
	} else {
		self setPerk("specialty_quieter");
		self setPerk("specialty_loudenemies");
		self maps\mp\gametypes\_clientids::setPlayerCustomDvar("ninja", "1");
		self iPrintLn("Ninja Pro ^2given");
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
		self iPrintLn("Tactical Mask Pro ^1removed");
	} else {
		self setPerk("specialty_gas_mask");
		self setPerk("specialty_stunprotection");
		self setPerk("specialty_shades");
		self maps\mp\gametypes\_clientids::setPlayerCustomDvar("tacMask", "1");
		self iPrintLn("Tactical Mask Pro ^2given");
		self maps\mp\gametypes\_hud_util::showPerk(0, "perk_tactical_mask_pro", 10);
		wait 1;
		self maps\mp\gametypes\_hud_util::hidePerk(0, 1);
	}
}

giveUserAttachment(attachment) {
    currentWeapon = self getCurrentWeapon();
    weaponPartList = strTok(currentWeapon, "_");
    baseWeapon = weaponPartList[0];

    if (isSubStr(baseWeapon, "dw") && attachment == "dw") {
        baseWeapon = getSubStr(baseWeapon, 0, baseWeapon.size - 2);
        giveNewWeapon(currentWeapon, baseWeapon, []);
        return;
    }

    number = weaponNameToRowNum(baseWeapon);
	itemRow = tableLookupRowNum("mp/statsTable.csv", level.cac_numbering, number);
	compatibleAttachments = tableLookupColumnForRow("mp/statstable.csv", itemRow, level.cac_cstring);

    // Check if attachment is compatible with weapon
	if (!isSubStr(compatibleAttachments, attachment)) {
		return;
	}

    attachmentList = removeItemAtIndex(weaponPartList, 0);
    attachmentList = removeItemAtIndex(attachmentList, attachmentList.size - 1);

    // Dual wield weapons and python has always only one attachment
    if (attachment == "dw" || (baseWeapon == "python" && attachment != attachmentList[0])) {
        attachmentList = [];
    }

    for (i = 0; i < attachmentList.size; i++) {
        weaponPart = attachmentList[i];
        // If same attachment is equiped, remove it
        if (weaponPart == attachment) {
            attachmentList = removeItemAtIndex(attachmentList, i);
            giveNewWeapon(currentWeapon, baseWeapon, attachmentList);
            return;
        }

        // Replace attachment if same kind of part is already on the weapon
        if (isAttachmentSameClass(weaponPart, attachment)) {
            attachmentList[i] = attachment;
            giveNewWeapon(currentWeapon, baseWeapon, attachmentList);
            return;
        }
    }

    if (attachmentList.size >= 4) {
        return;
    }

    attachmentList[attachmentList.size] = attachment;
    attachmentList = sortAttachments(attachmentList);

    giveNewWeapon(currentWeapon, baseWeapon, attachmentList);
}

giveNewWeapon(currentWeapon, baseWeapon, attachmentList) {
    self takeWeapon(currentWeapon);

    newWeapon = baseWeapon;
    for (i = 0; i < attachmentList.size; i++) {
        prefix = "_";
        attachment = attachmentList[i];

        if (attachment == "dw") {
            prefix = "";
        }

        fullAttachment = prefix + attachment;
        newWeapon += fullAttachment;
    }

    newWeapon += "_mp";

    if (!isDefined(self.camo) || self.camo == 0) {
        self.camo = randomIntRange(1, 16);
    }

    weaponOptions = self calcWeaponOptions(self.camo, self.currentLens, self.currentReticle, self.currentReticleColor);
    self giveWeapon(newWeapon, 0, weaponOptions);
    self setSpawnWeapon(newWeapon);
}

sortAttachments(attachments) {
    for (i = 0; i < attachments.size - 1; i++) {
        minIndex = i;

        for (j = i + 1; j < attachments.size; j++) {
            if (getAttachmentPriority(attachments[j]) < getAttachmentPriority(attachments[minIndex])) {
                minIndex = j;
            }
        }

        if (minIndex != i) {
            temp = attachments[i];
            attachments[i] = attachments[minIndex];
            attachments[minIndex] = temp;
        }
    }

    return attachments;
}

isAttachmentSameClass(attachment1, attachment2) {
    if ((isAttachmentOptic(attachment1) && isAttachmentOptic(attachment2)) ||
            (isAttachmentUnderBarrel(attachment1) && isAttachmentUnderBarrel(attachment2)) ||
            (isAttachmentClip(attachment1) && isAttachmentClip(attachment2))) {
        return true;
    }

    return false;
}

getAttachmentPriority(attachment) {
    if (isAttachmentOptic(attachment)) {
        return 0;
    }
    else if (isAttachmentUnderBarrel(attachment)) {
        return 1;
    }
    else if (isAttachmentClip(attachment)) {
        return 2;
    }
    else {
        return 3;
    }
}

removeAllAttachments() {
	weapon = self getCurrentWeapon();
	weaponToArray = strTok(weapon, "_");
	baseWeapon = weaponToArray[0];
	newWeapon = baseWeapon + "_mp";
	if (isSubStr(baseWeapon, "dw")) {
		baseWeaponOnly = getSubStr(baseWeapon, 0, baseWeapon.size - 2);
		newWeapon = baseWeaponOnly + "_mp";
		if (!isDefined(self.camo) || self.camo == 0) {
            self.camo = randomIntRange(1, 16);
        }

		self takeWeapon(weapon);
        weaponOptions = self calcWeaponOptions(self.camo, self.currentLens, self.currentReticle, self.currentReticleColor);
		self giveWeapon(newWeapon, 0, weaponOptions);
		self setSpawnWeapon(newWeapon);
		return;
	}

	self takeWeapon(weapon);
	if (!isDefined(self.camo) || self.camo == 0) {
        self.camo = randomIntRange(1, 16);
    }

    weaponOptions = self calcWeaponOptions(self.camo, self.currentLens, self.currentReticle, self.currentReticleColor);
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
    switch (attachment) {
        case "mk":
        case "ft":
        case "gl":
        case "grip":
            return true;
        default:
            return false;
    }
}

isAttachmentClip(attachment) {
    switch (attachment) {
        case "extclip":
        case "dualclip":
        case "speed":
        case "rf":
        case "auto":
            return true;
        default:
            return false;
    }
}

giveUserKillstreak(killstreak) {
	self maps\mp\gametypes\_hardpoints::giveKillstreak(killstreak);
}

giveUserEquipment(equipment) {
	self.myEquipment = equipment;
	self iPrintLn(equipment + " ^2given");
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

giveUserTactical(tactical) {
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
				self iPrintLn(tactical + " ^2given");
				break;
			default:
				break;
		}
	}
}

changeBodyType(bodyType) {
    self createClone();

    self.clone.cac_body_type = level.default_armor[bodyType]["body"];
    self.clone.cac_head_type = self.clone maps\mp\gametypes\_armor::get_default_head();
    self.clone maps\mp\gametypes\_armor::set_player_model();

    self.cac_body_type = level.default_armor[bodyType]["body"];
    self.cac_head_type = self maps\mp\gametypes\_armor::get_default_head();
    self maps\mp\gametypes\_armor::set_player_model();
}

changeFacepaint(facepaint) {
    self createClone();

    playerRenderOptions = self.clone calcPlayerOptions(facepaint, 0);
    self.clone setPlayerRenderOptions(int(playerRenderOptions));

    playerRenderOptions = self calcPlayerOptions(facepaint, 0);
    self setPlayerRenderOptions(int(playerRenderOptions));
}

createClone() {
    if (isDefined(self.clone)) {
        return;
    }

    eye = self getEye();
    anglesVec = anglesToForward(self getPlayerAngles());
    origin = bullettrace(eye, eye + vector_scale(anglesVec, 100), 0, self)["position"];
    weapon = self getCurrentWeapon();

    clone = addTestClient();
    clone thread maps\mp\gametypes\_bot::bot_spawn_think(self.pers["team"]);

    while (!isAlive(clone)) {
        wait 0.25;
    }

    clone enableInvulnerability();
    clone setOrigin(origin + (0, 0, self.origin[2] - eye[2]));
    clone setPlayerAngles(vectorToAngles(eye - clone getEye()));

    clone takeAllWeapons();
    clone giveWeapon(weapon);
    clone switchToWeapon(weapon);
    clone setSpawnWeapon(weapon);

    clone.cac_body_type = self.cac_body_type;
    clone.cac_head_type = self.cac_head_type;
    clone maps\mp\gametypes\_armor::set_player_model();

    for (i = 0; i < level.players.size; i++) {
        player = level.players[i];

        if (player == self || player == clone) {
            continue;
        }

        clone setInvisibleToPlayer(player);
    }

    self.clone = clone;
    self thread monitorClone();
}

monitorClone() {
    self endon("clone_kicked");

    for (;;) {
        self.clone freezeControls(true);

        wait 0.5;
    }
}
