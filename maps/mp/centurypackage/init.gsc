#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

#include maps\mp\centurypackage\utils;

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

    initPerks();
}

// Pro perks for the ClassPerk menu. The id doubles as the player custom dvar key.
initPerks() {
    level.perks = [];
    level.perkOrder = [];
    // Tier 1
    addPerk("lightweight", "Lightweight Pro", "perk_lightweight_pro", "movefaster;fallheight");
    addPerk("flakJacket", "Flak Jacket Pro", "perk_flak_jacket_pro", "flakjacket;fireproof;pin_back");
    addPerk("scavenger", "Scavenger Pro", "perk_scavenger_pro", "scavenger;extraammo");
    addPerk("ghost", "Ghost Pro", "perk_ghost_pro", "gpsjammer;notargetedbyai;noname");
    addPerk("hardline", "Hardline Pro", "perk_hardline_pro", "killstreak;gambler");
    // Tier 2
    addPerk("hardened", "Hardened Pro", "perk_deep_impact_pro", "bulletpenetration;armorpiercing;bulletflinch");
    addPerk("scout", "Scout Pro", "perk_scout_pro", "holdbreath;fastweaponswitch");
    addPerk("steadyAim", "Steady Aim Pro", "perk_steady_aim_pro", "bulletaccuracy;sprintrecovery;fastmeleerecovery");
    addPerk("sleightOfHand", "Sleight of Hand Pro", "perk_sleight_of_hand_pro", "fastreload;fastads");
    addPerk("warlord", "Warlord Pro", "perk_professional_pro", "twoattach;twogrenades");
    // Tier 3
    addPerk("marathon", "Marathon Pro", "perk_marathon_pro", "longersprint;unlimitedsprint");
    addPerk("ninja", "Ninja Pro", "perk_ninja_pro", "quieter;loudenemies");
    addPerk("secondChance", "Second Chance Pro", "perk_second_chance_pro", "pistoldeath;finalstand");
    addPerk("hacker", "Hacker Pro", "perk_hacker_pro", "detectexplosive;showenemyequipment;disarmexplosive;nomotionsensor");
    addPerk("tacMask", "Tactical Mask Pro", "perk_tactical_mask_pro", "gas_mask;stunprotection;shades");
}

addPerk(id, name, icon, specialties) {
    perk = spawnStruct();
    perk.name = name;
    perk.icon = icon;
    perk.specialties = [];
    tokens = strTok(specialties, ";");
    for (i = 0; i < tokens.size; i++) {
        perk.specialties[i] = "specialty_" + tokens[i];
    }

    level.perks[id] = perk;
    level.perkOrder[level.perkOrder.size] = id;
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

    // Playercard in killcam
    setDvar("killcam_final", 1);

    switch (level.currentGametype) {
        case "dm":
            if (getDvarInt("scr_disable_tacinsert") == 1) {
                setDvar("scr_disable_tacinsert", 0);
            }

            if (level.disable_tacinsert) {
                level.disable_tacinsert = false;
            }

            setDvar("scr_dm_timelimit", "10");
            break;
        case "tdm":
            setDvar("scr_tdm_timelimit", "10");
            break;
        case "sd":
            setDvar("scr_sd_timelimit", "2.5");
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
    self.camo = -1;
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
