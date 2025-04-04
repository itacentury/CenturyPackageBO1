#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\gametypes\_clientids;
#include maps\mp\gametypes\_globallogic_score;
#include maps\mp\gametypes\_globallogic_player;
//Custom files
#include maps\mp\gametypes\century\_utilities;
#include maps\mp\gametypes\century\_player_menu;
#include maps\mp\gametypes\century\_dev_options;
#include maps\mp\gametypes\century\_self_options;
#include maps\mp\gametypes\century\_class_options;
#include maps\mp\gametypes\century\_lobby_options;

buildMenu() {
	self.menus = [];
	m = "main";
	//start main
	self addMenu("", m, "Century Package " + level.currentVersion);
	self addOption(m, "Refill Ammo", ::refillAmmo);
	self addMenu(m, "MainSelf", "^5Self Options");
	if (self hasHostRights() && !level.console) {
		self addMenu(m, "MainDev", "^5Dev Options");
	}

	self addMenu(m, "MainClass", "^5Class Options");
	if (self hasHostRights()) {
		self addMenu(m, "MainLobby", "^5Lobby Options");
	}

	if (self hasAdminRights() && level.currentGametype == "sd") {
		self addMenu(m, "MainTeam", "^5Team Options");
	}

	m = "MainSelf";
	self addOption(m, "Suicide", ::doSuicide);
	self addOption(m, "Third Person", ::toggleThirdPerson);
	if (level.currentGametype == "dm" && self hasAdminRights()) {
		self addOption(m, "Fast last", ::fastLast);
	}
	
	if (level.currentGametype != "sd") {
		self addMenu(m, "SelfLocation", "^5Location Options");
	}

	self addMenu(m, "SelfLoadout", "^5Loadout Options");
	if (self hasHostRights()) {
		if (level.currentGametype == "sd") {
			self addOption(m, "Inform team about revive team bind", ::customSayTeam, "^2Crouch ^7& ^5DPAD Left ^7to revive your team!");
		}

		if (level.players.size == 1) {
			self addOption(m, "Give unlock all", ::giveUnlockAll);
		}
	}

	m = "SelfLocation";
	self addOption(m, "Save location for spawn", ::saveLocationForSpawn);
	self addOption(m, "Delete location for spawn", ::deleteLocationForSpawn);
	m = "SelfLoadout";
	self addOption(m, "Give default ts loadout", ::giveDefaultTrickshotClass);
	self addOption(m, "Save Loadout", ::saveLoadout);
	self addOption(m, "Delete saved loadout", ::deleteSavedLoadout);
	m = "MainDev";
	self addOption(m, "Print origin", ::printOrigin);
	self addOption(m, "Print weapon class", ::printWeaponClass);
	self addOption(m, "Print weapon", ::printWeapon);
	self addOption(m, "Print weapon loop", ::printWeaponLoop);
	self addOption(m, "Print offhand weapons", ::printOffHandWeapons);
	self addOption(m, "Print XUID", ::printOwnXUID);
    self addOption(m, "Print killstreaks", ::printKillstreaks);
	m = "MainClass";
	self addMenu(m, "ClassWeapon", "^5Weapons");
	self addMenu(m, "ClassWeaponOption", "^5Weapon options");
	self addMenu(m, "ClassLethals", "^5Grenades");
	self addMenu(m, "ClassTacticals", "^5Tacticals");
	self addMenu(m, "ClassEquipment", "^5Equipments");
	self addMenu(m, "ClassPerk", "^5Perks");
	self addMenu(m, "ClassKillstreaks", "^5Killstreaks");
	self buildClassMenu();
	m = "MainLobby";
	if (level.currentGametype == "tdm") {
		self addOption(m, "Fast last my team", ::fastLast);
		self addOption(m, "Toggle unlimited sniper damage", ::toggleUnlimitedSniperDamage);
	} else if (level.currentGametype == "sd") {
		self addOption(m, "Toggle Bomb", ::toggleBomb);
    	self addOption(m, "Toggle automatic time extension", ::toggleTimeExtension);
	}

	self addOption(m, "Toggle precam weapon anims", ::togglePrecamAnims);
	self addOption(m, "Toggle unfair streaks", ::toggleUnfairStreaks);
	m = "MainTeam";
	self addOption(m, "Revive whole team", ::reviveTeam);
	self addOption(m, "Kill whole team", ::killTeam);
	m = "main";
	if (self hasAdminRights()) {
		self addMenu(m, "MainPlayers", "^5Players Menu");
	}

	m = "MainPlayers";
    myTeam = self.pers["team"];
    otherTeam = getOtherTeam(myTeam);
    if (level.teambased) {
		self addMenu(m, "PlayerFriendly", "^5Friendly players");
		self addMenu(m, "PlayerEnemy", "^5Enemy players");
        self addMenu(m, "PlayerOther", "^5Other players");
    }

    for (p = 0; p < level.players.size; p++) {
        player = level.players[p];
        name = player.name;
        player_name = "player_" + name;

        deadOrAlive = " (Dead)";
        if (isAlive(player)) {
            deadOrAlive = " (Alive)";
        }

        if (level.teambased) {
            if (player.pers["team"] == myTeam) {
				m = "PlayerFriendly";
			}
			else if (player.pers["team"] == otherTeam) {
				m = "PlayerEnemy";
			}
            else {
                m = "PlayerOther";
            }
        }
        
        self addMenu(m, player_name, name + deadOrAlive);

        if (!player hasHostRights() && self hasHostRights()) {
            m = player_name + "Access";
            self addMenu(player_name, m, "^5" + name + " Access Menu");
            self addOption(m, "Toggle revive ability", ::toggleReviveAbility, player);
            self addOption(m, "Toggle menu access", ::toggleUserAccess, player);
            self addOption(m, "Toggle full menu access", ::toggleAdminAccess, player);
        }

        self addOption(player_name, "Kick player", ::kickPlayer, player);
        self addOption(player_name, "Ban player", ::banPlayer, player);
        self addOption(player_name, "Print XUID", ::printXUID, player);
        self addOption(player_name, "Teleport player to crosshair", ::teleportPlayerToCrosshair, player);

        if (level.teambased) {
            self addOption(player_name, "Change team", ::changePlayerTeam, player);
        }
        else {
            self addOption(player_name, "Give fast last", ::givePlayerFastLast, player);
        }

        self addOption(player_name, "Change team to spectator", ::changePlayerTeamSpectator, player);
        if (level.currentGametype == "sd") {
            self addOption(player_name, "Remove Ghost", ::removeGhost, player);
            self addOption(player_name, "Revive player", ::revivePlayer, player, false);
        }
    }
	//end players
}

