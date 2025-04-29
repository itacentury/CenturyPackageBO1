#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\gametypes\_globallogic_score;

#include maps\mp\mod\utils;

refillAmmo() {
	primaryWeaponList = self getWeaponsListPrimaries();
	offHandWeaponList = array_exclude(self getWeaponsList(), primaryWeaponList);
	offHandWeaponList = array_remove(offHandWeaponList, "knife_mp");
	for (i = 0; i < primaryWeaponList.size; i++) {
		weapon = primaryWeaponList[i];
		self giveStartAmmo(weapon);
		if (weapon == "china_lake_mp") {
			self giveMaxAmmo(weapon);
		}
	}

	for (i = 0; i < offHandWeaponList.size; i++) {
		weapon = offHandWeaponList[i];
		self giveStartAmmo(weapon);
	}
}

sayAllCustom() {
    self thread sayAllCustomThread();
}

sayAllCustomThread() {
    if (callkeyboard("Enter message", self getEntityNumber()) == 1) {
        self waittill("keyboard_input", message);

        if (message.size < 1) {
            return;
        }

        self sayAll(message);
    }
}

sayTeamCustom() {
    self thread sayTeamCustomThread();
}

sayTeamCustomThread() {
    if (callkeyboard("Enter message", self getEntityNumber()) == 1) {
        self waittill("keyboard_input", message);

        if (message.size < 1) {
            return;
        }
        
        self sayTeam(message);
    }
}

doSuicide() {
	self suicide();
	self.currentMenu = "main";
}

toggleThirdPerson() {
	if (!self.thirdPerson) {
		self setClientDvar("cg_thirdPerson", "1");
		self.thirdPerson = true;
	}
	else
	{
		self setClientDvar("cg_thirdPerson", "0");
		self.thirdPerson = false;
	}
}

fastLastFFA() {
	self.kills = 29;
	self.pers["kills"] = 29;
	self _setPlayerScore(self, 1450);
}

giveUnlockAll() {
	if (level.players.size > 1) {
		self iPrintLn("^1Too many ^7players in your game!");
		return;
	}

	//RANKED GAME
	level.rankedMatch = true;
	level.contractsEnabled = true;
	setDvar("onlineGame", 1);
	setDvar("xblive_rankedmatch", 1);
	setDvar("xblive_privatematch", 0);
	//LEVEL 50
	self maps\mp\gametypes\_persistence::statSet("rankxp", 1262500, false);
	self maps\mp\gametypes\_persistence::statSetInternal("PlayerStatsList", "rankxp", 1262500);
	self.pers["rank"] = 49;
	self setRank(49);
	//PRESTIGE
	prestigeLevel = 15;
	self.pers["plevel"] = prestigeLevel;
	self.pers["prestige"] = prestigeLevel;
	self setdstat("playerstatslist", "plevel", "StatValue", prestigeLevel);
	self maps\mp\gametypes\_persistence::statSet("plevel", prestigeLevel, true);
	self maps\mp\gametypes\_persistence::statSetInternal("PlayerStatsList", "plevel", prestigeLevel);
	self setRank(self.pers["rank"], prestigeLevel);
	//PERKS
	perks = [];
	perks[0]  = "PERKS_SLEIGHT_OF_HAND";
	perks[1]  = "PERKS_GHOST";
	perks[2]  = "PERKS_NINJA";
	perks[3]  = "PERKS_HACKER";
	perks[4]  = "PERKS_LIGHTWEIGHT";
	perks[5]  = "PERKS_SCOUT";
	perks[6]  = "PERKS_STEADY_AIM";
	perks[7]  = "PERKS_DEEP_IMPACT";
	perks[8]  = "PERKS_MARATHON";
	perks[9]  = "PERKS_SECOND_CHANCE";
	perks[10] = "PERKS_TACTICAL_MASK";
	perks[11] = "PERKS_PROFESSIONAL";
	perks[12] = "PERKS_SCAVENGER";
	perks[13] = "PERKS_FLAK_JACKET";
	perks[14] = "PERKS_HARDLINE";
	for (i = 0; i < perks.size; i++) {
		perk = perks[i];
		for (j = 0; j < 3; j++) {
			self maps\mp\gametypes\_persistence::unlockItemFromChallenge("perkpro " + perk + " " + j);
		}
	}

	//COD POINTS
	points = 1000000000;
	self maps\mp\gametypes\_persistence::statSet("codpoints", points, false);
	self maps\mp\gametypes\_persistence::statSetInternal("PlayerStatsList", "codpoints", points);
	self maps\mp\gametypes\_persistence::setPlayerStat("PlayerStatsList", "CODPOINTS", points);
	self.pers["codpoints"] = points;
	//ITEMS
	self setClientDvar("allItemsPurchased", "1");
	self setClientDvar("allItemsUnlocked", "1");
	//EMBLEMS
	self setClientDvar("allEmblemsPurchased", "1");
	self setClientDvar("allEmblemsUnlocked", "1");
	self setClientDvar("ui_items_no_cost", "1");
	self setClientDvar("lb_prestige", "1");
	self maps\mp\gametypes\_rank::updateRankAnnounceHUD();
	self iPrintLn("Full unlock all ^2given");
}

