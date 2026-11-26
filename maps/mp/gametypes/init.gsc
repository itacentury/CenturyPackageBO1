#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

#include maps\mp\gametypes\utils;

initLevelVars() {
    level.menuName = "The Century Package";
    level.twitterHandle = "@Zxckerschlecken";
	level.currentGametype = getDvar("g_gametype");
	level.currentMapName = getDvar("mapName");
    level.visibleOptions = 8;

    level.xAxis = 0;
	if (level.console) {
		level.yAxis = 165;
        level.yAxisOverlayPlacement = 434;
	} else {
		level.yAxis = 200;
        level.yAxisOverlayPlacement = 474;
	}

    level.unlimitedSniperDmg = false;
	if (level.currentGametype == "sd" || level.currentGametype == "dm") {
		level.unlimitedSniperDmg = true;
	}

	level.onPlayerDamageStub = level.callbackPlayerDamage;
	level.callbackPlayerDamage = ::onPlayerDamageHook;

    level.onForfeit = ::noForfeit;
}

initDvars() {
    if (getDvar("bombEnabled") == "") {
        setDvar("bombEnabled", 0);
	}

    if (getDvar("UnfairStreaksEnabled") == "") {
        setDvar("UnfairStreaksEnabled", 0);
	}

    if (getDvar("timeExtensionEnabled") == "") {
        setDvar("timeExtensionEnabled", 0);
	}

    //Playercard in killcam
    setDvar("killcam_final", 1);

    switch (level.currentGametype) {
		case "dm": {
			if (getDvarInt("scr_disable_tacinsert") == 1) {
				setDvar("scr_disable_tacinsert", 0);
			}

			if (level.disable_tacinsert) {
				level.disable_tacinsert = false;
			}

			setDvar("scr_" + level.currentGametype + "_timelimit", "10");
		}
			break;
		case "tdm": {
			setDvar("scr_" + level.currentGametype + "_timelimit", "10");
		}
			break;
		case "sd": {
			setDvar("scr_" + level.currentGametype + "_timelimit", "2.5");
		}
			break;
		default:
			break;
	}
}

initClassOverrides() {
    level.defaultClass = "CLASS_SMG";
	modifyDefaultLoadout("CLASS_ASSAULT", "enfield_mp", "m1911_mp", "frag_grenade_mp", "tabun_gas_mp", "", "specialty_flakjacket", "specialty_bulletaccuracy", "specialty_gas_mask");
	maps\mp\gametypes\_class::cac_init();
	maps\mp\gametypes\_class::getCacDataGroup(5, 10);
}

modifyDefaultLoadout(class, primary, secondary, lethal, tactical, equipment, p1, p2, p3) {
    level.classWeapons["axis"][class][0] = primary;
    level.classSidearm["axis"][class] = secondary;
    level.classWeapons["allies"][class][0] = primary;
    level.classSidearm["allies"][class] = secondary;
    level.classGrenades[class]["primary"]["type"] = lethal;
    level.classGrenades[class]["primary"]["count"] = 1;
    level.classGrenades[class]["secondary"]["type"] = tactical;
    level.classGrenades[class]["secondary"]["count"] = 2;
    level.default_equipment[class]["type"] = equipment;
    level.default_equipment[class]["count"] = 1;
    modifyDefaultPerks(class, p1, 0);
    modifyDefaultPerks(class, p2, 1);
    modifyDefaultPerks(class, p3, 2);
}

modifyDefaultPerks(class, perkRef, currentSpecialty) {
    specialty = level.perkReferenceToIndex[perkRef];            
    specialties[currentSpecialty] = maps\mp\gametypes\_class::validatePerk(specialty, currentSpecialty);
    maps\mp\gametypes\_class::storeDefaultSpecialtyData(class, specialties[currentSpecialty]);
    level.default_perkIcon[class][currentSpecialty] = level.tbl_PerkData[specialty]["reference_full"];
}

precacheStuff() {
    precacheModel("t5_weapon_cz75_dw_lh_world");
}