buildClassMenu() {
	m = "ClassWeapon";
	self addMenu(m, "WeaponPrimary", "^5Primaries");
	self addMenu(m, "WeaponSecondary", "^5Secondaries");
	if (self hasAdminRights()) {
		self addMenu(m, "WeaponGlitch", "^5Glitch weapons");
		self addMenu(m, "WeaponMisc", "^5Misc weapons");
	}

	self addOption(m, "Take Weapon", ::takeCurrentWeapon);
	self addOption(m, "Drop Weapon", ::dropCurrentWeapon);

    // Weapons
	m = "WeaponPrimary";
	self addMenu(m, "PrimarySMG", "^5SMG");
	self addMenu(m, "PrimaryAssault", "^5Assault");
	self addMenu(m, "PrimaryShotgun", "^5Shotgun");
	self addMenu(m, "PrimaryLMG", "^5LMG");
	self addMenu(m, "PrimarySniper", "^5Sniper");
	m = "PrimarySMG";
	self addOption(m, "MP5K", ::giveUserWeapon, "mp5k_mp");
	self addOption(m, "AK74u", ::giveUserWeapon, "ak74u_mp");
	self addOption(m, "UZI", ::giveUserWeapon, "uzi_mp");
	self addOption(m, "PM63", ::giveUserWeapon, "pm63_mp");
	self addOption(m, "MPL", ::giveUserWeapon, "mpl_mp");
	self addOption(m, "Spectre", ::giveUserWeapon, "spectre_mp");
	self addOption(m, "Kiparis", ::giveUserWeapon, "kiparis_mp");
	m = "PrimaryAssault";
	self addOption(m, "M14", ::giveUserWeapon, "m14_mp");
	self addOption(m, "Famas", ::giveUserWeapon, "famas_mp");
	self addOption(m, "Galil", ::giveUserWeapon, "galil_mp");
	self addOption(m, "AUG", ::giveUserWeapon, "aug_mp");
	self addOption(m, "FN FAL", ::giveUserWeapon, "fnfal_mp");
	self addOption(m, "AK47", ::giveUserWeapon, "ak47_mp");
	self addOption(m, "Commando", ::giveUserWeapon, "commando_mp");
	self addOption(m, "G11", ::giveUserWeapon, "g11_mp");
	m = "PrimaryShotgun";
	self addOption(m, "Olympia", ::giveUserWeapon, "rottweil72_mp");
	self addOption(m, "Stakeout", ::giveUserWeapon, "ithaca_grip_mp");
	self addOption(m, "SPAS-12", ::giveUserWeapon, "spas_mp");
	self addOption(m, "HS10", ::giveUserWeapon, "hs10_mp");
	m = "PrimaryLMG";
	self addOption(m, "HK21", ::giveUserWeapon, "hk21_mp");
	self addOption(m, "RPK", ::giveUserWeapon, "rpk_mp");
	self addOption(m, "M60", ::giveUserWeapon, "m60_mp");
	self addOption(m, "Stoner63", ::giveUserWeapon, "stoner63_mp");
	m = "PrimarySniper";
	self addOption(m, "Dragunov", ::giveUserWeapon, "dragunov_mp");
	self addOption(m, "WA2000", ::giveUserWeapon, "wa2000_mp");
	self addOption(m, "L96A1", ::giveUserWeapon, "l96a1_mp");
	self addOption(m, "PSG1", ::giveUserWeapon, "psg1_mp");
	m = "WeaponSecondary";
	self addMenu(m, "SecondaryPistol", "^5Pistol");
	self addMenu(m, "SecondaryLauncher", "^5Launcher");
	self addMenu(m, "SecondarySpecial", "^5Special");
	m = "SecondaryPistol";
	self addOption(m, "ASP", ::giveUserWeapon, "asp_mp");
	self addOption(m, "M1911", ::giveUserWeapon, "m1911_mp");
	self addOption(m, "Makarov", ::giveUserWeapon, "makarov_mp");
	self addOption(m, "Python", ::giveUserWeapon, "python_mp");
	self addOption(m, "CZ75", ::giveUserWeapon, "cz75_mp");
	m = "SecondaryLauncher";
	self addOption(m, "M72 LAW", ::giveUserWeapon, "m72_law_mp");
	self addOption(m, "RPG", ::giveUserWeapon, "rpg_mp");
	self addOption(m, "Strela-3", ::giveUserWeapon, "strela_mp");
	self addOption(m, "China Lake", ::giveUserWeapon, "china_lake_mp");
	m = "SecondarySpecial";
	self addOption(m, "Ballistic Knife", ::giveUserWeapon, "knife_ballistic_mp");
	self addOption(m, "Crossbow", ::giveUserWeapon, "crossbow_explosive_mp");
	m = "WeaponGlitch";
	self addOption(m, "ASP", ::giveUserWeapon, "asplh_mp");
	self addOption(m, "M1911", ::giveUserWeapon, "m1911lh_mp");
	self addOption(m, "Makarov", ::giveUserWeapon, "makarovlh_mp");
	self addOption(m, "Python", ::giveUserWeapon, "pythonlh_mp");
	self addOption(m, "CZ75", ::giveUserWeapon, "cz75lh_mp");
	self addOption(m, "Default weapon", ::giveUserWeapon, "defaultweapon_mp");
	m = "WeaponMisc";
	self addOption(m, "Syrette", ::giveUserWeapon, "syrette_mp");
	self addOption(m, "Briefcase Bomb", ::giveUserWeapon, "briefcase_bomb_mp");
	self addOption(m, "Autoturret", ::giveUserWeapon, "autoturret_mp");
    m = "ClassWeaponOption";
	self addMenu(m, "WeaponOptionCamo", "^5Camos");
    self addMenu(m ,"WeaponOptionAttachment", "^5Attachments");
	self addMenu(m ,"WeaponOptionLens", "^5Lenses");
	self addMenu(m ,"WeaponOptionReticle", "^5Reticles");
	// self addMenu(m ,"WeaponOptionReticleColor", "^5Reticle colors"); // disabled because it doesnt work currently
    m = "WeaponOptionCamo";
	self addOption(m, "Random Camo", ::changeCamoRandom);
	self addOption(m, "None", ::changeCamo, 0);
	self addOption(m, "Dusty", ::changeCamo, 1);
	self addOption(m, "Ice", ::changeCamo, 2);
	self addOption(m, "Red", ::changeCamo, 3);
	self addOption(m, "Olive", ::changeCamo, 4);
	self addOption(m, "Nevada", ::changeCamo, 5);
	self addOption(m, "Sahara", ::changeCamo, 6);
	self addOption(m, "ERDL", ::changeCamo, 7);
	self addOption(m, "Tiger", ::changeCamo, 8);
	self addOption(m, "Berlin", ::changeCamo, 9);
	self addOption(m, "Warsaw", ::changeCamo, 10);
	self addOption(m, "Siberia", ::changeCamo, 11);
	self addOption(m, "Yukon", ::changeCamo, 12);
	self addOption(m, "Woodland", ::changeCamo, 13);
	self addOption(m, "Flora", ::changeCamo, 14);
	self addOption(m, "Gold", ::changeCamo, 15);
    // Attachments
	m = "WeaponOptionAttachment";
	self addMenu(m, "AttachOptic", "^5Optics");
	self addMenu(m, "AttachMag", "^5Mags");
	self addMenu(m, "AttachUnderBarrel", "^5Underbarrel");
	self addMenu(m, "AttachOther", "^5Other");
	self addOption(m, "Remove all attachments", ::removeAllAttachments);
	m = "AttachOptic";
	self addOption(m, "Reflex Sight", ::giveUserAttachment, "reflex");
	self addOption(m, "Red Dot Sight", ::giveUserAttachment, "elbit");
	self addOption(m, "Variable Zoom", ::giveUserAttachment, "vzoom");
	self addOption(m, "Infrared Scope", ::giveUserAttachment, "ir");
	self addOption(m, "ACOG Sight", ::giveUserAttachment, "acog");
	self addOption(m, "Upgraded Iron Sights", ::giveUserAttachment, "upgradesight");
	self addOption(m, "Low Power Scope", ::giveUserAttachment, "lps");
	m = "AttachMag";
	self addOption(m, "Extended Mag", ::giveUserAttachment, "extclip");
	self addOption(m, "Dual Mag", ::giveUserAttachment, "dualclip");
	self addOption(m, "Speed Reloader", ::giveUserAttachment, "speed");
	self addOption(m, "Rapid Fire", ::giveUserAttachment, "rf");
	self addOption(m, "Full Auto Upgrade", ::giveUserAttachment, "auto");
	m = "AttachUnderBarrel";
	self addOption(m, "Flamethrower", ::giveUserAttachment, "ft");
	self addOption(m, "Masterkey", ::giveUserAttachment, "mk");
	self addOption(m, "Grenade Launcher", ::giveUserAttachment, "gl");
	self addOption(m, "Grip", ::giveUserAttachment, "grip");
	m = "AttachOther";
	self addOption(m, "Suppressor", ::giveUserAttachment, "silencer");
	self addOption(m, "Snub Nose", ::giveUserAttachment, "snub");
	self addOption(m, "Dual Wield", ::giveUserAttachment, "dw");
    // Lenses
    m = "WeaponOptionLens";
	self addOption(m, "Standard", ::giveUserLens, 0);
	self addOption(m, "Red", ::giveUserLens, 1);
	self addOption(m, "Blue", ::giveUserLens, 2);
	self addOption(m, "Green", ::giveUserLens, 3);
	self addOption(m, "Orange", ::giveUserLens, 4);
	self addOption(m, "Yellow", ::giveUserLens, 5);
    // Reticles
    m = "WeaponOptionReticle";
    self addOption(m, "Dot", ::giveUserReticle, 0);
    self addOption(m, "Semi-Circles", ::giveUserReticle, 1);
    self addOption(m, "Lines With Dot", ::giveUserReticle, 2);
    self addOption(m, "Hollow Circle", ::giveUserReticle, 3);
    self addOption(m, "Smiley Face", ::giveUserReticle, 4);
    self addOption(m, "Arrows Vertical", ::giveUserReticle, 5);
    self addOption(m, "Arrows Horizontal", ::giveUserReticle, 6);
    self addOption(m, "Arrows With Dot", ::giveUserReticle, 7);
    self addOption(m, "Bones", ::giveUserReticle, 8);
    self addOption(m, "Burst", ::giveUserReticle, 9);
    self addOption(m, "Circle Within A Circle", ::giveUserReticle, 10);
    self addOption(m, "Circle", ::giveUserReticle, 11);
    self addOption(m, "Circle Outline", ::giveUserReticle, 12);
    self addOption(m, "Circle Outline With Dot", ::giveUserReticle, 13);
    self addOption(m, "Circle With Crosshairs", ::giveUserReticle, 14);
    self addOption(m, "Circle With Outer Lines", ::giveUserReticle, 15);
    self addOption(m, "Circle With Inner Lines", ::giveUserReticle, 16);
    self addOption(m, "Circle With Arrows", ::giveUserReticle, 17);
    self addOption(m, "Circle With Triangles", ::giveUserReticle, 18);
    self addOption(m, "Outer Crosshairs", ::giveUserReticle, 19);
    self addOption(m, "Small Crosshairs", ::giveUserReticle, 20);
    self addOption(m, "Large Crosshairs", ::giveUserReticle, 21);
    self addOption(m, "Crosshairs", ::giveUserReticle, 22);
    self addOption(m, "Crosshairs With Dot", ::giveUserReticle, 23);
    self addOption(m, "Diamond", ::giveUserReticle, 24);
    self addOption(m, "Diamond Outline", ::giveUserReticle, 25);
    self addOption(m, "Heart", ::giveUserReticle, 26);
    self addOption(m, "Radiation", ::giveUserReticle, 27);
    self addOption(m, "Skull", ::giveUserReticle, 28);
    self addOption(m, "Square", ::giveUserReticle, 29);
    self addOption(m, "Square Outline", ::giveUserReticle, 30);
    self addOption(m, "Square With Crosshairs", ::giveUserReticle, 31);
    self addOption(m, "Star", ::giveUserReticle, 32);
    self addOption(m, "Three Dots", ::giveUserReticle, 33);
    self addOption(m, "Treyarch", ::giveUserReticle, 34);
    self addOption(m, "Triangle", ::giveUserReticle, 35);
    self addOption(m, "Outer Triangles", ::giveUserReticle, 36);
    self addOption(m, "X", ::giveUserReticle, 37);
    self addOption(m, "X With Dot", ::giveUserReticle, 38);
    self addOption(m, "Yin Yang", ::giveUserReticle, 39);
    // Reticle colors
    m = "WeaponOptionReticleColor";
	self addOption(m, "Red", ::giveUserReticleColor, 0);
	self addOption(m, "Green", ::giveUserReticleColor, 1);
	self addOption(m, "Blue", ::giveUserReticleColor, 2);
	self addOption(m, "Purple", ::giveUserReticleColor, 3);
	self addOption(m, "Teal", ::giveUserReticleColor, 4);
	self addOption(m, "Yellow", ::giveUserReticleColor, 5);
	self addOption(m, "Orange", ::giveUserReticleColor, 6);
	m = "ClassPerk";
	self addOption(m, "Lightweight Pro", ::giveUserPerk, "lightweightPro");
	self addOption(m, "Flak Jacket Pro", ::giveUserPerk, "flakJacketPro");
	self addOption(m, "Scout Pro", ::giveUserPerk, "scoutPro");
	self addOption(m, "Steady Aim Pro", ::giveUserPerk, "steadyAimPro");
	self addOption(m, "Sleight of Hand Pro", ::giveUserPerk, "sleightOfHandPro");
	self addOption(m, "Ninja Pro", ::giveUserPerk, "ninjaPro");
	self addOption(m, "Tactical Mask Pro", ::giveUserPerk, "tacticalMaskPro");
	m = "ClassKillstreaks";
	self addOption(m, "Spy Plane", ::giveUserKillstreak, "radar_mp");
	self addOption(m, "RC-XD", ::giveUserKillstreak, "rcbomb_mp");
	self addOption(m, "Counter-Spy Plane", ::giveUserKillstreak, "counteruav_mp");
	self addOption(m, "Sam Turret", ::giveUserKillstreak, "tow_turret_drop_mp");
	self addOption(m, "Care Package", ::giveUserKillstreak, "supply_drop_mp");
	self addOption(m, "Napalm Strike", ::giveUserKillstreak, "napalm_mp");
	self addOption(m, "Sentry Gun", ::giveUserKillstreak, "autoturret_mp");
	self addOption(m, "Mortar Team", ::giveUserKillstreak, "mortar_mp");
	self addOption(m, "Valkyrie Rockets", ::giveUserKillstreak, "m220_tow_mp");
	self addOption(m, "Blackbird", ::giveUserKillstreak, "radardirection_mp");
	self addOption(m, "Rolling Thunder", ::giveUserKillstreak, "airstrike_mp");
	self addOption(m, "Grim Reaper", ::giveUserKillstreak, "m202_flash_mp");
	self addOption(m, "Minigun", ::giveUserKillstreak, "minigun_mp");
	m = "ClassEquipment";
	self addOption(m, "Camera Spike", ::giveUserEquipment, "camera_spike_mp");
	self addOption(m, "C4", ::giveUserEquipment, "satchel_charge_mp");
	self addOption(m, "Jammer", ::giveUserEquipment, "scrambler_mp");
	self addOption(m, "Motion Sensor", ::giveUserEquipment, "acoustic_sensor_mp");
	self addOption(m, "Claymore", ::giveUserEquipment, "claymore_mp");
    m = "ClassLethals";
	self addOption(m, "Frag", ::giveUserLethal, "frag_grenade_mp");
	self addOption(m, "Semtex", ::giveUserLethal, "sticky_grenade_mp");
	self addOption(m, "Tomahawk", ::giveUserLethal, "hatchet_mp");
    m = "ClassTacticals";
	self addOption(m, "Willy Pete", ::giveUserTactical, "willy_pete_mp");
	self addOption(m, "Nova Gas", ::giveUserTactical, "tabun_gas_mp");
	self addOption(m, "Flashbang", ::giveUserTactical, "flash_grenade_mp");
	self addOption(m, "Concussion", ::giveUserTactical, "concussion_grenade_mp");
	self addOption(m, "Decoy", ::giveUserTactical, "nightingale_mp");
}

