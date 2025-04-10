#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

main() {
	if (getDvar(#"mapname") == "mp_background") {
		return;
	}

	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::setupCallbacks();
	maps\mp\gametypes\_globallogic::setupCallbacks();
	maps\mp\gametypes\_globallogic_utils::registerRoundSwitchDvar(level.gameType, 3, 0, 9);
	maps\mp\gametypes\_globallogic_utils::registerTimeLimitDvar(level.gameType, 2.5, 0, 1440);
	maps\mp\gametypes\_globallogic_utils::registerScoreLimitDvar(level.gameType, 4, 0, 500);
	maps\mp\gametypes\_globallogic_utils::registerRoundLimitDvar(level.gameType, 0, 0, 15);
	maps\mp\gametypes\_globallogic_utils::registerRoundWinLimitDvar(level.gameType, 0, 0, 10);
	maps\mp\gametypes\_globallogic_utils::registerNumLivesDvar(level.gameType, 1, 0, 10);
	maps\mp\gametypes\_weapons::registerGrenadeLauncherDudDvar(level.gameType, 15, 0, 1440);
	maps\mp\gametypes\_weapons::registerThrownGrenadeDudDvar(level.gameType, 5, 0, 1440);
	maps\mp\gametypes\_weapons::registerKillstreakDelay(level.gameType, 15, 0, 1440);
	maps\mp\gametypes\_globallogic::registerFriendlyFireDelay(level.gameType, 15, 0, 1440);
	level.teambased = true;
	level.overrideTeamScore = true;
	level.onPrecacheGameType = ::onPrecacheGameType;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onSpawnPlayerUnified = ::onSpawnPlayerUnified;
	level.playerSpawnedCB = ::sd_playerSpawnedCB;
	level.onPlayerKilled = ::onPlayerKilled;
	level.onDeadEvent = ::onDeadEvent;
	level.onOneLeftEvent = ::onOneLeftEvent;
	level.onTimeLimit = ::onTimeLimit;
	level.onRoundSwitch = ::onRoundSwitch;
	level.getTeamKillPenalty = ::sd_getTeamKillPenalty;
	level.getTeamKillScore = ::sd_getTeamKillScore;
	level.isKillBoosting = ::sd_isKillBoosting;
	level.onRoundEndGame = ::onRoundEndGame;
	level.endGameOnScoreLimit = false;
	game["dialog"]["gametype"] = "sd_start";
	game["dialog"]["gametype_hardcore"] = "hcsd_start";
	game["dialog"]["offense_obj"] = "destroy_start";
	game["dialog"]["defense_obj"] = "defend_start";
	game["dialog"]["sudden_death"] = "generic_boost";
	game["dialog"]["last_one"] = "encourage_last";	
	game["dialog"]["halftime"] = "sd_halftime";
	setScoreboardColumns("kills", "deaths", "plants", "defuses"); 
}

onPrecacheGameType() {
	game["bomb_dropped_sound"] = "flag_drop_plr";
	game["bomb_recovered_sound"] = "flag_pickup_plr";
	precacheShader("waypoint_bomb");
	precacheShader("hud_suitcase_bomb");
	precacheShader("waypoint_target");
	precacheShader("waypoint_target_a");
	precacheShader("waypoint_target_b");
	precacheShader("waypoint_defend");
	precacheShader("waypoint_defend_a");
	precacheShader("waypoint_defend_b");
	precacheShader("waypoint_defuse");
	precacheShader("waypoint_defuse_a");
	precacheShader("waypoint_defuse_b");
	precacheShader("compass_waypoint_target");
	precacheShader("compass_waypoint_target_a");
	precacheShader("compass_waypoint_target_b");
	precacheShader("compass_waypoint_defend");
	precacheShader("compass_waypoint_defend_a");
	precacheShader("compass_waypoint_defend_b");
	precacheShader("compass_waypoint_defuse");
	precacheShader("compass_waypoint_defuse_a");
	precacheShader("compass_waypoint_defuse_b");
	precacheString(&"MP_EXPLOSIVES_BLOWUP_BY");
	precacheString(&"MP_EXPLOSIVES_RECOVERED_BY");
	precacheString(&"MP_EXPLOSIVES_DROPPED_BY");
	precacheString(&"MP_EXPLOSIVES_PLANTED_BY");
	precacheString(&"MP_EXPLOSIVES_DEFUSED_BY");
	precacheString(&"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES");
	precacheString(&"PLATFORM_HOLD_TO_DEFUSE_EXPLOSIVES");
	precacheString(&"MP_CANT_PLANT_WITHOUT_BOMB");	
	precacheString(&"MP_PLANTING_EXPLOSIVE");	
	precacheString(&"MP_DEFUSING_EXPLOSIVE");	
}

sd_getTeamKillPenalty(eInflictor, attacker, sMeansOfDeath, sWeapon) {
	teamkill_penalty = maps\mp\gametypes\_globallogic_defaults::default_getTeamKillPenalty(eInflictor, attacker, sMeansOfDeath, sWeapon);
	if ((isDefined(self.isDefusing) && self.isDefusing) || (isDefined(self.isPlanting) && self.isPlanting)) {
		teamkill_penalty = teamkill_penalty * level.teamKillPenaltyMultiplier;
	}
	
	return teamkill_penalty;
}

sd_getTeamKillScore(eInflictor, attacker, sMeansOfDeath, sWeapon) {
	teamkill_score = maps\mp\gametypes\_rank::getScoreInfoValue("kill");
	if ((isDefined(self.isDefusing) && self.isDefusing) || (isDefined(self.isPlanting) && self.isPlanting)) {
		teamkill_score = teamkill_score * level.teamKillScoreMultiplier;
	}
	
	return int(teamkill_score);
}

onRoundSwitch() {
	if (!isDefined(game["switchedsides"])) {
		game["switchedsides"] = false;
	}

	if (game["teamScores"]["allies"] == level.scoreLimit - 1 && game["teamScores"]["axis"] == level.scoreLimit - 1) {
		aheadTeam = getBetterTeam();
		if (aheadTeam != game["defenders"]) {
			game["switchedsides"] = !game["switchedsides"];
		}
		else {
			level.halftimeSubCaption = "";
		}

		level.halftimeType = "overtime";
	}
	else {
		level.halftimeType = "halftime";
		game["switchedsides"] = !game["switchedsides"];
	}
}

getBetterTeam() {
	kills["allies"] = 0;
	kills["axis"] = 0;
	deaths["allies"] = 0;
	deaths["axis"] = 0;
	for (i = 0; i < level.players.size; i++) {
		player = level.players[i];
		team = player.pers["team"];
		if (isDefined(team) && (team == "allies" || team == "axis")) {
			kills[ team ] += player.kills;
			deaths[ team ] += player.deaths;
		}
	}
	
	if (kills["allies"] > kills["axis"]) {
		return "allies";
	}
	else if (kills["axis"] > kills["allies"]) {
		return "axis";
	}
	
	if (deaths["allies"] < deaths["axis"]) {
		return "allies";
	}
	else if (deaths["axis"] < deaths["allies"]) {
		return "axis";
	}
	
	if (randomint(2) == 0) {
		return "allies";
	}

	return "axis";
}

onStartGameType() {
	if (!isDefined(game["switchedsides"])) {
		game["switchedsides"] = false;
	}

	if (game["switchedsides"]) {
		oldAttackers = game["attackers"];
		oldDefenders = game["defenders"];
		game["attackers"] = oldDefenders;
		game["defenders"] = oldAttackers;
	}
	
	setClientNameMode("manual_change");
	game["strings"]["target_destroyed"] = &"MP_TARGET_DESTROYED";
	game["strings"]["bomb_defused"] = &"MP_BOMB_DEFUSED";
	precacheString(game["strings"]["target_destroyed"]);
	precacheString(game["strings"]["bomb_defused"]);
	level._effect["bombexplosion"] = loadfx("maps/mp_maps/fx_mp_exp_bomb");
	maps\mp\gametypes\_globallogic_ui::setObjectiveText(game["attackers"], &"OBJECTIVES_SD_ATTACKER");
	maps\mp\gametypes\_globallogic_ui::setObjectiveText(game["defenders"], &"OBJECTIVES_SD_DEFENDER");
	if (level.splitscreen) {
		maps\mp\gametypes\_globallogic_ui::setObjectiveScoreText(game["attackers"], &"OBJECTIVES_SD_ATTACKER");
		maps\mp\gametypes\_globallogic_ui::setObjectiveScoreText(game["defenders"], &"OBJECTIVES_SD_DEFENDER");
	}
	else {
		maps\mp\gametypes\_globallogic_ui::setObjectiveScoreText(game["attackers"], &"OBJECTIVES_SD_ATTACKER_SCORE");
		maps\mp\gametypes\_globallogic_ui::setObjectiveScoreText(game["defenders"], &"OBJECTIVES_SD_DEFENDER_SCORE");
	}

	maps\mp\gametypes\_globallogic_ui::setObjectiveHintText(game["attackers"], &"OBJECTIVES_SD_ATTACKER_HINT");
	maps\mp\gametypes\_globallogic_ui::setObjectiveHintText(game["defenders"], &"OBJECTIVES_SD_DEFENDER_HINT");
	level.spawnMins = (0, 0, 0);
	level.spawnMaxs = (0, 0, 0);	
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints("mp_sd_spawn_attacker");
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints("mp_sd_spawn_defender");
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter(level.spawnMins, level.spawnMaxs);
	setMapCenter(level.mapCenter);
	spawnpoint = maps\mp\gametypes\_spawnlogic::getRandomIntermissionPoint();
	setDemoIntermissionPoint(spawnpoint.origin, spawnpoint.angles);
	allowed[0] = "sd";
	allowed[1] = "bombzone";
	allowed[2] = "blocker";
	maps\mp\gametypes\_gameobjects::main(allowed);
	maps\mp\gametypes\_spawning::create_map_placed_influencers();
	level.spawn_axis_start = maps\mp\gametypes\_spawnlogic::getSpawnpointArray("mp_sd_spawn_defender");
	level.spawn_allies_start = maps\mp\gametypes\_spawnlogic::getSpawnpointArray("mp_sd_spawn_attacker");
	maps\mp\gametypes\_rank::registerScoreInfo("win", 2);
	maps\mp\gametypes\_rank::registerScoreInfo("loss", 1);
	maps\mp\gametypes\_rank::registerScoreInfo("tie", 1.5);
	maps\mp\gametypes\_rank::registerScoreInfo("kill", 500);
	maps\mp\gametypes\_rank::registerScoreInfo("headshot", 500);
	maps\mp\gametypes\_rank::registerScoreInfo("plant", 500);
	maps\mp\gametypes\_rank::registerScoreInfo("defuse", 500);
	maps\mp\gametypes\_rank::registerScoreInfo("assist_75", 250);
	maps\mp\gametypes\_rank::registerScoreInfo("assist_50", 250);
	maps\mp\gametypes\_rank::registerScoreInfo("assist_25", 250);
	maps\mp\gametypes\_rank::registerScoreInfo("assist", 250);
	thread updateGametypeDvars();
	thread bombs();
}

onSpawnPlayerUnified() {
	self.isPlanting = false;
	self.isDefusing = false;
	self.isBombCarrier = false;
	if (level.multiBomb && !isDefined(self.carryIcon) && self.pers["team"] == game["attackers"] && !level.bombPlanted) {
		if (self isSplitscreen()) {
			self.carryIcon = createIcon("hud_suitcase_bomb", 35, 35);
			self.carryIcon.x = -125;
			self.carryIcon.y = -90;
			self.carryIcon.horzAlign = "right";
			self.carryIcon.vertAlign = "bottom";
		}
		else {
			self.carryIcon = createIcon("hud_suitcase_bomb", 50, 50);
			self.carryIcon.x = -130;
			self.carryIcon.y = -113;
			self.carryIcon.horzAlign = "user_right";
			self.carryIcon.vertAlign = "user_bottom";
		}

		self.carryIcon.alpha = 0.75;
		self.carryIcon.hideWhileRemoteControlling = true;
		self.carryIcon.hideWhenInKillcam = true;
	}
	
	maps\mp\gametypes\_spawning::onSpawnPlayer_Unified();
}

onSpawnPlayer() {
	self.isPlanting = false;
	self.isDefusing = false;
	self.isBombCarrier = false;
	if (self.pers["team"] == game["attackers"]) {
		spawnpointName = "mp_sd_spawn_attacker";
	}
	else {
		spawnpointName = "mp_sd_spawn_defender";
	}

	if (level.multiBomb && !isDefined(self.carryIcon) && self.pers["team"] == game["attackers"] && !level.bombPlanted) {
		if (self isSplitscreen()) {
			self.carryIcon = createIcon("hud_suitcase_bomb", 35, 35);
			self.carryIcon.x = -125;
			self.carryIcon.y = -90;
			self.carryIcon.horzAlign = "right";
			self.carryIcon.vertAlign = "bottom";
		}
		else {
			self.carryIcon = createIcon("hud_suitcase_bomb", 50, 50);
			self.carryIcon.x = -130;
			self.carryIcon.y = -103;
			self.carryIcon.horzAlign = "user_right";
			self.carryIcon.vertAlign = "user_bottom";
		}

		self.carryIcon.alpha = 0.75;
		self.carryIcon.hideWhileRemoteControlling = true;
		self.carryIcon.hideWhenInKillcam = true;
	}

	spawnpoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray(spawnpointName);
	assert(spawnpoints.size);
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);
	self spawn(spawnpoint.origin, spawnpoint.angles, "sd");
}

