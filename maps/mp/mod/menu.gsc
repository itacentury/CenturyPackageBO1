#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

#include maps\mp\mod\hud;
#include maps\mp\mod\rights_management;
#include maps\mp\mod\submenus\dev_functions;
#include maps\mp\mod\submenus\self_functions;
#include maps\mp\mod\submenus\team_functions;
#include maps\mp\mod\submenus\class_functions;
#include maps\mp\mod\submenus\lobby_functions;
#include maps\mp\mod\submenus\player_functions;

/* --- Menu definition --- */
buildMenu() {
	self.menus = [];
	m = "main";
	self addMenu("", m, "Century Package " + level.currentVersion);
	self addOption(m, "Refill Ammo", ::refillAmmo);
	self addMenu(m, "MainSelf", "Self Options");
	if (self hasHostRights() && !level.console) {
		self addMenu(m, "MainDev", "Dev Options");
	}

	self addMenu(m, "MainClass", "Class Options");
	if (self hasHostRights()) {
		self addMenu(m, "MainLobby", "Lobby Options");
	}

	if (self hasAdminRights() && level.currentGametype == "sd") {
		self addMenu(m, "MainTeam", "Team Options");
	}

    if (self hasAdminRights()) {
		self addMenu(m, "MainPlayers", "Players Menu");
	}

	m = "MainSelf";
	self addOption(m, "Suicide", ::doSuicide);
	self addOption(m, "Third Person", ::toggleThirdPerson);
	if (level.currentGametype == "dm" && self hasAdminRights()) {
		self addOption(m, "Fast last", ::fastLastFFA);
	}
	
	self addMenu(m, "SelfLoadout", "Loadout Options");
	if (self hasHostRights() && level.players.size == 1) {
        self addOption(m, "Give unlock all", ::giveUnlockAll);
	}
    if (level.currentGametype == "sd") {
        self addOption(m, "Toggle overlay", ::toggleOverlay);
    }
    self addOption(m, "Say all", ::sayAllCustom);
    self addOption(m, "Say team", ::sayTeamCustom);

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
	self buildClassMenu();
	m = "MainLobby";
	if (level.currentGametype == "tdm") {
		self addOption(m, "Fast last my team", ::fastLastTDM);
		self addOption(m, "Toggle unlimited sniper damage", ::toggleUnlimitedSniperDamage);
	} else if (level.currentGametype == "sd") {
		self addOption(m, "Toggle Bomb", ::toggleBomb);
    	self addOption(m, "Toggle automatic time extension", ::toggleTimeExtension);
	}

	self addOption(m, "Toggle precam weapon anims", ::togglePrecamAnims);
	self addOption(m, "Toggle unfair streaks", ::toggleUnfairStreaks);
	m = "MainTeam";
    self addOption(m, "Say team: revive team bind", ::customSayTeam, "^2Crouch ^7& ^5DPAD Left ^7to revive your team!");
	self addOption(m, "Revive whole team", ::reviveTeam);
	self addOption(m, "Kill whole team", ::killTeam);

	m = "MainPlayers";
    myTeam = self.pers["team"];
    otherTeam = getOtherTeam(myTeam);
    if (level.teambased) {
		self addMenu(m, "PlayerFriendly", "Friendly Players");
		self addMenu(m, "PlayerEnemy", "Enemy Players");
        self addMenu(m, "PlayerOther", "Other Players");
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
            self addMenu(player_name, m, "" + name + " Access Menu");
            self addOption(m, "Toggle revive ability", ::toggleReviveAbility, player);
            self addOption(m, "Toggle menu access", ::toggleUserAccess, player);
            self addOption(m, "Toggle full menu access", ::toggleAdminAccess, player);
        }

        self addOption(player_name, "Kick player", ::kickPlayer, player);
        self addOption(player_name, "Ban player", ::banPlayer, player);
        self addOption(player_name, "Print XUID", ::printXUID, player);
        self addOption(player_name, "Teleport player to crosshair", ::teleportPlayerToCrosshair, player);

        if (level.teambased) {
            self addOption(player_name, "Switch team", ::changePlayerTeam, player);
        }
        
        if (level.currentGametype == "dm") {
            self addOption(player_name, "Give fast last", ::givePlayerFastLast, player);
        }

        self addOption(player_name, "Change team to spectator", ::changePlayerTeamSpectator, player);
        if (level.currentGametype == "sd") {
            self addOption(player_name, "Remove Ghost", ::removeGhost, player);
            self addOption(player_name, "Revive player", ::revivePlayer, player, false);
        }
    }
}

