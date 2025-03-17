#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init() {
	precacheString(&"MP_HALFTIME");
	precacheString(&"MP_OVERTIME");
	precacheString(&"MP_ROUNDEND");
	precacheString(&"MP_INTERMISSION");
	precacheString(&"MP_SWITCHING_SIDES_CAPS");
	precacheString(&"MP_FRIENDLY_FIRE_WILL_NOT");
	precacheString(&"PATCH_MP_CANNOT_JOIN_TEAM");
	if (level.splitscreen) {
		precacheString(&"MP_ENDED_GAME");
	}
	else {
		precacheString(&"MP_HOST_ENDED_GAME");
	}
}

setupCallbacks() {
	level.autoassign = ::menuAutoAssign;
	level.spectator = ::menuSpectator;
	level.class = ::menuClass;
	level.allies = ::menuAllies;
	level.axis = ::menuAxis;
}

hideLoadoutAfterTime(delay) {
	self endon("disconnect");
	self endon("perks_hidden");

	wait delay;
	self thread hidePerk(0, 0.4);
	self thread hidePerk(1, 0.4);
	self thread hidePerk(2, 0.4);
	self thread hidePerk(3, 0.4);
	self notify("perks_hidden");
}

hideLoadoutOnDeath() {
	self endon("disconnect");
	self endon("perks_hidden");

	self waittill("death");
	self hidePerk(0);
	self hidePerk(1);
	self hidePerk(2);
	self notify("perks_hidden");
}

hideLoadoutOnKill() {
	self endon("disconnect");
	self endon("death");
	self endon("perks_hidden");

	self waittill("killed_player");
	self hidePerk(0);
	self hidePerk(1);
	self hidePerk(2);
	self hidePerk(3);
	self notify("perks_hidden");
}

freeGameplayHudElems() {
	if (isDefined(self.perkicon)) {
		if (isDefined(self.perkicon[0])) {
			self.perkicon[0] destroyElem();
			self.perkname[0] destroyElem();
		}

		if (isDefined(self.perkicon[1])) {
			self.perkicon[1] destroyElem();
			self.perkname[1] destroyElem();
		}

		if (isDefined(self.perkicon[2])) {
			self.perkicon[2] destroyElem();
			self.perkname[2] destroyElem();
		}

		if (isDefined(self.perkicon[3])) {
			self.perkicon[3] destroyElem();
			self.perkname[3] destroyElem();
		}
	}
	
	if (isDefined(self.killstreakIcon)) {
		if (isDefined(self.killstreakIcon[0])) {
			self.killstreakIcon[0] destroyElem();
		}

		if (isDefined(self.killstreakIcon[1])) {
			self.killstreakIcon[1] destroyElem();
		}

		if (isDefined(self.killstreakIcon[2])) {
			self.killstreakIcon[2] destroyElem();
		}

		if (isDefined(self.killstreakIcon[3])) {
			self.killstreakIcon[3] destroyElem();
		}

		if (isDefined(self.killstreakIcon[4])) {
			self.killstreakIcon[4] destroyElem();
		}
	}

	self notify("perks_hidden"); 
	if (isDefined(self.lowerMessage)) {
		self.lowerMessage destroyElem();
	}

	if (isDefined(self.lowerTimer)) {
		self.lowerTimer destroyElem();
	}
	
	if (isDefined(self.proxBar)) {
		self.proxBar destroyElem();
	}

	if (isDefined(self.proxBarText)) {
		self.proxBarText destroyElem();
	}	
	
	if (isDefined(self.carryIcon)) {
		self.carryIcon destroyElem();
	}
}