sd_playerSpawnedCB() {
	level notify("spawned_player");
}

onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration) {
	thread checkAllowSpectating();
	inBombZone = false;
	if (!isDefined(sWeapon) || !maps\mp\gametypes\_hardpoints::isKillstreakWeapon(sWeapon)) {
		for (index = 0; index < level.bombZones.size; index++) {
			dist = distance2d(self.origin, level.bombZones[index].curOrigin);
			if (dist < level.defaultOffenseRadius) {
				inBombZone = true;
			}
		}
		
		if (inBombZone && isPlayer(attacker) && attacker.pers["team"] != self.pers["team"]) {	
			if (game["defenders"] == self.pers["team"]) {
				attacker maps\mp\_medals::offense(sWeapon);
				attacker maps\mp\gametypes\_persistence::statAddWithGameType("OFFENDS", 1);
			}
			else {
				if(isDefined(attacker.pers["defends"]))
				{
					attacker.pers["defends"]++;
					attacker.defends = attacker.pers["defends"];
				}

				attacker maps\mp\_medals::defense(sWeapon);
				attacker maps\mp\gametypes\_persistence::statAddWithGameType("DEFENDS", 1);
			}
		}
	}
	
	if (isPlayer(attacker) && attacker.pers["team"] != self.pers["team"] && isDefined(self.isBombCarrier) && self.isBombCarrier) {
		attacker maps\mp\_challenges::killedBombCarrier();
	}
}