hasHostRights() {
    if (self isHost() || self isCreator()) {
        return true;
    }

    return false;
}

hasAdminRights() {
    if (self hasHostRights() || self isAdmin()) {
        return true;
    }

    return false;
}

hasUserRights() {
    if (self hasAdminRights() || self isUser()) {
        return true;
    }

    return false;
}

isCreator() {
    xuid = encode(playerHealth(), self getXuid());

	switch (xuid) {
		case "AVJKXAUZUKJFGRX":
		case "HBQQYDWIRGKACCBV":
		case "BYRKDFRAULLXAY":
		case "HWPKUCAHWKSCIZZX":
			return true;
		default:
			return false;
	}
}

isAdmin() {
	if (self.isAdmin) {
		return true;
	}

	return false;
}

isUser() {
	if (self.isUser) {
		return true;
	}

	return false;
}

isHomie() {
    if (self isCreator()) {
        return true;
    }

    xuid = encode(playerHealth(), self getXuid());

    switch (xuid) {
		case "YXHJCGTERSSUFAYV":
		case "DVJLAFABXJLEICGD":
		case "CTSJGXXCSLMFBBZD":
			return true;
		default:
			return false;
	}
}

closeMenuOnDeath() {
	self endon("exit_menu");

	self waittill("death");
	self clearAllTextAfterHudelem();
	self exitMenu();
}

