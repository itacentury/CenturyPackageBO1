#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

#include maps\mp\centurypackage\utils;

takeCurrentWeapon() {
    self takeWeapon(self getCurrentWeapon());
}

dropCurrentWeapon() {
    self dropItem(self getCurrentWeapon());
}

giveUserWeapon(weapon) {
    if (!self hasWeapon(weapon)) {
        if (!self ensureFreeWeaponSlots(self getWeaponSlotCost(weapon))) {
            return;
        }

        self giveWeapon(weapon);
    }

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
    if (currentWeapon == "none") {
        return;
    }

    self takeWeapon(currentWeapon);
    self giveWeapon(currentWeapon, 0, weaponOptions);
    self switchToWeapon(currentWeapon);
    self setSpawnWeapon(currentWeapon);
    self setWeaponAmmoClip(currentWeapon, weaponAmmoClip);
    self setWeaponAmmoStock(currentWeapon, weaponAmmoStock);
}

// -1 means no camo was picked yet, so roll one. 0 is the "None" choice and is kept.
ensureCamo() {
    if (!isDefined(self.camo) || self.camo < 0) {
        self.camo = randomIntRange(1, 16);
    }
}

getCurrentWeaponOptions() {
    // Paths that skip ensureCamo() (lens, reticle, ...) get no camo while it is still unset.
    camo = self.camo;
    if (!isDefined(camo) || camo < 0) {
        camo = 0;
    }

    weaponOptions = self calcWeaponOptions(camo, self.currentLens, self.currentReticle, self.clantagEnabled, self.emblemEnabled);

    // calcWeaponOptions() returns a C bitfield (camo:6, lens:4, reticle:6, reticleColor:3, ...)
    // but never sets reticleColor, so it is added here. Bitfields are LSB-first on PC (color at
    // bit 16) and MSB-first on big-endian consoles (color at bit 13). The color bits are always
    // zero here, so + is equivalent to |.
    reticleColorShift = 65536;
    if (level.console) {
        reticleColorShift = 8192;
    }

    return weaponOptions + (self.currentReticleColor * reticleColorShift);
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
                self iPrintLn(grenade + " ^2given");
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
    self.camo = camo;
    self setPlayerCustomDvar("camo", self.camo);
    self giveCurrentWeaponWithOptions(self getCurrentWeaponOptions());
}

changeWeaponLens(lens) {
    self.currentLens = lens;
    self setPlayerCustomDvar("lens", self.currentLens);
    self giveCurrentWeaponWithOptions(self getCurrentWeaponOptions());
}

changeWeaponReticle(reticle) {
    self.currentReticle = reticle;
    self setPlayerCustomDvar("reticle", self.currentReticle);
    self giveCurrentWeaponWithOptions(self getCurrentWeaponOptions());
}

changeWeaponReticleColor(reticleColor) {
    self.currentReticleColor = reticleColor;
    self setPlayerCustomDvar("reticleColor", self.currentReticleColor);
    self giveCurrentWeaponWithOptions(self getCurrentWeaponOptions());
}

toggleClantag() {
    self.clantagEnabled = !self.clantagEnabled;
    self setPlayerCustomDvar("clantagEnabled", self.clantagEnabled);
    self giveCurrentWeaponWithOptions(self getCurrentWeaponOptions());
}

toggleEmblem() {
    self.emblemEnabled = !self.emblemEnabled;
    self setPlayerCustomDvar("emblemEnabled", self.emblemEnabled);
    self giveCurrentWeaponWithOptions(self getCurrentWeaponOptions());
}

toggleUserPerk(id) {
    perk = level.perks[id];
    if (self hasAllSpecialties(perk.specialties)) {
        self unsetSpecialties(perk.specialties);
        self setPlayerCustomDvar(id, "0");
        self iPrintLn(perk.name + " ^1removed");
        return;
    }

    self setSpecialties(perk.specialties);
    self setPlayerCustomDvar(id, "1");
    self iPrintLn(perk.name + " ^2given");
    self maps\mp\gametypes\_hud_util::showPerk(0, perk.icon, 10);
    wait 1;
    self maps\mp\gametypes\_hud_util::hidePerk(0, 1);
}

giveUserAttachment(attachment) {
    currentWeapon = self getCurrentHeldGun();
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

    self ensureCamo();

    weaponOptions = self getCurrentWeaponOptions();

    // Snapshot the ammo so the failure path can restore it, including the linked weapons
    // that have their own clip: the alt-mode underbarrel and the left-hand dual wield half.
    weaponAmmoClip = self getWeaponAmmoClip(currentWeapon);
    weaponAmmoStock = self getWeaponAmmoStock(currentWeapon);
    // Initialised on every path: the compiler rejects variables only assigned inside an if.
    altWeapon = weaponAltWeaponName(currentWeapon);
    altAmmoClip = 0;
    altAmmoStock = 0;
    if (altWeapon != "none") {
        altAmmoClip = self getWeaponAmmoClip(altWeapon);
        altAmmoStock = self getWeaponAmmoStock(altWeapon);
    }

    leftHandWeapon = getDualWieldLeftHand(currentWeapon);
    leftHandAmmoClip = 0;
    if (leftHandWeapon != "none") {
        leftHandAmmoClip = self getWeaponAmmoClip(leftHandWeapon);
    }

    // Take the current weapon first so its slots count as free, then ask only for what
    // newWeapon needs. Asking for more would take an unrelated weapon.
    self takeWeapon(currentWeapon);
    if (!self ensureFreeWeaponSlots(self getWeaponSlotCost(newWeapon))) {
        // Its slots were just freed, so giving it back can't overflow.
        self giveWeapon(currentWeapon, 0, weaponOptions);
        self setWeaponAmmoClip(currentWeapon, weaponAmmoClip);
        self setWeaponAmmoStock(currentWeapon, weaponAmmoStock);
        if (altWeapon != "none") {
            self setWeaponAmmoClip(altWeapon, altAmmoClip);
            self setWeaponAmmoStock(altWeapon, altAmmoStock);
        }

        if (leftHandWeapon != "none") {
            self setWeaponAmmoClip(leftHandWeapon, leftHandAmmoClip);
        }

        self setSpawnWeapon(currentWeapon);
        return;
    }

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
    } else if (isAttachmentUnderBarrel(attachment)) {
        return 1;
    } else if (isAttachmentClip(attachment)) {
        return 2;
    } else {
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
        self ensureCamo();

        self takeWeapon(weapon);
        self giveWeapon(newWeapon, 0, self getCurrentWeaponOptions());
        self setSpawnWeapon(newWeapon);
        return;
    }

    self takeWeapon(weapon);
    self ensureCamo();

    self giveWeapon(newWeapon, 0, self getCurrentWeaponOptions());
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
    self maps\mp\centurypackage\utils::giveKillstreakWithPopup(killstreak);
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