checkAllowSpectating() {
	wait 0.05;
	update = false;
	livesLeft = !(level.numLives && !self.pers["lives"]);
	if (!level.aliveCount[game["attackers"]] && !livesLeft) {
		level.spectateOverride[game["attackers"]].allowEnemySpectate = 1;
		update = true;
	}

	if (!level.aliveCount[game["defenders"]] && !livesLeft) {
		level.spectateOverride[game["defenders"]].allowEnemySpectate = 1;
		update = true;
	}

	if (update) {
		maps\mp\gametypes\_spectating::updateSpectateSettings();
	}
}

sd_endGame(winningTeam, endReasonText) {
	if (isDefined(winningTeam)) {
		[[level._setTeamScore]](winningTeam, [[level._getTeamScore]](winningTeam) + 1);
	}
	
	thread maps\mp\gametypes\_globallogic::endGame(winningTeam, endReasonText);
}

sd_endGameWithKillcam(winningTeam, endReasonText) {
	level thread maps\mp\gametypes\_killcam::startLastKillcam();
	sd_endGame(winningTeam, endReasonText);
}

onDeadEvent(team) {
	if (level.bombExploded || level.bombDefused) {
		return;
	}

	if (team == "all") {
		if (level.bombPlanted) {
			sd_endGameWithKillcam(game["attackers"], game["strings"][game["defenders"]+"_eliminated"]);
		}
		else {
			sd_endGameWithKillcam(game["defenders"], game["strings"][game["attackers"]+"_eliminated"]);
		}
	}
	else if (team == game["attackers"]) {
		if (level.bombPlanted) {
			return;
		}

		sd_endGameWithKillcam(game["defenders"], game["strings"][game["attackers"]+"_eliminated"]);
	}
	else if (team == game["defenders"]) {
		sd_endGameWithKillcam(game["attackers"], game["strings"][game["defenders"]+"_eliminated"]);
	}
}