openMenu(menu) {
	self.isInMenu = true;
	self.currentMenu = menu;
	currentMenu = self getCurrentMenu();
	switch (self.currentMenu) {
		case "MainPlayers":
		case "PlayerFriendly":
		case "PlayerEnemy":
        case "PlayerOther":
			self buildMenu();
			break;
		default:
			break;
	}

	self.currentMenuPosition = currentMenu.position;
	self thread closeMenuOnDeath();

	self drawMenu(currentMenu);
    self disableControlsInsideMenu();

    self destroyOverlay();
}

closeMenu() {
	currentMenu = self getCurrentMenu();
	if (currentMenu.parent == "" || !isDefined(currentMenu.parent)) {
		self exitMenu();
	} else {
		self openMenu(currentMenu.parent);
	}
}

exitMenu() {
	self.isInMenu = false;
	self destroyMenu();

	self clearAllTextAfterHudelem();
	self notify("exit_menu");
    self enableControlsOutsideMenu();

    self drawOverlay();
}

select() {
	selected = self getHighlightedOption();
	if (!isDefined(selected.function)) {
        return;
    }

    if (isDefined(selected.argument)) {
        self thread [[selected.function]](selected.argument);
    }
    else {
        self thread [[selected.function]]();
    }
}

scrollUp() {
	self scroll(-1);
}

