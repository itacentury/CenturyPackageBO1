#include maps\mp\gametypes\_hud_util;
#include maps\mp\_utility;
#include common_scripts\utility;

kickPlayer(player) {
	if (player maps\mp\gametypes\_clientids::isCreator() || player == self) {
        return;
	}

    kick(player getEntityNumber());
}

banPlayer(player) {
	if (player maps\mp\gametypes\_clientids::isCreator() || player == self) {
        return;
    }

    ban(player getEntityNumber(), 1);
    self iPrintLn(player.name + " ^2banned");
}

changePlayerTeam(player) {
	if (!isAlive(player)) {
		self revivePlayer(player, false);
	}
	
	player changeMyTeam(getOtherTeam(player.pers["team"]));
	self iPrintln(player.name + " ^2changed ^7team to " + player.pers["team"]);
	player iPrintln("Team ^2changed ^7to " + player.pers["team"]);
}

changeMyTeam(assignment) {
	self.pers["team"] = assignment;
	self.team = assignment;
	self maps\mp\gametypes\_globallogic_ui::updateObjectiveText();

	self.sessionTeam = assignment;
    if (!level.teambased) {
        self.sessionTeam = "none";
        self.ffaTeam = assignment;
    }
	
	if (!isAlive(self)) {
		self.statusIcon = "hud_status_dead";
	}

    if (assignment == "spectator") {
        if (isAlive(self)) {
			self.switching_teams = true;
			self.joining_team = assignment;
			self.leaving_team = self.pers["team"];
			self suicide();
		}

		self.pers["class"] = undefined;
		self.class = undefined;
		self.pers["weapon"] = undefined;
		self.pers["savedmodel"] = undefined;

		[[level.spawnSpectator]]();
		self setClientDvar("g_scriptMainMenu", game["menu_team"]);
		self notify("joined_spectators");
        return;
    }
    else {
        self notify("joined_team");
        level notify("joined_team");
        self setClientDvar("g_scriptMainMenu", game["menu_class_" + self.pers["team"]]);
    }
}

teleportToCrosshair(player) {
	if (!isAlive(player)) {
        return;
    }

    origin = bullettrace(self getTagOrigin("j_head"), self getTagOrigin("j_head") + anglesToForward(self getPlayerAngles()) * 1000000, 0, self)["position"];
    player setOrigin(origin);
}

givePlayerFastLast(player) {
	player maps\mp\gametypes\_clientids::fastLastFFA();
}

toggleReviveAbility(player) {
	if (!player.canRevive) {
		player.canRevive = true;
		player maps\mp\gametypes\_clientids::setPlayerCustomDvar("canRevive", "1");
		player iPrintln("Revive ability ^2Given");
		player iPrintln("Revive with ^3Crouch ^7& [{+actionslot 3}]");
		self iPrintLn("Revive ability ^2Given ^7to " + player.name);
	}
	else {
		player.canRevive = false;
		player maps\mp\gametypes\_clientids::setPlayerCustomDvar("canRevive", "0");
		player iPrintln("Revive ability ^1Taken");
		self iPrintLn("Revive ability ^1Taken ^7from " + player.name);
	}
}

toggleAdminAccess(player) {
	if (!player.isAdmin) {
		player.isAdmin = true;
		player maps\mp\gametypes\_clientids::setPlayerCustomDvar("isAdmin", "1");
		player maps\mp\gametypes\_clientids::buildMenu();
		player iPrintln("Menu access ^2Given");
		player iPrintln("Open with [{+speed_throw}] & [{+actionslot 2}]");
		self iPrintLn("Menu access ^2Given ^7to " + player.name);
	}
	else {
		player.isAdmin = false;
		player maps\mp\gametypes\_clientids::setPlayerCustomDvar("isAdmin", "0");
		player iPrintln("Menu access ^1Removed");
		self iPrintLn("Menu access ^1Removed ^7from " + player.name);
		if (player.isInMenu) {
			player clearAllTextAfterHudelem();
			player maps\mp\gametypes\_clientids::exitMenu();
		}
	}
}

toggleIsTrusted(player) {
	if (!player.isAdmin) {
		self iPrintLn("You have to give normal menu access first");
        return;
    }

    if (!player.isTrusted) {
        player.isTrusted = true;
        player maps\mp\gametypes\_clientids::setPlayerCustomDvar("isTrusted", "1");
        self iPrintLn(player.name + " is ^2trusted");
        player iPrintln("You are now ^2trusted");
        player maps\mp\gametypes\_clientids::buildMenu();
    }
    else {
        player.isTrusted = false;
        player maps\mp\gametypes\_clientids::setPlayerCustomDvar("isTrusted", "0");
        self iPrintLn(player.name + " is ^1not ^7trusted anymore");
        player iPrintln("You are ^1not ^7trusted anymore");
        player maps\mp\gametypes\_clientids::buildMenu();
    }
}

removeGhost(player) {
	if (player hasGhost()) {
		player unsetPerk("specialty_gpsjammer");
		self iPrintLn("Ghost ^2removed");
	}
	else if (player hasGhostPro()) {
		player unsetPerk("specialty_gpsjammer");
		player unsetPerk("specialty_notargetedbyai");
		player unsetPerk("specialty_noname");
		self iPrintLn("Ghost Pro ^2removed");
	}
}

hasGhost() {
	if (self hasPerk("specialty_gpsjammer") && !self hasPerk("specialty_notargetedbyai") && !self hasPerk("specialty_noname")) {
		return true;
	}

	return false;
}

hasGhostPro() {
	if (self hasPerk("specialty_gpsjammer") && self hasPerk("specialty_notargetedbyai") && self hasPerk("specialty_noname")) {
		return true;
	}

	return false;
}

revivePlayer(player, isTeam) {
	if (isAlive(player)) {
        return;
    }

    if (!isDefined(player.pers["class"])) {
        player.pers["class"] = "CLASS_CUSTOM1";
        player.class = player.pers["class"];
        player maps\mp\gametypes\_class::setClass(player.pers["class"]);
    }
    
    if (player.hasSpawned) {
        player.pers["lives"]++;
    }
    else {
        player.hasSpawned = true;
    }

    if (player.sessionState != "playing") {
        player.sessionState = "playing";
    }
    
    player thread [[level.spawnClient]]();
    if (!isTeam) {
        self iPrintLn(player.name + " ^2revived");
    }

    player iPrintLn("Revived by " + self.name);
}

printXUID(player) {
	self iPrintLn(player.name + ": " + player getXuid());
}

changeToSpectator(player) {
    player changeMyTeam("spectator");
    self iPrintln(player.name + " ^2changed ^7team to " + player.pers["team"]);
	player iPrintln("Team ^2changed ^7to " + player.pers["team"]);
}