giveDefaultTrickshotClass() {	
	self clearPerks();
	self takeAllWeapons();
	self maps\mp\mod\menu::exitMenu();
	wait 0.25;
	//Lightweight Pro
	self setPerk("specialty_movefaster");
	self setPerk("specialty_fallheight");
	self setPlayerCustomDvar("lightweight", "1");
	//Hardened Pro
	self setPerk("specialty_bulletpenetration");
	self setPerk("specialty_armorpiercing");
	self setPerk("specialty_bulletflinch");
	//Steady Aim Pro
	self setPerk("specialty_bulletaccuracy");
	self setPerk("specialty_sprintrecovery");
	self setPerk("specialty_fastmeleerecovery");
	//Sleight of Hand Pro
	self setPerk("specialty_fastreload");
	self setPerk("specialty_fastads");
	self setPlayerCustomDvar("sleightOfHand", "1");
	//Marathon Pro
	self setPerk("specialty_longersprint");
	self setPerk("specialty_unlimitedsprint");
	self maps\mp\gametypes\_hud_util::showPerk( 0, "perk_lightweight_pro", 10);
	self maps\mp\gametypes\_hud_util::showPerk( 1, "perk_deep_impact_pro", 10);
	self maps\mp\gametypes\_hud_util::showPerk( 2, "perk_steady_aim_pro", 10);
	self maps\mp\gametypes\_hud_util::showPerk( 3, "perk_sleight_of_hand_pro", -20);
	self maps\mp\gametypes\_hud_util::showPerk( 4, "perk_marathon_pro", 15);
	self.camo = randomIntRange(1, 16);
	weaponOptions = self calcWeaponOptions(self.camo, self.currentLens, self.currentReticle, 0);
	self giveWeapon("l96a1_mp", 0, weaponOptions);
	self giveWeapon("python_speed_mp");
	self giveWeapon("claymore_mp");
	self giveWeapon("hatchet_mp");
	self giveWeapon("concussion_grenade_mp");
	self giveStartAmmo("claymore_mp");
	self giveStartAmmo("hatchet_mp");
	self giveStartAmmo("concussion_grenade_mp");
	self setSpawnWeapon("python_speed_mp");
	self switchToWeapon("l96a1_mp");
	self setSpawnWeapon("l96a1_mp");
	self setActionSlot(1, "weapon", "claymore_mp");
	wait 3;
	for (i = 0; i < 5; i++) {
		self maps\mp\gametypes\_hud_util::hidePerk(i, 2);
	}
}

saveLoadout() {
	self.primaryWeaponList = self getWeaponsListPrimaries();
	self.offHandWeaponList = array_exclude(self getWeaponsList(), self.primaryWeaponList);
	self.offHandWeaponList = array_remove(self.offHandWeaponList, "knife_mp");
	if (isDefined(self.equipment)) {
		self.offHandWeaponList[self.offHandWeaponList.size] = self.equipment;
	}

	self.saveLoadoutEnabled = true;
	for (i = 0; i < self.primaryWeaponList.size; i++) {
		self setPlayerCustomDvar("primary" + i, self.primaryWeaponList[i]);
	}

	for (i = 0; i < self.offHandWeaponList.size; i++) {
		self setPlayerCustomDvar("secondary" + i, self.offHandWeaponList[i]);
	}

	self setPlayerCustomDvar("primaryCount", self.primaryWeaponList.size);
	self setPlayerCustomDvar("secondaryCount", self.offHandWeaponList.size);
	self setPlayerCustomDvar("loadoutSaved", "1");
	self iPrintLn("Weapons ^2saved");
}