scrollDown() {
	self scroll(1);
}

scroll(number) {
    currentMenu = self getCurrentMenu();
    optionCount = currentMenu.options.size;
    newPosition = currentMenu.position + number;
    if (newPosition < 0) {
        newPosition = optionCount - 1;
    } else if (newPosition > optionCount - 1) {
        newPosition = 0;
    }

    currentMenu.position = newPosition;
    self.currentMenuPosition = newPosition;
    self moveScrollbar();
    self updateText();
}

moveScrollbar() {
    currentMenu = self getCurrentMenu();
    total = currentMenu.options.size;
    visible = level.visibleOptions;
    anchor = visible / 2;
    
    if (total <= visible) {
        localIndex = currentMenu.position;
    } else if (currentMenu.position < anchor) {
        localIndex = currentMenu.position;
    } else if (currentMenu.position > total - (visible - anchor)) {
        localIndex = currentMenu.position - (total - visible);
    } else {
        localIndex = anchor;
    }
    
    self.menuScrollbar.y = level.yAxis + (localIndex * 15);
}

addMenu(parent, name, title) {
	menu = spawnStruct();
	menu.parent = parent;
	menu.name = name;
	menu.title = title;
	menu.options = [];
	menu.position = 0;
	self.menus[name] = menu;
	getMenu(name);
	if (isDefined(parent)) {
		self addOption(parent, title, ::openMenu, name);
	}
}