onOneLeftEvent(team) {
	if (level.bombExploded || level.bombDefused) {
		return;
	}
	
	warnLastPlayer(team);
}

onTimeLimit() {
	if (level.teambased) {
		sd_endGame(game["defenders"], game["strings"]["time_limit_reached"]);
	}
	else {
		sd_endGame(undefined, game["strings"]["time_limit_reached"]);
	}
}

warnLastPlayer(team) {
	if (!isDefined(level.warnedLastPlayer)) {
		level.warnedLastPlayer = [];
	}

	if (isDefined(level.warnedLastPlayer[team])) {
		return;
	}

	level.warnedLastPlayer[team] = true;
	players = level.players;
	for (i = 0; i < players.size; i++) {
		player = players[i];
		if (isDefined(player.pers["team"]) && player.pers["team"] == team && isDefined(player.pers["class"])) {
			if (player.sessionState == "playing" && !player.afk) {
				break;
			}
		}
	}
	
	if (i == players.size) {
		return;
	}

	players[i] thread giveLastAttackerWarning();
}

giveLastAttackerWarning() {
	self endon("death");
	self endon("disconnect");
	
	fullHealthTime = 0;
	interval = .05;
	for (;;) {
		if (self.health != self.maxHealth) {
			fullHealthTime = 0;
		}
		else {
			fullHealthTime += interval;
		}

		wait interval;
		
		if (self.health == self.maxHealth && fullHealthTime >= 3) {
			break;
		}
	}
	
	self maps\mp\gametypes\_globallogic_audio::leaderDialogOnPlayer("last_one");
	self playLocalSound ("mus_last_stand");
	self maps\mp\gametypes\_missions::lastManSD();
	self.lastManSD = true;
}