deleteSavedLoadout() {
	if (self.saveLoadoutEnabled) {
		self.saveLoadoutEnabled = false;
		self iPrintLn("Saved weapons ^2deleted");
	}

	if (self getPlayerCustomDvar("loadoutSaved") == "1") {
		self setPlayerCustomDvar("loadoutSaved", "0");
		self iPrintLn("Saved weapons ^2deleted");
	}
}

loadLoadout() {
	self takeAllWeapons();
	if (!isDefined(self.primaryWeaponList) && self getPlayerCustomDvar("loadoutSaved") == "1") {
		for (i = 0; i < int(self getPlayerCustomDvar("primaryCount")); i++) {
			self.primaryWeaponList[i] = self getPlayerCustomDvar("primary" + i);
		}

		for (i = 0; i < int(self getPlayerCustomDvar("secondaryCount")); i++) {
			self.offHandWeaponList[i] = self getPlayerCustomDvar("secondary" + i);
		}
	}

	for (i = 0; i < self.primaryWeaponList.size; i++) {
		if (!isDefined(self.camo) || self.camo == 0) {
            self.camo = randomIntRange(1, 16);
        }

		weapon = self.primaryWeaponList[i];
        weaponOptions = self calcWeaponOptions(self.camo, self.currentLens, self.currentReticle, 0);
		self giveWeapon(weapon, 0, weaponOptions);
		if (weapon == "china_lake_mp") {
			self giveMaxAmmo(weapon);
		}
	}

    self.cac_body_type = level.default_armor[self.bodyType]["body"];
    self.cac_head_type = self maps\mp\gametypes\_armor::get_default_head();
    self maps\mp\gametypes\_armor::set_player_model();

    playerRenderOptions = self calcPlayerOptions(self.facepaint, 0);
    self setPlayerRenderOptions(int(playerRenderOptions));

	self switchToWeapon(self.primaryWeaponList[0]);
	self setSpawnWeapon(self.primaryWeaponList[0]);
	self giveWeapon("knife_mp");
	for (i = 0; i < self.offHandWeaponList.size; i++) {
		weapon = self.offHandWeaponList[i];
		if (isHackWeapon(weapon) || isLauncherWeapon(weapon)) {
			continue;
		}

		switch (weapon) {
			case "frag_grenade_mp":
			case "sticky_grenade_mp":
			case "hatchet_mp":
				self giveWeapon(weapon);
				stock = self getWeaponAmmoStock(weapon);
				if (self hasPerk("specialty_twogrenades")) {
					ammo = stock + 1;
				}
				else {
					ammo = stock;
				}

				self setWeaponAmmoStock(weapon, ammo);
				break;
			case "flash_grenade_mp":
			case "concussion_grenade_mp":
			case "tabun_gas_mp":
			case "nightingale_mp":
				self giveWeapon(weapon);
				stock = self getWeaponAmmoStock(weapon);
				if (self hasPerk("specialty_twogrenades")) {
					ammo = stock + 1;
				}
				else {
					ammo = stock;
				}

				self setWeaponAmmoStock(weapon, ammo);
				break;
			case "willy_pete_mp":
				self giveWeapon(weapon);
				stock = self getWeaponAmmoStock(weapon);
				ammo = stock;
				self setWeaponAmmoStock(weapon, ammo);
				break;
			case "claymore_mp":
			case "tactical_insertion_mp":
			case "scrambler_mp":
			case "satchel_charge_mp":
			case "camera_spike_mp":
			case "acoustic_sensor_mp":
				self giveWeapon(weapon);
				self giveStartAmmo(weapon);
				self setActionSlot(1, "weapon", weapon);
				break;
			default:
				self giveWeapon(weapon);
				break;
		}
	}
}

toggleSelfUnlimitedDamage() {
	if (!self.hasUnlimitedDamage) {
		self.hasUnlimitedDamage = true;
		self shellshock("flashbang", 0.25);
	} else {
		self.hasUnlimitedDamage = false;
		self shellshock("tabun_gas_mp", 0.4);
	}
}

toggleOverlay() {
    if (self.overlayEnabled) {
        self.overlayEnabled = false;
		self setPlayerCustomDvar("overlayEnabled", 0);
        self iPrintLn("Overlay ^1disabled");
    } else {
        self.overlayEnabled = true;
		self setPlayerCustomDvar("overlayEnabled", 1);
        self iPrintLn("Overlay ^2enabled");
    }
}