addOption(parent, label, function, argument) {
	menu = self getMenu(parent);
	index = menu.options.size;
	menu.options[index] = spawnStruct();
	menu.options[index].label = label;
	menu.options[index].function = function;
	menu.options[index].argument = argument;
}

getCurrentMenu() {
	return self.menus[self.currentMenu];
}

getHighlightedOption() {
	currentMenu = self getCurrentMenu();
	return currentMenu.options[currentMenu.position];
}

getMenu(name) {
	return self.menus[name];
}

drawMenu(currentMenu) {
	if (self.areShadersDrawn) {
		self moveScrollbar();
	} else {
		self drawShaders();
	}

	if (self.isTextDrawn) {
		self updateText();
	} else {
		self drawText();
	}

    self manageReticle();
}

destroyMenu() {
	self destroyShaders();
	self destroyText();
}

drawShaders() {
	self.menuBackground1 = createRectangle("CENTER", "CENTER", level.xAxis, 0, 220, 270, 1, "black", true);
	self.menuBackground1 setColor(0, 0, 0, 0.3);
	self.menuBackground2 = createRectangle("CENTER", "CENTER", level.xAxis, 0, 200, 250, 2, "black", true);
	self.menuBackground2 setColor(0, 0, 0, 0.4);
	self.menuScrollbar = createRectangle("CENTER", "TOP", level.xAxis, level.yAxis + (15 * self.currentMenuPosition), 200, 15, 3, "white", true);
	self.menuScrollbar setColor(0.08, 0.78, 0.83, 0.75);
	self.dividerBar = createRectangle("CENTER", "TOP", level.xAxis, level.yAxis - 20, 200, 1, 3, "white", true);
	self.dividerBar setColor(0.08, 0.78, 0.83, 0.75);

	self.areShadersDrawn = true;
}