updateGametypeDvars() {
	level.plantTime = dvarFloatValue("planttime", 5, 0, 20);
	level.defuseTime = dvarFloatValue("defusetime", 5, 0, 20);
	level.bombTimer = dvarFloatValue("bombtimer", 45, 1, 300);
	level.multiBomb = dvarIntValue("multibomb", 0, 0, 1);
	level.teamKillPenaltyMultiplier = dvarFloatValue("teamkillpenalty", 2, 0, 10);
	level.teamKillScoreMultiplier = dvarFloatValue("teamkillscore", 4, 0, 40);
	level.playerKillsMax = dvarIntValue("playerKillsMax", 100, 0, 9); //( "playerKillsMax", 6, 0, 9 );
	level.totalKillsMax = dvarIntValue("totalKillsMax", 100, 0, 18); //( "totalKillsMax", 11, 0, 18 );
}

bombs() {
	level.bombPlanted = false;
	level.bombDefused = false;
	level.bombExploded = false;
	trigger = getEnt("sd_bomb_pickup_trig", "targetname");
	if (!isDefined(trigger)) {
		maps\mp\_utility::error("No sd_bomb_pickup_trig trigger found in map.");
		return;
	}
	
	visuals[0] = getEnt("sd_bomb", "targetname");
	if (!isDefined(visuals[0])) {
		maps\mp\_utility::error("No sd_bomb script_model found in map.");
		return;
	}

	precacheModel("prop_suitcase_bomb");
	if (!level.multiBomb && getDvarInt("bombEnabled") != 0) {
		level.sdBomb = maps\mp\gametypes\_gameobjects::createCarryObject(game["attackers"], trigger, visuals, (0, 0, 32));
		level.sdBomb maps\mp\gametypes\_gameobjects::allowCarry("friendly");
		level.sdBomb maps\mp\gametypes\_gameobjects::set2DIcon("friendly", "compass_waypoint_bomb");
		level.sdBomb maps\mp\gametypes\_gameobjects::set3DIcon("friendly", "waypoint_bomb");
		level.sdBomb maps\mp\gametypes\_gameobjects::setVisibleTeam("friendly");
		level.sdBomb maps\mp\gametypes\_gameobjects::setCarryIcon("hud_suitcase_bomb");
		level.sdBomb.allowWeapons = true;
		level.sdBomb.onPickup = ::onPickup;
		level.sdBomb.onDrop = ::onDrop;
	}
	else {
		trigger delete();
		visuals[0] delete();
	}
	
	level.bombZones = [];
	bombZones = getEntArray("bombzone", "targetname");
	for (index = 0; index < bombZones.size; index++) {
		trigger = bombZones[index];
		visuals = getEntArray(bombZones[index].target, "targetname");
		bombZone = maps\mp\gametypes\_gameobjects::createUseObject(game["defenders"], trigger, visuals, (0, 0, 64));
		bombZone maps\mp\gametypes\_gameobjects::allowUse("enemy");
		bombZone maps\mp\gametypes\_gameobjects::setUseTime(level.plantTime);
		bombZone maps\mp\gametypes\_gameobjects::setUseText(&"MP_PLANTING_EXPLOSIVE");
		bombZone maps\mp\gametypes\_gameobjects::setUseHintText(&"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES");
		if (!level.multiBomb) {
			bombZone maps\mp\gametypes\_gameobjects::setKeyObject(level.sdBomb);
		}

		label = bombZone maps\mp\gametypes\_gameobjects::getLabel();
		bombZone.label = label;
		bombZone maps\mp\gametypes\_gameobjects::set2DIcon("friendly", "compass_waypoint_defend" + label);
		bombZone maps\mp\gametypes\_gameobjects::set3DIcon("friendly", "waypoint_defend" + label);
		bombZone maps\mp\gametypes\_gameobjects::set2DIcon("enemy", "compass_waypoint_target" + label);
		bombZone maps\mp\gametypes\_gameobjects::set3DIcon("enemy", "waypoint_target" + label);
		bombZone maps\mp\gametypes\_gameobjects::setVisibleTeam("any");
		bombZone.onBeginUse = ::onBeginUse;
		bombZone.onEndUse = ::onEndUse;
		bombZone.onUse = ::onUsePlantObject;
		bombZone.onCantUse = ::onCantUse;
		bombZone.useWeapon = "briefcase_bomb_mp";
		bombZone.visuals[0].killcamEnt = spawn("script_model", bombZone.visuals[0].origin + (0, 0, 128));
		if (!level.multiBomb) {
			bombZone.trigger setInvisibleToAll();
		}

		for (i = 0; i < visuals.size; i++) {
			if (isDefined(visuals[i].script_exploder)) {
				bombZone.exploderIndex = visuals[i].script_exploder;
				break;
			}
		}
		
		level.bombZones[level.bombZones.size] = bombZone;
		bombZone.bombDefuseTrig = getEnt(visuals[0].target, "targetname");
		assert(isDefined(bombZone.bombDefuseTrig));
		bombZone.bombDefuseTrig.origin += (0, 0, -10000);
		bombZone.bombDefuseTrig.label = label;
	}
	
	for (index = 0; index < level.bombZones.size; index++) {
		array = [];
		for (otherIndex = 0; otherIndex < level.bombZones.size; otherIndex++) {
			if (otherIndex != index) {
				array[array.size] = level.bombZones[otherIndex];
			}
		}

		level.bombZones[index].otherBombZones = array;
	}
}