initPlayerVars() {
    self.isInMenu = false;
    self.currentMenu = "main";
    self.isTextDrawn = false;
    self.areShadersDrawn = false;
    self.isOverlayDrawn = false;
    self.isTwitterHandleDrawn = false;
    self.overlayEnabled = true;
    self.camo = 0;
    self.currentLens = 0;
    self.currentReticle = 0;
    self.currentReticleColor = 0;
    self.clantagEnabled = 0;
    self.emblemEnabled = 0;
    self.saveLoadoutEnabled = false;
    self.ufoEnabled = false;
    self.hasUnlimitedDamage = false;
    self.clone = undefined;
    self.bodyType = undefined;
    self.facepaint = undefined;
    self.isHidden = false;
    self.canRevive = false;
    self.isUser = false;
    self.isAdmin = false;

    if (self getPlayerCustomDvar("canRevive") == "1") {
        self.canRevive = true;
    }

    if (self getPlayerCustomDvar("isUser") == "1") {
        self.isUser = true;
    }

    if (self getPlayerCustomDvar("isAdmin") == "1") {
        self.isAdmin = true;
    }

    if (self getPlayerCustomDvar("camo") != "") {
        self.camo = int(self getPlayerCustomDvar("camo"));
    }

    if (self getPlayerCustomDvar("lens") != "") {
        self.currentLens = int(self getPlayerCustomDvar("lens"));
    }

    if (self getPlayerCustomDvar("reticle") != "") {
        self.currentReticle = int(self getPlayerCustomDvar("reticle"));
    }

    if (self getPlayerCustomDvar("reticleColor") != "") {
     	self.currentReticleColor = int(self getPlayerCustomDvar("reticleColor"));
    }

    if (self getPlayerCustomDvar("clantagEnabled") != "") {
     	self.clantagEnabled = int(self getPlayerCustomDvar("clantagEnabled"));
    }

    if (self getPlayerCustomDvar("emblemEnabled") != "") {
     	self.emblemEnabled = int(self getPlayerCustomDvar("emblemEnabled"));
    }

    if (self getPlayerCustomDvar("bodyType") != "") {
        self.bodyType = self getPlayerCustomDvar("bodyType");
    }

    if (self getPlayerCustomDvar("facepaint") != "") {
        self.facepaint = int(self getPlayerCustomDvar("facepaint"));
    }

    if (self getPlayerCustomDvar("overlayEnabled") != "") {
        self.overlayEnabled = int(self getPlayerCustomDvar("overlayEnabled"));
    }

    if (self getPlayerCustomDvar("isHidden") != "") {
        self.isHidden = int(self getPlayerCustomDvar("isHidden"));
    }
}

initPlayerDvars() {
    self setClientDvar("killcam_final", 1);
}

onPlayerDamageHook(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime) {
	if (sMeansOfDeath != "MOD_TRIGGER_HURT" && sMeansOfDeath != "MOD_FALLING" && sMeansOfDeath != "MOD_SUICIDE") {
		if (maps\mp\gametypes\_missions::getWeaponClass(sWeapon) == "weapon_sniper" || eAttacker isM14FnFalAndHostTeam(sWeapon)) {
			if (level.currentGametype == "sd" || level.currentGametype == "dm" || level.unlimitedSniperDmg || eAttacker.hasUnlimitedDamage) {
				iDamage = 10000000;
			}
		}

        if (level.currentGametype == "sd") {
            if (sMeansOfDeath == "MOD_GRENADE_SPLASH" || sMeansOfDeath == "MOD_PROJECTILE_SPLASH") {
                iDamage = 1;
            }
        }
	}

	[[level.onPlayerDamageStub]](eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
}

// Replaces default_onForfeit so games never end (or announce) when a team is empty
noForfeit(team) {}

isM14FnFalAndHostTeam(sWeapon) {
	if ((isSubStr(sWeapon, "m14") || isSubStr(sWeapon, "fnfal"))) {
		if (self.pers["team"] == getHostPlayer().pers["team"]) {
			return true;
		}
	}

	return false;
}