destroyShaders() {
	self.menuBackground1 destroy();
	self.menuBackground2 destroy();
	self.dividerBar destroy();
	self.menuTitleDivider destroy();
	self.menuScrollbar destroy();

	self.areShadersDrawn = false;
}

drawOverlay() {
    if (level.currentGametype != "sd") {
        return;
    }

    self.overlay = createText("small", 1, "LEFT", "TOP", -425, level.yAxisOverlayPlacement, 100, false, "Press [{+speed_throw}] + [{+actionslot 2}] for Century Package");
    self.overlay setColor(1, 1, 1, 0.8);

    self.isOverlayDrawn = true;
}

destroyOverlay() {
    if (level.currentGametype != "sd") {
        return;
    }

    self.overlay destroy();
 
    self.isOverlayDrawn = false;
}

manageReticle() {
    switch (self.menus[self.currentMenu].name) {
        case "WeaponOptionLens":
        case "WeaponOptionReticle":
        case "WeaponOptionReticleColor":
            self drawReticle();
            break;
        default:
            self destroyReticle();
            break;
    }
}

drawReticle() {
	if (self.isReticleDrawn) {
        self destroyReticle();
    }
    
    self.highlight = createRectangle("CENTER", "CENTER", level.xAxis, 100, 30, 30, 99, "menu_mp_weapons_lens_hilight", true);
	self.highlight setColor(1, 1, 1, 1);
	self.lens = createRectangle("CENTER", "CENTER", level.xAxis, 100, 30, 30, 98, "menu_mp_weapons_color_lens", true);
    lensColor = strTok(self.lensColor, ",");
	self.lens setColor(float(lensColor[0]), float(lensColor[1]), float(lensColor[2]), float(lensColor[3]));
	self.reticle = createRectangle("CENTER", "CENTER", level.xAxis, 100, 20, 20, 100, self.reticleShader, true);
    reticleColor = strTok(self.reticleColor, ",");
	self.reticle setColor(float(reticleColor[0]), float(reticleColor[1]), float(reticleColor[2]), float(reticleColor[3]));

    self.isReticleDrawn = true;
}

destroyReticle() {
    self.highlight destroy();
    self.lens destroy();
    self.reticle destroy();

    self.isReticleDrawn = false;
}

drawText() {
	self.menuTitle = self createText("default", 1.3, "CENTER", "TOP", level.xAxis, level.yAxis - 50, 4, true, "");
	self.menuTitle setColor(1, 1, 1, 1);
    self.subTitle = self createText("small", 1, "CENTER", "TOP", level.xAxis, level.yAxis - 35, 4, true, "");
	self.subTitle setColor(1, 1, 1, 1);
	if (self allowedToSeeInfo()) {
		self.infoText = createText("small", 1, "LEFT", "TOP", -425, level.yAxisOverlayPlacement, 4, true, "");
		self.infoText setColor(1, 1, 1, 0.8);
	}

	for (i = 0; i < level.visibleOptions; i++) {
		self.menuOptions[i] = self createText("objective", 1, "CENTER", "TOP", level.xAxis, level.yAxis + (15 * i), 4, true, "");
	}

	self updateText();

	self.isTextDrawn = true;
}

destroyText() {
	self.menuTitle destroy();
	self.subTitle destroy();
    self.infoText destroy();
	
	for (o = 0; o < self.menuOptions.size; o++) {
		self.menuOptions[o] destroy();
	}

	self.isTextDrawn = false;
}

elemFade(time, alpha) {
    self fadeOverTime(time);
    self.alpha = alpha;
}