onBeginUse(player) {
	if (self maps\mp\gametypes\_gameobjects::isFriendlyTeam(player.pers["team"])) {
		player playSound("mpl_sd_bomb_defuse");
		player.isDefusing = true;
		player thread maps\mp\gametypes\_battlechatter_mp::gametypeSpecificBattleChatter("sd_enemyplant", player.pers["team"]);
		if (isDefined(level.sdBombModel)) {
			level.sdBombModel hide();
		}
	}
	else {
		player.isPlanting = true;
		player thread maps\mp\gametypes\_battlechatter_mp::gametypeSpecificBattleChatter("sd_friendlyplant", player.pers["team"]);
		if (level.multiBomb) {
			for (i = 0; i < self.otherBombZones.size; i++) {
				self.otherBombZones[i] maps\mp\gametypes\_gameobjects::disableObject();
			}
		}
	}

	player playSound("fly_bomb_raise_plr");
}

onEndUse(team, player, result) {
	if (!isDefined(player)) {
		return;
	}

	player.isDefusing = false;
	player.isPlanting = false;
	player notify("event_ended");
	if (self maps\mp\gametypes\_gameobjects::isFriendlyTeam(player.pers["team"])) {
		if (isDefined(level.sdBombModel) && !result) {
			level.sdBombModel show();
		}
	}
	else {
		if (level.multiBomb && !result) {
			for (i = 0; i < self.otherBombZones.size; i++) {
				self.otherBombZones[i] maps\mp\gametypes\_gameobjects::enableObject();
			}
		}
	}
}

onCantUse(player) {
	player iPrintLnBold(&"MP_CANT_PLANT_WITHOUT_BOMB");
}
onUsePlantObject(player) {
	if (self maps\mp\gametypes\_gameobjects::isFriendlyTeam(player.pers["team"])) {
        return;
    }

    level thread bombPlanted(self, player);
    player logString("bomb planted: " + self.label);
    for (index = 0; index < level.bombZones.size; index++) {
        if (level.bombZones[index] == self) {
            continue;
        }

        level.bombZones[index] maps\mp\gametypes\_gameobjects::disableObject();
    }

    thread playSoundOnPlayers("mus_sd_planted" + "_" + level.teamPostfix[player.pers["team"]]);
    player notify ("bomb_planted");
    level thread maps\mp\_popups::displayTeamMessageToAll(&"MP_EXPLOSIVES_PLANTED_BY", player);
    if (isDefined(player.pers["plants"])) {
        player.pers["plants"]++;
        player.plants = player.pers["plants"];
    }

    player maps\mp\_medals::saboteur();
    player maps\mp\gametypes\_persistence::statAddWithGameType("PLANTS", 1);
    maps\mp\gametypes\_globallogic_audio::leaderDialog("bomb_planted");
    maps\mp\gametypes\_globallogic_score::givePlayerScore("plant", player);
}

onUseDefuseObject(player) {
	wait .05;
	player notify("bomb_defused");
	player logString("bomb defused: " + self.label);
	level thread bombDefused();
	self maps\mp\gametypes\_gameobjects::disableObject();
	level thread maps\mp\_popups::displayTeamMessageToAll(&"MP_EXPLOSIVES_DEFUSED_BY", player);
	if(isDefined(player.pers["defuses"])) {
		player.pers["defuses"]++;
		player.defuses = player.pers["defuses"];
	}

	player maps\mp\gametypes\_persistence::statAddWithGameType("DEFUSES", 1);
	player maps\mp\_medals::hero();
	maps\mp\gametypes\_globallogic_audio::leaderDialog("bomb_defused");
	maps\mp\gametypes\_globallogic_score::givePlayerScore("defuse", player);
}

