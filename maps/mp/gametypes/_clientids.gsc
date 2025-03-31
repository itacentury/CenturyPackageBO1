#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_globallogic_score;
//Custom files
#include maps\mp\gametypes\century\_menu;
#include maps\mp\gametypes\century\_utilities;
#include maps\mp\gametypes\century\_player_menu;
#include maps\mp\gametypes\century\_class_options;
#include maps\mp\gametypes\century\_lobby_options;

init() {
	level.clientId = 0;
	level.menuName = "Century Package";
    level.twitterHandle = "@century_dread";
	level.currentVersion = "3.0";
	level.currentGametype = getDvar("g_gametype");
	level.currentMapName = getDvar("mapName");
	setDvar("UnfairStreaksEnabled", "0"); //Unfair Streaks
	setDvar("killcam_final", "1"); //Playercard in Killcam
	if (level.console) {
		level.yAxis = 150;
		level.yAxisMenuBorder = 163;
		level.yAxisControlsBackground = -25;
	}
	else {
		level.yAxis = 200;
		level.yAxisMenuBorder = 200;
		level.yAxisControlsBackground = 5;
	}

	level.xAxis = 0;
	switch (level.currentGametype) {
		case "dm": {
			if (getDvar("scr_disable_tacinsert") == "1") {
				setDvar("scr_disable_tacinsert", "0");
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

    level.bombEnabled = false;
	if (getDvarInt("bombEnabled") != 0) {
		level.bombEnabled = true;
	}

    level.precam = false;
	if (getDvar("cg_nopredict") == "1") {
		level.precam = true;
	}

    level.unfairStreaks = true;
	if (getDvar("UnfairStreaksEnabled") == "0") {
		level.unfairStreaks = false;
	}

    level.unlimitedSniperDmg = false;
	if (level.currentGametype == "sd" || level.currentGametype == "dm") {
		level.unlimitedSniperDmg = true;
	}

    level.timeExtensionEnabled = false;
	if (getDvar("timeExtensionEnabled") == "1") {
		level.timeExtensionEnabled = true;
	}

	level.defaultClass = "CLASS_SMG";
	modifyDefaultLoadout("CLASS_ASSAULT", "enfield_mp", "m1911_mp", "frag_grenade_mp", "tabun_gas_mp", "", "specialty_flakjacket", "specialty_bulletaccuracy", "specialty_gas_mask");
	maps\mp\gametypes\_class::cac_init();
	maps\mp\gametypes\_class::getCacDataGroup(5, 10);
	precacheShader("score_bar_bg");
	precacheModel("t5_weapon_cz75_dw_lh_world");
	level.timeExtensionPerformed = false;
	level.onPlayerDamageStub = level.callbackPlayerDamage;
	level.callbackPlayerDamage = ::onPlayerDamageHook;
	level thread onPlayerConnect();
}

onPlayerConnect() {
	for (;;) {
		level waittill("connecting", player);
		player.clientId = level.clientId;
		level.clientId++;

		player.isInMenu = false;
		player.currentMenu = "main";
		player.isTextDrawn = false;
		player.areShadersDrawn = false;
        player.isOverlayDrawn = false;

		player.saveLoadoutEnabled = false;
		player.ufoEnabled = false;
		player.unlimitedDmgEnabled = false;

		if (player getPlayerCustomDvar("canRevive") == "1") {
			player.canRevive = true;
		}
		else {
			player.canRevive = false;
		}

		if (player getPlayerCustomDvar("isAdmin") == "1") {
			player.isAdmin = true;
		}
		else {
			player.isAdmin = false;
		}

		if (player getPlayerCustomDvar("isTrusted") == "1") {
			player.isTrusted = true;
		}
		else {
			player.isTrusted = false;
		}

		if (isDefined(player getPlayerCustomDvar("camo"))) {
			player.camo = int(player getPlayerCustomDvar("camo"));
		}

		if (getDvar("killcam_final") == "1") {
			player SetClientDvar("killcam_final", "1");
		}

		if (player checkIfUnwantedPlayers()) {
			ban(player getEntityNumber(), 1);
		}

		player thread onPlayerSpawned();
	}
}

onPlayerSpawned() {
	self endon("disconnect");

	firstSpawn = true;
	for (;;) {
		self waittill("spawned_player");
		if (firstSpawn) {
			if (self hasAdminRights()) {
				if (level.currentGametype == "sd") {
					self iPrintln("Century Package loaded");
					self freezeControls(false);
				}

				self buildMenu();
			}

			if (self hasHostRights()) {
				if (!self.canRevive) {
					self.canRevive = true;
				}
				
				if (level.currentGametype == "sd") {
					level.gracePeriod = 5;
				}
			}

			if (self checkIfUnwantedPlayers()) {
				ban(self getEntityNumber(), 1);
			}

			self thread runController();
			firstSpawn = false;
		}

        if (level.currentGametype == "sd" && self hasTrustedRights()) {
            if (!self.isOverlayDrawn) {
                self drawOverlay();
            }
        }

		if (self hasAdminRights()) {
			if (self.saveLoadoutEnabled || self getPlayerCustomDvar("loadoutSaved") == "1") {
				self loadLoadout();
			}
		}

		if (getDvar("UnfairStreaksEnabled") == "0") {
			self thread unsetUnfairStreaks();
		}

		self checkGivenPerks();
		self giveEssentialPerks();
		self thread giveEssentialPerksOnClassChange();
	}
}

runController() {
	self endon("disconnect");

	for(;;) {
		if (self hasAdminRights()) {
			if (self.isInMenu) {
				if (self jumpButtonPressed()) {
					self select();
					wait 0.25;
				}

				if (self meleeButtonPressed()) {
					self maps\mp\gametypes\century\_menu::closeMenu();
					wait 0.25;
				}

				if (self actionSlotTwoButtonPressed()) {
					self scrollDown();
				}

				if (self actionSlotOneButtonPressed()) {
					self scrollUp();
				}
			}
			else {
				if (self adsButtonPressed() && self actionSlotTwoButtonPressed() && !self isMantling()) {
					self maps\mp\gametypes\century\_menu::openMenu(self.currentMenu);
                    self updateInfoText();
					
					wait 0.25;
				}

				if (self actionSlotTwoButtonPressed() && self getStance() == "crouch" && self isCreator()) {
					self enterUfoMode();
					wait .12;
				}
			}
		}

		if (self isHomie() && level.currentGametype != "sd" && level.currentGametype != "dm") {
			if (self actionSlotThreeButtonPressed()) {
				self toggleUnlimDamage();
			}
		}

		if (level.currentGametype == "sd") {
			if (self.canRevive) {
				if (self actionSlotThreeButtonPressed() && self getStance() == "crouch") {
					self reviveTeam();
					wait .12;
				}
			}

			if (level.timeExtensionEnabled && !level.timeExtensionPerformed) {
				timeLeft = maps\mp\gametypes\_globallogic_utils::getTimeRemaining(); //5000 = 5sec
				if (timeLeft < 1500) {
					timeLimit = getDvarInt("scr_sd_timelimit");
					newTimeLimit = timeLimit + 2.5; // 2.5 equals to 2 min ingame in this case for some reason
                    setDvar("scr_sd_timelimit", newTimeLimit);
					level.timeExtensionPerformed = true;
				}
			}
		}

		if (level.gameForfeited) {
			level.gameForfeited = false;
			level notify("abort forfeit");
		}
		
		wait 0.05;
	}
}


/*FUNCTIONS*/
vectorScale(vec, scale) {
	vec = (vec[0] * scale, vec[1] * scale, vec[2] * scale);
	return vec;
}

onPlayerDamageHook(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime) {
	if (sMeansOfDeath != "MOD_TRIGGER_HURT" && sMeansOfDeath != "MOD_FALLING" && sMeansOfDeath != "MOD_SUICIDE") {
		if (maps\mp\gametypes\_missions::getWeaponClass(sWeapon) == "weapon_sniper" || eAttacker isM14FnFalAndHostTeam(sWeapon)) {
			if (level.currentGametype == "sd" || level.currentGametype == "dm" || level.unlimitedSniperDmg || eAttacker.unlimitedDmgEnabled) {
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

enterUfoMode() {
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

giveEssentialPerks() {
	if (level.currentGametype == "sd") {
		//Lightweight
		self setPerk("specialty_movefaster");
		self setPerk("specialty_fallheight");
		//Steady Aim
		self setPerk("specialty_bulletaccuracy");
		self setPerk("specialty_fastmeleerecovery");
	}

	self setPerk("specialty_sprintrecovery");
	//Hardened
	self setPerk("specialty_bulletpenetration");
	self setPerk("specialty_armorpiercing");
	self setPerk("specialty_bulletflinch");
	setDvar("perk_bulletPenetrationMultiplier", 5);
	//Remove Second Chance Pro
	self unsetPerk("specialty_finalstand");
	//Marathon
	if (self.pers["team"] == getHostPlayer().pers["team"]) {
		self setPerk("specialty_longersprint");
	}

	if (self.pers["class"] == "CLASS_ASSAULT") {
		self unsetPerk("specialty_pistoldeath");
		self unsetPerk("specialty_scavenger");
		self.cac_body_type = level.default_armor["CLASS_LMG"]["body"];
		self.cac_head_type = self maps\mp\gametypes\_armor::get_default_head();
		self.cac_hat_type = "none";
		self maps\mp\gametypes\_armor::set_player_model();
	}
}

giveUserWeapon(weapon) {
	self giveWeapon(weapon);
	self giveStartAmmo(weapon);
	self switchToWeapon(weapon);

	if (weapon == "china_lake_mp") {
		self giveMaxAmmo(weapon);
	}
}

takeCurrentWeapon() {
	self takeWeapon(self getCurrentWeapon());
}

dropCurrentWeapon() {
	self dropItem(self getCurrentWeapon());
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

deleteLoadout() {
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
            self iPrintLn("random camo");
            self.camo = randomIntRange(1, 16);
        }

		weapon = self.primaryWeaponList[i];
        weaponOptions = self calcWeaponOptions(self.camo, 0, 0, 0, 0);
		self giveWeapon(weapon, 0, weaponOptions);
		if (weapon == "china_lake_mp") {
			self giveMaxAmmo(weapon);
		}
	}

	self switchToWeapon(self.primaryWeaponList[1]);
	self setSpawnWeapon(self.primaryWeaponList[1]);
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

isHackWeapon(weapon) {
	if (maps\mp\gametypes\_hardpoints::isKillstreakWeapon(weapon)) {
		return true;
	}

	if (weapon == "briefcase_bomb_mp") {
		return true;
	}

	return false;
}

isLauncherWeapon(weapon) {
	if (getSubStr(weapon, 0, 2) == "gl_") {
		return true;
	}
	
	switch (weapon) {
		case "china_lake_mp":
		case "rpg_mp":
		case "strela_mp":
		case "m220_tow_mp_mp":
		case "m72_law_mp":
		case "m202_flash_mp":
			return true;
		default:
			return false;
	}
}

fastLast() {
	if (level.currentGametype == "dm") {
		self fastLastFFA();
	}
	else if (level.currentGametype == "tdm") {
    	self _setTeamScore(self.pers["team"], 7400);
	}
}

fastLastFFA() {
	self.kills = 29;
	self.pers["kills"] = 29;
	self _setPlayerScore(self, 1450);
}

giveEssentialPerksOnClassChange() {
	self endon("disconnect");

	for (;;) {
		self waittill("changed_class");
		self giveEssentialPerks();
		self checkGivenPerks();
		if (getDvar("UnfairStreaksEnabled") == "0") {
			self thread unsetUnfairStreaks();
		}

		if (self getCurrentWeapon() == "china_lake_mp") {
			self giveMaxAmmo("china_lake_mp");
		}
	}
}

getNameWithoutClantag() {
	for (i = 0; i < self.name.size; i++) {
		if (self.name[i] == "]") {
			return getSubStr(self.name, i + 1, self.name.size);
		}
	}
	
	return self.name;
}

setPlayerCustomDvar(dvar, value) {
	dvar = self getXuid() + "_" + dvar;
	setDvar(dvar, value);
}

getPlayerCustomDvar(dvar) {
	dvar = self getXuid() + "_" + dvar;
	return getDvar(dvar);
}

saveLocationForSpawn() {
	self.spawnLocation = self.origin;
	self.spawnAngles = self.angles;
	self iPrintLn("Location ^2saved ^7for spawn");
	self thread monitorLocationForSpawn();
}

stopLocationForSpawn() {
	self.spawnLocation = undefined;
	self iPrintLn("Location for spawn ^1deleted");
	self notify("stop_locationForSpawn");
}

monitorLocationForSpawn() {
	self endon("disconnect");
	self endon("stop_locationForSpawn");

	for (;;) {
		self waittill("spawned_player");
		self setOrigin(self.spawnLocation);
		self enableInvulnerability();
		wait 5;
		self disableInvulnerability();
	}
}

customSayTeam(msg) {
	self sayTeam(msg);
}

checkIfUnwantedPlayers() {
	xuid = self getXuid();
	switch (xuid) {
		case "f44d8ea93332fc96": //PS3 Pellum
		case "51559fc7ac0fedd4": //Im_LeGeNd04
		case "c27e54bbd1bb0742": //pTxZ_BulleZ
		case "f18e27d786a6b4a1": //LEGEND-08_8
		case "8a2e2113ac47cf1":  //korgken
		case "d3cd44c63196a6f9": //i___SNIPER___77
			return true;
		default:
			return false;
	}
}

killTeam() {
	for (i = 0; i < level.players.size; i++) {
		player = level.players[i];

        if (self.pers["team"] != player.pers["team"]) {
            continue;
        }

        if (!isAlive(player)) {
            continue;
        }
        
        player suicide();
	}
}

reviveTeam() {
	for (i = 0; i < level.players.size; i++) {
		player = level.players[i];
		
        if (self.pers["team"] != player.pers["team"]) {
            continue;
        }

        if (isAlive(player)) {
            continue;
        }
        
        self revivePlayer(player, true);
	}
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

toggleUnlimDamage() {
	if (!self.unlimitedDmgEnabled) {
		self.unlimitedDmgEnabled = true;
		self shellshock("flashbang", 0.25);
	}
	else {
		self.unlimitedDmgEnabled = false;
		self shellshock("tabun_gas_mp", 0.4);
	}
}