menuAutoAssign() {
	teams[0] = "allies";
	teams[1] = "axis";
	assignment = teams[randomInt(2)];
	self closeMenus();
	if (level.teambased) {
		if (level.console && getDvarInt(#"party_autoteams") == 1) {
			if (level.allow_teamchange == "1" && self.hasSpawned) {
				assignment = "";
			}
			else {
				teamNum = getAssignedTeam(self);
				switch (teamNum)
				{			
					case 1:
						assignment = teams[1];
						break;
					case 2:
						assignment = teams[0];
						break;
					default:
						assignment = "";
				}
			}
		}
		else if(level.teamchange_rememberChoice) {
			teamNum = 1; 
			switch (teamNum) {			
				case 1:
					assignment = teams[1];
					break;
				case 2:
					assignment = teams[0];
					break;
				default:
					assignment = "";
			}
		}
		
		if (assignment == "" || getDvarInt(#"party_autoteams") == 0) {	
			playerCounts = self maps\mp\gametypes\_teams::countPlayers();
			if (playerCounts["allies"] == playerCounts["axis"]) {
				if (!level.splitscreen && self isSplitscreen())
				{
					assignment = self getSplitscreenTeam();
					if (assignment == "")
					{
						assignment = pickTeamFromScores(teams);
					}
				}
				else 
				{
					assignment = pickTeamFromScores(teams);
				}
			}
			else if (playerCounts["allies"] < playerCounts["axis"]) {
				assignment = "allies";
			}
			else {
				assignment = "axis";
			}
		}
		
		if (assignment == self.pers["team"] && (self.sessionState == "playing" || self.sessionState == "dead")) {
			self beginClassChoice();
			return;
		}
	}

	if (assignment != self.pers["team"] && (self.sessionState == "playing" || self.sessionState == "dead")) {
		self.switching_teams = true;
		self.joining_team = assignment;
		self.leaving_team = self.pers["team"];
		self suicide();
	}

	self.pers["team"] = assignment;
	self.team = assignment;
	self.pers["class"] = undefined;
	self.class = undefined;
	self.pers["weapon"] = undefined;
	self.pers["savedmodel"] = undefined;
	self updateObjectiveText();
	if (level.teambased) {
		self.sessionTeam = assignment;
	}
	else {
		self.sessionTeam = "none";
		self.ffaTeam = assignment;
	}
	
	if (!isAlive(self)) {
		self.statusIcon = "hud_status_dead";
	}

	self notify("joined_team");
	level notify("joined_team");
	self notify("end_respawn");
	self thread preventTeamSwitchExploit();
	if (isPregameGameStarted()) {
		pregameClass = self getPregameClass();
		if(isDefined(pregameClass)) {
			self closeMenu();
			self closeInGameMenu();
			self.selectedClass = true;
			self [[level.class]](pregameClass);
			self setClientDvar("g_scriptMainMenu", game["menu_class_" + self.pers["team"]]);
			return;
		}
	}

	self beginClassChoice();	
	self setClientDvar("g_scriptMainMenu", game["menu_class_" + self.pers["team"]]);
}

pickTeamFromScores(teams) {
	assignment = "allies";
	if (getTeamScore("allies") == getTeamScore("axis")) {
		assignment = teams[randomInt(2)];
	}
	else if (getTeamScore("allies") < getTeamScore("axis")) {
		assignment = "allies";
	}
	else {
		assignment = "axis";
	}

	return assignment;
}

getSplitscreenTeam() {
	for (i = 0; i < level.players.size; i++) {
        player = level.players[i];
		if (!isDefined(player)) {
			continue;
		}

		if (player == self) {
			continue;
		}

		if (!(self isPlayerOnSameMachine(player))) {
			continue;
		}

		team = player.sessionTeam;
		if (team != "spectator") {
			return team;
		}
	}
	
	return "";
}

updateObjectiveText() {
	if (self.pers["team"] == "spectator") {
		self setClientDvar("cg_objectiveText", "");
		return;
	}

	if (level.scoreLimit > 0) {
		if (level.splitscreen) {
			self setClientDvar("cg_objectiveText", getObjectiveScoreText(self.pers["team"]));
		}
		else {
			self setClientDvar("cg_objectiveText", getObjectiveScoreText(self.pers["team"]), level.scoreLimit);
		}
	}
	else {
		self setClientDvar("cg_objectiveText", getObjectiveText(self.pers["team"]));
	}
}

closeMenus() {
	self closeMenu();
	self closeInGameMenu();
}

beginClassChoice(forceNewChoice) {
	assert(self.pers["team"] == "axis" || self.pers["team"] == "allies");
	team = self.pers["team"];
	if (level.oldschool || ( getDvarInt(#"scr_disable_cac") == 1)) {
		self.pers["class"] = level.defaultClass;
		self.class = level.defaultClass;
		if (self.sessionState != "playing" && game["state"] == "playing") {
			self thread [[level.spawnClient]]();
		}

		level thread maps\mp\gametypes\_globallogic::updateTeamStatus();
		self thread maps\mp\gametypes\_spectating::setSpectatePermissionsForMachine();
		return;
	}
	
	if (level.wagerMatch) {
		self openMenu(game["menu_changeclass_wager"]);
	}
	else if (maps\mp\gametypes\_customClasses::isUsingCustomGameModeClasses()) {
		self openMenu(game["menu_changeclass_custom"]);
	}
	else if (getDvarInt(#"barebones_class_mode")) {
		self openMenu(game["menu_changeclass_barebones"]);
	}
	else {
		self openMenu(game["menu_changeclass_" + team]);
	}
}

showMainMenuForTeam() {
	assert(self.pers["team"] == "axis" || self.pers["team"] == "allies");
	team = self.pers["team"];
	if (level.wagerMatch) {
		self openMenu(game["menu_changeclass_wager"]);
	}
	else if(maps\mp\gametypes\_customClasses::isUsingCustomGameModeClasses()) {
		self openMenu(game["menu_changeclass_custom"]);
	}
	else {
		self openMenu(game["menu_changeclass_" + team]);
	}
}

canJoinTeam(team) {
	if (team == "spectator") {
		if (self isDemoClient()) {
			printLn("canJoinTeam: " + team + ", " + self.name + " Yes, reason: admin");
			return true;
		}
				
		if (!level.allow_spectator || self is_bot()) {				
			printLn("canJoinTeam: " + team + ", " + self.name + " No, reason: not allowed");
			return false;
		}
		
		printLn("canJoinTeam: " + team + ", " + self.name + " Yes, reason: default");
		return true;
	}
	
	if (level.console || self is_bot()) {
		printLn("canJoinTeam: " + team + ", " + self.name + " Yes, reason: exception");
		return true;
	}
		
	if (level.allow_teamchange == "0" && isDefined(self.hasDoneCombat) && self.hasDoneCombat) {
		printLn("canJoinTeam: " + team + ", " + self.name + " No, reason: no teamchange");
		return false;
	}

	if (!level.teamchange_gracePeriod && level.teamchange_keepBalanced) {
		otherTeam = getOtherTeam(team);
		playerCounts = self maps\mp\gametypes\_teams::countPlayers();
		printLn("canJoinTeam: " + team + "=" + playerCounts[team] + " " + otherTeam + "=" + playerCounts[otherTeam]);
		if (playerCounts[team] + 1 - playerCounts[otherTeam] > 1) {
			printLn("canJoinTeam: " + team + ", " + self.name + " No, reason: unbalanced");
			return false;
		}
	}
	
	printLn("canJoinTeam: " + team + ", " + self.name + " Yes, reason: default");
	return true;
}

preventTeamSwitchExploit() {
	if (getDvarInt(#"scr_teamSwitchExploit") == 0) {
		return;
	}

	self notify("team_switch_exploit");
	self endon("team_switch_exploit");
	
	self.teamSwitchExploit = true;
	endTime = getTime() + getDvarInt(#"scr_teamSwitchExploit");
	while (endTime > getTime()) {
		wait 1;
	}

	self.teamSwitchExploit = undefined;
}

menuAllies() {
	self closeMenus();
	if (!self canJoinTeam("allies")) {
		self iPrintLn(&"PATCH_MP_CANNOT_JOIN_TEAM");	
		return;
	}
	
	if (self.pers["team"] != "allies") {
		if (level.inGracePeriod && (!isDefined(self.hasDoneCombat) || !self.hasDoneCombat)) {
			self.hasSpawned = false;
		}

		if (level.teamchange_gracePeriod) {
			self.pers["dont_autobalance"] = true;
		}

		if (self.sessionState == "playing") {
			self.switching_teams = true;
			self.joining_team = "allies";
			self.leaving_team = self.pers["team"];
			self suicide();
		}

		self.pers["team"] = "allies";
		self.team = "allies";
		self.pers["class"] = undefined;
		self.class = undefined;
		self.pers["weapon"] = undefined;
		self.pers["savedmodel"] = undefined;
		self updateObjectiveText();
		if (level.teambased) {
			self.sessionTeam = "allies";
		}
		else {
			self.sessionTeam = "none";
			self.ffaTeam = "allies";
		}

		self setClientDvar("g_scriptMainMenu", game["menu_class_allies"]);
		self notify("joined_team");
		level notify("joined_team");
		self notify("end_respawn");
		self thread preventTeamSwitchExploit();
	}
	
	self beginClassChoice();
}

menuAxis() {
	self closeMenus();
	if (!self canJoinTeam("axis")) {
		self iPrintLn(&"PATCH_MP_CANNOT_JOIN_TEAM");	
		return;
	}
	
	if (self.pers["team"] != "axis") {
		if (level.inGracePeriod && (!isDefined(self.hasDoneCombat) || !self.hasDoneCombat)) {
			self.hasSpawned = false;
		}

		if (level.teamchange_gracePeriod) {
			self.pers["dont_autobalance"] = true;
		}

		if (self.sessionState == "playing") {
			self.switching_teams = true;
			self.joining_team = "axis";
			self.leaving_team = self.pers["team"];
			self suicide();
		}

		self.pers["team"] = "axis";
		self.team = "axis";
		self.pers["class"] = undefined;
		self.class = undefined;
		self.pers["weapon"] = undefined;
		self.pers["savedmodel"] = undefined;
		self updateObjectiveText();
		if (level.teambased) {
			self.sessionTeam = "axis";
		}
		else {
			self.sessionTeam = "none";
			self.ffaTeam = "axis";
		}

		self setClientDvar("g_scriptMainMenu", game["menu_class_axis"]);
		self notify("joined_team");
		level notify("joined_team");
		self notify("end_respawn");
		self thread preventTeamSwitchExploit();
	}
	
	self beginClassChoice();
}

menuSpectator() {
	self closeMenus();
	if (!self canJoinTeam("spectator")) {
		self iPrintLn(&"PATCH_MP_CANNOT_JOIN_TEAM");	
		return;
	}
	
	if (self.pers["team"] != "spectator") {
		if (isAlive(self)) {
			self.switching_teams = true;
			self.joining_team = "spectator";
			self.leaving_team = self.pers["team"];
			self suicide();
		}

		self.pers["team"] = "spectator";
		self.team = "spectator";
		self.pers["class"] = undefined;
		self.class = undefined;
		self.pers["weapon"] = undefined;
		self.pers["savedmodel"] = undefined;
		self updateObjectiveText();
		self.sessionTeam = "spectator";
		if (!level.teambased) {
			self.ffaTeam = "spectator";
		}

		[[level.spawnSpectator]]();
		self setClientDvar("g_scriptMainMenu", game["menu_team"]);
		self notify("joined_spectators");
	}
}

menuClass(response) {
	self closeMenus();
	assert(!level.oldschool);
	if (!isDefined(self.pers["team"]) || (self.pers["team"] != "allies" && self.pers["team"] != "axis")) {
		return;
	}

	class = self maps\mp\gametypes\_class::getClassChoice(response);
	primary = self maps\mp\gametypes\_class::getWeaponChoice(response);
	if (class == "restricted") {
		self beginClassChoice();
		return;
	}

	if ((isDefined(self.pers["class"]) && self.pers["class"] == class) && (isDefined(self.pers["primary"]) && self.pers["primary"] == primary)) {
		return;
	}

	self notify("changed_class");
	self maps\mp\gametypes\_gametype_variants::onPlayerClassChange();
	if (isPregame()) {
		self maps\mp\gametypes\_pregame::onPlayerClassChange(response);
	}

	if (self.sessionState == "playing") {
		self.pers["class"] = class;
		self.class = class;
		self.pers["primary"] = primary;
		self.pers["weapon"] = undefined;
		if (game["state"] == "postgame") {
			return;
		}

		supplyStationClassChange = isDefined(self.usingSupplyStation) && self.usingSupplyStation;
		self.usingSupplyStation = false;
		if (level.currentGametype == "sd") {
			self maps\mp\gametypes\_class::setClass(self.pers["class"]);
			self.tag_stowed_back = undefined;
			self.tag_stowed_hip = undefined;
			self maps\mp\gametypes\_class::giveLoadout(self.pers["team"], self.pers["class"]);
			self maps\mp\gametypes\_hardpoints::giveOwnedKillstreak();
		}
		else {
			if ((level.inGracePeriod && !self.hasDoneCombat) || supplyStationClassChange) {
				self maps\mp\gametypes\_class::setClass(self.pers["class"]);
				self.tag_stowed_back = undefined;
				self.tag_stowed_hip = undefined;
				self maps\mp\gametypes\_class::giveLoadout(self.pers["team"], self.pers["class"]);
				self maps\mp\gametypes\_hardpoints::giveOwnedKillstreak();
			}
			else if (!level.splitscreen) {
				notifyData = spawnStruct();
				self displayGameModeMessage(game["strings"]["change_class"], "uin_alert_slideout");
			}
		}
	}
	else {
		self.pers["class"] = class;
		self.class = class;
		self.pers["primary"] = primary;
		self.pers["weapon"] = undefined;
		if (game["state"] == "postgame") {
			return;
		}

		if (self.sessionState != "spectator") {
			if (self isInVehicle()) {
				return;
			}

			if (self isRemoteControlling()) {
				return;
			}
		}
		if (game["state"] == "playing") {
			self thread [[level.spawnClient]]();
		}
	}

	level thread maps\mp\gametypes\_globallogic::updateTeamStatus();
	self thread maps\mp\gametypes\_spectating::setSpectatePermissionsForMachine();
}

removeSpawnMessageShortly(delay) {
	self endon("disconnect");
	
	waittillframeend;
	self endon("end_respawn");
	
	wait delay;
	self clearLowerMessage(2.0);
}

setObjectiveText(team, text) {
	game["strings"]["objective_" + team] = text;
	precacheString(text);
}

setObjectiveScoreText(team, text) {
	game["strings"]["objective_score_" + team] = text;
	precacheString(text);
}

setObjectiveHintText(team, text) {
	game["strings"]["objective_hint_" + team] = text;
	precacheString(text);
}

getObjectiveText(team) {
	return game["strings"]["objective_" + team];
}

getObjectiveScoreText(team) {
	return game["strings"]["objective_score_" + team];
}

getObjectiveHintText(team) {
	return game["strings"]["objective_hint_" + team];
}