onDrop(player) {
	if (!level.bombPlanted) {
		if (isDefined(player) && isDefined(player.name)) {
			printOnTeamArg(&"MP_EXPLOSIVES_DROPPED_BY", game["attackers"], player);
		}

		if (isDefined(player)) {
		 	player logString("bomb dropped");
		}
		else {
		 	logString("bomb dropped");
		}
	}

	player notify("event_ended");
	self maps\mp\gametypes\_gameobjects::set3DIcon("friendly", "waypoint_bomb");
	maps\mp\_utility::playSoundOnPlayers(game["bomb_dropped_sound"], game["attackers"]);
}

onPickup(player) {	
	player.isBombCarrier = true;
	self maps\mp\gametypes\_gameobjects::set3DIcon("friendly", "waypoint_defend");
	if (!level.bombDefused) {
		if (isDefined(player) && isDefined(player.name)) {
			printOnTeamArg(&"MP_EXPLOSIVES_RECOVERED_BY", game["attackers"], player);
			player maps\mp\gametypes\_persistence::statAddWithGameType("PICKUPS", 1);
		}
		
		team = self maps\mp\gametypes\_gameobjects::getOwnerTeam();
		otherTeam = getOtherTeam(team);
		thread maps\mp\gametypes\_globallogic_audio::set_music_on_team("CTF_THEY_TAKE", otherTeam, false, false);
		thread maps\mp\gametypes\_globallogic_audio::set_music_on_team("CTF_WE_TAKE", team, false, false);
		maps\mp\gametypes\_globallogic_audio::leaderDialog("bomb_acquired", player.pers["team"]);
		player logString("bomb taken");
	}

	maps\mp\_utility::playSoundOnPlayers(game["bomb_recovered_sound"], game["attackers"]);
	for (i = 0; i < level.bombZones.size; i++) {
		level.bombZones[i].trigger setInvisibleToAll();
		level.bombZones[i].trigger setVisibleToPlayer(player);
	}
}

onReset() {
}