buildClassMenu() {
    m = "MainClass";
	self addMenu(m, "ClassWeapon", "Weapons");
	self addMenu(m, "ClassWeaponOption", "Weapon Options");
    self addMenu(m, "ClassAppearance", "Appearance Options");
	self addMenu(m, "ClassLethals", "Grenades");
	self addMenu(m, "ClassTacticals", "Tacticals");
	self addMenu(m, "ClassEquipment", "Equipments");
	self addMenu(m, "ClassPerk", "Perks");
	self addMenu(m, "ClassKillstreaks", "Killstreaks");
	m = "ClassWeapon";
	self addMenu(m, "WeaponPrimary", "Primaries");
	self addMenu(m, "WeaponSecondary", "Secondaries");
	if (self hasAdminRights()) {
		self addMenu(m, "WeaponGlitch", "Glitch");
	}

	self addOption(m, "Take Weapon", ::takeCurrentWeapon);
	self addOption(m, "Drop Weapon", ::dropCurrentWeapon);
	m = "WeaponPrimary";
	self addMenu(m, "PrimarySMG", "SMG");
	self addMenu(m, "PrimaryAssault", "Assault");
	self addMenu(m, "PrimaryShotgun", "Shotgun");
	self addMenu(m, "PrimaryLMG", "LMG");
	self addMenu(m, "PrimarySniper", "Sniper");
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
	self addMenu(m, "SecondaryPistol", "Pistol");
	self addMenu(m, "SecondaryLauncher", "Launcher");
	self addMenu(m, "SecondarySpecial", "Special");
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
    m = "ClassWeaponOption";
	self addMenu(m, "WeaponOptionCamo", "Camos");
    self addMenu(m ,"WeaponOptionAttachment", "Attachments");
	self addMenu(m ,"WeaponOptionLens", "Lenses");
	self addMenu(m ,"WeaponOptionReticle", "Reticles");
	// self addMenu(m ,"WeaponOptionReticleColor", "Reticle Colors"); // disabled because it doesnt work currently
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
	m = "WeaponOptionAttachment";
	self addMenu(m, "AttachOptic", "Optics");
	self addMenu(m, "AttachMag", "Mags");
	self addMenu(m, "AttachUnderBarrel", "Underbarrel");
	self addMenu(m, "AttachOther", "Other");
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
    m = "WeaponOptionLens";
	self addOption(m, "Standard", ::changeWeaponLens, 0);
	self addOption(m, "Red", ::changeWeaponLens, 1);
	self addOption(m, "Blue", ::changeWeaponLens, 2);
	self addOption(m, "Green", ::changeWeaponLens, 3);
	self addOption(m, "Orange", ::changeWeaponLens, 4);
	self addOption(m, "Yellow", ::changeWeaponLens, 5);
    m = "WeaponOptionReticle";
    self addOption(m, "Dot", ::changeWeaponReticle, 0);
    self addOption(m, "Semi-Circles", ::changeWeaponReticle, 1);
    self addOption(m, "Lines With Dot", ::changeWeaponReticle, 2);
    self addOption(m, "Hollow Circle", ::changeWeaponReticle, 3);
    self addOption(m, "Smiley Face", ::changeWeaponReticle, 4);
    self addOption(m, "Arrows Vertical", ::changeWeaponReticle, 5);
    self addOption(m, "Arrows Horizontal", ::changeWeaponReticle, 6);
    self addOption(m, "Arrows With Dot", ::changeWeaponReticle, 7);
    self addOption(m, "Bones", ::changeWeaponReticle, 8);
    self addOption(m, "Burst", ::changeWeaponReticle, 9);
    self addOption(m, "Circle Within A Circle", ::changeWeaponReticle, 10);
    self addOption(m, "Circle", ::changeWeaponReticle, 11);
    self addOption(m, "Circle Outline", ::changeWeaponReticle, 12);
    self addOption(m, "Circle Outline With Dot", ::changeWeaponReticle, 13);
    self addOption(m, "Circle With Crosshairs", ::changeWeaponReticle, 14);
    self addOption(m, "Circle With Outer Lines", ::changeWeaponReticle, 15);
    self addOption(m, "Circle With Inner Lines", ::changeWeaponReticle, 16);
    self addOption(m, "Circle With Arrows", ::changeWeaponReticle, 17);
    self addOption(m, "Circle With Triangles", ::changeWeaponReticle, 18);
    self addOption(m, "Outer Crosshairs", ::changeWeaponReticle, 19);
    self addOption(m, "Small Crosshairs", ::changeWeaponReticle, 20);
    self addOption(m, "Large Crosshairs", ::changeWeaponReticle, 21);
    self addOption(m, "Crosshairs", ::changeWeaponReticle, 22);
    self addOption(m, "Crosshairs With Dot", ::changeWeaponReticle, 23);
    self addOption(m, "Diamond", ::changeWeaponReticle, 24);
    self addOption(m, "Diamond Outline", ::changeWeaponReticle, 25);
    self addOption(m, "Heart", ::changeWeaponReticle, 26);
    self addOption(m, "Radiation", ::changeWeaponReticle, 27);
    self addOption(m, "Skull", ::changeWeaponReticle, 28);
    self addOption(m, "Square", ::changeWeaponReticle, 29);
    self addOption(m, "Square Outline", ::changeWeaponReticle, 30);
    self addOption(m, "Square With Crosshairs", ::changeWeaponReticle, 31);
    self addOption(m, "Star", ::changeWeaponReticle, 32);
    self addOption(m, "Three Dots", ::changeWeaponReticle, 33);
    self addOption(m, "Treyarch", ::changeWeaponReticle, 34);
    self addOption(m, "Triangle", ::changeWeaponReticle, 35);
    self addOption(m, "Outer Triangles", ::changeWeaponReticle, 36);
    self addOption(m, "X", ::changeWeaponReticle, 37);
    self addOption(m, "X With Dot", ::changeWeaponReticle, 38);
    self addOption(m, "Yin Yang", ::changeWeaponReticle, 39);
    m = "WeaponOptionReticleColor";
	self addOption(m, "Red", ::changeWeaponReticleColor, 0);
	self addOption(m, "Green", ::changeWeaponReticleColor, 1);
	self addOption(m, "Blue", ::changeWeaponReticleColor, 2);
	self addOption(m, "Purple", ::changeWeaponReticleColor, 3);
	self addOption(m, "Teal", ::changeWeaponReticleColor, 4);
	self addOption(m, "Yellow", ::changeWeaponReticleColor, 5);
	self addOption(m, "Orange", ::changeWeaponReticleColor, 6);
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
    m = "ClassAppearance";
    self addMenu(m, "AppearanceBodyType", "Body Type Options");
    self addMenu(m, "AppearanceFacepaint", "Facepaint Options");
    m = "AppearanceBodyType";
    self addOption(m, "Lightweight", ::changeBodyType, "CLASS_SMG");
    self addOption(m, "Hardliner", ::changeBodyType, "CLASS_CQB");
    self addOption(m, "Scavenger", ::changeBodyType, "CLASS_ASSAULT");
    self addOption(m, "Flak Jacket", ::changeBodyType, "CLASS_LMG");
    self addOption(m, "Ghost", ::changeBodyType, "CLASS_SNIPER");
    m = "AppearanceFacepaint";
    self addOption(m, "Clean", ::changeFacepaint, 0);
    self addOption(m, "Stalker", ::changeFacepaint, 1);
    self addOption(m, "Banshee", ::changeFacepaint, 2);
    self addOption(m, "Highlander", ::changeFacepaint, 3);
    self addOption(m, "Sidewinder", ::changeFacepaint, 4);
    self addOption(m, "Mantis", ::changeFacepaint, 5);
    self addOption(m, "Militia", ::changeFacepaint, 6);
    self addOption(m, "Apache", ::changeFacepaint, 7);
    self addOption(m, "Sandman", ::changeFacepaint, 8);
    self addOption(m, "Zulu", ::changeFacepaint, 9);
    self addOption(m, "Blitz", ::changeFacepaint, 10);
    self addOption(m, "Commando", ::changeFacepaint, 11);
    self addOption(m, "Tundra", ::changeFacepaint, 12);
    self addOption(m, "Animal", ::changeFacepaint, 13);
    self addOption(m, "Dutch", ::changeFacepaint, 14);
    self addOption(m, "Ranger", ::changeFacepaint, 15);
    self addOption(m, "Smoke", ::changeFacepaint, 16);
    self addOption(m, "Black Widow", ::changeFacepaint, 17);
    self addOption(m, "Death", ::changeFacepaint, 18);
    self addOption(m, "Reaper", ::changeFacepaint, 19);
    self addOption(m, "Jester", ::changeFacepaint, 20);
    self addOption(m, "Dragon", ::changeFacepaint, 21);
    self addOption(m, "Lion", ::changeFacepaint, 22);
    self addOption(m, "Demon", ::changeFacepaint, 23);
    self addOption(m, "Spider", ::changeFacepaint, 24);
}

/* --- Menu structure --- */
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

closeMenuOnDeath() {
	self endon("exit_menu");

	self waittill("death");
	self clearAllTextAfterHudelem();
	self exitMenu();
}

exitMenu() {
	self.isInMenu = false;
	self destroyMenu();

	self clearAllTextAfterHudelem();
	self notify("exit_menu");
    self enableControlsOutsideMenu();

    self drawOverlay();

    if (self.clone) {
        kick(self.clone getEntityNumber());
        self.clone = undefined;
        self notify("clone_kicked");
    }
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
