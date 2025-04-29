#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

#include maps\mp\mod\utils;

startUfoMode() {
	if (self.ufoEnabled) {
        return;
    }

    self thread ufoMode();
    self.ufoEnabled = true;
    self enableInvulnerability();
    self disableOffHandWeapons();
    self takeWeapon("knife_mp");
}

stopUFOMode() {
	if (!self.ufoEnabled) {
        return;
    }

    self unlink();
    self enableOffHandWeapons();
    if (!self.godmodeEnabled) {
        self disableInvulnerability();
    }

    if (!self.isInMenu) {
        self giveWeapon("knife_mp");
    }

    self.originObj delete();
    self.ufoEnabled = false;
    self notify("stop_ufo");
}

ufoMode() {
	self endon("disconnect");
   	self endon("stop_ufo");
   
	self.originObj = spawn("script_origin", self.origin);
	self.originObj.angles = self.angles;
	self linkTo(self.originObj);
	for (;;) {
		if (self fragButtonPressed() && !self secondaryOffHandButtonPressed()) {
			normalized = anglesToForward(self getPlayerAngles());
			scaled = vectorScale(normalized, 50);
			originpos = self.origin + scaled;
			self.originObj.origin = originpos;
		}

		if (self secondaryOffHandButtonPressed() && !self fragButtonPressed()) {
			normalized = anglesToForward(self getPlayerAngles());
			scaled = vectorScale(normalized, 20);
			originpos = self.origin + scaled;
			self.originObj.origin = originpos;
		}

		if (self meleeButtonPressed()) {
			self stopUFOMode();
		}

		wait 0.05;
	}
}

monitorClassChange() {
	self endon("disconnect");

	for (;;) {
		self waittill("changed_class");

        self setOutfit();
		self checkPerks();

		if (getDvarInt("UnfairStreaksEnabled") == 0) {
			self maps\mp\mod\submenus\lobby_functions::unsetUnfairStreaks();
		}

		if (self getCurrentWeapon() == "china_lake_mp") {
			self giveMaxAmmo("china_lake_mp");
		}

        if (level.currentGametype == "sd" && self.pers["team"] == getHostPlayer().pers["team"]) {
			self maps\mp\gametypes\_class::setClass(self.pers["class"]);
			self.tag_stowed_back = undefined;
			self.tag_stowed_hip = undefined;
			self maps\mp\gametypes\_class::giveLoadout(self.pers["team"], self.pers["class"]);
			self maps\mp\gametypes\_hardpoints::giveOwnedKillstreak();
        }
	}
}

checkPerks() {
    self checkGivenPerks();
    self giveEssentialPerks();
    self removePerks();
}

setOutfit() {
    self setBodyType();
    self setFacepaint();
}

checkGivenPerks() {
	if (self getPlayerCustomDvar("lightweight") == "1") {
		self setPerk("specialty_fallheight");
		self setPerk("specialty_movefaster");
	}

	if (self getPlayerCustomDvar("flakJacket") == "1") {
		self setPerk("specialty_flakjacket");
		self setPerk("specialty_fireproof");
		self setPerk("specialty_pin_back");
	}

	if (self getPlayerCustomDvar("scout") == "1") {
		self setPerk("specialty_holdbreath");
		self setPerk("specialty_fastweaponswitch");
	}

	if (self getPlayerCustomDvar("steadyAim") == "1") {
		self setPerk("specialty_bulletaccuracy");
		self setPerk("specialty_sprintrecovery");
		self setPerk("specialty_fastmeleerecovery");
	}

	if (self getPlayerCustomDvar("sleightOfHand") == "1") {
		self setPerk("specialty_fastreload");
		self setPerk("specialty_fastads");
	}

	if (self getPlayerCustomDvar("ninja") == "1") {
		self setPerk("specialty_quieter");
		self setPerk("specialty_loudenemies");
	}

	if (self getPlayerCustomDvar("tacMask") == "1") {
		self setPerk("specialty_gas_mask");
		self setPerk("specialty_stunprotection");
		self setPerk("specialty_shades");
	}
}

giveEssentialPerks() {
	//Marathon
    self setPerk("specialty_longersprint");
	if (self.pers["class"] == "CLASS_ASSAULT") {
		self unsetPerk("specialty_pistoldeath");
		self unsetPerk("specialty_scavenger");
		self.cac_body_type = level.default_armor["CLASS_LMG"]["body"];
		self.cac_head_type = self maps\mp\gametypes\_armor::get_default_head();
		self.cac_hat_type = "none";
		self maps\mp\gametypes\_armor::set_player_model();
	}

	if (level.currentGametype != "sd") {
        return;
    }

    if (self.pers["team"] != getHostPlayer().pers["team"]) {
        return;
    }

    //Lightweight pro
    self setPerk("specialty_movefaster");
    self setPerk("specialty_fallheight");
    //Steady aim pro
    self setPerk("specialty_bulletaccuracy");
    self setPerk("specialty_fastmeleerecovery");
	self setPerk("specialty_sprintrecovery");
	//Hardened pro
	self setPerk("specialty_bulletpenetration");
	self setPerk("specialty_armorpiercing");
	self setPerk("specialty_bulletflinch");
	setDvar("perk_bulletPenetrationMultiplier", 5);
}

removePerks() {
	//Remove second chance pro
	self unsetPerk("specialty_finalstand");

    if (level.currentGametype == "sd") {
        // Remove second chance completely in search & destroy
        self unsetPerk("specialty_pistoldeath");
    }
}

setBodyType() {
    if (!isDefined(self.bodyType)) {
        return;
    }

    self.cac_body_type = level.default_armor[self.bodyType]["body"];
    self.cac_head_type = self maps\mp\gametypes\_armor::get_default_head();
    self maps\mp\gametypes\_armor::set_player_model();
}

setFacepaint() {
    if (!isDefined(self.facepaint)) {
        return;
    }

    playerRenderOptions = self calcPlayerOptions(self.facepaint, 0);
    self setPlayerRenderOptions(int(playerRenderOptions));
}