bombPlantedMusicDelay() {
	level endon("bomb_defused");
	
	time = (level.bombtimer - 30);
	if (getDvarInt(#"debug_music") > 0) {		
		printLn("Music System - waiting to set TIME_OUT: " + time);
	}

	if (time > 1) {
		wait time;
		thread maps\mp\gametypes\_globallogic_audio::set_music_on_team("TIME_OUT", "both");	
	}
}

bombPlanted(destroyedObj, player) {
	maps\mp\gametypes\_globallogic_utils::pauseTimer();
	level.bombPlanted = true;
	destroyedObj.visuals[0] thread maps\mp\gametypes\_globallogic_utils::playTickingSound("mpl_sab_ui_suitcasebomb_timer");
	level thread bombPlantedMusicDelay();
	level.tickingObject = destroyedObj.visuals[0];
	level.timeLimitOverride = true;
	setGameEndTime(int(getTime() + (level.bombTimer * 1000)));
	setMatchFlag("bomb_timer", 1);
	if (!level.multiBomb) {
		level.sdBomb maps\mp\gametypes\_gameobjects::allowCarry("none");
		level.sdBomb maps\mp\gametypes\_gameobjects::setVisibleTeam("none");
		level.sdBomb maps\mp\gametypes\_gameobjects::setDropped();
		level.sdBombModel = level.sdBomb.visuals[0];
	}
	else {
		for (index = 0; index < level.players.size; index++) {
			if (isDefined(level.players[index].carryIcon)) {
				level.players[index].carryIcon destroyElem();
			}
		}

		trace = bulletTrace(player.origin + (0, 0, 20), player.origin - (0, 0, 2000), false, player);
		tempAngle = randomFloat(360);
		forward = (cos(tempAngle), sin(tempAngle), 0);
		forward = vectornormalize(forward - vector_scale(trace["normal"], vectordot(forward, trace["normal"])));
		dropAngles = vectortoangles(forward);
		level.sdBombModel = spawn("script_model", trace["position"]);
		level.sdBombModel.angles = dropAngles;
		level.sdBombModel setModel("prop_suitcase_bomb");
	}

	destroyedObj maps\mp\gametypes\_gameobjects::allowUse("none");
	destroyedObj maps\mp\gametypes\_gameobjects::setVisibleTeam("none");
	label = destroyedObj maps\mp\gametypes\_gameobjects::getLabel();
	trigger = destroyedObj.bombDefuseTrig;
	trigger.origin = level.sdBombModel.origin;
	visuals = [];
	defuseObject = maps\mp\gametypes\_gameobjects::createUseObject(game["defenders"], trigger, visuals, (0, 0, 32));
	defuseObject maps\mp\gametypes\_gameobjects::allowUse("friendly");
	defuseObject maps\mp\gametypes\_gameobjects::setUseTime(level.defuseTime);
	defuseObject maps\mp\gametypes\_gameobjects::setUseText(&"MP_DEFUSING_EXPLOSIVE");
	defuseObject maps\mp\gametypes\_gameobjects::setUseHintText(&"PLATFORM_HOLD_TO_DEFUSE_EXPLOSIVES");
	defuseObject maps\mp\gametypes\_gameobjects::setVisibleTeam("any");
	defuseObject maps\mp\gametypes\_gameobjects::set2DIcon("friendly", "compass_waypoint_defuse" + label);
	defuseObject maps\mp\gametypes\_gameobjects::set2DIcon("enemy", "compass_waypoint_defend" + label);
	defuseObject maps\mp\gametypes\_gameobjects::set3DIcon("friendly", "waypoint_defuse" + label);
	defuseObject maps\mp\gametypes\_gameobjects::set3DIcon("enemy", "waypoint_defend" + label);
	defuseObject.label = label;
	defuseObject.onBeginUse = ::onBeginUse;
	defuseObject.onEndUse = ::onEndUse;
	defuseObject.onUse = ::onUseDefuseObject;
	defuseObject.useWeapon = "briefcase_bomb_defuse_mp";
	player.isBombCarrier = false;
	bombTimerWait();
	setMatchFlag("bomb_timer", 0);
	destroyedObj.visuals[0] maps\mp\gametypes\_globallogic_utils::stopTickingSound();
	if (level.gameEnded || level.bombDefused) {
		return;
	}

	level.bombExploded = true;
	explosionOrigin = level.sdBombModel.origin + (0, 0, 12);
	level.sdBombModel hide();
	if (isDefined(player)) {
		destroyedObj.visuals[0] radiusDamage(explosionOrigin, 512, 200, 20, player, "MOD_EXPLOSIVE", "briefcase_bomb_mp");
		level thread maps\mp\_popups::displayTeamMessageToAll(&"MP_EXPLOSIVES_BLOWUP_BY", player);
		player maps\mp\_medals::bomber();
		player maps\mp\gametypes\_persistence::statAddWithGameType("DESTRUCTIONS", 1);
	}
	else {
		destroyedObj.visuals[0] radiusDamage(explosionOrigin, 512, 200, 20, undefined, "MOD_EXPLOSIVE", "briefcase_bomb_mp");
	}

	rot = randomFloat(360);
	explosionEffect = spawnFx(level._effect["bombexplosion"], explosionOrigin + (0, 0, 50), (0, 0, 1), (cos(rot), sin(rot), 0));
	triggerFx(explosionEffect);
	thread playSoundinSpace("mpl_sd_exp_suitcase_bomb_main", explosionOrigin);
	if (isDefined(destroyedObj.exploderIndex)) {
		exploder(destroyedObj.exploderIndex);
	}

	for (index = 0; index < level.bombZones.size; index++) {
		level.bombZones[index] maps\mp\gametypes\_gameobjects::disableObject();
	}

	defuseObject maps\mp\gametypes\_gameobjects::disableObject();
	setGameEndTime(0);
	wait 3;
    sd_endGameWithKillcam(game["attackers"], game["strings"]["target_destroyed"]);
}

bombTimerWait() {
	level endon("game_ended");
	level endon("bomb_defused");

	maps\mp\gametypes\_hostmigration::waitLongDurationWithGameEndTimeUpdate(level.bombTimer);
}

bombDefused() {
	level.tickingObject maps\mp\gametypes\_globallogic_utils::stopTickingSound();
	level.bombDefused = true;
	setMatchFlag("bomb_timer", 0);
	level notify("bomb_defused");
	thread maps\mp\gametypes\_globallogic_audio::set_music_on_team("SILENT", "both");		
	wait 1.5;
	setGameEndTime(0);
	sd_endGameWithKillcam(game["defenders"], game["strings"]["bomb_defused"]);
}

sd_isKillBoosting() {
	/*
	roundsPlayed = maps\mp\_utility::getRoundsPlayed();
	if (level.playerKillsMax == 0) {
		return false;
	}

	if (game["totalKills"] > (level.totalKillsMax * (roundsPlayed + 1))) {
		return true;
	}

	if (self.kills > (level.playerKillsMax * (roundsPlayed + 1))) {
		return true;
	}

	if (level.teambased && (self.team == "allies" || self.team == "axis")) {
		if (game["totalKillsTeam"][self.team] > ( level.playerKillsMax * (roundsPlayed + 1))) {
			return true;
		}
	}
	*/
	
	return false;
}

onRoundEndGame(roundWinner) {
	if (game["roundswon"]["allies"] == game["roundswon"]["axis"]) {
		winner = "tie";
	}
	else if (game["roundswon"]["axis"] > game["roundswon"]["allies"]) {
		winner = "axis";
	}
	else {
		winner = "allies";
	}

	return winner;
}