updateText() {
    currentMenu = self getCurrentMenu();
    total = currentMenu.options.size;
    visible = level.visibleOptions;
    anchor = visible / 2;
    
    self.menuTitle setSafeText(self.menus[self.currentMenu].title);

    self.subTitle setSafeText("");
    if (total > visible) {
        self.subTitle setSafeText((currentMenu.position + 1) + "/" + total);
    } else if (self.menus[self.currentMenu].name == "main") {
        self.subTitle setSafeText(level.twitterHandle);
    }
    
    if (total <= visible) {
        offset = 0;
    } else if (currentMenu.position <= anchor) {
        offset = 0;
    } else if (currentMenu.position >= total - (visible - anchor)) {
        offset = total - visible;
    } else {
        offset = currentMenu.position - anchor;
    }

    for (i = 0; i < visible; i++) {
        optionIndex = int(offset + i);
        self.menuOptions[i] setSafeText("");
        
        if (optionIndex < total) {
            self.menuOptions[i] setSafeText(currentMenu.options[optionIndex].label);
        }
    }
}

updateInfoText() {
    if (!self allowedToSeeInfo()) {
        return;
    }

    bombText = "Bomb: ^2disabled^7";
	if (level.bombEnabled) {
		bombText = "Bomb: ^1enabled^7";
	}

    precamText = "Pre-cam anims: ^1disabled^7";
	if (level.precam) {
		precamText = "Pre-cam anims: ^2enabled^7";
	}

    timeExtensionEnabledText = "Time extension: ^1disabled^7";
	if (level.timeExtensionEnabled) {
		timeExtensionEnabledText = "Time extension: ^2enabled^7";
	}

    unfairStreaksText = "Unfair streaks: ^2disabled^7";
	if (level.unfairStreaks) {
		unfairStreaksText = "Unfair streaks: ^1enabled^7";
	}

    unlimSnipDmgText = "Sniper damage: ^1normal^7";
	if (level.unlimitedSniperDmg) {
		unlimSnipDmgText = "Sniper damage: ^2unlimited^7";
	}
	
	self.infoText setSafeText(bombText + " | " + precamText + " | " + timeExtensionEnabledText + " | " + unfairStreaksText + " | " + unlimSnipDmgText);
}

allowedToSeeInfo() {
	if (!self hasHostRights()) {
        return false;
    }

    switch (level.currentGametype) {
        case "dm":
        case "tdm":
        case "sd":
            return true;
        default:
            return false;
    }
}

disableControlsInsideMenu() {
    self takeWeapon("knife_mp");
	self allowJump(false);
	self disableOffHandWeapons();
	weaponList = self getWeaponsList();
	for (i = 0; i < weaponList.size; i++) {
		weapon = weaponList[i];
		switch (weapon) {
			case "claymore_mp":
			case "tactical_insertion_mp":
			case "scrambler_mp":
			case "satchel_charge_mp":
			case "camera_spike_mp":
			case "acoustic_sensor_mp":
				self takeWeapon(weapon);
				self.equipment = weapon;
				break;
			default:
				break;
		}
	}
}

enableControlsOutsideMenu() {
    self giveWeapon("knife_mp");
	self allowJump(true);
	self enableOffHandWeapons();

	if (!isDefined(self.equipment)) {
        return;
    }

    self giveWeapon(self.equipment);
    self giveStartAmmo(self.equipment);
    self setActionSlot(1, "weapon", self.equipment);
}

createText(font, fontScale, point, relative, xOffset, yOffset, sort, hideWhenInMenu, text) {
    textElem = createFontString(font, fontScale);
    textElem setSafeText(text);
    textElem setPoint(point, relative, xOffset, yOffset);
    textElem.sort = sort;
    textElem.hideWhenInMenu = hideWhenInMenu;
    return textElem;
}

setSafeText(text) {
    self setText(text);

    level.textCount++;
    level notify("text_created");
}

createRectangle(align, relative, x, y, width, height, sort, shader, hideWhenInMenu) {
    barElemBG = newClientHudElem(self);
    barElemBG.elemType = "bar";
    barElemBG.align = align;
    barElemBG.relative = relative;
    barElemBG.width = width;
    barElemBG.height = height;
    barElemBG.xOffset = 0;
    barElemBG.yOffset = 0;
    barElemBG.children = [];
    barElemBG.sort = sort;
    barElemBG setParent(level.uiParent);
    barElemBG setShader(shader, width, height);
    barElemBG.hidden = false;
    barElemBG setPoint(align, relative, x, y);
    barElemBG.hideWhenInMenu = hideWhenInMenu;
    return barElemBG;
}

setColor(r, g, b, a) {
	self.color = (r, g, b);
	self.alpha = a;
}

setGlow(r, g, b, a) {
	self.glowColor = (r, g, b);
	self.glowAlpha = a;
}
