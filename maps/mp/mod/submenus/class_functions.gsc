#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

#include maps\mp\mod\utils;

takeCurrentWeapon() {
	self takeWeapon(self getCurrentWeapon());
}

dropCurrentWeapon() {
	self dropItem(self getCurrentWeapon());
}

giveUserWeapon(weapon) {
	self giveWeapon(weapon);
	self giveStartAmmo(weapon);
	self switchToWeapon(weapon);

	if (weapon == "china_lake_mp") {
		self giveMaxAmmo(weapon);
	}
}

giveCurrentWeaponWithOptions(weaponOptions) {
    currentWeapon = self getCurrentWeapon();
	weaponAmmoClip = self getWeaponAmmoClip(currentWeapon);
    weaponAmmoStock = self getWeaponAmmoStock(currentWeapon);

	self takeWeapon(currentWeapon);
	self giveWeapon(currentWeapon, 0, weaponOptions);
	self switchToWeapon(currentWeapon);
	self setSpawnWeapon(currentWeapon);
	self setWeaponAmmoClip(currentWeapon, weaponAmmoClip);
    self setWeaponAmmoStock(currentWeapon, weaponAmmoStock);
}

giveUserLethal(grenade) {
	primaryWeaponList = self getWeaponsListPrimaries();
	offHandWeaponList = array_exclude(self getWeaponsList(), primaryWeaponList);
	offHandWeaponList = array_remove(offHandWeaponList, "knife_mp");
	for (i = 0; i < offHandWeaponList.size; i++) {
		offHandWeapon = offHandWeaponList[i];
		if (isHackWeapon(offHandWeapon) || isLauncherWeapon(offHandWeapon)) {
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
	weaponOptions = self calcWeaponOptions(camo, self.currentLens, self.currentReticle, 0);
    self giveCurrentWeaponWithOptions(weaponOptions);
	self.camo = camo;
	self setPlayerCustomDvar("camo", self.camo);
}

changeWeaponLens(lens) {
	weaponOptions = self calcWeaponOptions(self.camo, lens, self.currentReticle, 0);
    self giveCurrentWeaponWithOptions(weaponOptions);

    self.currentLens = lens;
    self.lensColor = lensToColor(lens);
	self setPlayerCustomDvar("lensColor", self.lensColor);

    self maps\mp\mod\hud::manageReticle();
}

changeWeaponReticle(reticle) {
	weaponOptions = self calcWeaponOptions(self.camo, self.currentLens, reticle, 0);
    self giveCurrentWeaponWithOptions(weaponOptions);

    self.currentReticle = reticle;
    self.reticleShader = getReticleShader(reticle);
	self setPlayerCustomDvar("reticle", self.currentReticle);

    self maps\mp\mod\hud::manageReticle();
}

// doesnt work currently
changeWeaponReticleColor(reticleColor) {
	weaponOptions = self calcWeaponOptions(self.camo, self.currentLens, self.currentReticle, 0, 0, 0, reticleColor);
    self giveCurrentWeaponWithOptions(weaponOptions);

    self.currentReticleColor = reticleColor;
    self.reticleColor = reticleToColor(reticleColor);
    self setPlayerCustomDvar("reticleColor", self.currentReticleColor);

    self maps\mp\mod\hud::manageReticle();
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
			self iPrintLn("^1Perk not implemented.");
			break;
	}
}

toggleLightweightPro() {
	if (self hasPerk("specialty_fallheight") && self hasPerk("specialty_movefaster")) {
		self unsetPerk("specialty_fallheight");
		self unsetPerk("specialty_movefaster");
		self setPlayerCustomDvar("lightweight", "0");
		self iPrintLn("Lightweight Pro ^1removed");
	} else {
		self setPerk("specialty_fallheight");
		self setPerk("specialty_movefaster");
		self setPlayerCustomDvar("lightweight", "1");
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
		self setPlayerCustomDvar("flakJacket", "0");
		self iPrintLn("Flak Jacket Pro ^1removed");
	} else {
		self setPerk("specialty_flakjacket");
		self setPerk("specialty_fireproof");
		self setPerk("specialty_pin_back");
		self setPlayerCustomDvar("flakJacket", "1");
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
		self setPlayerCustomDvar("scout", "0");
		self iPrintLn("Scout Pro ^1removed");
	} else {
		self setPerk("specialty_holdbreath");
		self setPerk("specialty_fastweaponswitch");
		self setPlayerCustomDvar("scout", "1");
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
		self setPlayerCustomDvar("steadyAim", "0");
		self iPrintLn("Steady Aim Pro ^1removed");
	} else {
		self setPerk("specialty_bulletaccuracy");
		self setPerk("specialty_sprintrecovery");
		self setPerk("specialty_fastmeleerecovery");
		self setPlayerCustomDvar("steadyAim", "1");
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
		self setPlayerCustomDvar("sleightOfHand", "0");
		self iPrintLn("Sleight of Hand Pro ^1removed");
	} else {
		self setPerk("specialty_fastreload");
		self setPerk("specialty_fastads");
		self setPlayerCustomDvar("sleightOfHand", "1");
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
		self setPlayerCustomDvar("ninja", "0");
		self iPrintLn("Ninja Pro ^1removed");
	} else {
		self setPerk("specialty_quieter");
		self setPerk("specialty_loudenemies");
		self setPlayerCustomDvar("ninja", "1");
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
		self setPlayerCustomDvar("tacMask", "0");
		self iPrintLn("Tactical Mask Pro ^1removed");
	} else {
		self setPerk("specialty_gas_mask");
		self setPerk("specialty_stunprotection");
		self setPerk("specialty_shades");
		self setPlayerCustomDvar("tacMask", "1");
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

    weaponOptions = self calcWeaponOptions(self.camo, self.currentLens, self.currentReticle, 0);
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
        weaponOptions = self calcWeaponOptions(self.camo, self.currentLens, self.currentReticle, 0);
		self giveWeapon(newWeapon, 0, weaponOptions);
		self setSpawnWeapon(newWeapon);
		return;
	}

	self takeWeapon(weapon);
	if (!isDefined(self.camo) || self.camo == 0) {
        self.camo = randomIntRange(1, 16);
    }

    weaponOptions = self calcWeaponOptions(self.camo, self.currentLens, self.currentReticle, 0);
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

    self.bodyType = bodyType;
	self setPlayerCustomDvar("bodyType", self.bodyType);
}

changeFacepaint(facepaint) {
    self createClone();

    playerRenderOptions = self.clone calcPlayerOptions(facepaint, 0);
    self.clone setPlayerRenderOptions(int(playerRenderOptions));

    playerRenderOptions = self calcPlayerOptions(facepaint, 0);
    self setPlayerRenderOptions(int(playerRenderOptions));

    self.facepaint = facepaint;
	self setPlayerCustomDvar("facepaint", self.facepaint);
}

createClone() {
    if (isDefined(self.clone)) {
        return;
    }

    eye = self getEye();
    anglesVec = anglesToForward(self getPlayerAngles());
    origin = bullettrace(eye, eye + vector_scale(anglesVec, 100), 0, self)["position"];
    origin = (origin[0], origin[1], self.origin[2]);
    weapon = self getCurrentWeapon();

    clone = addTestClient();
    clone thread maps\mp\gametypes\_bot::bot_spawn_think(self.pers["team"]);

    while (!isAlive(clone)) {
        wait 0.25;
    }

    clone enableInvulnerability();
    clone setOrigin(origin);
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
