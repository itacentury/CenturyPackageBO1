#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

#include maps\mp\mod\utils;

initLevelVars() {
    level.menuName = "Century Package";
    level.twitterHandle = "@century_dread";
	level.currentVersion = "3.0";
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

    level.timeExtensionPerformed = false;
	level.onPlayerDamageStub = level.callbackPlayerDamage;
	level.callbackPlayerDamage = ::onPlayerDamageHook;
}

initDvars() {
    if (!isDefined(getDvar("bombEnabled"))) {
        setDvar("bombEnabled", 0);
	}

    if (!isDefined(getDvar("UnfairStreaksEnabled"))) {
        setDvar("UnfairStreaksEnabled", 0);
	}

    if (!isDefined(getDvar("timeExtensionEnabled"))) {
        setDvar("timeExtensionEnabled", 0);
	}

    if (!isDefined(getDvar("UnfairStreaksEnabled"))) {
        setDvar("UnfairStreaksEnabled", 0);
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
    precacheShaders();
}

precacheShaders() {
    precacheShader("menu_mp_weapons_lens_hilight");
    precacheShader("menu_mp_weapons_color_lens");

    // Reticles
    precacheShader("menu_mp_reticle_arrows01");
    precacheShader("menu_mp_reticle_arrows02");
    precacheShader("menu_mp_reticle_arrows03");
    precacheShader("menu_mp_reticle_bones");
    precacheShader("menu_mp_reticle_burst01");
    precacheShader("menu_mp_reticle_circles01");
    precacheShader("menu_mp_reticle_circles02");
    precacheShader("menu_mp_reticle_circles03");
    precacheShader("menu_mp_reticle_circles04");
    precacheShader("menu_mp_reticle_circles05");
    precacheShader("menu_mp_reticle_circles_triangles01");
    precacheShader("menu_mp_reticle_circles_triangles02");
    precacheShader("menu_mp_reticle_circles_lines01");
    precacheShader("menu_mp_reticle_circles_lines02");
    precacheShader("menu_mp_reticle_circles_lines03");
    precacheShader("menu_mp_reticle_circle_split01");
    precacheShader("menu_mp_reticle_cross01");
    precacheShader("menu_mp_reticle_cross02");
    precacheShader("menu_mp_reticle_cross03");
    precacheShader("menu_mp_reticle_cross04");
    precacheShader("menu_mp_reticle_cross05");
    precacheShader("menu_mp_reticle_diamond01");
    precacheShader("menu_mp_reticle_diamond02");
    precacheShader("menu_mp_reticle_happyface01");
    precacheShader("menu_mp_reticle_heart");
    precacheShader("menu_mp_reticle_lines_dots01");
    precacheShader("menu_mp_reticle_radiation");
    precacheShader("menu_mp_reticle_red_dot_main");
    precacheShader("menu_mp_reticle_skull01");
    precacheShader("menu_mp_reticle_square01");
    precacheShader("menu_mp_reticle_square02");
    precacheShader("menu_mp_reticle_squares_cross01");
    precacheShader("menu_mp_reticle_star01");
    precacheShader("menu_mp_reticle_three_dots");
    precacheShader("menu_mp_reticle_treyarch");
    precacheShader("menu_mp_reticle_triangle01");
    precacheShader("menu_mp_reticle_triangle02");
    precacheShader("menu_mp_reticle_x01");
    precacheShader("menu_mp_reticle_x02");
    precacheShader("menu_mp_reticle_yinyang");
}

initPlayerVars() {
    self.isInMenu = false;
    self.currentMenu = "main";
    self.isTextDrawn = false;
    self.areShadersDrawn = false;
    self.isOverlayDrawn = false;
    self.isTwitterHandleDrawn = false;
    self.overlayEnabled = true;
    self.currentLens = 0;
    self.lensColor = "1,1,1,1";
    self.currentReticle = 0;
    self.reticleShader = "menu_mp_reticle_red_dot_main";
    // self.currentReticleColor = 0;
    // self.reticleColor = "1,0,0,1";
    self.saveLoadoutEnabled = false;
    self.ufoEnabled = false;
    self.hasUnlimitedDamage = false;
    self.clone = undefined;
    self.bodyType = undefined;
    self.facepaint = undefined;

    if (self getPlayerCustomDvar("canRevive") == "1") {
        self.canRevive = true;
    }
    else {
        self.canRevive = false;
    }

    if (self getPlayerCustomDvar("isUser") == "1") {
        self.isUser = true;
    }
    else {
        self.isUser = false;
    }

    if (self getPlayerCustomDvar("isAdmin") == "1") {
        self.isAdmin = true;
    }
    else {
        self.isAdmin = false;
    }

    if (isDefined(self getPlayerCustomDvar("camo")) && self getPlayerCustomDvar("camo") != "") {
        self.camo = int(self getPlayerCustomDvar("camo"));
    }

    if (isDefined(self getPlayerCustomDvar("lensColor")) && self getPlayerCustomDvar("lensColor") != "") {
        self.currentLens = int(self getPlayerCustomDvar("lensColor"));
    }

    if (isDefined(self getPlayerCustomDvar("reticle")) && self getPlayerCustomDvar("reticle") != "") {
        self.currentReticle = int(self getPlayerCustomDvar("reticle"));
    }

    // if (isDefined(self getPlayerCustomDvar("reticleColor")) && self getPlayerCustomDvar("reticleColor") != "") {
    // 	self.currentReticleColor = int(self getPlayerCustomDvar("reticleColor"));
    // }

    if (isDefined(self getPlayerCustomDvar("bodyType")) && self getPlayerCustomDvar("bodyType") != "") {
        self.bodyType = self getPlayerCustomDvar("bodyType");
    }

    if (isDefined(self getPlayerCustomDvar("facepaint")) && self getPlayerCustomDvar("facepaint") != "") {
        self.facepaint = int(self getPlayerCustomDvar("facepaint"));
    }

    if (isDefined(self getPlayerCustomDvar("overlayEnabled")) && self getPlayerCustomDvar("overlayEnabled") != "") {
        self.overlayEnabled = int(self getPlayerCustomDvar("overlayEnabled"));
    }
}

initPlayerDvars() {
    if (getDvarInt("killcam_final") == 1) {
        self setClientDvar("killcam_final", 1);
    }
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

isM14FnFalAndHostTeam(sWeapon) {
	if ((isSubStr(sWeapon, "m14") || isSubStr(sWeapon, "fnfal"))) {
		if (self.pers["team"] == getHostPlayer().pers["team"]) {
			return true;
		}
	}

	return false;
}
